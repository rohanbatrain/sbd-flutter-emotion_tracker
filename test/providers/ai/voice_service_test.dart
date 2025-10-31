import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/ai/voice_service.dart';

void main() {
  group('VoiceService', () {
    late ProviderContainer container;
    late VoiceService voiceService;

    setUp(() {
      container = ProviderContainer();
      voiceService = container.read(voiceServiceProvider);
    });

    tearDown(() {
      voiceService.dispose();
      container.dispose();
    });

    group('Permission Management', () {
      test('should handle microphone permission check', () async {
        // Act
        final hasPermission = await voiceService.hasMicrophonePermission();

        // Assert - Should not throw and return a boolean
        expect(hasPermission, isA<bool>());
      });

      test('should handle microphone permission request', () async {
        // Act
        final granted = await voiceService.requestMicrophonePermission();

        // Assert - Should not throw and return a boolean
        expect(granted, isA<bool>());
      });
    });

    group('Recording Management', () {
      test('should handle recording state checks', () async {
        // Act
        final isRecording = await voiceService.isRecording();

        // Assert
        expect(isRecording, isFalse); // Should not be recording initially
      });

      test('should handle amplitude measurement', () async {
        // Act
        final amplitude = await voiceService.getAmplitude();

        // Assert
        expect(amplitude, isA<double>());
        expect(amplitude, greaterThanOrEqualTo(0.0));
        expect(amplitude, lessThanOrEqualTo(1.0));
      });

      test('should handle recording cancellation', () async {
        // Act & Assert - Should not throw
        await expectLater(
          voiceService.cancelRecording(),
          completes,
        );
      });
    });

    group('Playback Management', () {
      test('should handle playback state checks', () {
        // Act & Assert
        expect(voiceService.isPlaying, isFalse);
        expect(voiceService.isPaused, isFalse);
      });

      test('should handle playback control', () async {
        // Act & Assert - Should not throw
        await expectLater(voiceService.pausePlayback(), completes);
        await expectLater(voiceService.resumePlayback(), completes);
        await expectLater(voiceService.stopPlayback(), completes);
      });

      test('should handle seek operations', () async {
        // Act & Assert - Should not throw
        await expectLater(
          voiceService.seekTo(const Duration(seconds: 10)),
          completes,
        );
      });

      test('should handle position and duration queries', () async {
        // Act
        final position = await voiceService.getCurrentPosition();
        final duration = await voiceService.getDuration();

        // Assert - Should return Duration or null
        expect(position, anyOf(isA<Duration>(), isNull));
        expect(duration, anyOf(isA<Duration>(), isNull));
      });
    });

    group('Audio Processing', () {
      test('should handle base64 conversion with non-existent file', () async {
        // Act
        final base64Data = await voiceService.convertToBase64('/non/existent/file.m4a');

        // Assert
        expect(base64Data, isNull);
      });

      test('should handle audio playback from invalid base64', () async {
        // Act
        final success = await voiceService.playAudioFromBase64('invalid-base64', 'test-message');

        // Assert
        expect(success, isFalse);
      });

      test('should handle audio playback from non-existent file', () async {
        // Act
        final success = await voiceService.playAudioFromFile('/non/existent/file.m4a');

        // Assert
        expect(success, isFalse);
      });
    });

    group('Cache Management', () {
      test('should handle cache cleanup', () async {
        // Act & Assert - Should not throw
        await expectLater(
          voiceService.cleanupTempFiles(),
          completes,
        );

        await expectLater(
          voiceService.cleanupTempFiles(keepRecentTTS: false),
          completes,
        );
      });

      test('should provide cache statistics', () async {
        // Act
        final stats = await voiceService.getCacheStats();

        // Assert
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('voice_recordings'), isTrue);
        expect(stats.containsKey('tts_files'), isTrue);
        expect(stats.containsKey('total_size_bytes'), isTrue);
        expect(stats.containsKey('total_size_mb'), isTrue);
      });
    });

    group('Stream Access', () {
      test('should provide audio streams', () {
        // Act & Assert
        expect(voiceService.playerStateStream, isNotNull);
        expect(voiceService.positionStream, isNotNull);
        expect(voiceService.durationStream, isNotNull);
      });
    });
  });

  group('VoiceRecordingState', () {
    test('should create with default values', () {
      // Act
      const state = VoiceRecordingState();

      // Assert
      expect(state.status, equals(VoiceRecordingStatus.idle));
      expect(state.duration, isNull);
      expect(state.amplitude, isNull);
      expect(state.filePath, isNull);
      expect(state.base64Data, isNull);
      expect(state.errorMessage, isNull);
    });

    test('should copy with updated values', () {
      // Arrange
      const original = VoiceRecordingState();

      // Act
      final updated = original.copyWith(
        status: VoiceRecordingStatus.recording,
        duration: const Duration(seconds: 5),
        amplitude: 0.5,
      );

      // Assert
      expect(updated.status, equals(VoiceRecordingStatus.recording));
      expect(updated.duration, equals(const Duration(seconds: 5)));
      expect(updated.amplitude, equals(0.5));
      expect(updated.filePath, isNull); // Unchanged
    });

    test('should provide correct state checks', () {
      // Arrange
      const recordingState = VoiceRecordingState(status: VoiceRecordingStatus.recording);
      const processingState = VoiceRecordingState(status: VoiceRecordingStatus.processing);
      const errorState = VoiceRecordingState(status: VoiceRecordingStatus.error);
      const completedState = VoiceRecordingState(status: VoiceRecordingStatus.completed);
      const idleState = VoiceRecordingState(status: VoiceRecordingStatus.idle);

      // Assert
      expect(recordingState.isRecording, isTrue);
      expect(processingState.isProcessing, isTrue);
      expect(errorState.hasError, isTrue);
      expect(completedState.isCompleted, isTrue);
      expect(idleState.canRecord, isTrue);
    });
  });

  group('VoicePlaybackState', () {
    test('should create with default values', () {
      // Act
      const state = VoicePlaybackState();

      // Assert
      expect(state.status, equals(VoicePlaybackStatus.idle));
      expect(state.duration, isNull);
      expect(state.position, isNull);
      expect(state.currentMessageId, isNull);
      expect(state.errorMessage, isNull);
    });

    test('should copy with updated values', () {
      // Arrange
      const original = VoicePlaybackState();

      // Act
      final updated = original.copyWith(
        status: VoicePlaybackStatus.playing,
        duration: const Duration(seconds: 30),
        position: const Duration(seconds: 10),
        currentMessageId: 'msg-123',
      );

      // Assert
      expect(updated.status, equals(VoicePlaybackStatus.playing));
      expect(updated.duration, equals(const Duration(seconds: 30)));
      expect(updated.position, equals(const Duration(seconds: 10)));
      expect(updated.currentMessageId, equals('msg-123'));
    });

    test('should provide correct state checks', () {
      // Arrange
      const playingState = VoicePlaybackState(status: VoicePlaybackStatus.playing);
      const pausedState = VoicePlaybackState(status: VoicePlaybackStatus.paused);
      const loadingState = VoicePlaybackState(status: VoicePlaybackStatus.loading);
      const errorState = VoicePlaybackState(status: VoicePlaybackStatus.error);
      const idleState = VoicePlaybackState(status: VoicePlaybackStatus.idle);

      // Assert
      expect(playingState.isPlaying, isTrue);
      expect(pausedState.isPaused, isTrue);
      expect(loadingState.isLoading, isTrue);
      expect(errorState.hasError, isTrue);
      expect(idleState.isIdle, isTrue);
    });
  });

  group('VoiceRecordingStateNotifier', () {
    late ProviderContainer container;
    late VoiceRecordingStateNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(voiceRecordingStateProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('should start with idle state', () {
      // Assert
      final state = container.read(voiceRecordingStateProvider);
      expect(state.status, equals(VoiceRecordingStatus.idle));
    });

    test('should handle recording start attempt', () async {
      // Act
      await notifier.startRecording();

      // Assert - Should handle permission request (may fail in test environment)
      final state = container.read(voiceRecordingStateProvider);
      expect(state.status, anyOf([
        VoiceRecordingStatus.permission_denied,
        VoiceRecordingStatus.error,
        VoiceRecordingStatus.recording,
      ]));
    });

    test('should handle recording cancellation', () async {
      // Act
      await notifier.cancelRecording();

      // Assert
      final state = container.read(voiceRecordingStateProvider);
      expect(state.status, equals(VoiceRecordingStatus.idle));
    });

    test('should reset to idle state', () {
      // Act
      notifier.reset();

      // Assert
      final state = container.read(voiceRecordingStateProvider);
      expect(state.status, equals(VoiceRecordingStatus.idle));
    });
  });

  group('VoicePlaybackStateNotifier', () {
    late ProviderContainer container;
    late VoicePlaybackStateNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(voicePlaybackStateProvider.notifier);
    });

    tearDown() {
      container.dispose();
    }

    test('should start with idle state', () {
      // Assert
      final state = container.read(voicePlaybackStateProvider);
      expect(state.status, equals(VoicePlaybackStatus.idle));
    });

    test('should handle playback from base64', () async {
      // Act
      await notifier.playFromBase64('invalid-base64', 'test-message');

      // Assert - Should handle error gracefully
      final state = container.read(voicePlaybackStateProvider);
      expect(state.status, anyOf([
        VoicePlaybackStatus.error,
        VoicePlaybackStatus.loading,
      ]));
    });

    test('should handle playback from file', () async {
      // Act
      await notifier.playFromFile('/non/existent/file.m4a', messageId: 'test-message');

      // Assert - Should handle error gracefully
      final state = container.read(voicePlaybackStateProvider);
      expect(state.status, anyOf([
        VoicePlaybackStatus.error,
        VoicePlaybackStatus.loading,
      ]));
    });

    test('should handle stop playback', () async {
      // Act
      await notifier.stop();

      // Assert
      final state = container.read(voicePlaybackStateProvider);
      expect(state.status, equals(VoicePlaybackStatus.idle));
      expect(state.currentMessageId, isNull);
    });

    test('should reset to idle state', () {
      // Act
      notifier.reset();

      // Assert
      final state = container.read(voicePlaybackStateProvider);
      expect(state.status, equals(VoicePlaybackStatus.idle));
    });

    test('should calculate progress correctly', () {
      // Arrange - Set state with duration and position
      final testState = const VoicePlaybackState().copyWith(
        duration: const Duration(seconds: 100),
        position: const Duration(seconds: 25),
      );
      
      // Create a temporary notifier to test progress calculation
      final tempNotifier = VoicePlaybackStateNotifier(container.read(voiceServiceProvider));
      tempNotifier.state = testState;

      // Act
      final progress = tempNotifier.progress;

      // Assert
      expect(progress, equals(0.25));

      tempNotifier.dispose();
    });

    test('should handle progress calculation with null values', () {
      // Act
      final progress = notifier.progress;

      // Assert
      expect(progress, equals(0.0));
    });

    test('should check if playing specific message', () {
      // Arrange
      final testState = const VoicePlaybackState().copyWith(
        status: VoicePlaybackStatus.playing,
        currentMessageId: 'test-message-123',
      );
      notifier.state = testState;

      // Act & Assert
      expect(notifier.isPlayingMessage('test-message-123'), isTrue);
      expect(notifier.isPlayingMessage('other-message'), isFalse);
    });

    test('should check if paused on specific message', () {
      // Arrange
      final testState = const VoicePlaybackState().copyWith(
        status: VoicePlaybackStatus.paused,
        currentMessageId: 'test-message-123',
      );
      notifier.state = testState;

      // Act & Assert
      expect(notifier.isPausedOnMessage('test-message-123'), isTrue);
      expect(notifier.isPausedOnMessage('other-message'), isFalse);
    });

    test('should handle seek operation', () async {
      // Arrange
      final testState = const VoicePlaybackState().copyWith(
        status: VoicePlaybackStatus.playing,
        duration: const Duration(seconds: 100),
      );
      notifier.state = testState;

      // Act
      await notifier.seekTo(const Duration(seconds: 30));

      // Assert
      final state = container.read(voicePlaybackStateProvider);
      expect(state.position, equals(const Duration(seconds: 30)));
    });

    test('should handle toggle play/pause', () async {
      // Test from idle state (should do nothing)
      await notifier.togglePlayPause();
      
      final idleState = container.read(voicePlaybackStateProvider);
      expect(idleState.status, equals(VoicePlaybackStatus.idle));

      // Test from playing state (should pause)
      notifier.state = const VoicePlaybackState(status: VoicePlaybackStatus.playing);
      await notifier.togglePlayPause();
      // Note: Actual pause behavior depends on audio player implementation

      // Test from paused state (should resume)
      notifier.state = const VoicePlaybackState(status: VoicePlaybackStatus.paused);
      await notifier.togglePlayPause();
      // Note: Actual resume behavior depends on audio player implementation
    });
  });

  group('Provider Integration', () {
    test('should provide voice service instance', () {
      // Arrange
      final container = ProviderContainer();

      // Act
      final voiceService = container.read(voiceServiceProvider);

      // Assert
      expect(voiceService, isA<VoiceService>());

      container.dispose();
    });

    test('should provide voice recording state notifier', () {
      // Arrange
      final container = ProviderContainer();

      // Act
      final notifier = container.read(voiceRecordingStateProvider.notifier);
      final state = container.read(voiceRecordingStateProvider);

      // Assert
      expect(notifier, isA<VoiceRecordingStateNotifier>());
      expect(state, isA<VoiceRecordingState>());

      container.dispose();
    });

    test('should provide voice playback state notifier', () {
      // Arrange
      final container = ProviderContainer();

      // Act
      final notifier = container.read(voicePlaybackStateProvider.notifier);
      final state = container.read(voicePlaybackStateProvider);

      // Assert
      expect(notifier, isA<VoicePlaybackStateNotifier>());
      expect(state, isA<VoicePlaybackState>());

      container.dispose();
    });
  });

  group('Error Handling', () {
    test('should handle recording errors gracefully', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(voiceRecordingStateProvider.notifier);

      // Act - Try to stop recording when not recording
      await notifier.stopRecording();

      // Assert - Should not throw and handle gracefully
      final state = container.read(voiceRecordingStateProvider);
      expect(state.status, anyOf([
        VoiceRecordingStatus.idle,
        VoiceRecordingStatus.error,
      ]));

      container.dispose();
    });

    test('should handle playback errors gracefully', () async {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(voicePlaybackStateProvider.notifier);

      // Act - Try to pause when not playing
      await notifier.pause();

      // Assert - Should not throw and handle gracefully
      final state = container.read(voicePlaybackStateProvider);
      expect(state.status, equals(VoicePlaybackStatus.idle));

      container.dispose();
    });
  });
}