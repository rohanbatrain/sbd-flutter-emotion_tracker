import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'package:emotion_tracker/providers/family/family_provider.dart';
import 'package:emotion_tracker/providers/family/family_models.dart' as models;
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'package:emotion_tracker/screens/settings/account/family/members_screen.dart';
import 'package:emotion_tracker/screens/settings/account/family/sbd_account_screen.dart';
import 'package:emotion_tracker/screens/settings/account/family/token_requests_screen.dart';
import 'package:emotion_tracker/screens/settings/account/family/family_notifications_screen.dart';
import 'package:emotion_tracker/screens/settings/account/family/invitations_screen.dart';
import 'package:emotion_tracker/screens/settings/account/family/admin_actions_screen.dart';

class FamilyDetailsScreen extends ConsumerStatefulWidget {
  final String familyId;

  const FamilyDetailsScreen({Key? key, required this.familyId})
    : super(key: key);

  @override
  ConsumerState<FamilyDetailsScreen> createState() =>
      _FamilyDetailsScreenState();
}

class _FamilyDetailsScreenState extends ConsumerState<FamilyDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(familyDetailsProvider(widget.familyId).notifier)
          .loadFamilyDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailsState = ref.watch(familyDetailsProvider(widget.familyId));

    return Scaffold(
      appBar: CustomAppBar(
        title: detailsState.family?.name ?? 'Family',
        showHamburger: false,
        showCurrency: false, // SBD token display disabled
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (detailsState.family?.isAdmin == true)
            PopupMenuButton(
              icon: Icon(Icons.more_vert),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Delete Family',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                  onTap: () => Future.delayed(
                    Duration(milliseconds: 100),
                    () => _showDeleteFamilyDialog(detailsState.family!, theme),
                  ),
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Leave Family',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: Implement leave family
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Leave family feature coming soon'),
                      ),
                    );
                  },
                ),
              ],
            ),
        ],
      ),
      body: detailsState.isLoading && detailsState.family == null
          ? LoadingStateWidget(message: 'Loading family details...')
          : detailsState.error != null
          ? ErrorStateWidget(
              error: detailsState.error,
              onRetry: () {
                ref
                    .read(familyDetailsProvider(widget.familyId).notifier)
                    .clearError();
                ref
                    .read(familyDetailsProvider(widget.familyId).notifier)
                    .loadFamilyDetails();
              },
            )
          : RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(familyDetailsProvider(widget.familyId).notifier)
                    .loadFamilyDetails();
              },
              child: detailsState.family == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.family_restroom,
                            size: 72,
                            color: theme.primaryColor.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No family data available',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try refreshing or check your network connection.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () async {
                              ref
                                  .read(
                                    familyDetailsProvider(
                                      widget.familyId,
                                    ).notifier,
                                  )
                                  .clearError();
                              await ref
                                  .read(
                                    familyDetailsProvider(
                                      widget.familyId,
                                    ).notifier,
                                  )
                                  .loadFamilyDetails();
                            },
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Family Info Header Card
                        _buildFamilyInfoCard(detailsState.family!, theme),
                        const SizedBox(height: 24),

                        // Family Management Section
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0, bottom: 10),
                          child: Text(
                            'Family Management',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),

                        _buildMenuTile(
                          context: context,
                          icon: Icons.people,
                          title: 'Members',
                          subtitle:
                              '${detailsState.members.length} member${detailsState.members.length != 1 ? 's' : ''}',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    MembersScreen(familyId: widget.familyId),
                              ),
                            );
                          },
                          theme: theme,
                        ),
                        const SizedBox(height: 12),

                        if (detailsState.family!.isAdmin) ...[
                          _buildMenuTile(
                            context: context,
                            icon: Icons.mail_outline,
                            title: 'Invitations',
                            subtitle: _getInvitationSubtitle(
                              detailsState.invitations,
                            ),
                            badge: _getPendingInvitationsCount(
                              detailsState.invitations,
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => InvitationsScreen(
                                    familyId: widget.familyId,
                                  ),
                                ),
                              );
                            },
                            theme: theme,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Family Shop tile - visible to all members
                        _buildMenuTile(
                          context: context,
                          icon: Icons.storefront,
                          title: 'Family Shop',
                          subtitle: 'Browse and request items for your family',
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              '/family/shop/v1',
                              arguments: {'familyId': widget.familyId},
                            );
                          },
                          theme: theme,
                        ),
                        const SizedBox(height: 12),

                        const SizedBox(height: 24),

                        // Financial Section
                        if (detailsState.sbdAccount != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 4.0,
                              bottom: 10,
                            ),
                            child: Text(
                              'Financial',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),

                          _buildMenuTile(
                            context: context,
                            icon: Icons.account_balance_wallet,
                            title: 'SBD Account',
                            subtitle:
                                '${detailsState.sbdAccount!.balance} ${detailsState.sbdAccount!.currency}',
                            iconColor: detailsState.sbdAccount!.isFrozen
                                ? Colors.red
                                : Colors.green,
                            badge: detailsState.sbdAccount!.isFrozen
                                ? 'FROZEN'
                                : null,
                            badgeColor: Colors.red,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SBDAccountScreen(
                                    familyId: widget.familyId,
                                  ),
                                ),
                              );
                            },
                            theme: theme,
                          ),
                          const SizedBox(height: 12),

                          _buildMenuTile(
                            context: context,
                            icon: Icons.request_page,
                            title: 'Token Requests',
                            subtitle: detailsState.family!.isAdmin
                                ? 'Review pending requests'
                                : 'Request or view your requests',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TokenRequestsScreen(
                                    familyId: widget.familyId,
                                  ),
                                ),
                              );
                            },
                            theme: theme,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Notifications & Activity Section
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0, bottom: 10),
                          child: Text(
                            'Activity',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),

                        _buildMenuTile(
                          context: context,
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          subtitle: 'View family activity and alerts',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => FamilyNotificationsScreen(
                                  familyId: widget.familyId,
                                ),
                              ),
                            );
                          },
                          theme: theme,
                        ),
                        const SizedBox(height: 12),

                        if (detailsState.family!.isAdmin) ...[
                          _buildMenuTile(
                            context: context,
                            icon: Icons.admin_panel_settings,
                            title: 'Admin Actions Log',
                            subtitle:
                                'View audit log of administrative actions',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AdminActionsScreen(
                                    familyId: widget.familyId,
                                  ),
                                ),
                              );
                            },
                            theme: theme,
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
            ),
    );
  }

  Widget _buildFamilyInfoCard(models.Family family, ThemeData theme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.family_restroom,
                    color: theme.primaryColor,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        family.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: family.isAdmin
                              ? Colors.blue.withOpacity(0.1)
                              : theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: family.isAdmin
                                ? Colors.blue.withOpacity(0.3)
                                : theme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          family.userRole.toUpperCase(),
                          style: TextStyle(
                            color: family.isAdmin
                                ? Colors.blue[700]
                                : theme.primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.people,
                  label: 'Members',
                  value: family.memberCount.toString(),
                  theme: theme,
                ),
                _buildStatItem(
                  icon: Icons.admin_panel_settings,
                  label: 'Admins',
                  value: family.adminUserIds.length.toString(),
                  theme: theme,
                ),
                _buildStatItem(
                  icon: Icons.calendar_today,
                  label: 'Created',
                  value: _formatDate(family.createdAt),
                  theme: theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Icon(icon, color: theme.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeData theme,
    Color? iconColor,
    dynamic badge,
    Color? badgeColor,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: (iconColor ?? theme.primaryColor).withOpacity(0.1),
          child: Icon(icon, color: iconColor ?? theme.primaryColor, size: 24),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (badgeColor ?? Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (badgeColor ?? Colors.orange).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  badge is int ? badge.toString() : badge.toString(),
                  style: TextStyle(
                    color: badgeColor ?? Colors.orange[700],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(Icons.chevron_right, color: theme.hintColor),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _getInvitationSubtitle(List<models.FamilyInvitation> invitations) {
    final pendingCount = _getPendingInvitationsCount(invitations);
    if (pendingCount > 0) {
      return '$pendingCount pending invitation${pendingCount != 1 ? 's' : ''}';
    }
    return 'Manage family invitations';
  }

  int _getPendingInvitationsCount(List<models.FamilyInvitation> invitations) {
    return invitations.where((i) => i.isPending && !i.isExpired).length;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }

  Future<void> _showDeleteFamilyDialog(
    models.Family family,
    ThemeData theme,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Family?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${family.name}"?',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. All family data will be lost.',
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final success = await ref
          .read(familyListProvider.notifier)
          .deleteFamily(family.familyId);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Family deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Pop back to family list
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete family'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
