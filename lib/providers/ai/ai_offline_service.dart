import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/models/ai/ai_events.dart';

/// Provider for AI offline service following existing provider patterns
final aiOfflineServiceProvider = Provider<AIOfflineService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return AIOfflineService(secureStorage);
});

/// Service for handling offline AI functionality including message queuing and caching
/// Follows existing storage patterns from the app
class AIOfflineService {
  final FlutterSecureStorage _secureStorage;
  
  // Storage keys following existing patterns
  static const String _queuedMessagesKey = 'ai_queued_messages';
  static const String _offlineStatusKey = 'ai_offline_status';
  static const String _cachedSessionsKey = 'ai_cached_sessions';
  
  // Queue management
  final List<QueuedMessage> _messageQueue = [];
  final StreamController<List<QueuedMessage>> _queueController = 
      StreamController<List<QueuedMessage>>.broadcast();
  
  // Offline status management
  bool _isOffline = false;
  final StreamController<bool> _offlineStatusController = 
      StreamController<bool>.broadcast();
  
  // Retry parameters following existing patterns
  static const int _maxRetryAttempts = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 2);
  static const Duration _maxRetryDelay = Duration(seconds: 30);

  AIOfflineService(this._secureStorage) {
    _loadQueuedMessages();
    _loadOfflineStatus();
  }

  /// Stream of queued messages for UI updates
  Stream<List<QueuedMessage>> get queuedMessages => _queueController.stream;
  
  /// Stream of offline status for UI updates
  Stream<bool> get offlineStatus => _offlineStatusController.stream;
  
  /// Current offline status
  bool get isOffline => _isOffline;
  
  /// Current queued message count
  int get queuedMessageCount => _messageQueue.length;
  
  /// Get current message queue
  List<QueuedMessage> get currentQueue => List.unmodifiable(_messageQueue);

  /// Queue a message for offline transmission
  /// Requirement 2.5: Queue messages for transmission when connectivity returns
  Future<void> queueMessage({
    required String sessionId,
    required String content,
    required MessageType messageType,
    String? audioData,
    Map<String, dynamic>? metadata,
  }) async {
    try {
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
      await _persistMessageQueue();
      _queueController.add(List.from(_messageQueue));
      
      debugPrint('[AI_Offline] Message queued: ${queuedMessage.id}');
    } catch (e) {
      debugPrint('[AI_Offline] Error queuing message: $e');
    }
  }

  /// Remove a message from the queue (after successful transmission)
  Future<void> removeQueuedMessage(String messageId) async {
    try {
      _messageQueue.removeWhere((msg) => msg.id == messageId);
      await _persistMessageQueue();
      _queueController.add(List.from(_messageQueue));
      
      debugPrint('[AI_Offline] Message removed from queue: $messageId');
    } catch (e) {
      debugPrint('[AI_Offline] Error removing queued message: $e');
    }
  }

  /// Update retry count for a queued message
  Future<void> updateMessageRetryCount(String messageId, int retryCount) async {
    try {
      final messageIndex = _messageQueue.indexWhere((msg) => msg.id == messageId);
      if (messageIndex != -1) {
        final updatedMessage = _messageQueue[messageIndex].copyWith(
          retryCount: retryCount,
          lastRetryAt: DateTime.now(),
        );
        _messageQueue[messageIndex] = updatedMessage;
        await _persistMessageQueue();
        _queueController.add(List.from(_messageQueue));
      }
    } catch (e) {
      debugPrint('[AI_Offline] Error updating retry count: $e');
    }
  }

  /// Clear all queued messages
  Future<void> clearMessageQueue() async {
    try {
      _messageQueue.clear();
      await _persistMessageQueue();
      _queueController.add(List.from(_messageQueue));
      
      debugPrint('[AI_Offline] Message queue cleared');
    } catch (e) {
      debugPrint('[AI_Offline] Error clearing message queue: $e');
    }
  }

  /// Set offline status
  /// Requirement 7.4: Display offline mode with cached conversation history
  Future<void> setOfflineStatus(bool isOffline) async {
    try {
      if (_isOffline != isOffline) {
        _isOffline = isOffline;
        await _persistOfflineStatus();
        _offlineStatusController.add(_isOffline);
        
        debugPrint('[AI_Offline] Offline status changed: $isOffline');
      }
    } catch (e) {
      debugPrint('[AI_Offline] Error setting offline status: $e');
    }
  }

  /// Cache conversation history for offline access
  /// Requirement 7.3: Cache messages locally
  Future<void> cacheConversationHistory({
    required String sessionId,
    required List<ChatMessage> messages,
  }) async {
    try {
      final cacheKey = 'ai_conversation_cache_$sessionId';
      final messagesJson = messages.map((m) => m.toJson()).toList();
      final cacheData = {
        'session_id': sessionId,
        'messages': messagesJson,
        'cached_at': DateTime.now().toIso8601String(),
        'message_count': messages.length,
      };
      
      await _secureStorage.write(
        key: cacheKey,
        value: json.encode(cacheData),
      );
      
      // Update cached sessions list
      await _updateCachedSessionsList(sessionId);
      
      debugPrint('[AI_Offline] Conversation cached: $sessionId (${messages.length} messages)');
    } catch (e) {
      debugPrint('[AI_Offline] Error caching conversation: $e');
    }
  }

  /// Cache message batch for efficient pagination
  /// Requirement 8.3: Optimize message pagination and caching
  Future<void> cacheMessageBatch({
    required String sessionId,
    required List<ChatMessage> messages,
    required int offset,
  }) async {
    try {
      // Load existing cache
      final existingMessages = await loadCachedConversation(sessionId);
      
      // Merge with new batch (prepend older messages)
      final allMessages = [...messages, ...existingMessages];
      
      // Cache the merged conversation
      await cacheConversationHistory(
        sessionId: sessionId,
        messages: allMessages,
      );
      
      debugPrint('[AI_Offline] Message batch cached: $sessionId (${messages.length} new, ${allMessages.length} total)');
    } catch (e) {
      debugPrint('[AI_Offline] Error caching message batch: $e');
    }
  }

  /// Load cached conversation history
  Future<List<ChatMessage>> loadCachedConversation(String sessionId) async {
    try {
      final cacheKey = 'ai_conversation_cache_$sessionId';
      final cachedData = await _secureStorage.read(key: cacheKey);
      
      if (cachedData != null) {
        final cacheJson = json.decode(cachedData);
        final List<dynamic> messagesJson = cacheJson['messages'] ?? [];
        
        final messages = messagesJson
            .map((json) => ChatMessage.fromJson(json))
            .toList();
        
        debugPrint('[AI_Offline] Loaded cached conversation: $sessionId (${messages.length} messages)');
        return messages;
      }
    } catch (e) {
      debugPrint('[AI_Offline] Error loading cached conversation: $e');
    }
    
    return [];
  }

  /// Get all cached session IDs
  Future<List<String>> getCachedSessionIds() async {
    try {
      final cachedSessionsData = await _secureStorage.read(key: _cachedSessionsKey);
      if (cachedSessionsData != null) {
        final List<dynamic> sessionIds = json.decode(cachedSessionsData);
        return sessionIds.cast<String>();
      }
    } catch (e) {
      debugPrint('[AI_Offline] Error getting cached session IDs: $e');
    }
    
    return [];
  }

  /// Clear cached conversation for a session
  Future<void> clearCachedConversation(String sessionId) async {
    try {
      final cacheKey = 'ai_conversation_cache_$sessionId';
      await _secureStorage.delete(key: cacheKey);
      
      // Remove from cached sessions list
      await _removeCachedSessionFromList(sessionId);
      
      debugPrint('[AI_Offline] Cleared cached conversation: $sessionId');
    } catch (e) {
      debugPrint('[AI_Offline] Error clearing cached conversation: $e');
    }
  }

  /// Clear all cached conversations
  Future<void> clearAllCachedConversations() async {
    try {
      final cachedSessionIds = await getCachedSessionIds();
      
      for (final sessionId in cachedSessionIds) {
        final cacheKey = 'ai_conversation_cache_$sessionId';
        await _secureStorage.delete(key: cacheKey);
      }
      
      await _secureStorage.delete(key: _cachedSessionsKey);
      
      debugPrint('[AI_Offline] Cleared all cached conversations');
    } catch (e) {
      debugPrint('[AI_Offline] Error clearing all cached conversations: $e');
    }
  }

  /// Get cache info for a session
  Future<CacheInfo?> getCacheInfo(String sessionId) async {
    try {
      final cacheKey = 'ai_conversation_cache_$sessionId';
      final cachedData = await _secureStorage.read(key: cacheKey);
      
      if (cachedData != null) {
        final cacheJson = json.decode(cachedData);
        return CacheInfo(
          sessionId: sessionId,
          cachedAt: DateTime.parse(cacheJson['cached_at']),
          messageCount: cacheJson['message_count'] ?? 0,
        );
      }
    } catch (e) {
      debugPrint('[AI_Offline] Error getting cache info: $e');
    }
    
    return null;
  }

  /// Check if a session has cached data
  Future<bool> hasCachedConversation(String sessionId) async {
    final cacheInfo = await getCacheInfo(sessionId);
    return cacheInfo != null;
  }

  /// Get retry delay for a message based on retry count
  Duration getRetryDelay(int retryCount) {
    final baseDelay = _baseRetryDelay.inMilliseconds * (1 << retryCount);
    final jitter = (baseDelay * 0.1 * (DateTime.now().millisecondsSinceEpoch % 100) / 100);
    final totalDelay = Duration(
      milliseconds: (baseDelay + jitter).clamp(
        _baseRetryDelay.inMilliseconds,
        _maxRetryDelay.inMilliseconds,
      ).toInt(),
    );
    
    return totalDelay;
  }

  /// Check if a message should be retried
  bool shouldRetryMessage(QueuedMessage message) {
    return message.retryCount < _maxRetryAttempts;
  }

  /// Get messages that are ready for retry
  List<QueuedMessage> getMessagesReadyForRetry() {
    final now = DateTime.now();
    return _messageQueue.where((message) {
      if (!shouldRetryMessage(message)) return false;
      
      if (message.lastRetryAt == null) return true;
      
      final retryDelay = getRetryDelay(message.retryCount);
      final nextRetryTime = message.lastRetryAt!.add(retryDelay);
      
      return now.isAfter(nextRetryTime);
    }).toList();
  }

  /// Load queued messages from storage
  Future<void> _loadQueuedMessages() async {
    try {
      final queueData = await _secureStorage.read(key: _queuedMessagesKey);
      if (queueData != null) {
        final List<dynamic> messagesJson = json.decode(queueData);
        _messageQueue.clear();
        _messageQueue.addAll(
          messagesJson.map((json) => QueuedMessage.fromJson(json)),
        );
        _queueController.add(List.from(_messageQueue));
        
        debugPrint('[AI_Offline] Loaded ${_messageQueue.length} queued messages');
      }
    } catch (e) {
      debugPrint('[AI_Offline] Error loading queued messages: $e');
    }
  }

  /// Persist message queue to storage
  Future<void> _persistMessageQueue() async {
    try {
      final messagesJson = _messageQueue.map((m) => m.toJson()).toList();
      await _secureStorage.write(
        key: _queuedMessagesKey,
        value: json.encode(messagesJson),
      );
    } catch (e) {
      debugPrint('[AI_Offline] Error persisting message queue: $e');
    }
  }

  /// Load offline status from storage
  Future<void> _loadOfflineStatus() async {
    try {
      final statusData = await _secureStorage.read(key: _offlineStatusKey);
      if (statusData != null) {
        _isOffline = json.decode(statusData) as bool;
        _offlineStatusController.add(_isOffline);
      }
    } catch (e) {
      debugPrint('[AI_Offline] Error loading offline status: $e');
    }
  }

  /// Persist offline status to storage
  Future<void> _persistOfflineStatus() async {
    try {
      await _secureStorage.write(
        key: _offlineStatusKey,
        value: json.encode(_isOffline),
      );
    } catch (e) {
      debugPrint('[AI_Offline] Error persisting offline status: $e');
    }
  }

  /// Update cached sessions list
  Future<void> _updateCachedSessionsList(String sessionId) async {
    try {
      final cachedSessionIds = await getCachedSessionIds();
      if (!cachedSessionIds.contains(sessionId)) {
        cachedSessionIds.add(sessionId);
        await _secureStorage.write(
          key: _cachedSessionsKey,
          value: json.encode(cachedSessionIds),
        );
      }
    } catch (e) {
      debugPrint('[AI_Offline] Error updating cached sessions list: $e');
    }
  }

  /// Remove session from cached sessions list
  Future<void> _removeCachedSessionFromList(String sessionId) async {
    try {
      final cachedSessionIds = await getCachedSessionIds();
      cachedSessionIds.remove(sessionId);
      await _secureStorage.write(
        key: _cachedSessionsKey,
        value: json.encode(cachedSessionIds),
      );
    } catch (e) {
      debugPrint('[AI_Offline] Error removing session from cached list: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _queueController.close();
    _offlineStatusController.close();
  }
}

/// Model for queued messages
class QueuedMessage {
  final String id;
  final String sessionId;
  final String content;
  final MessageType messageType;
  final String? audioData;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final int retryCount;
  final DateTime? lastRetryAt;

  const QueuedMessage({
    required this.id,
    required this.sessionId,
    required this.content,
    required this.messageType,
    this.audioData,
    required this.metadata,
    required this.timestamp,
    required this.retryCount,
    this.lastRetryAt,
  });

  /// Create a copy with updated properties
  QueuedMessage copyWith({
    String? id,
    String? sessionId,
    String? content,
    MessageType? messageType,
    String? audioData,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
    int? retryCount,
    DateTime? lastRetryAt,
  }) {
    return QueuedMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      audioData: audioData ?? this.audioData,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'content': content,
      'message_type': messageType.toString().split('.').last,
      'audio_data': audioData,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'retry_count': retryCount,
      'last_retry_at': lastRetryAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory QueuedMessage.fromJson(Map<String, dynamic> json) {
    return QueuedMessage(
      id: json['id'],
      sessionId: json['session_id'],
      content: json['content'],
      messageType: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['message_type'],
        orElse: () => MessageType.text,
      ),
      audioData: json['audio_data'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retry_count'] ?? 0,
      lastRetryAt: json['last_retry_at'] != null 
          ? DateTime.parse(json['last_retry_at'])
          : null,
    );
  }

  @override
  String toString() {
    return 'QueuedMessage(id: $id, sessionId: $sessionId, messageType: $messageType, retryCount: $retryCount)';
  }
}

/// Model for cache information
class CacheInfo {
  final String sessionId;
  final DateTime cachedAt;
  final int messageCount;

  const CacheInfo({
    required this.sessionId,
    required this.cachedAt,
    required this.messageCount,
  });

  /// Check if cache is stale (older than 1 hour)
  bool get isStale {
    final now = DateTime.now();
    final cacheAge = now.difference(cachedAt);
    return cacheAge.inHours >= 1;
  }

  /// Get cache age as a human-readable string
  String get ageDescription {
    final now = DateTime.now();
    final age = now.difference(cachedAt);
    
    if (age.inMinutes < 1) {
      return 'Just now';
    } else if (age.inHours < 1) {
      return '${age.inMinutes} minutes ago';
    } else if (age.inDays < 1) {
      return '${age.inHours} hours ago';
    } else {
      return '${age.inDays} days ago';
    }
  }

  @override
  String toString() {
    return 'CacheInfo(sessionId: $sessionId, cachedAt: $cachedAt, messageCount: $messageCount)';
  }
}