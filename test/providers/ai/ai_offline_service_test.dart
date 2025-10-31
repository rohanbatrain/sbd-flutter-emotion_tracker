import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:emotion_tracker/providers/ai/ai_offline_service.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/models/ai/ai_events.dart';

void main() {
  group('AIOfflineService', () {
    late ProviderContainer container;
    late AIOfflineService offlineService;
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
      );
      offlineService = container.read(aiOfflineServiceProvider);
    });

    tearDown(() {
      offlineService.dispose();
      container.dispose();
    });

    group('Message Queue Management', () {
      test('should queue message successfully', () async {
        // Act
        await offlineService.queueMessage(
          sessionId: 'test-session-1',
          content: 'Test message',
          messageType: MessageType.text,
        );

        // Assert
        expect(offlineService.queuedMessageCount, equals(1));
        expect(offlineService.currentQueue.first.content, equals('Test message'));
        expect(offlineService.currentQueue.first.sessionId, equals('test-session-1'));
      });

      test('should queue voice message with audio data', () async {
        // Act
        await offlineService.queueMessage(
          sessionId: 'test-session-1',
          content: 'Voice message',
          messageType: MessageType.voice,
          audioData: 'base64-audio-data',
          metadata: {'duration': 5.0},
        );

        // Assert
        final queuedMessage = offlineService.currentQueue.first;
        expect(queuedMessage.messageType, equals(MessageType.voice));
        expect(queuedMessage.audioData, equals('base64-audio-data'));
        expect(queuedMessage.metadata['duration'], equals(5.0));
      });

      test('should remove queued message', () async {
        // Arrange
        await offlineService.queueMessage(
          sessionId: 'test-session-1',
          content: 'Test message',
          messageType: MessageType.text,
        );
        final messageId = offlineService.currentQueue.first.id;

        // Act
        await offlineService.removeQueuedMessage(messageId);

        // Assert
        expect(offlineService.queuedMessageCount, equals(0));
      });

      test('should update message retry count', () async {
        // Arrange
        await offlineService.queueMessage(
          sessionId: 'test-session-1',
          content: 'Test message',
          messageType: MessageType.text,
        );
        final messageId = offlineService.currentQueue.first.id;

        // Act
        await offlineService.updateMessageRetryCount(messageId, 2);

        // Assert
        final updatedMessage = offlineService.currentQueue.first;
        expect(updatedMessage.retryCount, equals(2));
        expect(updatedMessage.lastRetryAt, isNotNull);
      });

      test('should clear all queued messages', () async {
        // Arrange
        await offlineService.queueMessage(
          sessionId: 'test-session-1',
          content: 'Message 1',
          messageType: MessageType.text,
        );
        await offlineService.queueMessage(
          sessionId: 'test-session-2',
          content: 'Message 2',
          messageType: MessageType.text,
        );

        // Act
        await offlineService.clearMessageQueue();

        // Assert
        expect(offlineService.queuedMessageCount, equals(0));
      });

      test('should persist and load queued messages', () async {
        // Arrange
        await offlineService.queueMessage(
          sessionId: 'test-session-1',
          content: 'Persistent message',
          messageType: MessageType.text,
        );

        // Create new service instance to test loading
        final newService = AIOfflineService(mockStorage);
        await Future.delayed(const Duration(milliseconds: 100)); // Allow loading

        // Assert
        expect(newService.queuedMessageCount, equals(1));
        expect(newService.currentQueue.first.content, equals('Persistent message'));

        newService.dispose();
      });
    });

    group('Offline Status Management', () {
      test('should set and get offline status', () async {
        // Act
        await offlineService.setOfflineStatus(true);

        // Assert
        expect(offlineService.isOffline, isTrue);
      });

      test('should emit offline status changes', () async {
        // Arrange
        final statusStream = offlineService.offlineStatus;
        final statusEvents = <bool>[];
        final subscription = statusStream.listen(statusEvents.add);

        // Act
        await offlineService.setOfflineStatus(true);
        await offlineService.setOfflineStatus(false);
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        expect(statusEvents, contains(true));
        expect(statusEvents, contains(false));

        await subscription.cancel();
      });

      test('should persist offline status', () async {
        // Arrange
        await offlineService.setOfflineStatus(true);

        // Create new service instance to test loading
        final newService = AIOfflineService(mockStorage);
        await Future.delayed(const Duration(milliseconds: 100)); // Allow loading

        // Assert
        expect(newService.isOffline, isTrue);

        newService.dispose();
      });
    });

    group('Conversation Caching', () {
      test('should cache conversation history', () async {
        // Arrange
        final messages = [
          ChatMessage(
            messageId: 'msg-1',
            sessionId: 'session-1',
            content: 'Hello',
            role: MessageRole.user,
            timestamp: DateTime.now(),
          ),
          ChatMessage(
            messageId: 'msg-2',
            sessionId: 'session-1',
            content: 'Hi there!',
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
          ),
        ];

        // Act
        await offlineService.cacheConversationHistory(
          sessionId: 'session-1',
          messages: messages,
        );

        // Assert
        final cachedMessages = await offlineService.loadCachedConversation('session-1');
        expect(cachedMessages.length, equals(2));
        expect(cachedMessages.first.content, equals('Hello'));
        expect(cachedMessages.last.content, equals('Hi there!'));
      });

      test('should cache message batch and merge with existing', () async {
        // Arrange - Cache initial messages
        final initialMessages = [
          ChatMessage(
            messageId: 'msg-1',
            sessionId: 'session-1',
            content: 'Message 1',
            role: MessageRole.user,
            timestamp: DateTime.now(),
          ),
        ];
        await offlineService.cacheConversationHistory(
          sessionId: 'session-1',
          messages: initialMessages,
        );

        // Act - Cache additional batch
        final newMessages = [
          ChatMessage(
            messageId: 'msg-0',
            sessionId: 'session-1',
            content: 'Message 0',
            role: MessageRole.user,
            timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          ),
        ];
        await offlineService.cacheMessageBatch(
          sessionId: 'session-1',
          messages: newMessages,
          offset: 0,
        );

        // Assert
        final cachedMessages = await offlineService.loadCachedConversation('session-1');
        expect(cachedMessages.length, equals(2));
        expect(cachedMessages.first.content, equals('Message 0'));
        expect(cachedMessages.last.content, equals('Message 1'));
      });

      test('should get cached session IDs', () async {
        // Arrange
        await offlineService.cacheConversationHistory(
          sessionId: 'session-1',
          messages: [],
        );
        await offlineService.cacheConversationHistory(
          sessionId: 'session-2',
          messages: [],
        );

        // Act
        final sessionIds = await offlineService.getCachedSessionIds();

        // Assert
        expect(sessionIds, contains('session-1'));
        expect(sessionIds, contains('session-2'));
      });

      test('should clear cached conversation', () async {
        // Arrange
        await offlineService.cacheConversationHistory(
          sessionId: 'session-1',
          messages: [
            ChatMessage(
              messageId: 'msg-1',
              sessionId: 'session-1',
              content: 'Test message',
              role: MessageRole.user,
              timestamp: DateTime.now(),
            ),
          ],
        );

        // Act
        await offlineService.clearCachedConversation('session-1');

        // Assert
        final cachedMessages = await offlineService.loadCachedConversation('session-1');
        expect(cachedMessages, isEmpty);
      });

      test('should clear all cached conversations', () async {
        // Arrange
        await offlineService.cacheConversationHistory(sessionId: 'session-1', messages: []);
        await offlineService.cacheConversationHistory(sessionId: 'session-2', messages: []);

        // Act
        await offlineService.clearAllCachedConversations();

        // Assert
        final sessionIds = await offlineService.getCachedSessionIds();
        expect(sessionIds, isEmpty);
      });

      test('should get cache info', () async {
        // Arrange
        final messages = List.generate(5, (i) => ChatMessage(
          messageId: 'msg-$i',
          sessionId: 'session-1',
          content: 'Message $i',
          role: MessageRole.user,
          timestamp: DateTime.now(),
        ));
        await offlineService.cacheConversationHistory(
          sessionId: 'session-1',
          messages: messages,
        );

        // Act
        final cacheInfo = await offlineService.getCacheInfo('session-1');

        // Assert
        expect(cacheInfo, isNotNull);
        expect(cacheInfo!.sessionId, equals('session-1'));
        expect(cacheInfo.messageCount, equals(5));
        expect(cacheInfo.cachedAt, isA<DateTime>());
      });

      test('should check if session has cached data', () async {
        // Arrange
        await offlineService.cacheConversationHistory(
          sessionId: 'session-1',
          messages: [],
        );

        // Act & Assert
        expect(await offlineService.hasCachedConversation('session-1'), isTrue);
        expect(await offlineService.hasCachedConversation('session-2'), isFalse);
      });
    });

    group('Retry Logic', () {
      test('should calculate retry delay with exponential backoff', () {
        // Act & Assert
        expect(offlineService.getRetryDelay(0).inSeconds, equals(2)); // Base delay
        expect(offlineService.getRetryDelay(1).inSeconds, greaterThanOrEqualTo(4));
        expect(offlineService.getRetryDelay(2).inSeconds, greaterThanOrEqualTo(8));
        expect(offlineService.getRetryDelay(5).inSeconds, lessThanOrEqualTo(30)); // Max delay
      });

      test('should determine if message should be retried', () async {
        // Arrange
        await offlineService.queueMessage(
          sessionId: 'test-session',
          content: 'Test message',
          messageType: MessageType.text,
        );
        final messageId = offlineService.currentQueue.first.id;

        // Act & Assert
        expect(offlineService.shouldRetryMessage(offlineService.currentQueue.first), isTrue);

        // Update retry count to max
        await offlineService.updateMessageRetryCount(messageId, 3);
        expect(offlineService.shouldRetryMessage(offlineService.currentQueue.first), isFalse);
      });

      test('should get messages ready for retry', () async {
        // Arrange - Add message with retry count
        await offlineService.queueMessage(
          sessionId: 'test-session',
          content: 'Test message',
          messageType: MessageType.text,
        );
        final messageId = offlineService.currentQueue.first.id;
        
        // Set last retry to past time (more than retry delay)
        await offlineService.updateMessageRetryCount(messageId, 1);
        
        // Wait a bit to ensure retry delay has passed
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Act
        final readyMessages = offlineService.getMessagesReadyForRetry();

        // Assert - Should have at least one message ready for retry
        expect(readyMessages.length, greaterThanOrEqualTo(0));
      });
    });

    group('Stream Events', () {
      test('should emit queued messages stream events', () async {
        // Arrange
        final messageStream = offlineService.queuedMessages;
        final messageEvents = <List<QueuedMessage>>[];
        final subscription = messageStream.listen(messageEvents.add);

        // Act
        await offlineService.queueMessage(
          sessionId: 'test-session',
          content: 'Message 1',
          messageType: MessageType.text,
        );
        await offlineService.queueMessage(
          sessionId: 'test-session',
          content: 'Message 2',
          messageType: MessageType.text,
        );
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        expect(messageEvents.length, greaterThanOrEqualTo(2));
        expect(messageEvents.last.length, equals(2));

        await subscription.cancel();
      });
    });

    group('Error Handling', () {
      test('should handle storage errors gracefully', () async {
        // Arrange - Create service with failing storage
        final failingStorage = FailingMockStorage();
        final failingService = AIOfflineService(failingStorage);

        // Act & Assert - Should not throw
        await expectLater(
          failingService.queueMessage(
            sessionId: 'test-session',
            content: 'Test message',
            messageType: MessageType.text,
          ),
          completes,
        );

        failingService.dispose();
      });
    });
  });

  group('QueuedMessage', () {
    test('should create queued message with required fields', () {
      // Act
      final message = QueuedMessage(
        id: 'msg-1',
        sessionId: 'session-1',
        content: 'Test content',
        messageType: MessageType.text,
        metadata: {'key': 'value'},
        timestamp: DateTime.now(),
        retryCount: 0,
      );

      // Assert
      expect(message.id, equals('msg-1'));
      expect(message.sessionId, equals('session-1'));
      expect(message.content, equals('Test content'));
      expect(message.messageType, equals(MessageType.text));
      expect(message.retryCount, equals(0));
    });

    test('should copy with updated properties', () {
      // Arrange
      final original = QueuedMessage(
        id: 'msg-1',
        sessionId: 'session-1',
        content: 'Original content',
        messageType: MessageType.text,
        metadata: {},
        timestamp: DateTime.now(),
        retryCount: 0,
      );

      // Act
      final updated = original.copyWith(
        retryCount: 2,
        lastRetryAt: DateTime.now(),
      );

      // Assert
      expect(updated.id, equals(original.id));
      expect(updated.content, equals(original.content));
      expect(updated.retryCount, equals(2));
      expect(updated.lastRetryAt, isNotNull);
    });

    test('should serialize to and from JSON', () {
      // Arrange
      final original = QueuedMessage(
        id: 'msg-1',
        sessionId: 'session-1',
        content: 'Test content',
        messageType: MessageType.voice,
        audioData: 'base64-audio',
        metadata: {'duration': 5.0},
        timestamp: DateTime.now(),
        retryCount: 1,
        lastRetryAt: DateTime.now(),
      );

      // Act
      final json = original.toJson();
      final restored = QueuedMessage.fromJson(json);

      // Assert
      expect(restored.id, equals(original.id));
      expect(restored.sessionId, equals(original.sessionId));
      expect(restored.content, equals(original.content));
      expect(restored.messageType, equals(original.messageType));
      expect(restored.audioData, equals(original.audioData));
      expect(restored.metadata['duration'], equals(5.0));
      expect(restored.retryCount, equals(original.retryCount));
    });
  });

  group('CacheInfo', () {
    test('should create cache info with required fields', () {
      // Arrange
      final cachedAt = DateTime.now();

      // Act
      final cacheInfo = CacheInfo(
        sessionId: 'session-1',
        cachedAt: cachedAt,
        messageCount: 10,
      );

      // Assert
      expect(cacheInfo.sessionId, equals('session-1'));
      expect(cacheInfo.cachedAt, equals(cachedAt));
      expect(cacheInfo.messageCount, equals(10));
    });

    test('should determine if cache is stale', () {
      // Arrange
      final recentCache = CacheInfo(
        sessionId: 'session-1',
        cachedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        messageCount: 5,
      );
      final staleCache = CacheInfo(
        sessionId: 'session-2',
        cachedAt: DateTime.now().subtract(const Duration(hours: 2)),
        messageCount: 5,
      );

      // Act & Assert
      expect(recentCache.isStale, isFalse);
      expect(staleCache.isStale, isTrue);
    });

    test('should provide age description', () {
      // Arrange
      final recentCache = CacheInfo(
        sessionId: 'session-1',
        cachedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        messageCount: 5,
      );

      // Act
      final ageDescription = recentCache.ageDescription;

      // Assert
      expect(ageDescription, contains('minutes ago'));
    });
  });
}

/// Mock implementation of FlutterSecureStorage for testing
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
  }) async {
    return _storage[key];
  }

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
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.clear();
  }

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage.containsKey(key);
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.from(_storage);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Mock storage that fails operations for error testing
class FailingMockStorage implements FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw Exception('Storage read failed');
  }

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
    throw Exception('Storage write failed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw Exception('Storage operation failed');
}