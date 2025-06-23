import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ForgotPasswordScreenV1 extends ConsumerStatefulWidget {
  const ForgotPasswordScreenV1({Key? key}) : super(key: key);

  @override
  ConsumerState<ForgotPasswordScreenV1> createState() => _ForgotPasswordScreenV1State();
}

class _ForgotPasswordScreenV1State extends ConsumerState<ForgotPasswordScreenV1> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;
  bool isSubmitted = false;
  String? errorText;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void _submit() async {
    setState(() {
      errorText = null;
    });
    final email = emailController.text.trim().toLowerCase();
    // Use centralized email validation
    final emailValidationError = InputValidator.validateEmail(email);
    if (emailValidationError != null) {
      setState(() {
        errorText = emailValidationError;
      });
      return;
    }
    setState(() {
      isLoading = true;
    });
    try {
      await forgotPasswordApi(ref, email);
      setState(() {
        isLoading = false;
        isSubmitted = true;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorText = 'Failed to send reset link. Please try again.';
      });
    }
  }

  void _resend() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });
    final email = emailController.text.trim().toLowerCase();
    try {
      final response = await forgotPasswordApi(ref, email);
      setState(() {
        isLoading = false;
      });
      final globalContext = ref.read(navigationServiceProvider).currentContext;
      if (globalContext != null) {
        ScaffoldMessenger.of(globalContext).showSnackBar(
          const SnackBar(content: Text('Reset link resent!')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorText = 'Failed to resend reset link. Please try again.';
      });
    }
  }

  void _backToEmail() {
    setState(() {
      isSubmitted = false;
      errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Forgot Password?', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: isSubmitted ? _buildConfirmation(theme) : _buildForm(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 32, bottom: 32),
      child: Column(
        key: const ValueKey('form'),
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/Animation - 1749905705545.json',
            width: 120,
            height: 120,
            repeat: true,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          Text(
            'Forgot Password?',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 26,
              letterSpacing: 0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            'Enter your email address and we’ll send you a link to reset your password.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
              fontSize: 15.5,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            enabled: !isLoading,
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: const Icon(Icons.email_outlined),
              errorText: errorText,
              filled: true,
              fillColor: theme.cardTheme.color,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: theme.textTheme.bodyLarge,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Send Reset Link',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation(ThemeData theme) {
    return Center(
      child: SizedBox(
        width: 500,
        child: Column(
          key: const ValueKey('confirmation'),
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Lottie.asset(
                      'assets/Animation - 1750273841544.json',
                      width: 120,
                      height: 120,
                      repeat: true,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Check Your Email',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 26,
                      letterSpacing: 0.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We’ve sent a password reset link to your email. Please check your inbox and follow the instructions to reset your password.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
                      fontSize: 15.5,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : _resend,
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
                        onPressed: isLoading ? null : _backToEmail,
                        icon: Icon(Icons.arrow_back, color: theme.primaryColor),
                        label: Text(
                          'Back to Email',
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0, top: 8.0),
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

Future<Map<String, dynamic>> forgotPasswordApi(WidgetRef ref, String email) async {
  final baseUrl = ref.read(apiBaseUrlProvider);
  final url = Uri.parse('$baseUrl/auth/forgot-password');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email}), // Send email in JSON body
  );
  if (response.statusCode >= 200 && response.statusCode < 300) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to send reset link: ${response.statusCode} ${response.body}');
  }
}
