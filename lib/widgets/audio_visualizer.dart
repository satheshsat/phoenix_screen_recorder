import 'dart:math';
import 'package:flutter/material.dart';

class AudioVisualizer extends StatefulWidget {
  final bool isEnabled;
  final double level; // 0.0 to 1.0
  final Color primaryColor;
  final Color accentColor;
  final int barCount;

  const AudioVisualizer({
    super.key,
    required this.isEnabled,
    required this.level,
    required this.primaryColor,
    required this.accentColor,
    this.barCount = 18,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final Random _random = Random();
  late List<double> _barMultipliers;

  @override
  void initState() {
    super.initState();
    _barMultipliers = List.generate(
      widget.barCount,
      (i) => 0.4 + (_random.nextDouble() * 0.6),
    );
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    )..addListener(() {
        if (widget.isEnabled && mounted) {
          setState(() {
            for (int i = 0; i < _barMultipliers.length; i++) {
              final target = 0.3 + (_random.nextDouble() * 0.7);
              _barMultipliers[i] = (_barMultipliers[i] * 0.6) + (target * 0.4);
            }
          });
        }
      });
    _animController.repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: CustomPaint(
        painter: _VisualizerPainter(
          isEnabled: widget.isEnabled,
          level: widget.level,
          primaryColor: widget.primaryColor,
          accentColor: widget.accentColor,
          multipliers: _barMultipliers,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  final bool isEnabled;
  final double level;
  final Color primaryColor;
  final Color accentColor;
  final List<double> multipliers;

  _VisualizerPainter({
    required this.isEnabled,
    required this.level,
    required this.primaryColor,
    required this.accentColor,
    required this.multipliers,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = multipliers.length;
    final totalSpacing = size.width * 0.3;
    final barSpacing = totalSpacing / (barCount - 1);
    final barWidth = (size.width - totalSpacing) / barCount;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + barSpacing);
      double heightRatio;

      if (!isEnabled) {
        heightRatio = 0.08;
      } else {
        final centerDist = ((i - (barCount / 2)).abs()) / (barCount / 2);
        final envelope = 1.0 - (centerDist * 0.4);
        heightRatio = ((level * multipliers[i] * envelope)).clamp(0.12, 1.0);
      }

      final barHeight = size.height * heightRatio;
      final y = size.height - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(3),
      );

      if (isEnabled) {
        final gradient = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            primaryColor.withValues(alpha: 0.85),
            accentColor,
          ],
        );
        paint.shader = gradient.createShader(rect.outerRect);
      } else {
        paint.shader = null;
        paint.color = Colors.white.withValues(alpha: 0.12);
      }

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.isEnabled != isEnabled ||
        oldDelegate.multipliers != multipliers;
  }
}
