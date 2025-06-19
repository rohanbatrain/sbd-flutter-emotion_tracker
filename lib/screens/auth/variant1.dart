import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:emotion_tracker/screens/auth/server-settings/variant1.dart';

class AuthScreenV1 extends ConsumerStatefulWidget {
  const AuthScreenV1({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthScreenV1> createState() => _AuthScreenV1State();
}

class _AuthScreenV1State extends ConsumerState<AuthScreenV1> with TickerProviderStateMixin {
  bool isLogin = true;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool encryptionEnabled = false;
  bool isEncryptionKeyVisible = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController encryptionKeyController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
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
    passwordFocusNode.addListener(() {
      if (!passwordFocusNode.hasFocus && passwordController.text.isEmpty) {
        confirmPasswordController.clear();
        setState(() {}); // Triggers rebuild to hide confirm password
      }
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    encryptionKeyController.dispose();
    usernameController.dispose();
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
                    
                    // Welcome Text
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

                    // Subtle info message for login/register
                    if (isLogin)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          'Please login with your Second Brain Database account.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (!isLogin)
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

                    // Enhanced Toggle Section
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: GestureDetector(
                                onTap: () => setState(() => isLogin = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isLogin ? theme.primaryColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: isLogin
                                        ? [
                                            BoxShadow(
                                              color: theme.primaryColor.withOpacity(0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    'Login',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: isLogin 
                                        ? Colors.white
                                        : theme.textTheme.bodyMedium?.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: GestureDetector(
                                onTap: () => setState(() => isLogin = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !isLogin ? theme.primaryColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: !isLogin
                                        ? [
                                            BoxShadow(
                                              color: theme.primaryColor.withOpacity(0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    'Signup',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: !isLogin 
                                        ? Colors.white
                                        : theme.textTheme.bodyMedium?.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Username Field (signup only)
                    if (!isLogin) ...[
                      _buildTextField(
                        controller: usernameController,
                        hintText: 'Username',
                        prefixIcon: Icons.person_outline,
                        keyboardType: TextInputType.text,
                        autofillHints: [AutofillHints.username],
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Enhanced Email Field
                    _buildTextField(
                      controller: emailController,
                      hintText: 'Email Address',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: isLogin
                          ? [AutofillHints.username, AutofillHints.email]
                          : [AutofillHints.newUsername, AutofillHints.email],
                      theme: theme,
                    ),

                    const SizedBox(height: 16),

                    // Enhanced Password Field
                    _buildTextField(
                      controller: passwordController,
                      hintText: 'Password',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      isPasswordVisible: isPasswordVisible,
                      onPasswordToggle: () => setState(() => isPasswordVisible = !isPasswordVisible),
                      autofillHints: isLogin
                          ? [AutofillHints.password]
                          : [AutofillHints.newPassword],
                      theme: theme,
                      keyboardType: TextInputType.text,
                      focusNode: passwordFocusNode,
                      onChanged: (val) {
                        if (val.isEmpty) {
                          confirmPasswordController.clear();
                        }
                        setState(() {});
                      },
                    ),

                    // Spacing between password fields
                    if (!isLogin) const SizedBox(height: 16),

                    // Confirm Password Field (animated)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: (!isLogin && passwordController.text.isNotEmpty && passwordFocusNode.hasFocus || (!isLogin && passwordController.text.isNotEmpty && !passwordFocusNode.hasFocus && passwordController.text.isNotEmpty)) ? 56 : 0,
                      child: (!isLogin && passwordController.text.isNotEmpty && passwordFocusNode.hasFocus || (!isLogin && passwordController.text.isNotEmpty && !passwordFocusNode.hasFocus && passwordController.text.isNotEmpty))
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

                    // Add spacing between Confirm Password and Encryption Key
                    if (!isLogin && encryptionEnabled) SizedBox(height: 16),

                    // Encryption Key Field (signup only, above checkbox)
                    if (!isLogin && encryptionEnabled) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 56,
                        child: _buildTextField(
                          controller: encryptionKeyController,
                          hintText: 'Enter encryption key (min 16 chars)',
                          prefixIcon: Icons.vpn_key,
                          isPassword: true,
                          isPasswordVisible: isEncryptionKeyVisible,
                          onPasswordToggle: () => setState(() => isEncryptionKeyVisible = !isEncryptionKeyVisible),
                          theme: theme,
                        ),
                      ),
                      SizedBox(height: 16),
                    ],

                    // Encryption Checkbox (signup only, below key field)
                    if (!isLogin) ...[
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
                                        Text(
                                          'If you enable encryption, your data will be protected with this key. If you forget it, there is absolutely no way to recover your data. This applies to all apps using this unified login.',
                                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Choose a strong encryption key (at least 16 characters, 32+ recommended, using a mix of upper and lower case letters, numbers, and symbols). More than 32 is overkill for most users.',
                                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Note: Enabling encryption will significantly increase our storage costs, as your data will be stored at a size proportional to your key length. Please consider supporting us to help keep this zero-trust ecosystem running.',
                                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: Text('Cancel', style: TextStyle(color: theme.primaryColor)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() => encryptionEnabled = true);
                                          Navigator.of(context).pop();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme.primaryColor,
                                          foregroundColor: theme.colorScheme.onPrimary,
                                        ),
                                        child: Text('I Understand'),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                setState(() {
                                  encryptionEnabled = val ?? false;
                                  if (!encryptionEnabled) encryptionKeyController.clear();
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
                    ],

                    const SizedBox(height: 24),

                    // Enhanced Submit Button
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
                              isLogin ? 'Login' : 'Create Account',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isLogin ? Icons.login : Icons.person_add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Forgot Password (only for login)
                    if (isLogin)
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

                    // Change Server Link with icon
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
    final username = usernameController.text.trim().toLowerCase();
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;

    // Username validation (for registration)
    final usernameRegExp = RegExp(r'^[a-z0-9_-]{3,50}$');
    if (!isLogin && !usernameRegExp.hasMatch(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Username must be 3-50 characters, only letters, numbers, dash (-), and underscore (_). No spaces or special characters.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
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

    // Password validation (eased)
    if (password.isEmpty || password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password must be at least 8 characters.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (!isLogin && password != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (!isLogin && encryptionEnabled && encryptionKeyController.text.length < 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Encryption key must be at least 16 characters.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    try {
      final authNotifier = ref.read(authProvider.notifier);
      if (isLogin) {
        await authNotifier.login(email, password);
      } else {
        await authNotifier.signup(username, email, password);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isLogin ? 'Login successful!' : 'Account created successfully!'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );

        // Navigate to home screen after successful auth
        Navigator.of(context).pushReplacementNamed('/home/v1');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
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