import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:emotion_tracker/providers/transition_provider.dart';
import 'package:emotion_tracker/providers/shared_prefs_provider.dart';
import 'package:emotion_tracker/utils/http_util.dart';
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
  String? _connectivityIssue; // Store connectivity issue message

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAuthAndNavigate();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200), // Slightly faster animation
      vsync: this,
    );

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic), // Faster logo animation
    ));

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut), // Earlier text animation
    ));

    // Start animation immediately
    _animationController.forward();
  }

  _checkAuthAndNavigate() async {
    // Minimum splash duration for branding (reduced to 1 second for faster startup)
    const minSplashDuration = Duration(milliseconds: 1000);
    
    // Wait for minimum splash duration, auth initialization, and server health check in parallel
    await Future.wait([
      Future.delayed(minSplashDuration),
      _waitForAuthInitialization(),
      _checkServerHealth(),
    ]);
    
    if (!mounted) return; // Check if widget is still mounted
    
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
        AuthScreenV1(connectivityIssue: _connectivityIssue),
        config: PageTransitionService.splashToAuth,
        routeName: '/auth/v1',
      );
    }
  }

  Future<void> _checkServerHealth() async {
    try {
      // Ensure the server providers are loaded
      final protocol = ref.read(serverProtocolProvider);  
      final domain = ref.read(serverDomainProvider);
      final healthCheckUrl = '$protocol://$domain/health';
      
      final response = await HttpUtil.get(Uri.parse(healthCheckUrl)).timeout(const Duration(seconds: 3));
      
      if (response.statusCode != 200) {
        // Server health check failed, but we'll still proceed to auth screen
        print('Server health check failed with status: ${response.statusCode}');
        
        // Provide specific messages for different error codes
        String errorMessage;
        if (response.statusCode == 502) {
          errorMessage = 'Server gateway error - Cloudflare tunnel temporarily down (502)';
        } else if (response.statusCode == 503) {
          errorMessage = 'Server temporarily unavailable - Cloudflare maintenance (503)';
        } else if (response.statusCode == 504) {
          errorMessage = 'Server timeout - Cloudflare gateway issue (504)';
        } else if (response.statusCode == 530) {
          errorMessage = 'Server DNS configuration error (530)';
        } else if (response.statusCode >= 520 && response.statusCode <= 529) {
          errorMessage = 'Cloudflare error (${response.statusCode})';
        } else if (response.statusCode >= 500 && response.statusCode <= 599) {
          errorMessage = 'Server error (${response.statusCode})';
        } else {
          errorMessage = 'Server is temporarily unavailable (HTTP ${response.statusCode})';
        }
        
        _setConnectivityIssue(errorMessage);
      }
    } catch (e) {
      // Server health check failed, but we'll still proceed to auth screen
      if (e is CloudflareTunnelException) {
        print('Cloudflare error: ${e.message}');
        
        // Provide specific messages for different Cloudflare errors
        String errorMessage;
        if (e.statusCode == 502) {
          errorMessage = 'Server gateway error - Cloudflare tunnel temporarily down';
        } else if (e.statusCode == 503) {
          errorMessage = 'Server temporarily unavailable - Cloudflare maintenance';
        } else if (e.statusCode == 504) {
          errorMessage = 'Server timeout - Cloudflare gateway issue';
        } else if (e.statusCode == 530) {
          errorMessage = 'Server DNS configuration error';
        } else if (e.statusCode >= 520 && e.statusCode <= 529) {
          errorMessage = 'Cloudflare tunnel issue (${e.statusCode})';
        } else {
          errorMessage = 'Server tunnel is currently down';
        }
        
        _setConnectivityIssue(errorMessage);
      } else if (e is NetworkException) {
        print('Network error during health check: ${e.message}');
        _setConnectivityIssue('No internet connection detected');
      } else {
        print('Server health check failed: $e');
        _setConnectivityIssue('Unable to connect to server');
      }
    }
  }

  void _setConnectivityIssue(String message) {
    _connectivityIssue = message;
  }

  Future<void> _waitForAuthInitialization() async {
    AuthState authState = ref.read(authProvider);
    while (!authState.isInitialized && mounted) {
      await Future.delayed(const Duration(milliseconds: 50)); // Reduced polling interval
      if (!mounted) return; // Exit if widget is disposed
      authState = ref.read(authProvider);
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
                
                // Loading indicator with faster animation
                FadeTransition(
                  opacity: _textAnimation,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                      strokeWidth: 2,
                    ),
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