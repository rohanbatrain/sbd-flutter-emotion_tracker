import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/setup/backend_url_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/login_screen.dart' as login;
import 'screens/user/online/home_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/auth/logout_screen.dart';
import 'screens/user/offline/home_screen.dart'; // Import OfflineHomeScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('is_dark_mode') ?? false;
  runApp(MyApp(isDarkMode: isDarkMode));
}

class MyApp extends StatelessWidget {
  final ValueNotifier<bool> isDarkModeNotifier;

  MyApp({super.key, required bool isDarkMode})
      : isDarkModeNotifier = ValueNotifier<bool>(isDarkMode);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        return MaterialApp(
          title: 'Emotion Tracker',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: isDarkMode ? Brightness.dark : Brightness.light,
          ),
          darkTheme: ThemeData.dark(),
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/',
          routes: {
            '/': (context) => SplashScreen(), // Start with the splash screen
            '/login': (context) => login.LoginScreen(),
            '/register': (context) => RegisterScreen(),
            '/home': (context) => HomeScreen(),
            '/backend_url': (context) => BackendUrlScreen(),
            '/admin_home': (context) => AdminHomeScreen(),
            '/logout': (context) => LogoutScreen(),
            '/offline/home_screen': (context) => OfflineHomeScreen(),
          },
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToInitialScreen();
  }

  Future<void> _navigateToInitialScreen() async {
    await Future.delayed(Duration(seconds: 3)); // Simulate splash screen delay

    final prefs = await SharedPreferences.getInstance();
    final backendUrl = prefs.getString('backend_url');
    final authToken = prefs.getString('auth_token');
    final isOfflineMode = prefs.getBool('offline_mode') ?? false;

    if (!mounted) return;

    if (isOfflineMode) {
      Navigator.pushReplacementNamed(context, '/offline/home_screen');
    } else if (backendUrl == null || backendUrl.isEmpty) {
      Navigator.pushReplacementNamed(context, '/backend_url');
    } else if (authToken != null && authToken.isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/register');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white, // Dynamic color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/splash.png', // Replace with your logo image
              width: 250,
              height: 187.5,
            ),
            SizedBox(height: 30),
            Text(
              'Emotion Tracker',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
                letterSpacing: 1.5,
                fontFamily: 'Roboto',
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
