import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/recording_item.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Directory? _recordingsDirectory;

  Future<Directory> getRecordingsDirectory() async {
    if (_recordingsDirectory != null) return _recordingsDirectory!;

    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      final home = Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '';
      if (home.isNotEmpty) {
        final videosDir = Directory(p.join(home, 'Videos', 'PhoenixRecordings'));
        if (!videosDir.existsSync()) {
          try {
            videosDir.createSync(recursive: true);
            _recordingsDirectory = videosDir;
            return videosDir;
          } catch (_) {}
        } else {
          _recordingsDirectory = videosDir;
          return videosDir;
        }
      }
    }

    final docs = await getApplicationDocumentsDirectory();
    final recDir = Directory(p.join(docs.path, 'PhoenixRecordings'));
    if (!recDir.existsSync()) {
      recDir.createSync(recursive: true);
    }
    _recordingsDirectory = recDir;
    return recDir;
  }

  Future<List<RecordingItem>> loadRecordings() async {
    final dir = await getRecordingsDirectory();
    final items = <RecordingItem>[];

    try {
      final entities = dir.listSync();
      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.mp4')) {
          final stat = entity.statSync();
          final metaFile = File('${entity.path}.meta.json');
          bool hasSys = true;
          bool hasMic = true;
          Duration dur = const Duration(seconds: 0);
          String res = '1080p';

          if (metaFile.existsSync()) {
            try {
              final json = jsonDecode(metaFile.readAsStringSync());
              hasSys = json['hasSystemAudio'] as bool? ?? true;
              hasMic = json['hasMicAudio'] as bool? ?? true;
              dur = Duration(seconds: (json['durationSeconds'] as num? ?? 0).toInt());
              res = json['resolution'] as String? ?? '1080p';
            } catch (_) {}
          }

          items.add(RecordingItem(
            id: p.basename(entity.path),
            title: p.basenameWithoutExtension(entity.path),
            filePath: entity.path,
            createdAt: stat.modified,
            duration: dur,
            fileSizeBytes: stat.size,
            hasSystemAudio: hasSys,
            hasMicAudio: hasMic,
            resolution: res,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error loading recordings: $e');
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> saveRecordingMetadata(
    String videoPath, {
    required Duration duration,
    required bool hasSystemAudio,
    required bool hasMicAudio,
    required String resolution,
  }) async {
    try {
      final metaFile = File('$videoPath.meta.json');
      final data = {
        'durationSeconds': duration.inSeconds,
        'hasSystemAudio': hasSystemAudio,
        'hasMicAudio': hasMicAudio,
        'resolution': resolution,
        'recordedAt': DateTime.now().toIso8601String(),
      };
      await metaFile.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving metadata: $e');
    }
  }

  Future<bool> playRecording(String filePath) async {
    try {
      if (Platform.isLinux) {
        final res = await Process.run('xdg-open', [filePath]);
        if (res.exitCode == 0) return true;
      }
      final result = await OpenFilex.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('Error playing file: $e');
      return false;
    }
  }

  Future<bool> showInFolder(String filePath) async {
    try {
      final dir = File(filePath).parent.path;
      if (Platform.isLinux) {
        await Process.run('xdg-open', [dir]);
        return true;
      }
      final result = await OpenFilex.open(dir);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('Error opening folder: $e');
      return false;
    }
  }

  Future<bool> deleteRecording(RecordingItem item) async {
    try {
      final video = File(item.filePath);
      if (video.existsSync()) {
        video.deleteSync();
      }
      final meta = File('${item.filePath}.meta.json');
      if (meta.existsSync()) {
        meta.deleteSync();
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }
}
