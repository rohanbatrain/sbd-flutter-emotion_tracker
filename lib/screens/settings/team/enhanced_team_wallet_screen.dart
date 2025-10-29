import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/models/team/team_models.dart';
import 'package:emotion_tracker/providers/team/team_providers.dart';
import 'package:emotion_tracker/widgets/sidebar_widget.dart';
import 'package:emotion_tracker/utils/design_system.dart';
import 'package:emotion_tracker/screens/settings/team/team_wallet_screen.dart';
import 'package:emotion_tracker/screens/settings/team/workspace_detail_screen.dart';

class EnhancedTeamWalletScreen extends ConsumerStatefulWidget {
  const EnhancedTeamWalletScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EnhancedTeamWalletScreen> createState() =>
      _EnhancedTeamWalletScreenState();
}

class _EnhancedTeamWalletScreenState
    extends ConsumerState<EnhancedTeamWalletScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Wallets'),
        elevation: 0,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Transactions', icon: Icon(Icons.receipt_long)),
            Tab(text: 'Requests', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Settings', icon: Icon(Icons.settings)),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      drawer: SidebarWidget(
        selectedItem: 'settings',
        onItemSelected: _onItemSelected,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(context, workspacesAsync, theme),
            _buildTransactionsTab(context, workspacesAsync, theme),
            _buildRequestsTab(context, workspacesAsync, theme),
            _buildSettingsTab(context, workspacesAsync, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    AsyncValue<List<TeamWorkspace>> workspacesAsync,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          _buildWalletOverviewHeader(context, theme),

          const SizedBox(height: 24),

          // Quick Stats
          _buildWalletStats(context, workspacesAsync, theme),

          const SizedBox(height: 24),

          // Workspace Wallets
          _buildWorkspaceWallets(context, workspacesAsync, theme),
        ],
      ),
    );
  }

  Widget _buildWalletOverviewHeader(BuildContext context, ThemeData theme) {
    return DesignSystem.gradientCard(
      colors: [
        theme.primaryColor.withOpacity(0.15),
        theme.primaryColor.withOpacity(0.05),
      ],
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: theme.primaryColor,
              size: 40,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team Wallet Management',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage shared funds, track transactions, and handle token requests across all workspaces',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletStats(
    BuildContext context,
    AsyncValue<List<TeamWorkspace>> workspacesAsync,
    ThemeData theme,
  ) {
    return workspacesAsync.when(
      data: (workspaces) {
        final totalWallets = workspaces.length;
        final activeWallets = workspaces
            .where((w) => w.members.isNotEmpty)
            .length;
        final totalMembers = workspaces.fold<int>(
          0,
          (sum, w) => sum + w.members.length,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 16),
              child: Text(
                'Overview',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    theme,
                    icon: Icons.business,
                    title: 'Total Workspaces',
                    value: totalWallets.toString(),
                    color: Colors.blue,
                    subtitle: '$activeWallets with wallets',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    theme,
                    icon: Icons.people,
                    title: 'Team Members',
                    value: totalMembers.toString(),
                    color: Colors.green,
                    subtitle: 'across workspaces',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    theme,
                    icon: Icons.pending_actions,
                    title: 'Pending Requests',
                    value: '5', // TODO: Calculate from actual data
                    color: Colors.orange,
                    subtitle: 'awaiting approval',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    theme,
                    icon: Icons.trending_up,
                    title: 'Total Balance',
                    value: '2,450 SBD', // TODO: Calculate from actual data
                    color: Colors.purple,
                    subtitle: 'across all wallets',
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Failed to load stats: $error')),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required String subtitle,
  }) {
    return DesignSystem.gradientCard(
      colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceWallets(
    BuildContext context,
    AsyncValue<List<TeamWorkspace>> workspacesAsync,
    ThemeData theme,
  ) {
    return workspacesAsync.when(
      data: (workspaces) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Row(
              children: [
                Text(
                  'Workspace Wallets',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showCreateWorkspaceDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('New Workspace'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...workspaces.map(
            (workspace) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildWorkspaceWalletCard(context, ref, workspace, theme),
            ),
          ),
          if (workspaces.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(Icons.business, size: 64, color: theme.hintColor),
                    const SizedBox(height: 16),
                    Text(
                      'No workspaces yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a workspace to start managing team wallets',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Failed to load workspaces: $error')),
    );
  }

  Widget _buildWorkspaceWalletCard(
    BuildContext context,
    WidgetRef ref,
    TeamWorkspace workspace,
    ThemeData theme,
  ) {
    final walletAsync = ref.watch(teamWalletProvider(workspace.workspaceId));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                WorkspaceWalletDetailScreen(workspaceId: workspace.workspaceId),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor.withOpacity(0.08),
                theme.primaryColor.withOpacity(0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.business,
                      color: theme.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workspace.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        Text(
                          '${workspace.members.length} member${workspace.members.length != 1 ? 's' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  walletAsync.when(
                    data: (wallet) => wallet != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: wallet.isFrozen
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: wallet.isFrozen
                                    ? Colors.red.withOpacity(0.3)
                                    : Colors.green.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              wallet.isFrozen ? 'Frozen' : 'Active',
                              style: TextStyle(
                                color: wallet.isFrozen
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: const Text(
                              'Not Initialized',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                    loading: () => const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (error, _) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'Error',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 20,
                    color: theme.hintColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              walletAsync.when(
                data: (wallet) => wallet != null
                    ? Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Balance',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${wallet.balance.toStringAsFixed(2)} SBD',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: wallet.isFrozen
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recent Transactions',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${wallet.recentTransactions.length}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: ElevatedButton.icon(
                            onPressed: () => _showInitializeWalletDialog(
                              context,
                              ref,
                              workspace,
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Initialize Wallet'),
                          ),
                        ),
                      ),
                loading: () => const Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('Failed to load wallet: $error'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsTab(
    BuildContext context,
    AsyncValue<List<TeamWorkspace>> workspacesAsync,
    ThemeData theme,
  ) {
    return workspacesAsync.when(
      data: (workspaces) => workspaces.isEmpty
          ? const Center(child: Text('No workspaces available'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: workspaces.length,
              itemBuilder: (context, index) {
                final workspace = workspaces[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildWorkspaceTransactionCard(
                    context,
                    ref,
                    workspace,
                    theme,
                  ),
                );
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Failed to load workspaces: $error')),
    );
  }

  Widget _buildWorkspaceTransactionCard(
    BuildContext context,
    WidgetRef ref,
    TeamWorkspace workspace,
    ThemeData theme,
  ) {
    final walletAsync = ref.watch(teamWalletProvider(workspace.workspaceId));

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: Text(
          workspace.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text('${workspace.members.length} members'),
        children: [
          walletAsync.when(
            data: (wallet) =>
                wallet != null && wallet.recentTransactions.isNotEmpty
                ? Column(
                    children: wallet.recentTransactions.map((transaction) {
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                (transaction.type == 'credit'
                                        ? Colors.green
                                        : Colors.red)
                                    .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            transaction.type == 'credit'
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: transaction.type == 'credit'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        title: Text(transaction.description),
                        subtitle: Text(
                          '${transaction.timestamp.toString().split(' ')[0]} • ${transaction.fromUser ?? 'System'}',
                        ),
                        trailing: Text(
                          '${transaction.type == 'credit' ? '+' : '-'}${transaction.amount} SBD',
                          style: TextStyle(
                            color: transaction.type == 'credit'
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No transactions yet'),
                  ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Failed to load transactions: $error'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(
    BuildContext context,
    AsyncValue<List<TeamWorkspace>> workspacesAsync,
    ThemeData theme,
  ) {
    return workspacesAsync.when(
      data: (workspaces) => workspaces.isEmpty
          ? const Center(child: Text('No workspaces available'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: workspaces.length,
              itemBuilder: (context, index) {
                final workspace = workspaces[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildWorkspaceRequestsCard(
                    context,
                    ref,
                    workspace,
                    theme,
                  ),
                );
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Failed to load workspaces: $error')),
    );
  }

  Widget _buildWorkspaceRequestsCard(
    BuildContext context,
    WidgetRef ref,
    TeamWorkspace workspace,
    ThemeData theme,
  ) {
    final requestsAsync = ref.watch(
      tokenRequestsProvider(workspace.workspaceId),
    );

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: Text(
          workspace.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text('${workspace.members.length} members'),
        children: [
          requestsAsync.when(
            data: (requests) => requests.isNotEmpty
                ? Column(
                    children: requests.map((request) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: request.status.color.withOpacity(
                            0.2,
                          ),
                          child: Icon(
                            Icons.pending_actions,
                            color: request.status.color,
                          ),
                        ),
                        title: Text(
                          'Request #${request.requestId.substring(0, 8)}',
                        ),
                        subtitle: Text(
                          '${request.amount} SBD • ${request.reason}',
                        ),
                        trailing: Chip(
                          label: Text(request.status.displayName),
                          backgroundColor: request.status.color.withOpacity(
                            0.2,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No pending requests'),
                  ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Failed to load requests: $error'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(
    BuildContext context,
    AsyncValue<List<TeamWorkspace>> workspacesAsync,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wallet Settings',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),

          const SizedBox(height: 24),

          // Global Settings
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    'Default Currency',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text('SBD (Steem Backed Dollars)'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showCurrencySelectionDialog(context),
                ),
                const Divider(),
                ListTile(
                  title: Text(
                    'Auto-approve Limits',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text('Set automatic approval limits'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showAutoApproveSettings(context),
                ),
                const Divider(),
                SwitchListTile(
                  title: Text(
                    'Require Approvals',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Require admin approval for transactions',
                  ),
                  value: true, // TODO: Get from settings
                  onChanged: (value) => _updateGlobalSettings(context, {
                    'require_approvals': value,
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Workspace-specific settings
          Text(
            'Workspace Settings',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),

          const SizedBox(height: 16),

          workspacesAsync.when(
            data: (workspaces) => Column(
              children: workspaces.map((workspace) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildWorkspaceSettingsCard(
                    context,
                    ref,
                    workspace,
                    theme,
                  ),
                );
              }).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Failed to load workspaces: $error')),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceSettingsCard(
    BuildContext context,
    WidgetRef ref,
    TeamWorkspace workspace,
    ThemeData theme,
  ) {
    final walletAsync = ref.watch(teamWalletProvider(workspace.workspaceId));

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: Text(
          workspace.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          walletAsync.when(
            data: (wallet) => wallet != null
                ? Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Freeze Account'),
                        subtitle: const Text('Prevent all spending'),
                        value: wallet.isFrozen,
                        onChanged: (value) => _toggleWalletFreeze(
                          context,
                          ref,
                          workspace.workspaceId,
                          value,
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Wallet Permissions'),
                        subtitle: const Text('Manage member permissions'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () =>
                            _showWalletPermissions(context, ref, workspace),
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Audit Trail'),
                        subtitle: const Text('View transaction history'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () =>
                            _showAuditTrail(context, workspace.workspaceId),
                      ),
                    ],
                  )
                : const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Wallet not initialized'),
                  ),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Failed to load wallet: $error'),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for dialogs and actions
  void _showCreateWorkspaceDialog(BuildContext context, WidgetRef ref) {
    // Navigate to the full workspaces screen where create/manage is available
    Navigator.of(context).pushNamed('/team/workspaces');
  }

  void _showInitializeWalletDialog(
    BuildContext context,
    WidgetRef ref,
    TeamWorkspace workspace,
  ) {
    // Navigate to workspace detail where initialize dialog is available
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkspaceDetailScreen(workspace: workspace),
      ),
    );
  }

  void _showCurrencySelectionDialog(BuildContext context) {
    String selected = 'SBD';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Default Currency'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('SBD (Steem Backed Dollars)'),
                value: 'SBD',
                groupValue: selected,
                onChanged: (v) => setState(() => selected = v ?? 'SBD'),
              ),
              // Add future currencies here
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateGlobalSettings(context, {'default_currency': selected});
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAutoApproveSettings(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto-approve Limits'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Auto-approve limit (integer amount in SBD)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            const Text(
              'Set a threshold below which transactions are auto-approved.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              final limit = int.tryParse(text);
              if (limit == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid integer')),
                );
                return;
              }
              Navigator.pop(context);
              _updateGlobalSettings(context, {'auto_approve_limit': limit});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _updateGlobalSettings(
    BuildContext context,
    Map<String, dynamic> settings,
  ) {
    // TODO: Implement global settings update
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Global settings updated')));
  }

  void _toggleWalletFreeze(
    BuildContext context,
    WidgetRef ref,
    String workspaceId,
    bool freeze,
  ) async {
    try {
      if (freeze) {
        await ref
            .read(teamWalletProvider(workspaceId).notifier)
            .freezeWallet('Admin freeze');
      } else {
        await ref
            .read(teamWalletProvider(workspaceId).notifier)
            .unfreezeWallet();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Wallet ${freeze ? 'frozen' : 'unfrozen'} successfully',
          ),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to ${freeze ? 'freeze' : 'unfreeze'} wallet: $error',
          ),
        ),
      );
    }
  }

  void _showWalletPermissions(
    BuildContext context,
    WidgetRef ref,
    TeamWorkspace workspace,
  ) {
    final memberIdController = TextEditingController();
    final limitController = TextEditingController();
    bool canSpend = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update Wallet Permissions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: memberIdController,
                decoration: const InputDecoration(labelText: 'Member ID'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: limitController,
                decoration: const InputDecoration(
                  labelText: 'Spending limit (integer)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: canSpend,
                    onChanged: (v) => setState(() => canSpend = v ?? false),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Can spend')),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final memberId = memberIdController.text.trim();
                final limit = int.tryParse(limitController.text.trim()) ?? -1;
                if (memberId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a member id')),
                  );
                  return;
                }
                Navigator.pop(context);
                try {
                  await ref
                      .read(teamWalletProvider(workspace.workspaceId).notifier)
                      .updatePermissions({
                        memberId: {
                          'can_spend': canSpend,
                          'spending_limit': limit,
                        },
                      });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Permissions updated')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update permissions: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAuditTrail(BuildContext context, String workspaceId) {
    // Navigate to the existing AuditTrailScreen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuditTrailScreen(workspaceId: workspaceId),
      ),
    );
  }
}

class WorkspaceWalletDetailScreen extends ConsumerStatefulWidget {
  final String workspaceId;

  const WorkspaceWalletDetailScreen({Key? key, required this.workspaceId})
    : super(key: key);

  @override
  ConsumerState<WorkspaceWalletDetailScreen> createState() =>
      _WorkspaceWalletDetailScreenState();
}

class _WorkspaceWalletDetailScreenState
    extends ConsumerState<WorkspaceWalletDetailScreen> {
  @override
  void initState() {
    super.initState();
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workspace Wallet'),
        elevation: 0,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: walletAsync.when(
        data: (wallet) => wallet == null
            ? _buildWalletNotInitialized(context, ref)
            : _buildWalletContent(context, ref, wallet, theme),
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
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Card
          _buildBalanceCard(context, wallet, theme),

          const SizedBox(height: 24),

          // Quick Actions
          _buildQuickActions(context, ref, wallet, theme),

          const SizedBox(height: 24),

          // Recent Transactions
          _buildRecentTransactions(context, wallet, theme),

          const SizedBox(height: 24),

          // Admin Actions
          _buildAdminActions(context, ref, wallet, theme),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    TeamWallet wallet,
    ThemeData theme,
  ) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: wallet.isFrozen
                ? [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)]
                : [
                    Colors.green.withOpacity(0.1),
                    Colors.green.withOpacity(0.05),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (wallet.isFrozen ? Colors.red : Colors.green)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
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
                          color: wallet.isFrozen ? Colors.red : Colors.green,
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
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
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
            const SizedBox(height: 24),
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
                            color: wallet.isFrozen ? Colors.red : Colors.green,
                            fontSize: 28,
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
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    WidgetRef ref,
    TeamWallet wallet,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Quick Actions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                theme,
                icon: Icons.add,
                label: 'Request Tokens',
                color: Colors.blue,
                onPressed: () => _showCreateTokenRequestDialog(context, ref),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                theme,
                icon: Icons.pending_actions,
                label: 'View Requests',
                color: Colors.orange,
                onPressed: () => _showPendingRequests(context, ref),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
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
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(
    BuildContext context,
    TeamWallet wallet,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Row(
            children: [
              Text(
                'Recent Transactions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showAllTransactions(context),
                child: Text(
                  'View All',
                  style: TextStyle(color: theme.primaryColor),
                ),
              ),
            ],
          ),
        ),
        if (wallet.recentTransactions.isEmpty)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(32),
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
                      (transaction.type == 'credit' ? Colors.green : Colors.red)
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
                                transaction.timestamp.toString().split(' ')[0],
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
      ],
    );
  }

  Widget _buildAdminActions(
    BuildContext context,
    WidgetRef ref,
    TeamWallet wallet,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Admin Actions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildAdminActionButton(
              context,
              theme,
              icon: wallet.isFrozen ? Icons.lock_open : Icons.lock,
              label: wallet.isFrozen ? 'Unfreeze Account' : 'Freeze Account',
              color: wallet.isFrozen ? Colors.green : Colors.red,
              onPressed: () =>
                  _showFreezeAccountDialog(context, ref, wallet.isFrozen),
            ),
            _buildAdminActionButton(
              context,
              theme,
              icon: Icons.history,
              label: 'Audit Trail',
              color: Colors.blue,
              onPressed: () => _showAuditTrail(context, widget.workspaceId),
            ),
            _buildAdminActionButton(
              context,
              theme,
              icon: Icons.assignment,
              label: 'Compliance Report',
              color: Colors.purple,
              onPressed: () =>
                  _showComplianceReport(context, widget.workspaceId),
            ),
            _buildAdminActionButton(
              context,
              theme,
              icon: Icons.settings,
              label: 'Wallet Settings',
              color: Colors.teal,
              onPressed: () => _showWalletSettings(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminActionButton(
    BuildContext context,
    ThemeData theme, {
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

  // Helper methods for dialogs and actions
  void _showInitializeWalletDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController(text: 'Team Wallet');
    final balanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final balance = double.tryParse(balanceController.text);

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a wallet name')),
                );
                return;
              }

              if (balance == null || balance < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid initial balance'),
                  ),
                );
                return;
              }

              try {
                await ref
                    .read(teamWalletProvider(widget.workspaceId).notifier)
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
                    content: Text('Failed to initialize wallet: $error'),
                  ),
                );
              }
            },
            child: const Text('Initialize'),
          ),
        ],
      ),
    );
  }

  void _showCreateTokenRequestDialog(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              final reason = reasonController.text.trim();

              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }

              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }

              try {
                await ref
                    .read(teamWalletProvider(widget.workspaceId).notifier)
                    .createTokenRequest(amount, reason);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Token request created successfully'),
                  ),
                );
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to create request: $error')),
                );
              }
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  void _showPendingRequests(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(tokenRequestsProvider(widget.workspaceId));

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
                      'Account ${isFrozen ? 'unfrozen' : 'unfrozen'} successfully',
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

  void _showAuditTrail(BuildContext context, String workspaceId) {
    // Navigate to the existing AuditTrailScreen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuditTrailScreen(workspaceId: workspaceId),
      ),
    );
  }

  void _showComplianceReport(BuildContext context, String workspaceId) {
    // Navigate to the existing ComplianceReportScreen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ComplianceReportScreen(workspaceId: workspaceId),
      ),
    );
  }

  void _showWalletSettings(BuildContext context, WidgetRef ref) {
    // Route to the full Team Wallets screen as a hub for settings
    Navigator.of(context).pushNamed('/team/wallets');
  }

  void _showAllTransactions(BuildContext context) {
    // For now route to the team wallets hub where transactions are accessible per workspace
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
