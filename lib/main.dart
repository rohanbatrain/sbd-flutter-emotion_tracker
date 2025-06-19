import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:emotion_tracker/screens/splash/variant1.dart';
import 'package:emotion_tracker/screens/auth/variant1.dart';
import 'package:emotion_tracker/screens/home/variant1.dart';
import 'package:emotion_tracker/widgets/auth_guard.dart';
import 'package:emotion_tracker/screens/auth/verify-email/variant1.dart';
import 'package:emotion_tracker/screens/auth/client-side-encryption/variant1.dart';
import 'package:emotion_tracker/screens/auth/forgot-password/variant1.dart';

const String registrationAppId = 'emotion_tracker';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    final navigationService = ref.read(navigationServiceProvider);
    final authState = ref.watch(authProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      navigatorKey: navigationService.navigatorKey,
      home: _getInitialScreen(authState),
      routes: {
        // Variant 1 Routes
        '/splash/v1': (context) => const SplashScreenV1(),
        '/auth/v1': (context) => const AuthScreenV1(),
        '/home/v1': (context) => const AuthGuard(child: HomeScreenV1()),
        '/verify-email/v1': (context) => const VerifyEmailScreenV1(),
        '/forgot-password/v1': (context) => const ForgotPasswordScreenV1(),
        '/client-side-encryption/v1': (context) => const ClientSideEncryptionScreenV1(),
        // Variant 2 Routes
      },
    );
  }

  Widget _getInitialScreen(AuthState authState) {
    if (authState.isLoggedIn) {
      return const HomeScreenV1();
    }
    return const SplashScreenV1();
  }
}
