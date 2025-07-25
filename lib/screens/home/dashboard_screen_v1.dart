import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';

class DashboardScreenV1 extends ConsumerWidget {
  const DashboardScreenV1({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dashboard_rounded, size: 64, color: theme.primaryColor),
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
