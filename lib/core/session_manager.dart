import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/app_providers.dart'
    show authProvider, navigationServiceProvider;
import 'package:emotion_tracker/providers/api_token_service.dart'
    show UnauthorizedException;
import 'package:emotion_tracker/core/error_constants.dart';

/// SessionManager handles automatic session management and redirects
/// Integrates with existing auth provider and navigation patterns
class SessionManager {
  /// Handles session expiry by clearing auth data and redirecting to login
  /// Uses existing authProvider.logout() method and navigation patterns
  static Future<void> handleSessionExpiry(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      // Clear authentication data using existing auth provider
      await ref.read(authProvider.notifier).logout();

      // Show session expired snackbar
      if (context.mounted) {
        _showSessionExpiredSnackbar(context);
      }

      // Redirect to login using existing navigation pattern
      _redirectToLogin(context);
    } catch (e) {
      // If logout fails, still redirect to login
      if (context.mounted) {
        _redirectToLogin(context);
      }
    }
  }

  /// Clears authentication data using existing auth provider
  /// This method delegates to the existing authProvider.logout() method
  static Future<void> clearAuthData(WidgetRef ref) async {
    await ref.read(authProvider.notifier).logout();
  }

  /// Redirects to login screen using existing navigation pattern
  /// Uses the same pattern as existing code: pushNamedAndRemoveUntil('/auth/v1')
  static void redirectToLogin(BuildContext context, {String? message}) {
    if (message != null && context.mounted) {
      _showCustomSnackbar(context, message);
    }
    _redirectToLogin(context);
  }

  /// Internal method to redirect to login using existing navigation pattern
  static void _redirectToLogin(BuildContext context) {
    if (context.mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/auth/v1', (route) => false);
    }
  }

  /// Shows session expired snackbar using existing snackbar patterns
  static void _showSessionExpiredSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.logout, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                ErrorConstants.sessionExpired,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: ErrorConstants.snackbarDuration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows custom snackbar message
  static void _showCustomSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: ErrorConstants.snackbarDuration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Detects if an error is a session expiry error
  /// Works with existing UnauthorizedException handling
  static bool isSessionExpired(dynamic error) {
    return error is UnauthorizedException;
  }

  /// Handles UnauthorizedException automatically
  /// This method can be called from error handling code to automatically
  /// process session expiry without manual intervention
  static Future<void> handleUnauthorizedException(
    BuildContext context,
    WidgetRef ref,
    UnauthorizedException error,
  ) async {
    await handleSessionExpiry(context, ref);
  }

  /// Alternative method using NavigationService for contexts where BuildContext is not available
  /// This uses the existing navigationServiceProvider pattern
  static Future<void> handleSessionExpiryWithNavigationService(
    WidgetRef ref,
  ) async {
    try {
      // Clear authentication data using existing auth provider
      await ref.read(authProvider.notifier).logout();

      // Get navigation service
      final navigationService = ref.read(navigationServiceProvider);
      final context = navigationService.currentContext;

      if (context != null && context.mounted) {
        // Show session expired snackbar
        _showSessionExpiredSnackbar(context);
      }

      // Redirect to login using navigation service
      navigationService.navigateToAndClearStack('/auth/v1');
    } catch (e) {
      // If logout fails, still redirect to login
      final navigationService = ref.read(navigationServiceProvider);
      navigationService.navigateToAndClearStack('/auth/v1');
    }
  }

  /// Utility method to check if current user session is valid
  /// This can be used by other parts of the app to check session validity
  static bool isSessionValid(WidgetRef ref) {
    final authState = ref.read(authProvider);
    return authState.isLoggedIn && authState.accessToken != null;
  }
}
