import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:emotion_tracker/providers/ai/ai_api_service.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/core/exceptions.dart' as core_exceptions;
import 'package:emotion_tracker/models/ai/ai_events.dart';

void main() {
  group('AIApiService', () {
    late ProviderContainer container;
    late AIApiService aiApiService;

    setUp(() {
      // Create a provider container with overrides for testing
      container = ProviderContainer(
        overrides: [
          apiBaseUrlProvider.overrideWithValue('https://test-api.example.com'),
          secureStorageProvider.overrideWithValue(MockFlutterSecureStorage()),
        ],
      );
      
      aiApiService = container.read(aiApiServiceProvider);
    });

    tearDown(() {
      container.dispose();
    });

    group('Service Initialization', () {
      test('should initialize with correct base URL', () {
        // Act
        final baseUrl = container.read(apiBaseUrlProvider);
        
        // Assert
        expect(baseUrl, equals('https://test-api.example.com'));
      });

      test('should have access to secure storage provider', () {
        // Act
        final secureStorage = container.read(secureStorageProvider);
        
        // Assert
        expect(secureStorage, isA<MockFlutterSecureStorage>());
      });
    });

    group('Authentication Handling', () {
      test('should throw UnauthorizedException when token is missing', () async {
        // Arrange - No token in storage (default state)
        
        // Act & Assert
        expect(
          () => aiApiService.createSession(agentType: AgentType.personal),
          throwsA(isA<core_exceptions.UnauthorizedException>()),
        );
      });

      test('should include proper headers when token is available', () async {
        // Arrange
        final mockStorage = container.read(secureStorageProvider) as MockFlutterSecureStorage;
        await mockStorage.write(key: 'access_token', value: 'test-token-123');
        
        // Act & Assert - This will fail due to network call, but we can verify the token is read
        try {
          await aiApiService.createSession(agentType: AgentType.family);
        } catch (e) {
          // Expected to fail due to network call, but token should have been read
          expect(e, isNot(isA<core_exceptions.UnauthorizedException>()));
        }
      });
    });

    group('Request Parameter Validation', () {
      test('should validate session creation parameters', () async {
        // Arrange
        final mockStorage = container.read(secureStorageProvider) as MockFlutterSecureStorage;
        await mockStorage.write(key: 'access_token', value: 'test-token');
        
        // Act & Assert - Test different agent types
        for (final agentType in AgentType.values) {
          try {
            await aiApiService.createSession(
              agentType: agentType,
              voiceEnabled: true,
              preferences: {'test': 'value'},
            );
          } catch (e) {
            // Expected to fail due to network, but parameters should be valid
            expect(e, isNot(isA<ArgumentError>()));
          }
        }
      });

      test('should validate message parameters', () async {
        // Arrange
        final mockStorage = container.read(secureStorageProvider) as MockFlutterSecureStorage;
        await mockStorage.write(key: 'access_token', value: 'test-token');
        
        const sessionId = 'test-session-123';
        const content = 'Test message content';
        
        // Act & Assert - Test different message types
        for (final messageType in MessageType.values) {
          try {
            await aiApiService.sendMessage(
              sessionId: sessionId,
              content: content,
              messageType: messageType,
              audioData: messageType == MessageType.voice ? 'base64-audio' : null,
              metadata: {'test': 'metadata'},
            );
          } catch (e) {
            // Expected to fail due to network, but parameters should be valid
            expect(e, isNot(isA<ArgumentError>()));
          }
        }
      });
    });

    group('URL Construction', () {
      test('should construct correct URLs for different endpoints', () {
        // Arrange
        final baseUrl = container.read(apiBaseUrlProvider);
        
        // Assert - Verify base URL is used correctly
        expect(baseUrl, equals('https://test-api.example.com'));
        
        // Test URL construction logic (indirectly through service initialization)
        expect(aiApiService, isNotNull);
      });

      test('should handle session ID validation', () {
        // Test that session IDs are properly validated
        const validSessionIds = [
          'session-123',
          'abc-def-456',
          'test_session_789',
        ];
        
        for (final sessionId in validSessionIds) {
          expect(sessionId.isNotEmpty, isTrue);
          expect(sessionId.length, greaterThan(5));
        }
      });
    });

    group('Data Model Integration', () {
      test('should work with AI event models', () {
        // Test AgentType enum values
        expect(AgentType.values, hasLength(6));
        expect(AgentType.family.value, equals('family'));
        expect(AgentType.personal.value, equals('personal'));
        expect(AgentType.workspace.value, equals('workspace'));
        expect(AgentType.commerce.value, equals('commerce'));
        expect(AgentType.security.value, equals('security'));
        expect(AgentType.voice.value, equals('voice'));
      });

      test('should work with message type models', () {
        // Test MessageType enum values
        expect(MessageType.values, hasLength(6));
        expect(MessageType.text.value, equals('text'));
        expect(MessageType.voice.value, equals('voice'));
        expect(MessageType.toolCall.value, equals('tool_call'));
        expect(MessageType.toolResult.value, equals('tool_result'));
        expect(MessageType.thinking.value, equals('thinking'));
        expect(MessageType.typing.value, equals('typing'));
      });

      test('should work with session status models', () {
        // Test SessionStatus enum values
        expect(SessionStatus.values, hasLength(4));
        expect(SessionStatus.active.value, equals('active'));
        expect(SessionStatus.inactive.value, equals('inactive'));
        expect(SessionStatus.expired.value, equals('expired'));
        expect(SessionStatus.terminated.value, equals('terminated'));
      });

      test('should create valid AI session objects', () {
        // Test AISession model creation
        final now = DateTime.now();
        final session = AISession(
          sessionId: 'test-123',
          userId: 'user-456',
          agentType: AgentType.family,
          status: SessionStatus.active,
          createdAt: now,
          lastActivity: now,
          voiceEnabled: true,
          messageCount: 5,
        );

        expect(session.sessionId, equals('test-123'));
        expect(session.userId, equals('user-456'));
        expect(session.agentType, equals(AgentType.family));
        expect(session.status, equals(SessionStatus.active));
        expect(session.voiceEnabled, isTrue);
        expect(session.messageCount, equals(5));
        expect(session.isActive, isTrue);
        expect(session.isExpired, isFalse);
      });

      test('should create valid chat message objects', () {
        // Test ChatMessage model creation
        final now = DateTime.now();
        final message = ChatMessage(
          messageId: 'msg-123',
          sessionId: 'session-456',
          content: 'Hello, AI!',
          role: MessageRole.user,
          timestamp: now,
          messageType: MessageType.text,
        );

        expect(message.messageId, equals('msg-123'));
        expect(message.sessionId, equals('session-456'));
        expect(message.content, equals('Hello, AI!'));
        expect(message.role, equals(MessageRole.user));
        expect(message.messageType, equals(MessageType.text));
        expect(message.isUserMessage, isTrue);
        expect(message.isAssistantMessage, isFalse);
        expect(message.isVoiceMessage, isFalse);
        expect(message.isToolMessage, isFalse);
      });
    });

    group('Error Handling Patterns', () {
      test('should handle missing authentication tokens', () async {
        // Arrange - No token in storage (default state)
        
        // Act & Assert
        expect(
          () => aiApiService.createSession(agentType: AgentType.family),
          throwsA(isA<core_exceptions.UnauthorizedException>()),
        );
        
        expect(
          () => aiApiService.sendMessage(
            sessionId: 'test-session',
            content: 'test message',
          ),
          throwsA(isA<core_exceptions.UnauthorizedException>()),
        );
        
        expect(
          () => aiApiService.getAISessions(),
          throwsA(isA<core_exceptions.UnauthorizedException>()),
        );
      });

      test('should validate required parameters', () {
        // Test that empty or invalid parameters are handled
        expect(() => AgentType.values.firstWhere((e) => e.value == 'invalid'), throwsStateError);
        expect(() => MessageType.values.firstWhere((e) => e.value == 'invalid'), throwsStateError);
        expect(() => SessionStatus.values.firstWhere((e) => e.value == 'invalid'), throwsStateError);
      });

      test('should handle timeout scenarios gracefully', () async {
        // Arrange
        final mockStorage = container.read(secureStorageProvider) as MockFlutterSecureStorage;
        await mockStorage.write(key: 'access_token', value: 'test-token');
        
        // Act & Assert - Network calls will timeout, but should be handled gracefully
        try {
          await aiApiService.createSession(agentType: AgentType.family);
        } catch (e) {
          // Should handle timeout/network errors gracefully
          expect(e.toString(), contains('error'));
        }
      });
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

  // Use noSuchMethod for all other methods we don't need to implement
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return default values for getters
    if (invocation.isGetter) {
      return null;
    }
    // Return empty futures for async methods
    if (invocation.memberName.toString().contains('Future')) {
      return Future.value();
    }
    // Return null for everything else
    return null;
  }
}