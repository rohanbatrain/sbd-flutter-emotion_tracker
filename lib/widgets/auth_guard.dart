import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:emotion_tracker/screens/auth/variant1.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emotion_tracker/screens/auth/verify-email/variant1.dart';
import 'package:emotion_tracker/screens/splash/variant1.dart';
import 'package:emotion_tracker/core/session_manager.dart';

class AuthGuard extends ConsumerWidget {
  final Widget child;
  
  const AuthGuard({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    // Show splash screen while authentication is being initialized
    if (!authState.isInitialized) {
      return const SplashScreenV1();
    }
    
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        final isVerified = snapshot.hasData ? (snapshot.data!.getBool('is_verified') ?? true) : true;
        final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
        
        // If user is not verified and not on allowed routes, show verification screen
        if (!isVerified && 
            currentRoute != '/verify-email/v1' && 
            currentRoute != '/splash/v1' && 
            currentRoute != '/auth/v1') {
          return const VerifyEmailScreenV1();
        }
        
        // If user is logged in (has valid token), show the protected content
        if (authState.isLoggedIn) {
          // Check for session validity
          if (!SessionManager.isSessionValid(ref)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              SessionManager.redirectToLogin(context, message: 'Session expired. Please log in again.');
            });
            return const SizedBox.shrink();
          }
          return child;
        } else {
          // Not logged in, show auth screen
          return const AuthScreenV1();
        }
      },
    );
  }
}