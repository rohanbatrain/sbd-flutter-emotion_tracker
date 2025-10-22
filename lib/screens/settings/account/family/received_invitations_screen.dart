import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/family/received_invitations_provider.dart';
import 'package:emotion_tracker/providers/family/family_models.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';

class ReceivedInvitationsScreen extends ConsumerStatefulWidget {
  const ReceivedInvitationsScreen({super.key});

  @override
  ConsumerState<ReceivedInvitationsScreen> createState() =>
      _ReceivedInvitationsScreenState();
}

class _ReceivedInvitationsScreenState
    extends ConsumerState<ReceivedInvitationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Load invitations when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(receivedInvitationsProvider.notifier).loadInvitations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await ref.read(receivedInvitationsProvider.notifier).refresh();
  }

  Future<void> _respondToInvitation(
    String invitationId,
    String action,
    String familyName,
  ) async {
    final notifier = ref.read(receivedInvitationsProvider.notifier);

    // Show confirmation dialog with different messages for accept vs decline
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action == 'accept' ? 'Accept' : 'Decline'} Invitation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to $action the invitation to join $familyName?',
            ),
            if (action == 'decline') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Note: After declining, they cannot send you another invitation for 24 hours.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'accept' ? Colors.green : Colors.red,
            ),
            child: Text(action == 'accept' ? 'Accept' : 'Decline'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await notifier.respondToInvitation(invitationId, action);

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    // Show result
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Invitation ${action}ed successfully'
              : 'Failed to $action invitation',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(receivedInvitationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Family Invitations',
        showHamburger: false,
        showCurrency: false, // SBD token display disabled
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Show total pending count in app bar
          if (state.pendingInvitations.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${state.pendingInvitations.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Custom tab bar with better styling
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: theme.primaryColor,
              indicatorWeight: 3,
              labelColor: theme.primaryColor,
              unselectedLabelColor: theme.textTheme.bodyMedium?.color
                  ?.withOpacity(0.6),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: [
                _buildTab(
                  'Pending',
                  state.pendingInvitations.length,
                  Icons.pending_actions,
                  Colors.orange,
                ),
                _buildTab(
                  'Accepted',
                  state.acceptedInvitations.length,
                  Icons.check_circle_outline,
                  Colors.green,
                ),
                _buildTab(
                  'Declined',
                  state.declinedInvitations.length,
                  Icons.cancel_outlined,
                  Colors.red,
                ),
                _buildTab(
                  'Expired',
                  state.expiredInvitations.length,
                  Icons.timer_off_outlined,
                  Colors.grey,
                ),
              ],
            ),
          ),
          // Content area
          Expanded(
            child: state.isLoading && state.invitations.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                ? _buildErrorView(state.error!)
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildInvitationsList(
                        state.pendingInvitations,
                        'No pending invitations',
                        'You don\'t have any pending invitations at the moment.',
                        Icons.inbox_outlined,
                        showActions: true,
                      ),
                      _buildInvitationsList(
                        state.acceptedInvitations,
                        'No accepted invitations',
                        'You haven\'t accepted any family invitations yet.',
                        Icons.check_circle_outline,
                      ),
                      _buildInvitationsList(
                        state.declinedInvitations,
                        'No declined invitations',
                        'You haven\'t declined any family invitations.',
                        Icons.cancel_outlined,
                      ),
                      _buildInvitationsList(
                        state.expiredInvitations,
                        'No expired invitations',
                        'No invitations have expired yet.',
                        Icons.timer_off_outlined,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int count, IconData icon, Color color) {
    return Tab(
      height: 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 22),
              if (count > 0)
                Positioned(
                  right: -8,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    // Check if this is the backend not ready error
    final isBackendNotReady = error.contains('BACKEND_NOT_READY');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isBackendNotReady ? Icons.construction : Icons.error_outline,
              size: 64,
              color: isBackendNotReady ? Colors.orange : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              isBackendNotReady
                  ? 'Backend Endpoint Not Ready'
                  : 'Error Loading Invitations',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isBackendNotReady
                  ? 'The received invitations endpoint is not yet available on the backend.'
                  : error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (isBackendNotReady) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Required Backend Endpoint',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'GET /family/my-invitations',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This endpoint should return invitations received by the current authenticated user.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (!isBackendNotReady)
              ElevatedButton.icon(
                onPressed: _handleRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationsList(
    List<ReceivedInvitation> invitations,
    String emptyTitle,
    String emptySubtitle,
    IconData emptyIcon, {
    bool showActions = false,
  }) {
    if (invitations.isEmpty) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(emptyIcon, size: 64, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    emptyTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      emptySubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Pull down to refresh',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: invitations.length,
        itemBuilder: (context, index) {
          final invitation = invitations[index];
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildInvitationCard(
              invitation,
              showActions: showActions,
              key: ValueKey(invitation.invitationId),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInvitationCard(
    ReceivedInvitation invitation, {
    bool showActions = false,
    Key? key,
  }) {
    final theme = Theme.of(context);
    final isExpired = invitation.isExpired;
    final isFamilyNameMissing = invitation.familyName == 'Unknown Family';

    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _getInvitationBorderColor(invitation).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: showActions
            ? null
            : () {
                // Show details dialog for non-pending invitations
                _showInvitationDetailsDialog(invitation);
              },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Family name and status badge
              Row(
                children: [
                  // Family icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getInvitationBorderColor(
                        invitation,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.family_restroom,
                      color: _getInvitationBorderColor(invitation),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invitation.familyName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (isFamilyNameMissing)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 12,
                                  color: Colors.orange[700],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Name unavailable',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.orange[700],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(invitation),
                ],
              ),
              const SizedBox(height: 16),

              // Divider
              Divider(color: Colors.grey[300], height: 1),
              const SizedBox(height: 12),

              // Details section
              _buildDetailRow(
                Icons.person_outline,
                'Invited by',
                invitation.inviterUsername,
                theme,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.badge_outlined,
                'Role',
                _formatRelationship(invitation.relationshipType),
                theme,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                isExpired ? Icons.timer_off : Icons.access_time,
                isExpired ? 'Expired' : 'Expires',
                isExpired
                    ? _formatDate(invitation.expiresAt)
                    : 'in ${invitation.timeUntilExpiry}',
                theme,
                valueColor: isExpired ? Colors.red : null,
              ),

              // Expiring soon warning (show if pending, not expired, and less than 2 days left)
              if (showActions &&
                  !isExpired &&
                  invitation.daysUntilExpiry < 2) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          invitation.daysUntilExpiry == 0
                              ? '⏰ Expires today! Please respond soon.'
                              : '⏰ Expires tomorrow! Please respond soon.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[900],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action buttons for pending invitations
              if (showActions && !isExpired) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _respondToInvitation(
                          invitation.invitationId,
                          'decline',
                          invitation.familyName,
                        ),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        label: const Text(
                          'Decline',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(
                            color: Colors.red.shade300,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _respondToInvitation(
                          invitation.invitationId,
                          'accept',
                          invitation.familyName,
                        ),
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: const Text(
                          'Accept',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: theme.primaryColor),
        ),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Color _getInvitationBorderColor(ReceivedInvitation invitation) {
    if (invitation.isExpired) return Colors.grey;
    if (invitation.isPending) return Colors.orange;
    if (invitation.isAccepted) return Colors.green;
    if (invitation.isDeclined) return Colors.red;
    return Colors.grey;
  }

  void _showInvitationDetailsDialog(ReceivedInvitation invitation) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: theme.primaryColor),
            const SizedBox(width: 8),
            const Expanded(child: Text('Invitation Details')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogDetailRow('Family', invitation.familyName),
            const Divider(),
            _buildDialogDetailRow('Invited by', invitation.inviterUsername),
            const Divider(),
            _buildDialogDetailRow(
              'Role',
              _formatRelationship(invitation.relationshipType),
            ),
            const Divider(),
            _buildDialogDetailRow('Status', invitation.status.toUpperCase()),
            const Divider(),
            _buildDialogDetailRow('Created', _formatDate(invitation.createdAt)),
            const Divider(),
            _buildDialogDetailRow('Expires', _formatDate(invitation.expiresAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ReceivedInvitation invitation) {
    Color backgroundColor;
    Color textColor = Colors.white;
    IconData icon;
    String label;

    if (invitation.isExpired) {
      backgroundColor = Colors.grey;
      icon = Icons.timer_off;
      label = 'Expired';
    } else if (invitation.isPending) {
      backgroundColor = Colors.orange;
      icon = Icons.pending;
      label = 'Pending';
    } else if (invitation.isAccepted) {
      backgroundColor = Colors.green;
      icon = Icons.check_circle;
      label = 'Accepted';
    } else if (invitation.isDeclined) {
      backgroundColor = Colors.red;
      icon = Icons.cancel;
      label = 'Declined';
    } else {
      backgroundColor = Colors.grey;
      icon = Icons.help_outline;
      label = invitation.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelationship(String relationship) {
    return relationship[0].toUpperCase() + relationship.substring(1);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
