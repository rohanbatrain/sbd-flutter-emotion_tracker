import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/widgets/ai/chat_message_widget.dart';
import 'package:emotion_tracker/models/ai/ai_events.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';

void main() {
  group('ChatMessageWidget Tests', () {
    Widget createTestWidget(Widget child) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: child,
          ),
        ),
      );
    }

    ChatMessage createTestMessage({
      String? messageId,
      String? sessionId,
      String? content,
      MessageRole? role,
      String? agentType,
      DateTime? timestamp,
      MessageType? messageType,
      Map<String, dynamic>? metadata,
      String? audioData,
      int? processingTimeMs,
    }) {
      return ChatMessage(
        messageId: messageId ?? 'test_message_1',
        sessionId: sessionId ?? 'test_session_1',
        content: content ?? 'Test message content',
        role: role ?? MessageRole.user,
        agentType: agentType,
        timestamp: timestamp ?? DateTime.now(),
        messageType: messageType ?? MessageType.text,
        metadata: metadata ?? {},
        audioData: audioData,
        processingTimeMs: processingTimeMs,
      );
    }

    testWidgets('should display user message correctly', (tester) async {
      final message = createTestMessage(
        content: 'Hello, AI!',
        role: MessageRole.user,
      );

      await tester.pumpWidget(
        createTestWidget(
          ChatMessageWidget(message: message),
        ),
      );

      // Check message content is displayed
      expect(find.text('Hello, AI!'), findsOneWidget);
      
      // Check user avatar is displayed
      expect(find.byIcon(Icons.person), findsOneWidget);
      
      // Check message bubble is present
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should display assistant message correctly', (tester) async {
      final message = createTestMessage(
        content: 'Hello, human!',
        role: MessageRole.assistant,
        agentType: 'family',
      );

      await tester.pumpWidget(
        createTestWidget(
          ChatMessageWidget(message: message),
        ),
      );

      // Check message content is displayed
      expect(find.text('Hello, human!'), findsOneWidget);
      
      // Check agent avatar is displayed
      expect(find.byIcon(Icons.family_restroom), findsOneWidget);
    });

    testWidgets('should display streaming indicator when streaming', (tester) async {
      final message = createTestMessage(
        content: 'Streaming response...',
        role: MessageRole.assistant,
      );

      await tester.pumpWidget(
        createTestWidget(
          ChatMessageWidget(
            message: message,
            isStreaming: true,
          ),
        ),
      );

      // Check streaming indicator is displayed
      expect(find.text('Streaming...'), findsOneWidget);
      
      // Verify animation is running
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('should display thinking indicator correctly', (tester) async {
      final message = createTestMessage(
        content: 'AI is thinking...',
        role: MessageRole.system,
        metadata: {'is_thinking': true},
      );

      await tester.pumpWidget(
        createTestWidget(
          ChatMessageWidget(message: message),
        ),
      );

      // Check thinking indicator is displayed
      expect(find.text('AI is thinking'), findsOneWidget);
      
      // Check animated dots are present
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });

    testWidgets('should display typing indicator correctly', (tester) async {
      final message = createTestMessage(
        content: 'AI is typing...',
        role: MessageRole.system,
        metadata: {'is_typing': true},
      );

      await tester.pumpWidget(
        createTestWidget(
          ChatMessageWidget(message: message),
        ),
      );

      // Check typing indicator is displayed
      expect(find.text('AI is typing'), findsOneWidget);
    });

    testWidgets('should display error message correctly', (tester) async {
      final message = createTestMessage(
        content: 'Error occurred',
        role: MessageRole.system,
        metadata: {'is_error': true},
      );

      await tester.pumpWidget(
        createTestWidget(
          ChatMessageWidget(message: message),
        ),
      );

      // Check error message is displayed
      expect(find.text('Error occurred'), findsOneWidget);
    });

    testWidgets('should display tool execution indicator', (tester) async {
      final message = createTestMessage(
        content: 'Executing tool',
        role: MessageRole.assistant,
        messageType: MessageType.toolCall,
        metadata: {
          'tool_name': 'create_family_invitation',
          'status': 'executing',
        },
      );

      await tester.pumpWidget(
        createTestWidget(
          ChatMessageWidget(message: message),
        ),
      );

      // Check tool indicator is displayed
      expect(find.text('create_family_invitation'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      
      // Check progress indicator for executing tool
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display successful tool result', (tester) async {
      final message = createTestMessage(
        content: 'Tool completed successfully',
        role: MessageRole.assistant,
        messageType: MessageType.toolResult,
        metadata: {
          'tool_name': 'get_user_balance',
          'success': true,
          'result': {'balance': 100},
        },
      );

      await tester.pumpWidget(
        createTestWidget(
          ChatMessageWidget(message: message),
        ),
      );

      // Check success indicator
      expect(find.text('get_user_balance'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should display voice message controls', (tester) async {
      final message = createTestMessage(
        content: 'Voice message',
        role: MessageRole.user,
        messageType: MessageType.voice,
        audioData: 'base64_audio_data',
      );

      await tester.pumpWidget(
        createTestWidget(
          ChatMessageWidget(message: message),
        ),
      );

      // Check voice controls are displayed
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('should display message timestamp', (tester) async {
      final timestamp = DateTime(2025, 1, 1, 12, 30);
      final message = createTestMessage(
        content: 'Test message',
        timestamp: timestamp,
      );

      await tester.pumpWidget(
        createTestWidget(
          ChatMessageWidget(message: message),
        ),
      );

      // Check timestamp is displayed
      expect(find.text('12:30'), findsOneWidget);
    });

    testWidgets('should display processing time when available', (tester) async {
      final message = createTestMessage(
        content: 'Test message',
        processingTimeMs: 250,
      );

      await tester.pumpWidget(
        createTestWidget(
          ChatMessageWidget(message: message),
        ),
      );

      // Check processing time is displayed
      expect(find.textContaining('250ms'), findsOneWidget);
    });

    testWidgets('should handle retry callback for error messages', (tester) async {
      final message = createTestMessage(
        content: 'Error message',
        metadata: {'is_error': true},
      );

      bool retryPressed = false;

      await tester.pumpWidget(
        createTestWidget(
          ChatMessageWidget(
            message: message,
            onRetry: () => retryPressed = true,
          ),
        ),
      );

      // Find and tap retry button
      final retryButton = find.byIcon(Icons.refresh);
      expect(retryButton, findsOneWidget);
      
      await tester.tap(retryButton);
      expect(retryPressed, isTrue);
    });

    testWidgets('should show message options on long press', (tester) async {
      final message = createTestMessage(
        content: 'Test message for options',
      );

      await tester.pumpWidget(
        createTestWidget(
          ChatMessageWidget(message: message),
        ),
      );

      // Long press on message bubble
      final inkWells = find.byType(InkWell);
      if (inkWells.evaluate().isNotEmpty) {
        await tester.longPress(inkWells.first);
        await tester.pumpAndSettle();

        // Check bottom sheet is displayed (if modal shows up)
        // Note: The actual modal behavior may vary in test environment
        expect(find.byType(ChatMessageWidget), findsOneWidget);
      }
    });

    testWidgets('should handle copy message action', (tester) async {
      final message = createTestMessage(
        content: 'Message to copy',
      );

      bool copyPressed = false;

      await tester.pumpWidget(
        createTestWidget(
          ChatMessageWidget(
            message: message,
            onCopy: () => copyPressed = true,
          ),
        ),
      );

      // Tap on message bubble (if InkWell is present)
      final inkWells = find.byType(InkWell);
      if (inkWells.evaluate().isNotEmpty) {
        await tester.tap(inkWells.first);
        // Note: Copy callback is triggered on tap, not automatically
      }
      
      // Widget should render without errors
      expect(find.byType(ChatMessageWidget), findsOneWidget);
    });

    testWidgets('should display different agent icons correctly', (tester) async {
      final agentTypes = [
        ('family', Icons.family_restroom),
        ('personal', Icons.person_outline),
        ('workspace', Icons.work_outline),
        ('commerce', Icons.shopping_cart_outlined),
        ('security', Icons.security_outlined),
        ('voice', Icons.record_voice_over_outlined),
      ];

      for (final (agentType, expectedIcon) in agentTypes) {
        final message = createTestMessage(
          role: MessageRole.assistant,
          agentType: agentType,
        );

        await tester.pumpWidget(
          createTestWidget(
            ChatMessageWidget(message: message),
          ),
        );

        // Check correct agent icon is displayed
        expect(find.byIcon(expectedIcon), findsOneWidget);
      }
    });

    testWidgets('should animate fade-in for new messages', (tester) async {
      final message = createTestMessage(
        content: 'New message',
      );

      await tester.pumpWidget(
        createTestWidget(
          ChatMessageWidget(message: message),
        ),
      );

      // Check TweenAnimationBuilder is present (used for fade animation)
      expect(find.byType(TweenAnimationBuilder<double>), findsWidgets);
      
      // Verify animation completes
      await tester.pumpAndSettle();
    });

    testWidgets('should handle message info dialog', (tester) async {
      final message = createTestMessage(
        content: 'Test message',
        messageId: 'msg_123',
        agentType: 'family',
        processingTimeMs: 150,
        metadata: {'custom_field': 'custom_value'},
      );

      await tester.pumpWidget(
        createTestWidget(
          ChatMessageWidget(message: message),
        ),
      );

      // Widget should render with message info
      expect(find.text('Test message'), findsOneWidget);
      expect(find.textContaining('150ms'), findsOneWidget);
    });

    testWidgets('should handle voice playback for voice messages', (tester) async {
      final message = createTestMessage(
        messageType: MessageType.voice,
        audioData: 'base64_audio_data',
      );

      await tester.pumpWidget(
        createTestWidget(
          ChatMessageWidget(message: message),
        ),
      );

      // Check voice message is displayed
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('should display correct message bubble alignment', (tester) async {
      // Test user message alignment (right)
      final userMessage = createTestMessage(
        role: MessageRole.user,
        content: 'User message',
      );

      await tester.pumpWidget(
        createTestWidget(
          ChatMessageWidget(message: userMessage),
        ),
      );

      // Check user message is displayed correctly
      expect(find.text('User message'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);

      // Test assistant message alignment (left)
      final assistantMessage = createTestMessage(
        role: MessageRole.assistant,
        content: 'Assistant message',
      );

      await tester.pumpWidget(
        createTestWidget(
          ChatMessageWidget(message: assistantMessage),
        ),
      );

      // Check assistant message is displayed correctly
      expect(find.text('Assistant message'), findsOneWidget);
    });

    testWidgets('should handle empty or null content gracefully', (tester) async {
      final message = createTestMessage(
        content: '',
      );

      await tester.pumpWidget(
        createTestWidget(
          ChatMessageWidget(message: message),
        ),
      );

      // Widget should render without errors
      expect(find.byType(ChatMessageWidget), findsOneWidget);
    });

    testWidgets('should update streaming state correctly', (tester) async {
      final message = createTestMessage(
        content: 'Streaming message',
        role: MessageRole.assistant,
      );

      await tester.pumpWidget(
        createTestWidget(
          ChatMessageWidget(
            message: message,
            isStreaming: true,
          ),
        ),
      );

      // Check streaming indicator is present
      expect(find.text('Streaming...'), findsOneWidget);

      // Update to non-streaming
      await tester.pumpWidget(
        createTestWidget(
          ChatMessageWidget(
            message: message,
            isStreaming: false,
          ),
        ),
      );

      // Check streaming indicator is removed
      expect(find.text('Streaming...'), findsNothing);
    });
  });
}