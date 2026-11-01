import 'package:flutter/material.dart';
import 'audio_visualizer.dart';

class AudioControlCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isEnabled;
  final ValueChanged<bool> onToggle;
  final double volume;
  final ValueChanged<double> onVolumeChanged;
  final double audioLevel;
  final Color primaryColor;
  final Color accentColor;
  final String deviceLabel;

  const AudioControlCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isEnabled,
    required this.onToggle,
    required this.volume,
    required this.onVolumeChanged,
    required this.audioLevel,
    required this.primaryColor,
    required this.accentColor,
    required this.deviceLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131A29).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isEnabled
              ? primaryColor.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: [
          if (isEnabled)
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.12),
              blurRadius: 16,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Icon, Title, Subtitle, Switch
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isEnabled
                        ? [primaryColor, accentColor]
                        : [Colors.white12, Colors.white10],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    if (isEnabled)
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: isEnabled ? Colors.white : Colors.white54,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isEnabled
                                ? primaryColor.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isEnabled
                                  ? primaryColor.withValues(alpha: 0.5)
                                  : Colors.white12,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isEnabled ? 'ON' : 'OFF',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isEnabled ? accentColor : Colors.white38,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Big Switch toggle
              Transform.scale(
                scale: 1.1,
                child: Switch(
                  value: isEnabled,
                  onChanged: onToggle,
                  activeThumbColor: Colors.white,
                  activeTrackColor: primaryColor,
                  inactiveThumbColor: Colors.white38,
                  inactiveTrackColor: Colors.white12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Live Equalizer Visualizer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0C111C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEnabled ? 'Live Audio Stream' : 'Audio Input Disabled',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isEnabled
                            ? primaryColor.withValues(alpha: 0.9)
                            : Colors.white24,
                      ),
                    ),
                    Text(
                      isEnabled
                          ? '${(audioLevel * 100).toInt()}% dB'
                          : 'MUTED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isEnabled ? accentColor : Colors.white24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AudioVisualizer(
                  isEnabled: isEnabled,
                  level: audioLevel,
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                  barCount: 22,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Volume Slider and Device badge
          Row(
            children: [
              Icon(
                isEnabled
                    ? (volume > 0 ? Icons.volume_up_rounded : Icons.volume_mute_rounded)
                    : Icons.volume_off_rounded,
                size: 18,
                color: isEnabled ? primaryColor : Colors.white30,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: primaryColor,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: accentColor,
                    overlayColor: primaryColor.withValues(alpha: 0.2),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                  ),
                  child: Slider(
                    value: volume,
                    min: 0.0,
                    max: 1.0,
                    onChanged: isEnabled ? onVolumeChanged : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 42,
                child: Text(
                  isEnabled ? '${(volume * 100).toInt()}%' : '--',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isEnabled ? Colors.white70 : Colors.white24,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Device Tag
          Row(
            children: [
              Icon(
                Icons.device_hub_rounded,
                size: 13,
                color: Colors.white.withValues(alpha: 0.35),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  deviceLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.4),
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
