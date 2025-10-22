import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'package:emotion_tracker/providers/family/family_provider.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';

class InvitationsScreen extends ConsumerStatefulWidget {
  final String familyId;

  const InvitationsScreen({Key? key, required this.familyId}) : super(key: key);

  @override
  ConsumerState<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends ConsumerState<InvitationsScreen> {
  // bool _showDegraded = false; // Commented out - showing all invitations for now
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(familyDetailsProvider(widget.familyId).notifier)
          .loadFamilyDetails();
    });
  }

  Future<void> _showInviteMemberDialog() async {
    final theme = Theme.of(context);
    final identifierController = TextEditingController();
    String identifierType = 'email';
    String relationshipType = 'parent';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Invite Family Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: identifierController,
                  decoration: InputDecoration(
                    labelText: 'Email or Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: identifierType,
                  decoration: InputDecoration(
                    labelText: 'Identifier Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ['email', 'username']
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => identifierType = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: relationshipType,
                  decoration: InputDecoration(
                    labelText: 'Relationship',
                    border: OutlineInputBorder(),
                  ),
                  items: ['parent', 'child', 'sibling', 'spouse']
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            type[0].toUpperCase() + type.substring(1),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => relationshipType = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Send Invitation'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final success = await ref
          .read(familyDetailsProvider(widget.familyId).notifier)
          .inviteMember(
            identifier: identifierController.text.trim(),
            identifierType: identifierType,
            relationshipType: relationshipType,
          );

      if (success && mounted) {
        // Reload to sync with backend (backend validation may filter invitations)
        await _refreshInvitations();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _refreshInvitations() async {
    await ref
        .read(familyDetailsProvider(widget.familyId).notifier)
        .loadFamilyDetails();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailsState = ref.watch(familyDetailsProvider(widget.familyId));
    // Filter out degraded invitations unless the user toggles to show them
    // Commented out for now - showing all invitations
    // final visibleInvitations = detailsState.invitations.where((invitation) {
    //   if (_showDegraded) return true;
    //   return !_isDegraded(invitation);
    // }).toList();
    final visibleInvitations = detailsState.invitations; // Show all invitations

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Family Invitations',
        showHamburger: false,
        showCurrency: false, // SBD token display disabled
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInviteMemberDialog,
        icon: Icon(Icons.person_add),
        label: Text('Invite Member'),
        backgroundColor: theme.primaryColor,
      ),
      body: detailsState.isLoading
          ? LoadingStateWidget(message: 'Loading invitations...')
          : detailsState.error != null
          ? ErrorStateWidget(
              error: detailsState.error,
              onRetry: () {
                ref
                    .read(familyDetailsProvider(widget.familyId).notifier)
                    .loadFamilyDetails();
              },
            )
          : RefreshIndicator(
              onRefresh: _refreshInvitations,
              child: Column(
                children: [
                  // Centered toggle for showing degraded invitations
                  // Commented out - showing all invitations by default for now
                  // Padding(
                  //   padding: const EdgeInsets.all(16.0),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.center,
                  //     children: [
                  //       Text(
                  //         'Show degraded invitations',
                  //         style: theme.textTheme.bodyMedium,
                  //       ),
                  //       const SizedBox(width: 8),
                  //       Switch(
                  //         value: _showDegraded,
                  //         activeColor: theme.primaryColor,
                  //         onChanged: (v) => setState(() => _showDegraded = v),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // Content area
                  Expanded(
                    child: visibleInvitations.isEmpty
                        ? SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height - 250,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.mail_outline,
                                      size: 80,
                                      color: theme.hintColor,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No invitations',
                                      style: theme.textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap the button below to invite a member',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Pull down to refresh',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: theme.hintColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            physics: AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.all(16),
                            itemCount: visibleInvitations.length,
                            itemBuilder: (context, index) {
                              final invitation = visibleInvitations[index];
                              return Card(
                                margin: EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  invitation.inviteeEmail ??
                                                      invitation
                                                          .inviteeUsername ??
                                                      'Unknown Recipient',
                                                  style: theme
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                                if (invitation.familyName ==
                                                    'Unknown Family')
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 4,
                                                        ),
                                                    child: Text(
                                                      '⚠️ Family name not available',
                                                      style: theme
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color:
                                                                Colors.orange,
                                                            fontSize: 11,
                                                          ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          _buildStatusChip(
                                            invitation.status,
                                            invitation.isExpired,
                                            theme,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Family: ${invitation.familyName}'),
                                      Text(
                                        'Relationship: ${invitation.relationshipType}',
                                      ),
                                      Text(
                                        'Invited by: ${invitation.invitedByUsername}',
                                      ),
                                      Text(
                                        'Expires: ${_formatDate(invitation.expiresAt)}',
                                      ),
                                      if (invitation.isPending &&
                                          !invitation.isExpired) ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () async {
                                                final success = await ref
                                                    .read(
                                                      familyDetailsProvider(
                                                        widget.familyId,
                                                      ).notifier,
                                                    )
                                                    .cancelInvitation(
                                                      invitation.invitationId,
                                                    );
                                                if (success && mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Invitation cancelled',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: Text('Cancel'),
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
                  ),
                ],
              ),
            ),
    );
  }

  // Helper to determine whether an invitation is degraded/corrupted and
  // should be hidden by default. Criteria (conservative): missing both
  // email and username, missing invitedByUsername, missing familyName,
  // or clearly expired with no chance of interaction. Adjust as needed.
  // Commented out for now - showing all invitations
  // bool _isDegraded(invitation) {
  //   try {
  //     final hasRecipient =
  //         (invitation.inviteeEmail != null &&
  //             invitation.inviteeEmail!.isNotEmpty) ||
  //         (invitation.inviteeUsername != null &&
  //             invitation.inviteeUsername!.isNotEmpty);
  //     final hasInviter =
  //         invitation.invitedByUsername != null &&
  //         invitation.invitedByUsername!.isNotEmpty &&
  //         invitation.invitedByUsername != 'Unknown';
  //     final hasFamily =
  //         invitation.familyName != null &&
  //         invitation.familyName!.isNotEmpty &&
  //         invitation.familyName != 'Unknown Family';
  //
  //     // If there's no recipient or no inviter and family name is unknown,
  //     // treat as degraded. Also treat as degraded if it's expired and
  //     // flagged as non-actionable (isExpired true and status not pending).
  //     if (!hasRecipient) return true;
  //     if (!hasInviter && !hasFamily) return true;
  //     if (invitation.isExpired && invitation.status != 'pending') return true;
  //
  //     return false;
  //   } catch (_) {
  //     // On unexpected structure treat as degraded.
  //     return true;
  //   }
  // }

  Widget _buildStatusChip(String status, bool isExpired, ThemeData theme) {
    Color backgroundColor;
    Color textColor;
    String text;

    if (isExpired) {
      backgroundColor = Colors.grey.withOpacity(0.1);
      textColor = Colors.grey.shade700;
      text = 'EXPIRED';
    } else {
      switch (status) {
        case 'accepted':
          backgroundColor = Colors.green.withOpacity(0.1);
          textColor = Colors.green.shade700;
          text = 'ACCEPTED';
          break;
        case 'declined':
          backgroundColor = Colors.red.withOpacity(0.1);
          textColor = Colors.red.shade700;
          text = 'DECLINED';
          break;
        default:
          backgroundColor = Colors.orange.withOpacity(0.1);
          textColor = Colors.orange.shade700;
          text = 'PENDING';
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
