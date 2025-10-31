import 'dart:async';
import 'dart:convert';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/providers/user_agent_util.dart';
import 'package:emotion_tracker/core/session_manager.dart';
import 'package:emotion_tracker/core/exceptions.dart' as core_exceptions;
import 'package:emotion_tracker/models/ai/ai_events.dart';

enum AIConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// WebSocket connection pool for efficient connection management
/// Requirement 8.2: Add WebSocket connection pooling and efficient state updates
class AIWebSocketConnectionPool {
  final Ref _ref;
  final Map<String, WebSocketChannel> _connectionPool = {};
  final Map<String, DateTime> _lastUsed = {};
  final Queue<AIEvent> _eventBuffer = Queue<AIEvent>();
  Timer? _cleanupTimer;
  Timer? _bufferFlushTimer;
  
  static const int _maxConnections = 3;
  static const Duration _connectionTimeout = Duration(minutes: 5);
  static const Duration _bufferFlushInterval = Duration(milliseconds: 50);
  
  AIWebSocketConnectionPool(this._ref) {
    _startCleanupTimer();
    _startBufferFlushTimer();
  }

  /// Get or create a WebSocket connection for a session
  WebSocketChannel? getConnection(String sessionId) {
    _lastUsed[sessionId] = DateTime.now();
    return _connectionPool[sessionId];
  }

  /// Add a connection to the pool with optimized management
  void addConnection(String sessionId, WebSocketChannel channel) {
    // Check if connection already exists
    if (_connectionPool.containsKey(sessionId)) {
      _lastUsed[sessionId] = DateTime.now();
      return; // Reuse existing connection
    }
    
    // Remove oldest connection if pool is full
    if (_connectionPool.length >= _maxConnections) {
      _removeOldestConnection();
    }
    
    _connectionPool[sessionId] = channel;
    _lastUsed[sessionId] = DateTime.now();
    
    print('[WS_Pool] Added connection for session $sessionId (pool size: ${_connectionPool.length})');
  }

  /// Remove a connection from the pool
  void removeConnection(String sessionId) {
    final channel = _connectionPool.remove(sessionId);
    _lastUsed.remove(sessionId);
    
    if (channel != null) {
      try {
        channel.sink.close(status.normalClosure);
      } catch (e) {
        print('[WS_Pool] Error closing connection for session $sessionId: $e');
      }
      print('[WS_Pool] Removed connection for session $sessionId');
    }
  }

  /// Buffer events for efficient batch processing
  void bufferEvent(AIEvent event) {
    _eventBuffer.add(event);
    
    // If buffer is getting large, flush immediately
    if (_eventBuffer.length > 10) {
      _flushEventBuffer();
    }
  }

  /// Get buffered events and clear buffer
  List<AIEvent> getBufferedEvents() {
    final events = List<AIEvent>.from(_eventBuffer);
    _eventBuffer.clear();
    return events;
  }

  /// Remove oldest connection when pool is full
  void _removeOldestConnection() {
    if (_lastUsed.isEmpty) return;
    
    String? oldestSession;
    DateTime? oldestTime;
    
    for (final entry in _lastUsed.entries) {
      if (oldestTime == null || entry.value.isBefore(oldestTime)) {
        oldestTime = entry.value;
        oldestSession = entry.key;
      }
    }
    
    if (oldestSession != null) {
      removeConnection(oldestSession);
    }
  }

  /// Start cleanup timer to remove stale connections
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      final staleConnections = <String>[];
      
      for (final entry in _lastUsed.entries) {
        if (now.difference(entry.value) > _connectionTimeout) {
          staleConnections.add(entry.key);
        }
      }
      
      for (final sessionId in staleConnections) {
        removeConnection(sessionId);
        print('[WS_Pool] Removed stale connection for session $sessionId');
      }
    });
  }

  /// Start buffer flush timer for efficient event processing
  void _startBufferFlushTimer() {
    _bufferFlushTimer = Timer.periodic(_bufferFlushInterval, (timer) {
      if (_eventBuffer.isNotEmpty) {
        _flushEventBuffer();
      }
    });
  }

  /// Flush event buffer
  void _flushEventBuffer() {
    if (_eventBuffer.isEmpty) return;
    
    // Events will be processed by the client that calls getBufferedEvents()
    print('[WS_Pool] Flushing ${_eventBuffer.length} buffered events');
  }

  /// Get pool statistics
  Map<String, dynamic> getPoolStats() {
    return {
      'active_connections': _connectionPool.length,
      'max_connections': _maxConnections,
      'buffered_events': _eventBuffer.length,
      'sessions': _connectionPool.keys.toList(),
    };
  }

  /// Dispose all connections and timers
  void dispose() {
    _cleanupTimer?.cancel();
    _bufferFlushTimer?.cancel();
    
    for (final channel in _connectionPool.values) {
      try {
        channel.sink.close(status.normalClosure);
      } catch (e) {
        print('[WS_Pool] Error closing connection during dispose: $e');
      }
    }
    
    _connectionPool.clear();
    _lastUsed.clear();
    _eventBuffer.clear();
  }
}

// WebSocket connection pool for efficient connection management
final aiWebSocketConnectionPoolProvider = Provider((ref) => AIWebSocketConnectionPool(ref));

final aiWebSocketClientProvider = Provider((ref) => AIWebSocketClient(ref));

class AIWebSocketClient {
  final Ref _ref;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  Timer? _stateUpdateTimer;
  
  // Connection state management
  final _connectionStateController = StreamController<AIConnectionState>.broadcast();
  AIConnectionState _currentState = AIConnectionState.disconnected;
  
  // Event stream management
  final _eventController = StreamController<AIEvent>.broadcast();
  
  // Reconnection parameters
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _baseReconnectDelay = Duration(seconds: 2);
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  
  // Current session tracking
  String? _currentSessionId;
  String? _currentAgentType;
  
  // Connection pool reference
  AIWebSocketConnectionPool? _connectionPool;

  AIWebSocketClient(this._ref) {
    _initializeConnectionPool();
    _startEfficientStateUpdates();
  }

  /// Initialize connection pool
  void _initializeConnectionPool() {
    try {
      _connectionPool = _ref.read(aiWebSocketConnectionPoolProvider);
    } catch (e) {
      print('[AI_WS] Could not initialize connection pool: $e');
    }
  }

  /// Start efficient state update timer to batch UI updates
  /// Requirement 8.2: Add WebSocket connection pooling and efficient state updates
  void _startEfficientStateUpdates() {
    _stateUpdateTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      // Process buffered events at 60fps for smooth UI updates
      if (_connectionPool != null) {
        final bufferedEvents = _connectionPool!.getBufferedEvents();
        for (final event in bufferedEvents) {
          _eventController.add(event);
        }
      }
    });
  }

  // Getters for streams
  Stream<AIConnectionState> get connectionState => _connectionStateController.stream;
  Stream<AIEvent> get events => _eventController.stream;
  AIConnectionState get currentState => _currentState;
  String? get currentSessionId => _currentSessionId;
  String? get currentAgentType => _currentAgentType;

  /// Connect to AI WebSocket with session ID using connection pool
  /// Requirement 8.2: Add WebSocket connection pooling and efficient state updates
  Future<void> connect(String sessionId, {String? agentType}) async {
    if (_currentState == AIConnectionState.connected && _currentSessionId == sessionId) {
      print('[AI_WS] Already connected to session $sessionId');
      return;
    }

    // Check if connection exists in pool
    if (_connectionPool != null) {
      final existingChannel = _connectionPool!.getConnection(sessionId);
      if (existingChannel != null) {
        print('[AI_WS] Reusing pooled connection for session $sessionId');
        _channel = existingChannel;
        _currentSessionId = sessionId;
        _currentAgentType = agentType;
        _updateConnectionState(AIConnectionState.connected);
        return;
      }
    }

    await disconnect(); // Clean up any existing connection
    
    _currentSessionId = sessionId;
    _currentAgentType = agentType;
    _updateConnectionState(AIConnectionState.connecting);

    try {
      final wsUrl = await _buildWebSocketUrl(sessionId);
      final headers = await _getWebSocketHeaders();
      
      print('[AI_WS] Connecting to: $wsUrl');
      
      _channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
        protocols: ['ai-chat'],
      );

      // Set up message handling with efficient buffering
      _subscription = _channel!.stream.listen(
        _handleMessageEfficiently,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

      // Add to connection pool
      if (_connectionPool != null) {
        _connectionPool!.addConnection(sessionId, _channel!);
      }

      // Start heartbeat
      _startHeartbeat();
      
      _updateConnectionState(AIConnectionState.connected);
      _reconnectAttempts = 0;
      
      print('[AI_WS] Connected successfully to session $sessionId');
      
    } catch (e) {
      print('[AI_WS] Connection failed: $e');
      _updateConnectionState(AIConnectionState.error);
      _scheduleReconnect();
    }
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    print('[AI_WS] Disconnecting...');
    
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    
    await _subscription?.cancel();
    _subscription = null;
    
    // Don't close channel if it's in the pool - let pool manage it
    if (_connectionPool == null || _currentSessionId == null) {
      await _channel?.sink.close(status.normalClosure);
    }
    _channel = null;
    
    _currentSessionId = null;
    _currentAgentType = null;
    _reconnectAttempts = 0;
    
    _updateConnectionState(AIConnectionState.disconnected);
  }

  /// Send a message through WebSocket
  Future<void> sendMessage({
    required String content,
    String messageType = 'text',
    String? audioData,
    Map<String, dynamic>? metadata,
  }) async {
    if (_channel == null || _currentState != AIConnectionState.connected) {
      throw Exception('WebSocket not connected');
    }

    final message = {
      'type': 'message',
      'data': {
        'content': content,
        'message_type': messageType,
        if (audioData != null) 'audio_data': audioData,
        if (metadata != null) 'metadata': metadata,
      },
      'session_id': _currentSessionId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      _channel!.sink.add(json.encode(message));
      print('[AI_WS] Message sent: ${messageType} message');
    } catch (e) {
      print('[AI_WS] Failed to send message: $e');
      rethrow;
    }
  }

  /// Switch agent in current session
  Future<void> switchAgent(String newAgentType) async {
    if (_channel == null || _currentState != AIConnectionState.connected) {
      throw Exception('WebSocket not connected');
    }

    final message = {
      'type': 'switch_agent',
      'data': {
        'agent_type': newAgentType,
      },
      'session_id': _currentSessionId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      _channel!.sink.add(json.encode(message));
      _currentAgentType = newAgentType;
      print('[AI_WS] Agent switch requested: $newAgentType');
    } catch (e) {
      print('[AI_WS] Failed to switch agent: $e');
      rethrow;
    }
  }

  /// Send voice data
  Future<void> sendVoiceData(String audioData) async {
    await sendMessage(
      content: '',
      messageType: 'voice',
      audioData: audioData,
    );
  }

  /// Build WebSocket URL with authentication
  Future<String> _buildWebSocketUrl(String sessionId) async {
    final baseUrl = _ref.read(apiBaseUrlProvider);
    final token = await _getAccessToken();
    
    // Convert HTTP URL to WebSocket URL
    final wsBaseUrl = baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    
    return '$wsBaseUrl/ai/sessions/$sessionId/ws?token=$token';
  }

  /// Get access token from secure storage
  Future<String> _getAccessToken() async {
    final secureStorage = _ref.read(secureStorageProvider);
    final token = await secureStorage.read(key: 'access_token');
    if (token == null) {
      throw core_exceptions.UnauthorizedException(
        'Session expired. Please log in again.',
      );
    }
    return token;
  }

  /// Get WebSocket headers
  Future<Map<String, String>> _getWebSocketHeaders() async {
    final userAgent = await getUserAgent();
    return {
      'User-Agent': userAgent,
      'X-User-Agent': userAgent,
    };
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message.toString());
      final event = AIEvent.fromJson(data);
      
      print('[AI_WS] Received event: ${event.eventType} for session ${event.sessionId}');
      
      // Handle special events
      switch (event.eventType) {
        case AIEventType.error:
          _handleServerError(event);
          break;
        case AIEventType.response:
          // Handle session end or agent switch based on data content
          if (event.data['action'] == 'session_end') {
            _handleSessionEnd(event);
          } else if (event.data['action'] == 'agent_switch') {
            _currentAgentType = event.agentType;
          }
          break;
        default:
          // Regular event, forward to listeners
          break;
      }
      
      _eventController.add(event);
      
    } catch (e) {
      print('[AI_WS] Failed to parse message: $e');
      print('[AI_WS] Raw message: $message');
    }
  }

  /// Handle incoming WebSocket messages with efficient buffering
  /// Requirement 8.2: Add WebSocket connection pooling and efficient state updates
  void _handleMessageEfficiently(dynamic message) {
    try {
      final data = json.decode(message.toString());
      final event = AIEvent.fromJson(data);
      
      // Handle special events immediately
      switch (event.eventType) {
        case AIEventType.error:
          _handleServerError(event);
          _eventController.add(event); // Immediate error handling
          break;
        case AIEventType.response:
          // Handle session end or agent switch based on data content
          if (event.data['action'] == 'session_end') {
            _handleSessionEnd(event);
            _eventController.add(event); // Immediate session end handling
          } else if (event.data['action'] == 'agent_switch') {
            _currentAgentType = event.agentType;
            _eventController.add(event); // Immediate agent switch handling
          } else {
            // Buffer regular response events for efficient processing
            _bufferEvent(event);
          }
          break;
        case AIEventType.token:
          // Buffer streaming tokens for smooth UI updates
          _bufferEvent(event);
          break;
        default:
          // Buffer other events for batch processing
          _bufferEvent(event);
          break;
      }
      
    } catch (e) {
      print('[AI_WS] Failed to parse message: $e');
      print('[AI_WS] Raw message: $message');
    }
  }

  /// Buffer event for efficient processing
  void _bufferEvent(AIEvent event) {
    if (_connectionPool != null) {
      _connectionPool!.bufferEvent(event);
    } else {
      // Fallback to immediate processing if no pool
      _eventController.add(event);
    }
  }

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    print('[AI_WS] WebSocket error: $error');
    
    // Check if it's an authentication error
    if (error.toString().contains('401') || error.toString().contains('Unauthorized')) {
      _handleAuthenticationError();
      return;
    }
    
    _updateConnectionState(AIConnectionState.error);
    _scheduleReconnect();
  }

  /// Handle WebSocket disconnection
  void _handleDisconnection() {
    print('[AI_WS] WebSocket disconnected');
    
    if (_currentState != AIConnectionState.disconnected) {
      _updateConnectionState(AIConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  /// Handle server-sent error events
  void _handleServerError(AIEvent event) {
    final errorType = event.data['error_type'] as String?;
    final errorMessage = event.data['message'] as String?;
    
    print('[AI_WS] Server error: $errorType - $errorMessage');
    
    if (errorType == 'authentication_error' || errorType == 'session_expired') {
      _handleAuthenticationError();
    }
  }

  /// Handle session end events
  void _handleSessionEnd(AIEvent event) {
    print('[AI_WS] Session ended: ${event.data['reason']}');
    disconnect();
  }

  /// Handle authentication errors
  void _handleAuthenticationError() {
    print('[AI_WS] Authentication error - session expired');
    
    // Use existing session manager to handle session expiry
    // This will clear auth data and redirect to login
    // Fire and forget - don't await to avoid blocking the WebSocket handler
    _ref.read(authProvider.notifier).logout().then((_) {
      // Use navigation service to redirect
      final navigationService = _ref.read(navigationServiceProvider);
      navigationService.navigateToAndClearStack('/auth/v1');
    }).catchError((e) {
      print('[AIWebSocket] Error handling session expiry: $e');
      // Fallback: just navigate to login
      final navigationService = _ref.read(navigationServiceProvider);
      navigationService.navigateToAndClearStack('/auth/v1');
    });
  }

  /// Schedule reconnection with exponential backoff
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('[AI_WS] Max reconnection attempts reached');
      _updateConnectionState(AIConnectionState.error);
      return;
    }

    if (_currentSessionId == null) {
      print('[AI_WS] No session ID for reconnection');
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(
      milliseconds: (_baseReconnectDelay.inMilliseconds * 
          (1 << (_reconnectAttempts - 1))).clamp(0, 30000),
    );

    print('[AI_WS] Scheduling reconnection attempt $_reconnectAttempts in ${delay.inSeconds}s');
    
    _updateConnectionState(AIConnectionState.reconnecting);
    
    _reconnectTimer = Timer(delay, () {
      if (_currentSessionId != null) {
        connect(_currentSessionId!, agentType: _currentAgentType);
      }
    });
  }

  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_channel != null && _currentState == AIConnectionState.connected) {
        try {
          final heartbeat = {
            'type': 'heartbeat',
            'timestamp': DateTime.now().toIso8601String(),
          };
          _channel!.sink.add(json.encode(heartbeat));
        } catch (e) {
          print('[AI_WS] Heartbeat failed: $e');
        }
      }
    });
  }

  /// Update connection state and notify listeners
  void _updateConnectionState(AIConnectionState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _connectionStateController.add(newState);
      print('[AI_WS] Connection state changed to: $newState');
    }
  }

  /// Dispose resources
  void dispose() {
    _stateUpdateTimer?.cancel();
    disconnect();
    _connectionStateController.close();
    _eventController.close();
  }
}