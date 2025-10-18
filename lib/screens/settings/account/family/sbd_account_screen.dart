import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'package:emotion_tracker/providers/family/family_provider.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';

class SBDAccountScreen extends ConsumerStatefulWidget {
  final String familyId;

  const SBDAccountScreen({Key? key, required this.familyId}) : super(key: key);

  @override
  ConsumerState<SBDAccountScreen> createState() => _SBDAccountScreenState();
}

class _SBDAccountScreenState extends ConsumerState<SBDAccountScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref
          .read(familyDetailsProvider(widget.familyId).notifier)
          .loadFamilyDetails();
      ref
          .read(transactionsProvider(widget.familyId).notifier)
          .loadTransactions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailsState = ref.watch(familyDetailsProvider(widget.familyId));
    final transactionsState = ref.watch(transactionsProvider(widget.familyId));
    final account = detailsState.sbdAccount;
    final isAdmin = detailsState.family?.isAdmin ?? false;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'SBD Account',
        showHamburger: false,
        showCurrency: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: account == null
          ? LoadingStateWidget(message: 'Loading account...')
          : Column(
              children: [
                Container(
                  color: theme.primaryColor.withOpacity(0.1),
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text('Balance', style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Text(
                        '${account.balance} ${account.currency}',
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: account.isFrozen
                              ? Colors.red
                              : theme.primaryColor,
                        ),
                      ),
                      if (account.isFrozen) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Account Frozen',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'Transactions'),
                    Tab(text: 'Permissions'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTransactionsTab(transactionsState),
                      _buildPermissionsTab(detailsState, isAdmin, theme),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTransactionsTab(TransactionsState transactionsState) {
    if (transactionsState.isLoading) {
      return LoadingStateWidget(message: 'Loading transactions...');
    }

    if (transactionsState.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(transactionsProvider(widget.familyId).notifier)
            .loadTransactions();
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: transactionsState.transactions.length,
        itemBuilder: (context, index) {
          final tx = transactionsState.transactions[index];
          return Card(
            margin: EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: tx.type == 'spend'
                    ? Colors.red.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                child: Icon(
                  tx.type == 'spend'
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  color: tx.type == 'spend' ? Colors.red : Colors.green,
                ),
              ),
              title: Text(tx.username),
              subtitle: Text(tx.description ?? tx.type.toUpperCase()),
              trailing: Text(
                '${tx.type == 'spend' ? '-' : '+'}${tx.amount}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: tx.type == 'spend' ? Colors.red : Colors.green,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermissionsTab(
    FamilyDetailsState detailsState,
    bool isAdmin,
    ThemeData theme,
  ) {
    if (detailsState.members.isEmpty) {
      return Center(child: Text('No members found'));
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: detailsState.members.length,
      itemBuilder: (context, index) {
        final member = detailsState.members[index];
        final permissions = member.spendingPermissions;

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      child: Text(
                        member.displayName[0].toUpperCase(),
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            member.role.toUpperCase(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Can Spend:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Switch(
                      value: permissions?.canSpend ?? true,
                      onChanged: isAdmin
                          ? (value) {
                              // TODO: Implement permission update
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Permission update coming soon',
                                  ),
                                ),
                              );
                            }
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Spending Limit:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      (permissions?.spendingLimit ?? -1) == -1
                          ? 'Unlimited'
                          : '${permissions?.spendingLimit ?? 0} SBD',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
