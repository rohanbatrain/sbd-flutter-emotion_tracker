import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/app_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with TickerProviderStateMixin {
  bool isLogin = true;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
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
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
                    const SizedBox(height: 32),

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

                    // Enhanced Email Field
                    _buildTextField(
                      controller: emailController,
                      hintText: 'Email Address',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
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
                      theme: theme,
                    ),

                    // Spacing between password fields
                    if (!isLogin) const SizedBox(height: 16),

                    // Confirm Password Field (animated)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: !isLogin ? 56 : 0,
                      child: !isLogin
                          ? _buildTextField(
                              controller: confirmPasswordController,
                              hintText: 'Confirm Password',
                              prefixIcon: Icons.lock_outline,
                              isPassword: true,
                              isPasswordVisible: isConfirmPasswordVisible,
                              onPasswordToggle: () => setState(() => isConfirmPasswordVisible = !isConfirmPasswordVisible),
                              theme: theme,
                            )
                          : const SizedBox.shrink(),
                    ),

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
                          // Handle forgot password
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Password reset link sent!'),
                              backgroundColor: theme.colorScheme.secondary,
                            ),
                          );
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword && !isPasswordVisible,
      style: theme.textTheme.bodyLarge,
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
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all fields'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (!isLogin && passwordController.text != confirmPasswordController.text) {
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
      
      if (isLogin) {
        await authNotifier.login(emailController.text, passwordController.text);
      } else {
        await authNotifier.signup(emailController.text, passwordController.text);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isLogin ? 'Login successful!' : 'Account created successfully!'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );

        // Navigate to home screen after successful auth
        Navigator.of(context).pushReplacementNamed('/home');
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
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.cardTheme.color,
          title: Text(
            'Change Server',
            style: theme.textTheme.titleMedium,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter server URL',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                  filled: true,
                  fillColor: theme.scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: theme.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Server updated successfully'),
                    backgroundColor: theme.colorScheme.secondary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: theme.floatingActionButtonTheme.foregroundColor,
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}