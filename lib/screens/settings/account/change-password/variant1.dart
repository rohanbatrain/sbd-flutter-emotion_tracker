import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';

class ChangePasswordScreenV1 extends ConsumerStatefulWidget {
  final VoidCallback? onBackToSettings;
  const ChangePasswordScreenV1({Key? key, this.onBackToSettings}) : super(key: key);

  @override
  ConsumerState<ChangePasswordScreenV1> createState() => _ChangePasswordScreenV1State();
}

class _ChangePasswordScreenV1State extends ConsumerState<ChangePasswordScreenV1> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    setState(() => _isLoading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password changed successfully!')),
    );
    Navigator.of(context).pop();
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
          onPressed: () {
            if (widget.onBackToSettings != null) {
              widget.onBackToSettings!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                _buildPasswordField(
                  theme,
                  label: 'Current Password',
                  controller: _currentPasswordController,
                  validator: (v) => v == null || v.isEmpty ? 'Enter current password' : null,
                ),
                const SizedBox(height: 8),
                _buildPasswordField(
                  theme,
                  label: 'New Password',
                  controller: _newPasswordController,
                  validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 8),
                _buildPasswordField(
                  theme,
                  label: 'Confirm New Password',
                  controller: _confirmPasswordController,
                  validator: (v) => v != _newPasswordController.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: theme.colorScheme.onPrimary,
                    minimumSize: const Size.fromHeight(48),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onPressed: _isLoading ? null : _handleChangePassword,
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Change Password'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/forgot-password/v1');
                  },
                  child: const Text('Forgot Password?', style: TextStyle(decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    ThemeData theme, {
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: true,
          validator: validator,
          decoration: InputDecoration(
            hintText: label,
            filled: true,
            fillColor: theme.inputDecorationTheme.fillColor ?? theme.cardColor,
            border: theme.inputDecorationTheme.border,
            focusedBorder: theme.inputDecorationTheme.focusedBorder,
            enabledBorder: theme.inputDecorationTheme.enabledBorder,
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          ),
        ),
      ],
    );
  }
}
