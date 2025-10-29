import 'package:emotion_tracker/providers/workspace_provider.dart';
import 'package:emotion_tracker/providers/family/family_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkspaceSwitcher extends ConsumerWidget {
  const WorkspaceSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentWorkspace = ref.watch(currentWorkspaceProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showWorkspaceSwitcherDialog(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  _getWorkspaceIcon(currentWorkspace.type),
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    currentWorkspace.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getWorkspaceIcon(WorkspaceType type) {
    switch (type) {
      case WorkspaceType.personal:
        return Icons.person_rounded;
      case WorkspaceType.family:
        return Icons.family_restroom_rounded;
      case WorkspaceType.team:
        return Icons.groups_rounded;
    }
  }

  void _showWorkspaceSwitcherDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const WorkspaceSwitcherDialog(),
    );
  }
}

class WorkspaceSwitcherDialog extends ConsumerWidget {
  const WorkspaceSwitcherDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentWorkspace = ref.watch(currentWorkspaceProvider);
    final families = ref.watch(familyWorkspacesProvider);
    final teams = ref.watch(teamWorkspacesProvider);
    final familyListState = ref.watch(familyListProvider);

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Switch Workspace',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a workspace to continue',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Workspace options
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal workspace
                    _buildWorkspaceOption(
                      context,
                      workspace: const Workspace(
                        type: WorkspaceType.personal,
                        id: 'personal',
                        name: 'Personal',
                        description: 'Your personal workspace',
                      ),
                      isSelected:
                          currentWorkspace.type == WorkspaceType.personal,
                      onTap: () =>
                          _switchWorkspace(context, ref, Workspace.personal),
                    ),
                    const SizedBox(height: 16),

                    // Families section
                    if (families.isNotEmpty) ...[
                      _buildSectionHeader(
                        context,
                        'Families',
                        Icons.family_restroom_rounded,
                      ),
                      const SizedBox(height: 8),
                      ...families.map(
                        (family) => _buildWorkspaceOption(
                          context,
                          workspace: family,
                          isSelected: currentWorkspace.id == family.id,
                          onTap: () => _switchWorkspace(context, ref, family),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Teams section
                    if (teams.isNotEmpty) ...[
                      _buildSectionHeader(
                        context,
                        'Teams',
                        Icons.groups_rounded,
                      ),
                      const SizedBox(height: 8),
                      ...teams.map(
                        (team) => _buildWorkspaceOption(
                          context,
                          workspace: team,
                          isSelected: currentWorkspace.id == team.id,
                          onTap: () => _switchWorkspace(context, ref, team),
                        ),
                      ),
                    ],

                    // Empty states
                    if (families.isEmpty && teams.isEmpty) ...[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.workspace_premium_rounded,
                                size: 48,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No additional workspaces',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create a family or join a team to see more workspaces',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons: Refresh + Close
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Refresh button shows a spinner when families are loading
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: familyListState.isLoading
                      ? SizedBox(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : TextButton(
                          onPressed: () async {
                            // Trigger a reload of families which will populate workspaces
                            await ref
                                .read(familyListProvider.notifier)
                                .loadFamilies();
                          },
                          child: Text(
                            'Refresh',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                ),

                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkspaceOption(
    BuildContext context, {
    required Workspace workspace,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Icon(
                    _getWorkspaceIcon(workspace.type),
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workspace.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (workspace.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          workspace.description!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.check_circle_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getWorkspaceIcon(WorkspaceType type) {
    switch (type) {
      case WorkspaceType.personal:
        return Icons.person_rounded;
      case WorkspaceType.family:
        return Icons.family_restroom_rounded;
      case WorkspaceType.team:
        return Icons.groups_rounded;
    }
  }

  void _switchWorkspace(
    BuildContext context,
    WidgetRef ref,
    Workspace workspace,
  ) {
    ref.read(workspaceProvider.notifier).switchWorkspace(workspace);
    Navigator.of(context).pop();
    // TODO: Handle navigation/app state changes based on workspace switch
  }
}
