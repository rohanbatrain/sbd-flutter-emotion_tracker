import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/utils/http_util.dart';
import 'package:http/http.dart' as http;

const String _accessTokenKey = 'access_token';

final twoFAServiceProvider = Provider((ref) => TwoFAService(ref));

// Centralized constants for secure storage keys and error messages
class TwoFAConstants {
  static const String backupCodesKey = '2fa_backup_codes';
  static const String backupCodesRegeneratedAtKey = '2fa_backup_codes_regenerated_at';
  static const String errorInvalidTOTP = 'Invalid authentication code. Please try again.';
  static const String errorInvalidBackupCode = 'Invalid or already used backup code.';
  static const String errorSessionExpired = 'Your session has expired. Please log in again.';
  static const String errorNetwork = 'Network error: Please check your connection.';
  static const String errorTimeout = 'The request timed out. Please try again.';
  static const String errorUnknown = 'An unknown error occurred.';
}

class _Endpoints {
  static const String status = '/auth/2fa/status';
  static const String setup = '/auth/2fa/setup';
  static const String verify = '/auth/2fa/verify';
  static const String disable = '/auth/2fa/disable';
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

class TwoFAService {
  final Ref _ref;

  TwoFAService(this._ref);

  String get _baseUrl => _ref.read(apiBaseUrlProvider);

  Future<String?> _getAccessToken() async {
    final secureStorage = _ref.read(secureStorageProvider);
    return await secureStorage.read(key: _accessTokenKey);
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAccessToken();
    if (token == null) {
      throw UnauthorizedException(TwoFAConstants.errorSessionExpired);
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _processResponse(http.Response response) async {
    if (response.statusCode == 401) {
      try {
        final responseBody = json.decode(response.body);
        if (responseBody is Map && responseBody['detail'] is String) {
          final detail = responseBody['detail'] as String;
          if (detail.toLowerCase().contains('invalid totp')) {
            // Don't logout, just show error in UI
            throw ApiException(detail, 401);
          }
        }
      } catch (_) {}
      await _ref.read(authProvider.notifier).logout();
      throw UnauthorizedException(TwoFAConstants.errorSessionExpired);
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
      throw ApiException(errorMessage, response.statusCode);
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint,
    {Map<String, dynamic>? data,}
  ) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders();
    http.Response response;
    const timeoutDuration = Duration(seconds: 15);

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await HttpUtil.get(url, headers: headers).timeout(timeoutDuration);
          break;
        case 'POST':
          response = await HttpUtil.post(
            url,
            headers: headers,
            body: data != null ? json.encode(data) : null,
          ).timeout(timeoutDuration);
          break;
        default:
          throw UnsupportedError('HTTP method $method not supported.');
      }
      return _processResponse(response);
    } on TimeoutException catch (_) {
      throw ApiException(TwoFAConstants.errorTimeout);
    } on SocketException catch (e) {
      throw ApiException('${TwoFAConstants.errorNetwork} (${e.message})');
    } on http.ClientException catch (e) {
      throw ApiException('${TwoFAConstants.errorNetwork}: ${e.message}');
    } catch (e) {
      throw ApiException(TwoFAConstants.errorUnknown);
    }
  }

  Future<Map<String, dynamic>> get2FAStatus() async {
    // Returns enabled, methods, pending, never backup_codes
    return _request('GET', _Endpoints.status);
  }

  Future<Map<String, dynamic>> setup2FA() async {
    // Only returns totp_secret, provisioning_uri, qr_code_url
    return _request('POST', _Endpoints.setup, data: {'method': 'totp'});
  }

  Future<Map<String, dynamic>> verify2FA(String code) async {
    // Only returns backup_codes on first successful verification
    return _request('POST', _Endpoints.verify, data: {'method': 'totp', 'code': code});
  }

  Future<Map<String, dynamic>> disable2FA() async {
    // Disables 2FA
    return _request('POST', _Endpoints.disable);
  }

  Future<Map<String, dynamic>> reset2FA() async {
    // Resets TOTP secret, does not return backup codes
    return _request('POST', '/auth/2fa/reset', data: {'method': 'totp'});
  }

  Future<Map<String, dynamic>> regenerateBackupCodes() async {
    return _request('POST', '/auth/2fa/regenerate-backup-codes');
  }

  /// Returns the last backup code regeneration time, if available.
  Future<DateTime?> getBackupCodesRegeneratedAt() async {
    final secureStorage = _ref.read(secureStorageProvider);
    final value = await secureStorage.read(key: TwoFAConstants.backupCodesRegeneratedAtKey);
    if (value == null) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  /// Deletes backup codes and timestamp from secure storage.
  Future<void> deleteBackupCodes() async {
    final secureStorage = _ref.read(secureStorageProvider);
    await secureStorage.delete(key: TwoFAConstants.backupCodesKey);
    await secureStorage.delete(key: TwoFAConstants.backupCodesRegeneratedAtKey);
  }
}
