import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'package:emotion_tracker/widgets/sidebar_widget.dart';
import 'package:emotion_tracker/screens/settings/variant1.dart';

class HomeScreenV1 extends ConsumerStatefulWidget {
  const HomeScreenV1({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreenV1> createState() => _HomeScreenV1State();
}

class _HomeScreenV1State extends ConsumerState<HomeScreenV1> {
  String selectedItem = 'dashboard';

  void _onItemSelected(String item) {
    setState(() {
      selectedItem = item;
    });
    Navigator.of(context).pop(); // Close drawer
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    
    return Scaffold(
      appBar: const CustomAppBar(title: 'Emotion Tracker'),
      drawer: SidebarWidget(
        selectedItem: selectedItem,
        onItemSelected: _onItemSelected,
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    switch (selectedItem) {
      case 'settings':
        return const SettingsScreenV1();
      case 'shop':
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_rounded,
                size: 64,
                color: theme.primaryColor,
              ),
              SizedBox(height: 16),
              Text(
                'Shop Coming Soon!',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case 'dashboard':
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.dashboard_rounded,
                size: 64,
                color: theme.primaryColor,
              ),
              SizedBox(height: 16),
              Text(
                'Welcome to Dashboard',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Your emotion tracking starts here!',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
        );
    }
  }
}