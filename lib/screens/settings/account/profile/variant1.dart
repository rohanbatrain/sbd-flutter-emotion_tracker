import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';

class ProfileScreenV1 extends ConsumerWidget {
  const ProfileScreenV1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    // Dummy profile data for demonstration
    final userName = 'John Doe';
    final userEmail = 'john.doe@email.com';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: theme.primaryColor.withOpacity(0.15),
              child: Icon(Icons.person, size: 54, color: theme.primaryColor),
            ),
            const SizedBox(height: 24),
            Text(userName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(userEmail, style: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor)),
            const SizedBox(height: 32),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Icon(Icons.email, color: theme.primaryColor),
                title: Text('Email'),
                subtitle: Text(userEmail),
              ),
            ),
            // Add more profile info here as needed
          ],
        ),
      ),
    );
  }
}
