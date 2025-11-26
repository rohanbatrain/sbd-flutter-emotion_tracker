# Emotion Tracker

[![Netlify Status](https://api.netlify.com/api/v1/badges/f90782bd-d91d-4f17-8636-9b9307a7fbc2/deploy-status)](https://app.netlify.com/sites/emotion-tracker/deploys)
[![Docker Hub](https://img.shields.io/docker/v/rohanbatra/sbd-flutter-emotion_tracker-web?label=docker%20standard)](https://hub.docker.com/r/rohanbatra/sbd-flutter-emotion_tracker-web)
[![Docker Hub WASM](https://img.shields.io/docker/v/rohanbatra/sbd-flutter-emotion_tracker-web-wasm?label=docker%20wasm)](https://hub.docker.com/r/rohanbatra/sbd-flutter-emotion_tracker-web-wasm)

A Flutter-based emotion tracking application part of the Second Brain Database ecosystem.

## Features

- Cross-platform support (Web, Android, iOS, Linux, macOS, Windows)
- Emotion logging and visualization
- Data persistence with SharedPreferences
- Beautiful charts and analytics
- Responsive UI design

## Docker Deployment

The emotion tracker web application is available as Docker images in two variants:

### Standard Web Build (CanvasKit)
Uses the CanvasKit renderer with Dart compiled to JavaScript. Best for broad browser compatibility.

**Docker Hub:**
```bash
docker pull rohanbatra/sbd-flutter-emotion_tracker-web:latest
docker run -d -p 8080:80 --name emotion-tracker rohanbatra/sbd-flutter-emotion_tracker-web:latest
```

**GitHub Container Registry:**
```bash
docker pull ghcr.io/rohanbatrain/sbd-flutter-emotion_tracker:latest
docker run -d -p 8080:80 --name emotion-tracker ghcr.io/rohanbatrain/sbd-flutter-emotion_tracker:latest
```

### WASM Web Build (skwasm)
Uses the skwasm renderer with Dart compiled to WebAssembly. Best for performance-critical applications.

**Docker Hub:**
```bash
docker pull rohanbatra/sbd-flutter-emotion_tracker-web-wasm:latest
docker run -d -p 8080:80 --name emotion-tracker-wasm rohanbatra/sbd-flutter-emotion_tracker-web-wasm:latest
```

**GitHub Container Registry:**
```bash
docker pull ghcr.io/rohanbatrain/sbd-flutter-emotion_tracker/web-wasm:latest
docker run -d -p 8080:80 --name emotion-tracker-wasm ghcr.io/rohanbatrain/sbd-flutter-emotion_tracker/web-wasm:latest
```

### Multi-Platform Support
Both images support:
- `linux/amd64`
- `linux/arm64`

Docker will automatically pull the correct architecture for your system.

### Available Tags
- `latest` - Latest stable build from main branch
- `main` - Latest build from main branch
- `vX.Y.Z` - Specific version release
- `vX.Y` - Latest patch version
- `sha-<commit>` - Specific commit build

### Health Check
The nginx server includes a health check endpoint:
```bash
curl http://localhost:8080/health
```

## Development

### Prerequisites
- Flutter SDK 3.19.0 or higher
- Dart SDK 3.3.0 or higher

### Setup
```bash
flutter pub get
```

### Run Development Server
```bash
# Web
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios

# Linux
flutter run -d linux

# macOS
flutter run -d macos

# Windows
flutter run -d windows
```

### Build for Production

**Web:**
```bash
# Standard build
flutter build web --release

# WASM build
flutter build web --release --wasm
```

**Android:**
```bash
flutter build apk --release
flutter build appbundle --release
```

**Linux:**
```bash
flutter build linux --release
```

**macOS DMG:**
```bash
flutter build macos --release
cd build/macos/Build/Products/Release
hdiutil create -volname Emotion-Tracker -srcfolder Emotion\ Tracker.app -ov -format UDZO Emotion-Tracker.dmg
```

**macOS PKG:**
```bash
pkgbuild --identifier in.rohanbatra.emotion-tracker --version 1.0 --install-location /Applications --root ./Emotion\ Tracker.app Emotion_Tracker.pkg
```

## Testing
```bash
flutter test
```

## Linting & Formatting
```bash
# Check formatting
dart format --set-exit-if-changed .

# Analyze code
dart analyze

# Auto-format code
dart format .
```

## License
Part of the Second Brain Database ecosystem.

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md) for details.