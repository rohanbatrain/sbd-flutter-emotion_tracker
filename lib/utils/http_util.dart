import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

/// HTTP utility class that wraps all HTTP requests with Cloudflare tunnel error detection
class HttpUtil {
  
  /// Performs an HTTP GET request with Cloudflare error detection
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final response = await http.get(
        url,
        headers: headers,
      ).timeout(timeout ?? const Duration(seconds: 30));
      
      _checkCloudflareErrors(response);
      return response;
    } catch (e) {
      if (e is CloudflareTunnelException) {
        rethrow;
      }
      throw _handleNetworkError(e);
    }
  }

  /// Performs an HTTP POST request with Cloudflare error detection
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
  }) async {
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
        encoding: encoding,
      ).timeout(timeout ?? const Duration(seconds: 30));
      
      _checkCloudflareErrors(response);
      return response;
    } catch (e) {
      if (e is CloudflareTunnelException) {
        rethrow;
      }
      throw _handleNetworkError(e);
    }
  }

  /// Performs an HTTP PUT request with Cloudflare error detection
  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
  }) async {
    try {
      final response = await http.put(
        url,
        headers: headers,
        body: body,
        encoding: encoding,
      ).timeout(timeout ?? const Duration(seconds: 30));
      
      _checkCloudflareErrors(response);
      return response;
    } catch (e) {
      if (e is CloudflareTunnelException) {
        rethrow;
      }
      throw _handleNetworkError(e);
    }
  }

  /// Performs an HTTP DELETE request with Cloudflare error detection
  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
  }) async {
    try {
      final response = await http.delete(
        url,
        headers: headers,
        body: body,
        encoding: encoding,
      ).timeout(timeout ?? const Duration(seconds: 30));
      
      _checkCloudflareErrors(response);
      return response;
    } catch (e) {
      if (e is CloudflareTunnelException) {
        rethrow;
      }
      throw _handleNetworkError(e);
    }
  }

  /// Checks if the response contains Cloudflare tunnel errors
  static void _checkCloudflareErrors(http.Response response) {
    final responseBody = response.body.toLowerCase();
    final cfRay = response.headers['cf-ray'];
    final server = response.headers['server']?.toLowerCase();
    
    // Check for 502 Bad Gateway from Cloudflare (like the error you encountered)
    if (response.statusCode == 502) {
      // Check if it's a Cloudflare 502 error
      if (cfRay != null || 
          server?.contains('cloudflare') == true ||
          responseBody.contains('cloudflare') ||
          responseBody.contains('bad gateway') && responseBody.contains('web server') ||
          responseBody.contains('performance & security by cloudflare')) {
        throw CloudflareTunnelException(
          'Bad Gateway (Error 502): The server is temporarily unavailable. This is likely a Cloudflare tunnel issue.',
          response.statusCode,
          response.body,
        );
      }
    }
    
    // Check for other Cloudflare tunnel errors (503, 504, etc.)
    if (response.statusCode == 503 || response.statusCode == 504) {
      // Check for Cloudflare indicators
      if (cfRay != null || 
          server?.contains('cloudflare') == true ||
          responseBody.contains('cloudflare') ||
          responseBody.contains('service unavailable') ||
          responseBody.contains('gateway timeout')) {
        throw CloudflareTunnelException(
          'Service temporarily unavailable (Error ${response.statusCode}). The Cloudflare tunnel may be down.',
          response.statusCode,
          response.body,
        );
      }
    }
    
    // Check for Cloudflare Error 1033 (tunnel down) and other tunnel errors
    if (responseBody.contains('error 1033') || 
        responseBody.contains('cloudflare') && responseBody.contains('tunnel') ||
        responseBody.contains('argo tunnel error') ||
        responseBody.contains('tunnel connection failed')) {
      throw CloudflareTunnelException(
        'The server tunnel is currently down (Cloudflare Error 1033). Please try again later.',
        response.statusCode,
        response.body,
      );
    }

    // Additional check for Cloudflare-specific 5xx errors with tunnel indicators
    if (cfRay != null && server?.contains('cloudflare') == true) {
      if (response.statusCode >= 500 && response.statusCode < 600) {
        // Check for tunnel-related errors
        if (responseBody.contains('tunnel') || 
            responseBody.contains('origin') && responseBody.contains('unreachable') ||
            responseBody.contains('connection failed') ||
            responseBody.contains('gateway timeout') && responseBody.contains('cloudflare')) {
          throw CloudflareTunnelException(
            'The server tunnel appears to be down. Please try again later.',
            response.statusCode,
            response.body,
          );
        }
      }
    }

    // Check for common Cloudflare error pages
    if (response.statusCode == 522 || response.statusCode == 523 || response.statusCode == 524) {
      throw CloudflareTunnelException(
        'Server connection timeout (Cloudflare Error ${response.statusCode}). The tunnel may be down.',
        response.statusCode,
        response.body,
      );
    }
  }

  /// Handles network-related errors and converts them to user-friendly exceptions
  static Exception _handleNetworkError(dynamic error) {
    final errorMsg = error.toString().toLowerCase();
    
    if (errorMsg.contains('timeout') || errorMsg.contains('timed out')) {
      return NetworkException('Request timed out. Please check your connection and try again.');
    } else if (errorMsg.contains('no internet') || errorMsg.contains('network unreachable')) {
      return NetworkException('No internet connection. Please check your network and try again.');
    } else if (errorMsg.contains('connection refused') || errorMsg.contains('failed to connect')) {
      return NetworkException('Could not connect to server. Please check the server address.');
    }
    
    return NetworkException('Network error occurred. Please try again.');
  }

  /// Shows a user-friendly error dialog for Cloudflare tunnel errors
  static void showCloudflareErrorDialog(BuildContext context, CloudflareTunnelException error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        
        // Determine error details based on status code
        String title = 'Server Connection Issue';
        IconData icon = Icons.cloud_off;
        String explanation = 'The server is temporarily unavailable. This is usually a temporary issue.';
        
        if (error.statusCode == 502) {
          title = 'Bad Gateway (502)';
          icon = Icons.warning_rounded;
          explanation = 'The Cloudflare proxy received an invalid response from the server. This typically means the backend server is down or unreachable.';
        } else if (error.statusCode == 503) {
          title = 'Service Unavailable (503)';
          icon = Icons.build_circle;
          explanation = 'The server is temporarily overloaded or under maintenance. Please wait a few minutes and try again.';
        } else if (error.statusCode == 504) {
          title = 'Gateway Timeout (504)';
          icon = Icons.timer_off;
          explanation = 'The server took too long to respond. This could indicate server overload or network issues.';
        } else if (error.statusCode == 522 || error.statusCode == 523 || error.statusCode == 524) {
          title = 'Cloudflare Connection Error (${error.statusCode})';
          icon = Icons.link_off;
          explanation = 'Cloudflare could not establish a connection to the origin server. The tunnel configuration may need attention.';
        }
        
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: Row(
            children: [
              Icon(
                icon,
                color: Colors.orange,
                size: 24,
              ),
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
              Text(
                error.message,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange, size: 16),
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
  static void showNetworkErrorSnackbar(BuildContext context, NetworkException error) {
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
}

/// Exception thrown when Cloudflare tunnel errors are detected
class CloudflareTunnelException implements Exception {
  final String message;
  final int statusCode;
  final String responseBody;

  const CloudflareTunnelException(this.message, this.statusCode, this.responseBody);

  @override
  String toString() => 'CloudflareTunnelException: $message (Status: $statusCode)';
}

/// Exception thrown for general network errors
class NetworkException implements Exception {
  final String message;

  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}
