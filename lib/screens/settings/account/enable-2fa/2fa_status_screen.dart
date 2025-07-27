import 'package:emotion_tracker/screens/settings/account/enable-2fa/2fa_enabled_screen.dart';
import 'package:emotion_tracker/screens/settings/account/enable-2fa/2fa_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/two_fa_service.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/core/session_manager.dart';
import 'package:emotion_tracker/core/exceptions.dart' as core_exceptions;

/// Entry point for 2FA settings. Decides which screen to show based on /2fa/status.
class TwoFAStatusScreen extends ConsumerWidget {
  final VoidCallback? onBackToSettings;

  const TwoFAStatusScreen({Key? key, this.onBackToSettings}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(twoFAServiceProvider).get2FAStatus(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = snapshot.error;
          if (error is core_exceptions.UnauthorizedException) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              SessionManager.redirectToLogin(context, message: 'Your session has expired. Please log in again.');
            });
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: Center(child: Text('Session expired. Redirecting to login...')),
            );
          }
          return ErrorStateWidget(
            error: error,
            onRetry: () => ref.invalidate(twoFAServiceProvider),
            customMessage: 'Unable to load your 2FA status. Please try again.',
          );
        }
        if (!snapshot.hasData) {
          return const LoadingStateWidget(message: 'Loading your 2FA status...');
        }
        final data = snapshot.data as Map<String, dynamic>;
        final enabled = data['enabled'] == true;
        final pending = data['pending'] == true;
        if (!enabled && !pending) {
          return const TwoFADisabledScreen();
        } else if (!enabled && pending) {
          return const TwoFASetupScreen();
        } else if (enabled) {
          return const TwoFAEnabledScreen();
        }
        return const Center(child: Text('Unknown 2FA state'));
      },
    );
  }
}
