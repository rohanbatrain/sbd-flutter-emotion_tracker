import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

class VerifyEmailScreenV1 extends ConsumerWidget {
  final VoidCallback? onResend;
  final VoidCallback? onRefresh;

  const VerifyEmailScreenV1({
    Key? key,
    this.onResend,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onResend,
                        icon: Icon(Icons.refresh, color: theme.colorScheme.onPrimary),
                        label: Text(
                          'Resend Email',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: onRefresh,
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
