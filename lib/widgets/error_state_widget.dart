import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/core/global_error_handler.dart';
import 'package:emotion_tracker/core/error_state.dart';
import 'package:emotion_tracker/utils/http_util.dart';

/// Reusable widget for displaying consistent error states across the application
/// Works with existing exception classes from api_token_service.dart and HttpUtil
class ErrorStateWidget extends ConsumerWidget {
  /// The error object to display (can be any exception type)
  final dynamic error;

  /// Callback function to execute when retry button is pressed
  final VoidCallback? onRetry;

  /// Callback function to execute when info button is pressed
  final VoidCallback? onInfo;

  /// Custom error message to override the default message
  final String? customMessage;

  /// Custom error title to override the default title
  final String? customTitle;

  /// Whether to show the error in a compact format (smaller icons and text)
  final bool compact;

  const ErrorStateWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.onInfo,
    this.customMessage,
    this.customTitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final errorState = GlobalErrorHandler.processError(error);

    // Handle automatic redirects for unauthorized errors
    if (errorState.autoRedirect && errorState.type == ErrorType.unauthorized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Check if this is an AI-specific authentication error
        final isAISpecific = errorState.metadata?['aiSpecific'] == true;
        if (isAISpecific) {
          // For AI authentication errors, use the same session management
          // but could be extended for AI-specific handling in the future
          GlobalErrorHandler.handleUnauthorized(context, ref);
        } else {
          GlobalErrorHandler.handleUnauthorized(context, ref);
        }
      });
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16.0 : 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error Icon
            Icon(
              errorState.icon,
              color: errorState.color,
              size: compact ? 32.0 : 48.0,
            ),
            SizedBox(height: compact ? 12.0 : 16.0),

            // Error Title
            Text(
              customTitle ?? errorState.title,
              style: (compact
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.titleLarge)
                  ?.copyWith(
                    color: errorState.color,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: compact ? 6.0 : 8.0),

            // Error Message
            Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 16.0 : 32.0),
              child: Text(
                customMessage ?? errorState.message,
                style:
                    compact
                        ? theme.textTheme.bodySmall
                        : theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: compact ? 16.0 : 24.0),

            // Action Buttons
            _buildActionButtons(context, theme, errorState),
          ],
        ),
      ),
    );
  }

  /// Builds the action buttons (retry, info) based on error state configuration
  Widget _buildActionButtons(
    BuildContext context,
    ThemeData theme,
    ErrorState errorState,
  ) {
    final List<Widget> buttons = [];

    // Add retry button if enabled and callback provided
    if (errorState.showRetry && onRetry != null) {
      buttons.add(
        ElevatedButton.icon(
          icon: Icon(Icons.refresh, size: compact ? 16.0 : 20.0),
          label: Text(
            'Retry',
            style: TextStyle(fontSize: compact ? 12.0 : 14.0),
          ),
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12.0 : 16.0,
              vertical: compact ? 8.0 : 12.0,
            ),
          ),
        ),
      );
    }

    // Add info button if enabled
    if (errorState.showInfo) {
      final infoCallback =
          onInfo ?? () => _showDefaultInfoDialog(context, errorState);

      buttons.add(
        OutlinedButton.icon(
          icon: Icon(Icons.info_outline, size: compact ? 16.0 : 20.0),
          label: Text(
            'More Info',
            style: TextStyle(fontSize: compact ? 12.0 : 14.0),
          ),
          onPressed: infoCallback,
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            side: BorderSide(color: theme.colorScheme.primary),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12.0 : 16.0,
              vertical: compact ? 8.0 : 12.0,
            ),
          ),
        ),
      );
    }

    // Return buttons in a row or single button
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

  /// Shows a default info dialog for errors that support it
  void _showDefaultInfoDialog(BuildContext context, ErrorState errorState) {
    switch (errorState.type) {
      case ErrorType.cloudflareError:
        _showCloudflareInfoDialog(context, errorState);
        break;
      case ErrorType.serverError:
        _showServerInfoDialog(context, errorState);
        break;
      case ErrorType.aiSessionError:
        _showAISessionInfoDialog(context, errorState);
        break;
      case ErrorType.aiVoiceError:
        _showAIVoiceInfoDialog(context, errorState);
        break;
      case ErrorType.aiToolError:
        _showAIToolInfoDialog(context, errorState);
        break;
      case ErrorType.aiAgentError:
        _showAIAgentInfoDialog(context, errorState);
        break;
      default:
        _showGenericInfoDialog(context, errorState);
    }
  }

  /// Shows detailed info dialog for Cloudflare errors
  void _showCloudflareInfoDialog(BuildContext context, ErrorState errorState) {
    final originalError = errorState.metadata?['originalError'];

    if (originalError is CloudflareTunnelException) {
      // Use existing HttpUtil dialog for Cloudflare errors
      HttpUtil.showCloudflareErrorDialog(context, originalError);
    } else {
      _showGenericInfoDialog(context, errorState);
    }
  }

  /// Shows detailed info dialog for server errors
  void _showServerInfoDialog(BuildContext context, ErrorState errorState) {
    final theme = Theme.of(context);
    final statusCode = errorState.metadata?['statusCode'] as int?;

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: theme.cardColor,
            title: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Server Information',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The server is currently experiencing issues. This usually happens when:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '• Server is temporarily overloaded\n• Maintenance is in progress\n• Network connectivity issues\n• Database connection problems',
                  style: theme.textTheme.bodySmall,
                ),
                if (statusCode != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withAlpha(75),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Technical Details:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'HTTP Status Code: $statusCode',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.blue[700],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withAlpha(75),
                    ),
                  ),
                  child: Text(
                    'Please wait a few minutes and try again. If the problem persists, contact your system administrator.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'OK',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
    );
  }

  /// Shows a generic info dialog for other error types
  void _showGenericInfoDialog(BuildContext context, ErrorState errorState) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: theme.cardColor,
            title: Row(
              children: [
                Icon(errorState.icon, color: errorState.color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error Information',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: errorState.color,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(errorState.message, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: errorState.color.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: errorState.color.withAlpha(75),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: errorState.color,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'What you can do:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: errorState.color.withAlpha(200),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getErrorAdvice(errorState.type),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: errorState.color.withAlpha(180),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'OK',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
    );
  }

  /// Gets appropriate advice text based on error type
  String _getErrorAdvice(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.unauthorized:
        return '• Log in again with your credentials\n• Check if your account is still active\n• Contact support if login continues to fail';
      case ErrorType.rateLimited:
        return '• Wait a few minutes before trying again\n• Reduce the frequency of your requests\n• Try again during off-peak hours';
      case ErrorType.networkError:
        return '• Check your internet connection\n• Try switching between WiFi and mobile data\n• Restart your network connection';
      case ErrorType.serverError:
        return '• Wait a few minutes and try again\n• Check if other features work\n• Contact support if problem persists';
      case ErrorType.cloudflareError:
        return '• Wait for the server to come back online\n• Try again in a few minutes\n• Check server status if available';
      case ErrorType.aiSessionError:
        return '• Start a new AI conversation\n• Check your internet connection\n• Try switching to a different AI agent';
      case ErrorType.aiVoiceError:
        return '• Check microphone permissions in settings\n• Ensure your device has a working microphone\n• Try using text input instead';
      case ErrorType.aiToolError:
        return '• Try the AI operation again\n• Switch to a different AI agent\n• Use manual operations if available';
      case ErrorType.aiAgentError:
        return '• Select a different AI agent\n• Check your account permissions\n• Contact administrator for access';
      case ErrorType.aiWebSocketError:
        return '• Check your internet connection\n• Try refreshing the AI chat\n• Switch between WiFi and mobile data';
      case ErrorType.generic:
        return '• Try the operation again\n• Restart the app if problem persists\n• Contact support with error details';
    }
  }

  /// Shows detailed info dialog for AI session errors
  void _showAISessionInfoDialog(BuildContext context, ErrorState errorState) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Row(
          children: [
            Icon(Icons.chat_bubble_outline, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'AI Session Information',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI sessions manage your conversations with AI assistants. Session issues can occur when:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '• Session expires due to inactivity\n• Maximum concurrent sessions reached\n• Network connection is interrupted\n• AI service is temporarily unavailable',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withAlpha(75)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Quick Fix:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a new AI conversation or refresh the current session to continue chatting.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  /// Shows detailed info dialog for AI voice errors
  void _showAIVoiceInfoDialog(BuildContext context, ErrorState errorState) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Row(
          children: [
            Icon(Icons.mic_off, color: Colors.red, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'AI Voice Information',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voice features allow you to speak with AI assistants. Voice issues can occur when:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '• Microphone permission is not granted\n• Device microphone is not working\n• Audio playback is disabled\n• Network connection is poor',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withAlpha(75)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Settings Check:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Go to device Settings > Apps > Emotion Tracker > Permissions and enable Microphone access.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  /// Shows detailed info dialog for AI tool errors
  void _showAIToolInfoDialog(BuildContext context, ErrorState errorState) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Row(
          children: [
            Icon(Icons.build_circle_outlined, color: Colors.red, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'AI Tool Information',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI tools help assistants perform actions like managing family settings or making purchases. Tool errors occur when:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '• Tool is temporarily unavailable\n• Operation times out due to complexity\n• Insufficient permissions for the action\n• Backend service is experiencing issues',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withAlpha(75)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.alternate_email, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Alternative:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can perform the same actions manually through the app\'s regular interface.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  /// Shows detailed info dialog for AI agent errors
  void _showAIAgentInfoDialog(BuildContext context, ErrorState errorState) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Row(
          children: [
            Icon(Icons.smart_toy_outlined, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'AI Agent Information',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI agents are specialized assistants for different tasks. Agent issues can occur when:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              '• Agent is not available or configured\n• Insufficient permissions for agent access\n• Agent requires administrator privileges\n• Service is temporarily down',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withAlpha(75)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.group, color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Available Agents:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try selecting a different AI agent from the agent selector to continue your conversation.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ],
      ),
    );
  }
}
