import 'package:flutter/material.dart';
import 'models/recording_settings.dart';
import 'services/recording_service.dart';
import 'widgets/audio_control_card.dart';
import 'widgets/recording_preview_stage.dart';
import 'widgets/recordings_library_sheet.dart';
import 'widgets/settings_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final recordingService = RecordingService();
  await recordingService.init();

  runApp(PhoenixScreenRecorderApp(service: recordingService));
}

class PhoenixScreenRecorderApp extends StatelessWidget {
  final RecordingService service;

  const PhoenixScreenRecorderApp({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phoenix Screen Recorder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090D16),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5722),
          brightness: Brightness.dark,
          surface: const Color(0xFF111726),
          primary: const Color(0xFFFF5722),
          secondary: const Color(0xFF00E5FF),
        ),
        fontFamily: 'sans-serif',
      ),
      home: PhoenixRecorderHomePage(service: service),
    );
  }
}

class PhoenixRecorderHomePage extends StatefulWidget {
  final RecordingService service;

  const PhoenixRecorderHomePage({super.key, required this.service});

  @override
  State<PhoenixRecorderHomePage> createState() =>
      _PhoenixRecorderHomePageState();
}

class _PhoenixRecorderHomePageState extends State<PhoenixRecorderHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _openLibrarySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ListenableBuilder(
        listenable: widget.service,
        builder: (_, _) => RecordingsLibrarySheet(
          items: widget.service.recordings,
          onRefresh: () => widget.service.refreshRecordings(),
        ),
      ),
    );
  }

  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SettingsDialog(service: widget.service),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.service,
      builder: (context, _) {
        final service = widget.service;
        final state = service.state;
        final isRecording = state == RecordingState.recording;
        final isPaused = state == RecordingState.paused;
        final isCountingDown = state == RecordingState.countingDown;
        final isFinalizing = state == RecordingState.finalizing;

        return Scaffold(
          backgroundColor: const Color(0xFF090D16),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0C121F),
            elevation: 0,
            titleSpacing: 20,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: const Color(0xFFFF7A00).withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5722).withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/icon/icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.fiber_manual_record_rounded,
                        color: Color(0xFFFF5722),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Phoenix Screen Recorder',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'High-Performance Screen & Dual Audio Capture',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: _openLibrarySheet,
                  icon: const Icon(Icons.video_library_rounded, size: 18),
                  label: Text('Recordings (${service.recordings.length})'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Preferences',
                icon: const Icon(Icons.tune_rounded, color: Colors.white70),
                onPressed: _openSettingsDialog,
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RecordingPreviewStage(service: service),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.graphic_eq_rounded,
                                color: Color(0xFFFF7A00),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Audio Capture Configuration',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            isRecording
                                ? 'Live audio streaming active'
                                : 'Configure background sound & mic',
                            style: TextStyle(
                              fontSize: 12,
                              color: isRecording
                                  ? const Color(0xFFFF7A00)
                                  : Colors.white38,
                              fontWeight: isRecording
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 700;
                          final cards = [
                            // 1. BACKGROUND SOUND (System Audio) CARD
                            AudioControlCard(
                              title: 'Background Sound',
                              subtitle:
                                  'Captures games, media, YouTube & internal audio',
                              icon: Icons.headphones_rounded,
                              isEnabled: service.settings.recordBackgroundSound,
                              onToggle: (val) =>
                                  service.toggleBackgroundSound(val),
                              volume:
                                  service.settings.backgroundSoundVolume,
                              onVolumeChanged: (val) =>
                                  service.setBackgroundSoundVolume(val),
                              audioLevel: service.bgSoundLevel,
                              primaryColor: const Color(0xFFFF5722),
                              accentColor: const Color(0xFFFF9100),
                              deviceLabel:
                                  'System Audio Output (Speakers / Headphones)',
                            ),

                            // 2. MICROPHONE CARD
                            AudioControlCard(
                              title: 'Microphone Audio',
                              subtitle:
                                  'Captures voice commentary & external sound',
                              icon: Icons.mic_rounded,
                              isEnabled: service.settings.recordMic,
                              onToggle: (val) => service.toggleMic(val),
                              volume: service.settings.micVolume,
                              onVolumeChanged: (val) =>
                                  service.setMicVolume(val),
                              audioLevel: service.micLevel,
                              primaryColor: const Color(0xFF00B0FF),
                              accentColor: const Color(0xFF00E5FF),
                              deviceLabel:
                                  'Default Microphone Input (Speech / Aux)',
                            ),
                          ];

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: cards[0]),
                                const SizedBox(width: 16),
                                Expanded(child: cards[1]),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                cards[0],
                                const SizedBox(height: 14),
                                cards[1],
                              ],
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          const Text(
                            'Capture Source: ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: CaptureSource.values.map((source) {
                                final selected =
                                    service.settings.captureSource == source;
                                return ChoiceChip(
                                  label: Text(source.title),
                                  selected: selected,
                                  selectedColor: const Color(0xFFFF5722),
                                  backgroundColor: const Color(0xFF131A29),
                                  labelStyle: TextStyle(
                                    color:
                                        selected ? Colors.white : Colors.white60,
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                  onSelected: (_) {
                                    service.toggleCaptureSource(source);
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              _buildBottomActionBar(
                service: service,
                isRecording: isRecording,
                isPaused: isPaused,
                isCountingDown: isCountingDown,
                isFinalizing: isFinalizing,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomActionBar({
    required RecordingService service,
    required bool isRecording,
    required bool isPaused,
    required bool isCountingDown,
    required bool isFinalizing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C111C),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isRecording || isPaused) ...[
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => service.cancelRecording(),
                icon: const Icon(Icons.close_rounded, size: 20),
                label: const Text('Discard'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E283D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (isPaused) {
                    service.resumeRecording();
                  } else {
                    service.pauseRecording();
                  }
                },
                icon: Icon(
                  isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  size: 20,
                  color: isPaused ? Colors.amber : Colors.white,
                ),
                label: Text(isPaused ? 'Resume' : 'Pause'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 8,
                  shadowColor: Colors.redAccent.withValues(alpha: 0.5),
                ),
                onPressed: () async {
                  await service.stopRecording();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF1A233A),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        content: const Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF00E676),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Screen recording saved successfully!',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        action: SnackBarAction(
                          label: 'View Library',
                          textColor: const Color(0xFFFF7A00),
                          onPressed: _openLibrarySheet,
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.stop_rounded, size: 24),
                label: const Text(
                  'Stop Recording',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else if (isFinalizing) ...[
              const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFFFF5722),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Encoding video & mixing audio tracks...',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ] else if (isCountingDown) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white12,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => service.cancelRecording(),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Cancel Countdown'),
              ),
            ] else ...[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF3D00), Color(0xFFFF9100)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5722).withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () => service.startRecording(),
                  icon: const Icon(
                    Icons.fiber_manual_record_rounded,
                    size: 26,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'START RECORDING',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
