import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/core/global_error_handler.dart';
import 'package:emotion_tracker/core/error_utils.dart';
import 'package:emotion_tracker/core/error_state.dart';
import 'package:emotion_tracker/widgets/error_state_widget.dart';
import 'shop_constants.dart';

/// Specialized error handler for shop-related operations
class ShopErrorHandler {
  /// Handles errors that occur during cart operations
  static void handleCartError(
    BuildContext context,
    dynamic error, {
    String? customMessage,
  }) {
    final errorState = GlobalErrorHandler.processError(error);
    final message =
        customMessage ??
        ErrorUtils.formatErrorMessage(
          error,
          fallback: ShopConstants.addToCartError,
        );

    // Log the error with shop context
    ErrorUtils.logError(
      error,
      context: {
        'operation': 'cart',
        'screen': 'shop',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Show error snackbar
    GlobalErrorHandler.showErrorSnackbar(context, message, errorState.type);
  }

  /// Handles errors that occur during item loading operations
  static void handleLoadingError(
    BuildContext context,
    dynamic error, {
    String? itemType,
    VoidCallback? onRetry,
  }) {
    final errorState = GlobalErrorHandler.processError(error);
    final message = ErrorUtils.formatErrorMessage(
      error,
      fallback: itemType != null
          ? 'Failed to load $itemType'
          : ShopConstants.loadingError,
    );

    // Log the error with loading context
    ErrorUtils.logError(
      error,
      context: {
        'operation': 'loading',
        'itemType': itemType,
        'screen': 'shop',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // For loading errors, we might want to show a different UI
    if (onRetry != null && GlobalErrorHandler.isRetryable(errorState)) {
      // Show error snackbar with retry option
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(errorState.icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onRetry();
                },
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: errorState.color,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      GlobalErrorHandler.showErrorSnackbar(context, message, errorState.type);
    }
  }

  /// Handles errors that occur during purchase operations
  static void handlePurchaseError(
    BuildContext context,
    WidgetRef ref,
    dynamic error, {
    String? itemId,
    String? itemType,
  }) {
    final errorState = GlobalErrorHandler.processError(error);

    // Log the error with purchase context
    ErrorUtils.logError(
      error,
      context: {
        'operation': 'purchase',
        'itemId': itemId,
        'itemType': itemType,
        'screen': 'shop',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Handle unauthorized errors specially for purchases
    if (errorState.type == ErrorType.unauthorized) {
      ErrorUtils.handleSessionError(context, ref, error);
      return;
    }

    final message = ErrorUtils.formatErrorMessage(
      error,
      fallback: ShopConstants.purchaseError,
    );

    GlobalErrorHandler.showErrorSnackbar(context, message, errorState.type);
  }

  /// Creates a retry mechanism for shop operations
  static Future<T> withShopRetry<T>(
    Future<T> Function() operation, {
    required String operationType,
    Map<String, dynamic>? context,
    int maxRetries = 3,
  }) async {
    return ErrorUtils.withRetry(
      operation,
      maxRetries: maxRetries,
      onRetry: (error, retryCount) {
        ErrorUtils.logError(
          error,
          context: {
            'operation': operationType,
            'retryCount': retryCount,
            'screen': 'shop',
            ...?context,
          },
        );
      },
      onError: (error, stackTrace) {
        ErrorUtils.logError(
          error,
          stackTrace: stackTrace,
          context: {
            'operation': operationType,
            'failed': true,
            'screen': 'shop',
            ...?context,
          },
        );
      },
    );
  }

  /// Creates an error state widget for shop-specific errors
  static Widget createErrorWidget(
    dynamic error, {
    VoidCallback? onRetry,
    String? customMessage,
    bool compact = false,
  }) {
    return ErrorStateWidget(
      error: error,
      onRetry: onRetry,
      customMessage: customMessage,
      compact: compact,
    );
  }

  /// Handles session-related errors in shop context
  static Future<void> handleSessionError(
    BuildContext context,
    WidgetRef ref,
    dynamic error,
  ) async {
    // Log session error with shop context
    ErrorUtils.logError(
      error,
      context: {
        'operation': 'session',
        'screen': 'shop',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    await ErrorUtils.handleSessionError(context, ref, error);
  }

  /// Creates a debounced error handler for shop operations
  static void Function(dynamic error) createDebouncedShopErrorHandler(
    BuildContext context, {
    String? operationType,
    Duration debounceTime = const Duration(milliseconds: 500),
  }) {
    return ErrorUtils.createDebouncedErrorHandler((error) {
      final errorState = GlobalErrorHandler.processError(error);
      final message = ErrorUtils.formatErrorMessage(error);

      // Log with shop context
      ErrorUtils.logError(
        error,
        context: {
          'operation': operationType ?? 'unknown',
          'screen': 'shop',
          'debounced': true,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      GlobalErrorHandler.showErrorSnackbar(context, message, errorState.type);
    }, debounceTime: debounceTime);
  }

  /// Validates shop operation preconditions and throws appropriate errors
  static void validateShopOperation({
    required String operation,
    String? itemId,
    String? itemType,
    Map<String, dynamic>? additionalContext,
  }) {
    if (operation.isEmpty) {
      throw ArgumentError('Operation type cannot be empty');
    }

    // Log validation attempt
    ErrorUtils.logError(
      'Shop operation validation',
      context: {
        'operation': operation,
        'itemId': itemId,
        'itemType': itemType,
        'screen': 'shop',
        'validation': true,
        ...?additionalContext,
      },
    );
  }

  /// Gets user-friendly error message for shop-specific errors
  static String getShopErrorMessage(dynamic error, String operation) {
    final baseMessage = ErrorUtils.formatErrorMessage(error);

    switch (operation) {
      case 'cart':
        return 'Unable to add item to cart: $baseMessage';
      case 'purchase':
        return 'Purchase failed: $baseMessage';
      case 'loading':
        return 'Failed to load shop items: $baseMessage';
      default:
        return baseMessage;
    }
  }
}
