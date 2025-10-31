import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:emotion_tracker/screens/ai/ai_chat_screen.dart';
import 'package:emotion_tracker/providers/ai/ai_providers.dart';
import 'package:emotion_tracker/providers/ai/ai_websocket_client.dart';
import 'package:emotion_tracker/providers/ai/ai_offline_service.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/models/ai/ai_events.dart';
import 'package:emotion_tracker/widgets/ai/agent_selector_widget.dart';
import 'package:emotion_tracker/widgets/ai/chat_message_widget.dart';
import 'package:emotion_tracker/widgets/ai/voice_input_widget.dart';
import 'package:emotion_tracker/widgets/ai/ai_offline_indicator.dart';

void main() {
  group('AI Chat Integration Tests', () {
    late MockFlutterSecureStorage mockStorage;
    late MockCurrentAISessionNotifier mockSessionNotifier;
    late MockChatMessagesNotifier mockMessagesNotifier;
    late MockAIConnectionStateNotifier mockConnectionNotifier;
    late MockAIOfflineService mockOfflineService;

    Widget createTestApp({List<Override>? additionalOverrides}) {
      return ProviderScope(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
          currentAISessionProvider.overrideWith((ref) => mockSessionNotifier),
          chatMessagesProvider.overrideWith((ref) => mockMessagesNotifier),
          aiConnectionStateProvider.overrideWith((ref) => mockConnectionNotifier),
          aiOfflineServiceProvider.overrideWithValue(mockOfflineService),
          ...?additionalOverrides,
        ],
        child: const MaterialApp(
          home: AIChatScreen(),
        ),
      );
    }

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      mockSessionNotifier = MockCurrentAISessionNotifier();
      mockMessagesNotifier = MockChatMessagesNotifier();
      mockConnectionNotifier = MockAIConnectionStateNotifier();
      mockOfflineService = MockAIOfflineService();
    });

    tearDown(() {
      mockOfflineService.dispose();
    });

    testWidgets('Complete AI chat flow - from welcome to conversation', (tester) async {
      // Set up screen size for better testing
      await tester.binding.setSurfaceSize(const Size(800, 600));

      // Step 1: Start with welcome screen
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify welcome screen is displayed
      expect(find.text('Welcome to AI Chat'), findsOneWidget);
      expect(find.text('Choose AI Agent'), findsOneWidget);

      // Step 2: Open agent selector
      await tester.tap(find.text('Choose AI Agent'));
      await tester.pumpAndSettle();

      // Verify agent selector is displayed
      expect(find.byType(AgentSelectorWidget), findsOneWidget);

      // Step 3: Select Family Assistant
      await tester.tap(find.text('Family Assistant'));
      await tester.pumpAndSettle();

      // Verify session was created and UI updated
      expect(mockSessionNotifier.state?.agentType, equals(AgentType.family));
      expect(find.text('AI Chat - Family Assistant'), findsOneWidget);

      // Step 4: Connect to session
      mockConnectionNotifier.setState(AIConnectionState.connected);
      await tester.pumpAndSettle();

      // Verify connection status
      expect(find.text('Connected'), findsOneWidget);

      // Step 5: Send a text message
      await tester.enterText(find.byType(TextField), 'Hello, Family Assistant!');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Verify message was sent and displayed
      expect(mockMessagesNotifier.messages.length, equals(1));
      expect(mockMessagesNotifier.messages.first.content, equals('Hello, Family Assistant!'));
      expect(find.text('Hello, Family Assistant!'), findsOneWidget);

      // Step 6: Simulate AI response
      await mockMessagesNotifier.addMessage(ChatMessage(
        messageId: 'ai_response_1',
        sessionId: mockSessionNotifier.state!.sessionId,
        content: 'Hello! How can I help you with family management today?',
        role: MessageRole.assistant,
        agentType: 'family',
        timestamp: DateTime.now(),
      ));
      await tester.pumpAndSettle();

      // Verify AI response is displayed
      expect(find.text('Hello! How can I help you with family management today?'), findsOneWidget);
      expect(find.byType(ChatMessageWidget), findsNWidgets(2));

      // Step 7: Switch to voice mode
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();

      // Verify voice input is displayed
      expect(find.byType(VoiceInputWidget), findsOneWidget);
      expect(find.byIcon(Icons.keyboard), findsOneWidget);

      // Step 8: Switch back to text mode
      await tester.tap(find.byIcon(Icons.keyboard));
      await tester.pumpAndSettle();

      // Verify text input is restored
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);

      // Step 9: Test agent switching
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Personal Assistant'));
      await tester.pumpAndSettle();

      // Verify agent was switched
      expect(mockSessionNotifier.state?.agentType, equals(AgentType.personal));
      expect(find.text('AI Chat - Personal Assistant'), findsOneWidget);
    });

    testWidgets('Offline mode integration test', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      // Step 1: Start with active session
      await mockSessionNotifier.createSession(agentType: AgentType.family);
      mockConnectionNotifier.setState(AIConnectionState.connected);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Step 2: Go offline
      mockOfflineService.setOfflineStatus(true);
      mockConnectionNotifier.setState(AIConnectionState.disconnected);
      await tester.pumpAndSettle();

      // Verify offline indicators are displayed
      expect(find.byType(AIOfflineBanner), findsOneWidget);
      expect(find.text('AI Chat Offline'), findsOneWidget);

      // Step 3: Try to send message while offline
      await tester.enterText(find.byType(TextField), 'Offline message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Verify message was queued
      expect(mockOfflineService.queuedMessageCount, equals(1));
      expect(find.text('Offline - 1 message queued'), findsOneWidget);

      // Step 4: Send another message
      await tester.enterText(find.byType(TextField), 'Another offline message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Verify multiple messages queued
      expect(mockOfflineService.queuedMessageCount, equals(2));
      expect(find.text('Offline - 2 messages queued'), findsOneWidget);

      // Step 5: Go back online
      mockOfflineService.setOfflineStatus(false);
      mockConnectionNotifier.setState(AIConnectionState.connected);
      await tester.pumpAndSettle();

      // Verify offline indicators are hidden
      expect(find.text('AI Chat Offline'), findsNothing);
      expect(find.text('Connected'), findsOneWidget);
    });

    testWidgets('Error handling integration test', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      // Step 1: Start with session
      await mockSessionNotifier.createSession(agentType: AgentType.family);
      mockConnectionNotifier.setState(AIConnectionState.connected);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Step 2: Simulate connection error
      mockConnectionNotifier.setState(AIConnectionState.error);
      await tester.pumpAndSettle();

      // Verify error status is displayed
      expect(find.text('Connection Error'), findsOneWidget);

      // Step 3: Simulate session expiry
      mockSessionNotifier.clearSession();
      await tester.pumpAndSettle();

      // Verify return to welcome screen
      expect(find.text('Welcome to AI Chat'), findsOneWidget);

      // Step 4: Try to create new session
      await tester.tap(find.text('Choose AI Agent'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Family Assistant'));
      await tester.pumpAndSettle();

      // Verify recovery
      expect(mockSessionNotifier.state?.agentType, equals(AgentType.family));
    });

    testWidgets('Voice integration test', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      // Step 1: Start with voice-enabled session
      await mockSessionNotifier.createSession(
        agentType: AgentType.voice,
        voiceEnabled: true,
      );
      mockConnectionNotifier.setState(AIConnectionState.connected);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Step 2: Switch to voice mode
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle();

      // Verify voice input is displayed
      expect(find.byType(VoiceInputWidget), findsOneWidget);

      // Step 3: Simulate voice message completion
      // Note: This would require mocking the voice service more extensively
      // For now, we verify the UI components are present
      expect(find.byType(VoiceInputWidget), findsOneWidget);
    });

    testWidgets('Message history and pagination test', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      // Step 1: Start with session and load history
      await mockSessionNotifier.createSession(agentType: AgentType.family);
      
      // Add multiple messages to simulate history
      final messages = List.generate(10, (i) => ChatMessage(
        messageId: 'msg_$i',
        sessionId: mockSessionNotifier.state!.sessionId,
        content: 'Message $i',
        role: i.isEven ? MessageRole.user : MessageRole.assistant,
        timestamp: DateTime.now().subtract(Duration(minutes: 10 - i)),
      ));
      
      for (final message in messages) {
        await mockMessagesNotifier.addMessage(message);
      }

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify messages are displayed
      expect(find.byType(ChatMessageWidget), findsNWidgets(10));
      expect(find.text('Message 0'), findsOneWidget);
      expect(find.text('Message 9'), findsOneWidget);

      // Step 2: Test scrolling behavior
      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);

      // Scroll to top to test pagination (if implemented)
      await tester.fling(listView, const Offset(0, 500), 1000);
      await tester.pumpAndSettle();

      // Messages should still be visible
      expect(find.byType(ChatMessageWidget), findsWidgets);
    });

    testWidgets('Agent switching with message history test', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      // Step 1: Start with family agent and send messages
      await mockSessionNotifier.createSession(agentType: AgentType.family);
      mockConnectionNotifier.setState(AIConnectionState.connected);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Send a message with family agent
      await tester.enterText(find.byType(TextField), 'Family question');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('Family question'), findsOneWidget);

      // Step 2: Switch to personal agent
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Personal Assistant'));
      await tester.pumpAndSettle();

      // Verify agent switched and messages cleared (if that's the behavior)
      expect(mockSessionNotifier.state?.agentType, equals(AgentType.personal));
      expect(find.text('AI Chat - Personal Assistant'), findsOneWidget);

      // Step 3: Send message with new agent
      await tester.enterText(find.byType(TextField), 'Personal question');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('Personal question'), findsOneWidget);
    });

    testWidgets('Connection state transitions test', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Test disconnected state
      expect(find.text('Disconnected'), findsOneWidget);

      // Test connecting state
      mockConnectionNotifier.setState(AIConnectionState.connecting);
      await tester.pumpAndSettle();
      expect(find.text('Connecting...'), findsOneWidget);

      // Test connected state
      mockConnectionNotifier.setState(AIConnectionState.connected);
      await tester.pumpAndSettle();
      expect(find.text('Connected'), findsOneWidget);

      // Test reconnecting state
      mockConnectionNotifier.setState(AIConnectionState.reconnecting);
      await tester.pumpAndSettle();
      expect(find.text('Reconnecting...'), findsOneWidget);

      // Test error state
      mockConnectionNotifier.setState(AIConnectionState.error);
      await tester.pumpAndSettle();
      expect(find.text('Connection Error'), findsOneWidget);
    });

    testWidgets('UI responsiveness test', (tester) async {
      // Test different screen sizes
      final screenSizes = [
        const Size(400, 800), // Mobile portrait
        const Size(800, 400), // Mobile landscape
        const Size(1200, 800), // Tablet/Desktop
      ];

      for (final size in screenSizes) {
        await tester.binding.setSurfaceSize(size);

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Verify basic UI elements are present regardless of screen size
        expect(find.text('Welcome to AI Chat'), findsOneWidget);
        expect(find.text('Choose AI Agent'), findsOneWidget);

        // Test agent selection
        await tester.tap(find.text('Choose AI Agent'));
        await tester.pumpAndSettle();

        expect(find.byType(AgentSelectorWidget), findsOneWidget);

        // Reset for next iteration
        await mockSessionNotifier.clearSession();
      }
    });
  });
}

// Mock implementations for integration testing

class MockFlutterSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _storage[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _storage[key] = value;
    } else {
      _storage.remove(key);
    }
  }

  @override
  Future<void> delete({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll({IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    _storage.clear();
  }

  @override
  Future<bool> containsKey({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    return _storage.containsKey(key);
  }

  @override
  Future<Map<String, String>> readAll({IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    return Map.from(_storage);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockCurrentAISessionNotifier extends StateNotifier<AISession?> {
  MockCurrentAISessionNotifier() : super(null);

  Future<AISession?> createSession({
    required AgentType agentType,
    bool voiceEnabled = false,
  }) async {
    final session = AISession(
      sessionId: 'test_session_${DateTime.now().millisecondsSinceEpoch}',
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

  List<ChatMessage> get messages => state;

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

  Future<void> addMessage(ChatMessage message) async {
    state = [...state, message];
  }

  Future<void> loadSessionHistory(String sessionId, {int limit = 50}) async {
    // Mock loading messages
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

  void setState(AIConnectionState newState) {
    state = newState;
  }

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

class MockAIOfflineService {
  bool _isOffline = false;
  final List<QueuedMessage> _messageQueue = [];

  bool get isOffline => _isOffline;
  int get queuedMessageCount => _messageQueue.length;
  List<QueuedMessage> get currentQueue => List.unmodifiable(_messageQueue);

  Stream<bool> get offlineStatus => Stream.value(_isOffline);
  Stream<List<QueuedMessage>> get queuedMessages => Stream.value(_messageQueue);

  Future<void> setOfflineStatus(bool isOffline) async {
    _isOffline = isOffline;
  }

  Future<void> queueMessage({
    required String sessionId,
    required String content,
    required MessageType messageType,
    String? audioData,
    Map<String, dynamic>? metadata,
  }) async {
    final queuedMessage = QueuedMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: sessionId,
      content: content,
      messageType: messageType,
      audioData: audioData,
      metadata: metadata ?? {},
      timestamp: DateTime.now(),
      retryCount: 0,
    );
    _messageQueue.add(queuedMessage);
  }

  void dispose() {
    // Cleanup resources
  }
}