import 'package:emotion_tracker/providers/team/team_exceptions.dart';

/// Utility class for mapping TeamApiException types to user-friendly UI messages
class TeamErrorMessages {
  static String getUserFriendlyMessage(dynamic error) {
    if (error is TeamApiException) {
      return _mapTeamApiException(error);
    } else if (error is Exception) {
      return 'An unexpected error occurred: ${error.toString()}';
    } else {
      return 'An unknown error occurred';
    }
  }

  static String _mapTeamApiException(TeamApiException exception) {
    // Handle specific exception types
    if (exception is PermissionDeniedException) {
      return 'You don\'t have permission to perform this action. Please contact your workspace administrator.';
    }

    if (exception is RateLimitException) {
      return 'Too many requests. Please wait a moment before trying again.';
    }

    if (exception is ValidationException) {
      return 'Invalid input: ${exception.message}';
    }

    if (exception is WorkspaceNotFoundException) {
      return 'Workspace not found. It may have been deleted or you may not have access.';
    }

    if (exception is WalletNotFoundException) {
      return 'Team wallet not found. Please initialize the wallet first.';
    }

    if (exception is InsufficientFundsException) {
      return 'Insufficient funds in the team wallet.';
    }

    if (exception is NetworkException) {
      return 'Network error. Please check your connection and try again.';
    }

    // Handle HTTP status codes
    if (exception.statusCode != null) {
      switch (exception.statusCode) {
        case 400:
          return 'Invalid request. Please check your input and try again.';
        case 401:
          return 'Authentication failed. Please log in again.';
        case 403:
          return 'Access denied. You don\'t have permission for this action.';
        case 404:
          return 'The requested resource was not found.';
        case 409:
          return 'Conflict: This action cannot be completed due to a conflict.';
        case 422:
          return 'Validation failed. Please check your input.';
        case 429:
          return 'Too many requests. Please wait before trying again.';
        case 500:
          return 'Server error. Please try again later.';
        case 502:
        case 503:
        case 504:
          return 'Service temporarily unavailable. Please try again later.';
        default:
          return 'An error occurred (${exception.statusCode}). Please try again.';
      }
    }

    // Default message for generic TeamApiException
    return exception.message.isNotEmpty
        ? exception.message
        : 'An error occurred. Please try again.';
  }

  /// Get a title for error dialogs based on the error type
  static String getErrorTitle(dynamic error) {
    if (error is PermissionDeniedException) {
      return 'Permission Denied';
    }

    if (error is RateLimitException) {
      return 'Rate Limit Exceeded';
    }

    if (error is ValidationException) {
      return 'Invalid Input';
    }

    if (error is NetworkException) {
      return 'Connection Error';
    }

    if (error is TeamApiException && error.statusCode != null) {
      if (error.statusCode! >= 500) {
        return 'Server Error';
      }
      if (error.statusCode! >= 400) {
        return 'Request Error';
      }
    }

    return 'Error';
  }

  /// Determine if an error should show a retry button
  static bool shouldShowRetry(dynamic error) {
    if (error is NetworkException) {
      return true;
    }

    if (error is TeamApiException) {
      // Retry for server errors, rate limits, and some client errors
      final statusCode = error.statusCode;
      return statusCode == null ||
          statusCode >= 500 ||
          statusCode == 429 ||
          statusCode == 408 ||
          statusCode == 503;
    }

    return false;
  }
}
