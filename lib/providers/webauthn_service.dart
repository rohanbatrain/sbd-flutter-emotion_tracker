import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:emotion_tracker/core/error_constants.dart';
import 'package:emotion_tracker/models/webauthn_models.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:emotion_tracker/providers/api_token_service.dart' as api_token;
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/utils/http_util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

const String _accessTokenKey = 'access_token';

final webAuthnServiceProvider = Provider((ref) => WebAuthnService(ref));

class _Endpoints {
  static const String beginAuthentication = '/auth/webauthn/authenticate/begin';
  static const String completeAuthentication =
      '/auth/webauthn/authenticate/complete';
  static const String beginRegistration = '/auth/webauthn/register/begin';
  static const String completeRegistration = '/auth/webauthn/register/complete';
  static const String listCredentials = '/auth/webauthn/credentials';
  static String deleteCredential(String credentialId) =>
      '/auth/webauthn/credentials/$credentialId';
}

class WebAuthnService {
  final Ref _ref;

  WebAuthnService(this._ref);

  String get _baseUrl => _ref.read(apiBaseUrlProvider);

  Future<String?> _getAccessToken() async {
    final secureStorage = _ref.read(secureStorageProvider);
    return await secureStorage.read(key: _accessTokenKey);
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAccessToken();
    if (token == null) {
      throw api_token.UnauthorizedException(ErrorConstants.sessionExpired);
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, String>> _getPublicHeaders() async {
    return {'Content-Type': 'application/json'};
  }

  Future<Map<String, dynamic>> _processResponse(http.Response response) async {
    if (response.statusCode == 401) {
      // Handle session expiry using existing SessionManager patterns
      await _ref.read(authProvider.notifier).logout();
      throw api_token.UnauthorizedException(ErrorConstants.sessionExpired);
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
      throw api_token.RateLimitException(rateLimitMessage);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return json.decode(response.body);
    } else {
      String errorMessage;
      String? flutterCode;
      try {
        final responseBody = json.decode(response.body);
        // Prefer 'detail' if present, else fallback to known error messages
        if (responseBody is Map && responseBody.containsKey('detail')) {
          errorMessage = responseBody['detail'];
          flutterCode = responseBody['flutter_code'];
        } else {
          errorMessage = response.body;
        }
      } catch (e) {
        errorMessage = response.body;
      }

      // Handle specific error codes with user-friendly messages
      switch (response.statusCode) {
        case 404:
          throw WebAuthnException(
            'Passkey not found or already deleted.',
            statusCode: response.statusCode,
            flutterCode: flutterCode,
          );
        case 403:
          throw WebAuthnException(
            'You do not have permission to perform this action.',
            statusCode: response.statusCode,
            flutterCode: flutterCode,
          );
        case 422:
          throw WebAuthnException(
            'Invalid request data: $errorMessage',
            statusCode: response.statusCode,
            flutterCode: flutterCode,
          );
        case 500:
          throw WebAuthnException(
            'Server error occurred. Please try again later.',
            statusCode: response.statusCode,
            flutterCode: flutterCode,
          );
        case 502:
        case 503:
        case 504:
          throw WebAuthnException(
            'Server is temporarily unavailable. Please try again later.',
            statusCode: response.statusCode,
            flutterCode: flutterCode,
          );
        default:
          throw WebAuthnException(
            errorMessage,
            statusCode: response.statusCode,
            flutterCode: flutterCode,
          );
      }
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? data,
    bool requiresAuth = true,
    int retryCount = 0,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers =
        requiresAuth ? await _getHeaders() : await _getPublicHeaders();
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
          requiresAuth: requiresAuth,
          retryCount: retryCount + 1,
        );
      }
      throw WebAuthnException(ErrorConstants.timeout);
    } on SocketException catch (e) {
      if (retryCount < maxRetries && _isRetryableNetworkError(e)) {
        await Future.delayed(Duration(seconds: 1 << retryCount));
        return _request(
          method,
          endpoint,
          data: data,
          requiresAuth: requiresAuth,
          retryCount: retryCount + 1,
        );
      }
      throw WebAuthnException('${ErrorConstants.networkError} (${e.message})');
    } on http.ClientException catch (e) {
      if (retryCount < maxRetries && _isRetryableClientError(e)) {
        await Future.delayed(Duration(seconds: 1 << retryCount));
        return _request(
          method,
          endpoint,
          data: data,
          requiresAuth: requiresAuth,
          retryCount: retryCount + 1,
        );
      }
      throw WebAuthnException('${ErrorConstants.networkError}: ${e.message}');
    } on CloudflareTunnelException catch (e) {
      // Don't retry Cloudflare tunnel errors, they need manual intervention
      throw WebAuthnException(
        'Server tunnel is down: ${e.message}',
        statusCode: e.statusCode,
      );
    } on NetworkException catch (e) {
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: 1 << retryCount));
        return _request(
          method,
          endpoint,
          data: data,
          requiresAuth: requiresAuth,
          retryCount: retryCount + 1,
        );
      }
      throw WebAuthnException(e.message);
    } catch (e) {
      if (e is WebAuthnException || e is api_token.UnauthorizedException) {
        rethrow;
      }
      // For unknown errors, don't retry
      throw WebAuthnException(ErrorConstants.unknown);
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

  /// Check if WebAuthn is supported on the current device
  Future<bool> isWebAuthnSupported() async {
    try {
      // For now, we'll do a basic platform check
      // This can be enhanced later with actual WebAuthn capability detection
      return Platform.isAndroid ||
          Platform.isIOS ||
          Platform.isMacOS ||
          Platform.isWindows;
    } catch (e) {
      // If there's any error checking support, assume not supported
      return false;
    }
  }

  /// Begin WebAuthn authentication flow
  Future<WebAuthnAuthBeginResponse> beginAuthentication({
    String? username,
    String? email,
  }) async {
    try {
      final requestData =
          WebAuthnAuthBeginRequest(username: username, email: email).toJson();

      final response = await _request(
        'POST',
        _Endpoints.beginAuthentication,
        data: requestData,
        requiresAuth:
            false, // Authentication begin doesn't require existing auth
      );

      return WebAuthnAuthBeginResponse.fromJson(response);
    } catch (e) {
      if (e is WebAuthnException) {
        rethrow;
      }
      throw WebAuthnException(
        '${ErrorConstants.authenticationFailed}: ${e.toString()}',
      );
    }
  }

  /// Complete WebAuthn authentication flow
  Future<WebAuthnAuthCompleteResponse> completeAuthentication(
    WebAuthnAuthCompleteRequest completeRequest,
  ) async {
    try {
      final response = await _request(
        'POST',
        _Endpoints.completeAuthentication,
        data: completeRequest.toJson(),
        requiresAuth:
            false, // Authentication complete doesn't require existing auth
      );

      return WebAuthnAuthCompleteResponse.fromJson(response);
    } catch (e) {
      if (e is WebAuthnException) {
        rethrow;
      }
      throw WebAuthnException(
        '${ErrorConstants.authenticationFailed}: ${e.toString()}',
      );
    }
  }

  /// Begin WebAuthn registration flow (requires existing authentication)
  Future<Map<String, dynamic>> beginRegistration({String? deviceName}) async {
    try {
      final requestData = <String, dynamic>{};
      if (deviceName != null && deviceName.isNotEmpty) {
        requestData['device_name'] = deviceName;
      }

      final response = await _request(
        'POST',
        _Endpoints.beginRegistration,
        data: requestData,
        requiresAuth: true, // Registration requires existing authentication
      );

      return response;
    } catch (e) {
      if (e is WebAuthnException || e is api_token.UnauthorizedException) {
        rethrow;
      }
      throw WebAuthnException(
        '${ErrorConstants.registrationFailed}: ${e.toString()}',
      );
    }
  }

  /// Complete WebAuthn registration flow (requires existing authentication)
  Future<Map<String, dynamic>> completeRegistration(
    Map<String, dynamic> completeRequest,
  ) async {
    try {
      final response = await _request(
        'POST',
        _Endpoints.completeRegistration,
        data: completeRequest,
        requiresAuth: true, // Registration requires existing authentication
      );

      return response;
    } catch (e) {
      if (e is WebAuthnException || e is api_token.UnauthorizedException) {
        rethrow;
      }
      throw WebAuthnException(
        '${ErrorConstants.registrationFailed}: ${e.toString()}',
      );
    }
  }

  /// List all registered WebAuthn credentials for the authenticated user
  Future<List<Map<String, dynamic>>> listCredentials() async {
    try {
      final response = await _request(
        'GET',
        _Endpoints.listCredentials,
        requiresAuth: true, // Listing credentials requires authentication
      );

      if (response['credentials'] is List) {
        final credentialsList = response['credentials'] as List;
        return credentialsList.cast<Map<String, dynamic>>();
      }

      return [];
    } catch (e) {
      if (e is WebAuthnException || e is api_token.UnauthorizedException) {
        rethrow;
      }
      throw WebAuthnException('Failed to list credentials: ${e.toString()}');
    }
  }

  /// Delete a WebAuthn credential by its ID
  Future<void> deleteCredential(String credentialId) async {
    if (credentialId.trim().isEmpty) {
      throw WebAuthnException('Credential ID cannot be empty');
    }

    try {
      await _request(
        'DELETE',
        _Endpoints.deleteCredential(credentialId),
        requiresAuth: true, // Deleting credentials requires authentication
      );
    } catch (e) {
      if (e is WebAuthnException || e is api_token.UnauthorizedException) {
        rethrow;
      }
      throw WebAuthnException('Failed to delete credential: ${e.toString()}');
    }
  }
}
