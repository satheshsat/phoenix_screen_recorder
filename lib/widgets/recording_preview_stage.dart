import 'package:flutter/material.dart';
import '../models/recording_settings.dart';
import '../services/recording_service.dart';

class RecordingPreviewStage extends StatelessWidget {
  final RecordingService service;

  const RecordingPreviewStage({super.key, required this.service});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final state = service.state;
    final isRecording = state == RecordingState.recording;
    final isPaused = state == RecordingState.paused;
    final isCountingDown = state == RecordingState.countingDown;

    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFF0D131F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isRecording
              ? const Color(0xFFFF3D00).withValues(alpha: 0.6)
              : (isPaused
                  ? Colors.amber.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.08)),
          width: isRecording ? 2 : 1.2,
        ),
        boxShadow: [
          if (isRecording)
            BoxShadow(
              color: const Color(0xFFFF3D00).withValues(alpha: 0.18),
              blurRadius: 24,
              spreadRadius: 2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          children: [
            // Background grid pattern simulation
            Positioned.fill(
              child: CustomPaint(
                painter: _StageGridPainter(),
              ),
            ),

            // Subtle Phoenix logo watermark in center
            Center(
              child: Opacity(
                opacity: isRecording ? 0.08 : 0.15,
                child: Image.asset(
                  'assets/icon/icon.png',
                  width: 140,
                  height: 140,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.screen_share_rounded,
                    size: 90,
                    color: Colors.white24,
                  ),
                ),
              ),
            ),

            // Top Status Bar in Stage
            Positioned(
              top: 16,
              left: 18,
              right: 18,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isRecording
                          ? const Color(0xFFFF3D00).withValues(alpha: 0.2)
                          : (isPaused
                              ? Colors.amber.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.06)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isRecording
                            ? const Color(0xFFFF3D00)
                            : (isPaused ? Colors.amber : Colors.white24),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isRecording
                                ? const Color(0xFFFF3D00)
                                : (isPaused ? Colors.amber : const Color(0xFF00E5FF)),
                            boxShadow: [
                              if (isRecording)
                                BoxShadow(
                                  color: const Color(0xFFFF3D00).withValues(alpha: 0.8),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          isRecording
                              ? 'LIVE RECORDING'
                              : (isPaused
                                  ? 'PAUSED'
                                  : (isCountingDown
                                      ? 'STARTING...'
                                      : 'DISPLAY READY')),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: isRecording
                                ? const Color(0xFFFF5722)
                                : (isPaused ? Colors.amber : Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Display resolution & FPS tags
                  Row(
                    children: [
                      _tag(service.settings.resolution.label),
                      const SizedBox(width: 6),
                      _tag('${service.settings.frameRate} FPS'),
                    ],
                  ),
                ],
              ),
            ),

            // Center Content: Countdown or Live Timer or Ready State
            Center(
              child: isCountingDown
                  ? _buildCountdown(service.countdown)
                  : (isRecording || isPaused)
                      ? _buildRecordingTimer(service.elapsed, isPaused)
                      : _buildIdleCenter(service.settings),
            ),

            // Bottom Audio Track Status Pills
            Positioned(
              bottom: 14,
              left: 18,
              right: 18,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _audioPill(
                        icon: Icons.headphones_rounded,
                        label: 'Background Sound',
                        isEnabled: service.settings.recordBackgroundSound,
                        activeColor: const Color(0xFFFF7A00),
                      ),
                      const SizedBox(width: 8),
                      _audioPill(
                        icon: Icons.mic_rounded,
                        label: 'Microphone',
                        isEnabled: service.settings.recordMic,
                        activeColor: const Color(0xFF00E5FF),
                      ),
                    ],
                  ),
                  Text(
                    service.settings.captureSource.title,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Corner viewfinder marks
            const Positioned(
              top: 10,
              left: 10,
              child: _CornerMark(rotation: 0),
            ),
            const Positioned(
              top: 10,
              right: 10,
              child: _CornerMark(rotation: 90),
            ),
            const Positioned(
              bottom: 10,
              left: 10,
              child: _CornerMark(rotation: 270),
            ),
            const Positioned(
              bottom: 10,
              right: 10,
              child: _CornerMark(rotation: 180),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdown(int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFF5722),
            shadows: [
              Shadow(
                color: Color(0xFFFF3D00),
                blurRadius: 30,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Get Ready...',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingTimer(Duration duration, bool isPaused) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatDuration(duration),
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
            color: isPaused ? Colors.amber : Colors.white,
            letterSpacing: 2,
            shadows: [
              BoxShadow(
                color: isPaused
                    ? Colors.amber.withValues(alpha: 0.4)
                    : const Color(0xFFFF5722).withValues(alpha: 0.5),
                blurRadius: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isPaused ? 'Recording Paused' : 'Capturing Display & Selected Audio',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isPaused ? Colors.amber.shade200 : Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget _buildIdleCenter(RecordingSettings settings) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFF7A00).withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.videocam_rounded,
            size: 32,
            color: Color(0xFFFF7A00),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Ready to Record',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select your audio sources and press Start Recording',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white60,
        ),
      ),
    );
  }

  Widget _audioPill({
    required IconData icon,
    required String label,
    required bool isEnabled,
    required Color activeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isEnabled ? activeColor.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: isEnabled ? activeColor.withValues(alpha: 0.4) : Colors.white10,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isEnabled ? activeColor : Colors.white30,
          ),
          const SizedBox(width: 5),
          Text(
            '$label: ${isEnabled ? "ON" : "OFF"}',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isEnabled ? activeColor : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerMark extends StatelessWidget {
  final double rotation;
  const _CornerMark({required this.rotation});

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: (rotation / 90).round(),
      child: SizedBox(
        width: 14,
        height: 14,
        child: CustomPaint(
          painter: _CornerPainter(),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF7A00).withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StageGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 1;

    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
