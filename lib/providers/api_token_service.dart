import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/utils/http_util.dart';
import 'package:http/http.dart' as http;

const String _accessTokenKey = 'access_token';

final apiTokenServiceProvider = Provider((ref) => ApiTokenService(ref));

// Centralized constants for error messages
class ApiTokenConstants {
  static const String errorSessionExpired =
      'Your session has expired. Please log in again.';
  static const String errorNetwork =
      'Network error: Please check your connection.';
  static const String errorTimeout = 'The request timed out. Please try again.';
  static const String errorUnknown = 'An unknown error occurred.';
  static const String errorTokenNotFound =
      'Token not found or already revoked.';
  static const String errorInvalidDescription =
      'Token description is required and must be valid.';
}

class _Endpoints {
  static const String listTokens = '/auth/permanent-tokens';
  static const String createToken = '/auth/permanent-tokens';
  static String revokeToken(String tokenId) =>
      '/auth/permanent-tokens/$tokenId';
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException: $message (Status code: $statusCode)';
    }
    return 'ApiException: $message';
  }
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  @override
  String toString() => message;
}

class RateLimitException implements Exception {
  final String message;
  RateLimitException(this.message);
  @override
  String toString() => message;
}

class ApiToken {
  final String tokenId;
  final String description;
  final DateTime createdAt;
  final DateTime? lastUsed;
  final bool revoked;
  final String? tokenValue; // Only present during creation

  ApiToken({
    required this.tokenId,
    required this.description,
    required this.createdAt,
    this.lastUsed,
    required this.revoked,
    this.tokenValue,
  });

  factory ApiToken.fromJson(Map<String, dynamic> json) {
    return ApiToken(
      tokenId: json['token_id'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastUsed:
          json['last_used'] != null
              ? DateTime.parse(json['last_used'] as String)
              : null,
      revoked: json['revoked'] as bool? ?? false,
      tokenValue: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token_id': tokenId,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'last_used': lastUsed?.toIso8601String(),
      'revoked': revoked,
      if (tokenValue != null) 'token_value': tokenValue,
    };
  }
}

class ApiTokenService {
  final Ref _ref;

  ApiTokenService(this._ref);

  String get _baseUrl => _ref.read(apiBaseUrlProvider);

  Future<String?> _getAccessToken() async {
    final secureStorage = _ref.read(secureStorageProvider);
    return await secureStorage.read(key: _accessTokenKey);
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAccessToken();
    if (token == null) {
      throw UnauthorizedException(ApiTokenConstants.errorSessionExpired);
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _processResponse(http.Response response) async {
    if (response.statusCode == 401) {
      await _ref.read(authProvider.notifier).logout();
      throw UnauthorizedException(ApiTokenConstants.errorSessionExpired);
    }

    if (response.statusCode == 429) {
      // Handle rate limiting
      String rateLimitMessage =
          'Too many requests. Please wait before trying again.';
      try {
        final responseBody = json.decode(response.body);
        if (responseBody is Map && responseBody.containsKey('detail')) {
          rateLimitMessage = responseBody['detail'];
        }
      } catch (e) {
        // Use default message if parsing fails
      }
      throw RateLimitException(rateLimitMessage);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return json.decode(response.body);
    } else {
      String errorMessage;
      try {
        final responseBody = json.decode(response.body);
        // Prefer 'detail' if present, else fallback to known error messages
        if (responseBody is Map && responseBody.containsKey('detail')) {
          errorMessage = responseBody['detail'];
        } else {
          errorMessage = response.body;
        }
      } catch (e) {
        errorMessage = response.body;
      }

      // Handle specific error codes with user-friendly messages
      switch (response.statusCode) {
        case 404:
          throw ApiException(
            'Token not found or already deleted.',
            response.statusCode,
          );
        case 403:
          throw ApiException(
            'You do not have permission to perform this action.',
            response.statusCode,
          );
        case 422:
          throw ApiException(
            'Invalid request data: $errorMessage',
            response.statusCode,
          );
        case 500:
          throw ApiException(
            'Server error occurred. Please try again later.',
            response.statusCode,
          );
        case 502:
        case 503:
        case 504:
          throw ApiException(
            'Server is temporarily unavailable. Please try again later.',
            response.statusCode,
          );
        default:
          throw ApiException(errorMessage, response.statusCode);
      }
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? data,
    int retryCount = 0,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders();
    http.Response response;
    const timeoutDuration = Duration(seconds: 15);
    const maxRetries = 3;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await HttpUtil.get(
            url,
            headers: headers,
          ).timeout(timeoutDuration);
          break;
        case 'POST':
          response = await HttpUtil.post(
            url,
            headers: headers,
            body: data != null ? json.encode(data) : null,
          ).timeout(timeoutDuration);
          break;
        case 'DELETE':
          response = await HttpUtil.delete(
            url,
            headers: headers,
          ).timeout(timeoutDuration);
          break;
        default:
          throw UnsupportedError('HTTP method $method not supported.');
      }
      return _processResponse(response);
    } on TimeoutException catch (_) {
      if (retryCount < maxRetries) {
        // Exponential backoff: wait 1s, 2s, 4s
        await Future.delayed(Duration(seconds: 1 << retryCount));
        return _request(
          method,
          endpoint,
          data: data,
          retryCount: retryCount + 1,
        );
      }
      throw ApiException(ApiTokenConstants.errorTimeout);
    } on SocketException catch (e) {
      if (retryCount < maxRetries && _isRetryableNetworkError(e)) {
        await Future.delayed(Duration(seconds: 1 << retryCount));
        return _request(
          method,
          endpoint,
          data: data,
          retryCount: retryCount + 1,
        );
      }
      throw ApiException('${ApiTokenConstants.errorNetwork} (${e.message})');
    } on http.ClientException catch (e) {
      if (retryCount < maxRetries && _isRetryableClientError(e)) {
        await Future.delayed(Duration(seconds: 1 << retryCount));
        return _request(
          method,
          endpoint,
          data: data,
          retryCount: retryCount + 1,
        );
      }
      throw ApiException('${ApiTokenConstants.errorNetwork}: ${e.message}');
    } on CloudflareTunnelException catch (e) {
      // Don't retry Cloudflare tunnel errors, they need manual intervention
      throw ApiException('Server tunnel is down: ${e.message}', e.statusCode);
    } on NetworkException catch (e) {
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: 1 << retryCount));
        return _request(
          method,
          endpoint,
          data: data,
          retryCount: retryCount + 1,
        );
      }
      throw ApiException(e.message);
    } catch (e) {
      if (e is ApiException || e is UnauthorizedException) {
        rethrow;
      }
      // For unknown errors, don't retry
      throw ApiException(ApiTokenConstants.errorUnknown);
    }
  }

  /// Determines if a SocketException is retryable
  bool _isRetryableNetworkError(SocketException e) {
    final message = e.message.toLowerCase();
    return message.contains('connection refused') ||
        message.contains('network unreachable') ||
        message.contains('timeout') ||
        message.contains('connection reset');
  }

  /// Determines if a ClientException is retryable
  bool _isRetryableClientError(http.ClientException e) {
    final message = e.message.toLowerCase();
    return message.contains('connection closed') ||
        message.contains('connection aborted') ||
        message.contains('timeout');
  }

  /// List all permanent tokens for the authenticated user
  Future<List<ApiToken>> listTokens() async {
    final response = await _request('GET', _Endpoints.listTokens);

    if (response['tokens'] is List) {
      final tokensList = response['tokens'] as List;
      return tokensList
          .map(
            (tokenJson) => ApiToken.fromJson(tokenJson as Map<String, dynamic>),
          )
          .toList();
    }

    return [];
  }

  /// Create a new permanent token with the given description
  Future<ApiToken> createToken(String description) async {
    final sanitizedDescription = _sanitizeAndValidateDescription(description);

    final response = await _request(
      'POST',
      _Endpoints.createToken,
      data: {'description': sanitizedDescription},
    );

    // Debug: Print the response to see what fields are available
    // print('Create token API response: $response');

    return ApiToken.fromJson(response);
  }

  /// Sanitizes and validates token description input
  String _sanitizeAndValidateDescription(String description) {
    if (description.trim().isEmpty) {
      throw ApiException(ApiTokenConstants.errorInvalidDescription);
    }

    // Trim whitespace and normalize
    String sanitized = description.trim();

    // Remove any potentially dangerous characters
    sanitized = sanitized.replaceAll(RegExp(r'[<>"&]'), '');

    // Check length constraints
    if (sanitized.length < 3) {
      throw ApiException(
        'Token description must be at least 3 characters long.',
      );
    }

    if (sanitized.length > 100) {
      throw ApiException(
        'Token description must be less than 100 characters long.',
      );
    }

    // Check for valid characters (alphanumeric, spaces, hyphens, underscores, periods)
    if (!RegExp(r'^[a-zA-Z0-9\s\-_.]+$').hasMatch(sanitized)) {
      throw ApiException(
        'Token description contains invalid characters. Only letters, numbers, spaces, hyphens, underscores, and periods are allowed.',
      );
    }

    // Prevent descriptions that are only whitespace or special characters
    if (sanitized.replaceAll(RegExp(r'[\s\-_.]'), '').isEmpty) {
      throw ApiException(
        'Token description must contain at least some alphanumeric characters.',
      );
    }

    return sanitized;
  }

  /// Revoke a permanent token by its ID
  Future<void> revokeToken(String tokenId) async {
    if (tokenId.trim().isEmpty) {
      throw ApiException(ApiTokenConstants.errorTokenNotFound);
    }

    await _request('DELETE', _Endpoints.revokeToken(tokenId));
  }
}
