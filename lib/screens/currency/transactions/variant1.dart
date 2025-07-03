import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/sbd_tokens_provider.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/widgets/transaction_card.dart';
import 'package:emotion_tracker/screens/currency/variant1.dart' show TransactionDetailsDialog;

class TransactionsScreenV1 extends ConsumerStatefulWidget {
  const TransactionsScreenV1({Key? key}) : super(key: key);

  @override
  ConsumerState<TransactionsScreenV1> createState() => _TransactionsScreenV1State();
}

class _TransactionsScreenV1State extends ConsumerState<TransactionsScreenV1> {
  static const int _pageSize = 100;
  List<dynamic> _allTransactions = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _skip = 0;
  String? _error;

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
        _error = null;
      }
    });
    try {
      await ref.read(sbdTokensProvider.notifier).fetchTransactions(skip: _skip, limit: _pageSize);
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
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error', style: theme.textTheme.bodyMedium))
                : _allTransactions.isEmpty
                    ? Center(child: Text('No transactions found.', style: theme.textTheme.bodyMedium))
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
                                    ? const CircularProgressIndicator()
                                    : ElevatedButton(
                                        onPressed: _isLoading ? null : () => _fetchNextPage(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme.primaryColor,
                                          foregroundColor: theme.colorScheme.onPrimary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                    if (tx['transaction_id'] != null && note.isNotEmpty) {
                                      await ref.read(sbdTokensProvider.notifier).updateTransactionNote(
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
