import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:emotion_tracker/utils/http_util.dart';
import 'package:emotion_tracker/providers/auth_token_manager.dart';

/// HTTP client that automatically handles token refresh on 401 responses
class AuthHttpClient {
  final Ref _ref;

  AuthHttpClient(this._ref);

  /// Makes an HTTP GET request with automatic token refresh on 401
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final response = await HttpUtil.get(
      url,
      headers: headers,
      timeout: timeout,
    );
    if (response.statusCode == 401) {
      if (await _tryRefreshAndRetry(
        () => HttpUtil.get(url, headers: headers, timeout: timeout),
      )) {
        return await HttpUtil.get(url, headers: headers, timeout: timeout);
      }
    }
    return response;
  }

  /// Makes an HTTP POST request with automatic token refresh on 401
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
  }) async {
    final response = await HttpUtil.post(
      url,
      headers: headers,
      body: body,
      timeout: timeout,
    );
    if (response.statusCode == 401) {
      if (await _tryRefreshAndRetry(
        () =>
            HttpUtil.post(url, headers: headers, body: body, timeout: timeout),
      )) {
        return await HttpUtil.post(
          url,
          headers: headers,
          body: body,
          timeout: timeout,
        );
      }
    }
    return response;
  }

  /// Makes an HTTP PUT request with automatic token refresh on 401
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
  }) async {
    final response = await HttpUtil.put(
      url,
      headers: headers,
      body: body,
      timeout: timeout,
    );
    if (response.statusCode == 401) {
      if (await _tryRefreshAndRetry(
        () => HttpUtil.put(url, headers: headers, body: body, timeout: timeout),
      )) {
        return await HttpUtil.put(
          url,
          headers: headers,
          body: body,
          timeout: timeout,
        );
      }
    }
    return response;
  }

  /// Makes an HTTP DELETE request with automatic token refresh on 401
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeout,
  }) async {
    final response = await HttpUtil.delete(
      url,
      headers: headers,
      body: body,
      timeout: timeout,
    );
    if (response.statusCode == 401) {
      if (await _tryRefreshAndRetry(
        () => HttpUtil.delete(
          url,
          headers: headers,
          body: body,
          timeout: timeout,
        ),
      )) {
        return await HttpUtil.delete(
          url,
          headers: headers,
          body: body,
          timeout: timeout,
        );
      }
    }
    return response;
  }

  /// Attempts to refresh the active profile's token and returns true if successful
  Future<bool> _tryRefreshAndRetry(
    Future<http.Response> Function() retryRequest,
  ) async {
    try {
      final authTokenManager = _ref.read(authTokenManagerProvider);
      final currentProfile = await authTokenManager.getActiveProfile(
        autoRefresh: false,
      );
      if (currentProfile != null) {
        final refreshSuccess = await authTokenManager.refreshProfile(
          currentProfile.id,
        );
        if (refreshSuccess) {
          // Token was refreshed, the retry request will use the new token
          return true;
        }
      }
    } catch (e) {
      // Refresh failed, don't retry
    }
    return false;
  }
}

final authHttpClientProvider = Provider<AuthHttpClient>((ref) {
  return AuthHttpClient(ref);
});
