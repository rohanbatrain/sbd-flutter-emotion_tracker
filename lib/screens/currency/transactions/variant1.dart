import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/sbd_tokens_provider.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/widgets/transaction_card.dart';
import 'package:emotion_tracker/screens/currency/variant2.dart'
    show TransactionDetailsDialog;
import 'package:emotion_tracker/core/global_error_handler.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/core/session_manager.dart';
import 'package:emotion_tracker/core/exceptions.dart';
import 'package:emotion_tracker/core/error_state.dart';

class TransactionsScreenV1 extends ConsumerStatefulWidget {
  const TransactionsScreenV1({Key? key}) : super(key: key);

  @override
  ConsumerState<TransactionsScreenV1> createState() =>
      _TransactionsScreenV1State();
}

class _TransactionsScreenV1State extends ConsumerState<TransactionsScreenV1> {
  static const int _pageSize = 100;
  List<dynamic> _allTransactions = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _skip = 0;
  ErrorState? _errorState;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchNextPage(initial: true);
    });
  }

  Future<void> _fetchNextPage({bool initial = false}) async {
    setState(() {
      _isLoading = true;
      if (initial) {
        _allTransactions = [];
        _skip = 0;
        _hasMore = true;
        _errorState = null;
      }
    });
    try {
      await ref
          .read(sbdTokensProvider.notifier)
          .fetchTransactions(skip: _skip, limit: _pageSize);
      final sbdState = ref.read(sbdTokensProvider);
      final newTxs = sbdState.transactions ?? [];
      setState(() {
        if (initial) {
          _allTransactions = newTxs;
        } else {
          _allTransactions.addAll(newTxs);
        }
        _skip += newTxs.length;
        _hasMore = newTxs.length == _pageSize;
        _errorState = null;
      });
    } catch (e) {
      final errorState = GlobalErrorHandler.processError(e);
      setState(() {
        _errorState = errorState;
      });
      if (e is UnauthorizedException) {
        SessionManager.redirectToLogin(
          context,
          message: 'Session expired. Please log in again.',
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleRetry() {
    _fetchNextPage(initial: true);
    GlobalErrorHandler.showErrorSnackbar(
      context,
      'Retrying request...',
      ErrorType.generic,
    );
  }

  void _showErrorInfo(dynamic error) {
    final errorState = GlobalErrorHandler.processError(error);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(errorState.icon, color: errorState.color),
            const SizedBox(width: 8),
            const Text('Transaction Error Help'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Unable to load your transactions.'),
            const SizedBox(height: 8),
            Text(errorState.message),
            const SizedBox(height: 16),
            const Text(
              'Troubleshooting steps:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () => _fetchNextPage(initial: true),
        child: _isLoading && _allTransactions.isEmpty
            ? const LoadingStateWidget(message: 'Loading your transactions...')
            : _errorState != null
            ? ErrorStateWidget(
                error: _errorState!,
                onRetry: _handleRetry,
                onInfo: () => _showErrorInfo(_errorState),
                customMessage: 'Unable to load transactions. Please try again.',
              )
            : _allTransactions.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: theme.primaryColor.withAlpha(80),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions found',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(180),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your transactions will appear here when available',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(120),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.only(
                  top: 16,
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                itemCount: _allTransactions.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, idx) {
                  if (idx == _allTransactions.length && _hasMore) {
                    // Load More button
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: _isLoading
                            ? const LoadingStateWidget(
                                message: 'Loading more transactions...',
                              )
                            : ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _fetchNextPage(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Load More'),
                              ),
                      ),
                    );
                  }
                  final tx = _allTransactions[idx];
                  return MinimalTransactionCard(
                    tx: tx,
                    theme: theme,
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (context) => TransactionDetailsDialog(
                          tx: tx,
                          theme: theme,
                          onNoteSaved: (note) async {
                            setState(() {
                              tx['note'] = note;
                            });
                            if (tx['transaction_id'] != null &&
                                note.isNotEmpty) {
                              await ref
                                  .read(sbdTokensProvider.notifier)
                                  .updateTransactionNote(
                                    transactionId: tx['transaction_id'],
                                    note: note,
                                  );
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
