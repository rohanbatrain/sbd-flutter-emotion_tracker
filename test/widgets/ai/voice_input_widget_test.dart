import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/widgets/ai/voice_input_widget.dart';
import 'package:emotion_tracker/providers/ai/voice_service.dart';

void main() {
  group('VoiceInputWidget Tests', () {
    Widget createTestWidget(Widget child) {
      return ProviderScope(
        overrides: [
          voiceRecordingStateProvider.overrideWith((ref) => MockVoiceRecordingStateNotifier()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: child,
          ),
        ),
      );
    }

    testWidgets('should display record button when idle', (tester) async {
      // Act
      await tester.pumpWidget(
        createTestWidget(
          VoiceInputWidget(
            onVoiceMessage: (audioData) {},
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should start recording when record button is pressed', (tester) async {
      // Arrange
      bool recordingStarted = false;
      final mockNotifier = MockVoiceRecordingStateNotifier();
      mockNotifier.onStartRecording = () => recordingStarted = true;

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceRecordingStateProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: VoiceInputWidget(
                onVoiceMessage: (audioData) {},
              ),
            ),
          ),
        ),
      );

      // Tap the record button
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();

      // Assert
      expect(recordingStarted, isTrue);
    });

    testWidgets('should display recording state with animation', (tester) async {
      // Arrange
      final mockNotifier = MockVoiceRecordingStateNotifier();
      mockNotifier.setState(const VoiceRecordingState(
        status: VoiceRecordingStatus.recording,
        duration: Duration(seconds: 5),
        amplitude: 0.7,
      ));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceRecordingStateProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: VoiceInputWidget(
                onVoiceMessage: (audioData) {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.text('00:05'), findsOneWidget);
      expect(find.byType(AnimatedContainer), findsWidgets);
    });

    testWidgets('should stop recording when stop button is pressed', (tester) async {
      // Arrange
      bool recordingStopped = false;
      final mockNotifier = MockVoiceRecordingStateNotifier();
      mockNotifier.setState(const VoiceRecordingState(
        status: VoiceRecordingStatus.recording,
        duration: Duration(seconds: 3),
      ));
      mockNotifier.onStopRecording = () => recordingStopped = true;

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceRecordingStateProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: VoiceInputWidget(
                onVoiceMessage: (audioData) {},
              ),
            ),
          ),
        ),
      );

      // Tap the stop button
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();

      // Assert
      expect(recordingStopped, isTrue);
    });

    testWidgets('should cancel recording on long press', (tester) async {
      // Arrange
      bool recordingCancelled = false;
      final mockNotifier = MockVoiceRecordingStateNotifier();
      mockNotifier.setState(const VoiceRecordingState(
        status: VoiceRecordingStatus.recording,
        duration: Duration(seconds: 2),
      ));
      mockNotifier.onCancelRecording = () => recordingCancelled = true;

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceRecordingStateProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: VoiceInputWidget(
                onVoiceMessage: (audioData) {},
              ),
            ),
          ),
        ),
      );

      // Long press the stop button
      await tester.longPress(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();

      // Assert
      expect(recordingCancelled, isTrue);
    });

    testWidgets('should display processing state', (tester) async {
      // Arrange
      final mockNotifier = MockVoiceRecordingStateNotifier();
      mockNotifier.setState(const VoiceRecordingState(
        status: VoiceRecordingStatus.processing,
        duration: Duration(seconds: 8),
      ));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceRecordingStateProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: VoiceInputWidget(
                onVoiceMessage: (audioData) {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Processing...'), findsOneWidget);
      expect(find.text('00:08'), findsOneWidget);
    });

    testWidgets('should call onVoiceMessage when recording completes', (tester) async {
      // Arrange
      String? receivedAudioData;
      final mockNotifier = MockVoiceRecordingStateNotifier();

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceRecordingStateProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: VoiceInputWidget(
                onVoiceMessage: (audioData) => receivedAudioData = audioData,
              ),
            ),
          ),
        ),
      );

      // Simulate recording completion
      mockNotifier.setState(const VoiceRecordingState(
        status: VoiceRecordingStatus.completed,
        base64Data: 'test-audio-data-base64',
        duration: Duration(seconds: 5),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(receivedAudioData, equals('test-audio-data-base64'));
    });

    testWidgets('should display error state', (tester) async {
      // Arrange
      final mockNotifier = MockVoiceRecordingStateNotifier();
      mockNotifier.setState(const VoiceRecordingState(
        status: VoiceRecordingStatus.error,
        errorMessage: 'Recording failed',
      ));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceRecordingStateProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: VoiceInputWidget(
                onVoiceMessage: (audioData) {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Recording failed'), findsOneWidget);
      expect(find.text('Tap to retry'), findsOneWidget);
    });

    testWidgets('should retry recording after error', (tester) async {
      // Arrange
      bool retryAttempted = false;
      final mockNotifier = MockVoiceRecordingStateNotifier();
      mockNotifier.setState(const VoiceRecordingState(
        status: VoiceRecordingStatus.error,
        errorMessage: 'Recording failed',
      ));
      mockNotifier.onStartRecording = () => retryAttempted = true;

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceRecordingStateProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: VoiceInputWidget(
                onVoiceMessage: (audioData) {},
              ),
            ),
          ),
        ),
      );

      // Tap to retry
      await tester.tap(find.byIcon(Icons.error));
      await tester.pumpAndSettle();

      // Assert
      expect(retryAttempted, isTrue);
    });

    testWidgets('should display permission denied state', (tester) async {
      // Arrange
      final mockNotifier = MockVoiceRecordingStateNotifier();
      mockNotifier.setState(const VoiceRecordingState(
        status: VoiceRecordingStatus.permission_denied,
        errorMessage: 'Microphone permission denied',
      ));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceRecordingStateProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: VoiceInputWidget(
                onVoiceMessage: (audioData) {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.mic_off), findsOneWidget);
      expect(find.text('Permission Required'), findsOneWidget);
      expect(find.text('Tap to grant microphone access'), findsOneWidget);
    });

    testWidgets('should request permission when permission denied', (tester) async {
      // Arrange
      bool permissionRequested = false;
      final mockNotifier = MockVoiceRecordingStateNotifier();
      mockNotifier.setState(const VoiceRecordingState(
        status: VoiceRecordingStatus.permission_denied,
      ));
      mockNotifier.onStartRecording = () => permissionRequested = true;

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceRecordingStateProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: VoiceInputWidget(
                onVoiceMessage: (audioData) {},
              ),
            ),
          ),
        ),
      );

      // Tap to request permission
      await tester.tap(find.byIcon(Icons.mic_off));
      await tester.pumpAndSettle();

      // Assert
      expect(permissionRequested, isTrue);
    });

    testWidgets('should display requesting permission state', (tester) async {
      // Arrange
      final mockNotifier = MockVoiceRecordingStateNotifier();
      mockNotifier.setState(const VoiceRecordingState(
        status: VoiceRecordingStatus.requesting_permission,
      ));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceRecordingStateProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: VoiceInputWidget(
                onVoiceMessage: (audioData) {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Requesting permission...'), findsOneWidget);
    });

    testWidgets('should format duration correctly', (tester) async {
      // Arrange
      final mockNotifier = MockVoiceRecordingStateNotifier();
      mockNotifier.setState(const VoiceRecordingState(
        status: VoiceRecordingStatus.recording,
        duration: Duration(minutes: 1, seconds: 23),
      ));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceRecordingStateProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: VoiceInputWidget(
                onVoiceMessage: (audioData) {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('01:23'), findsOneWidget);
    });

    testWidgets('should display amplitude visualization', (tester) async {
      // Arrange
      final mockNotifier = MockVoiceRecordingStateNotifier();
      mockNotifier.setState(const VoiceRecordingState(
        status: VoiceRecordingStatus.recording,
        amplitude: 0.8,
        duration: Duration(seconds: 3),
      ));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceRecordingStateProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: VoiceInputWidget(
                onVoiceMessage: (audioData) {},
              ),
            ),
          ),
        ),
      );

      // Assert - Check for amplitude visualization elements
      expect(find.byType(AnimatedContainer), findsWidgets);
    });

    testWidgets('should handle compact mode', (tester) async {
      // Act
      await tester.pumpWidget(
        createTestWidget(
          VoiceInputWidget(
            onVoiceMessage: (audioData) {},
            compact: true,
          ),
        ),
      );

      // Assert - Should render in compact mode
      expect(find.byType(VoiceInputWidget), findsOneWidget);
    });

    testWidgets('should handle disabled state', (tester) async {
      // Act
      await tester.pumpWidget(
        createTestWidget(
          VoiceInputWidget(
            onVoiceMessage: (audioData) {},
            enabled: false,
          ),
        ),
      );

      // Assert - Button should be disabled
      final button = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('should apply custom colors', (tester) async {
      // Act
      await tester.pumpWidget(
        createTestWidget(
          VoiceInputWidget(
            onVoiceMessage: (audioData) {},
            primaryColor: Colors.red,
            backgroundColor: Colors.blue,
          ),
        ),
      );

      // Assert - Should render with custom colors
      expect(find.byType(VoiceInputWidget), findsOneWidget);
    });

    testWidgets('should handle maximum recording duration', (tester) async {
      // Arrange
      final mockNotifier = MockVoiceRecordingStateNotifier();
      mockNotifier.setState(const VoiceRecordingState(
        status: VoiceRecordingStatus.recording,
        duration: Duration(minutes: 5), // Max duration reached
      ));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceRecordingStateProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: VoiceInputWidget(
                onVoiceMessage: (audioData) {},
                maxDuration: const Duration(minutes: 5),
              ),
            ),
          ),
        ),
      );

      // Assert - Should show max duration reached
      expect(find.text('05:00'), findsOneWidget);
    });

    testWidgets('should show hint text when provided', (tester) async {
      // Act
      await tester.pumpWidget(
        createTestWidget(
          VoiceInputWidget(
            onVoiceMessage: (audioData) {},
            hintText: 'Hold to record voice message',
          ),
        ),
      );

      // Assert
      expect(find.text('Hold to record voice message'), findsOneWidget);
    });

    testWidgets('should handle onError callback', (tester) async {
      // Arrange
      String? errorMessage;
      final mockNotifier = MockVoiceRecordingStateNotifier();
      mockNotifier.setState(const VoiceRecordingState(
        status: VoiceRecordingStatus.error,
        errorMessage: 'Test error',
      ));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            voiceRecordingStateProvider.overrideWith((ref) => mockNotifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: VoiceInputWidget(
                onVoiceMessage: (audioData) {},
                onError: (error) => errorMessage = error,
              ),
            ),
          ),
        ),
      );

      // Assert - Error callback should be triggered
      expect(errorMessage, equals('Test error'));
    });
  });
}

/// Mock Voice Recording State Notifier for testing
class MockVoiceRecordingStateNotifier extends StateNotifier<VoiceRecordingState> {
  MockVoiceRecordingStateNotifier() : super(const VoiceRecordingState());

  VoidCallback? onStartRecording;
  VoidCallback? onStopRecording;
  VoidCallback? onCancelRecording;

  void setState(VoiceRecordingState newState) {
    state = newState;
  }

  @override
  Future<void> startRecording() async {
    onStartRecording?.call();
    state = state.copyWith(status: VoiceRecordingStatus.recording);
  }

  @override
  Future<void> stopRecording() async {
    onStopRecording?.call();
    state = state.copyWith(status: VoiceRecordingStatus.completed);
  }

  @override
  Future<void> cancelRecording() async {
    onCancelRecording?.call();
    state = const VoiceRecordingState();
  }

  @override
  void reset() {
    state = const VoiceRecordingState();
  }
}