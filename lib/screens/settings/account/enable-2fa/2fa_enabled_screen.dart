import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '2fa_setup_screen.dart';
import 'package:emotion_tracker/providers/two_fa_service.dart';
import 'package:emotion_tracker/providers/transition_provider.dart';
import 'package:emotion_tracker/core/global_error_handler.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/core/session_manager.dart';
import 'package:emotion_tracker/core/exceptions.dart' as core_exceptions;
import 'package:emotion_tracker/core/error_state.dart';

/// Screen shown when 2FA is enabled.
class TwoFAEnabledScreen extends ConsumerWidget {
  const TwoFAEnabledScreen({Key? key}) : super(key: key);

  Future<void> _confirmDisable(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disable 2FA?'),
        content: const Text('Are you sure you want to disable two-factor authentication?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Disable')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(twoFAServiceProvider).disable2FA();
        if (context.mounted) {
          Navigator.of(context).pushReplacementWithTransition(
            const TwoFADisabledScreen(),
            config: PageTransitionService.homeToSettings,
          );
        }
      } catch (e) {
        final errorState = GlobalErrorHandler.processError(e);
        if (e is core_exceptions.UnauthorizedException) {
          SessionManager.redirectToLogin(context, message: 'Session expired. Please log in again.');
          return;
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorState.message)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Two-Factor Authentication')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              Text('Two-factor authentication is enabled.', style: theme.textTheme.titleMedium),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.lock_open),
                  onPressed: () => _confirmDisable(context, ref),
                  label: const Text('Disable 2FA'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen shown when 2FA is disabled.
class TwoFADisabledScreen extends ConsumerWidget {
  const TwoFADisabledScreen({Key? key}) : super(key: key);

  void _navigateToSetup(BuildContext context) {
    Navigator.of(context).pushReplacementWithTransition(
      const TwoFASetupScreen(),
      config: PageTransitionService.homeToSettings,
    );
  }

  Future<void> _launchEnteAuth() async {
    final url = Uri.parse('https://ente.io/auth/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Widget _buildStep(int number, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$number.', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: content),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Two-Factor Authentication')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_open, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Two-factor authentication is disabled.', style: theme.textTheme.titleMedium),
              const SizedBox(height: 32),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 10),
                          Text(
                            'How to Set Up 2FA',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildStep(
                        1,
                        RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodyMedium,
                            children: [
                              const TextSpan(text: 'Download an authenticator app like'),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: GestureDetector(
                                  onTap: _launchEnteAuth,
                                  child: Text(
                                    'Ente Auth (Open Source)',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildStep(
                        2,
                        const Text('Tap "Enable 2FA" below and scan the QR code with your authenticator app.'),
                      ),
                      _buildStep(
                        3,
                        const Text('Enter the verification code from your app to complete the setup.'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.verified_user),
                  onPressed: () => _navigateToSetup(context),
                  label: const Text('Enable 2FA'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
