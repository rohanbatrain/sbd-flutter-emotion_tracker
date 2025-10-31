import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:emotion_tracker/widgets/ai/ai_offline_indicator.dart';
import 'package:emotion_tracker/providers/ai/ai_offline_service.dart';
import 'package:emotion_tracker/providers/ai/ai_providers.dart';
import 'package:emotion_tracker/providers/ai/ai_websocket_client.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/models/ai/ai_events.dart';

void main() {
  group('AIOfflineIndicator Tests', () {
    late MockFlutterSecureStorage mockStorage;
    late AIOfflineService mockOfflineService;

    Widget createTestWidget(Widget child, {List<Override>? overrides}) {
      return ProviderScope(
        overrides: overrides ?? [
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: child,
          ),
        ),
      );
    }

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
    });

    testWidgets('should not display when online', (tester) async {
      // Act
      await tester.pumpWidget(
        createTestWidget(
          const AIOfflineIndicator(),
        ),
      );

      // Assert - Should not show anything when online
      expect(find.byType(AIOfflineIndicator), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsNothing);
    });

    testWidgets('should display offline indicator when offline', (tester) async {
      // Arrange
      mockOfflineService = AIOfflineService(mockStorage);
      await mockOfflineService.setOfflineStatus(true);

      // Act
      await tester.pumpWidget(
        createTestWidget(
          const AIOfflineIndicator(),
          overrides: [
            aiOfflineServiceProvider.overrideWithValue(mockOfflineService),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.text('Offline - Messages will be cached'), findsOneWidget);

      mockOfflineService.dispose();
    });

    testWidgets('should display queued message count', (tester) async {
      // Arrange
      mockOfflineService = AIOfflineService(mockStorage);
      await mockOfflineService.setOfflineStatus(true);
      await mockOfflineService.queueMessage(
        sessionId: 'test-session',
        content: 'Test message 1',
        messageType: MessageType.text,
      );
      await mockOfflineService.queueMessage(
        sessionId: 'test-session',
        content: 'Test message 2',
        messageType: MessageType.text,
      );

      // Act
      await tester.pumpWidget(
        createTestWidget(
          const AIOfflineIndicator(showQueuedCount: true),
          overrides: [
            aiOfflineServiceProvider.overrideWithValue(mockOfflineService),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Offline - 2 messages queued'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // Badge count

      mockOfflineService.dispose();
    });

    testWidgets('should display singular message text for one queued message', (tester) async {
      // Arrange
      mockOfflineService = AIOfflineService(mockStorage);
      await mockOfflineService.setOfflineStatus(true);
      await mockOfflineService.queueMessage(
        sessionId: 'test-session',
        content: 'Test message',
        messageType: MessageType.text,
      );

      // Act
      await tester.pumpWidget(
        createTestWidget(
          const AIOfflineIndicator(showQueuedCount: true),
          overrides: [
            aiOfflineServiceProvider.overrideWithValue(mockOfflineService),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Offline - 1 message queued'), findsOneWidget);

      mockOfflineService.dispose();
    });

    testWidgets('should hide queued count when showQueuedCount is false', (tester) async {
      // Arrange
      mockOfflineService = AIOfflineService(mockStorage);
      await mockOfflineService.setOfflineStatus(true);
      await mockOfflineService.queueMessage(
        sessionId: 'test-session',
        content: 'Test message',
        messageType: MessageType.text,
      );

      // Act
      await tester.pumpWidget(
        createTestWidget(
          const AIOfflineIndicator(showQueuedCount: false),
          overrides: [
            aiOfflineServiceProvider.overrideWithValue(mockOfflineService),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Offline - Messages queued for sending'), findsOneWidget);

      mockOfflineService.dispose();
    });

    testWidgets('should apply custom padding', (tester) async {
      // Arrange
      mockOfflineService = AIOfflineService(mockStorage);
      await mockOfflineService.setOfflineStatus(true);
      const customPadding = EdgeInsets.all(20.0);

      // Act
      await tester.pumpWidget(
        createTestWidget(
          const AIOfflineIndicator(padding: customPadding),
          overrides: [
            aiOfflineServiceProvider.overrideWithValue(mockOfflineService),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Container), findsWidgets);

      mockOfflineService.dispose();
    });

    testWidgets('should update when offline status changes', (tester) async {
      // Arrange
      mockOfflineService = AIOfflineService(mockStorage);

      // Act - Start online
      await tester.pumpWidget(
        createTestWidget(
          const AIOfflineIndicator(),
          overrides: [
            aiOfflineServiceProvider.overrideWithValue(mockOfflineService),
          ],
        ),
      );

      // Should not show indicator
      expect(find.byIcon(Icons.wifi_off), findsNothing);

      // Go offline
      await mockOfflineService.setOfflineStatus(true);
      await tester.pumpAndSettle();

      // Should show indicator
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);

      // Go back online
      await mockOfflineService.setOfflineStatus(false);
      await tester.pumpAndSettle();

      // Should hide indicator
      expect(find.byIcon(Icons.wifi_off), findsNothing);

      mockOfflineService.dispose();
    });
  });

  group('AIOfflineIndicatorCompact Tests', () {
    late MockFlutterSecureStorage mockStorage;
    late AIOfflineService mockOfflineService;

    Widget createTestWidget(Widget child, {List<Override>? overrides}) {
      return ProviderScope(
        overrides: overrides ?? [
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: child,
          ),
        ),
      );
    }

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
    });

    testWidgets('should display compact offline indicator', (tester) async {
      // Arrange
      mockOfflineService = AIOfflineService(mockStorage);
      await mockOfflineService.setOfflineStatus(true);

      // Act
      await tester.pumpWidget(
        createTestWidget(
          const AIOfflineIndicatorCompact(),
          overrides: [
            aiOfflineServiceProvider.overrideWithValue(mockOfflineService),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Tooltip), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);

      // Check tooltip message
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, equals('AI chat is offline'));

      mockOfflineService.dispose();
    });

    testWidgets('should not display when online', (tester) async {
      // Act
      await tester.pumpWidget(
        createTestWidget(
          const AIOfflineIndicatorCompact(),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.wifi_off), findsNothing);
    });
  });

  group('AIOfflineBanner Tests', () {
    late MockFlutterSecureStorage mockStorage;
    late AIOfflineService mockOfflineService;

    Widget createTestWidget(Widget child, {List<Override>? overrides}) {
      return ProviderScope(
        overrides: overrides ?? [
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: child,
          ),
        ),
      );
    }

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
    });

    testWidgets('should display full-width offline banner', (tester) async {
      // Arrange
      mockOfflineService = AIOfflineService(mockStorage);
      await mockOfflineService.setOfflineStatus(true);

      // Act
      await tester.pumpWidget(
        createTestWidget(
          const AIOfflineBanner(),
          overrides: [
            aiOfflineServiceProvider.overrideWithValue(mockOfflineService),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('AI Chat Offline'), findsOneWidget);
      expect(find.text('Messages will be cached until connection is restored'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);

      mockOfflineService.dispose();
    });

    testWidgets('should display queued message information in banner', (tester) async {
      // Arrange
      mockOfflineService = AIOfflineService(mockStorage);
      await mockOfflineService.setOfflineStatus(true);
      await mockOfflineService.queueMessage(
        sessionId: 'test-session',
        content: 'Test message 1',
        messageType: MessageType.text,
      );
      await mockOfflineService.queueMessage(
        sessionId: 'test-session',
        content: 'Test message 2',
        messageType: MessageType.text,
      );

      // Act
      await tester.pumpWidget(
        createTestWidget(
          const AIOfflineBanner(),
          overrides: [
            aiOfflineServiceProvider.overrideWithValue(mockOfflineService),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('2 messages will be sent when connection is restored'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // Badge count

      mockOfflineService.dispose();
    });

    testWidgets('should handle banner tap callback', (tester) async {
      // Arrange
      mockOfflineService = AIOfflineService(mockStorage);
      await mockOfflineService.setOfflineStatus(true);
      bool bannerTapped = false;

      // Act
      await tester.pumpWidget(
        createTestWidget(
          AIOfflineBanner(
            onTap: () => bannerTapped = true,
          ),
          overrides: [
            aiOfflineServiceProvider.overrideWithValue(mockOfflineService),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Tap the banner
      await tester.tap(find.byType(InkWell));
      
      // Assert
      expect(bannerTapped, isTrue);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      mockOfflineService.dispose();
    });

    testWidgets('should display singular message text for one queued message', (tester) async {
      // Arrange
      mockOfflineService = AIOfflineService(mockStorage);
      await mockOfflineService.setOfflineStatus(true);
      await mockOfflineService.queueMessage(
        sessionId: 'test-session',
        content: 'Test message',
        messageType: MessageType.text,
      );

      // Act
      await tester.pumpWidget(
        createTestWidget(
          const AIOfflineBanner(),
          overrides: [
            aiOfflineServiceProvider.overrideWithValue(mockOfflineService),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('1 message will be sent when connection is restored'), findsOneWidget);

      mockOfflineService.dispose();
    });

    testWidgets('should not display when online', (tester) async {
      // Act
      await tester.pumpWidget(
        createTestWidget(
          const AIOfflineBanner(),
        ),
      );

      // Assert
      expect(find.text('AI Chat Offline'), findsNothing);
    });
  });

  group('AIConnectionStatusIndicator Tests', () {
    late MockFlutterSecureStorage mockStorage;

    Widget createTestWidget(Widget child, {List<Override>? overrides}) {
      return ProviderScope(
        overrides: overrides ?? [
          secureStorageProvider.overrideWithValue(mockStorage),
          aiConnectionStateProvider.overrideWith((ref) => MockAIConnectionStateNotifier()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: child,
          ),
        ),
      );
    }

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
    });

    testWidgets('should display online status', (tester) async {
      // Act
      await tester.pumpWidget(
        createTestWidget(
          const AIConnectionStatusIndicator(),
          overrides: [
            aiConnectionStateProvider.overrideWith((ref) => 
              MockAIConnectionStateNotifier(AIConnectionState.connected)),
          ],
        ),
      );

      // Assert
      expect(find.text('Online'), findsOneWidget);
    });

    testWidgets('should display connecting status', (tester) async {
      // Act
      await tester.pumpWidget(
        createTestWidget(
          const AIConnectionStatusIndicator(),
          overrides: [
            aiConnectionStateProvider.overrideWith((ref) => 
              MockAIConnectionStateNotifier(AIConnectionState.connecting)),
          ],
        ),
      );

      // Assert
      expect(find.text('Connecting...'), findsOneWidget);
    });

    testWidgets('should display offline status when offline service is offline', (tester) async {
      // Arrange
      final mockOfflineService = AIOfflineService(mockStorage);
      await mockOfflineService.setOfflineStatus(true);

      // Act
      await tester.pumpWidget(
        createTestWidget(
          const AIConnectionStatusIndicator(),
          overrides: [
            aiOfflineServiceProvider.overrideWithValue(mockOfflineService),
            aiConnectionStateProvider.overrideWith((ref) => 
              MockAIConnectionStateNotifier(AIConnectionState.connected)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Offline'), findsOneWidget);

      mockOfflineService.dispose();
    });

    testWidgets('should hide label when showLabel is false', (tester) async {
      // Act
      await tester.pumpWidget(
        createTestWidget(
          const AIConnectionStatusIndicator(showLabel: false),
          overrides: [
            aiConnectionStateProvider.overrideWith((ref) => 
              MockAIConnectionStateNotifier(AIConnectionState.connected)),
          ],
        ),
      );

      // Assert
      expect(find.text('Online'), findsNothing);
      expect(find.byType(Container), findsOneWidget); // Status dot should still be present
    });

    testWidgets('should display error status', (tester) async {
      // Act
      await tester.pumpWidget(
        createTestWidget(
          const AIConnectionStatusIndicator(),
          overrides: [
            aiConnectionStateProvider.overrideWith((ref) => 
              MockAIConnectionStateNotifier(AIConnectionState.error)),
          ],
        ),
      );

      // Assert
      expect(find.text('Error'), findsOneWidget);
    });

    testWidgets('should display reconnecting status', (tester) async {
      // Act
      await tester.pumpWidget(
        createTestWidget(
          const AIConnectionStatusIndicator(),
          overrides: [
            aiConnectionStateProvider.overrideWith((ref) => 
              MockAIConnectionStateNotifier(AIConnectionState.reconnecting)),
          ],
        ),
      );

      // Assert
      expect(find.text('Reconnecting...'), findsOneWidget);
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

/// Mock AI Connection State Notifier for testing
class MockAIConnectionStateNotifier extends StateNotifier<AIConnectionState> {
  MockAIConnectionStateNotifier([AIConnectionState? initialState]) 
      : super(initialState ?? AIConnectionState.disconnected);

  void setState(AIConnectionState newState) {
    state = newState;
  }
}