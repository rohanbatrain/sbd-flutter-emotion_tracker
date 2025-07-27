import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/api_token_service.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/core/global_error_handler.dart';
import 'package:emotion_tracker/core/session_manager.dart';
import 'package:emotion_tracker/core/exceptions.dart' as core_ex;
import 'package:emotion_tracker/core/error_state.dart';
import 'create_token_dialog.dart';
import 'token_display_dialog.dart';

// FutureProvider for fetching API tokens
final apiTokensProvider = FutureProvider<List<ApiToken>>((ref) async {
  final service = ref.read(apiTokenServiceProvider);
  return await service.listTokens();
});

class ApiTokensScreen extends ConsumerWidget {
  const ApiTokensScreen({super.key});

  void _showErrorInfo(BuildContext context, dynamic error) {
    final errorState = GlobalErrorHandler.processError(error);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(errorState.icon, color: errorState.color),
            const SizedBox(width: 8),
            const Text('API Token Error Help'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Unable to load your API tokens.'),
            const SizedBox(height: 8),
            Text(errorState.message),
            const SizedBox(height: 16),
            const Text('Troubleshooting steps:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_getTroubleshootingSteps(errorState.type)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getTroubleshootingSteps(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.unauthorized:
        return '• Check if you are still logged in\n• Try logging out and back in\n• Contact support if issue persists';
      case ErrorType.networkError:
        return '• Check your internet connection\n• Try switching networks\n• Wait and try again';
      case ErrorType.serverError:
        return '• Server may be temporarily down\n• Try again in a few minutes\n• Check server status';
      case ErrorType.rateLimited:
        return '• You are making requests too quickly\n• Wait a few minutes\n• Try again later';
      default:
        return '• Try refreshing the page\n• Check your connection\n• Contact support if needed';
    }
  }

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
          loading: () => const LoadingStateWidget(
            message: 'Loading your API tokens...',
          ),
          error: (error, stackTrace) {
            final errorState = GlobalErrorHandler.processError(error);
            if (error is core_ex.UnauthorizedException) {
              SessionManager.redirectToLogin(context, message: 'Session expired. Please log in again.');
            }
            return ErrorStateWidget(
              error: errorState,
              onRetry: () => ref.invalidate(apiTokensProvider),
              onInfo: () => _showErrorInfo(context, error),
              customMessage: 'Unable to load API tokens. Please try again.',
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
                          ? theme.cardColor.withAlpha(153)
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
                                color: theme.colorScheme.error.withAlpha(30),
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
    final theme = Theme.of(context);
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
                    color: Colors.red.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withAlpha(77),
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
          ref.invalidate(apiTokensProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 4),
              content: Text('Token revoked successfully.'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          final errorState = GlobalErrorHandler.processError(e);
          if (e is core_ex.UnauthorizedException) {
            SessionManager.redirectToLogin(context, message: 'Session expired. Please log in again.');
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 4),
              content: Text(errorState.message),
              backgroundColor: theme.colorScheme.error,
              action: errorState.showRetry
                  ? SnackBarAction(
                      label: 'Retry',
                      textColor: Colors.white,
                      onPressed: () => ref.invalidate(apiTokensProvider),
                    )
                  : null,
            ),
          );
        }
      }
    }
  }
}
