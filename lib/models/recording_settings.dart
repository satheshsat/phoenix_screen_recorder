enum VideoResolution {
  res720p('1280x720', '720p HD', 1280, 720),
  res1080p('1920x1080', '1080p Full HD', 1920, 1080),
  res1440p('2560x1440', '2K QHD', 2560, 1440),
  res4k('3840x2160', '4K UHD', 3840, 2160);

  final String label;
  final String title;
  final int width;
  final int height;

  const VideoResolution(this.label, this.title, this.width, this.height);
}

enum CaptureSource {
  fullScreen('Full Screen', 'Entire desktop display'),
  activeWindow('Active Window', 'Single application window'),
  customArea('Custom Region', 'Selected screen rectangle');

  final String title;
  final String description;

  const CaptureSource(this.title, this.description);
}

class RecordingSettings {
  final VideoResolution resolution;
  final int frameRate; // 30 or 60
  final int videoBitrateMbps; // 4, 8, 16
  final CaptureSource captureSource;
  final bool recordBackgroundSound; // System audio / internal sound
  final double backgroundSoundVolume; // 0.0 to 1.0
  final bool recordMic; // Microphone sound
  final double micVolume; // 0.0 to 1.5
  final bool showCursor;
  final int countdownSeconds; // 0, 3, 5

  const RecordingSettings({
    this.resolution = VideoResolution.res1080p,
    this.frameRate = 30,
    this.videoBitrateMbps = 6,
    this.captureSource = CaptureSource.fullScreen,
    this.recordBackgroundSound = true,
    this.backgroundSoundVolume = 1.0,
    this.recordMic = true,
    this.micVolume = 1.0,
    this.showCursor = true,
    this.countdownSeconds = 3,
  });

  RecordingSettings copyWith({
    VideoResolution? resolution,
    int? frameRate,
    int? videoBitrateMbps,
    CaptureSource? captureSource,
    bool? recordBackgroundSound,
    double? backgroundSoundVolume,
    bool? recordMic,
    double? micVolume,
    bool? showCursor,
    int? countdownSeconds,
  }) {
    return RecordingSettings(
      resolution: resolution ?? this.resolution,
      frameRate: frameRate ?? this.frameRate,
      videoBitrateMbps: videoBitrateMbps ?? this.videoBitrateMbps,
      captureSource: captureSource ?? this.captureSource,
      recordBackgroundSound:
          recordBackgroundSound ?? this.recordBackgroundSound,
      backgroundSoundVolume:
          backgroundSoundVolume ?? this.backgroundSoundVolume,
      recordMic: recordMic ?? this.recordMic,
      micVolume: micVolume ?? this.micVolume,
      showCursor: showCursor ?? this.showCursor,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
    );
  }
}
