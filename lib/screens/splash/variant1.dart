import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'package:emotion_tracker/providers/theme_provider.dart';

class SplashScreenV1 extends ConsumerStatefulWidget {
  const SplashScreenV1({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreenV1> createState() => _SplashScreenV1State();
}

class _SplashScreenV1State extends ConsumerState<SplashScreenV1> {
  @override
  void initState() {
    super.initState();
    _navigateToAuth();
  }

  _navigateToAuth() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/auth/v1');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/Animation - 1749905705545.json',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 20),
            Text(
              'Emotion Tracker',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Powered by Second Brain Database',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}