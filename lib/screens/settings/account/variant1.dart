import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:local_auth/local_auth.dart';
import 'change-password/variant1.dart';
import 'enable-2fa/variant1.dart';
import 'profile/variant1.dart';

class AccountSettingsScreenV1 extends ConsumerWidget {
  const AccountSettingsScreenV1({Key? key}) : super(key: key);

  Future<bool> _authenticate(BuildContext context) async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to change your password',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      return didAuthenticate;
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
              final authenticated = await _authenticate(context);
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
            title: Text('Enable 2FA'),
            onTap: () async {
              final LocalAuthentication auth = LocalAuthentication();
              final authenticated = await auth.authenticate(
                localizedReason: 'Please authenticate to enable 2FA',
                options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
              );
              if (authenticated) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Enable2FAScreenV1(),
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
