import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/widgets/app_scaffold.dart';
import 'package:emotion_tracker/providers/team/team_providers.dart';
import 'package:emotion_tracker/models/team/team_models.dart';

class TeamWalletScreen extends ConsumerWidget {
  const TeamWalletScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final workspacesAsync = ref.watch(teamWorkspacesProvider);

    void _onItemSelected(String item) {
      Navigator.of(context).pop();
      if (item == 'dashboard') {
        Navigator.of(context).pushReplacementNamed('/home/v1');
      } else if (item == 'shop') {
        // Navigate to shop
      } else if (item == 'settings') {
        // Already in settings
      }
    }

    return AppScaffold(
      title: 'Team Wallets',
      selectedItem: 'settings',
      onItemSelected: _onItemSelected,
      body: workspacesAsync.when(
        data: (workspaces) => workspaces.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 64,
                        color: theme.hintColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No workspaces available',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a workspace first to manage team wallets',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: workspaces
                    .map(
                      (workspace) => Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: theme.primaryColor.withOpacity(
                              0.13,
                            ),
                            child: Icon(
                              Icons.business,
                              color: theme.primaryColor,
                              size: 26,
                            ),
                          ),
                          title: Text(
                            workspace.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Text(
                            '${workspace.members.length} member${workspace.members.length != 1 ? 's' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 20,
                            color: theme.hintColor,
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WorkspaceWalletScreen(
                                workspaceId: workspace.workspaceId,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load workspaces'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(teamWorkspacesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkspaceWalletScreen extends ConsumerStatefulWidget {
  final String workspaceId;

  const WorkspaceWalletScreen({Key? key, required this.workspaceId})
    : super(key: key);

  @override
  ConsumerState<WorkspaceWalletScreen> createState() =>
      _WorkspaceWalletScreenState();
}

class _WorkspaceWalletScreenState extends ConsumerState<WorkspaceWalletScreen> {
  @override
  void initState() {
    super.initState();
    // Load fresh wallet and token requests on screen appear
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teamWalletProvider(widget.workspaceId).notifier).loadWallet();
      ref
          .read(tokenRequestsProvider(widget.workspaceId).notifier)
          .loadPendingRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(teamWalletProvider(widget.workspaceId));
    final tokenRequestsAsync = ref.watch(
      tokenRequestsProvider(widget.workspaceId),
    );

    void _onItemSelected(String item) {
      Navigator.of(context).pop();
      if (item == 'dashboard') {
        Navigator.of(context).pushReplacementNamed('/home/v1');
      } else if (item == 'shop') {
        // Navigate to shop
      } else if (item == 'settings') {
        // Already in settings
      }
    }

    return AppScaffold(
      title: 'Team Wallet',
      selectedItem: 'settings',
      onItemSelected: _onItemSelected,
      body: walletAsync.when(
        data: (wallet) => wallet == null
            ? _buildWalletNotInitialized(context, ref)
            : _buildWalletContent(context, ref, wallet, tokenRequestsAsync),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load wallet: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(teamWalletProvider(widget.workspaceId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletNotInitialized(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 64,
              color: Theme.of(context).hintColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Team wallet not initialized',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Initialize the team wallet to start managing shared funds',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showInitializeWalletDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Initialize Wallet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletContent(
    BuildContext context,
    WidgetRef ref,
    TeamWallet wallet,
    AsyncValue<List<TokenRequest>> tokenRequestsAsync,
  ) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Card
          Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: wallet.isFrozen
                      ? [
                          Colors.red.withOpacity(0.1),
                          Colors.red.withOpacity(0.05),
                        ]
                      : [
                          Colors.green.withOpacity(0.1),
                          Colors.green.withOpacity(0.05),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: wallet.isFrozen
                              ? Colors.red.withOpacity(0.15)
                              : Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: wallet.isFrozen ? Colors.red : Colors.green,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              wallet.accountUsername,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: wallet.isFrozen
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                            Text(
                              'Team Wallet',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (wallet.isFrozen)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lock, color: Colors.red, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Frozen',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (wallet.isFrozen ? Colors.red : Colors.green)
                            .withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Balance',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.hintColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${wallet.balance.toStringAsFixed(2)} SBD',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: wallet.isFrozen
                                      ? Colors.red
                                      : Colors.green,
                                  fontSize: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (wallet.isFrozen ? Colors.red : Colors.green)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            wallet.isFrozen ? Icons.lock : Icons.check_circle,
                            color: wallet.isFrozen ? Colors.red : Colors.green,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Quick Actions
          Padding(
            padding: const EdgeInsets.only(left: 4.0, top: 10, bottom: 10),
            child: Text(
              'Quick Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
                letterSpacing: 0.8,
                fontSize: 22,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showCreateTokenRequestDialog(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withOpacity(0.1),
                            Colors.blue.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.add,
                              color: Colors.blue,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Request Tokens',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Request SBD tokens',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () =>
                        _showPendingRequests(context, ref, tokenRequestsAsync),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withOpacity(0.1),
                            Colors.orange.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.pending,
                              color: Colors.orange,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Pending Requests',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Review token requests',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Recent Transactions
          Padding(
            padding: const EdgeInsets.only(left: 4.0, top: 10, bottom: 10),
            child: Row(
              children: [
                Text(
                  'Recent Transactions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                    letterSpacing: 0.8,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${wallet.recentTransactions.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (wallet.recentTransactions.isEmpty)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.hintColor.withOpacity(0.05),
                      theme.hintColor.withOpacity(0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, size: 48, color: theme.hintColor),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Transactions will appear here once the wallet is active',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...wallet.recentTransactions.map(
              (transaction) => Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (transaction.type == 'credit'
                                ? Colors.green
                                : Colors.red)
                            .withOpacity(0.05),
                        Colors.transparent,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              (transaction.type == 'credit'
                                      ? Colors.green
                                      : Colors.red)
                                  .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          transaction.type == 'credit'
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: transaction.type == 'credit'
                              ? Colors.green
                              : Colors.red,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction.description,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: theme.hintColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  transaction.timestamp.toString().split(
                                    ' ',
                                  )[0],
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                                if (transaction.fromUser != null) ...[
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.person,
                                    size: 14,
                                    color: theme.hintColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    transaction.fromUser!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.hintColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (transaction.type == 'credit'
                                      ? Colors.green
                                      : Colors.red)
                                  .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${transaction.type == 'credit' ? '+' : '-'}${transaction.amount} SBD',
                          style: TextStyle(
                            color: transaction.type == 'credit'
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 28),

          // Admin Actions
          Padding(
            padding: const EdgeInsets.only(left: 4.0, top: 10, bottom: 10),
            child: Text(
              'Admin Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
                letterSpacing: 0.8,
                fontSize: 22,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildAdminActionButton(
                context,
                icon: wallet.isFrozen ? Icons.lock_open : Icons.lock,
                label: wallet.isFrozen ? 'Unfreeze Account' : 'Freeze Account',
                color: wallet.isFrozen ? Colors.green : Colors.red,
                onPressed: () =>
                    _showFreezeAccountDialog(context, ref, wallet.isFrozen),
              ),
              _buildAdminActionButton(
                context,
                icon: Icons.history,
                label: 'Audit Trail',
                color: Colors.blue,
                onPressed: () => _showAuditTrail(context, ref),
              ),
              _buildAdminActionButton(
                context,
                icon: Icons.assignment,
                label: 'Compliance Report',
                color: Colors.purple,
                onPressed: () => _showComplianceReport(context, ref),
              ),
              _buildAdminActionButton(
                context,
                icon: Icons.settings,
                label: 'Wallet Settings',
                color: Colors.teal,
                onPressed: () => _showWalletSettings(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showInitializeWalletDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController(text: 'Team Wallet');
    final balanceController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Initialize Team Wallet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Wallet Name',
                  hintText: 'Enter wallet name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: balanceController,
                decoration: const InputDecoration(
                  labelText: 'Initial Balance',
                  hintText: 'Enter initial balance',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      final balance = double.tryParse(balanceController.text);

                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a wallet name'),
                          ),
                        );
                        return;
                      }

                      if (balance == null || balance < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter a valid initial balance',
                            ),
                          ),
                        );
                        return;
                      }

                      setState(() => isLoading = true);
                      try {
                        await ref
                            .read(
                              teamWalletProvider(widget.workspaceId).notifier,
                            )
                            .initializeWallet(
                              initialBalance: balance,
                              currency: 'SBD',
                              walletName: name,
                            );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Wallet initialized successfully'),
                          ),
                        );
                      } catch (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to initialize wallet: $error',
                            ),
                          ),
                        );
                      } finally {
                        setState(() => isLoading = false);
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Initialize'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTokenRequestDialog(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Request Tokens'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'Enter amount of tokens',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Why do you need these tokens?',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final amount = double.tryParse(amountController.text);
                      final reason = reasonController.text.trim();

                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid amount'),
                          ),
                        );
                        return;
                      }

                      if (reason.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please provide a reason'),
                          ),
                        );
                        return;
                      }

                      setState(() => isLoading = true);
                      try {
                        await ref
                            .read(
                              teamWalletProvider(widget.workspaceId).notifier,
                            )
                            .createTokenRequest(amount, reason);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Token request created successfully'),
                          ),
                        );
                      } catch (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to create request: $error'),
                          ),
                        );
                      } finally {
                        setState(() => isLoading = false);
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Request'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPendingRequests(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<TokenRequest>> requestsAsync,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PendingTokenRequestsScreen(
          workspaceId: widget.workspaceId,
          requestsAsync: requestsAsync,
        ),
      ),
    );
  }

  void _showFreezeAccountDialog(
    BuildContext context,
    WidgetRef ref,
    bool isFrozen,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isFrozen ? 'Unfreeze' : 'Freeze'} Account'),
        content: isFrozen
            ? const Text('Are you sure you want to unfreeze this team wallet?')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Freezing the account will prevent all spending. Please provide a reason:',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      hintText: 'Why are you freezing this account?',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isFrozen ? Colors.green : Colors.red,
            ),
            onPressed: () async {
              try {
                if (isFrozen) {
                  await ref
                      .read(teamWalletProvider(widget.workspaceId).notifier)
                      .unfreezeWallet();
                } else {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please provide a reason')),
                    );
                    return;
                  }
                  await ref
                      .read(teamWalletProvider(widget.workspaceId).notifier)
                      .freezeWallet(reason);
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Account ${isFrozen ? 'unfrozen' : 'frozen'} successfully',
                    ),
                  ),
                );
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to ${isFrozen ? 'unfreeze' : 'freeze'} account: $error',
                    ),
                  ),
                );
              }
            },
            child: Text(isFrozen ? 'Unfreeze' : 'Freeze'),
          ),
        ],
      ),
    );
  }

  void _showAuditTrail(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuditTrailScreen(workspaceId: widget.workspaceId),
      ),
    );
  }

  void _showComplianceReport(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ComplianceReportScreen(workspaceId: widget.workspaceId),
      ),
    );
  }

  Widget _buildAdminActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
    );
  }

  void _showWalletSettings(BuildContext context, WidgetRef ref) {
    // Navigate to enhanced wallet screen which contains settings and admin tools
    Navigator.of(context).pushNamed('/team/wallets');
  }
}

class PendingTokenRequestsScreen extends ConsumerWidget {
  final String workspaceId;
  final AsyncValue<List<TokenRequest>> requestsAsync;

  const PendingTokenRequestsScreen({
    Key? key,
    required this.workspaceId,
    required this.requestsAsync,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Token Requests')),
      body: requestsAsync.when(
        data: (requests) => requests.isEmpty
            ? const Center(child: Text('No pending requests'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Request #${request.requestId.substring(0, 8)}',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              Chip(
                                label: Text(request.status.displayName),
                                backgroundColor: request.status.color
                                    .withOpacity(0.2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Amount: ${request.amount} SBD'),
                          Text('Reason: ${request.reason}'),
                          Text(
                            'Requested: ${request.createdAt.toString().split(' ')[0]}',
                          ),
                          if (request.adminComments != null) ...[
                            const SizedBox(height: 8),
                            Text('Comments: ${request.adminComments}'),
                          ],
                          const SizedBox(height: 16),
                          if (request.status == TokenRequestStatus.pending) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _showReviewDialog(
                                      context,
                                      ref,
                                      request,
                                      'deny',
                                    ),
                                    child: const Text('Deny'),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _showReviewDialog(
                                      context,
                                      ref,
                                      request,
                                      'approve',
                                    ),
                                    child: const Text('Approve'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showReviewDialog(
    BuildContext context,
    WidgetRef ref,
    TokenRequest request,
    String action,
  ) {
    final commentsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action == 'approve' ? 'Approve' : 'Deny'} Request'),
        content: TextField(
          controller: commentsController,
          decoration: const InputDecoration(
            labelText: 'Comments (Optional)',
            hintText: 'Add any comments...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(tokenRequestsProvider(workspaceId).notifier)
                    .reviewRequest(
                      request.requestId,
                      action,
                      comments: commentsController.text.trim().isEmpty
                          ? null
                          : commentsController.text.trim(),
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Request ${action}d successfully')),
                );
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to ${action} request: $error'),
                  ),
                );
              }
            },
            child: Text(action == 'approve' ? 'Approve' : 'Deny'),
          ),
        ],
      ),
    );
  }
}

class AuditTrailScreen extends ConsumerWidget {
  final String workspaceId;

  const AuditTrailScreen({Key? key, required this.workspaceId})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auditAsync = ref.watch(auditTrailProvider(workspaceId));

    return Scaffold(
      appBar: AppBar(title: const Text('Audit Trail')),
      body: auditAsync.when(
        data: (entries) => entries.isEmpty
            ? const Center(child: Text('No audit entries'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.eventType.displayName,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              Text(
                                entry.timestamp.toString().split(' ')[0],
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          if (entry.adminUsername != null) ...[
                            const SizedBox(height: 4),
                            Text('Admin: ${entry.adminUsername}'),
                          ],
                          if (entry.action != null) ...[
                            const SizedBox(height: 4),
                            Text('Action: ${entry.action}'),
                          ],
                          if (entry.reason != null) ...[
                            const SizedBox(height: 4),
                            Text('Reason: ${entry.reason}'),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'Hash: ${entry.integrityHash.substring(0, 16)}...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class ComplianceReportScreen extends ConsumerWidget {
  final String workspaceId;

  const ComplianceReportScreen({Key? key, required this.workspaceId})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reportAsync = ref.watch(complianceReportProvider(workspaceId));

    return Scaffold(
      appBar: AppBar(title: const Text('Compliance Report')),
      body: reportAsync.when(
        data: (report) => report == null
            ? const Center(child: Text('No compliance report available'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Compliance Report',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Generated: ${report.generatedAt.toString().split(' ')[0]}',
                            ),
                            Text('Report Type: ${report.reportType}'),
                            const SizedBox(height: 16),
                            Text(
                              'Summary',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total Transactions: ${report.summary['total_transactions']}',
                            ),
                            Text(
                              'Total Amount: ${report.summary['total_amount']} ${report.summary['currency']}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
