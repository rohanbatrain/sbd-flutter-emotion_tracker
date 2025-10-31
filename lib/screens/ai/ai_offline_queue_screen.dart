import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/ai/ai_offline_service.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/models/ai/ai_events.dart';

/// Screen for managing offline AI message queue
/// Requirement 7.3: Cache messages locally and retry transmission
class AIOfflineQueueScreen extends ConsumerWidget {
  const AIOfflineQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    final offlineService = ref.watch(aiOfflineServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Message Queue'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: StreamBuilder<List<QueuedMessage>>(
        stream: offlineService.queuedMessages,
        initialData: offlineService.currentQueue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingStateWidget(message: 'Loading queue...');
          }

          if (snapshot.hasError) {
            return ErrorStateWidget(
              error: snapshot.error,
              onRetry: () {
                // Trigger rebuild
                ref.invalidate(aiOfflineServiceProvider);
              },
            );
          }

          final queuedMessages = snapshot.data ?? [];

          if (queuedMessages.isEmpty) {
            return _buildEmptyState(theme);
          }

          return _buildQueueList(context, ref, theme, queuedMessages, offlineService);
        },
      ),
    );
  }

  /// Build empty state when no messages are queued
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Queued Messages',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All messages have been sent successfully',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build the list of queued messages
  Widget _buildQueueList(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    List<QueuedMessage> messages,
    AIOfflineService offlineService,
  ) {
    return Column(
      children: [
        // Queue summary
        _buildQueueSummary(theme, messages, offlineService),
        
        // Message list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return _buildQueuedMessageCard(
                context,
                ref,
                theme,
                message,
                offlineService,
              );
            },
          ),
        ),
        
        // Actions
        _buildActions(context, ref, theme, messages, offlineService),
      ],
    );
  }

  /// Build queue summary header
  Widget _buildQueueSummary(
    ThemeData theme,
    List<QueuedMessage> messages,
    AIOfflineService offlineService,
  ) {
    final totalMessages = messages.length;
    final failedMessages = messages.where((m) => !offlineService.shouldRetryMessage(m)).length;
    final retryingMessages = messages.where((m) => m.retryCount > 0 && offlineService.shouldRetryMessage(m)).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Queue Summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSummaryChip(theme, 'Total', totalMessages.toString(), Colors.blue),
              const SizedBox(width: 8),
              if (retryingMessages > 0)
                _buildSummaryChip(theme, 'Retrying', retryingMessages.toString(), Colors.orange),
              const SizedBox(width: 8),
              if (failedMessages > 0)
                _buildSummaryChip(theme, 'Failed', failedMessages.toString(), Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  /// Build summary chip
  Widget _buildSummaryChip(ThemeData theme, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build queued message card
  Widget _buildQueuedMessageCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    QueuedMessage message,
    AIOfflineService offlineService,
  ) {
    final canRetry = offlineService.shouldRetryMessage(message);
    final statusColor = canRetry 
        ? (message.retryCount > 0 ? Colors.orange : Colors.blue)
        : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Icon(
                  _getMessageTypeIcon(message.messageType),
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getMessageTypeLabel(message.messageType),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _buildStatusChip(theme, message, canRetry),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Message content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
              child: Text(
                message.content.isNotEmpty 
                    ? message.content
                    : '[Voice message]',
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Metadata
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTimestamp(message.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const Spacer(),
                if (message.retryCount > 0) ...[
                  Text(
                    'Retries: ${message.retryCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ],
            ),
            
            // Actions
            if (canRetry) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _removeMessage(context, ref, message, offlineService),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Remove'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build status chip for message
  Widget _buildStatusChip(ThemeData theme, QueuedMessage message, bool canRetry) {
    String label;
    Color color;
    
    if (!canRetry) {
      label = 'Failed';
      color = Colors.red;
    } else if (message.retryCount > 0) {
      label = 'Retrying';
      color = Colors.orange;
    } else {
      label = 'Queued';
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Build actions section
  Widget _buildActions(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    List<QueuedMessage> messages,
    AIOfflineService offlineService,
  ) {
    if (messages.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _clearAllMessages(context, ref, offlineService),
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear All'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: offlineService.isOffline 
                  ? null
                  : () => _retryAllMessages(context, ref, offlineService),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry All'),
            ),
          ),
        ],
      ),
    );
  }

  /// Get icon for message type
  IconData _getMessageTypeIcon(MessageType type) {
    switch (type) {
      case MessageType.text:
        return Icons.message;
      case MessageType.voice:
        return Icons.mic;
      case MessageType.toolCall:
        return Icons.build;
      case MessageType.toolResult:
        return Icons.check_circle;
      case MessageType.thinking:
        return Icons.psychology;
      case MessageType.typing:
        return Icons.keyboard;
    }
  }

  /// Get label for message type
  String _getMessageTypeLabel(MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'Text Message';
      case MessageType.voice:
        return 'Voice Message';
      case MessageType.toolCall:
        return 'Tool Call';
      case MessageType.toolResult:
        return 'Tool Result';
      case MessageType.thinking:
        return 'Thinking';
      case MessageType.typing:
        return 'Typing';
    }
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Remove a specific message
  Future<void> _removeMessage(
    BuildContext context,
    WidgetRef ref,
    QueuedMessage message,
    AIOfflineService offlineService,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Message'),
        content: const Text('Are you sure you want to remove this message from the queue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await offlineService.removeQueuedMessage(message.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message removed from queue')),
        );
      }
    }
  }

  /// Clear all messages
  Future<void> _clearAllMessages(
    BuildContext context,
    WidgetRef ref,
    AIOfflineService offlineService,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Messages'),
        content: const Text('Are you sure you want to remove all messages from the queue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await offlineService.clearMessageQueue();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All messages cleared from queue')),
        );
      }
    }
  }

  /// Retry all messages
  Future<void> _retryAllMessages(
    BuildContext context,
    WidgetRef ref,
    AIOfflineService offlineService,
  ) async {
    // This would trigger the retry mechanism in the chat messages provider
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Retry will happen automatically when connection is restored'),
      ),
    );
  }
}