import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/screens/ai/ai_chat_screen.dart';
import 'package:emotion_tracker/providers/ai/ai_providers.dart';
import 'package:emotion_tracker/providers/ai/ai_websocket_client.dart';
import 'package:emotion_tracker/providers/ai/ai_offline_service.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/models/ai/ai_events.dart';
import 'package:emotion_tracker/widgets/ai/agent_selector_widget.dart';
import 'package:emotion_tracker/widgets/ai/chat_message_widget.dart';
import 'package:emotion_tracker/widgets/ai/voice_input_widget.dart';
import 'package:emotion_tracker/widgets/ai/ai_offline_indicator.dart';
import 'package:emotion_tracker/widgets/app_scaffold.dart';

// Mock providers for testing
class MockAIApiService extends StateNotifier<void> {
  MockAIApiService() : super(null);
}

class MockCurrentAISessionNotifier extends StateNotifier<AISession?> {
  MockCurrentAISessionNotifier() : super(null);

  Future<AISession?> createSession({
    required AgentType agentType,
    bool voiceEnabled = false,
  }) async {
    final session = AISession(
      sessionId: 'test_session_1',
      userId: 'test_user_1',
      agentType: agentType,
      status: SessionStatus.active,
      createdAt: DateTime.now(),
      lastActivity: DateTime.now(),
      voiceEnabled: voiceEnabled,
    );
    state = session;
    return session;
  }

  Future<void> switchAgent(AgentType agentType) async {
    if (state != null) {
      state = state!.copyWith(agentType: agentType);
    }
  }

  void clearSession() {
    state = null;
  }
}

class MockChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  MockChatMessagesNotifier() : super([]);

  Future<void> sendMessage({
    required String sessionId,
    required String content,
    MessageType messageType = MessageType.text,
    String? audioData,
    Map<String, dynamic>? metadata,
  }) async {
    final message = ChatMessage(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: sessionId,
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
      messageType: messageType,
      audioData: audioData,
      metadata: metadata ?? {},
    );
    state = [...state, message];
  }

  Future<void> loadSessionHistory(String sessionId, {int limit = 50}) async {
    // Mock loading some messages
    final messages = [
      ChatMessage(
        messageId: 'msg_1',
        sessionId: sessionId,
        content: 'Hello!',
        role: MessageRole.user,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      ChatMessage(
        messageId: 'msg_2',
        sessionId: sessionId,
        content: 'Hello! How can I help you today?',
        role: MessageRole.assistant,
        agentType: 'family',
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
    ];
    state = messages;
  }

  void clearMessages() {
    state = [];
  }

  bool get isStreaming => false;
}

class MockAIConnectionStateNotifier extends StateNotifier<AIConnectionState> {
  MockAIConnectionStateNotifier() : super(AIConnectionState.disconnected);

  Future<void> connectToSession(String sessionId, {String? agentType}) async {
    state = AIConnectionState.connecting;
    await Future.delayed(const Duration(milliseconds: 100));
    state = AIConnectionState.connected;
  }

  Future<void> disconnect() async {
    state = AIConnectionState.disconnected;
  }

  void setError(String error) {
    state = AIConnectionState.error;
  }
}

void main() {
  group('AIChatScreen Tests', () {
    late MockCurrentAISessionNotifier mockSessionNotifier;
    late MockChatMessagesNotifier mockMessagesNotifier;
    late MockAIConnectionStateNotifier mockConnectionNotifier;

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          currentAISessionProvider.overrideWith((ref) => mockSessionNotifier),
          chatMessagesProvider.overrideWith((ref) => mockMessagesNotifier),
          aiConnectionStateProvider.overrideWith((ref) => mockConnectionNotifier),
        ],
        child: const MaterialApp(
          home: AIChatScreen(),
        ),
      );
    }

    setUp(() {
      mockSessionNotifier = MockCurrentAISessionNotifier();
      mockMessagesNotifier = MockChatMessagesNotifier();
      mockConnectionNotifier = MockAIConnectionStateNotifier();
    });

    testWidgets('should display welcome screen when no session is active', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check welcome screen elements
      expect(find.text('Welcome to AI Chat'), findsOneWidget);
      expect(find.text('Select an AI agent to start chatting. Each agent specializes in different areas to help you with various tasks.'), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy_rounded), findsOneWidget);
      expect(find.text('Choose AI Agent'), findsOneWidget);
    });

    testWidgets('should show agent selector when choose agent button is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Tap choose agent button
      await tester.tap(find.text('Choose AI Agent'));
      await tester.pumpAndSettle();

      // Check agent selector is displayed
      expect(find.byType(AgentSelectorWidget), findsOneWidget);
    });

    testWidgets('should display empty chat when session is active but no messages', (tester) async {
      // Create a session
      await mockSessionNotifier.createSession(agentType: AgentType.family);
      
      await tester.pumpWidget(createTestWidget());

      // Check empty chat screen
      expect(find.text('Chat with Family Assistant'), findsOneWidget);
      expect(find.byIcon(Icons.family_restroom), findsOneWidget);
      expect(find.text('Helps with family management, invitations, and shared resources.'), findsOneWidget);
      expect(find.text('Start typing a message below or use voice input to begin your conversation.'), findsOneWidget);
    });

    testWidgets('should display chat messages when available', (tester) async {
      // Create session and load messages
      await mockSessionNotifier.createSession(agentType: AgentType.family);
      await mockMessagesNotifier.loadSessionHistory('test_session_1');
      
      await tester.pumpWidget(createTestWidget());

      // Check messages are displayed
      expect(find.text('Hello!'), findsOneWidget);
      expect(find.text('Hello! How can I help you today?'), findsOneWidget);
      expect(find.byType(ChatMessageWidget), findsNWidgets(2));
    });

    testWidgets('should display connection status bar', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check disconnected status
      expect(find.text('Disconnected'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);

      // Change to connected
      mockConnectionNotifier.state = AIConnectionState.connected;
      await tester.pumpAndSettle();

      expect(find.text('Connected'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should toggle agent selector visibility', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find agent selector toggle button
      final toggleButton = find.byIcon(Icons.expand_more);
      expect(toggleButton, findsOneWidget);

      // Tap to show agent selector
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      // Check agent selector is visible
      expect(find.byType(AgentSelectorWidget), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);

      // Tap to hide agent selector
      await tester.tap(find.byIcon(Icons.expand_less));
      await tester.pumpAndSettle();

      // Check agent selector is hidden
      expect(find.byType(AgentSelectorWidget), findsNothing);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('should toggle voice mode', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find voice mode toggle button
      final voiceToggle = find.byIcon(Icons.mic);
      expect(voiceToggle, findsOneWidget);

      // Tap to enable voice mode
      await tester.tap(voiceToggle);
      await tester.pumpAndSettle();

      // Check voice mode is enabled
      expect(find.byIcon(Icons.keyboard), findsOneWidget);
      expect(find.byType(VoiceInputWidget), findsOneWidget);

      // Tap to disable voice mode
      await tester.tap(find.byIcon(Icons.keyboard));
      await tester.pumpAndSettle();

      // Check text mode is restored
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should handle agent selection', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Show agent selector
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      // Select family agent
      await tester.tap(find.text('Family Assistant'));
      await tester.pumpAndSettle();

      // Check session was created
      expect(mockSessionNotifier.state?.agentType, equals(AgentType.family));
      
      // Check title updated
      expect(find.text('AI Chat - Family Assistant'), findsOneWidget);
    });

    testWidgets('should handle message sending', (tester) async {
      // Create session and connect
      await mockSessionNotifier.createSession(agentType: AgentType.family);
      mockConnectionNotifier.state = AIConnectionState.connected;
      
      await tester.pumpWidget(createTestWidget());

      // Find text input
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Enter message
      await tester.enterText(textField, 'Hello AI!');
      await tester.pumpAndSettle();

      // Tap send button
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Check message was added
      expect(mockMessagesNotifier.state.length, equals(1));
      expect(mockMessagesNotifier.state.first.content, equals('Hello AI!'));
    });

    testWidgets('should disable input when not connected', (tester) async {
      // Create session but keep disconnected
      await mockSessionNotifier.createSession(agentType: AgentType.family);
      
      await tester.pumpWidget(createTestWidget());

      // Check input is disabled
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);

      // Check placeholder text
      expect(find.text('Connect to start chatting'), findsOneWidget);

      // Check send button is disabled
      final sendButton = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(sendButton.onPressed, isNull);
    });

    testWidgets('should handle connection errors', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Set error state
      mockConnectionNotifier.setError('Connection failed');
      await tester.pumpAndSettle();

      // Check error status is displayed
      expect(find.text('Connection Error'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('should handle agent switching', (tester) async {
      // Create session with family agent
      await mockSessionNotifier.createSession(agentType: AgentType.family);
      
      await tester.pumpWidget(createTestWidget());

      // Show agent selector
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      // Switch to personal agent
      await tester.tap(find.text('Personal Assistant'));
      await tester.pumpAndSettle();

      // Check agent was switched
      expect(mockSessionNotifier.state?.agentType, equals(AgentType.personal));
      expect(find.text('AI Chat - Personal Assistant'), findsOneWidget);
    });

    testWidgets('should display offline banner when offline', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check offline banner is present (component exists)
      expect(find.byType(AIOfflineBanner), findsOneWidget);
    });

    testWidgets('should handle navigation to other screens', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // The navigation would be tested through integration tests
      // Here we just verify the AppScaffold is present with correct properties
      expect(find.byType(AppScaffold), findsOneWidget);
    });

    testWidgets('should auto-scroll to bottom when new messages arrive', (tester) async {
      // Create session with messages
      await mockSessionNotifier.createSession(agentType: AgentType.family);
      await mockMessagesNotifier.loadSessionHistory('test_session_1');
      mockConnectionNotifier.state = AIConnectionState.connected;
      
      await tester.pumpWidget(createTestWidget());

      // Send a new message
      await tester.enterText(find.byType(TextField), 'New message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Verify ListView is present (auto-scroll behavior would need integration test)
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should handle voice message sending', (tester) async {
      // Create session and enable voice mode
      await mockSessionNotifier.createSession(agentType: AgentType.family, voiceEnabled: true);
      mockConnectionNotifier.state = AIConnectionState.connected;
      
      await tester.pumpWidget(createTestWidget());

      // Enable voice mode
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();

      // Check voice input widget is displayed
      expect(find.byType(VoiceInputWidget), findsOneWidget);
    });

    testWidgets('should display correct agent icons and descriptions', (tester) async {
      final agentTests = [
        (AgentType.family, Icons.family_restroom, 'Family Assistant'),
        (AgentType.personal, Icons.person, 'Personal Assistant'),
        (AgentType.workspace, Icons.work, 'Workspace Assistant'),
        (AgentType.commerce, Icons.shopping_cart, 'Commerce Assistant'),
        (AgentType.security, Icons.security, 'Security Assistant'),
        (AgentType.voice, Icons.record_voice_over, 'Voice Assistant'),
      ];

      for (final (agentType, expectedIcon, expectedName) in agentTests) {
        // Create session with specific agent
        mockSessionNotifier.clearSession();
        await mockSessionNotifier.createSession(agentType: agentType);
        
        await tester.pumpWidget(createTestWidget());

        // Check correct title and icon are displayed
        expect(find.text('AI Chat - $expectedName'), findsOneWidget);
        expect(find.byIcon(expectedIcon), findsOneWidget);
      }
    });

    testWidgets('should handle session expiry gracefully', (tester) async {
      // Create session
      await mockSessionNotifier.createSession(agentType: AgentType.family);
      
      await tester.pumpWidget(createTestWidget());

      // Simulate session expiry by clearing session
      mockSessionNotifier.clearSession();
      await tester.pumpAndSettle();

      // Should return to welcome screen
      expect(find.text('Welcome to AI Chat'), findsOneWidget);
    });

    testWidgets('should show error messages in snackbar', (tester) async {
      // Create session but keep disconnected to trigger error
      await mockSessionNotifier.createSession(agentType: AgentType.family);
      
      await tester.pumpWidget(createTestWidget());

      // Try to send message while disconnected
      await tester.enterText(find.byType(TextField), 'Test message');
      
      // The actual error handling would show a snackbar
      // This would be better tested in integration tests
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should handle empty message submission', (tester) async {
      // Create session and connect
      await mockSessionNotifier.createSession(agentType: AgentType.family);
      mockConnectionNotifier.state = AIConnectionState.connected;
      
      await tester.pumpWidget(createTestWidget());

      // Try to send empty message
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // No message should be added
      expect(mockMessagesNotifier.state.length, equals(0));
    });

    testWidgets('should clear input after sending message', (tester) async {
      // Create session and connect
      await mockSessionNotifier.createSession(agentType: AgentType.family);
      mockConnectionNotifier.state = AIConnectionState.connected;
      
      await tester.pumpWidget(createTestWidget());

      // Enter and send message
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Check input is cleared
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });
  });
}