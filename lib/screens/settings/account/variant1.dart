import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'change-password/variant1.dart';
import 'profile/variant1.dart';
import 'enable-2fa/2fa_status_screen.dart';

class AccountSettingsScreenV1 extends ConsumerWidget {
  const AccountSettingsScreenV1({Key? key}) : super(key: key);

  Future<bool> _authenticate(BuildContext context, {String? reason, bool allowSkip = false, VoidCallback? onSkip}) async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: reason ?? 'Please authenticate',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable' && allowSkip) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Device Security Not Enabled'),
            content: Text(
              'No device security (PIN, password, or biometrics) is enabled.\n\n'
              'Enabling 2FA without device protection is less secure.\n\n'
              'Would you like to continue anyway?'
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
          SnackBar(content: Text('Authentication error: ${e.message ?? e.code}')),
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
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Settings',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.person, color: theme.primaryColor),
            title: Text('Profile'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileScreenV1(),
                ),
              );
            },
          ),
          SizedBox(height: 14),
          ListTile(
            leading: Icon(Icons.lock, color: theme.primaryColor),
            title: Text('Change Password'),
            onTap: () async {
              final authenticated = await _authenticate(context, reason: 'Please authenticate to change your password');
              if (authenticated) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangePasswordScreenV1(),
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
                onSkip: null, // Optionally handle skip event
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
        ],
      ),
    );
  }
}
