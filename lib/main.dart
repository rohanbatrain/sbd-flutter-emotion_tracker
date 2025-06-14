import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:emotion_tracker/screens/splash_screen.dart';
import 'package:emotion_tracker/screens/auth_screen.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';

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

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      navigatorKey: navigationService.navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    
    return Scaffold(
      appBar: const CustomAppBar(title: 'Emotion Tracker'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to Emotion Tracker!',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _showThemeSelector(context, ref),
              child: const Text('Change Theme'),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeSelector(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.read(themeProvider);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ThemeSelector(currentTheme: currentTheme),
    );
  }
}
