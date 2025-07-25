import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'package:emotion_tracker/providers/api_token_service.dart';
import 'package:emotion_tracker/utils/http_util.dart';
import 'package:emotion_tracker/screens/settings/account/api-tokens/api_tokens_screen.dart';

/// Example demonstrating how to use ErrorStateWidget with existing error handling patterns
/// This shows the migration from the current api_tokens_screen.dart error handling
class ErrorStateWidgetExample extends ConsumerWidget {
  const ErrorStateWidgetExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ErrorStateWidget Examples'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildExampleCard(
            context,
            'UnauthorizedException Example',
            'Shows session expired error with automatic redirect',
            () => _showErrorExample(
              context,
              UnauthorizedException(
                'Your session has expired. Please log in again.',
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildExampleCard(
            context,
            'RateLimitException Example',
            'Shows rate limiting error with retry option',
            () => _showErrorExample(
              context,
              RateLimitException(
                'Too many requests. Please wait before trying again.',
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildExampleCard(
            context,
            'CloudflareTunnelException Example',
            'Shows server tunnel error with retry and info options',
            () => _showErrorExample(
              context,
              CloudflareTunnelException(
                'The server tunnel is currently down. Please try again later.',
                502,
                'Bad Gateway',
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildExampleCard(
            context,
            'NetworkException Example',
            'Shows network connection error with retry option',
            () => _showErrorExample(
              context,
              NetworkException('Network error: Please check your connection.'),
            ),
          ),
          const SizedBox(height: 16),

          _buildExampleCard(
            context,
            'ApiException (Server Error) Example',
            'Shows server error with retry and info options',
            () => _showErrorExample(
              context,
              ApiException('Internal server error occurred.', 500),
            ),
          ),
          const SizedBox(height: 16),

          _buildExampleCard(
            context,
            'ApiException (Client Error) Example',
            'Shows client error (403 Forbidden)',
            () => _showErrorExample(
              context,
              ApiException(
                'You do not have permission to perform this action.',
                403,
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildExampleCard(
            context,
            'Generic Exception Example',
            'Shows generic error handling',
            () => _showErrorExample(
              context,
              Exception('An unexpected error occurred'),
            ),
          ),
          const SizedBox(height: 16),

          _buildExampleCard(
            context,
            'Compact Mode Example',
            'Shows error in compact format',
            () => _showCompactErrorExample(
              context,
              NetworkException('Connection failed'),
            ),
          ),
          const SizedBox(height: 16),

          _buildExampleCard(
            context,
            'Custom Message Example',
            'Shows error with custom title and message',
            () => _showCustomErrorExample(
              context,
              ApiException('Server overloaded', 503),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(
    BuildContext context,
    String title,
    String description,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: ListTile(
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showErrorExample(BuildContext context, dynamic error) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) =>
                _ErrorExampleScreen(error: error, title: 'Error Example'),
      ),
    );
  }

  void _showCompactErrorExample(BuildContext context, dynamic error) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => _ErrorExampleScreen(
              error: error,
              title: 'Compact Error Example',
              compact: true,
            ),
      ),
    );
  }

  void _showCustomErrorExample(BuildContext context, dynamic error) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => _ErrorExampleScreen(
              error: error,
              title: 'Custom Error Example',
              customTitle: 'Service Temporarily Down',
              customMessage:
                  'Our servers are experiencing high load. Please try again in a few minutes.',
            ),
      ),
    );
  }
}

class _ErrorExampleScreen extends ConsumerWidget {
  final dynamic error;
  final String title;
  final bool compact;
  final String? customTitle;
  final String? customMessage;

  const _ErrorExampleScreen({
    required this.error,
    required this.title,
    this.compact = false,
    this.customTitle,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ErrorStateWidget(
        error: error,
        compact: compact,
        customTitle: customTitle,
        customMessage: customMessage,
        onRetry: () {
          // Simulate retry action
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Retry action triggered!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        onInfo: () {
          // Custom info action (optional - widget provides default)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Custom info action triggered!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}

/// Example showing how to migrate from existing error handling in api_tokens_screen.dart
/// This demonstrates the before/after comparison
class MigrationExample extends ConsumerWidget {
  const MigrationExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTokens = ref.watch(apiTokensProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Migration Example')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(apiTokensProvider),
        child: asyncTokens.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          // OLD WAY: Complex error handling with lots of if-else statements
          // error: (error, stackTrace) => _buildOldErrorState(context, error, ref),

          // NEW WAY: Simple, consistent error handling
          error:
              (error, stackTrace) => ErrorStateWidget(
                error: error,
                onRetry: () => ref.invalidate(apiTokensProvider),
              ),

          data:
              (tokens) => ListView.builder(
                itemCount: tokens.length,
                itemBuilder:
                    (context, index) =>
                        ListTile(title: Text(tokens[index].description)),
              ),
        ),
      ),
    );
  }

  // This is what the old error handling looked like (commented out for reference)
  /*
  Widget _buildOldErrorState(BuildContext context, dynamic error, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Handle UnauthorizedException
    if (error is UnauthorizedException) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.logout, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Your session has expired. Please log in again.'),
                ),
              ],
            ),
            backgroundColor: Colors.orange[600],
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/auth/v1', (route) => false);
      });
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            Text(
              'Session Expired',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Redirecting to login...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      );
    }

    // Handle RateLimitException
    if (error is RateLimitException) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            Text(
              'Rate Limited',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error.message,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              onPressed: () => ref.invalidate(apiTokensProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // ... and many more similar if-else blocks for other error types
    // This is exactly what ErrorStateWidget replaces!
  }
  */
}
