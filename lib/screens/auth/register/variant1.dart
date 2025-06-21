import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:emotion_tracker/screens/auth/server-settings/variant1.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class RegisterScreenV1 extends ConsumerStatefulWidget {
  const RegisterScreenV1({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreenV1> createState() => _RegisterScreenV1State();
}

class _RegisterScreenV1State extends ConsumerState<RegisterScreenV1> with TickerProviderStateMixin {
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool encryptionEnabled = false;
  bool? isUsernameAvailable;
  bool isCheckingUsername = false;
  String? usernameError;
  String? passwordError;
  final TextEditingController emailController = TextEditingController();
  bool? isEmailAvailable;
  bool isCheckingEmail = false;
  String? emailError;
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final FocusNode passwordFocusNode = FocusNode();
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  Timer? _usernameDebounce;

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
    passwordFocusNode.addListener(() {
      if (!passwordFocusNode.hasFocus && passwordController.text.isEmpty) {
        confirmPasswordController.clear();
        setState(() {});
      }
    });
    usernameController.addListener(_onUsernameChanged);
    emailController.addListener(_onEmailChanged);
  }

  void _onUsernameChanged() {
    final username = usernameController.text.trim().toLowerCase();
    // Only check if length and pattern are valid
    if (username.length < 3) {
      setState(() {
        isUsernameAvailable = null;
        usernameError = 'Username must be at least 3 characters.';
        isCheckingUsername = false;
      });
      _usernameDebounce?.cancel();
      return;
    } else if (username.length > 50) {
      setState(() {
        isUsernameAvailable = null;
        usernameError = 'Username must be less than 50 characters.';
        isCheckingUsername = false;
      });
      _usernameDebounce?.cancel();
      return;
    } else if (!RegExp(r'^[a-z0-9_-]+$').hasMatch(username)) {
      setState(() {
        isUsernameAvailable = null;
        usernameError = 'Only lowercase letters, numbers, dash (-), and underscore (_).';
        isCheckingUsername = false;
      });
      _usernameDebounce?.cancel();
      return;
    }
    setState(() {
      isUsernameAvailable = null;
      usernameError = null;
      isCheckingUsername = true;
    });
    _usernameDebounce?.cancel();
    _usernameDebounce = Timer(const Duration(milliseconds: 600), () async {
      // Only trigger API if client-side checks pass
      try {
        final available = await checkUsernameAvailability(ref, username);
        setState(() {
          isUsernameAvailable = available;
          usernameError = available ? null : 'Username is already taken.';
        });
      } catch (e) {
        setState(() {
          usernameError = 'Could not check username.';
        });
      } finally {
        setState(() {
          isCheckingUsername = false;
        });
      }
    });
  }

  void _onEmailChanged() {
    final email = emailController.text.trim().toLowerCase();
    final emailRegExp = RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$');
    if (!emailRegExp.hasMatch(email)) {
      setState(() {
        isEmailAvailable = null;
        emailError = 'Enter a valid email address.';
        isCheckingEmail = false;
      });
      return;
    }
    setState(() {
      isEmailAvailable = null;
      emailError = null;
      isCheckingEmail = true;
    });
    Timer(const Duration(milliseconds: 600), () async {
      try {
        final available = await checkEmailAvailability(ref, email);
        setState(() {
          isEmailAvailable = available;
          emailError = available ? null : 'Email is already registered.';
        });
      } catch (e) {
        setState(() {
          emailError = 'Could not check email.';
        });
      } finally {
        setState(() {
          isCheckingEmail = false;
        });
      }
    });
  }

  void _onPasswordChanged(String val) {
    // Password strength: min 8, upper, lower, digit, special
    if (val.isEmpty) {
      setState(() {
        passwordError = null;
      });
      return;
    }
    if (val.length < 8) {
      setState(() {
        passwordError = 'Password must be at least 8 characters.';
      });
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(val)) {
      setState(() {
        passwordError = 'Password must contain an uppercase letter.';
      });
      return;
    }
    if (!RegExp(r'[a-z]').hasMatch(val)) {
      setState(() {
        passwordError = 'Password must contain a lowercase letter.';
      });
      return;
    }
    if (!RegExp(r'\d').hasMatch(val)) {
      setState(() {
        passwordError = 'Password must contain a digit.';
      });
      return;
    }
    if (!RegExp(r'[!@#\$&*~%^()_\-+=\[\]{}|;:,.<>?/]').hasMatch(val)) {
      setState(() {
        passwordError = 'Password must contain a special character.';
      });
      return;
    }
    setState(() {
      passwordError = null;
    });
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _animationController?.dispose();
    emailController.removeListener(_onEmailChanged);
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    usernameController.dispose();
    passwordFocusNode.dispose();
    usernameController.removeListener(_onUsernameChanged);
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
                        'You are creating a Second Brain Database account. This account will be used across all our apps.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: usernameController,
                      hintText: 'Username',
                      prefixIcon: Icons.person_outline,
                      keyboardType: TextInputType.text,
                      autofillHints: [AutofillHints.username],
                      theme: theme,
                      onEditingComplete: null, // debounce now handles checking
                      errorText: usernameError,
                      suffix: isCheckingUsername
                          ? Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: Icon(Icons.more_horiz, color: theme.dividerColor, size: 14),
                            )
                          : isUsernameAvailable == true
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 2),
                                  child: Icon(Icons.check_circle, color: Colors.green, size: 12),
                                )
                              : isUsernameAvailable == false
                                  ? Padding(
                                      padding: const EdgeInsets.only(right: 2),
                                      child: Icon(Icons.error, color: Colors.red, size: 12),
                                    )
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: emailController,
                      hintText: 'Email Address',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: [AutofillHints.newUsername, AutofillHints.email],
                      theme: theme,
                      errorText: emailError,
                      suffix: isCheckingEmail
                          ? Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: Icon(Icons.more_horiz, color: theme.dividerColor, size: 14),
                            )
                          : isEmailAvailable == true
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 2),
                                  child: Icon(Icons.check_circle, color: Colors.green, size: 12),
                                )
                              : isEmailAvailable == false
                                  ? Padding(
                                      padding: const EdgeInsets.only(right: 2),
                                      child: Icon(Icons.error, color: Colors.red, size: 12),
                                    )
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: passwordController,
                      hintText: 'Password',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      isPasswordVisible: isPasswordVisible,
                      onPasswordToggle: () => setState(() => isPasswordVisible = !isPasswordVisible),
                      autofillHints: [AutofillHints.newPassword],
                      theme: theme,
                      keyboardType: TextInputType.text,
                      focusNode: passwordFocusNode,
                      onChanged: _onPasswordChanged,
                      errorText: passwordError,
                    ),
                    const SizedBox(height: 16),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: (passwordController.text.isNotEmpty && passwordFocusNode.hasFocus || (passwordController.text.isNotEmpty && !passwordFocusNode.hasFocus && passwordController.text.isNotEmpty)) ? 56 : 0,
                      child: (passwordController.text.isNotEmpty && passwordFocusNode.hasFocus || (passwordController.text.isNotEmpty && !passwordFocusNode.hasFocus && passwordController.text.isNotEmpty))
                          ? _buildTextField(
                              controller: confirmPasswordController,
                              hintText: 'Confirm Password',
                              prefixIcon: Icons.lock_outline,
                              isPassword: true,
                              isPasswordVisible: isConfirmPasswordVisible,
                              onPasswordToggle: () => setState(() => isConfirmPasswordVisible = !isConfirmPasswordVisible),
                              autofillHints: [AutofillHints.newPassword],
                              theme: theme,
                            )
                          : const SizedBox.shrink(),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: encryptionEnabled,
                          onChanged: (val) {
                            if (val == true && !encryptionEnabled) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: theme.cardTheme.color,
                                  title: Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
                                      SizedBox(width: 8),
                                      Text('Important Notice', style: theme.textTheme.titleMedium),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('If you enable encryption, your data will be encrypted with a key only you know. If you lose this key, your data cannot be recovered.'),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      child: Text('Cancel', style: TextStyle(color: theme.primaryColor)),
                                      onPressed: () => Navigator.of(context).pop(),
                                    ),
                                    ElevatedButton(
                                      child: Text('I Understand'),
                                      onPressed: () {
                                        setState(() {
                                          encryptionEnabled = true;
                                        });
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              setState(() {
                                encryptionEnabled = val ?? false;
                              });
                            }
                          },
                        ),
                        Expanded(
                          child: Text(
                            'Enable encryption for my account data',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
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
                              'Create Account',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.person_add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
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
    VoidCallback? onEditingComplete,
    String? errorText,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword && !isPasswordVisible,
      style: theme.textTheme.bodyLarge,
      autofillHints: autofillHints,
      focusNode: focusNode,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
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
            : suffix,
        errorText: errorText,
      ),
    );
  }

  void _handleSubmit() async {
    final username = usernameController.text.trim().toLowerCase();
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;

    // Username validation
    final usernameRegExp = RegExp(r'^[a-z0-9_-]{3,50}$');
    if (!usernameRegExp.hasMatch(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Username must be 3-50 characters, only letters, numbers, dash (-), and underscore (_). No spaces or special characters.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Username availability check
    setState(() { isCheckingUsername = true; });
    try {
      final available = await checkUsernameAvailability(ref, username);
      setState(() { isUsernameAvailable = available; });
      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Username is already taken.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
    } catch (e) {
      setState(() { usernameError = 'Could not check username.'; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not check username.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    } finally {
      setState(() { isCheckingUsername = false; });
    }

    // Email validation
    final emailRegExp = RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$');
    if (!emailRegExp.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid email address.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Email availability check
    if (isEmailAvailable == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email is already registered.'),
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

    if (password != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    try {
      final authNotifier = ref.read(authProvider.notifier);
      final result = await registerWithApi(
        ref,
        username,
        email,
        password,
        clientSideEncryption: encryptionEnabled,
      );
      await authNotifier.signup(username, email, password);

      final secureStorage = ref.read(secureStorageProvider);
      await secureStorage.write(key: 'access_token', value: result['access_token'] ?? '');
      await secureStorage.write(key: 'token_type', value: result['token_type'] ?? '');
      await secureStorage.write(key: 'client_side_encryption', value: encryptionEnabled ? 'true' : 'false');
      await secureStorage.write(key: 'user_email', value: email);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('issued_at', result['issued_at']?.toString() ?? '');
      await prefs.setString('expires_at', result['expires_at']?.toString() ?? '');
      await prefs.setBool('is_verified', result['is_verified'] ?? false);

      if (mounted) {
        final needsVerification = result['is_verified'] == false;
        
        if (encryptionEnabled && needsVerification) {
          // Both required: start with encryption, then verification
          Navigator.of(context).pushReplacementNamed(
            '/client-side-encryption/v1',
            arguments: {'nextScreen': '/verify-email/v1', 'finalScreen': '/home/v1'},
          );
          return;
        } else if (encryptionEnabled) {
          // Only encryption required
          Navigator.of(context).pushReplacementNamed(
            '/client-side-encryption/v1',
            arguments: {'finalScreen': '/home/v1'},
          );
          return;
        } else if (needsVerification) {
          // Only verification required
          Navigator.of(context).pushReplacementNamed(
            '/verify-email/v1',
            arguments: {'finalScreen': '/home/v1'},
          );
          return;
        }
        
        // Neither required, go directly to home
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account created successfully!'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/home/v1');
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        if (errorMsg.contains('domain/IP')) {
          _showServerChangeDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Authentication failed: $errorMsg'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
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
