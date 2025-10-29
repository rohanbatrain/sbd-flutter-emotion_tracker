import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/models/team/team_models.dart';
import 'package:emotion_tracker/providers/team/team_providers.dart';
import 'package:emotion_tracker/widgets/sidebar_widget.dart';
import 'package:emotion_tracker/screens/settings/team/workspace_management_screen.dart';

enum WorkspaceSortOption {
  name('Name'),
  createdDate('Created Date'),
  memberCount('Member Count'),
  lastActivity('Last Activity');

  const WorkspaceSortOption(this.displayName);
  final String displayName;
}

enum WorkspaceFilterOption {
  all('All Workspaces'),
  active('Active Only'),
  myWorkspaces('My Workspaces'),
  withWallets('With Wallets');

  const WorkspaceFilterOption(this.displayName);
  final String displayName;
}

class WorkspaceListScreen extends ConsumerStatefulWidget {
  const WorkspaceListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WorkspaceListScreen> createState() =>
      _WorkspaceListScreenState();
}

class _WorkspaceListScreenState extends ConsumerState<WorkspaceListScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  WorkspaceSortOption _sortOption = WorkspaceSortOption.name;
  WorkspaceFilterOption _filterOption = WorkspaceFilterOption.all;
  bool _sortAscending = true;
  bool _isSearchMode = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workspacesAsync = ref.watch(teamWorkspacesProvider);
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
        title: const Text('Workspaces'),
        elevation: 0,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showCreateWorkspaceDialog(context, ref),
            icon: const Icon(Icons.add),
            tooltip: 'Create Workspace',
          ),
        ],
      ),
      drawer: SidebarWidget(
        selectedItem: 'settings',
        onItemSelected: _onItemSelected,
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => _showCreateWorkspaceDialog(context, ref),
          backgroundColor: theme.primaryColor,
          elevation: 6,
          icon: const Icon(Icons.add_business, color: Colors.white),
          label: const Text(
            'Create Workspace',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: workspacesAsync.when(
        data: (workspaces) =>
            _buildWorkspaceList(context, ref, workspaces, theme),
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

  Widget _buildWorkspaceList(
    BuildContext context,
    WidgetRef ref,
    List<TeamWorkspace> workspaces,
    ThemeData theme,
  ) {
    final filteredWorkspaces = _filterAndSortWorkspaces(workspaces);

    return Column(
      children: [
        // Search and Filter Bar
        _buildSearchAndFilterBar(
          context,
          theme,
          workspaces.length,
          filteredWorkspaces.length,
        ),

        // Workspace Grid/List
        Expanded(
          child: filteredWorkspaces.isEmpty
              ? _buildEmptyState(context, theme)
              : _buildWorkspaceGrid(context, ref, filteredWorkspaces, theme),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterBar(
    BuildContext context,
    ThemeData theme,
    int totalCount,
    int filteredCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isSearchMode ? 56 : 0,
            child: _isSearchMode
                ? Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.inputDecorationTheme.fillColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor, width: 1),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search workspaces...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Controls Row
          Row(
            children: [
              // Search Toggle
              IconButton(
                onPressed: () => setState(() => _isSearchMode = !_isSearchMode),
                icon: Icon(_isSearchMode ? Icons.search_off : Icons.search),
                tooltip: _isSearchMode ? 'Hide search' : 'Show search',
              ),

              // Filter Dropdown
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: DropdownButtonFormField<WorkspaceFilterOption>(
                    value: _filterOption,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      filled: true,
                      fillColor: theme.inputDecorationTheme.fillColor,
                    ),
                    items: WorkspaceFilterOption.values.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _filterOption = value);
                      }
                    },
                  ),
                ),
              ),

              // Sort Button
              IconButton(
                onPressed: () => _showSortDialog(context),
                icon: const Icon(Icons.sort),
                tooltip: 'Sort options',
              ),
            ],
          ),

          // Results Count
          if (filteredCount != totalCount)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Showing $filteredCount of $totalCount workspaces',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.business,
                size: 64,
                color: theme.primaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No workspaces found',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptyStateMessage(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showCreateWorkspaceDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Workspace'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkspaceGrid(
    BuildContext context,
    WidgetRef ref,
    List<TeamWorkspace> workspaces,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: workspaces.length,
        itemBuilder: (context, index) {
          final workspace = workspaces[index];
          return _buildWorkspaceCard(context, ref, workspace, theme);
        },
      ),
    );
  }

  Widget _buildWorkspaceCard(
    BuildContext context,
    WidgetRef ref,
    TeamWorkspace workspace,
    ThemeData theme,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WorkspaceManagementScreen(workspace: workspace),
          ),
        ),
        onLongPress: () => _showWorkspaceOptions(context, ref, workspace),
        child: Container(
          padding: const EdgeInsets.all(16),
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
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.business,
                      color: theme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (action) =>
                        _handleWorkspaceAction(context, ref, workspace, action),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit Workspace'),
                      ),
                      const PopupMenuItem(
                        value: 'members',
                        child: Text('Manage Members'),
                      ),
                      const PopupMenuItem(
                        value: 'wallet',
                        child: Text('View Wallet'),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Workspace'),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Title
              Text(
                workspace.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Description
              if (workspace.description != null)
                Text(
                  workspace.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const Spacer(),

              // Stats
              Row(
                children: [
                  _buildStatChip(
                    context,
                    theme,
                    icon: Icons.people,
                    label: '${workspace.members.length}',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    context,
                    theme,
                    icon: workspace.settings.allowMemberInvites
                        ? Icons.lock_open
                        : Icons.lock,
                    label: workspace.settings.allowMemberInvites
                        ? 'Open'
                        : 'Closed',
                    color: workspace.settings.allowMemberInvites
                        ? Colors.green
                        : Colors.orange,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Created Date
              Text(
                'Created ${workspace.createdAt.toString().split(' ')[0]}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  List<TeamWorkspace> _filterAndSortWorkspaces(List<TeamWorkspace> workspaces) {
    // Filter
    List<TeamWorkspace> filtered = workspaces.where((workspace) {
      switch (_filterOption) {
        case WorkspaceFilterOption.all:
          return true;
        case WorkspaceFilterOption.active:
          return workspace.members.isNotEmpty;
        case WorkspaceFilterOption.myWorkspaces:
          // TODO: Filter by user's workspaces
          return true;
        case WorkspaceFilterOption.withWallets:
          // TODO: Filter by workspaces with wallets
          return true;
      }
    }).toList();

    // Search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((workspace) {
        return workspace.name.toLowerCase().contains(query) ||
            (workspace.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Sort
    filtered.sort((a, b) {
      int comparison;
      switch (_sortOption) {
        case WorkspaceSortOption.name:
          comparison = a.name.compareTo(b.name);
          break;
        case WorkspaceSortOption.createdDate:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case WorkspaceSortOption.memberCount:
          comparison = a.members.length.compareTo(b.members.length);
          break;
        case WorkspaceSortOption.lastActivity:
          // TODO: Implement last activity sorting
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  String _getEmptyStateMessage() {
    switch (_filterOption) {
      case WorkspaceFilterOption.all:
        return _searchController.text.isNotEmpty
            ? 'No workspaces match your search.'
            : 'You haven\'t created any workspaces yet.';
      case WorkspaceFilterOption.active:
        return 'No active workspaces found.';
      case WorkspaceFilterOption.myWorkspaces:
        return 'You don\'t have any workspaces.';
      case WorkspaceFilterOption.withWallets:
        return 'No workspaces with wallets found.';
    }
  }

  void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Sort Workspaces'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...WorkspaceSortOption.values.map((option) {
                return RadioListTile<WorkspaceSortOption>(
                  title: Text(option.displayName),
                  value: option,
                  groupValue: _sortOption,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sortOption = value);
                    }
                  },
                );
              }),
              const Divider(),
              SwitchListTile(
                title: const Text('Ascending'),
                value: _sortAscending,
                onChanged: (value) => setState(() => _sortAscending = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWorkspaceOptions(
    BuildContext context,
    WidgetRef ref,
    TeamWorkspace workspace,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              workspace.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildOptionTile(
              context,
              icon: Icons.edit,
              title: 'Edit Workspace',
              onTap: () {
                Navigator.pop(context);
                _showEditWorkspaceDialog(context, ref, workspace);
              },
            ),
            _buildOptionTile(
              context,
              icon: Icons.people,
              title: 'Manage Members',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        WorkspaceManagementScreen(workspace: workspace),
                  ),
                );
              },
            ),
            _buildOptionTile(
              context,
              icon: Icons.account_balance_wallet,
              title: 'View Wallet',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to wallet screen
              },
            ),
            const Divider(),
            _buildOptionTile(
              context,
              icon: Icons.delete,
              title: 'Delete Workspace',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showDeleteWorkspaceDialog(context, ref, workspace);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: color ?? theme.primaryColor),
      title: Text(title, style: TextStyle(color: color ?? theme.primaryColor)),
      onTap: onTap,
    );
  }

  void _handleWorkspaceAction(
    BuildContext context,
    WidgetRef ref,
    TeamWorkspace workspace,
    String action,
  ) {
    switch (action) {
      case 'edit':
        _showEditWorkspaceDialog(context, ref, workspace);
        break;
      case 'members':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WorkspaceManagementScreen(workspace: workspace),
          ),
        );
        break;
      case 'wallet':
        // TODO: Navigate to wallet screen
        break;
      case 'delete':
        _showDeleteWorkspaceDialog(context, ref, workspace);
        break;
    }
  }

  void _showCreateWorkspaceDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    bool allowInvites = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Workspace'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Workspace Name',
                  hintText: 'Enter workspace name',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Describe your workspace',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Allow Member Invites'),
                subtitle: const Text('Let members invite others'),
                value: allowInvites,
                onChanged: (value) => setState(() => allowInvites = value),
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
                      .createWorkspace(
                        name,
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                      );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Workspace created successfully'),
                    ),
                  );
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to create workspace: $error'),
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditWorkspaceDialog(
    BuildContext context,
    WidgetRef ref,
    TeamWorkspace workspace,
  ) {
    final nameController = TextEditingController(text: workspace.name);
    final descriptionController = TextEditingController(
      text: workspace.description ?? '',
    );
    bool allowInvites = workspace.settings.allowMemberInvites;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Workspace'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Workspace Name',
                  hintText: 'Enter workspace name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Describe your workspace',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Allow Member Invites'),
                subtitle: const Text('Let members invite others'),
                value: allowInvites,
                onChanged: (value) => setState(() => allowInvites = value),
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
                        workspace.workspaceId,
                        name: name,
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                        settings: {'allow_member_invites': allowInvites},
                      );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Workspace updated successfully'),
                    ),
                  );
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update workspace: $error'),
                    ),
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

  void _showDeleteWorkspaceDialog(
    BuildContext context,
    WidgetRef ref,
    TeamWorkspace workspace,
  ) {
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workspace'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to delete "${workspace.name}"? This action cannot be undone.',
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
                Navigator.of(context).pop(); // Close dialog
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
}
