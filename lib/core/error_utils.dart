import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/core/error_constants.dart';
import 'package:emotion_tracker/core/error_state.dart';
import 'package:emotion_tracker/core/global_error_handler.dart';
import 'package:emotion_tracker/core/session_manager.dart';

/// Utility class providing common error handling operations and helper functions
class ErrorUtils {
  /// Formats error messages for user display
  /// Removes technical details and provides user-friendly messages
  static String formatErrorMessage(dynamic error, {String? fallback}) {
    if (error == null) {
      return fallback ?? ErrorConstants.unknown;
    }

    // Handle ErrorState objects
    if (error is ErrorState) {
      return error.message;
    }

    // Handle common exception types
    if (error is TimeoutException) {
      return ErrorConstants.timeout;
    }

    if (error is FormatException) {
      return 'Invalid data format received from server.';
    }

    // Extract message from exception objects
    String message = '';
    if (error is Exception) {
      message = error.toString();
      // Remove "Exception: " prefix if present
      if (message.startsWith('Exception: ')) {
        message = message.substring(11);
      }
    } else {
      message = error.toString();
    }

    // Clean up common technical messages
    message = _cleanTechnicalMessage(message);

    return message.isNotEmpty ? message : (fallback ?? ErrorConstants.unknown);
  }

  /// Cleans technical error messages to be more user-friendly
  static String _cleanTechnicalMessage(String message) {
    // Remove common technical prefixes
    final prefixesToRemove = [
      'HttpException: ',
      'SocketException: ',
      'HandshakeException: ',
      'ClientException: ',
      'FormatException: ',
    ];

    String cleaned = message;
    for (final prefix in prefixesToRemove) {
      if (cleaned.startsWith(prefix)) {
        cleaned = cleaned.substring(prefix.length);
        break;
      }
    }

    // Replace technical terms with user-friendly ones
    final replacements = {
      'Connection refused': ErrorConstants.connectionRefused,
      'No route to host': ErrorConstants.noInternet,
      'Network is unreachable': ErrorConstants.noInternet,
      'Connection timed out': ErrorConstants.timeout,
      'Certificate verify failed': 'Security certificate error occurred.',
      'Bad certificate': 'Security certificate error occurred.',
    };

    for (final entry in replacements.entries) {
      if (cleaned.contains(entry.key)) {
        cleaned = entry.value;
        break;
      }
    }

    return cleaned;
  }

  /// Determines the severity level of an error for logging purposes
  static ErrorSeverity getErrorSeverity(dynamic error) {
    if (error is ErrorState) {
      switch (error.type) {
        case ErrorType.unauthorized:
          return ErrorSeverity.warning;
        case ErrorType.rateLimited:
          return ErrorSeverity.warning;
        case ErrorType.networkError:
          return ErrorSeverity.error;
        case ErrorType.serverError:
          return ErrorSeverity.error;
        case ErrorType.cloudflareError:
          return ErrorSeverity.critical;
        case ErrorType.generic:
          return ErrorSeverity.error;
      }
    }

    // Default severity based on error type
    if (error is TimeoutException) {
      return ErrorSeverity.warning;
    }
    if (error is FormatException) {
      return ErrorSeverity.error;
    }

    return ErrorSeverity.error;
  }

  /// Logs error with appropriate level and context information
  /// Prepares for future analytics integration
  static void logError(
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? userId,
    String? sessionId,
  }) {
    final severity = getErrorSeverity(error);
    final formattedMessage = formatErrorMessage(error);
    final timestamp = DateTime.now().toIso8601String();

    // Create structured log entry
    final logEntry = {
      'timestamp': timestamp,
      'severity': severity.name,
      'message': formattedMessage,
      'originalError': error.toString(),
      'stackTrace': stackTrace?.toString(),
      'context': context,
      'userId': userId,
      'sessionId': sessionId,
    };

    // Log to console in debug mode
    if (kDebugMode) {
      final logMessage =
          'ERROR [${severity.name.toUpperCase()}]: $formattedMessage';
      switch (severity) {
        case ErrorSeverity.info:
          developer.log(logMessage, name: 'ErrorUtils');
          break;
        case ErrorSeverity.warning:
          developer.log(logMessage, name: 'ErrorUtils', level: 900);
          break;
        case ErrorSeverity.error:
          developer.log(logMessage, name: 'ErrorUtils', level: 1000);
          break;
        case ErrorSeverity.critical:
          developer.log(logMessage, name: 'ErrorUtils', level: 1200);
          break;
      }

      if (stackTrace != null) {
        developer.log('Stack trace: $stackTrace', name: 'ErrorUtils');
      }
    }

    // TODO: Send to analytics service in production
    // This is where you would integrate with services like:
    // - Firebase Crashlytics
    // - Sentry
    // - Custom analytics endpoint
    _prepareForAnalytics(logEntry);
  }

  /// Prepares error data for analytics services
  /// This method can be extended to integrate with specific analytics providers
  static void _prepareForAnalytics(Map<String, dynamic> logEntry) {
    // TODO: Implement analytics integration
    // Example integrations:

    // Firebase Crashlytics:
    // FirebaseCrashlytics.instance.recordError(
    //   logEntry['originalError'],
    //   logEntry['stackTrace'],
    //   fatal: logEntry['severity'] == 'critical',
    // );

    // Sentry:
    // Sentry.captureException(
    //   logEntry['originalError'],
    //   stackTrace: logEntry['stackTrace'],
    // );

    // Custom analytics:
    // AnalyticsService.trackError(logEntry);
  }

  /// Creates a retry mechanism with exponential backoff
  /// Returns a Future that completes when retry should be attempted
  static Future<void> createRetryDelay(int retryCount, ErrorType errorType) {
    Duration delay;

    switch (errorType) {
      case ErrorType.rateLimited:
        // Longer delay for rate limiting with linear backoff
        delay = Duration(seconds: (retryCount + 1) * 5);
        break;
      case ErrorType.networkError:
      case ErrorType.serverError:
      case ErrorType.cloudflareError:
        // Exponential backoff for other retryable errors
        delay = Duration(seconds: (1 << retryCount).clamp(1, 30));
        break;
      default:
        delay = ErrorConstants.retryDelay;
    }

    return Future.delayed(delay);
  }

  /// Executes a function with automatic retry logic
  /// Handles common error scenarios and implements retry strategies
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    bool Function(dynamic error)? shouldRetry,
    void Function(dynamic error, int retryCount)? onRetry,
    void Function(dynamic error, StackTrace? stackTrace)? onError,
  }) async {
    int retryCount = 0;
    dynamic lastError;
    StackTrace? lastStackTrace;

    while (retryCount <= maxRetries) {
      try {
        return await operation();
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;

        // Log the error
        logError(
          error,
          stackTrace: stackTrace,
          context: {'retryCount': retryCount, 'maxRetries': maxRetries},
        );

        // Check if we should retry
        final defaultShouldRetry = _shouldRetryByDefault(error);
        final customShouldRetry = shouldRetry?.call(error) ?? true;

        if (retryCount >= maxRetries ||
            !(defaultShouldRetry && customShouldRetry)) {
          onError?.call(error, stackTrace);
          rethrow;
        }

        // Notify about retry attempt
        onRetry?.call(error, retryCount);

        // Wait before retrying
        final errorState = GlobalErrorHandler.processError(error);
        await createRetryDelay(retryCount, errorState.type);

        retryCount++;
      }
    }

    // This should never be reached, but just in case
    onError?.call(lastError, lastStackTrace);
    throw lastError;
  }

  /// Determines if an error should be retried by default
  static bool _shouldRetryByDefault(dynamic error) {
    final errorState = GlobalErrorHandler.processError(error);
    return GlobalErrorHandler.isRetryable(errorState);
  }

  /// Handles errors in a standardized way across the application
  /// Processes error, logs it, and returns appropriate ErrorState
  static ErrorState handleError(
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? userId,
    String? sessionId,
  }) {
    // Log the error
    logError(
      error,
      stackTrace: stackTrace,
      context: context,
      userId: userId,
      sessionId: sessionId,
    );

    // Process error into ErrorState
    return GlobalErrorHandler.processError(error);
  }

  /// Handles session-related errors automatically
  /// Integrates with SessionManager for consistent session handling
  static Future<void> handleSessionError(
    BuildContext context,
    WidgetRef ref,
    dynamic error, {
    StackTrace? stackTrace,
  }) async {
    // Log the session error
    logError(
      error,
      stackTrace: stackTrace,
      context: {'errorType': 'session', 'action': 'auto_logout'},
    );

    // Handle session expiry
    if (SessionManager.isSessionExpired(error)) {
      await SessionManager.handleSessionExpiry(context, ref);
    }
  }

  /// Creates a safe error handler that won't throw exceptions
  /// Useful for error boundaries and critical error handling
  static void safeErrorHandler(
    dynamic error, {
    StackTrace? stackTrace,
    String? fallbackMessage,
    void Function(String message)? onSafeError,
  }) {
    try {
      final message = formatErrorMessage(error, fallback: fallbackMessage);
      logError(
        error,
        stackTrace: stackTrace,
        context: {'handler': 'safe', 'fallbackUsed': fallbackMessage != null},
      );
      onSafeError?.call(message);
    } catch (handlerError) {
      // Even the error handler failed - use absolute fallback
      final safeMessage = fallbackMessage ?? 'An unexpected error occurred';
      onSafeError?.call(safeMessage);

      // Log to console as last resort
      if (kDebugMode) {
        developer.log(
          'CRITICAL: Error handler failed: $handlerError',
          name: 'ErrorUtils',
          level: 1200,
        );
      }
    }
  }

  /// Validates error recovery conditions
  /// Determines if error recovery should be attempted
  static bool canRecover(ErrorState errorState, int previousAttempts) {
    // Don't attempt recovery for unauthorized errors
    if (errorState.type == ErrorType.unauthorized) {
      return false;
    }

    // Check retry limits
    if (previousAttempts >= ErrorConstants.maxRetries) {
      return false;
    }

    // Check if error type supports recovery
    return GlobalErrorHandler.isRetryable(errorState);
  }

  /// Creates error recovery strategy based on error type
  /// Returns a function that can be called to attempt recovery
  static Future<void> Function()? createRecoveryStrategy(
    ErrorState errorState,
    Future<void> Function() originalOperation,
    int attemptCount,
  ) {
    if (!canRecover(errorState, attemptCount)) {
      return null;
    }

    return () async {
      // Wait for appropriate delay
      await createRetryDelay(attemptCount, errorState.type);

      // Log recovery attempt
      logError(
        'Recovery attempt',
        context: {
          'errorType': errorState.type.name,
          'attemptCount': attemptCount,
          'originalMessage': errorState.message,
        },
      );

      // Execute original operation
      await originalOperation();
    };
  }

  /// Extracts user-actionable information from errors
  /// Provides suggestions for users on how to resolve issues
  static String? getUserActionSuggestion(ErrorState errorState) {
    switch (errorState.type) {
      case ErrorType.networkError:
        return 'Please check your internet connection and try again.';
      case ErrorType.rateLimited:
        return 'Please wait a moment before trying again.';
      case ErrorType.serverError:
        return 'This appears to be a temporary server issue. Please try again in a few minutes.';
      case ErrorType.cloudflareError:
        return 'The server is temporarily unavailable. Please try again later.';
      case ErrorType.unauthorized:
        return 'Please log in again to continue.';
      case ErrorType.generic:
        return 'Please try again. If the problem persists, contact support.';
    }
  }

  /// Checks if an error indicates a critical system failure
  /// Used to determine if additional error handling measures are needed
  static bool isCriticalError(dynamic error) {
    final severity = getErrorSeverity(error);
    return severity == ErrorSeverity.critical;
  }

  /// Creates a debounced error handler to prevent error spam
  /// Useful for preventing multiple error dialogs from the same source
  static void Function(dynamic error) createDebouncedErrorHandler(
    void Function(dynamic error) handler, {
    Duration debounceTime = const Duration(milliseconds: 500),
  }) {
    Timer? debounceTimer;
    String? lastErrorMessage;

    return (dynamic error) {
      // Cancel previous timer
      debounceTimer?.cancel();

      // Get error message for comparison
      final errorMessage = formatErrorMessage(error);

      // Check if it's the same error message
      if (lastErrorMessage == errorMessage) {
        return; // Skip duplicate error
      }

      lastErrorMessage = errorMessage;
      debounceTimer = Timer(debounceTime, () {
        handler(error);
        lastErrorMessage = null;
      });
    };
  }
}

/// Enumeration of error severity levels for logging and analytics
enum ErrorSeverity { info, warning, error, critical }
