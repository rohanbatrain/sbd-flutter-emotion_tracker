import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:emotion_tracker/screens/auth/server-settings/variant1.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class LoginScreenV1 extends ConsumerStatefulWidget {
  final String? connectivityIssue;

  const LoginScreenV1({Key? key, this.connectivityIssue}) : super(key: key);

  @override
  ConsumerState<LoginScreenV1> createState() => _LoginScreenV1State();
}

class _LoginScreenV1State extends ConsumerState<LoginScreenV1> with TickerProviderStateMixin {
  bool isPasswordVisible = false;
  final TextEditingController usernameOrEmailController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode passwordFocusNode = FocusNode();
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  // 2FA State
  bool _is2faRequired = false;
  List<String> _available2faMethods = [];
  String? _selected2faMethod;
  final TextEditingController _2faCodeController = TextEditingController();
  AnimationController? _2faAnimationController;
  Animation<double>? _2faSectionFadeAnimation;
  Animation<Offset>? _2faSectionSlideAnimation;

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

    _2faAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _2faSectionFadeAnimation = CurvedAnimation(
      parent: _2faAnimationController!,
      curve: Curves.easeInOut,
    );
    _2faSectionSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _2faAnimationController!,
      curve: Curves.easeOut,
    ));

    // Show connectivity issue from splash screen if present
    if (widget.connectivityIssue != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showConnectivityNotification(widget.connectivityIssue!);
      });
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    usernameOrEmailController.dispose();
    emailController.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
    _2faAnimationController?.dispose();
    _2faCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: FadeTransition(
            opacity: _fadeAnimation!,
            child: SlideTransition(
              position: _slideAnimation!,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Text(
                      'Welcome Back to',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Emotion Tracker',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        'Please login with your username or email.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Username or Email Field
                    _buildTextField(
                      controller: usernameOrEmailController,
                      hintText: 'Username or Email',
                      prefixIcon: Icons.person_outline,
                      keyboardType: TextInputType.text,
                      autofillHints: [AutofillHints.username, AutofillHints.email],
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    // Password Field
                    _buildTextField(
                      controller: passwordController,
                      hintText: 'Password',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      isPasswordVisible: isPasswordVisible,
                      onPasswordToggle: () => setState(() => isPasswordVisible = !isPasswordVisible),
                      autofillHints: [AutofillHints.password],
                      theme: theme,
                      keyboardType: TextInputType.text,
                      focusNode: passwordFocusNode,
                    ),
                    if (_is2faRequired)
                      FadeTransition(
                        opacity: _2faSectionFadeAnimation!,
                        child: SlideTransition(
                          position: _2faSectionSlideAnimation!,
                          child: SizeTransition(
                            sizeFactor: _2faSectionFadeAnimation!,
                            axisAlignment: -1.0,
                            child: _build2faSection(theme),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.secondary,
                            theme.primaryColor,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.secondary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Login',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.login,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/forgot-password/v1');
                      },
                      child: Text(
                        'Forgot Password?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _showServerChangeDialog,
                      icon: Icon(
                        Icons.settings_outlined,
                        size: 18,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                      label: Text(
                        'Server Settings',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          fontWeight: FontWeight.w400,
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
    );
  }

  Widget _build2faSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_available2faMethods.length > 1)
            DropdownButtonFormField<String>(
              value: _selected2faMethod,
              items: _available2faMethods.map((String method) {
                return DropdownMenuItem<String>(
                  value: method,
                  child: Row(
                    children: [
                      Icon(
                        method == 'totp' ? Icons.shield : Icons.vpn_key,
                        color: theme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        method == 'totp' ? 'Authenticator App Code' : 'Backup Code',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selected2faMethod = newValue;
                });
              },
              decoration: InputDecoration(
                labelText: 'Verification Method',
                hintText: 'Select a method',
                filled: true,
                fillColor: theme.cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(
                    Icons.verified_user_outlined,
                    color: theme.iconTheme.color?.withOpacity(0.7),
                    size: 20,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              ),
              style: theme.textTheme.bodyLarge,
              dropdownColor: theme.cardTheme.color,
              icon: Icon(Icons.arrow_drop_down, color: theme.primaryColor),
            )
          else if (_available2faMethods.length == 1)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(
                    _available2faMethods[0] == 'totp' ? Icons.shield : Icons.vpn_key,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _available2faMethods[0] == 'totp' ? 'Authenticator App Code' : 'Backup Code',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Only option', style: theme.textTheme.bodySmall?.copyWith(color: theme.primaryColor)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _2faCodeController,
            hintText: 'Verification Code',
            prefixIcon: Icons.shield_outlined,
            theme: theme,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required ThemeData theme,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onPasswordToggle,
    List<String>? autofillHints,
    FocusNode? focusNode,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword && !isPasswordVisible,
      style: theme.textTheme.bodyLarge,
      autofillHints: autofillHints,
      focusNode: focusNode,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
        ),
        filled: true,
        fillColor: theme.cardTheme.color,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.primaryColor,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.all(16),
        prefixIcon: Container(
          margin: const EdgeInsets.only(left: 12, right: 8),
          child: Icon(
            prefixIcon,
            color: theme.iconTheme.color?.withOpacity(0.7),
            size: 20,
          ),
        ),
        suffixIcon: isPassword
            ? IconButton(
                onPressed: onPasswordToggle,
                icon: Icon(
                  isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: theme.iconTheme.color?.withOpacity(0.7),
                  size: 20,
                ),
              )
            : null,
      ),
    );
  }

  void _handleSubmit() async {
    final userInput = usernameOrEmailController.text.trim();
    final password = passwordController.text;
    final twoFaCode = _2faCodeController.text.trim();

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final result = await loginWithApi(
        ref,
        userInput,
        password,
        twoFaCode: _is2faRequired ? twoFaCode : null,
        twoFaMethod: _is2faRequired ? _selected2faMethod : null,
      );

      await authNotifier.login(userInput);

      // Ensure all storage operations are complete before continuing
      await Future.delayed(const Duration(milliseconds: 50));

      if (mounted) {
        final secureStorage = ref.read(secureStorageProvider);
        // Check for special email not verified error (login failed due to unverified email)
        if (result['error'] == 'email_not_verified') {
          // Even with email not verified, check if encryption is also required
          final needsEncryption = result['client_side_encryption'] == true || result['client_side_encryption'] == 'true';

          if (needsEncryption) {
            // Check if we already have an encryption key
            final existingKey = await secureStorage.read(key: 'client_side_encryption_key');
            if (existingKey != null && existingKey.isNotEmpty) {
              // Key exists, go directly to verification
              Navigator.of(context).pushReplacementNamed(
                '/verify-email/v1',
                arguments: {'finalScreen': '/home/v1'},
              );
            } else {
              // No key, need to set up encryption first, then verification
              Navigator.of(context).pushReplacementNamed(
                '/client-side-encryption/v1',
                arguments: {'nextScreen': '/verify-email/v1', 'finalScreen': '/home/v1'},
              );
            }
          } else {
            // Only verification required
            Navigator.of(context).pushReplacementNamed(
              '/verify-email/v1',
              arguments: {'finalScreen': '/home/v1'},
            );
          }
          return;
        }

        // Login was successful, now check what additional steps are needed
        final needsEncryption = result['client_side_encryption'] == true || result['client_side_encryption'] == 'true';
        final isVerified = result['is_verified'] == true || result['is_verified'] == 'true';

        if (needsEncryption && !isVerified) {
          // Check if we already have an encryption key
          final existingKey = await secureStorage.read(key: 'client_side_encryption_key');
          if (existingKey != null && existingKey.isNotEmpty) {
            // Key exists, go directly to verification
            Navigator.of(context).pushReplacementNamed(
              '/verify-email/v1',
              arguments: {'finalScreen': '/home/v1'},
            );
          } else {
            // No key, need to set up encryption first, then verification
            Navigator.of(context).pushReplacementNamed(
              '/client-side-encryption/v1',
              arguments: {'nextScreen': '/verify-email/v1', 'finalScreen': '/home/v1'},
            );
          }
          return;
        } else if (needsEncryption && isVerified) {
          // Check if we already have an encryption key
          final existingKey = await secureStorage.read(key: 'client_side_encryption_key');
          if (existingKey != null && existingKey.isNotEmpty) {
            // Key exists and verified, go directly to home
            Navigator.of(context).pushReplacementNamed('/home/v1');
          } else {
            // No key, need to set up encryption
            Navigator.of(context).pushReplacementNamed(
              '/client-side-encryption/v1',
              arguments: {'finalScreen': '/home/v1'},
            );
          }
          return;
        } else if (!isVerified) {
          // Only verification required (no encryption needed)
          // This should only happen if login succeeded but server indicates email not verified
          Navigator.of(context).pushReplacementNamed(
            '/verify-email/v1',
            arguments: {'finalScreen': '/home/v1'},
          );
          return;
        }

        // Neither required, go directly to home
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Login successful!'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/home/v1');
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();

        // Handle invalid TOTP code error
        if (errorMsg.contains('Login failed: 401') && errorMsg.contains('Invalid TOTP code')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid verification code. Please try again.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
        // Handle invalid or already used backup code error
        if (errorMsg.contains('Login failed: 401') && errorMsg.contains('Invalid or already used backup code')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid or already used backup code. Please use a valid backup code.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }

        if (errorMsg.contains('Login failed: 422')) {
          try {
            final jsonString = errorMsg.substring(errorMsg.indexOf('{'), errorMsg.lastIndexOf('}') + 1);
            final errorJson = jsonDecode(jsonString);
            if (errorJson['two_fa_required'] == true) {
              setState(() {
                _is2faRequired = true;
                _available2faMethods = List<String>.from(errorJson['available_methods'] ?? []);
                if (_available2faMethods.isNotEmpty) {
                  _selected2faMethod = _available2faMethods[0];
                }
              });
              _2faAnimationController!.forward();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorJson['detail'] ?? '2FA authentication required.'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
          } catch (jsonError) {
            // Fallback for JSON parsing error
            print('Error parsing 2FA error from server: $jsonError');
          }
        }

        // Handle different types of errors with user-friendly messages
        String displayMessage = 'Authentication failed';
        Color? backgroundColor = Theme.of(context).colorScheme.error;

        if (errorMsg.contains('CLOUDFLARE_TUNNEL_DOWN:')) {
          displayMessage = 'Cloudflare tunnel is down. Please try again later or contact support.';
          backgroundColor = Colors.orange;
          _showServerChangeDialog();
          return;
        } else if (errorMsg.contains('NETWORK_ERROR:')) {
          displayMessage = 'Network error. Please check your internet connection.';
          backgroundColor = Colors.red;
        } else if (errorMsg.contains('domain/IP')) {
          _showServerChangeDialog();
          return;
        } else if (errorMsg.contains('Login failed: 401')) {
          displayMessage = 'Invalid username/email or password. Please check your credentials and try again.';
        } else if (errorMsg.contains('Login failed: 403') && errorMsg.contains('Email not verified')) {
          // Only trigger email verification for 403 errors that specifically mention "Email not verified"
          Navigator.of(context).pushReplacementNamed(
            '/verify-email/v1',
            arguments: {'finalScreen': '/home/v1'},
          );
          return;
        } else if (errorMsg.contains('Login failed: 403')) {
          displayMessage = 'Access denied. Please check your credentials.';
        } else if (errorMsg.contains('Login failed: 429')) {
          displayMessage = 'Too many login attempts. Please wait and try again later.';
        } else if (errorMsg.contains('Could not connect')) {
          displayMessage = 'Could not connect to server. Please check your internet connection.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMessage),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showConnectivityNotification(String connectivityIssue) {
    if (!mounted) return;

    final theme = ref.read(currentThemeProvider);
    final warningColor = theme.colorScheme.error;

    // Determine if this is a network connectivity issue vs server issue
    final isNetworkIssue = connectivityIssue.toLowerCase().contains('no internet') ||
        connectivityIssue.toLowerCase().contains('network') ||
        connectivityIssue.toLowerCase().contains('unable to connect');

    // Delay to ensure the login screen is fully loaded
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: warningColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    isNetworkIssue ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
                    color: warningColor.withOpacity(0.8),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isNetworkIssue ? 'Network Connection Issue' : 'Server Connection Issue',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onError,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        connectivityIssue,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onError.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: warningColor.withOpacity(0.7),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: warningColor.withOpacity(0.9),
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          action: SnackBarAction(
            label: 'Settings',
            textColor: theme.colorScheme.onError,
            backgroundColor: warningColor.withOpacity(0.8),
            onPressed: () {
              if (!mounted) return;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();

              // Open device network settings for network issues, server settings for server issues
              if (isNetworkIssue) {
                _openDeviceNetworkSettings();
              } else {
                _showServerChangeDialog();
              }
            },
          ),
        ),
      );
    });
  }

  void _openDeviceNetworkSettings() async {
    if (!mounted) return;

    // Get platform information and capture context-dependent values before any async operations
    final platform = Theme.of(context).platform;
    final theme = ref.read(currentThemeProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Try to open WiFi settings on Android
      if (platform == TargetPlatform.android) {
        // Use url_launcher to open Android WiFi settings
        try {
          // Try to launch WiFi settings intent directly
          final Uri wifiUri = Uri.parse('android.settings.WIFI_SETTINGS');
          if (await canLaunchUrl(wifiUri)) {
            await launchUrl(wifiUri, mode: LaunchMode.externalApplication);
          } else {
            throw Exception('Cannot launch WiFi settings');
          }
        } catch (e) {
          // Fallback to general settings
          try {
            final Uri settingsUri = Uri.parse('android.settings.SETTINGS');
            if (await canLaunchUrl(settingsUri)) {
              await launchUrl(settingsUri, mode: LaunchMode.externalApplication);
            } else {
              throw Exception('Cannot launch settings');
            }
          } catch (e2) {
            // Final fallback - show guidance dialog
            if (mounted) _showConnectionGuidance();
          }
        }
      } else if (platform == TargetPlatform.iOS) {
        // iOS doesn't allow direct navigation to WiFi settings
        // Try to open general settings
        try {
          final Uri settingsUri = Uri.parse('App-Prefs:root=WIFI');
          if (await canLaunchUrl(settingsUri)) {
            await launchUrl(settingsUri);
          } else {
            throw Exception('Cannot launch iOS settings');
          }
        } catch (e) {
          // Show helpful message for iOS
          if (mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Please go to Settings > Wi-Fi to check your connection'),
                backgroundColor: theme.primaryColor,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        // For other platforms, show guidance
        if (mounted) _showConnectionGuidance();
      }
    } catch (e) {
      // If all else fails, show helpful guidance
      if (mounted) _showConnectionGuidance();
    }
  }

  void _showConnectionGuidance() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = ref.read(currentThemeProvider);
        final warningColor = theme.colorScheme.error;

        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: warningColor, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Connection Issue',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: warningColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To fix your connection, please try:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12),
              _buildGuidanceItem('Go to Settings > Wi-Fi', Icons.wifi),
              _buildGuidanceItem('Check if Wi-Fi is enabled', Icons.wifi_tethering),
              _buildGuidanceItem('Try connecting to a network', Icons.network_wifi),
              _buildGuidanceItem('Or enable mobile data', Icons.signal_cellular_alt),
              SizedBox(height: 8),
              Text(
                'Then try logging in again.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: warningColor.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: theme.primaryColor,
              ),
              child: Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGuidanceItem(String text, IconData icon) {
    final theme = ref.read(currentThemeProvider);
    final warningColor = theme.colorScheme.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: warningColor.withOpacity(0.8)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _showServerChangeDialog() {
    ref.read(currentThemeProvider);
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
}
