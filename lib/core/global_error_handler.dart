import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/core/error_constants.dart';
import 'package:emotion_tracker/core/error_state.dart';
import 'package:emotion_tracker/core/session_manager.dart';
import 'package:emotion_tracker/providers/api_token_service.dart';
import 'package:emotion_tracker/utils/http_util.dart';

/// Global error handler service that processes and categorizes all application errors
class GlobalErrorHandler {
  /// Processes any error and returns an appropriate ErrorState
  static ErrorState processError(dynamic error) {
    if (error is UnauthorizedException) {
      return _createUnauthorizedError(error);
    } else if (error is RateLimitException) {
      return _createRateLimitError(error);
    } else if (error is CloudflareTunnelException) {
      return _createCloudflareError(error);
    } else if (error is NetworkException) {
      return _createNetworkError(error);
    } else if (error is ApiException) {
      return _createApiError(error);
    } else {
      return _createGenericError(error);
    }
  }

  /// Creates an ErrorState for UnauthorizedException
  static ErrorState _createUnauthorizedError(UnauthorizedException error) {
    final config = ErrorConfigs.getConfig(ErrorType.unauthorized);
    return ErrorState.fromConfig(
      type: ErrorType.unauthorized,
      config: config,
      title: ErrorConstants.unauthorizedTitle,
      message: ErrorConstants.sessionExpired,
      metadata: {'originalError': error},
    );
  }

  /// Creates an ErrorState for RateLimitException
  static ErrorState _createRateLimitError(RateLimitException error) {
    final config = ErrorConfigs.getConfig(ErrorType.rateLimited);
    return ErrorState.fromConfig(
      type: ErrorType.rateLimited,
      config: config,
      title: ErrorConstants.rateLimitTitle,
      message: error.message.isNotEmpty
          ? error.message
          : ErrorConstants.rateLimited,
      metadata: {'originalError': error},
    );
  }

  /// Creates an ErrorState for CloudflareTunnelException
  static ErrorState _createCloudflareError(CloudflareTunnelException error) {
    final config = ErrorConfigs.getConfig(ErrorType.cloudflareError);
    return ErrorState.fromConfig(
      type: ErrorType.cloudflareError,
      config: config,
      title: ErrorConstants.cloudflareTitle,
      message: error.message.isNotEmpty
          ? error.message
          : ErrorConstants.cloudflareDown,
      metadata: {
        'originalError': error,
        'statusCode': error.statusCode,
        'responseBody': error.responseBody,
      },
    );
  }

  /// Creates an ErrorState for NetworkException
  static ErrorState _createNetworkError(NetworkException error) {
    final config = ErrorConfigs.getConfig(ErrorType.networkError);
    return ErrorState.fromConfig(
      type: ErrorType.networkError,
      config: config,
      title: ErrorConstants.networkTitle,
      message: error.message.isNotEmpty
          ? error.message
          : ErrorConstants.networkError,
      metadata: {'originalError': error},
    );
  }

  /// Creates an ErrorState for ApiException with status code handling
  static ErrorState _createApiError(ApiException error) {
    final statusCode = error.statusCode;

    // Determine error type and message based on status code
    if (statusCode == 401) {
      // This should have been caught as UnauthorizedException, but handle it anyway
      return _createUnauthorizedError(UnauthorizedException(error.message));
    } else if (statusCode == 429) {
      // This should have been caught as RateLimitException, but handle it anyway
      return _createRateLimitError(RateLimitException(error.message));
    } else if (statusCode != null && statusCode >= 500) {
      // Server errors
      final config = ErrorConfigs.getConfig(ErrorType.serverError);
      String message = _getServerErrorMessage(statusCode, error.message);

      return ErrorState.fromConfig(
        type: ErrorType.serverError,
        config: config,
        title: ErrorConstants.serverTitle,
        message: message,
        metadata: {'originalError': error, 'statusCode': statusCode},
      );
    } else {
      // Client errors (4xx) or other errors
      final config = ErrorConfigs.getConfig(ErrorType.generic);
      String message = _getClientErrorMessage(statusCode, error.message);

      return ErrorState.fromConfig(
        type: ErrorType.generic,
        config: config,
        title: ErrorConstants.genericTitle,
        message: message,
        metadata: {'originalError': error, 'statusCode': statusCode},
      );
    }
  }

  /// Creates an ErrorState for generic/unknown errors
  static ErrorState _createGenericError(dynamic error) {
    final config = ErrorConfigs.getConfig(ErrorType.generic);
    return ErrorState.fromConfig(
      type: ErrorType.generic,
      config: config,
      title: ErrorConstants.genericTitle,
      message: ErrorConstants.unknown,
      metadata: {'originalError': error},
    );
  }

  /// Gets appropriate server error message based on status code
  static String _getServerErrorMessage(int statusCode, String originalMessage) {
    switch (statusCode) {
      case 500:
        return 'Internal server error occurred. Please try again later.';
      case 502:
        return 'Bad gateway error. The server is temporarily unavailable.';
      case 503:
        return ErrorConstants.serviceUnavailable;
      case 504:
        return ErrorConstants.gatewayTimeout;
      default:
        return originalMessage.isNotEmpty
            ? originalMessage
            : ErrorConstants.serverError;
    }
  }

  /// Gets appropriate client error message based on status code
  static String _getClientErrorMessage(
    int? statusCode,
    String originalMessage,
  ) {
    if (statusCode == null) {
      return originalMessage.isNotEmpty
          ? originalMessage
          : ErrorConstants.unknown;
    }

    switch (statusCode) {
      case 400:
        return originalMessage.isNotEmpty
            ? originalMessage
            : ErrorConstants.badRequest;
      case 403:
        return ErrorConstants.accessDenied;
      case 404:
        return ErrorConstants.notFound;
      case 422:
        return originalMessage.isNotEmpty
            ? 'Invalid data: $originalMessage'
            : ErrorConstants.badRequest;
      default:
        return originalMessage.isNotEmpty
            ? originalMessage
            : ErrorConstants.unknown;
    }
  }

  /// Handles unauthorized errors by delegating to SessionManager
  /// Uses the new SessionManager for consistent session handling
  static Future<void> handleUnauthorized(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await SessionManager.handleSessionExpiry(context, ref);
  }

  /// Shows an error snackbar with appropriate styling
  static void showErrorSnackbar(
    BuildContext context,
    String message,
    ErrorType type,
  ) {
    final config = ErrorConfigs.getConfig(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(config.icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: config.color,
        duration: ErrorConstants.snackbarDuration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Determines if an error is retryable
  static bool isRetryable(ErrorState errorState) {
    switch (errorState.type) {
      case ErrorType.unauthorized:
        return false; // Don't retry unauthorized errors
      case ErrorType.rateLimited:
      case ErrorType.networkError:
      case ErrorType.serverError:
      case ErrorType.cloudflareError:
      case ErrorType.generic:
        return true;
    }
  }

  /// Gets retry delay based on error type
  static Duration getRetryDelay(ErrorState errorState, int retryCount) {
    switch (errorState.type) {
      case ErrorType.rateLimited:
        // Longer delay for rate limiting
        return Duration(seconds: (retryCount + 1) * 5);
      case ErrorType.networkError:
      case ErrorType.serverError:
      case ErrorType.cloudflareError:
        // Exponential backoff for other retryable errors
        return Duration(seconds: (1 << retryCount).clamp(1, 30));
      case ErrorType.unauthorized:
        // These errors are not retryable, but return default delay just in case
        return ErrorConstants.retryDelay;
      case ErrorType.generic:
        return ErrorConstants.retryDelay;
    }
  }

  /// Checks if the maximum retry count has been reached
  static bool hasExceededMaxRetries(int retryCount) {
    return retryCount >= ErrorConstants.maxRetries;
  }
}
