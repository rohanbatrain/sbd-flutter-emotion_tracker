import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'profile/variant1.dart';
import '../variant1.dart';
import 'package:emotion_tracker/screens/settings/account/change-password/variant1.dart';
import 'package:emotion_tracker/screens/settings/account/enable-2fa/2fa_status_screen.dart';
import 'package:emotion_tracker/screens/settings/account/trusted-ip/trusted_ip_status_screen.dart';
import 'package:emotion_tracker/screens/settings/account/login_history_screen.dart';
import 'package:emotion_tracker/screens/settings/account/api-tokens/api_tokens_screen.dart';
import 'package:emotion_tracker/screens/settings/account/user-agent/trusted_user_agent_status_screen.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';

class AccountSettingsScreenV1 extends ConsumerWidget {
  const AccountSettingsScreenV1({Key? key}) : super(key: key);

  Future<bool> _authenticate(
    BuildContext context, {
    String? reason,
    bool allowSkip = false,
    VoidCallback? onSkip,
  }) async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: reason ?? 'Please authenticate',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable' && allowSkip) {
        final proceed = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Device Security Not Enabled'),
                content: Text(
                  'No device security (PIN, password, or biometrics) is enabled.\n\n'
                  'Enabling 2FA without device protection is less secure.\n\n'
                  'Would you like to continue anyway?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Continue Anyway'),
                  ),
                ],
              ),
        );
        if (proceed == true) {
          if (onSkip != null) onSkip();
          return true;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication error: ${e.message ?? e.code}'),
          ),
        );
      }
      return false;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication error: ${e.toString()}')),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Account Settings',
        showHamburger: false,
        showCurrency: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const SettingsScreenV1()),
              (route) => false,
            );
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.person, color: theme.primaryColor),
              title: Text('Profile'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreenV1()),
                );
              },
            ),
            SizedBox(height: 14),
            ListTile(
              leading: Icon(Icons.lock, color: theme.primaryColor),
              title: Text('Change Password'),
              onTap: () async {
                final authenticated = await _authenticate(
                  context,
                  reason: 'Please authenticate to change your password',
                );
                if (authenticated) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreenV1(),
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 14),
            ListTile(
              leading: Icon(Icons.verified_user, color: theme.primaryColor),
              title: Text('Enable/Disable 2FA'),
              onTap: () async {
                final authenticated = await _authenticate(
                  context,
                  reason: 'Please authenticate to enable 2FA',
                  allowSkip: true,
                  onSkip: null,
                );
                if (authenticated) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TwoFAStatusScreen(),
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 14),
            ListTile(
              leading: Icon(Icons.shield, color: theme.primaryColor),
              title: Text('Trusted IP Lockdown'),
              onTap: () async {
                final authenticated = await _authenticate(
                  context,
                  reason: 'Please authenticate to view Trusted IP Lockdown',
                );
                if (authenticated) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TrustedIpStatusScreen(),
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 14),
            ListTile(
              leading: Icon(Icons.devices_other, color: theme.primaryColor),
              title: Text('Trusted User Agent Lockdown'),
              onTap: () async {
                final authenticated = await _authenticate(
                  context,
                  reason: 'Please authenticate to view Trusted User Agent Lockdown',
                );
                if (authenticated) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TrustedUserAgentStatusScreen(),
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 14),
            ListTile(
              leading: Icon(Icons.key, color: theme.primaryColor),
              title: Text('API Tokens'),
              onTap: () async {
                final authenticated = await _authenticate(
                  context,
                  reason: 'Please authenticate to manage API tokens',
                );
                if (authenticated) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ApiTokensScreen()),
                  );
                }
              },
            ),
            SizedBox(height: 14),
            ListTile(
              leading: Icon(Icons.history, color: theme.primaryColor),
              title: Text('Recent Login(s)'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginHistoryScreen()),
                );
              },
            ),
            SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}
