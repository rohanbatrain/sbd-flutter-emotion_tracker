import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/team/team_providers.dart';
import 'package:emotion_tracker/screens/settings/team/workspace_overview_screen.dart';

class TeamScreenV1 extends ConsumerStatefulWidget {
  const TeamScreenV1({Key? key}) : super(key: key);

  @override
  ConsumerState<TeamScreenV1> createState() => _TeamScreenV1State();
}

class _TeamScreenV1State extends ConsumerState<TeamScreenV1> {
  @override
  void initState() {
    super.initState();
    // Load fresh workspaces on screen appear
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teamWorkspacesProvider.notifier).loadWorkspaces();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Return a plain scaffold without the top app bar or tabs.
    return Scaffold(body: WorkspaceOverviewScreen());
  }
}
