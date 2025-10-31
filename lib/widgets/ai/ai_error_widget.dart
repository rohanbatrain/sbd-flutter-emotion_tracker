import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'package:emotion_tracker/providers/ai/ai_exceptions.dart';

/// Specialized error widget for AI-specific errors
/// Extends the general ErrorStateWidget with AI-specific functionality
class AIErrorWidget extends ConsumerWidget {
  /// The AI-specific error to display
  final dynamic error;

  /// Callback function to execute when retry button is pressed
  final VoidCallback? onRetry;

  /// Callback function to execute when switching agents
  final VoidCallback? onSwitchAgent;

  /// Callback function to execute when starting a new session
  final VoidCallback? onNewSession;

  /// Whether to show the error in a compact format
  final bool compact;

  const AIErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.onSwitchAgent,
    this.onNewSession,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the general ErrorStateWidget as the base
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ErrorStateWidget(
          error: error,
          onRetry: onRetry,
          compact: compact,
        ),
        
        // Add AI-specific action buttons if applicable
        if (_shouldShowAIActions()) ...[
          const SizedBox(height: 16),
          _buildAIActionButtons(context),
        ],
      ],
    );
  }

  /// Determines if AI-specific action buttons should be shown
  bool _shouldShowAIActions() {
    if (error is! AIApiException) return false;
    
    // Show AI actions for specific error types
    return error is SessionNotFoundException ||
           error is SessionExpiredException ||
           error is AgentNotFoundException ||
           error is AgentAccessDeniedException ||
           error is SessionLimitReachedException;
  }

  /// Builds AI-specific action buttons
  Widget _buildAIActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> buttons = [];

    // Add "Switch Agent" button for agent-related errors
    if ((error is AgentNotFoundException || error is AgentAccessDeniedException) && 
        onSwitchAgent != null) {
      buttons.add(
        OutlinedButton.icon(
          icon: Icon(Icons.swap_horiz, size: compact ? 16.0 : 20.0),
          label: Text(
            'Switch Agent',
            style: TextStyle(fontSize: compact ? 12.0 : 14.0),
          ),
          onPressed: onSwitchAgent,
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.secondary,
            side: BorderSide(color: theme.colorScheme.secondary),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12.0 : 16.0,
              vertical: compact ? 8.0 : 12.0,
            ),
          ),
        ),
      );
    }

    // Add "New Session" button for session-related errors
    if ((error is SessionNotFoundException || 
         error is SessionExpiredException ||
         error is SessionLimitReachedException) && 
        onNewSession != null) {
      buttons.add(
        ElevatedButton.icon(
          icon: Icon(Icons.add_comment, size: compact ? 16.0 : 20.0),
          label: Text(
            'New Chat',
            style: TextStyle(fontSize: compact ? 12.0 : 14.0),
          ),
          onPressed: onNewSession,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12.0 : 16.0,
              vertical: compact ? 8.0 : 12.0,
            ),
          ),
        ),
      );
    }

    // Return buttons in a row
    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    } else if (buttons.length == 1) {
      return buttons.first;
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buttons.first,
          SizedBox(width: compact ? 8.0 : 12.0),
          buttons.last,
        ],
      );
    }
  }
}

/// Specialized error widget for AI voice errors with permission handling
class AIVoiceErrorWidget extends ConsumerWidget {
  /// The voice-specific error to display
  final VoiceException error;

  /// Callback function to execute when retry button is pressed
  final VoidCallback? onRetry;

  /// Callback function to execute when opening settings
  final VoidCallback? onOpenSettings;

  /// Whether to show the error in a compact format
  final bool compact;

  const AIVoiceErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.onOpenSettings,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ErrorStateWidget(
          error: error,
          onRetry: onRetry,
          compact: compact,
        ),
        
        // Add voice-specific action button for permission errors
        if (error is MicrophonePermissionException && onOpenSettings != null) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: Icon(Icons.settings, size: compact ? 16.0 : 20.0),
            label: Text(
              'Open Settings',
              style: TextStyle(fontSize: compact ? 12.0 : 14.0),
            ),
            onPressed: onOpenSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12.0 : 16.0,
                vertical: compact ? 8.0 : 12.0,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Specialized error widget for AI WebSocket connection errors
class AIConnectionErrorWidget extends ConsumerWidget {
  /// The connection error to display
  final NetworkException error;

  /// Callback function to execute when retry button is pressed
  final VoidCallback? onRetry;

  /// Callback function to execute when reconnecting
  final VoidCallback? onReconnect;

  /// Whether to show the error in a compact format
  final bool compact;

  const AIConnectionErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.onReconnect,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ErrorStateWidget(
          error: error,
          onRetry: onRetry,
          compact: compact,
        ),
        
        // Add reconnection button for WebSocket errors
        if (onReconnect != null) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: Icon(Icons.refresh, size: compact ? 16.0 : 20.0),
            label: Text(
              'Reconnect',
              style: TextStyle(fontSize: compact ? 12.0 : 14.0),
            ),
            onPressed: onReconnect,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12.0 : 16.0,
                vertical: compact ? 8.0 : 12.0,
              ),
            ),
          ),
        ],
      ],
    );
  }
}