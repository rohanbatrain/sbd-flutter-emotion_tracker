/// Centralized error constants and configurations for the application
/// Consolidates existing ApiTokenConstants and adds new centralized messages
class ErrorConstants {
  // Existing error messages from ApiTokenConstants (consolidated)
  static const String sessionExpired =
      'Your session has expired. Please log in again.';
  static const String networkError =
      'Network error: Please check your connection.';
  static const String timeout = 'The request timed out. Please try again.';
  static const String unknown = 'An unknown error occurred.';
  static const String tokenNotFound = 'Token not found or already revoked.';
  static const String invalidDescription =
      'Token description is required and must be valid.';

  // New centralized error messages
  static const String serverError =
      'The server is experiencing issues. Please try again later.';
  static const String rateLimited =
      'Too many requests. Please wait before trying again.';
  static const String cloudflareDown =
      'Server tunnel is down. Please try again later.';
  static const String accessDenied =
      'You do not have permission to perform this action.';
  static const String notFound = 'The requested resource was not found.';
  static const String badRequest = 'Invalid request data provided.';
  static const String serviceUnavailable =
      'Service is temporarily unavailable.';
  static const String gatewayTimeout = 'Gateway timeout occurred.';
  static const String connectionRefused = 'Could not connect to server.';
  static const String noInternet = 'No internet connection available.';

  // Error Configurations
  static const Duration snackbarDuration = Duration(seconds: 4);
  static const Duration retryDelay = Duration(seconds: 2);
  static const int maxRetries = 3;

  // Error Type Titles
  static const String unauthorizedTitle = 'Session Expired';
  static const String rateLimitTitle = 'Rate Limited';
  static const String networkTitle = 'Connection Problem';
  static const String serverTitle = 'Server Error';
  static const String cloudflareTitle = 'Server Unavailable';
  static const String genericTitle = 'Error';
}
