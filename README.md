# sbd-flutter-emotion_tracker

The **Emotion Tracker** is a mobile application built with Flutter designed to help users track and analyze their emotional well-being. It integrates with the Second Brain ecosystem to provide insights and personalized recommendations.

## Features

-   **Emotion Logging**: Easily log daily emotions and moods.
-   **Biometric Security**: Secure access using `local_auth` (FaceID/TouchID).
-   **Data Visualization**: View emotional trends over time.
-   **QR Code Integration**: Scan and generate QR codes for sharing data.
-   **Secure Storage**: Encrypted local storage using `flutter_secure_storage`.

## Tech Stack

-   **Framework**: [Flutter](https://flutter.dev/)
-   **Language**: Dart
-   **State Management**: [Riverpod](https://riverpod.dev/)
-   **Networking**: Dio, HTTP
-   **Storage**: Flutter Secure Storage, Shared Preferences
-   **Animations**: Lottie
-   **Ads**: Google Mobile Ads

## Prerequisites

-   [Flutter SDK](https://docs.flutter.dev/get-started/install)
-   Android Studio or Xcode (for mobile development)

## Getting Started

1.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

2.  **Run the application**:
    ```bash
    flutter run
    ```

3.  **Generate code (if needed)**:
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

## Project Structure

-   `lib/`: Main Dart code.
-   `assets/`: Images, fonts, and Lottie animations.
-   `test/`: Unit and widget tests.

## License

Private
