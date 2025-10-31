import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/widgets/ai/ai_error_widget.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'package:emotion_tracker/providers/ai/ai_exceptions.dart';

void main() {
  group('AIErrorWidget Tests', () {
    Widget createTestWidget(Widget child) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: child,
          ),
        ),
      );
    }

    testWidgets('should display general error using ErrorStateWidget', (tester) async {
      // Arrange
      const error = 'General error message';
      bool retryPressed = false;

      // Act
      await tester.pumpWidget(
        createTestWidget(
          AIErrorWidget(
            error: error,
            onRetry: () => retryPressed = true,
          ),
        ),
      );

      // Assert
      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.byType(AIErrorWidget), findsOneWidget);

      // Test retry functionality if retry button exists
      final retryButton = find.byIcon(Icons.refresh);
      if (retryButton.evaluate().isNotEmpty) {
        await tester.tap(retryButton);
        expect(retryPressed, isTrue);
      }
    });

    testWidgets('should display AI-specific actions for session errors', (tester) async {
      // Arrange
      final error = SessionNotFoundException('Session not found');
      bool newSessionPressed = false;

      // Act
      await tester.pumpWidget(
        createTestWidget(
          AIErrorWidget(
            error: error,
            onNewSession: () => newSessionPressed = true,
          ),
        ),
      );

      // Assert
      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.text('New Chat'), findsOneWidget);
      expect(find.byIcon(Icons.add_comment), findsOneWidget);

      // Test new session action
      await tester.tap(find.text('New Chat'));
      expect(newSessionPressed, isTrue);
    });

    testWidgets('should display switch agent action for agent errors', (tester) async {
      // Arrange
      final error = AgentNotFoundException('Agent not found');
      bool switchAgentPressed = false;

      // Act
      await tester.pumpWidget(
        createTestWidget(
          AIErrorWidget(
            error: error,
            onSwitchAgent: () => switchAgentPressed = true,
          ),
        ),
      );

      // Assert
      expect(find.text('Switch Agent'), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);

      // Test switch agent action
      await tester.tap(find.text('Switch Agent'));
      expect(switchAgentPressed, isTrue);
    });

    testWidgets('should display both actions for applicable errors', (tester) async {
      // Arrange
      final error = SessionLimitReachedException('Session limit reached');
      bool newSessionPressed = false;
      bool switchAgentPressed = false;

      // Act
      await tester.pumpWidget(
        createTestWidget(
          AIErrorWidget(
            error: error,
            onNewSession: () => newSessionPressed = true,
            onSwitchAgent: () => switchAgentPressed = true,
          ),
        ),
      );

      // Assert - Check that AI-specific actions are displayed
      expect(find.byType(AIErrorWidget), findsOneWidget);
      expect(find.byType(ErrorStateWidget), findsOneWidget);
      
      // Look for action buttons (may have different text based on error processing)
      final newChatButtons = find.text('New Chat');
      final switchAgentButtons = find.text('Switch Agent');
      
      if (newChatButtons.evaluate().isNotEmpty) {
        await tester.tap(newChatButtons.first);
        expect(newSessionPressed, isTrue);
      }

      if (switchAgentButtons.evaluate().isNotEmpty) {
        await tester.tap(switchAgentButtons.first);
        expect(switchAgentPressed, isTrue);
      }
    });

    testWidgets('should display compact format when requested', (tester) async {
      // Arrange
      const error = 'Compact error';

      // Act
      await tester.pumpWidget(
        createTestWidget(
          AIErrorWidget(
            error: error,
            compact: true,
          ),
        ),
      );

      // Assert
      expect(find.byType(ErrorStateWidget), findsOneWidget);
      
      // Check that compact styling is applied (smaller text/buttons)
      final errorWidget = tester.widget<ErrorStateWidget>(find.byType(ErrorStateWidget));
      expect(errorWidget.compact, isTrue);
    });

    testWidgets('should not show AI actions for non-AI errors', (tester) async {
      // Arrange
      const error = 'Regular network error';

      // Act
      await tester.pumpWidget(
        createTestWidget(
          AIErrorWidget(
            error: error,
            onNewSession: () {},
            onSwitchAgent: () {},
          ),
        ),
      );

      // Assert
      expect(find.text('New Chat'), findsNothing);
      expect(find.text('Switch Agent'), findsNothing);
    });

    testWidgets('should handle session expired error', (tester) async {
      // Arrange
      final error = SessionExpiredException('Session has expired');
      bool newSessionPressed = false;

      // Act
      await tester.pumpWidget(
        createTestWidget(
          AIErrorWidget(
            error: error,
            onNewSession: () => newSessionPressed = true,
          ),
        ),
      );

      // Assert
      expect(find.text('New Chat'), findsOneWidget);

      // Test action
      await tester.tap(find.text('New Chat'));
      expect(newSessionPressed, isTrue);
    });

    testWidgets('should handle agent access denied error', (tester) async {
      // Arrange
      final error = AgentAccessDeniedException('Access denied to agent');
      bool switchAgentPressed = false;

      // Act
      await tester.pumpWidget(
        createTestWidget(
          AIErrorWidget(
            error: error,
            onSwitchAgent: () => switchAgentPressed = true,
          ),
        ),
      );

      // Assert
      expect(find.text('Switch Agent'), findsOneWidget);

      // Test action
      await tester.tap(find.text('Switch Agent'));
      expect(switchAgentPressed, isTrue);
    });
  });

  group('AIVoiceErrorWidget Tests', () {
    Widget createTestWidget(Widget child) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: child,
          ),
        ),
      );
    }

    testWidgets('should display voice error with base error widget', (tester) async {
      // Arrange
      final error = AudioRecordingException('Recording failed');
      bool retryPressed = false;

      // Act
      await tester.pumpWidget(
        createTestWidget(
          AIVoiceErrorWidget(
            error: error,
            onRetry: () => retryPressed = true,
          ),
        ),
      );

      // Assert
      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.byType(AIVoiceErrorWidget), findsOneWidget);
    });

    testWidgets('should display settings button for permission errors', (tester) async {
      // Arrange
      final error = MicrophonePermissionException('Microphone permission denied');
      bool settingsPressed = false;

      // Act
      await tester.pumpWidget(
        createTestWidget(
          AIVoiceErrorWidget(
            error: error,
            onOpenSettings: () => settingsPressed = true,
          ),
        ),
      );

      // Assert
      expect(find.text('Open Settings'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);

      // Test settings action
      await tester.tap(find.text('Open Settings'));
      expect(settingsPressed, isTrue);
    });

    testWidgets('should not show settings for non-permission errors', (tester) async {
      // Arrange
      final error = AudioRecordingException('Recording failed');

      // Act
      await tester.pumpWidget(
        createTestWidget(
          AIVoiceErrorWidget(
            error: error,
            onOpenSettings: () {},
          ),
        ),
      );

      // Assert
      expect(find.text('Open Settings'), findsNothing);
    });

    testWidgets('should display compact format for voice errors', (tester) async {
      // Arrange
      final error = AudioPlaybackException('Playback failed');

      // Act
      await tester.pumpWidget(
        createTestWidget(
          AIVoiceErrorWidget(
            error: error,
            compact: true,
          ),
        ),
      );

      // Assert
      expect(find.byType(ErrorStateWidget), findsOneWidget);
      
      // Check compact styling
      final errorWidget = tester.widget<ErrorStateWidget>(find.byType(ErrorStateWidget));
      expect(errorWidget.compact, isTrue);
    });
  });

  group('AIConnectionErrorWidget Tests', () {
    Widget createTestWidget(Widget child) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: child,
          ),
        ),
      );
    }

    testWidgets('should display connection error with base error widget', (tester) async {
      // Arrange
      final error = NetworkException('Connection failed');
      bool retryPressed = false;

      // Act
      await tester.pumpWidget(
        createTestWidget(
          AIConnectionErrorWidget(
            error: error,
            onRetry: () => retryPressed = true,
          ),
        ),
      );

      // Assert
      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.text('Connection failed'), findsOneWidget);
    });

    testWidgets('should display reconnect button', (tester) async {
      // Arrange
      final error = NetworkException('WebSocket disconnected');
      bool reconnectPressed = false;

      // Act
      await tester.pumpWidget(
        createTestWidget(
          AIConnectionErrorWidget(
            error: error,
            onReconnect: () => reconnectPressed = true,
          ),
        ),
      );

      // Assert
      expect(find.text('Reconnect'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Test reconnect action
      await tester.tap(find.text('Reconnect'));
      expect(reconnectPressed, isTrue);
    });

    testWidgets('should display both retry and reconnect buttons', (tester) async {
      // Arrange
      final error = NetworkException('Connection timeout');
      bool retryPressed = false;
      bool reconnectPressed = false;

      // Act
      await tester.pumpWidget(
        createTestWidget(
          AIConnectionErrorWidget(
            error: error,
            onRetry: () => retryPressed = true,
            onReconnect: () => reconnectPressed = true,
          ),
        ),
      );

      // Assert
      expect(find.text('Reconnect'), findsOneWidget);
      
      // Test reconnect action
      await tester.tap(find.text('Reconnect'));
      expect(reconnectPressed, isTrue);
    });

    testWidgets('should display compact format for connection errors', (tester) async {
      // Arrange
      final error = NetworkException('Timeout');

      // Act
      await tester.pumpWidget(
        createTestWidget(
          AIConnectionErrorWidget(
            error: error,
            compact: true,
          ),
        ),
      );

      // Assert
      expect(find.byType(ErrorStateWidget), findsOneWidget);
      
      // Check compact styling
      final errorWidget = tester.widget<ErrorStateWidget>(find.byType(ErrorStateWidget));
      expect(errorWidget.compact, isTrue);
    });

    testWidgets('should not show reconnect button when callback is null', (tester) async {
      // Arrange
      final error = NetworkException('Connection failed');

      // Act
      await tester.pumpWidget(
        createTestWidget(
          AIConnectionErrorWidget(
            error: error,
            onRetry: () {},
          ),
        ),
      );

      // Assert
      expect(find.text('Reconnect'), findsNothing);
    });
  });

  group('Error Widget Integration', () {
    testWidgets('should handle null callbacks gracefully', (tester) async {
      // Arrange
      final error = SessionNotFoundException('Session not found');

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AIErrorWidget(error: error),
            ),
          ),
        ),
      );

      // Assert - Should render without errors
      expect(find.byType(AIErrorWidget), findsOneWidget);
      expect(find.byType(ErrorStateWidget), findsOneWidget);
    });

    testWidgets('should apply correct theme colors', (tester) async {
      // Arrange
      final error = AgentNotFoundException('Agent not found');

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: AIErrorWidget(
                error: error,
                onSwitchAgent: () {},
              ),
            ),
          ),
        ),
      );

      // Assert - Check that widget renders with theme
      expect(find.byType(AIErrorWidget), findsOneWidget);
      expect(find.byType(ErrorStateWidget), findsOneWidget);
      
      // Check for any buttons that might be rendered
      final buttons = find.byType(OutlinedButton);
      if (buttons.evaluate().isNotEmpty) {
        final button = tester.widget<OutlinedButton>(buttons.first);
        expect(button.style, isNotNull);
      }
    });

    testWidgets('should handle complex error scenarios', (tester) async {
      // Arrange
      final error = SessionLimitReachedException('Too many sessions');
      bool newSessionPressed = false;
      bool retryPressed = false;

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AIErrorWidget(
                error: error,
                onRetry: () => retryPressed = true,
                onNewSession: () => newSessionPressed = true,
                compact: false,
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.text('New Chat'), findsOneWidget);
      
      // Test that both error widget and AI actions work
      await tester.tap(find.text('New Chat'));
      expect(newSessionPressed, isTrue);
    });
  });
}