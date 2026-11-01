# Phoenix Screen Recorder

A high-performance, modern cross-platform screen recording application built with Flutter featuring dual audio capture: **Background Sound (System Audio)** and **Microphone Audio**, live equalizer visualizers, configurable video presets, and a built-in recordings library.

---

## ✨ Features

- 🎥 **High-Definition Screen Recording**: Full desktop display, active window, or custom region recording with zero frame drops.
- 🎧 **Background Sound (System / Internal Audio) ON / OFF**:
  - Independent switch toggle to capture or mute internal sounds (YouTube, games, media players, system alerts).
  - Dedicated volume control slider (0% to 100%).
  - Real-time animated equalizer waveform bars responding to audio levels.
- 🎙️ **Microphone Audio ON / OFF**:
  - Independent switch toggle for commentary, voiceover, and external sound.
  - Dedicated mic volume & gain slider (0% to 150%).
  - Real-time animated spectrum analyzer visualizer.
- 🎛️ **Dual Audio Mixing Engine**:
  - When both Background Sound and Mic are enabled, audio tracks are mixed seamlessly using FFmpeg audio filters (`amix`).
  - When either source is disabled, only the active stream is recorded.
  - Clean video-only mode when both sound sources are turned off.
- ⏱️ **Live Viewfinder & Timer HUD**:
  - Camera-style reticle preview stage with pulsing recording beacon.
  - Live elapsed timer (`HH:MM:SS`), pause/resume controls, and countdown timer (0s, 3s, 5s).
- 📁 **Recordings Library**:
  - In-app gallery with recording metadata (resolution, duration, file size, audio tags).
  - One-click instant playback via default system player.
  - Quick reveal in file manager (`Show in Folder`).
  - Delete and management controls.
- ⚙️ **Customizable Preferences**:
  - Resolutions: 720p HD, 1080p Full HD, 2K QHD, 4K UHD.
  - Framerates: 30 FPS, 60 FPS.
  - Adjustable bitrates.

---

## 🚀 Running the App

```bash
# Get dependencies
flutter pub get

# Run on Linux desktop
flutter run -d linux

# Run tests
flutter test

# Run analyzer
flutter analyze
```

---

## 🛠️ Technology Stack & Architecture

- **UI Framework**: Flutter (Material 3 with custom dark obsidian & fiery phoenix design system)
- **State Management**: Reactive `ListenableBuilder` with `ChangeNotifier`
- **Native Video & Audio Pipeline**:
  - **Video Capture**: High-speed X11 capture via FFmpeg (`-f x11grab`, H.264 ultrafast)
  - **System Audio (Background Sound)**: PipeWire / PulseAudio sink monitor capture (`pw-record --target <sink>.monitor`)
  - **Microphone**: PipeWire / PulseAudio source capture (`pw-record <mic>`)
  - **Muxer & Mixer**: FFmpeg hardware-accelerated muxing with AAC audio encoding
