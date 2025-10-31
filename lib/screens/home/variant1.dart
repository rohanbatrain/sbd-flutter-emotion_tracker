import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/screens/settings/variant1.dart';
import 'package:emotion_tracker/screens/shop/variant1/variant1.dart';
import 'package:emotion_tracker/widgets/app_scaffold.dart';
import 'package:emotion_tracker/providers/workspace_provider.dart';
import 'package:emotion_tracker/screens/home/personal_dashboard_screen.dart';
import 'package:emotion_tracker/screens/home/family_dashboard_screen.dart';
import 'package:emotion_tracker/screens/home/team_dashboard_screen.dart';
import 'package:emotion_tracker/screens/ai/ai_chat_screen.dart';

class HomeScreenV1 extends ConsumerStatefulWidget {
  const HomeScreenV1({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreenV1> createState() => _HomeScreenV1State();
}

class _HomeScreenV1State extends ConsumerState<HomeScreenV1> {
  void _onItemSelected(String item) {
    Navigator.of(context).pop(); // Close drawer
    if (item == 'settings') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SettingsScreenV1()));
    } else if (item == 'shop') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ShopScreenV1()));
    } else if (item == 'ai_chat') {
      Navigator.of(context).pushNamed('/ai/chat');
    } else if (item == 'dashboard') {
      // Instead of popping to root, push dashboard if not already on it
      final isDashboard = ModalRoute.of(context)?.settings.name == 'dashboard';
      if (!isDashboard) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const HomeScreenV1(),
            settings: const RouteSettings(name: 'dashboard'),
          ),
        );
      }
      // If already on dashboard, just close the drawer
    }
  }

  Future<bool> _onWillPop() async {
    return (await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App?'),
            content: const Text('Are you sure you want to quit?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final currentWorkspace = ref.watch(currentWorkspaceProvider);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: AppScaffold(
        title: _getTitleForWorkspace(currentWorkspace),
        selectedItem: 'dashboard',
        onItemSelected: _onItemSelected,
        body: _getBodyForWorkspace(currentWorkspace),
      ),
    );
  }

  String _getTitleForWorkspace(Workspace workspace) {
    switch (workspace.type) {
      case WorkspaceType.personal:
        return 'Emotion Tracker';
      case WorkspaceType.family:
        return workspace.name;
      case WorkspaceType.team:
        return workspace.name;
    }
  }

  Widget _getBodyForWorkspace(Workspace workspace) {
    switch (workspace.type) {
      case WorkspaceType.personal:
        return const PersonalDashboardScreen();
      case WorkspaceType.family:
        return const FamilyDashboardScreen();
      case WorkspaceType.team:
        return const TeamDashboardScreen();
    }
  }
}
