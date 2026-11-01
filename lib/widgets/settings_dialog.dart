import 'package:flutter/material.dart';
import '../models/recording_settings.dart';
import '../services/recording_service.dart';

class SettingsDialog extends StatefulWidget {
  final RecordingService service;

  const SettingsDialog({super.key, required this.service});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late RecordingSettings _tempSettings;

  @override
  void initState() {
    super.initState();
    _tempSettings = widget.service.settings;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111726),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: Color(0xFFFF7A00),
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Recording Preferences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white60),
                ),
              ],
            ),
            const SizedBox(height: 18),

            const Text(
              'Video Resolution',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: VideoResolution.values.map((res) {
                final selected = _tempSettings.resolution == res;
                return ChoiceChip(
                  label: Text(res.title),
                  selected: selected,
                  selectedColor: const Color(0xFFFF5722),
                  backgroundColor: const Color(0xFF182236),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _tempSettings = _tempSettings.copyWith(resolution: res);
                      });
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            const Text(
              'Frame Rate (FPS)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [30, 60].map((fps) {
                final selected = _tempSettings.frameRate == fps;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$fps FPS'),
                    selected: selected,
                    selectedColor: const Color(0xFFFF5722),
                    backgroundColor: const Color(0xFF182236),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _tempSettings = _tempSettings.copyWith(frameRate: fps);
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            const Text(
              'Countdown Timer',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [0, 3, 5].map((sec) {
                final selected = _tempSettings.countdownSeconds == sec;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(sec == 0 ? 'No Countdown' : '$sec Seconds'),
                    selected: selected,
                    selectedColor: const Color(0xFFFF5722),
                    backgroundColor: const Color(0xFF182236),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _tempSettings =
                              _tempSettings.copyWith(countdownSeconds: sec);
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 22),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    widget.service.updateSettings(_tempSettings);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Apply Settings',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
