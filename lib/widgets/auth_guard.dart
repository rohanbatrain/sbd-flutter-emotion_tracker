import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:emotion_tracker/screens/auth/variant1.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emotion_tracker/screens/auth/verify-email/variant1.dart';

class AuthGuard extends ConsumerWidget {
  final Widget child;
  
  const AuthGuard({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        final isVerified = snapshot.hasData ? (snapshot.data!.getBool('is_verified') ?? true) : true;
        final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
        if (!isVerified && currentRoute != '/verify-email/v1' && currentRoute != '/splash/v1' && currentRoute != '/auth/v1') {
          // Only allow verify-email, splash, and login
          return const VerifyEmailScreenV1();
        }
        if (authState.isLoggedIn) {
          return child;
        } else {
          return const AuthScreenV1();
        }
      },
    );
  }
}