import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:emotion_tracker/providers/ai/ai_api_service.dart';
import 'package:emotion_tracker/providers/ai/ai_websocket_client.dart';
import 'package:emotion_tracker/providers/ai/ai_offline_service.dart';
import 'package:emotion_tracker/providers/ai/voice_service.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:emotion_tracker/models/ai/ai_events.dart';
import 'dart:convert';
import 'dart:async';

// AI API Service Provider - follows existing pattern from family providers
final aiApiServiceProvider = Provider<AIApiService>((ref) {
  return AIApiService(ref);
});

// Current AI Session Provider - manages the active AI session
final currentAISessionProvider = StateNotifierProvider<CurrentAISessionNotifier, AISession?>((ref) {
  final apiService = ref.watch(aiApiServiceProvider);
  return CurrentAISessionNotifier(apiService);
});

// Chat Messages Provider - manages conversation history and streaming
final chatMessagesProvider = StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>((ref) {
  final apiService = ref.watch(aiApiServiceProvider);
  final webSocketClient = ref.watch(aiWebSocketClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final offlineService = ref.watch(aiOfflineServiceProvider);
  return ChatMessagesNotifier(apiService, webSocketClient, secureStorage, offlineService, ref);
});

// AI Connection State Provider - manages WebSocket connection status
final aiConnectionStateProvider = StateNotifierProvider<AIConnectionStateNotifier, AIConnectionState>((ref) {
  final webSocketClient = ref.watch(aiWebSocketClientProvider);
  return AIConnectionStateNotifier(webSocketClient, ref);
});

// Current AI Session State Notifier
class CurrentAISessionNotifier extends StateNotifier<AISession?> {
  final AIApiService _apiService;

  CurrentAISessionNotifier(this._apiService) : super(null);

  Future<AISession?> createSession({
    required AgentType agentType,
    bool voiceEnabled = false,
  }) async {
    try {
      final session = await _apiService.createSession(
        agentType: agentType,
        voiceEnabled: voiceEnabled,
      );
      state = session;
      return session;
    } catch (e) {
      // Error handling - session remains null
      return null;
    }
  }

  Future<void> endSession() async {
    if (state != null) {
      try {
        await _apiService.endSession(state!.sessionId);
      } catch (e) {
        // Log error but continue with cleanup
      }
      state = null;
    }
  }

  Future<void> switchAgent(AgentType newAgentType) async {
    if (state != null) {
      try {
        final newSession = await _apiService.switchAgent(
          sessionId: state!.sessionId,
          newAgentType: newAgentType,
        );
        state = newSession;
      } catch (e) {
        // Error switching agent - keep current session
      }
    }
  }

  void updateSession(AISession session) {
    state = session;
  }

  void clearSession() {
    state = null;
  }
}

// Chat Messages State Notifier
class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  final AIApiService _apiService;
  final AIWebSocketClient _webSocketClient;
  final FlutterSecureStorage _secureStorage;
  final AIOfflineService _offlineService;
  final Ref _ref;
  StreamSubscription<AIEvent>? _eventSubscription;
  StreamSubscription<bool>? _offlineStatusSubscription;
  Timer? _retryTimer;
  String? _currentSessionId;
  String? _currentStreamingMessageId;

  ChatMessagesNotifier(
    this._apiService,
    this._webSocketClient,
    this._secureStorage,
    this._offlineService,
    this._ref,
  ) : super([]) {
    _initializeWebSocketListener();
    _initializeOfflineListener();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _offlineStatusSubscription?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }

  /// Initialize WebSocket event listener for real-time updates
  void _initializeWebSocketListener() {
    _eventSubscription = _webSocketClient.events.listen((event) {
      if (event.sessionId == _currentSessionId) {
        _handleWebSocketEvent(event);
      }
    });
  }

  /// Initialize offline status listener for queue management
  /// Requirement 2.5: Queue messages for transmission when connectivity returns
  void _initializeOfflineListener() {
    _offlineStatusSubscription = _offlineService.offlineStatus.listen((isOffline) {
      if (!isOffline && _currentSessionId != null) {
        // Connection restored - process queued messages
        _processQueuedMessages();
      }
    });
  }

  /// Handle WebSocket events for real-time chat updates
  void _handleWebSocketEvent(AIEvent event) {
    switch (event.eventType) {
      case AIEventType.token:
        _handleTokenEvent(event);
        break;
      case AIEventType.response:
        _handleResponseEvent(event);
        break;
      case AIEventType.toolCall:
        _handleToolCallEvent(event);
        break;
      case AIEventType.toolResult:
        _handleToolResultEvent(event);
        break;
      case AIEventType.tts:
        _handleTTSEvent(event);
        break;
      case AIEventType.thinking:
        _handleThinkingEvent(event);
        break;
      case AIEventType.typing:
        _handleTypingEvent(event);
        break;
      case AIEventType.error:
        _handleErrorEvent(event);
        break;
      default:
        // Handle other event types as needed
        break;
    }
  }

  /// Handle streaming token events
  void _handleTokenEvent(AIEvent event) {
    final token = event.data['token'] as String? ?? '';
    final messageId = event.data['message_id'] as String?;
    
    if (token.isNotEmpty) {
      addStreamingToken(
        sessionId: event.sessionId,
        token: token,
        messageId: messageId,
      );
    }
  }

  /// Handle complete response events
  void _handleResponseEvent(AIEvent event) {
    final content = event.data['content'] as String? ?? '';
    final messageId = event.data['message_id'] as String?;
    
    if (content.isNotEmpty) {
      final message = ChatMessage(
        messageId: messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: event.sessionId,
        content: content,
        role: MessageRole.assistant,
        agentType: event.agentType,
        timestamp: event.timestamp,
        messageType: MessageType.text,
        metadata: event.data,
      );
      
      _replaceOrAddMessage(message);
      _currentStreamingMessageId = null;
    }
  }

  /// Handle tool call events
  void _handleToolCallEvent(AIEvent event) {
    final toolName = event.data['tool_name'] as String? ?? '';
    final toolArgs = event.data['arguments'] as Map<String, dynamic>? ?? {};
    
    final message = ChatMessage(
      messageId: event.data['message_id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: event.sessionId,
      content: 'Executing tool: $toolName',
      role: MessageRole.assistant,
      agentType: event.agentType,
      timestamp: event.timestamp,
      messageType: MessageType.toolCall,
      metadata: {
        'tool_name': toolName,
        'arguments': toolArgs,
        'status': 'executing',
      },
    );
    
    addCompleteMessage(message);
  }

  /// Handle tool result events
  void _handleToolResultEvent(AIEvent event) {
    final toolName = event.data['tool_name'] as String? ?? '';
    final result = event.data['result'];
    final success = event.data['success'] as bool? ?? false;
    
    final message = ChatMessage(
      messageId: event.data['message_id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: event.sessionId,
      content: success 
          ? 'Tool $toolName completed successfully'
          : 'Tool $toolName failed: ${event.data['error'] ?? 'Unknown error'}',
      role: MessageRole.assistant,
      agentType: event.agentType,
      timestamp: event.timestamp,
      messageType: MessageType.toolResult,
      metadata: {
        'tool_name': toolName,
        'result': result,
        'success': success,
      },
    );
    
    addCompleteMessage(message);
  }

  /// Handle TTS audio events
  void _handleTTSEvent(AIEvent event) {
    final audioData = event.data['audio_data'] as String?;
    final messageId = event.data['message_id'] as String?;
    
    if (audioData != null && messageId != null) {
      // Update existing message with audio data
      final messages = List<ChatMessage>.from(state);
      final messageIndex = messages.indexWhere((m) => m.messageId == messageId);
      
      if (messageIndex != -1) {
        final updatedMessage = messages[messageIndex].copyWith(audioData: audioData);
        messages[messageIndex] = updatedMessage;
        state = messages;
        _persistMessages();
      }
    }
  }

  /// Handle thinking indicator events
  void _handleThinkingEvent(AIEvent event) {
    final isThinking = event.data['thinking'] as bool? ?? false;
    
    if (isThinking) {
      final thinkingMessage = ChatMessage(
        messageId: 'thinking_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: event.sessionId,
        content: 'AI is thinking...',
        role: MessageRole.system,
        timestamp: event.timestamp,
        messageType: MessageType.text,
        metadata: {'is_thinking': true},
      );
      
      addCompleteMessage(thinkingMessage);
    } else {
      // Remove thinking messages
      state = state.where((message) => 
          message.metadata['is_thinking'] != true).toList();
    }
  }

  /// Handle typing indicator events
  void _handleTypingEvent(AIEvent event) {
    final isTyping = event.data['typing'] as bool? ?? false;
    
    if (isTyping) {
      final typingMessage = ChatMessage(
        messageId: 'typing_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: event.sessionId,
        content: 'AI is typing...',
        role: MessageRole.system,
        timestamp: event.timestamp,
        messageType: MessageType.text,
        metadata: {'is_typing': true},
      );
      
      addCompleteMessage(typingMessage);
    } else {
      // Remove typing messages
      state = state.where((message) => 
          message.metadata['is_typing'] != true).toList();
    }
  }

  /// Handle error events
  void _handleErrorEvent(AIEvent event) {
    final errorMessage = event.data['message'] as String? ?? 'An error occurred';
    
    final message = ChatMessage(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: event.sessionId,
      content: 'Error: $errorMessage',
      role: MessageRole.system,
      timestamp: event.timestamp,
      messageType: MessageType.text,
      metadata: {'is_error': true, 'error_details': event.data},
    );
    
    addCompleteMessage(message);
  }

  /// Load session history from API and cache with pagination support
  /// Requirement 7.4: Display offline mode with cached conversation history
  /// Requirement 8.3: Implement pagination to handle large conversations
  Future<void> loadSessionHistory(String sessionId, {int limit = 50, bool loadMore = false}) async {
    _currentSessionId = sessionId;
    
    try {
      // First try to load from offline cache
      final cachedMessages = await _offlineService.loadCachedConversation(sessionId);
      if (cachedMessages.isNotEmpty && !loadMore) {
        state = cachedMessages;
        print('[ChatMessages] Loaded ${cachedMessages.length} cached messages for session $sessionId');
      }
      
      // If online, try to load from API to get latest messages
      if (!_offlineService.isOffline) {
        try {
          final offset = loadMore ? state.length : 0;
          final messages = await _apiService.getSessionHistory(
            sessionId: sessionId,
            limit: limit,
            offset: offset,
          );
          
          if (loadMore) {
            // Prepend older messages to existing state for pagination
            state = [...messages, ...state];
          } else {
            // Replace state with fresh messages
            state = messages;
          }
          
          // Cache the fresh messages
          await _offlineService.cacheConversationHistory(
            sessionId: sessionId,
            messages: state,
          );
          
          print('[ChatMessages] Loaded ${messages.length} messages from API for session $sessionId (loadMore: $loadMore)');
        } catch (e) {
          print('[ChatMessages] Error loading from API, using cached messages: $e');
          // Set offline status if API fails
          await _offlineService.setOfflineStatus(true);
        }
      } else {
        print('[ChatMessages] Offline mode - using cached messages only');
      }
      
    } catch (e) {
      print('[ChatMessages] Error loading session history: $e');
      // Keep any existing state if everything fails
    }
  }

  /// Load more messages for pagination (older messages) with optimized batching
  /// Requirement 8.3: Implement pagination to handle large conversations
  Future<bool> loadMoreMessages({int limit = 25}) async {
    if (_currentSessionId == null || _offlineService.isOffline) {
      return false;
    }

    try {
      final offset = state.length;
      
      // Use smaller batch size for faster loading
      final messages = await _apiService.getSessionHistory(
        sessionId: _currentSessionId!,
        limit: limit,
        offset: offset,
      );

      if (messages.isNotEmpty) {
        // Efficiently prepend older messages using spread operator
        final newState = <ChatMessage>[...messages, ...state];
        state = newState;
        
        // Cache only new messages to avoid full conversation re-caching
        await _offlineService.cacheMessageBatch(
          sessionId: _currentSessionId!,
          messages: messages,
          offset: offset,
        );
        
        print('[ChatMessages] Loaded ${messages.length} more messages for pagination (batch size: $limit)');
        return true;
      }
      
      return false; // No more messages to load
    } catch (e) {
      print('[ChatMessages] Error loading more messages: $e');
      return false;
    }
  }

  /// Get total message count for pagination UI
  int get totalMessageCount => state.length;

  /// Check if more messages are available for loading
  bool get hasMoreMessages => _currentSessionId != null && !_offlineService.isOffline;

  /// Send message through WebSocket for real-time delivery
  /// Requirement 2.5: Queue messages for transmission when connectivity returns
  /// Requirement 7.3: Cache messages locally and retry transmission
  Future<void> sendMessage({
    required String sessionId,
    required String content,
    MessageType messageType = MessageType.text,
    String? audioData,
    Map<String, dynamic>? metadata,
  }) async {
    _currentSessionId = sessionId;
    
    // Add user message immediately for UI responsiveness
    final userMessage = ChatMessage(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: sessionId,
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
      messageType: messageType,
      audioData: audioData,
      metadata: metadata ?? {},
    );
    
    state = [...state, userMessage];
    await _cacheCurrentConversation();

    // Check if offline - queue message if needed
    if (_offlineService.isOffline) {
      await _offlineService.queueMessage(
        sessionId: sessionId,
        content: content,
        messageType: messageType,
        audioData: audioData,
        metadata: metadata,
      );
      
      // Add queued indicator message
      final queuedIndicator = ChatMessage(
        messageId: 'queued_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: sessionId,
        content: 'Message queued for sending when connection is restored',
        role: MessageRole.system,
        timestamp: DateTime.now(),
        messageType: MessageType.text,
        metadata: {'is_queued': true},
      );
      state = [...state, queuedIndicator];
      await _cacheCurrentConversation();
      
      print('[ChatMessages] Message queued for offline transmission');
      return;
    }

    try {
      // Send through WebSocket for real-time delivery
      await _webSocketClient.sendMessage(
        content: content,
        messageType: messageType.toString().split('.').last,
        audioData: audioData,
        metadata: metadata,
      );
      
      print('[ChatMessages] Message sent via WebSocket');
    } catch (e) {
      print('[ChatMessages] Error sending message via WebSocket: $e');
      
      // Fallback to HTTP API
      try {
        await _apiService.sendMessage(
          sessionId: sessionId,
          content: content,
          messageType: messageType,
          audioData: audioData,
        );
        
        print('[ChatMessages] Message sent via HTTP API fallback');
      } catch (apiError) {
        print('[ChatMessages] HTTP API fallback failed: $apiError');
        
        // Queue message for retry
        await _offlineService.queueMessage(
          sessionId: sessionId,
          content: content,
          messageType: messageType,
          audioData: audioData,
          metadata: metadata,
        );
        
        // Set offline status
        await _offlineService.setOfflineStatus(true);
        
        // Add error message to chat
        final errorMessage = ChatMessage(
          messageId: DateTime.now().millisecondsSinceEpoch.toString(),
          sessionId: sessionId,
          content: 'Connection lost. Message queued for retry.',
          role: MessageRole.system,
          timestamp: DateTime.now(),
          messageType: MessageType.text,
          metadata: {'is_error': true, 'is_queued': true},
        );
        state = [...state, errorMessage];
        await _cacheCurrentConversation();
      }
    }
  }

  /// Add streaming token to the current assistant message
  void addStreamingToken({
    required String sessionId,
    required String token,
    String? messageId,
  }) {
    final messages = List<ChatMessage>.from(state);
    
    // Find existing streaming message or create new one
    if (_currentStreamingMessageId != null) {
      final messageIndex = messages.indexWhere(
        (m) => m.messageId == _currentStreamingMessageId,
      );
      
      if (messageIndex != -1) {
        // Append token to existing message
        final existingMessage = messages[messageIndex];
        final updatedMessage = existingMessage.copyWith(
          content: existingMessage.content + token,
        );
        messages[messageIndex] = updatedMessage;
      }
    } else {
      // Create new streaming message
      _currentStreamingMessageId = messageId ?? 
          'streaming_${DateTime.now().millisecondsSinceEpoch}';
      
      final newMessage = ChatMessage(
        messageId: _currentStreamingMessageId!,
        sessionId: sessionId,
        content: token,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        messageType: MessageType.text,
        metadata: {'is_streaming': true},
      );
      messages.add(newMessage);
    }
    
    state = messages;
    // Don't persist while streaming to avoid excessive writes
  }

  /// Replace or add a complete message (used when streaming is complete)
  void _replaceOrAddMessage(ChatMessage message) {
    final messages = List<ChatMessage>.from(state);
    final existingIndex = messages.indexWhere(
      (m) => m.messageId == message.messageId,
    );
    
    if (existingIndex != -1) {
      messages[existingIndex] = message;
    } else {
      messages.add(message);
    }
    
    state = messages;
    _persistMessages();
  }

  /// Add a complete message to the conversation
  void addCompleteMessage(ChatMessage message) {
    state = [...state, message];
    _persistMessages();
  }

  /// Clear all messages
  void clearMessages() {
    state = [];
    _currentStreamingMessageId = null;
    if (_currentSessionId != null) {
      _clearCachedMessages(_currentSessionId!);
    }
  }

  /// Process queued messages when connection is restored
  /// Requirement 2.5: Queue messages for transmission when connectivity returns
  Future<void> _processQueuedMessages() async {
    if (_currentSessionId == null) return;
    
    final readyMessages = _offlineService.getMessagesReadyForRetry();
    final sessionMessages = readyMessages
        .where((msg) => msg.sessionId == _currentSessionId)
        .toList();
    
    if (sessionMessages.isEmpty) return;
    
    print('[ChatMessages] Processing ${sessionMessages.length} queued messages');
    
    for (final queuedMessage in sessionMessages) {
      try {
        // Remove queued indicator messages
        state = state.where((msg) => 
            msg.metadata['is_queued'] != true ||
            msg.role != MessageRole.system).toList();
        
        // Try to send the message
        await _webSocketClient.sendMessage(
          content: queuedMessage.content,
          messageType: queuedMessage.messageType.toString().split('.').last,
          audioData: queuedMessage.audioData,
          metadata: queuedMessage.metadata,
        );
        
        // Remove from queue on success
        await _offlineService.removeQueuedMessage(queuedMessage.id);
        
        print('[ChatMessages] Successfully sent queued message: ${queuedMessage.id}');
        
      } catch (e) {
        print('[ChatMessages] Failed to send queued message: ${queuedMessage.id}, error: $e');
        
        // Update retry count
        await _offlineService.updateMessageRetryCount(
          queuedMessage.id,
          queuedMessage.retryCount + 1,
        );
        
        // If max retries reached, remove from queue
        if (!_offlineService.shouldRetryMessage(queuedMessage)) {
          await _offlineService.removeQueuedMessage(queuedMessage.id);
          
          // Add failure message to chat
          final failureMessage = ChatMessage(
            messageId: DateTime.now().millisecondsSinceEpoch.toString(),
            sessionId: _currentSessionId!,
            content: 'Failed to send message after multiple attempts: "${queuedMessage.content}"',
            role: MessageRole.system,
            timestamp: DateTime.now(),
            messageType: MessageType.text,
            metadata: {'is_error': true, 'failed_message': true},
          );
          state = [...state, failureMessage];
        }
      }
    }
    
    await _cacheCurrentConversation();
    
    // Schedule retry for remaining messages
    _scheduleRetryTimer();
  }

  /// Schedule retry timer for failed messages
  void _scheduleRetryTimer() {
    _retryTimer?.cancel();
    
    final readyMessages = _offlineService.getMessagesReadyForRetry();
    if (readyMessages.isEmpty) return;
    
    // Find the next retry time
    DateTime? nextRetryTime;
    for (final message in readyMessages) {
      if (message.sessionId != _currentSessionId) continue;
      
      final retryDelay = _offlineService.getRetryDelay(message.retryCount);
      final messageRetryTime = (message.lastRetryAt ?? message.timestamp).add(retryDelay);
      
      if (nextRetryTime == null || messageRetryTime.isBefore(nextRetryTime)) {
        nextRetryTime = messageRetryTime;
      }
    }
    
    if (nextRetryTime != null) {
      final delay = nextRetryTime.difference(DateTime.now());
      if (delay.isNegative) {
        // Retry immediately
        _processQueuedMessages();
      } else {
        _retryTimer = Timer(delay, () {
          _processQueuedMessages();
        });
        
        print('[ChatMessages] Scheduled retry in ${delay.inSeconds} seconds');
      }
    }
  }

  /// Cache current conversation using offline service
  /// Requirement 7.3: Cache messages locally
  Future<void> _cacheCurrentConversation() async {
    if (_currentSessionId != null && state.isNotEmpty) {
      await _offlineService.cacheConversationHistory(
        sessionId: _currentSessionId!,
        messages: state,
      );
    }
  }

  /// Remove a specific message
  void removeMessage(String messageId) {
    state = state.where((message) => message.messageId != messageId).toList();
    _persistMessages();
  }

  /// Persist messages to secure storage for offline access
  /// This method is kept for backward compatibility but now uses offline service
  Future<void> _persistMessages() async {
    await _cacheCurrentConversation();
  }

  /// Load cached messages from secure storage
  /// This method is kept for backward compatibility but now uses offline service
  Future<List<ChatMessage>> _loadCachedMessages(String sessionId) async {
    return await _offlineService.loadCachedConversation(sessionId);
  }

  /// Clear cached messages for a session
  /// This method is kept for backward compatibility but now uses offline service
  Future<void> _clearCachedMessages(String sessionId) async {
    await _offlineService.clearCachedConversation(sessionId);
  }

  /// Get message count for current session
  int get messageCount => state.length;

  /// Get last message timestamp
  DateTime? get lastMessageTimestamp {
    if (state.isEmpty) return null;
    return state.last.timestamp;
  }

  /// Check if currently streaming
  bool get isStreaming => _currentStreamingMessageId != null;

  /// Check if currently loading messages
  bool get isLoading => false; // TODO: Implement proper loading state tracking

  /// Get current session ID
  String? get currentSessionId => _currentSessionId;
}

// AI Connection State Notifier
class AIConnectionStateNotifier extends StateNotifier<AIConnectionState> {
  final AIWebSocketClient _webSocketClient;
  final Ref _ref;
  StreamSubscription<AIConnectionState>? _connectionSubscription;
  Timer? _reconnectTimer;
  Timer? _sessionExpiryTimer;
  AIOfflineService? _offlineService;
  
  // Reconnection parameters
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _baseReconnectDelay = Duration(seconds: 2);
  static const Duration _maxReconnectDelay = Duration(seconds: 30);
  
  // Session management
  String? _currentSessionId;
  DateTime? _sessionExpiryTime;

  AIConnectionStateNotifier(this._webSocketClient, this._ref) 
      : super(AIConnectionState.disconnected) {
    _initializeConnectionListener();
    _initializeOfflineService();
  }

  /// Initialize offline service reference
  void _initializeOfflineService() {
    try {
      _offlineService = _ref.read(aiOfflineServiceProvider);
    } catch (e) {
      print('[AIConnection] Could not initialize offline service: $e');
    }
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _reconnectTimer?.cancel();
    _sessionExpiryTimer?.cancel();
    super.dispose();
  }

  /// Initialize connection state listener
  void _initializeConnectionListener() {
    _connectionSubscription = _webSocketClient.connectionState.listen((newState) {
      _handleConnectionStateChange(newState);
    });
  }

  /// Handle connection state changes from WebSocket client
  void _handleConnectionStateChange(AIConnectionState newState) {
    final previousState = state;
    state = newState;
    
    switch (newState) {
      case AIConnectionState.connected:
        _onConnected();
        break;
      case AIConnectionState.disconnected:
        _onDisconnected(previousState);
        break;
      case AIConnectionState.error:
        _onError();
        break;
      case AIConnectionState.connecting:
      case AIConnectionState.reconnecting:
        // No special handling needed
        break;
    }
  }

  /// Handle successful connection
  void _onConnected() {
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _startSessionExpiryTimer();
    
    // Update offline status
    _offlineService?.setOfflineStatus(false);
    
    print('[AIConnection] Connected successfully');
  }

  /// Handle disconnection
  void _onDisconnected(AIConnectionState previousState) {
    _sessionExpiryTimer?.cancel();
    
    // Set offline status
    _offlineService?.setOfflineStatus(true);
    
    // Only attempt reconnection if we were previously connected
    // and it wasn't a manual disconnection
    if (previousState == AIConnectionState.connected && 
        _currentSessionId != null) {
      _scheduleReconnection();
    }
    
    print('[AIConnection] Disconnected');
  }

  /// Handle connection error
  void _onError() {
    _sessionExpiryTimer?.cancel();
    
    // Set offline status
    _offlineService?.setOfflineStatus(true);
    
    if (_currentSessionId != null) {
      _scheduleReconnection();
    }
    
    print('[AIConnection] Connection error occurred');
  }

  /// Connect to AI session with automatic reconnection
  Future<void> connectToSession(String sessionId, {String? agentType}) async {
    _currentSessionId = sessionId;
    _reconnectAttempts = 0;
    
    // Calculate session expiry (assuming 1 hour sessions)
    _sessionExpiryTime = DateTime.now().add(const Duration(hours: 1));
    
    try {
      await _webSocketClient.connect(sessionId, agentType: agentType);
    } catch (e) {
      print('[AIConnection] Failed to connect to session: $e');
      _scheduleReconnection();
    }
  }

  /// Disconnect from current session
  Future<void> disconnect() async {
    _currentSessionId = null;
    _sessionExpiryTime = null;
    _reconnectAttempts = 0;
    
    _reconnectTimer?.cancel();
    _sessionExpiryTimer?.cancel();
    
    await _webSocketClient.disconnect();
  }

  /// Schedule automatic reconnection with exponential backoff
  void _scheduleReconnection() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('[AIConnection] Max reconnection attempts reached');
      state = AIConnectionState.error;
      return;
    }

    if (_currentSessionId == null) {
      print('[AIConnection] No session ID for reconnection');
      return;
    }

    // Check if session has expired
    if (_sessionExpiryTime != null && DateTime.now().isAfter(_sessionExpiryTime!)) {
      print('[AIConnection] Session expired, not reconnecting');
      _handleSessionExpiry();
      return;
    }

    _reconnectAttempts++;
    
    // Calculate delay with exponential backoff and jitter
    final baseDelay = _baseReconnectDelay.inMilliseconds * (1 << (_reconnectAttempts - 1));
    final jitter = (baseDelay * 0.1 * (DateTime.now().millisecondsSinceEpoch % 100) / 100);
    final totalDelay = Duration(
      milliseconds: (baseDelay + jitter).clamp(
        _baseReconnectDelay.inMilliseconds,
        _maxReconnectDelay.inMilliseconds,
      ).toInt(),
    );

    print('[AIConnection] Scheduling reconnection attempt $_reconnectAttempts in ${totalDelay.inSeconds}s');
    
    state = AIConnectionState.reconnecting;
    
    _reconnectTimer = Timer(totalDelay, () {
      if (_currentSessionId != null) {
        _attemptReconnection();
      }
    });
  }

  /// Attempt to reconnect to the current session
  Future<void> _attemptReconnection() async {
    if (_currentSessionId == null) return;
    
    try {
      print('[AIConnection] Attempting reconnection to session $_currentSessionId');
      await _webSocketClient.connect(_currentSessionId!);
    } catch (e) {
      print('[AIConnection] Reconnection attempt failed: $e');
      _scheduleReconnection();
    }
  }

  /// Start session expiry timer
  void _startSessionExpiryTimer() {
    _sessionExpiryTimer?.cancel();
    
    if (_sessionExpiryTime == null) return;
    
    final timeUntilExpiry = _sessionExpiryTime!.difference(DateTime.now());
    
    if (timeUntilExpiry.isNegative) {
      _handleSessionExpiry();
      return;
    }
    
    _sessionExpiryTimer = Timer(timeUntilExpiry, () {
      _handleSessionExpiry();
    });
    
    print('[AIConnection] Session will expire in ${timeUntilExpiry.inMinutes} minutes');
  }

  /// Handle session expiry using existing SessionManager patterns
  void _handleSessionExpiry() {
    print('[AIConnection] AI session expired');
    
    // Import the session manager to handle expiry
    // This will follow existing patterns from the app
    try {
      // Try to get navigation context
      final navigationService = _ref.read(navigationServiceProvider);
      final context = navigationService.currentContext;
      
      if (context != null) {
        // Use existing session manager patterns
        // This would typically show a dialog and redirect to login if needed
        _showSessionExpiredDialog(context);
      } else {
        // Fallback: just disconnect
        disconnect();
      }
    } catch (e) {
      print('[AIConnection] Error handling session expiry: $e');
      disconnect();
    }
  }

  /// Show session expired dialog (following existing patterns)
  void _showSessionExpiredDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('AI Session Expired'),
        content: const Text(
          'Your AI chat session has expired. You can start a new session to continue chatting.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              disconnect();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Force reconnection (manual retry)
  Future<void> forceReconnect() async {
    if (_currentSessionId == null) return;
    
    _reconnectAttempts = 0;
    await _attemptReconnection();
  }

  /// Update session expiry time (when session is refreshed)
  void updateSessionExpiry(DateTime newExpiryTime) {
    _sessionExpiryTime = newExpiryTime;
    _startSessionExpiryTimer();
  }

  /// Check if connection is stable (connected without recent errors)
  bool get isStable => state == AIConnectionState.connected && _reconnectAttempts == 0;

  /// Check if currently attempting to reconnect
  bool get isReconnecting => state == AIConnectionState.reconnecting;

  /// Get current reconnection attempt count
  int get reconnectionAttempts => _reconnectAttempts;

  /// Get time until session expiry
  Duration? get timeUntilExpiry {
    if (_sessionExpiryTime == null) return null;
    final remaining = _sessionExpiryTime!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Check if session is near expiry (within 5 minutes)
  bool get isSessionNearExpiry {
    final remaining = timeUntilExpiry;
    return remaining != null && remaining.inMinutes <= 5;
  }

  /// Get current session ID
  String? get currentSessionId => _currentSessionId;

  /// Manual state setters for compatibility
  void setConnecting() {
    state = AIConnectionState.connecting;
  }

  void setConnected() {
    state = AIConnectionState.connected;
  }

  void setDisconnected() {
    state = AIConnectionState.disconnected;
  }

  void setError(String error) {
    print('[AIConnection] Error: $error');
    state = AIConnectionState.error;
  }

  void setReconnecting() {
    state = AIConnectionState.reconnecting;
  }
}