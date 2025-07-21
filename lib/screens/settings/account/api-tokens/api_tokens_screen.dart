import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/api_token_service.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'create_token_dialog.dart';
import 'token_display_dialog.dart';

// FutureProvider for fetching API tokens
final apiTokensProvider = FutureProvider<List<ApiToken>>((ref) async {
  final service = ref.read(apiTokenServiceProvider);
  return await service.listTokens();
});

class ApiTokensScreen extends ConsumerWidget {
  const ApiTokensScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncTokens = ref.watch(apiTokensProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'API Tokens',
        showCurrency: false,
        showHamburger: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(apiTokensProvider),
        child: asyncTokens.when(
          loading:
              () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                        strokeWidth: 5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Loading your API tokens...',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please wait while we securely fetch your tokens.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
          error: (error, stackTrace) {
            return _buildErrorState(context, theme, error, ref);
          },
          data: (tokens) {
            if (tokens.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.key_off, size: 64, color: theme.hintColor),
                    const SizedBox(height: 16),
                    Text(
                      'No API tokens found',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first API token to get started with programmatic access.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: tokens.length,
              itemBuilder: (context, index) {
                final token = tokens[index];
                return Card(
                  elevation: 2,
                  color:
                      token.revoked
                          ? theme.cardColor.withOpacity(0.6)
                          : theme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          token.revoked
                              ? theme.hintColor
                              : theme.colorScheme.primary,
                      child: Icon(
                        token.revoked ? Icons.key_off : Icons.key,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      token.description,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: token.revoked ? theme.hintColor : null,
                        decoration:
                            token.revoked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Created: ${_formatDate(token.createdAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: token.revoked ? theme.hintColor : null,
                            ),
                          ),
                          if (token.lastUsed != null)
                            Text(
                              'Last used: ${_formatDate(token.lastUsed!)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: token.revoked ? theme.hintColor : null,
                              ),
                            )
                          else
                            Text(
                              'Never used',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          if (token.revoked)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error.withOpacity(
                                  0.12,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'REVOKED',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    trailing:
                        token.revoked
                            ? Icon(Icons.block, color: theme.hintColor)
                            : IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: theme.colorScheme.error,
                              ),
                              onPressed:
                                  () => _showRevokeDialog(context, ref, token),
                              tooltip: 'Revoke token',
                            ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTokenDialog(context, ref),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildErrorState(
    BuildContext context,
    ThemeData theme,
    dynamic error,
    WidgetRef ref,
  ) {
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
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/auth/v1', (route) => false);
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

    // Handle CloudflareTunnelException and NetworkException
    if (error.toString().contains('CLOUDFLARE_TUNNEL_DOWN') ||
        error.toString().contains('Server tunnel is down')) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Server Unavailable',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'The server tunnel is currently down. Please try again later or contact support if the issue persists.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  onPressed: () => ref.invalidate(apiTokensProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.info_outline),
                  label: const Text('More Info'),
                  onPressed: () => _showServerErrorDialog(context, error),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Handle network errors
    if (error.toString().contains('NETWORK_ERROR') ||
        error.toString().contains('Network error')) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Connection Problem',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Please check your internet connection and try again.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () => ref.invalidate(apiTokensProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    // Handle ApiException with specific status codes
    if (error is ApiException) {
      IconData errorIcon;
      Color errorColor;
      String errorTitle;
      String errorDescription;

      switch (error.statusCode) {
        case 403:
          errorIcon = Icons.lock_outline;
          errorColor = Colors.orange;
          errorTitle = 'Access Denied';
          errorDescription = 'You do not have permission to access API tokens.';
          break;
        case 404:
          errorIcon = Icons.search_off;
          errorColor = Colors.grey;
          errorTitle = 'Not Found';
          errorDescription =
              'The API tokens endpoint was not found on the server.';
          break;
        case 500:
        case 502:
        case 503:
        case 504:
          errorIcon = Icons.error_outline;
          errorColor = Colors.red;
          errorTitle = 'Server Error';
          errorDescription =
              'The server is experiencing issues. Please try again later.';
          break;
        default:
          errorIcon = Icons.error_outline;
          errorColor = theme.colorScheme.error;
          errorTitle = 'Something went wrong';
          errorDescription = error.message;
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(errorIcon, color: errorColor, size: 48),
            const SizedBox(height: 16),
            Text(
              errorTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                color: errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorDescription,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () => ref.invalidate(apiTokensProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    // Handle generic errors
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: () => ref.invalidate(apiTokensProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showServerErrorDialog(BuildContext context, dynamic error) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Server Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The server is currently experiencing connectivity issues. This usually happens when:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '• The server tunnel is temporarily down\n• Network connectivity issues\n• Server maintenance is in progress',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Please wait a few minutes and try again. If the problem persists, contact your system administrator.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showCreateTokenDialog(BuildContext context, WidgetRef ref) async {
    final token = await showCreateTokenDialog(context);
    if (token != null) {
      // Show the token display dialog
      if (context.mounted) {
        await showTokenDisplayDialog(context, token);
      }

      // Refresh the token list to show the new token
      ref.invalidate(apiTokensProvider);
    }
  }

  void _showRevokeDialog(
    BuildContext context,
    WidgetRef ref,
    ApiToken token,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Revoke Token?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to revoke the token "${token.description}"?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This action cannot be undone. The token will be permanently disabled.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Revoke Token'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        final service = ref.read(apiTokenServiceProvider);
        await service.revokeToken(token.tokenId);

        if (context.mounted) {
          // Refresh the token list to reflect the revocation
          ref.invalidate(apiTokensProvider);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Token "${token.description}" has been revoked',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green[600],
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          String errorMessage = _getRevokeErrorMessage(e);

          // Handle session expiry specially
          if (e is UnauthorizedException) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(errorMessage)),
                  ],
                ),
                backgroundColor: Colors.orange[600],
                duration: const Duration(seconds: 4),
              ),
            );
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(errorMessage)),
                ],
              ),
              backgroundColor: Colors.red[600],
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _showRevokeDialog(context, ref, token),
              ),
            ),
          );
        }
      }
    }
  }

  String _getRevokeErrorMessage(dynamic error) {
    if (error is UnauthorizedException) {
      return 'Your session has expired. Please log in again.';
    }

    if (error is RateLimitException) {
      return error.message;
    }

    if (error is ApiException) {
      switch (error.statusCode) {
        case 404:
          return 'Token not found. It may have already been revoked.';
        case 403:
          return 'You do not have permission to revoke this token.';
        case 409:
          return 'Token is already revoked or in an invalid state.';
        case 429:
          return 'Too many requests. Please wait before trying again.';
        case 500:
        case 502:
        case 503:
        case 504:
          return 'Server error occurred. Please try again later.';
        default:
          return error.message.isNotEmpty
              ? error.message
              : 'Failed to revoke token. Please try again.';
      }
    }

    // Handle network and tunnel errors
    if (error.toString().contains('CLOUDFLARE_TUNNEL_DOWN') ||
        error.toString().contains('Server tunnel is down')) {
      return 'Server is temporarily unavailable. Please try again later.';
    }

    if (error.toString().contains('NETWORK_ERROR') ||
        error.toString().contains('Network error')) {
      return 'Network connection problem. Please check your internet connection.';
    }

    if (error.toString().contains('timeout') ||
        error.toString().contains('timed out')) {
      return 'Request timed out. Please try again.';
    }

    // Generic error message
    return 'Failed to revoke token. Please try again.';
  }
}
