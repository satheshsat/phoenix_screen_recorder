import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../models/recording_item.dart';
import '../models/recording_settings.dart';
import 'storage_service.dart';

enum RecordingState {
  idle,
  countingDown,
  recording,
  paused,
  finalizing,
}

class RecordingService extends ChangeNotifier {
  static final RecordingService _instance = RecordingService._internal();
  factory RecordingService() => _instance;
  RecordingService._internal();

  final StorageService _storageService = StorageService();

  RecordingState _state = RecordingState.idle;
  RecordingState get state => _state;

  RecordingSettings _settings = const RecordingSettings();
  RecordingSettings get settings => _settings;

  int _countdown = 3;
  int get countdown => _countdown;

  Duration _elapsed = Duration.zero;
  Duration get elapsed => _elapsed;

  Timer? _timer;
  Timer? _countdownTimer;
  Timer? _audioVisualizerTimer;

  // Real-time audio levels for UI meters (0.0 - 1.0)
  double _bgSoundLevel = 0.0;
  double get bgSoundLevel => _bgSoundLevel;

  double _micLevel = 0.0;
  double get micLevel => _micLevel;

  // Linux native process handles
  Process? _videoProcess;
  Process? _sysAudioProcess;
  Process? _micAudioProcess;

  Directory? _tempDir;
  String? _tempVideoPath;
  String? _tempSysAudioPath;
  String? _tempMicAudioPath;
  DateTime? _recordingStartTime;
  DateTime? get recordingStartTime => _recordingStartTime;

  List<RecordingItem> _recordings = [];
  List<RecordingItem> get recordings => _recordings;

  Future<void> init() async {
    await refreshRecordings();
    _startAudioMonitor();
  }

  void updateSettings(RecordingSettings newSettings) {
    if (_state != RecordingState.idle) return;
    _settings = newSettings;
    notifyListeners();
  }

  // Toggles for user request
  void toggleBackgroundSound(bool enable) {
    _settings = _settings.copyWith(recordBackgroundSound: enable);
    notifyListeners();
  }

  void setBackgroundSoundVolume(double volume) {
    _settings = _settings.copyWith(backgroundSoundVolume: volume);
    notifyListeners();
  }

  void toggleMic(bool enable) {
    _settings = _settings.copyWith(recordMic: enable);
    notifyListeners();
  }

  void setMicVolume(double volume) {
    _settings = _settings.copyWith(micVolume: volume);
    notifyListeners();
  }

  void toggleResolution(VideoResolution res) {
    _settings = _settings.copyWith(resolution: res);
    notifyListeners();
  }

  void toggleFrameRate(int fps) {
    _settings = _settings.copyWith(frameRate: fps);
    notifyListeners();
  }

  void toggleCaptureSource(CaptureSource source) {
    _settings = _settings.copyWith(captureSource: source);
    notifyListeners();
  }

  Future<void> refreshRecordings() async {
    _recordings = await _storageService.loadRecordings();
    notifyListeners();
  }

  // Audio level simulator/monitor for the UI waveform meters
  void _startAudioMonitor() {
    final random = Random();
    _audioVisualizerTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (_settings.recordBackgroundSound) {
        final base = _state == RecordingState.recording ? 0.35 : 0.2;
        final delta = (random.nextDouble() * 0.45) * _settings.backgroundSoundVolume;
        _bgSoundLevel = (_bgSoundLevel * 0.3) + ((base + delta) * 0.7);
        if (_bgSoundLevel > 1.0) _bgSoundLevel = 1.0;
      } else {
        _bgSoundLevel = 0.0;
      }

      if (_settings.recordMic) {
        final base = _state == RecordingState.recording ? 0.4 : 0.25;
        final delta = (random.nextDouble() * 0.5) * (_settings.micVolume / 1.5);
        _micLevel = (_micLevel * 0.3) + ((base + delta) * 0.7);
        if (_micLevel > 1.0) _micLevel = 1.0;
      } else {
        _micLevel = 0.0;
      }

      notifyListeners();
    });
  }

  Future<String?> _findFfmpegPath() async {
    final home = Platform.environment['HOME'] ?? '';
    final localPath = p.join(home, '.local', 'bin', 'ffmpeg');
    if (File(localPath).existsSync()) return localPath;

    final whichResult = await Process.run('which', ['ffmpeg']);
    if (whichResult.exitCode == 0) {
      final bin = (whichResult.stdout as String).trim();
      if (bin.isNotEmpty && File(bin).existsSync()) return bin;
    }

    if (File('/usr/bin/ffmpeg').existsSync()) return '/usr/bin/ffmpeg';
    return null;
  }

  Future<String?> _detectDefaultSink() async {
    try {
      final res = await Process.run('pactl', ['get-default-sink']);
      if (res.exitCode == 0) {
        final sink = (res.stdout as String).trim();
        if (sink.isNotEmpty) return sink;
      }
    } catch (_) {}
    return null;
  }

  Future<void> startRecording() async {
    if (_state != RecordingState.idle) return;

    if (_settings.countdownSeconds > 0) {
      _state = RecordingState.countingDown;
      _countdown = _settings.countdownSeconds;
      notifyListeners();

      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _countdown--;
        if (_countdown <= 0) {
          timer.cancel();
          _beginRecordingProcess();
        } else {
          notifyListeners();
        }
      });
    } else {
      await _beginRecordingProcess();
    }
  }

  Future<void> _beginRecordingProcess() async {
    _state = RecordingState.recording;
    _elapsed = Duration.zero;
    _recordingStartTime = DateTime.now();
    notifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      notifyListeners();
    });

    try {
      if (Platform.isLinux) {
        await _startLinuxNativeRecording();
      } else {
        debugPrint('Non-Linux platform or fallback mode');
      }
    } catch (e) {
      debugPrint('Error starting native capture: $e');
    }
  }

  Future<void> _startLinuxNativeRecording() async {
    final ffmpegPath = await _findFfmpegPath();
    if (ffmpegPath == null) {
      debugPrint('FFmpeg not found');
      return;
    }

    _tempDir = await Directory.systemTemp.createTemp('phoenix_rec_');
    _tempVideoPath = p.join(_tempDir!.path, 'video.mp4');
    _tempSysAudioPath = p.join(_tempDir!.path, 'system_sound.wav');
    _tempMicAudioPath = p.join(_tempDir!.path, 'microphone.wav');

    final res = _settings.resolution;
    final fps = _settings.frameRate;
    final bitrate = '${_settings.videoBitrateMbps}M';

    // 1. Launch FFmpeg screen video capture
    final videoArgs = [
      '-y',
      '-f', 'x11grab',
      '-video_size', '${res.width}x${res.height}',
      '-framerate', '$fps',
      '-i', ':0.0',
      '-c:v', 'libx264',
      '-preset', 'ultrafast',
      '-b:v', bitrate,
      '-pix_fmt', 'yuv420p',
      _tempVideoPath!,
    ];

    try {
      _videoProcess = await Process.start(ffmpegPath, videoArgs);
    } catch (e) {
      debugPrint('Failed to start FFmpeg video process: $e');
    }

    // 2. Launch Background Sound (System Audio) capture if enabled
    if (_settings.recordBackgroundSound) {
      final defaultSink = await _detectDefaultSink();
      final target = defaultSink != null ? '$defaultSink.monitor' : null;
      try {
        final args = <String>[];
        if (target != null) {
          args.addAll(['--target', target]);
        }
        args.add(_tempSysAudioPath!);
        _sysAudioProcess = await Process.start('pw-record', args);
      } catch (e) {
        debugPrint('Failed to start Background Sound pw-record: $e');
      }
    }

    // 3. Launch Microphone capture if enabled
    if (_settings.recordMic) {
      try {
        _micAudioProcess = await Process.start('pw-record', [_tempMicAudioPath!]);
      } catch (e) {
        debugPrint('Failed to start Microphone pw-record: $e');
      }
    }
  }

  void pauseRecording() {
    if (_state != RecordingState.recording) return;
    _state = RecordingState.paused;
    _timer?.cancel();

    if (_videoProcess != null) {
      Process.run('kill', ['-STOP', '${_videoProcess!.pid}']);
    }
    if (_sysAudioProcess != null) {
      Process.run('kill', ['-STOP', '${_sysAudioProcess!.pid}']);
    }
    if (_micAudioProcess != null) {
      Process.run('kill', ['-STOP', '${_micAudioProcess!.pid}']);
    }

    notifyListeners();
  }

  void resumeRecording() {
    if (_state != RecordingState.paused) return;
    _state = RecordingState.recording;

    if (_videoProcess != null) {
      Process.run('kill', ['-CONT', '${_videoProcess!.pid}']);
    }
    if (_sysAudioProcess != null) {
      Process.run('kill', ['-CONT', '${_sysAudioProcess!.pid}']);
    }
    if (_micAudioProcess != null) {
      Process.run('kill', ['-CONT', '${_micAudioProcess!.pid}']);
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      notifyListeners();
    });

    notifyListeners();
  }

  Future<void> stopRecording() async {
    if (_state != RecordingState.recording && _state != RecordingState.paused) {
      return;
    }

    _state = RecordingState.finalizing;
    _timer?.cancel();
    notifyListeners();

    final recordedDuration = _elapsed;
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);
    final outputFileName = 'Phoenix_Recording_$dateStr.mp4';
    final targetDir = await _storageService.getRecordingsDirectory();
    final targetPath = p.join(targetDir.path, outputFileName);

    try {
      if (_videoProcess != null) {
        Process.runSync('kill', ['-INT', '${_videoProcess!.pid}']);
        await _videoProcess!.exitCode;
      }
      if (_sysAudioProcess != null) {
        Process.runSync('kill', ['-INT', '${_sysAudioProcess!.pid}']);
        await _sysAudioProcess!.exitCode;
      }
      if (_micAudioProcess != null) {
        Process.runSync('kill', ['-INT', '${_micAudioProcess!.pid}']);
        await _micAudioProcess!.exitCode;
      }

      final ffmpegPath = await _findFfmpegPath();
      final hasVideo = _tempVideoPath != null && File(_tempVideoPath!).existsSync();
      final hasSysAudio = _settings.recordBackgroundSound &&
          _tempSysAudioPath != null &&
          File(_tempSysAudioPath!).existsSync();
      final hasMicAudio = _settings.recordMic &&
          _tempMicAudioPath != null &&
          File(_tempMicAudioPath!).existsSync();

      if (ffmpegPath != null && hasVideo) {
        if (hasSysAudio && hasMicAudio) {
          await Process.run(ffmpegPath, [
            '-y',
            '-i', _tempVideoPath!,
            '-i', _tempSysAudioPath!,
            '-i', _tempMicAudioPath!,
            '-filter_complex',
            '[1:a]volume=${_settings.backgroundSoundVolume}[a1];[2:a]volume=${_settings.micVolume}[a2];[a1][a2]amix=inputs=2:duration=longest[a]',
            '-map', '0:v',
            '-map', '[a]',
            '-c:v', 'copy',
            '-c:a', 'aac',
            '-b:a', '192k',
            targetPath,
          ]);
        } else if (hasSysAudio) {
          await Process.run(ffmpegPath, [
            '-y',
            '-i', _tempVideoPath!,
            '-i', _tempSysAudioPath!,
            '-filter_complex', '[1:a]volume=${_settings.backgroundSoundVolume}[a]',
            '-map', '0:v',
            '-map', '[a]',
            '-c:v', 'copy',
            '-c:a', 'aac',
            '-b:a', '192k',
            targetPath,
          ]);
        } else if (hasMicAudio) {
          await Process.run(ffmpegPath, [
            '-y',
            '-i', _tempVideoPath!,
            '-i', _tempMicAudioPath!,
            '-filter_complex', '[1:a]volume=${_settings.micVolume}[a]',
            '-map', '0:v',
            '-map', '[a]',
            '-c:v', 'copy',
            '-c:a', 'aac',
            '-b:a', '192k',
            targetPath,
          ]);
        } else {
          File(_tempVideoPath!).copySync(targetPath);
        }

        await _storageService.saveRecordingMetadata(
          targetPath,
          duration: recordedDuration,
          hasSystemAudio: _settings.recordBackgroundSound,
          hasMicAudio: _settings.recordMic,
          resolution: _settings.resolution.label,
        );
      }
    } catch (e) {
      debugPrint('Error finalizing recording: $e');
    } finally {
      try {
        if (_tempDir != null && _tempDir!.existsSync()) {
          _tempDir!.deleteSync(recursive: true);
        }
      } catch (_) {}

      _videoProcess = null;
      _sysAudioProcess = null;
      _micAudioProcess = null;
      _state = RecordingState.idle;
      _elapsed = Duration.zero;

      await refreshRecordings();
      notifyListeners();
    }
  }

  void cancelRecording() {
    _countdownTimer?.cancel();
    _timer?.cancel();

    if (_videoProcess != null) {
      Process.runSync('kill', ['-KILL', '${_videoProcess!.pid}']);
    }
    if (_sysAudioProcess != null) {
      Process.runSync('kill', ['-KILL', '${_sysAudioProcess!.pid}']);
    }
    if (_micAudioProcess != null) {
      Process.runSync('kill', ['-KILL', '${_micAudioProcess!.pid}']);
    }

    try {
      if (_tempDir != null && _tempDir!.existsSync()) {
        _tempDir!.deleteSync(recursive: true);
      }
    } catch (_) {}

    _videoProcess = null;
    _sysAudioProcess = null;
    _micAudioProcess = null;
    _state = RecordingState.idle;
    _elapsed = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    _audioVisualizerTimer?.cancel();
    super.dispose();
  }
}
