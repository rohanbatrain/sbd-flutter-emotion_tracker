import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:emotion_tracker/providers/transition_provider.dart';
import 'package:emotion_tracker/screens/splash/variant1.dart';
import 'package:emotion_tracker/screens/auth/variant1.dart';
import 'package:emotion_tracker/screens/home/variant1.dart';
import 'package:emotion_tracker/widgets/auth_guard.dart';
import 'package:emotion_tracker/screens/auth/verify-email/variant1.dart';
import 'package:emotion_tracker/screens/auth/client-side-encryption/variant1.dart';
import 'package:emotion_tracker/screens/auth/forgot-password/variant1.dart';
import 'package:emotion_tracker/screens/auth/login-with-token/variant1.dart';
import 'package:emotion_tracker/screens/settings/account/family/family_shop_screen.dart';
import 'package:emotion_tracker/screens/settings/team/enhanced_team_wallet_screen.dart';
import 'package:emotion_tracker/screens/settings/team/workspace_list_screen.dart';
import 'package:emotion_tracker/screens/ai/ai_chat_screen.dart';
import 'package:timezone/data/latest_all.dart' as tz;

const String registrationAppId = 'emotion_tracker';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  // Pre-warm AdMob initialization in background (non-blocking)
  _initializeAdMobInBackground();

  // Run the app immediately, let background tasks initialize asynchronously
  runApp(const ProviderScope(child: MyApp()));
}

// Initialize AdMob in background without blocking app startup
void _initializeAdMobInBackground() {
  // Only initialize AdMob on iOS or Android. Many desktop targets (including macOS)
  // do not have a native implementation for the google_mobile_ads plugin and
  // calling MobileAds.instance.initialize() will throw MissingPluginException.
  if (!(defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS)) {
    return;
  }

  Future.microtask(() async {
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      // AdMob initialization failed, but don't block the app
      print('Background AdMob initialization failed: $e');
    }
  });
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
      home: WillPopScope(
        onWillPop: () async {
          if (navigationService.navigatorKey.currentState?.canPop() ?? false) {
            navigationService.navigatorKey.currentState?.pop();
            return false;
          }
          return true;
        },
        child: _getInitialScreen(authState),
      ),
      onGenerateRoute: (settings) => _generateRoute(settings),
      routes: {
        // Variant 1 Routes
        '/splash/v1': (context) => const SplashScreenV1(),
        '/auth/v1': (context) => const AuthScreenV1(),
        '/home/v1': (context) => const AuthGuard(child: HomeScreenV1()),
        '/verify-email/v1': (context) => const VerifyEmailScreenV1(),
        '/forgot-password/v1': (context) => const ForgotPasswordScreenV1(),
        '/client-side-encryption/v1': (context) =>
            const ClientSideEncryptionScreenV1(),
        '/login-with-token/v1': (context) =>
            const LoginWithTokenScreenV1(), // <-- Added route
        '/family/shop/v1': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          final familyId = args != null && args['familyId'] is String
              ? args['familyId'] as String
              : '';
          return FamilyShopScreen(familyId: familyId);
        },
        // Variant 2 Routes
        '/team/wallets': (context) => const EnhancedTeamWalletScreen(),
        '/team/workspaces': (context) => const WorkspaceListScreen(),
        // AI Routes
        '/ai/chat': (context) => const AIChatScreen(),
      },
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    // Custom route generation with beautiful transitions
    Widget page;
    TransitionConfig config;

    switch (settings.name) {
      case '/splash/v1':
        page = const SplashScreenV1();
        config = const TransitionConfig(type: TransitionType.fade);
        break;
      case '/auth/v1':
        page = const AuthScreenV1();
        config = PageTransitionService.splashToAuth;
        break;
      case '/home/v1':
        page = const AuthGuard(child: HomeScreenV1());
        config = PageTransitionService.authToHome;
        break;
      case '/verify-email/v1':
        page = const VerifyEmailScreenV1();
        config = PageTransitionService.modalTransition;
        break;
      case '/forgot-password/v1':
        page = const ForgotPasswordScreenV1();
        config = PageTransitionService.modalTransition;
        break;
      case '/client-side-encryption/v1':
        page = const ClientSideEncryptionScreenV1();
        config = PageTransitionService.modalTransition;
        break;
      case '/login-with-token/v1':
        page = const LoginWithTokenScreenV1();
        config = PageTransitionService.modalTransition;
        break;
      case '/family/shop/v1':
        final args = settings.arguments as Map<String, dynamic>?;
        final familyId = args != null && args['familyId'] is String
            ? args['familyId'] as String
            : '';
        page = FamilyShopScreen(familyId: familyId);
        config = PageTransitionService.modalTransition;
        break;
      case '/ai/chat':
        page = const AIChatScreen();
        config = PageTransitionService.modalTransition;
        break;
      default:
        return null; // Let Flutter handle other routes normally
    }

    return PageTransitionService.createRoute(
      page: page,
      config: config,
      settings: settings,
    );
  }

  Widget _getInitialScreen(AuthState authState) {
    // Always show splash screen first to ensure proper timing
    return const SplashScreenV1();
  }
}
