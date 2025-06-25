import 'package:emotion_tracker/screens/settings/account/enable-2fa/2fa_enabled_screen.dart';
import 'package:emotion_tracker/screens/settings/account/enable-2fa/2fa_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/two_fa_service.dart';

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
          final theme = Theme.of(context);
          // If UnauthorizedException, show message and redirect
          final error = snapshot.error;
          if (error is UnauthorizedException) {
            // Show a dialog/snackbar and redirect to login
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Your session has expired. Please log in again.')),
              );
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            });
            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              body: Center(child: Text('Session expired. Redirecting to login...')),
            );
          }
          // Other errors
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          final theme = Theme.of(context);
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              title: const Text('Two-Factor Authentication'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (onBackToSettings != null) {
                    onBackToSettings!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
              centerTitle: true,
              elevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                      strokeWidth: 5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Loading your 2FA status...',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we securely check your account.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
          );
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
