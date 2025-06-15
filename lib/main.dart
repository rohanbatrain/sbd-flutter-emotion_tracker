import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:emotion_tracker/screens/splash_screen.dart';
import 'package:emotion_tracker/screens/auth_screen.dart';
import 'package:emotion_tracker/screens/home_screen.dart';
import 'package:emotion_tracker/widgets/auth_guard.dart';

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
        '/splash': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const AuthGuard(child: HomeScreen()),
      },
    );
  }

  Widget _getInitialScreen(AuthState authState) {
    if (authState.isLoggedIn) {
      return const HomeScreen();
    }
    return const SplashScreen();
  }
}
