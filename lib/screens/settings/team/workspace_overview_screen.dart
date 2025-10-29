import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/models/team/team_models.dart';
import 'package:emotion_tracker/providers/team/team_providers.dart';
import 'package:emotion_tracker/widgets/app_scaffold.dart';
import 'package:emotion_tracker/screens/settings/team/workspace_management_screen.dart';
import 'package:emotion_tracker/screens/settings/team/workspace_detail_screen.dart';
import 'package:emotion_tracker/utils/design_system.dart';
import 'package:emotion_tracker/providers/family/family_provider.dart';
import 'package:emotion_tracker/providers/profiles_provider.dart';

class WorkspaceOverviewScreen extends ConsumerWidget {
  const WorkspaceOverviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspacesAsync = ref.watch(teamWorkspacesProvider);
    final theme = Theme.of(context);

    // Load pending requests when workspaces are loaded
    ref.listen(teamWorkspacesProvider, (previous, next) {
      next.whenData((workspaces) {
        if (workspaces.isNotEmpty) {
          ref
              .read(allPendingRequestsProvider.notifier)
              .loadAllPendingRequests();
        }
      });
    });

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
      title: 'Workspace Overview',
      selectedItem: 'settings',
      onItemSelected: _onItemSelected,
      body: workspacesAsync.when(
        data: (workspaces) =>
            _buildOverviewContent(context, ref, workspaces, theme),
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

  Widget _buildOverviewContent(
    BuildContext context,
    WidgetRef ref,
    List<TeamWorkspace> workspaces,
    ThemeData theme,
  ) {
    final totalMembers = workspaces.fold<int>(
      0,
      (sum, workspace) => sum + workspace.members.length,
    );

    final activeWorkspaces = workspaces
        .where((w) => w.members.isNotEmpty)
        .length;
    final totalWorkspaces = workspaces.length;

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh workspaces and families
        var workspacesOk = true;
        var familiesOk = true;
        var pendingRequestsOk = true;
        try {
          await ref.read(teamWorkspacesProvider.notifier).loadWorkspaces();
        } catch (_) {
          workspacesOk = false;
        }
        try {
          await ref.read(familyListProvider.notifier).loadFamilies();
        } catch (_) {
          familiesOk = false;
        }
        try {
          await ref
              .read(allPendingRequestsProvider.notifier)
              .loadAllPendingRequests();
        } catch (_) {
          pendingRequestsOk = false;
        }

        // Provide subtle feedback to the user
        if (workspacesOk && familiesOk && pendingRequestsOk) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data refreshed successfully')),
          );
        } else if (workspacesOk && familiesOk) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Workspaces and families refreshed (requests failed)',
              ),
            ),
          );
        } else if (workspacesOk) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Workspaces refreshed (families and requests failed)',
              ),
            ),
          );
        } else if (familiesOk) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Families refreshed (workspaces and requests failed)',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to refresh data')),
          );
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            _buildWelcomeHeader(context, ref, theme, workspaces),

            const SizedBox(height: 24),

            // Stats Dashboard
            _buildStatsDashboard(
              context,
              ref,
              totalWorkspaces,
              activeWorkspaces,
              totalMembers,
            ),

            const SizedBox(height: 32),

            // Quick Actions
            _buildQuickActions(context, ref, theme, workspaces),

            const SizedBox(height: 32),

            // Recent Activity
            _buildRecentActivity(context, theme, workspaces),

            const SizedBox(height: 32),

            // Workspace Cards
            _buildWorkspaceCards(context, ref, workspaces, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    List<TeamWorkspace> workspaces,
  ) {
    final profilesState = ref.watch(profilesProvider);
    final userName = profilesState.current?.displayName ?? 'You';

    // Larger, more polished header with CTA
    return DesignSystem.gradientCard(
      colors: [
        theme.primaryColor.withOpacity(0.18),
        theme.primaryColor.withOpacity(0.03),
      ],
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      borderRadius: BorderRadius.circular(24),
      child: Row(
        children: [
          // Icon block
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.16),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.workspace_premium,
                color: theme.primaryColor,
                size: 44,
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $userName!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.primaryColor,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage your ${workspaces.length} workspace${workspaces.length != 1 ? 's' : ''} and collaborate with your team',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.hintColor,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Small informative badge (non-actionable)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 16, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  '${workspaces.length} spaces',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsDashboard(
    BuildContext context,
    WidgetRef ref,
    int totalWorkspaces,
    int activeWorkspaces,
    int totalMembers,
  ) {
    final theme = Theme.of(context);
    final pendingRequestsAsync = ref.watch(allPendingRequestsProvider);

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
                title: 'Spaces',
                value: totalWorkspaces.toString(),
                color: Colors.blue,
                subtitle: '$activeWorkspaces active',
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
                subtitle: 'across all workspaces',
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
                icon: Icons.account_balance_wallet,
                title: 'Active Wallets',
                value: activeWorkspaces.toString(),
                color: Colors.purple,
                subtitle: 'with team funds',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: pendingRequestsAsync.when(
                data: (pendingRequests) => _buildStatCard(
                  context,
                  theme,
                  icon: Icons.pending_actions,
                  title: 'Pending Requests',
                  value: pendingRequests.length.toString(),
                  color: Colors.orange,
                  subtitle: 'awaiting approval',
                ),
                loading: () => _buildStatCard(
                  context,
                  theme,
                  icon: Icons.pending_actions,
                  title: 'Pending Requests',
                  value: '...',
                  color: Colors.orange,
                  subtitle: 'loading...',
                ),
                error: (error, _) => _buildStatCard(
                  context,
                  theme,
                  icon: Icons.pending_actions,
                  title: 'Pending Requests',
                  value: '!',
                  color: Colors.red,
                  subtitle: 'error loading',
                ),
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
    required String subtitle,
  }) {
    return DesignSystem.standardCard(
      elevation: DesignSystem.mediumElevation,
      borderRadius: BorderRadius.circular(20),
      color: null,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
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
                    style: theme.textTheme.headlineMedium?.copyWith(
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    List<TeamWorkspace> workspaces,
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
              child: _buildActionButton(
                context,
                theme,
                icon: Icons.add_business,
                label: 'Create Workspace',
                color: Colors.blue,
                onPressed: () =>
                    Navigator.of(context).pushNamed('/team/workspaces'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                theme,
                icon: Icons.person_add,
                label: 'Invite Members',
                color: Colors.green,
                // Navigate to workspaces list where members can be managed
                onPressed: () =>
                    Navigator.of(context).pushNamed('/team/workspaces'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                theme,
                icon: Icons.account_balance_wallet,
                label: 'Manage Wallets',
                color: Colors.purple,
                onPressed: () =>
                    Navigator.of(context).pushNamed('/team/wallets'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                theme,
                icon: Icons.analytics,
                label: 'View Analytics',
                color: Colors.teal,
                onPressed: () => _showAnalytics(context, ref, workspaces),
              ),
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

  Widget _buildRecentActivity(
    BuildContext context,
    ThemeData theme,
    List<TeamWorkspace> workspaces,
  ) {
    // If no workspaces, show empty state
    if (workspaces.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Recent Activity',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history, size: 48, color: theme.hintColor),
                    const SizedBox(height: 16),
                    Text(
                      'No recent activity',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a workspace to get started',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Use audit trail from the first workspace
    return Consumer(
      builder: (context, ref, child) {
        final auditTrailAsync = ref.watch(
          auditTrailProvider(workspaces.first.workspaceId),
        );

        return auditTrailAsync.when(
          data: (auditEntries) {
            final recentEntries = auditEntries.take(4).toList();

            if (recentEntries.isEmpty) {
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
                          onPressed: () =>
                              _showAllActivity(context, workspaces.first),
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
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.history,
                              size: 48,
                              color: theme.hintColor,
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
                    ),
                  ),
                ],
              );
            }

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
                        onPressed: () =>
                            _showAllActivity(context, workspaces.first),
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
                    child: Column(
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
                                  _getActivityIcon(entry.eventType),
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
                                      '${workspaces.first.name} • ${_formatTimeAgo(entry.timestamp)}',
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
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 16),
                child: Text(
                  'Recent Activity',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.all(40),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          ),
          error: (error, stack) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 16),
                child: Text(
                  'Recent Activity',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load activity',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWorkspaceCards(
    BuildContext context,
    WidgetRef ref,
    List<TeamWorkspace> workspaces,
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
                'Your Workspaces',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed('/team/workspaces'),
                icon: Icon(Icons.grid_view, size: 18),
                label: const Text('View All'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                ),
              ),
            ],
          ),
        ),
        ...workspaces
            .take(3)
            .map(
              (workspace) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildWorkspaceCard(context, ref, workspace, theme),
              ),
            ),
      ],
    );
  }

  Widget _buildWorkspaceCard(
    BuildContext context,
    WidgetRef ref,
    TeamWorkspace workspace,
    ThemeData theme,
  ) {
    return DesignSystem.standardCard(
      elevation: DesignSystem.mediumElevation,
      borderRadius: BorderRadius.circular(20),
      color: null,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WorkspaceManagementScreen(workspace: workspace),
          ),
        ),
        child: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 20,
                      color: theme.hintColor,
                    ),
                  ],
                ),
                if (workspace.description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    workspace.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildWorkspaceChip(
                      context,
                      theme,
                      icon: Icons.people,
                      label: '${workspace.members.length}',
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildWorkspaceChip(
                      context,
                      theme,
                      icon: Icons.calendar_today,
                      label:
                          'Created ${workspace.createdAt.toString().split(' ')[0]}',
                      color: Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspaceChip(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
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

  // Note: create/invite actions navigate to the full Workspaces screen.

  void _showAnalytics(
    BuildContext context,
    WidgetRef ref,
    List<TeamWorkspace> workspaces,
  ) {
    // If we have at least one workspace, navigate to its detail analytics tab.
    if (workspaces.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              WorkspaceDetailScreen(workspace: workspaces.first, initialTab: 2),
        ),
      );
      return;
    }

    // Otherwise navigate to the workspaces listing so the user can create one.
    Navigator.of(context).pushNamed('/team/workspaces');
  }

  void _showAllActivity(BuildContext context, TeamWorkspace workspace) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkspaceDetailScreen(
          workspace: workspace,
          initialTab: 2,
        ), // Analytics tab
      ),
    );
  }

  IconData _getActivityIcon(AuditEventType eventType) {
    switch (eventType) {
      case AuditEventType.sbdTransaction:
        return Icons.account_balance_wallet;
      case AuditEventType.permissionChange:
        return Icons.security;
      case AuditEventType.accountFreeze:
        return Icons.ac_unit;
      case AuditEventType.adminAction:
        return Icons.admin_panel_settings;
      case AuditEventType.complianceExport:
        return Icons.file_download;
    }
  }

  String _getActivityDescription(AuditEntry entry) {
    if (entry.action != null && entry.action!.isNotEmpty) {
      return entry.action!;
    }

    // Fallback descriptions based on event type
    switch (entry.eventType) {
      case AuditEventType.sbdTransaction:
        return 'SBD Transaction completed';
      case AuditEventType.permissionChange:
        return 'Permissions updated';
      case AuditEventType.accountFreeze:
        return 'Account frozen/unfrozen';
      case AuditEventType.adminAction:
        return 'Admin action performed';
      case AuditEventType.complianceExport:
        return 'Compliance report generated';
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes != 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
