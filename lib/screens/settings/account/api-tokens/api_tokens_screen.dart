import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/api_token_service.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/core/global_error_handler.dart';
import 'create_token_dialog.dart';
import 'token_display_dialog.dart';

// FutureProvider for fetching API tokens
final apiTokensProvider = FutureProvider<List<ApiToken>>((ref) async {
  final service = ref.read(apiTokenServiceProvider);
  return await service.listTokens();
});

class ApiTokensScreen extends ConsumerWidget {
  const ApiTokensScreen({super.key});

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
              () => const LoadingStateWidget(
                message: 'Loading your API tokens...',
              ),
          error: (error, stackTrace) {
            return ErrorStateWidget(
              error: error,
              onRetry: () => ref.invalidate(apiTokensProvider),
            );
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
                          ? theme.cardColor.withValues(alpha: 0.6)
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
                                color: theme.colorScheme.error.withValues(
                                  alpha: 0.12,
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
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
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
          final errorState = GlobalErrorHandler.processError(e);

          // Handle session expiry specially using the new system
          if (e is UnauthorizedException) {
            await GlobalErrorHandler.handleUnauthorized(context, ref);
            return;
          }

          // Show error snackbar with retry action for retryable errors
          if (GlobalErrorHandler.isRetryable(errorState)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(errorState.icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_getRevokeErrorMessage(e))),
                  ],
                ),
                backgroundColor: errorState.color,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => _showRevokeDialog(context, ref, token),
                ),
              ),
            );
          } else {
            // Show error snackbar without retry for non-retryable errors
            GlobalErrorHandler.showErrorSnackbar(
              context,
              _getRevokeErrorMessage(e),
              errorState.type,
            );
          }
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
