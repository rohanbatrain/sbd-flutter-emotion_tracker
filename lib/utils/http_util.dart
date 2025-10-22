import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:emotion_tracker/core/global_error_handler.dart';
import 'package:emotion_tracker/core/error_state.dart';
import 'package:emotion_tracker/core/session_manager.dart';
import 'package:emotion_tracker/core/exceptions.dart' as core_exceptions;

/// HTTP utility class that wraps all HTTP requests with Cloudflare tunnel error detection
class HttpUtil {
  /// Common method to handle HTTP requests with error detection
  static Future<http.Response> _performRequest(
    Future<http.Response> Function() requestFunction, {
    Duration? timeout,
  }) async {
    try {
      final response = await requestFunction().timeout(
        timeout ?? const Duration(seconds: 30),
      );
      _checkCloudflareErrors(response);
      return response;
    } catch (e) {
      // Log the underlying error and stacktrace to help diagnose network issues
      // (e.g., DNS failure, TLS, socket errors). This does not change error
      // semantics but makes debugging easier in development.
      try {
        // ignore: avoid_print
        print('[HttpUtil] request failed: $e');
      } catch (_) {}
      try {
        // ignore: avoid_print
        print(StackTrace.current);
      } catch (_) {}
      if (e is CloudflareTunnelException) {
        rethrow;
      }
      throw _handleNetworkError(e);
    }
  }

  /// Asserts that User-Agent headers are present (throws in release mode)
  static void _assertUserAgent(Map<String, String>? headers) {
    assert(
      headers != null &&
          headers['User-Agent'] != null &&
          headers['X-User-Agent'] != null,
      'User-Agent and X-User-Agent must be set in all API requests!',
    );
    if (headers == null ||
        headers['User-Agent'] == null ||
        headers['X-User-Agent'] == null) {
      throw ArgumentError(
        'User-Agent and X-User-Agent must be set in all API requests!',
      );
    }
  }

  /// Performs an HTTP GET request with Cloudflare error detection
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    _assertUserAgent(headers);
    return _performRequest(
      () => http.get(url, headers: headers),
      timeout: timeout,
    );
  }

  /// Performs an HTTP POST request with Cloudflare error detection
  /// Includes manual redirect handling for macOS compatibility
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
    bool followRedirects = true,
  }) async {
    _assertUserAgent(headers);

    print('[HttpUtil] POST request to: $url');
    print(
      '[HttpUtil] URL scheme: ${url.scheme}, host: ${url.host}, path: ${url.path}',
    );

    // Make the initial POST request
    var response = await _performRequest(
      () => http.post(url, headers: headers, body: body, encoding: encoding),
      timeout: timeout,
    );

    // Skip redirect handling if explicitly disabled
    if (!followRedirects) {
      return response;
    }

    // Handle redirects manually for POST requests (important for macOS)
    // The http package doesn't automatically follow redirects for POST by design
    var redirectCount = 0;
    const maxRedirects = 5;

    while ((response.statusCode == 301 ||
            response.statusCode == 302 ||
            response.statusCode == 303 ||
            response.statusCode == 307 ||
            response.statusCode == 308) &&
        redirectCount < maxRedirects) {
      final location = response.headers['location'];
      if (location == null || location.isEmpty) {
        // No location header, can't redirect
        break;
      }

      print('[HttpUtil] Following redirect ${redirectCount + 1}: $location');

      // Parse the redirect URL (might be relative or absolute)
      Uri redirectUri;
      if (location.startsWith('http://') || location.startsWith('https://')) {
        redirectUri = Uri.parse(location);
      } else {
        // Relative URL - combine with original URL
        redirectUri = url.resolve(location);
      }

      // For API endpoints, always keep POST as POST to preserve the request method
      // Standard HTTP spec says 301/302/303 should change to GET, but modern REST APIs
      // expect POST to remain POST for redirects (especially for authentication endpoints)
      // This ensures login and other POST endpoints work correctly across all platforms
      response = await _performRequest(
        () => http.post(
          redirectUri,
          headers: headers,
          body: body,
          encoding: encoding,
        ),
        timeout: timeout,
      );

      redirectCount++;
    }

    if (redirectCount >= maxRedirects) {
      print('[HttpUtil] ⚠️ Max redirects ($maxRedirects) exceeded');
    }

    return response;
  }

  /// Performs an HTTP PUT request with Cloudflare error detection
  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
  }) async {
    _assertUserAgent(headers);
    return _performRequest(
      () => http.put(url, headers: headers, body: body, encoding: encoding),
      timeout: timeout,
    );
  }

  /// Performs an HTTP DELETE request with Cloudflare error detection
  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
  }) async {
    _assertUserAgent(headers);
    return _performRequest(
      () => http.delete(url, headers: headers, body: body, encoding: encoding),
      timeout: timeout,
    );
  }

  /// Performs an HTTP PATCH request with Cloudflare error detection
  static Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
  }) async {
    _assertUserAgent(headers);
    return _performRequest(
      () => http.patch(url, headers: headers, body: body, encoding: encoding),
      timeout: timeout,
    );
  }

  /// Checks if the response contains Cloudflare tunnel errors
  static void _checkCloudflareErrors(http.Response response) {
    final responseBody = response.body.toLowerCase();
    final cfRay = response.headers['cf-ray'];
    final server = response.headers['server']?.toLowerCase();

    // Helper method to check if response has Cloudflare indicators
    bool hasCloudflareIndicators() {
      return cfRay != null ||
          server?.contains('cloudflare') == true ||
          responseBody.contains('cloudflare') ||
          responseBody.contains('performance & security by cloudflare');
    }

    // Check for specific error codes
    switch (response.statusCode) {
      case 502:
        if (hasCloudflareIndicators() ||
            responseBody.contains('bad gateway') &&
                responseBody.contains('web server')) {
          throw CloudflareTunnelException(
            'Bad Gateway (Error 502): The server is temporarily unavailable. This is likely a Cloudflare tunnel issue.',
            response.statusCode,
            response.body,
          );
        }
        break;

      case 503:
      case 504:
        if (hasCloudflareIndicators() ||
            responseBody.contains('service unavailable') ||
            responseBody.contains('gateway timeout')) {
          throw CloudflareTunnelException(
            'Service temporarily unavailable (Error ${response.statusCode}). The Cloudflare tunnel may be down.',
            response.statusCode,
            response.body,
          );
        }
        break;

      case 522:
      case 523:
      case 524:
        throw CloudflareTunnelException(
          'Server connection timeout (Cloudflare Error ${response.statusCode}). The tunnel may be down.',
          response.statusCode,
          response.body,
        );

      case 530:
        throw CloudflareTunnelException(
          'Origin DNS Error (Error 530): Cloudflare cannot resolve the server DNS. The server configuration may need attention. This typically indicates that the cloudflared tunnel service has lost connectivity to Cloudflare servers.',
          response.statusCode,
          response.body,
        );
    }

    // Check for Cloudflare Error 1033 and tunnel-specific errors
    if (responseBody.contains('error 1033') ||
        responseBody.contains('cloudflare') &&
            responseBody.contains('tunnel') ||
        responseBody.contains('argo tunnel error') ||
        responseBody.contains('tunnel connection failed')) {
      throw CloudflareTunnelException(
        'The server tunnel is currently down (Cloudflare Error 1033). Please try again later.',
        response.statusCode,
        response.body,
      );
    }

    // Additional check for Cloudflare-specific 5xx errors with tunnel indicators
    if (hasCloudflareIndicators() &&
        response.statusCode >= 500 &&
        response.statusCode < 600) {
      if (responseBody.contains('tunnel') ||
          responseBody.contains('origin') &&
              responseBody.contains('unreachable') ||
          responseBody.contains('connection failed') ||
          responseBody.contains('gateway timeout') &&
              responseBody.contains('cloudflare')) {
        throw CloudflareTunnelException(
          'The server tunnel appears to be down. Please try again later.',
          response.statusCode,
          response.body,
        );
      }
    }
  }

  /// Handles network-related errors and converts them to user-friendly exceptions
  static Exception _handleNetworkError(dynamic error) {
    final errorMsg = error.toString().toLowerCase();

    if (errorMsg.contains('timeout') || errorMsg.contains('timed out')) {
      return NetworkException(
        'Request timed out. Please check your connection and try again.',
      );
    } else if (errorMsg.contains('no internet') ||
        errorMsg.contains('network unreachable')) {
      return NetworkException(
        'No internet connection. Please check your network and try again.',
      );
    } else if (errorMsg.contains('connection refused') ||
        errorMsg.contains('failed to connect')) {
      return NetworkException(
        'Could not connect to server. Please check the server address.',
      );
    }

    return NetworkException('Network error occurred. Please try again.');
  }

  /// Shows a user-friendly error dialog for Cloudflare tunnel errors
  static void showCloudflareErrorDialog(
    BuildContext context,
    CloudflareTunnelException error,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);

        // Helper method to get error details based on status code
        Map<String, dynamic> getErrorDetails(int statusCode) {
          switch (statusCode) {
            case 502:
              return {
                'title': 'Bad Gateway (502)',
                'icon': Icons.warning_rounded,
                'explanation':
                    'The Cloudflare proxy received an invalid response from the server. This typically means the backend server is down or unreachable.',
              };
            case 503:
              return {
                'title': 'Service Unavailable (503)',
                'icon': Icons.build_circle,
                'explanation':
                    'The server is temporarily overloaded or under maintenance. Please wait a few minutes and try again.',
              };
            case 504:
              return {
                'title': 'Gateway Timeout (504)',
                'icon': Icons.timer_off,
                'explanation':
                    'The server took too long to respond. This could indicate server overload or network issues.',
              };
            case 522:
            case 523:
            case 524:
              return {
                'title': 'Cloudflare Connection Error ($statusCode)',
                'icon': Icons.link_off,
                'explanation':
                    'Cloudflare could not establish a connection to the origin server. The tunnel configuration may need attention.',
              };
            case 530:
              return {
                'title': 'Origin DNS Error (530)',
                'icon': Icons.dns_rounded,
                'explanation':
                    'Cloudflare cannot resolve the server DNS. This usually means the server configuration needs to be fixed by the administrator.',
              };
            default:
              return {
                'title': 'Server Connection Issue',
                'icon': Icons.cloud_off,
                'explanation':
                    'The server is temporarily unavailable. This is usually a temporary issue.',
              };
          }
        }

        final errorDetails = getErrorDetails(error.statusCode);
        final title = errorDetails['title'] as String;
        final icon = errorDetails['icon'] as IconData;
        final explanation = errorDetails['explanation'] as String;

        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: Row(
            children: [
              Icon(icon, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(error.message, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withAlpha(75)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'What this means:',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      explanation,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'What you can do:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Wait a few minutes and try again\n• Check if other websites work\n• Try changing server settings if problem persists',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Try Again Later',
                style: TextStyle(color: theme.primaryColor),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Shows a generic network error snackbar
  static void showNetworkErrorSnackbar(
    BuildContext context,
    NetworkException error,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(error.message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            // Caller can provide retry logic
          },
        ),
      ),
    );
  }

  // ========== NEW CENTRALIZED ERROR PROCESSING METHODS ==========

  /// Processes HTTP errors and returns an appropriate ErrorState
  /// This method integrates with the centralized error handling system
  /// while working with existing CloudflareTunnelException and NetworkException
  static ErrorState processHttpError(dynamic error) {
    if (error is core_exceptions.UnauthorizedException) {
      // Optionally trigger redirect here if needed
      // SessionManager.redirectToLogin(context, message: 'Session expired. Please log in again.');
    }
    return GlobalErrorHandler.processError(error);
  }

  /// Shows an HTTP error dialog using the centralized error handling system
  /// This method integrates the existing showCloudflareErrorDialog functionality
  /// into the centralized system while maintaining backward compatibility
  static void showHttpErrorDialog(BuildContext context, dynamic error) {
    if (error is core_exceptions.UnauthorizedException) {
      SessionManager.redirectToLogin(
        context,
        message: 'Session expired. Please log in again.',
      );
      return;
    }

    // Handle CloudflareTunnelException with existing detailed dialog
    if (error is CloudflareTunnelException) {
      showCloudflareErrorDialog(context, error);
      return;
    }

    // Handle NetworkException with existing snackbar
    if (error is NetworkException) {
      showNetworkErrorSnackbar(context, error);
      return;
    }

    // For other errors, use the centralized error processing
    final errorState = processHttpError(error);
    _showGenericErrorDialog(context, errorState);
  }

  /// Shows a generic error dialog for non-Cloudflare/non-Network errors
  /// This provides consistent error display for other HTTP errors
  static void _showGenericErrorDialog(
    BuildContext context,
    ErrorState errorState,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);

        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: Row(
            children: [
              Icon(errorState.icon, color: errorState.color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorState.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: errorState.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(errorState.message, style: theme.textTheme.bodyLarge),
              if (errorState.showInfo && errorState.metadata != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: errorState.color.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: errorState.color.withAlpha(75)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: errorState.color,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Additional Information:',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: errorState.color.withAlpha(200),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (errorState.metadata!['statusCode'] != null)
                        Text(
                          'Status Code: ${errorState.metadata!['statusCode']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: errorState.color.withAlpha(175),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (errorState.showRetry)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Try Again',
                  style: TextStyle(color: theme.primaryColor),
                ),
              ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: errorState.color,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Shows an error snackbar using the centralized error handling system
  /// This provides a consistent way to show error notifications
  static void showHttpErrorSnackbar(
    BuildContext context,
    dynamic error,
    ErrorType errorType,
  ) {
    final errorState = processHttpError(error);
    GlobalErrorHandler.showErrorSnackbar(
      context,
      errorState.message,
      errorType,
    );
  }

  /// Determines if an HTTP error is retryable using the centralized system
  /// This helps maintain consistent retry logic across the application
  static bool isHttpErrorRetryable(dynamic error) {
    final errorState = processHttpError(error);
    return GlobalErrorHandler.isRetryable(errorState);
  }

  /// Gets the appropriate retry delay for an HTTP error
  /// This uses the centralized retry logic for consistent behavior
  static Duration getHttpErrorRetryDelay(dynamic error, int retryCount) {
    final errorState = processHttpError(error);
    return GlobalErrorHandler.getRetryDelay(errorState, retryCount);
  }
}

/// Exception thrown when Cloudflare tunnel errors are detected
class CloudflareTunnelException implements Exception {
  final String message;
  final int statusCode;
  final String responseBody;

  const CloudflareTunnelException(
    this.message,
    this.statusCode,
    this.responseBody,
  );

  @override
  String toString() =>
      'CloudflareTunnelException: $message (Status: $statusCode)';
}

/// Exception thrown for general network errors
class NetworkException implements Exception {
  final String message;

  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}
