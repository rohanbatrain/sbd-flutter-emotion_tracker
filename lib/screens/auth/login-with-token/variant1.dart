import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/screens/auth/server-settings/variant1.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'dart:async';

class LoginWithTokenScreenV1 extends ConsumerStatefulWidget {
  const LoginWithTokenScreenV1({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginWithTokenScreenV1> createState() => _LoginWithTokenScreenV1State();
}

class _LoginWithTokenScreenV1State extends ConsumerState<LoginWithTokenScreenV1> with TickerProviderStateMixin {
  final TextEditingController tokenController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOutBack,
    ));
    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    tokenController.dispose();
    super.dispose();
  }

  void _showServerChangeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ServerSettingsDialog(
          onSaved: () {
            if (mounted) setState(() {});
          },
        );
      },
    );
  }

  Future<void> _handleTokenLogin() async {
    setState(() {
      isLoading = true;
    });
    final token = tokenController.text.trim();
    if (token.isEmpty) {
      setState(() { isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Please enter a token before logging in.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      );
      return;
    }
    try {
      // Store the token in secure storage before login attempt
      final secureStorage = ref.read(secureStorageProvider);
      await secureStorage.write(key: 'access_token', value: token);
      final authNotifier = ref.read(authProvider.notifier);
      final result = await authNotifier.loginWithToken(ref, token);
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      // Handle invalid token (API returns {"token":"invalid"})6
      if (result['token'] == 'invalid') {
        final reason = result['reason']?.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reason != null && reason.isNotEmpty
                        ? 'Token invalid: $reason'
                        : 'Invalid or expired token. Please check your token and try again.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }
      // Handle special error for unverified email
      if (result['error'] == 'email_not_verified') {
        final needsEncryption = result['client_side_encryption'] == true || result['client_side_encryption'] == 'true';
        if (needsEncryption) {
          final existingKey = await secureStorage.read(key: 'client_side_encryption_key');
          if (existingKey != null && existingKey.isNotEmpty) {
            Navigator.of(context).pushReplacementNamed(
              '/verify-email/v1',
              arguments: {'finalScreen': '/home/v1'},
            );
          } else {
            Navigator.of(context).pushReplacementNamed(
              '/client-side-encryption/v1',
              arguments: {'nextScreen': '/verify-email/v1', 'finalScreen': '/home/v1'},
            );
          }
        } else {
          Navigator.of(context).pushReplacementNamed(
            '/verify-email/v1',
            arguments: {'finalScreen': '/home/v1'},
          );
        }
        return;
      }
      // Handle encryption/verification requirements
      final needsEncryption = result['client_side_encryption'] == true || result['client_side_encryption'] == 'true';
      final isVerified = result['is_verified'] == true || result['is_verified'] == 'true';
      if (needsEncryption && !isVerified) {
        final existingKey = await secureStorage.read(key: 'client_side_encryption_key');
        if (existingKey != null && existingKey.isNotEmpty) {
          Navigator.of(context).pushReplacementNamed(
            '/verify-email/v1',
            arguments: {'finalScreen': '/home/v1'},
          );
        } else {
          Navigator.of(context).pushReplacementNamed(
            '/client-side-encryption/v1',
            arguments: {'nextScreen': '/verify-email/v1', 'finalScreen': '/home/v1'},
          );
        }
        return;
      } else if (needsEncryption && isVerified) {
        final existingKey = await secureStorage.read(key: 'client_side_encryption_key');
        if (existingKey != null && existingKey.isNotEmpty) {
          Navigator.of(context).pushReplacementNamed('/home/v1');
        } else {
          Navigator.of(context).pushReplacementNamed(
            '/client-side-encryption/v1',
            arguments: {'finalScreen': '/home/v1'},
          );
        }
        return;
      } else if (!isVerified) {
        Navigator.of(context).pushReplacementNamed(
          '/verify-email/v1',
          arguments: {'finalScreen': '/home/v1'},
        );
        return;
      }
      // Success: go to home
      // If the API response contains an access_token, store it in secure storage
      if (result['access_token'] != null && result['access_token'].toString().isNotEmpty) {
        await secureStorage.write(key: 'access_token', value: result['access_token'].toString());
      }
      // Robustly wait for auth state update before navigating
      bool loggedIn = false;
      for (int i = 0; i < 10; i++) {
        final authState = ref.read(authProvider);
        if (authState.isLoggedIn) {
          loggedIn = true;
          break;
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (!mounted) return;
      if (loggedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Login successful! Welcome back.', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        );
        Navigator.of(context).pushReplacementNamed('/home/v1');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Session could not be established. Please try again.', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        );
        Navigator.of(context).pushReplacementNamed('/auth/v1');
      }
      return;
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString();
      String displayMessage = 'Authentication failed';
      Color? backgroundColor = Theme.of(context).colorScheme.error;
      if (errorMsg.contains('CLOUDFLARE_TUNNEL_DOWN:')) {
        displayMessage = 'Cloudflare tunnel is down. Please try again later or contact support.';
        backgroundColor = Colors.orange;
        _showServerChangeDialog();
        setState(() { isLoading = false; });
        return;
      } else if (errorMsg.contains('NETWORK_ERROR:')) {
        displayMessage = 'Network error. Please check your internet connection.';
        backgroundColor = Colors.red;
      } else if (errorMsg.contains('domain/IP')) {
        _showServerChangeDialog();
        setState(() { isLoading = false; });
        return;
      } else if (errorMsg.contains('Login failed: 401')) {
        displayMessage = 'Invalid or expired token. Please check your token and try again.';
      } else if (errorMsg.contains('Login failed: 403') && errorMsg.contains('Email not verified')) {
        Navigator.of(context).pushReplacementNamed(
          '/verify-email/v1',
          arguments: {'finalScreen': '/home/v1'},
        );
        setState(() { isLoading = false; });
        return;
      } else if (errorMsg.contains('Login failed: 403')) {
        displayMessage = 'Access denied. Please check your token.';
      } else if (errorMsg.contains('Login failed: 429')) {
        displayMessage = 'Too many login attempts. Please wait and try again later.';
      } else if (errorMsg.contains('Could not connect')) {
        displayMessage = 'Could not connect to server. Please check your internet connection.';
      }
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayMessage,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      );
    }
    setState(() { isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    return Scaffold(
      appBar: const CustomAppBar(title: 'Token Login', showHamburger: false, actions: [], showCurrency: false),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnimation!,
                  child: SlideTransition(
                    position: _slideAnimation!,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Login with Token',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Consumer(
                          builder: (context, ref, _) {
                            final theme = ref.watch(currentThemeProvider);
                            return Text(
                              'Enter your token to log in.\nOnly verified users can log in with a token.\nInvalid, expired, or unverified tokens will show an error.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onBackground,
                              ),
                              textAlign: TextAlign.center,
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: errorMessage != null && errorMessage!.isNotEmpty
                              ? Card(
                                  key: ValueKey(errorMessage),
                                  color: Colors.red.shade50,
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: Colors.red),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            errorMessage!,
                                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        TextField(
                          controller: tokenController,
                          decoration: InputDecoration(
                            labelText: 'Token',
                            prefixIcon: const Icon(Icons.vpn_key),
                            suffixIcon: tokenController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        tokenController.clear();
                                      });
                                    },
                                    tooltip: 'Clear token',
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.95),
                          ),
                          style: const TextStyle(letterSpacing: 1.1),
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: isLoading ? null : _handleTokenLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 2,
                              shadowColor: theme.primaryColor.withOpacity(0.2),
                            ),
                            icon: isLoading
                                ? const SizedBox.shrink()
                                : const Icon(Icons.login, color: Colors.white),
                            label: isLoading
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  )
                                : Text(
                                    'Login',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
