import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:emotion_tracker/screens/auth/server-settings/variant1.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreenV1 extends ConsumerStatefulWidget {
  const LoginScreenV1({Key? key}) : super(key: key);

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
    usernameOrEmailController.dispose();
    emailController.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
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
                      'Welcome to',
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

    // Regex for email and username
    final emailRegExp = RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$');
    final usernameRegExp = RegExp(r'^[a-z0-9_-]{3,50}$');

    if (!emailRegExp.hasMatch(userInput) && !usernameRegExp.hasMatch(userInput)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid username or email.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Password validation
    if (password.isEmpty || password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password must be at least 8 characters.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final result = await loginWithApi(ref, userInput, password);
      await authNotifier.login(userInput, password);

      final secureStorage = ref.read(secureStorageProvider);
      await secureStorage.write(key: 'access_token', value: result['access_token'] ?? '');
      await secureStorage.write(key: 'token_type', value: result['token_type'] ?? '');
      await secureStorage.write(key: 'client_side_encryption', value: result['client_side_encryption']?.toString() ?? 'false');
      await secureStorage.write(key: 'user_role', value: result['role'] ?? 'user');
      // Store email if present
      if (emailRegExp.hasMatch(userInput)) {
        await secureStorage.write(key: 'user_email', value: userInput);
      } else {
        // Store username for verification purposes
        await secureStorage.write(key: 'user_username', value: userInput);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('issued_at', result['issued_at']?.toString() ?? '');
      await prefs.setString('expires_at', result['expires_at']?.toString() ?? '');
      await prefs.setBool('is_verified', result['is_verified'] ?? false);

      // Ensure all storage operations are complete before continuing
      await Future.delayed(const Duration(milliseconds: 50));

      if (mounted) {
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
}
