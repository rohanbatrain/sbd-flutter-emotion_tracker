import 'package:emotion_tracker/providers/user_agent_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/core/global_error_handler.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'package:emotion_tracker/widgets/loading_state_widget.dart';
import 'package:emotion_tracker/core/session_manager.dart';
import 'package:emotion_tracker/core/error_state.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/core/exceptions.dart' as core_exceptions;
import 'dart:convert';
import 'package:emotion_tracker/utils/http_util.dart';

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
  ErrorState? _errorState;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorState = null;
    });
    try {
      final currentPassword = _currentPasswordController.text.trim();
      final newPassword = _newPasswordController.text.trim();
      // Use centralized password validation
      final passwordValidationError = InputValidator.validatePassword(newPassword);
      if (passwordValidationError != null) {
        setState(() {
          _isLoading = false;
          _errorState = GlobalErrorHandler.processError(Exception(passwordValidationError));
        });
        return;
      }
      // Call provider/service method for password change
      await changePassword(ref, currentPassword, newPassword);
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      final errorState = GlobalErrorHandler.processError(e);
      setState(() {
        _isLoading = false;
        _errorState = errorState;
      });
      if (e is core_exceptions.UnauthorizedException) {
        SessionManager.redirectToLogin(context, message: 'Session expired. Please log in again.');
        return;
      }
      GlobalErrorHandler.showErrorSnackbar(
        context,
        errorState.message,
        errorState.type,
      );
    }
  }

  void _handleRetry() {
    _handleChangePassword();
    GlobalErrorHandler.showErrorSnackbar(
      context,
      'Retrying request...',
      ErrorType.generic,
    );
  }

  void _showErrorInfo(dynamic error) {
    final errorState = GlobalErrorHandler.processError(error);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(errorState.icon, color: errorState.color),
            const SizedBox(width: 8),
            const Text('Change Password Error Help'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Unable to change your password.'),
            const SizedBox(height: 8),
            Text(errorState.message),
            const SizedBox(height: 16),
            const Text('Troubleshooting steps:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_getTroubleshootingSteps(errorState.type)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getTroubleshootingSteps(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.unauthorized:
        return '• Check if you are still logged in\n• Try logging out and back in\n• Contact support if issue persists';
      case ErrorType.networkError:
        return '• Check your internet connection\n• Try switching networks\n• Wait and try again';
      case ErrorType.serverError:
        return '• Server may be temporarily down\n• Try again in a few minutes\n• Check server status';
      case ErrorType.rateLimited:
        return '• You are making requests too quickly\n• Wait a few minutes\n• Try again later';
      default:
        return '• Try refreshing the page\n• Check your connection\n• Contact support if needed';
    }
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
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        ),
      ),
      body: _isLoading
          ? const LoadingStateWidget(message: 'Changing your password...')
          : _errorState != null
              ? ErrorStateWidget(
                  error: _errorState!,
                  onRetry: _handleRetry,
                  onInfo: () => _showErrorInfo(_errorState),
                  customMessage: 'Unable to change password. Please try again.',
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.shadowColor.withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Change your password',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 18),
                                _buildPasswordField(
                                  theme,
                                  label: 'Current Password',
                                  controller: _currentPasswordController,
                                  validator: (v) => v == null || v.isEmpty ? 'Enter current password' : null,
                                ),
                                const SizedBox(height: 12),
                                _buildPasswordField(
                                  theme,
                                  label: 'New Password',
                                  controller: _newPasswordController,
                                  validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                                ),
                                const SizedBox(height: 12),
                                _buildPasswordField(
                                  theme,
                                  label: 'Confirm New Password',
                                  controller: _confirmPasswordController,
                                  validator: (v) => v != _newPasswordController.text ? 'Passwords do not match' : null,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor,
                                    foregroundColor: theme.colorScheme.onPrimary,
                                    minimumSize: const Size.fromHeight(48),
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 2,
                                  ),
                                  icon: const Icon(Icons.lock_reset),
                                  onPressed: _isLoading ? null : _handleChangePassword,
                                  label: const Text('Change Password'),
                                ),
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed('/forgot-password/v1');
                                  },
                                  child: const Text('Forgot Password?', style: TextStyle(decoration: TextDecoration.underline)),
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

/// Calls the backend API to change the user's password
Future<void> changePassword(WidgetRef ref, String currentPassword, String newPassword) async {
  final baseUrl = ref.read(apiBaseUrlProvider);
  final url = Uri.parse('$baseUrl/auth/change-password');
  final secureStorage = ref.read(secureStorageProvider);
  final token = await secureStorage.read(key: 'access_token');
  if (token == null || token.isEmpty) {
    throw core_exceptions.UnauthorizedException('Session expired. Please log in again.');
  }
  final userAgent = await getUserAgent();
  final headers = {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'User-Agent': userAgent,
    'X-User-Agent': userAgent,
  };
  final body = {
    'current_password': currentPassword,
    'new_password': newPassword,
  };
  final response = await HttpUtil.post(
    url,
    headers: headers,
    body: jsonEncode(body),
  );
  if (response.statusCode == 200) {
    return;
  } else if (response.statusCode == 401) {
    await ref.read(authProvider.notifier).logout();
    throw core_exceptions.UnauthorizedException('Session expired. Please log in again.');
  } else if (response.statusCode == 429) {
    String message = 'Too many requests. Please wait before trying again.';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['detail'] is String) {
        message = body['detail'];
      }
    } catch (_) {}
    throw core_exceptions.RateLimitException(message);
  } else if (response.statusCode >= 500 && response.statusCode < 600) {
    throw core_exceptions.ApiException('Server error (${response.statusCode}). Please try again later.', response.statusCode);
  } else {
    String errorMsg = 'Failed to change password.';
    try {
      final errJson = jsonDecode(response.body);
      errorMsg = errJson['detail']?.toString() ?? errorMsg;
    } catch (_) {}
    throw core_exceptions.ApiException(errorMsg, response.statusCode);
  }
}
