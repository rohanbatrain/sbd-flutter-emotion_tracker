# Contributing to SBD Flutter Emotion Tracker

## 🚀 Quick Start

```bash
git clone <repo-url>
cd sbd-flutter-emotion_tracker
flutter pub get
```

## 📝 Branch Naming Convention

**Format**: `<type>/<name>`

**Allowed Types**: `feat/`, `fix/`, `perf/`, `refactor/`, `docs/`, `chore/`, `hotfix/`, `release/`

## 💬 Commit Message Format

**Format**: `<type>: <message>`

Examples:
- ✅ `feat: add emotion tracking UI`
- ✅ `fix(db): resolve data persistence issue`

## 🔨 Development Workflow

```bash
# Create feature branch
git checkout -b feat/my-feature

# Develop
flutter run

# Format code
dart format .

# Analyze
dart analyze

# Test
flutter test

# Commit
git add .
git commit -m "feat: add my feature"

# Push
git push origin feat/my-feature
```

## 🔄 Pull Request Process

PR titles must follow: `<type>: <message>`

Automated CI checks:
- ✅ Branch name validation
- ✅ PR title validation
- ✅ Dart format check
- ✅ Dart analyze
- ✅ Flutter tests
- ✅ APK build verification

All checks must pass before merge!
