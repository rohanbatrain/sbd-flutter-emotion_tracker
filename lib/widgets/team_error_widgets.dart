import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/team/team_exceptions.dart';

// Global error provider for team operations
final teamErrorProvider = StateProvider<TeamApiException?>((ref) => null);

// Global error handler widget
class TeamErrorHandler extends ConsumerWidget {
  final Widget child;

  const TeamErrorHandler({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<TeamApiException?>(teamErrorProvider, (previous, current) {
      if (current != null) {
        _showErrorDialog(context, current);
        // Clear the error after showing
        Future.microtask(
          () => ref.read(teamErrorProvider.notifier).state = null,
        );
      }
    });

    return child;
  }

  void _showErrorDialog(BuildContext context, TeamApiException error) {
    showDialog(
      context: context,
      builder: (context) => TeamErrorDialog(error: error),
    );
  }
}

// Error dialog widget
class TeamErrorDialog extends StatelessWidget {
  final TeamApiException error;

  const TeamErrorDialog({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(_getErrorIcon(error), color: _getErrorColor(error), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getErrorTitle(error),
              style: theme.textTheme.titleLarge?.copyWith(
                color: _getErrorColor(error),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.message, style: theme.textTheme.bodyLarge),
            if (error is RateLimitException) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please wait ${(error as RateLimitException).retryAfterSeconds ?? 60} seconds before trying again.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Technical details removed - TeamApiException doesn't include details
          ],
        ),
      ),
      actions: [
        if (error is RateLimitException)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Wait'),
          )
        else
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        if (error is! RateLimitException)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Could add retry logic here
            },
            child: const Text('Retry'),
          ),
      ],
    );
  }

  IconData _getErrorIcon(TeamApiException error) {
    if (error is PermissionDeniedException) {
      return Icons.lock;
    } else if (error is RateLimitException) {
      return Icons.timer;
    } else if (error is WalletNotInitializedException) {
      return Icons.account_balance_wallet;
    } else {
      return Icons.error;
    }
  }

  Color _getErrorColor(TeamApiException error) {
    if (error is PermissionDeniedException) {
      return Colors.red;
    } else if (error is RateLimitException) {
      return Colors.orange;
    } else if (error is WalletNotInitializedException) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }

  String _getErrorTitle(TeamApiException error) {
    return TeamErrorMessages.getErrorTitle(error);
  }
}

// Error boundary widget for team operations
class TeamErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(TeamApiException error)? errorBuilder;
  final void Function(TeamApiException error)? onError;

  const TeamErrorBoundary({
    Key? key,
    required this.child,
    this.errorBuilder,
    this.onError,
  }) : super(key: key);

  @override
  _TeamErrorBoundaryState createState() => _TeamErrorBoundaryState();
}

class _TeamErrorBoundaryState extends State<TeamErrorBoundary> {
  TeamApiException? _error;

  @override
  void initState() {
    super.initState();
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      final error = TeamApiException(
        'An unexpected error occurred',
        statusCode: 500,
      );
      _handleError(error);
    };
  }

  void _handleError(TeamApiException error) {
    setState(() {
      _error = error;
    });

    widget.onError?.call(error);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!) ??
          TeamErrorDialog(error: _error!);
    }

    return widget.child;
  }
}

// Loading state widget with error handling
class TeamAsyncBuilder<T> extends ConsumerWidget {
  final AsyncValue<T> asyncValue;
  final Widget Function(T data) dataBuilder;
  final Widget? loadingWidget;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;
  final VoidCallback? onRetry;

  const TeamAsyncBuilder({
    Key? key,
    required this.asyncValue,
    required this.dataBuilder,
    this.loadingWidget,
    this.errorBuilder,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncValue.when(
      data: dataBuilder,
      loading: () =>
          loadingWidget ?? const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        // Convert to TeamApiException if possible
        final teamError = error is TeamApiException
            ? error
            : TeamApiException(
                'An error occurred: ${error.toString()}',
                statusCode: 500,
              );

        if (errorBuilder != null) {
          return errorBuilder!(error, stackTrace);
        }

        return TeamErrorCard(error: teamError, onRetry: onRetry);
      },
    );
  }
}

// Error card widget for inline error display
class TeamErrorCard extends StatelessWidget {
  final TeamApiException error;
  final VoidCallback? onRetry;

  const TeamErrorCard({Key? key, required this.error, this.onRetry})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getErrorIcon(error), size: 48, color: _getErrorColor(error)),
            const SizedBox(height: 16),
            Text(
              _getErrorTitle(error),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (error is RateLimitException) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${(error as RateLimitException).retryAfterSeconds ?? 60}s',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getErrorIcon(TeamApiException error) {
    if (error is PermissionDeniedException) {
      return Icons.lock;
    } else if (error is RateLimitException) {
      return Icons.timer;
    } else if (error is WalletNotInitializedException) {
      return Icons.account_balance_wallet;
    } else {
      return Icons.error_outline;
    }
  }

  Color _getErrorColor(TeamApiException error) {
    if (error is PermissionDeniedException) {
      return Colors.red;
    } else if (error is RateLimitException) {
      return Colors.orange;
    } else if (error is WalletNotInitializedException) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }

  String _getErrorTitle(TeamApiException error) {
    if (error is PermissionDeniedException) {
      return 'Access Denied';
    } else if (error is RateLimitException) {
      return 'Please Wait';
    } else if (error is WalletNotInitializedException) {
      return 'Wallet Setup Required';
    } else {
      return 'Something Went Wrong';
    }
  }
}

// Retry helper with exponential backoff
class TeamRetryHelper {
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffFactor = 2.0,
    bool Function(TeamApiException error)? shouldRetry,
    void Function(TeamApiException error, int attempt)? onRetry,
  }) async {
    Duration delay = initialDelay;
    TeamApiException? lastError;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await operation();
      } catch (error) {
        final teamError = error is TeamApiException
            ? error
            : TeamApiException(
                'Operation failed: ${error.toString()}',
                statusCode: 500,
              );

        lastError = teamError;

        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(teamError)) {
          throw teamError;
        }

        // Don't retry on the last attempt
        if (attempt == maxAttempts) {
          break;
        }

        onRetry?.call(teamError, attempt);

        // Wait before retrying
        await Future.delayed(delay);
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffFactor).round(),
        );
      }
    }

    throw lastError!;
  }
}

// Rate limit handler widget
class TeamRateLimitHandler extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onRetry;

  const TeamRateLimitHandler({Key? key, required this.child, this.onRetry})
    : super(key: key);

  @override
  _TeamRateLimitHandlerState createState() => _TeamRateLimitHandlerState();
}

class _TeamRateLimitHandlerState extends ConsumerState<TeamRateLimitHandler> {
  Timer? _retryTimer;
  int _secondsRemaining = 0;

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _handleRateLimit(RateLimitException error) {
    setState(() {
      _secondsRemaining = error.retryAfterSeconds ?? 60;
    });

    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsRemaining--;
      });

      if (_secondsRemaining <= 0) {
        timer.cancel();
        widget.onRetry?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TeamApiException?>(teamErrorProvider, (previous, current) {
      if (current is RateLimitException) {
        _handleRateLimit(current);
      }
    });

    if (_secondsRemaining > 0) {
      return TeamErrorCard(
        error: RateLimitException(
          'Rate limit exceeded. Please wait before trying again.',
        ),
        onRetry: null, // Disable manual retry during countdown
      );
    }

    return widget.child;
  }
}
