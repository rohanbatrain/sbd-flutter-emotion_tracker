import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/providers/shared_prefs_provider.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:emotion_tracker/utils/http_util.dart';
import 'dart:convert';

class VerifyEmailScreenV1 extends ConsumerStatefulWidget {
  final VoidCallback? onRefresh;

  const VerifyEmailScreenV1({
    Key? key,
    this.onRefresh,
  }) : super(key: key);

  @override
  ConsumerState<VerifyEmailScreenV1> createState() => _VerifyEmailScreenV1State();
}

class _VerifyEmailScreenV1State extends ConsumerState<VerifyEmailScreenV1> {
  Map<String, dynamic>? flowArguments;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get navigation arguments
    flowArguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _resendVerificationEmail() async {
    try {
      await resendVerificationEmail(ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend verification email: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _checkVerification(BuildContext context, WidgetRef ref) async {
    // Add a small delay to ensure token is saved if we just logged in
    await Future.delayed(const Duration(milliseconds: 100));
    
    final storage = ref.read(secureStorageProvider);
    final prefs = await ref.read(sharedPrefsProvider.future);
    final token = await storage.read(key: 'access_token');
    final protocol = prefs.getString('server_protocol') ?? 'https';
    final domain = prefs.getString('server_domain') ?? 'dev-app-sbd.rohanbatra.in';
    final url = Uri.parse('$protocol://$domain/auth/is-verified');
    
    if (token == null || token.isEmpty) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/auth/v1');
      }
      return;
    }
    try {
      final response = await HttpUtil.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['is_verified'] == true) {
          await prefs.setBool('is_verified', true);
          if (context.mounted) {
            // Navigate based on flow arguments or default to home
            final finalScreen = flowArguments?['finalScreen'] as String? ?? '/home/v1';
            Navigator.of(context).pushReplacementNamed(finalScreen);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email not verified yet. Please check your inbox.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to check verification: ${response.body}')),
        );
      }
    } catch (e) {
      if (e is CloudflareTunnelException) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cloudflare tunnel is down. Please try again later.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (e is NetworkException) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please check your connection.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: flowArguments != null ? AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.primaryColor),
          onPressed: () {
            // Check if we came from encryption screen
            Navigator.of(context).pushReplacementNamed('/auth/v1');
          },
        ),
      ) : null,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                // Top Lottie Icon
                Container(
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Lottie.asset(
                    'assets/Animation - 1750273841544.json',
                    width: 100,
                    height: 100,
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                Text(
                  'Verify Your Email',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                    letterSpacing: 0.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Subtitle
                Text(
                  'We’ve sent a verification link to your email. Please check your inbox and click the link to verify your account.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
                    fontSize: 15.5,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Buttons
                Column(
                  children: [
                    TextButton.icon(
                      onPressed: () => _checkVerification(context, ref),
                      icon: Icon(Icons.check_circle_outline, color: theme.primaryColor),
                      label: Text(
                        'I Have Verified',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.primaryColor,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                        foregroundColor: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _resendVerificationEmail,
                      icon: Icon(Icons.send_outlined, color: theme.hintColor),
                      label: Text(
                        'Resend Verification Link',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.hintColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Footer hint
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Column(
                    children: [
                      Text(
                        'Didn’t receive the email? Check your spam folder or try resending.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          fontSize: 13.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _EmailClientButton(
                            icon: Icons.email_outlined,
                            label: 'Gmail',
                            url: 'googlegmail://',
                            fallbackUrl: 'https://mail.google.com',
                          ),
                          const SizedBox(width: 10),
                          _EmailClientButton(
                            icon: Icons.mail_outline,
                            label: 'Outlook',
                            url: 'ms-outlook://',
                            fallbackUrl: 'https://outlook.live.com',
                          ),
                          const SizedBox(width: 10),
                          _EmailClientButton(
                            icon: Icons.mail_lock_outlined,
                            label: 'Proton Mail',
                            url: 'protonmail://',
                            fallbackUrl: 'https://mail.proton.me',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailClientButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  final String fallbackUrl;

  const _EmailClientButton({
    required this.icon,
    required this.label,
    required this.url,
    required this.fallbackUrl,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.primaryColor,
        side: BorderSide(color: theme.primaryColor.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        textStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          final fallbackUri = Uri.parse(fallbackUrl);
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}
