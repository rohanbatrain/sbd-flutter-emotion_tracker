import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:emotion_tracker/providers/transition_provider.dart';
import 'package:emotion_tracker/screens/auth/variant1.dart';
import 'package:emotion_tracker/screens/home/variant1.dart';
import 'package:emotion_tracker/widgets/auth_guard.dart';

class SplashScreenV1 extends ConsumerStatefulWidget {
  const SplashScreenV1({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreenV1> createState() => _SplashScreenV1State();
}

class _SplashScreenV1State extends ConsumerState<SplashScreenV1> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAuthAndNavigate();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  _checkAuthAndNavigate() async {
    final startTime = DateTime.now();
    const minSplashDuration = Duration(seconds: 4);
    
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
      // Use beautiful transition to home
      Navigator.of(context).pushReplacementWithTransition(
        const AuthGuard(child: HomeScreenV1()),
        config: PageTransitionService.splashToHome,
        routeName: '/home/v1',
      );
    } else {
      // Use beautiful transition to auth
      Navigator.of(context).pushReplacementWithTransition(
        const AuthScreenV1(),
        config: PageTransitionService.splashToAuth,
        routeName: '/auth/v1',
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Logo
                FadeTransition(
                  opacity: _logoAnimation,
                  child: ScaleTransition(
                    scale: _logoAnimation,
                    child: Lottie.asset(
                      'assets/Animation - 1749905705545.json',
                      width: 200,
                      height: 200,
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Animated Title
                FadeTransition(
                  opacity: _textAnimation,
                  child: Text(
                    'Emotion Tracker',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Animated Subtitle
                FadeTransition(
                  opacity: _textAnimation,
                  child: Text(
                    'Powered by Second Brain Database',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Loading indicator
                FadeTransition(
                  opacity: _textAnimation,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}