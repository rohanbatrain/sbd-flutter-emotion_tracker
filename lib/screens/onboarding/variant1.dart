import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';

class OnboardingScreenV1 extends ConsumerWidget {
  const OnboardingScreenV1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_emotions, color: theme.primaryColor, size: 48),
                  const SizedBox(height: 18),
                  Text(
                    "Welcome!",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "We see you're new to our ecosystem — would you like to set up your profile to get the most personalized experience?",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed('/profile-setup/v1');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Yes, set up now'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed('/home/v1');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.primaryColor,
                            side: BorderSide(color: theme.primaryColor, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text("I'll build it later"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
