import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/screens/settings/variant1.dart';
import 'package:emotion_tracker/screens/shop/variant1/variant1.dart';
import 'package:emotion_tracker/screens/home/dashboard_screen_v1.dart';
import 'package:emotion_tracker/widgets/app_scaffold.dart';

class HomeScreenV1 extends ConsumerStatefulWidget {
  const HomeScreenV1({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreenV1> createState() => _HomeScreenV1State();
}

class _HomeScreenV1State extends ConsumerState<HomeScreenV1> {
  void _onItemSelected(String item) {
    Navigator.of(context).pop(); // Close drawer
    if (item == 'settings') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SettingsScreenV1()),
      );
    } else if (item == 'shop') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ShopScreenV1()),
      );
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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: AppScaffold(
        title: 'Emotion Tracker',
        selectedItem: 'dashboard',
        onItemSelected: _onItemSelected,
        body: const DashboardScreenV1(),
      ),
    );
  }
}