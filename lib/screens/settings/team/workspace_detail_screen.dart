import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/models/team/team_models.dart';
import 'package:emotion_tracker/providers/team/team_providers.dart';
import 'package:emotion_tracker/widgets/sidebar_widget.dart';
import 'package:emotion_tracker/screens/settings/team/team_wallet_screen.dart';

class WorkspaceDetailScreen extends ConsumerStatefulWidget {
  final TeamWorkspace workspace;
  final int initialTab;

  const WorkspaceDetailScreen({
    Key? key,
    required this.workspace,
    this.initialTab = 0,
  }) : super(key: key);

  @override
  ConsumerState<WorkspaceDetailScreen> createState() =>
      _WorkspaceDetailScreenState();
}

class _WorkspaceDetailScreenState extends ConsumerState<WorkspaceDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    // Load audit trail for this workspace
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(auditTrailProvider(widget.workspace.workspaceId).notifier)
          .loadAuditTrail(limit: 10);
    });
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
        title: Text(widget.workspace.name),
        elevation: 0,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Members', icon: Icon(Icons.people)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
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
            _buildOverviewTab(context, theme),
            _buildMembersTab(context, theme),
            _buildAnalyticsTab(context, theme),
            _buildSettingsTab(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, ThemeData theme) {
    final walletAsync = ref.watch(
      teamWalletProvider(widget.workspace.workspaceId),
    );

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh audit trail and wallet for this workspace
        var auditOk = true;
        var walletOk = true;
        try {
          await ref
              .read(auditTrailProvider(widget.workspace.workspaceId).notifier)
              .loadAuditTrail(limit: 10);
        } catch (_) {
          auditOk = false;
        }
        try {
          await ref
              .read(teamWalletProvider(widget.workspace.workspaceId).notifier)
              .loadWallet();
        } catch (_) {
          walletOk = false;
        }

        if (auditOk && walletOk) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workspace details refreshed')),
          );
        } else if (auditOk) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audit trail refreshed (wallet failed)'),
            ),
          );
        } else if (walletOk) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wallet refreshed (audit failed)')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to refresh workspace details'),
            ),
          );
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workspace Header Card
            _buildWorkspaceHeaderCard(context, theme),

            const SizedBox(height: 24),

            // Quick Stats
            _buildQuickStats(context, theme),

            const SizedBox(height: 24),

            // Wallet Status
            _buildWalletStatus(context, theme, walletAsync),

            const SizedBox(height: 24),

            // Recent Activity
            _buildRecentActivity(context, theme),

            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkspaceHeaderCard(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.primaryColor.withOpacity(0.15),
              theme.primaryColor.withOpacity(0.05),
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
                    color: theme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.business,
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
                        widget.workspace.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      if (widget.workspace.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.workspace.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildInfoChip(
                  context,
                  theme,
                  icon: Icons.people,
                  label: '${widget.workspace.members.length} members',
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  context,
                  theme,
                  icon: Icons.calendar_today,
                  label:
                      'Created ${widget.workspace.createdAt.toString().split(' ')[0]}',
                  color: Colors.purple,
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  context,
                  theme,
                  icon: widget.workspace.settings.allowMemberInvites
                      ? Icons.lock_open
                      : Icons.lock,
                  label: widget.workspace.settings.allowMemberInvites
                      ? 'Open Invites'
                      : 'Closed Invites',
                  color: widget.workspace.settings.allowMemberInvites
                      ? Colors.green
                      : Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Quick Stats',
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
                icon: Icons.people,
                title: 'Total Members',
                value: widget.workspace.members.length.toString(),
                color: Colors.blue,
                trend: '+2 this week',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                theme,
                icon: Icons.account_balance_wallet,
                title: 'Wallet Status',
                value: 'Active',
                color: Colors.green,
                trend: 'Balance: --',
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
                value: '3',
                color: Colors.orange,
                trend: '2 approvals needed',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                theme,
                icon: Icons.trending_up,
                title: 'Activity Score',
                value: '85%',
                color: Colors.purple,
                trend: '+5% from last month',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required String trend,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
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
              trend,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletStatus(
    BuildContext context,
    ThemeData theme,
    AsyncValue<TeamWallet?> walletAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Wallet Status',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
        ),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: walletAsync.when(
            data: (wallet) => wallet == null
                ? Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.withOpacity(0.1),
                          Colors.grey.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 48,
                          color: theme.hintColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Wallet not initialized',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showInitializeWalletDialog(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('Initialize Wallet'),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (wallet.isFrozen ? Colors.red : Colors.green)
                              .withOpacity(0.1),
                          (wallet.isFrozen ? Colors.red : Colors.green)
                              .withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (wallet.isFrozen ? Colors.red : Colors.green)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: wallet.isFrozen ? Colors.red : Colors.green,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 20),
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
                                '${wallet.balance.toStringAsFixed(2)} SBD',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: wallet.isFrozen
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                              if (wallet.isFrozen)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'Frozen',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/team/wallets'),
                          icon: Icon(
                            Icons.arrow_forward_ios,
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
            loading: () => Container(
              padding: const EdgeInsets.all(48),
              child: const CircularProgressIndicator(),
            ),
            error: (error, _) => Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Failed to load wallet'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(
                      teamWalletProvider(widget.workspace.workspaceId),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, ThemeData theme) {
    return Consumer(
      builder: (context, ref, child) {
        final auditTrailAsync = ref.watch(
          auditTrailProvider(widget.workspace.workspaceId),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 16),
              child: Row(
                children: [
                  Text(
                    'Recent Activity',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showAllActivity(context),
                    child: Text(
                      'View All',
                      style: TextStyle(color: theme.primaryColor),
                    ),
                  ),
                ],
              ),
            ),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: auditTrailAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error,
                            color: theme.colorScheme.error,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load activity',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (auditEntries) {
                    if (auditEntries.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.history,
                                color: theme.hintColor,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No recent activity',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Take only the first 4 entries for the summary view
                    final recentEntries = auditEntries.take(4).toList();

                    return Column(
                      children: recentEntries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _getActivityIcon(entry.action),
                                  color: theme.primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getActivityDescription(entry),
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Text(
                                      '${entry.adminUsername ?? entry.adminUserId ?? 'System'} • ${_formatTimestamp(entry.timestamp)}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: theme.hintColor),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
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
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionButton(
              context,
              theme,
              icon: Icons.person_add,
              label: 'Invite Member',
              color: Colors.blue,
              onPressed: () => _showInviteMemberDialog(context, ref),
            ),
            _buildActionButton(
              context,
              theme,
              icon: Icons.account_balance_wallet,
              label: 'Manage Wallet',
              color: Colors.green,
              onPressed: () => Navigator.of(context).pushNamed('/team/wallets'),
            ),
            _buildActionButton(
              context,
              theme,
              icon: Icons.analytics,
              label: 'View Analytics',
              color: Colors.purple,
              onPressed: () => _tabController.animateTo(2),
            ),
            _buildActionButton(
              context,
              theme,
              icon: Icons.settings,
              label: 'Workspace Settings',
              color: Colors.teal,
              onPressed: () => _tabController.animateTo(3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
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
          width: (MediaQuery.of(context).size.width - 64) / 2,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                child: Icon(icon, color: color, size: 24),
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

  Widget _buildMembersTab(BuildContext context, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Members Header
          Row(
            children: [
              Text(
                'Team Members',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.workspace.members.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showInviteMemberDialog(context, ref),
                icon: const Icon(Icons.person_add),
                label: const Text('Invite Member'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Members List
          ...widget.workspace.members.map(
            (member) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMemberCard(context, ref, member, theme),
            ),
          ),

          // Empty State
          if (widget.workspace.members.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(Icons.people, size: 64, color: theme.hintColor),
                    const SizedBox(height: 16),
                    Text(
                      'No members yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Invite team members to collaborate',
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
    );
  }

  Widget _buildMemberCard(
    BuildContext context,
    WidgetRef ref,
    WorkspaceMember member,
    ThemeData theme,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getRoleColor(member.role).withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    color: _getRoleColor(member.role),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              member
                                  .userId, // TODO: Replace with actual user name
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          if (member.userId == widget.workspace.ownerId)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.amber.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Owner',
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor(member.role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getRoleColor(member.role).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          member.role.displayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getRoleColor(member.role),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (member.userId != widget.workspace.ownerId)
                  PopupMenuButton<String>(
                    onSelected: (action) =>
                        _handleMemberAction(context, ref, member, action),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'change_role',
                        child: Text('Change Role'),
                      ),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Text('Remove Member'),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: theme.hintColor),
                const SizedBox(width: 6),
                Text(
                  'Joined ${member.joinedAt.toString().split(' ')[0]}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab(BuildContext context, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workspace Analytics',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),

          const SizedBox(height: 24),

          // Analytics Cards
          _buildAnalyticsCard(
            context,
            theme,
            title: 'Member Growth',
            value: '+12%',
            subtitle: 'vs last month',
            icon: Icons.trending_up,
            color: Colors.green,
          ),

          const SizedBox(height: 16),

          _buildAnalyticsCard(
            context,
            theme,
            title: 'Active Sessions',
            value: '24',
            subtitle: 'this week',
            icon: Icons.access_time,
            color: Colors.blue,
          ),

          const SizedBox(height: 16),

          _buildAnalyticsCard(
            context,
            theme,
            title: 'Token Usage',
            value: '1,250 SBD',
            subtitle: 'total spent',
            icon: Icons.account_balance_wallet,
            color: Colors.purple,
          ),

          const SizedBox(height: 32),

          // Charts / Actions Placeholder
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              height: 200,
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 48, color: theme.hintColor),
                    const SizedBox(height: 12),
                    Text(
                      'Advanced analytics',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Detailed charts and reports are coming soon. Meanwhile you can view audit logs and compliance reports below.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AuditTrailScreen(
                                workspaceId: widget.workspace.workspaceId,
                              ),
                            ),
                          ),
                          child: const Text('View Audit Trail'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ComplianceReportScreen(
                                workspaceId: widget.workspace.workspaceId,
                              ),
                            ),
                          ),
                          child: const Text('Compliance Report'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
    BuildContext context,
    ThemeData theme, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
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

  Widget _buildSettingsTab(BuildContext context, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workspace Settings',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),

          const SizedBox(height: 24),

          // General Settings
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    'Workspace Name',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(widget.workspace.name),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showEditWorkspaceDialog(context, ref),
                ),
                const Divider(),
                ListTile(
                  title: Text(
                    'Description',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    widget.workspace.description ?? 'No description',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showEditWorkspaceDialog(context, ref),
                ),
                const Divider(),
                SwitchListTile(
                  title: Text(
                    'Allow Member Invites',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text('Let team members invite others'),
                  value: widget.workspace.settings.allowMemberInvites,
                  onChanged: (value) => _updateWorkspaceSettings(context, ref, {
                    'allow_member_invites': value,
                  }),
                ),
                const Divider(),
                ListTile(
                  title: Text(
                    'Default Member Role',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    widget.workspace.settings.defaultNewMemberRole.displayName,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showRoleSelectionDialog(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Danger Zone
          Text(
            'Danger Zone',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),

          const SizedBox(height: 16),

          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.red, width: 1),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.red.withOpacity(0.13),
                child: const Icon(
                  Icons.delete_forever,
                  color: Colors.red,
                  size: 26,
                ),
              ),
              title: Text(
                'Delete Workspace',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Colors.red,
                ),
              ),
              subtitle: Text(
                'Permanently delete this workspace and all associated data',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.red.withOpacity(0.7),
                ),
              ),
              onTap: () => _showDeleteWorkspaceDialog(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for dialogs and actions
  void _showInviteMemberDialog(BuildContext context, WidgetRef ref) {
    final idController = TextEditingController();
    WorkspaceRole selectedRole = widget.workspace.settings.defaultNewMemberRole;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Invite Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'User ID or email',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<WorkspaceRole>(
                value: selectedRole,
                items: WorkspaceRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.displayName),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => selectedRole = v);
                },
                decoration: const InputDecoration(labelText: 'Role'),
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
                final identifier = idController.text.trim();
                if (identifier.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an identifier')),
                  );
                  return;
                }
                try {
                  await ref
                      .read(teamWorkspacesProvider.notifier)
                      .addMember(
                        widget.workspace.workspaceId,
                        identifier,
                        selectedRole,
                      );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Member invited/added successfully'),
                    ),
                  );
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to invite member: $error')),
                  );
                }
              },
              child: const Text('Invite'),
            ),
          ],
        ),
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
                decoration: const InputDecoration(labelText: 'Wallet Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: balanceController,
                decoration: const InputDecoration(labelText: 'Initial Balance'),
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
              onPressed: isLoading
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      final balance = double.tryParse(balanceController.text);
                      if (name.isEmpty || balance == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please provide valid inputs'),
                          ),
                        );
                        return;
                      }
                      setState(() => isLoading = true);
                      try {
                        await ref
                            .read(
                              teamWalletProvider(
                                widget.workspace.workspaceId,
                              ).notifier,
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

  void _showAllActivity(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AuditTrailScreen(workspaceId: widget.workspace.workspaceId),
      ),
    );
  }

  void _handleMemberAction(
    BuildContext context,
    WidgetRef ref,
    WorkspaceMember member,
    String action,
  ) {
    switch (action) {
      case 'change_role':
        _showChangeRoleDialog(context, ref, member);
        break;
      case 'remove':
        _showRemoveMemberDialog(context, ref, member);
        break;
    }
  }

  void _showChangeRoleDialog(
    BuildContext context,
    WidgetRef ref,
    WorkspaceMember member,
  ) {
    WorkspaceRole selectedRole = member.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Member Role'),
          content: DropdownButtonFormField<WorkspaceRole>(
            value: selectedRole,
            items: WorkspaceRole.values.map((role) {
              return DropdownMenuItem(
                value: role,
                child: Text(role.displayName),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedRole = value);
              }
            },
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
                      .read(teamWorkspacesProvider.notifier)
                      .updateMemberRole(
                        widget.workspace.workspaceId,
                        member.userId,
                        selectedRole,
                      );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Member role updated successfully'),
                    ),
                  );
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update role: $error')),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveMemberDialog(
    BuildContext context,
    WidgetRef ref,
    WorkspaceMember member,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${member.userId} from this workspace?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await ref
                    .read(teamWorkspacesProvider.notifier)
                    .removeMember(widget.workspace.workspaceId, member.userId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Member removed successfully')),
                );
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to remove member: $error')),
                );
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showEditWorkspaceDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController(text: widget.workspace.name);
    final descriptionController = TextEditingController(
      text: widget.workspace.description ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Workspace'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Workspace Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
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
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a workspace name'),
                  ),
                );
                return;
              }

              try {
                await ref
                    .read(teamWorkspacesProvider.notifier)
                    .updateWorkspace(
                      widget.workspace.workspaceId,
                      name: name,
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Workspace updated successfully'),
                  ),
                );
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update workspace: $error')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateWorkspaceSettings(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> settings,
  ) async {
    try {
      await ref
          .read(teamWorkspacesProvider.notifier)
          .updateWorkspace(widget.workspace.workspaceId, settings: settings);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workspace settings updated successfully'),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update settings: $error')),
      );
    }
  }

  void _showRoleSelectionDialog(BuildContext context, WidgetRef ref) {
    WorkspaceRole selectedRole = widget.workspace.settings.defaultNewMemberRole;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Default New Member Role'),
          content: DropdownButtonFormField<WorkspaceRole>(
            value: selectedRole,
            items: WorkspaceRole.values.map((role) {
              return DropdownMenuItem(
                value: role,
                child: Text(role.displayName),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedRole = value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _updateWorkspaceSettings(context, ref, {
                  'default_new_member_role': selectedRole.name,
                });
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteWorkspaceDialog(BuildContext context, WidgetRef ref) {
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workspace'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This action cannot be undone. All workspace data, including team wallets and member information, will be permanently deleted.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                labelText: 'Type "DELETE" to confirm',
                hintText: 'DELETE',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (confirmController.text != 'DELETE') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please type "DELETE" to confirm'),
                  ),
                );
                return;
              }

              try {
                await ref
                    .read(teamWorkspacesProvider.notifier)
                    .deleteWorkspace(widget.workspace.workspaceId);
                Navigator.of(context).popUntil((route) => route.isFirst);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Workspace deleted successfully'),
                  ),
                );
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete workspace: $error')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(WorkspaceRole role) {
    switch (role) {
      case WorkspaceRole.admin:
        return Colors.red;
      case WorkspaceRole.editor:
        return Colors.blue;
      case WorkspaceRole.viewer:
        return Colors.green;
    }
  }

  IconData _getActivityIcon(String? action) {
    if (action == null) return Icons.history;

    if (action.contains('join') || action.contains('invite')) {
      return Icons.person_add;
    } else if (action.contains('approve') || action.contains('request')) {
      return Icons.check_circle;
    } else if (action.contains('transaction') || action.contains('transfer')) {
      return Icons.account_balance_wallet;
    } else if (action.contains('update') || action.contains('change')) {
      return Icons.settings;
    } else if (action.contains('remove') || action.contains('delete')) {
      return Icons.remove_circle;
    } else {
      return Icons.history;
    }
  }

  String _getActivityDescription(AuditEntry entry) {
    if (entry.action != null) {
      return entry.action!;
    }

    // Fallback based on event type
    switch (entry.eventType) {
      case AuditEventType.sbdTransaction:
        return 'SBD Transaction';
      case AuditEventType.permissionChange:
        return 'Permission Change';
      case AuditEventType.accountFreeze:
        return 'Account Freeze';
      case AuditEventType.adminAction:
        return 'Admin Action';
      case AuditEventType.complianceExport:
        return 'Compliance Export';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return '1 day ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
      }
    } else if (difference.inHours > 0) {
      if (difference.inHours == 1) {
        return '1 hour ago';
      } else {
        return '${difference.inHours} hours ago';
      }
    } else if (difference.inMinutes > 0) {
      if (difference.inMinutes == 1) {
        return '1 minute ago';
      } else {
        return '${difference.inMinutes} minutes ago';
      }
    } else {
      return 'Just now';
    }
  }
}
