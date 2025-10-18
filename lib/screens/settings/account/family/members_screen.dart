import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'package:emotion_tracker/providers/family/family_provider.dart';
import 'package:emotion_tracker/providers/family/family_models.dart' as models;
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';

class MembersScreen extends ConsumerStatefulWidget {
  final String familyId;

  const MembersScreen({Key? key, required this.familyId}) : super(key: key);

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
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
    String relationshipType = 'other';

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
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: identifierType,
                  decoration: InputDecoration(
                    labelText: 'Identifier Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: [
                    DropdownMenuItem(value: 'email', child: Text('Email')),
                    DropdownMenuItem(
                      value: 'username',
                      child: Text('Username'),
                    ),
                  ],
                  onChanged: (value) => setState(() => identifierType = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: relationshipType,
                  decoration: InputDecoration(
                    labelText: 'Relationship',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.family_restroom),
                  ),
                  items: [
                    DropdownMenuItem(value: 'parent', child: Text('Parent')),
                    DropdownMenuItem(value: 'child', child: Text('Child')),
                    DropdownMenuItem(value: 'sibling', child: Text('Sibling')),
                    DropdownMenuItem(value: 'spouse', child: Text('Spouse')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
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

    if (result == true && identifierController.text.trim().isNotEmpty) {
      final success = await ref
          .read(familyDetailsProvider(widget.familyId).notifier)
          .inviteMember(
            identifier: identifierController.text.trim(),
            identifierType: identifierType,
            relationshipType: relationshipType,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showMemberActions(models.FamilyMember member, bool isCurrentUserAdmin) {
    if (!isCurrentUserAdmin) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withOpacity(0.1),
                child: Text(
                  member.displayName[0].toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(member.displayName),
              subtitle: Text(
                '${member.role.toUpperCase()} • ${member.relationshipType}',
              ),
            ),
            Divider(),
            if (member.role == 'member') ...[
              ListTile(
                leading: Icon(Icons.admin_panel_settings, color: Colors.blue),
                title: Text('Promote to Admin'),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await ref
                      .read(familyDetailsProvider(widget.familyId).notifier)
                      .promoteToAdmin(member.userId);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${member.displayName} promoted to admin',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ] else if (member.role == 'admin') ...[
              ListTile(
                leading: Icon(Icons.remove_moderator, color: Colors.orange),
                title: Text('Demote from Admin'),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await ref
                      .read(familyDetailsProvider(widget.familyId).notifier)
                      .demoteFromAdmin(member.userId);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${member.displayName} demoted to member',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
              ),
            ],
            ListTile(
              leading: Icon(Icons.person_remove, color: Colors.red),
              title: Text('Remove from Family'),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Remove Member'),
                    content: Text(
                      'Are you sure you want to remove ${member.displayName} from the family?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Remove'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final success = await ref
                      .read(familyDetailsProvider(widget.familyId).notifier)
                      .removeMember(member.userId);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${member.displayName} removed from family',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel),
              title: Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailsState = ref.watch(familyDetailsProvider(widget.familyId));
    final isAdmin = detailsState.family?.isAdmin ?? false;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Family Members',
        showHamburger: false,
        showCurrency: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showInviteMemberDialog,
              icon: Icon(Icons.person_add),
              label: Text('Invite Member'),
              backgroundColor: theme.primaryColor,
            )
          : null,
      body: detailsState.isLoading
          ? LoadingStateWidget(message: 'Loading members...')
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
              onRefresh: () async {
                await ref
                    .read(familyDetailsProvider(widget.familyId).notifier)
                    .loadFamilyDetails();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: detailsState.members.length,
                itemBuilder: (context, index) {
                  final member = detailsState.members[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                        child: Text(
                          member.displayName[0].toUpperCase(),
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        member.displayName,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${member.role.toUpperCase()} • ${member.relationshipType}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (member.role == 'admin')
                            Chip(
                              label: Text(
                                'ADMIN',
                                style: TextStyle(fontSize: 10),
                              ),
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              labelStyle: TextStyle(
                                color: Colors.blue.shade700,
                              ),
                            ),
                          if (isAdmin) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.more_vert),
                              onPressed: () =>
                                  _showMemberActions(member, isAdmin),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
