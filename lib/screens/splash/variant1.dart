import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/app_providers.dart';

class SplashScreenV1 extends ConsumerStatefulWidget {
  const SplashScreenV1({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreenV1> createState() => _SplashScreenV1State();
}

class _SplashScreenV1State extends ConsumerState<SplashScreenV1> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  _checkAuthAndNavigate() async {
    final startTime = DateTime.now();
    const minSplashDuration = Duration(seconds: 2);
    
    // Wait for auth initialization to complete
    AuthState authState = ref.read(authProvider);
    while (!authState.isInitialized && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return; // Exit if widget is disposed
      authState = ref.read(authProvider);
    }
    
    if (!mounted) return; // Check if widget is still mounted
    
    final elapsedTime = DateTime.now().difference(startTime);
    final remainingTime = minSplashDuration - elapsedTime;
    
    // If we haven't shown the splash for the minimum duration, wait longer
    if (remainingTime.inMilliseconds > 0) {
      await Future.delayed(remainingTime);
    }
    
    if (!mounted) return; // Final check before navigation
    
    final finalAuthState = ref.read(authProvider);
    if (finalAuthState.isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home/v1');
    } else {
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
            const SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}