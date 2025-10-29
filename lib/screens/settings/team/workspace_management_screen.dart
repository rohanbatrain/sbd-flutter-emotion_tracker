import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/widgets/app_scaffold.dart';
import 'package:emotion_tracker/models/team/team_models.dart';
import 'package:emotion_tracker/providers/team/team_providers.dart';

class WorkspaceManagementScreen extends ConsumerWidget {
  final TeamWorkspace workspace;

  const WorkspaceManagementScreen({Key? key, required this.workspace})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return AppScaffold(
      title: workspace.name,
      selectedItem: 'settings',
      onItemSelected: _onItemSelected,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showInviteMemberDialog(context, ref),
        backgroundColor: theme.primaryColor,
        elevation: 6,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Workspace Info Card
          Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor.withOpacity(0.1),
                    theme.primaryColor.withOpacity(0.05),
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
                          color: theme.primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.business,
                          color: theme.primaryColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workspace.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                            if (workspace.description != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  workspace.description!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
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
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
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
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildInfoChip(
                        context,
                        icon: Icons.people,
                        label:
                            '${workspace.members.length} member${workspace.members.length != 1 ? 's' : ''}',
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _buildInfoChip(
                        context,
                        icon: Icons.calendar_today,
                        label:
                            'Created ${workspace.createdAt.toString().split(' ')[0]}',
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 12),
                      _buildInfoChip(
                        context,
                        icon: Icons.workspace_premium,
                        label: workspace.settings.allowMemberInvites
                            ? 'Open Invites'
                            : 'Closed Invites',
                        color: workspace.settings.allowMemberInvites
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Team Members Section
          Padding(
            padding: const EdgeInsets.only(left: 4.0, top: 10, bottom: 10),
            child: Row(
              children: [
                Text(
                  'Team Members',
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
                    '${workspace.members.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Add Member
          Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _showInviteMemberDialog(context, ref),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.person_add,
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
                            'Invite Team Member',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add new members to collaborate',
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
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Members List
          ...workspace.members.map(
            (member) => Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: _getRoleColor(
                            member.role,
                          ).withOpacity(0.2),
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
                                          .userId, // TODO: Replace with actual user name when available
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 18,
                                          ),
                                    ),
                                  ),
                                  if (member.userId == workspace.ownerId)
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
                                  color: _getRoleColor(
                                    member.role,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getRoleColor(
                                      member.role,
                                    ).withOpacity(0.3),
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
                        if (member.userId != workspace.ownerId)
                          PopupMenuButton<String>(
                            onSelected: (action) => _handleMemberAction(
                              context,
                              ref,
                              member,
                              action,
                            ),
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
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: theme.hintColor,
                        ),
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
            ),
          ),

          const SizedBox(height: 28),

          // Workspace Settings Section
          Padding(
            padding: const EdgeInsets.only(left: 4.0, top: 10, bottom: 10),
            child: Text(
              'Workspace Settings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
                letterSpacing: 0.8,
                fontSize: 22,
              ),
            ),
          ),

          // Workspace Settings
          Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'Allow Member Invites',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Let team members invite others to the workspace',
                  ),
                  value: workspace.settings.allowMemberInvites,
                  onChanged: (value) => _updateWorkspaceSettings(context, ref, {
                    'allow_member_invites': value,
                  }),
                ),
                const Divider(),
                ListTile(
                  title: Text(
                    'Default New Member Role',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    workspace.settings.defaultNewMemberRole.displayName,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showRoleSelectionDialog(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Danger Zone
          Padding(
            padding: const EdgeInsets.only(left: 4.0, top: 10, bottom: 10),
            child: Text(
              'Danger Zone',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                letterSpacing: 0.8,
                fontSize: 22,
              ),
            ),
          ),

          Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
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

  void _showInviteMemberDialog(BuildContext context, WidgetRef ref) {
    final userIdController = TextEditingController();
    WorkspaceRole selectedRole = workspace.settings.defaultNewMemberRole;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Invite Team Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userIdController,
                decoration: const InputDecoration(
                  labelText: 'User ID',
                  hintText: 'Enter user ID to invite',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<WorkspaceRole>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: WorkspaceRole.values
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(role.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedRole = value);
                  }
                },
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
                      final userId = userIdController.text.trim();

                      if (userId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a user ID'),
                          ),
                        );
                        return;
                      }

                      setState(() => isLoading = true);
                      try {
                        await ref
                            .read(teamWorkspacesProvider.notifier)
                            .addMember(
                              workspace.workspaceId,
                              userId,
                              selectedRole,
                            );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Member invited successfully'),
                          ),
                        );
                      } catch (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to invite member: $error'),
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
                  : const Text('Invite'),
            ),
          ],
        ),
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
            items: WorkspaceRole.values
                .map(
                  (role) => DropdownMenuItem(
                    value: role,
                    child: Text(role.displayName),
                  ),
                )
                .toList(),
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
                        workspace.workspaceId,
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
                    .removeMember(workspace.workspaceId, member.userId);
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

  Future<void> _updateWorkspaceSettings(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> settings,
  ) async {
    try {
      await ref
          .read(teamWorkspacesProvider.notifier)
          .updateWorkspace(workspace.workspaceId, settings: settings);
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
    WorkspaceRole selectedRole = workspace.settings.defaultNewMemberRole;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Default New Member Role'),
          content: DropdownButtonFormField<WorkspaceRole>(
            value: selectedRole,
            items: WorkspaceRole.values
                .map(
                  (role) => DropdownMenuItem(
                    value: role,
                    child: Text(role.displayName),
                  ),
                )
                .toList(),
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
                    .deleteWorkspace(workspace.workspaceId);
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

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);

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
}
