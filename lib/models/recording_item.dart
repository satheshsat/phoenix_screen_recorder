import 'dart:io';

class RecordingItem {
  final String id;
  final String title;
  final String filePath;
  final DateTime createdAt;
  final Duration duration;
  final int fileSizeBytes;
  final bool hasSystemAudio;
  final bool hasMicAudio;
  final String resolution;

  const RecordingItem({
    required this.id,
    required this.title,
    required this.filePath,
    required this.createdAt,
    required this.duration,
    required this.fileSizeBytes,
    required this.hasSystemAudio,
    required this.hasMicAudio,
    required this.resolution,
  });

  String get formattedFileSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSizeBytes < 1024 * 1024 * 1024) {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get formattedDuration {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  bool get exists => File(filePath).existsSync();
}
