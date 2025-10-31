import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/ai/ai_offline_service.dart';
import 'package:emotion_tracker/providers/ai/ai_providers.dart';
import 'package:emotion_tracker/providers/ai/ai_websocket_client.dart';

/// Offline indicator widget for AI chat following existing widget patterns
/// Requirement 7.4: Display offline mode with cached conversation history
class AIOfflineIndicator extends ConsumerWidget {
  final bool showQueuedCount;
  final EdgeInsetsGeometry? padding;

  const AIOfflineIndicator({
    super.key,
    this.showQueuedCount = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final offlineService = ref.watch(aiOfflineServiceProvider);
    
    return StreamBuilder<bool>(
      stream: offlineService.offlineStatus,
      initialData: offlineService.isOffline,
      builder: (context, offlineSnapshot) {
        final isOffline = offlineSnapshot.data ?? false;
        
        if (!isOffline) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<List<QueuedMessage>>(
          stream: offlineService.queuedMessages,
          initialData: offlineService.currentQueue,
          builder: (context, queueSnapshot) {
            final queuedMessages = queueSnapshot.data ?? [];
            
            return Container(
              padding: padding ?? const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: theme.colorScheme.error.withOpacity(0.3),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi_off,
                    size: 16.0,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8.0),
                  Flexible(
                    child: Text(
                      _getOfflineMessage(queuedMessages.length, showQueuedCount),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (queuedMessages.isNotEmpty) ...[
                    const SizedBox(width: 8.0),
                    _buildQueuedMessagesIndicator(
                      context,
                      queuedMessages.length,
                      theme,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Get appropriate offline message based on queued message count
  String _getOfflineMessage(int queuedCount, bool showCount) {
    if (queuedCount == 0) {
      return 'Offline - Messages will be cached';
    } else if (showCount) {
      return queuedCount == 1 
          ? 'Offline - 1 message queued'
          : 'Offline - $queuedCount messages queued';
    } else {
      return 'Offline - Messages queued for sending';
    }
  }

  /// Build queued messages indicator badge
  Widget _buildQueuedMessagesIndicator(
    BuildContext context,
    int count,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6.0,
        vertical: 2.0,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Text(
        count.toString(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onError,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Compact offline indicator for use in app bars or tight spaces
class AIOfflineIndicatorCompact extends ConsumerWidget {
  const AIOfflineIndicatorCompact({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final offlineService = ref.watch(aiOfflineServiceProvider);
    
    return StreamBuilder<bool>(
      stream: offlineService.offlineStatus,
      initialData: offlineService.isOffline,
      builder: (context, snapshot) {
        final isOffline = snapshot.data ?? false;
        
        if (!isOffline) {
          return const SizedBox.shrink();
        }

        return Tooltip(
          message: 'AI chat is offline',
          child: Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.error,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wifi_off,
              size: 16.0,
              color: theme.colorScheme.onError,
            ),
          ),
        );
      },
    );
  }
}

/// Offline banner for full-width display at top of screens
class AIOfflineBanner extends ConsumerWidget {
  final VoidCallback? onTap;
  final bool showDismiss;

  const AIOfflineBanner({
    super.key,
    this.onTap,
    this.showDismiss = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final offlineService = ref.watch(aiOfflineServiceProvider);
    
    return StreamBuilder<bool>(
      stream: offlineService.offlineStatus,
      initialData: offlineService.isOffline,
      builder: (context, offlineSnapshot) {
        final isOffline = offlineSnapshot.data ?? false;
        
        if (!isOffline) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<List<QueuedMessage>>(
          stream: offlineService.queuedMessages,
          initialData: offlineService.currentQueue,
          builder: (context, queueSnapshot) {
            final queuedMessages = queueSnapshot.data ?? [];
            
            return Material(
              color: theme.colorScheme.errorContainer,
              child: InkWell(
                onTap: onTap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.wifi_off,
                        color: theme.colorScheme.onErrorContainer,
                        size: 20.0,
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'AI Chat Offline',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (queuedMessages.isNotEmpty) ...[
                              const SizedBox(height: 2.0),
                              Text(
                                queuedMessages.length == 1
                                    ? '1 message will be sent when connection is restored'
                                    : '${queuedMessages.length} messages will be sent when connection is restored',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onErrorContainer.withOpacity(0.8),
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 2.0),
                              Text(
                                'Messages will be cached until connection is restored',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onErrorContainer.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (queuedMessages.isNotEmpty) ...[
                        const SizedBox(width: 8.0),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            queuedMessages.length.toString(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onError,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (onTap != null) ...[
                        const SizedBox(width: 8.0),
                        Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onErrorContainer.withOpacity(0.7),
                          size: 20.0,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Connection status indicator showing online/offline/reconnecting states
class AIConnectionStatusIndicator extends ConsumerWidget {
  final bool showLabel;
  final MainAxisSize mainAxisSize;

  const AIConnectionStatusIndicator({
    super.key,
    this.showLabel = true,
    this.mainAxisSize = MainAxisSize.min,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final connectionState = ref.watch(aiConnectionStateProvider);
    final offlineService = ref.watch(aiOfflineServiceProvider);
    
    return StreamBuilder<bool>(
      stream: offlineService.offlineStatus,
      initialData: offlineService.isOffline,
      builder: (context, offlineSnapshot) {
        final isOffline = offlineSnapshot.data ?? false;
        
        // Determine display state
        final displayState = isOffline 
            ? AIConnectionState.disconnected 
            : connectionState;
        
        final statusInfo = _getStatusInfo(displayState, theme);
        
        return Row(
          mainAxisSize: mainAxisSize,
          children: [
            Container(
              width: 8.0,
              height: 8.0,
              decoration: BoxDecoration(
                color: statusInfo.color,
                shape: BoxShape.circle,
              ),
            ),
            if (showLabel) ...[
              const SizedBox(width: 8.0),
              Text(
                statusInfo.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: statusInfo.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Get status information for display
  _StatusInfo _getStatusInfo(AIConnectionState state, ThemeData theme) {
    switch (state) {
      case AIConnectionState.connected:
        return _StatusInfo(
          label: 'Online',
          color: Colors.green,
        );
      case AIConnectionState.connecting:
        return _StatusInfo(
          label: 'Connecting...',
          color: Colors.orange,
        );
      case AIConnectionState.reconnecting:
        return _StatusInfo(
          label: 'Reconnecting...',
          color: Colors.orange,
        );
      case AIConnectionState.disconnected:
        return _StatusInfo(
          label: 'Offline',
          color: Colors.red,
        );
      case AIConnectionState.error:
        return _StatusInfo(
          label: 'Error',
          color: Colors.red,
        );
    }
  }
}

/// Helper class for status information
class _StatusInfo {
  final String label;
  final Color color;

  const _StatusInfo({
    required this.label,
    required this.color,
  });
}