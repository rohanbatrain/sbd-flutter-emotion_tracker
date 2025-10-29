import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/workspace_provider.dart';

class DashboardScreenV1 extends ConsumerWidget {
  final Workspace? workspaceContext;

  const DashboardScreenV1({super.key, this.workspaceContext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    final Workspace workspace =
        workspaceContext ?? ref.watch(currentWorkspaceProvider);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getWorkspaceIcon(workspace.type),
            size: 64,
            color: theme.primaryColor,
          ),
          SizedBox(height: 16),
          Text(
            _getWelcomeMessage(workspace),
            style: theme.textTheme.headlineLarge?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            _getSubtitleMessage(workspace),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.secondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (workspace.type != WorkspaceType.personal) ...[
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.5,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Workspace: ${workspace.name}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getWorkspaceIcon(WorkspaceType type) {
    switch (type) {
      case WorkspaceType.personal:
        return Icons.dashboard_rounded;
      case WorkspaceType.family:
        return Icons.family_restroom_rounded;
      case WorkspaceType.team:
        return Icons.groups_rounded;
    }
  }

  String _getWelcomeMessage(Workspace workspace) {
    switch (workspace.type) {
      case WorkspaceType.personal:
        return 'Welcome to Dashboard';
      case WorkspaceType.family:
        return 'Welcome to ${workspace.name}';
      case WorkspaceType.team:
        return 'Welcome to ${workspace.name}';
    }
  }

  String _getSubtitleMessage(Workspace workspace) {
    switch (workspace.type) {
      case WorkspaceType.personal:
        return 'Your emotion tracking starts here!';
      case WorkspaceType.family:
        return 'Family emotion tracking and collaboration';
      case WorkspaceType.team:
        return 'Team emotion tracking and collaboration';
    }
  }
}
