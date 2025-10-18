// This file is intentionally small; main Team details placeholder lives in `variant1.dart`.
// Kept for route-friendly structure if you'd rather import a separate details screen later.

import 'package:flutter/material.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';

class TeamDetailsPlaceholder extends StatelessWidget {
  final String teamId;
  const TeamDetailsPlaceholder({Key? key, required this.teamId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Team',
        showHamburger: false,
        showCurrency: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.group,
                size: 96,
                color: theme.primaryColor.withOpacity(0.2),
              ),
              const SizedBox(height: 20),
              Text(
                'Team details placeholder',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This page is a placeholder. Wire it to your Team API/provider to show members, roles and settings.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
