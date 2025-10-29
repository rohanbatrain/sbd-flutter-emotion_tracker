import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/app_providers.dart'
    hide RateLimitException;
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/utils/http_util.dart' hide NetworkException;
import 'package:http/http.dart' as http;
import 'package:emotion_tracker/providers/user_agent_util.dart';
import 'package:emotion_tracker/core/exceptions.dart' as core_exceptions;
import 'package:emotion_tracker/models/team/team_models.dart';
import 'package:emotion_tracker/providers/team/team_providers.dart';
import 'package:emotion_tracker/utils/backend_data_mapper.dart';
import 'team_exceptions.dart';

class ApiConstants {
  // Workspace endpoints
  static const String workspaces = '/workspaces';
  static const String members = '/members';

  // Team Wallet endpoints
  static const String wallet = '/wallet';
  static const String walletInit =
      '/wallet/initialize'; // Updated to correct backend endpoint
  static const String walletSettings =
      '/wallet/permissions'; // Updated to correct backend endpoint
  static const String tokenRequests =
      '/wallet/token-requests'; // Updated to correct backend endpoint
  static const String audit = '/wallet/audit';
  static const String compliance = '/wallet/compliance-report';
  static const String backupAdmin = '/backup-admin';
  static const String emergencyUnfreeze = '/emergency-unfreeze';

  // Auth endpoints
  static const String authRefresh = '/auth/refresh';

  // Diagnostic endpoints
  static const String diagnostic = '/workspaces/diagnostic';
}

class TeamApiService {
  final Ref _ref;

  TeamApiService(this._ref);

  String get _baseUrl => _ref.read(apiBaseUrlProvider);

  Future<String?> _getAccessToken() async {
    final secureStorage = _ref.read(secureStorageProvider);
    final token = await secureStorage.read(key: 'access_token');
    return token;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAccessToken();
    if (token == null) {
      throw core_exceptions.UnauthorizedException(
        'Session expired. Please log in again.',
      );
    }
    final userAgent = await getUserAgent();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'User-Agent': userAgent,
      'X-User-Agent': userAgent,
    };
  }

  Future<Map<String, dynamic>> _processResponse(http.Response response) async {
    // Extract rate limit information from headers
    final rateLimitInfo = _extractRateLimitInfo(response.headers);

    // Store rate limit info in a provider if available
    if (rateLimitInfo != null) {
      // We'll expose this via a provider later
      _ref.read(rateLimitProvider.notifier).state = rateLimitInfo;
    }

    if (response.statusCode == 401) {
      throw core_exceptions.UnauthorizedException(
        'Session expired. Please log in again.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {}; // Return empty map for empty responses
      }
      final decoded = json.decode(response.body);
      // Handle case where response is just an empty array
      if (decoded is List) {
        return {'items': decoded};
      }
      return decoded;
    } else {
      // Check for rate limit exceeded before parsing error
      if (response.statusCode == 429) {
        throw RateLimitException(
          'Rate limit exceeded. Please try again later.',
        );
      }

      // Try to parse structured error bodies and throw typed exceptions
      try {
        final responseBody = json.decode(response.body);
        String message = response.body;
        String? code;

        if (responseBody is Map) {
          if (responseBody.containsKey('error')) {
            final error = responseBody['error'];
            if (error is String) {
              code = error;
            } else if (error is Map) {
              code = error['code']?.toString();
              if (error.containsKey('message')) {
                message = error['message'].toString();
              }
            }
          }
        }

        // Map backend error codes to typed exceptions
        switch (code) {
          case 'INSUFFICIENT_PERMISSIONS':
            throw PermissionDeniedException(message);
          case 'RATE_LIMIT_EXCEEDED':
            throw RateLimitException(message);
          case 'INVALID_REQUEST':
            throw ValidationException(message);
          case 'WORKSPACE_NOT_FOUND':
            throw WorkspaceNotFoundException(message);
          case 'WALLET_INSUFFICIENT_FUNDS':
            throw InsufficientFundsException(message);
          default:
            throw TeamApiException(
              'API Error (${response.statusCode}): $message',
              statusCode: response.statusCode,
            );
        }
      } catch (e) {
        // If parsing failed, throw a generic TeamApiException with raw body
        throw TeamApiException(
          'API Error (${response.statusCode}): ${response.body}',
          statusCode: response.statusCode,
        );
      }
    }
  }

  RateLimitInfo? _extractRateLimitInfo(Map<String, String> headers) {
    try {
      final limit = int.tryParse(headers['x-ratelimit-limit'] ?? '');
      final remaining = int.tryParse(headers['x-ratelimit-remaining'] ?? '');
      final reset = int.tryParse(headers['x-ratelimit-reset'] ?? '');

      if (limit != null && remaining != null && reset != null) {
        return RateLimitInfo(limit: limit, remaining: remaining, reset: reset);
      }
    } catch (_) {
      // Ignore parsing errors
    }
    return null;
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? data,
    Duration? timeout,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders();
    http.Response response;
    final timeoutDuration = timeout ?? const Duration(seconds: 30);

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await HttpUtil.get(
            url,
            headers: headers,
            timeout: timeoutDuration,
          );
          break;
        case 'POST':
          response = await HttpUtil.post(
            url,
            headers: headers,
            body: data != null ? json.encode(data) : null,
            timeout: timeoutDuration,
          );
          break;
        case 'PUT':
          response = await HttpUtil.put(
            url,
            headers: headers,
            body: data != null ? json.encode(data) : null,
            timeout: timeoutDuration,
          );
          break;
        case 'DELETE':
          response = await HttpUtil.delete(
            url,
            headers: headers,
            body: data != null ? json.encode(data) : null,
            timeout: timeoutDuration,
          );
          break;
        default:
          throw UnsupportedError('HTTP method $method not supported.');
      }
      return _processResponse(response);
    } on TimeoutException catch (_) {
      throw NetworkException('Request timed out. Please try again.');
    } on SocketException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } on http.ClientException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    }
  }

  // Workspace Management
  Future<List<TeamWorkspace>> getWorkspaces() async {
    try {
      final response = await _request('GET', ApiConstants.workspaces);
      final data = (response['items'] ?? response) as List;
      return data
          .map((json) => BackendDataMapper.mapWorkspaceResponse(json))
          .toList();
    } catch (e) {
      if (e is TeamApiException) {
        rethrow;
      }
      throw TeamApiException('Failed to load workspaces: $e');
    }
  }

  Future<TeamWorkspace> createWorkspace(
    String name, {
    String? description,
  }) async {
    try {
      final response = await _request(
        'POST',
        ApiConstants.workspaces,
        data: {'name': name, 'description': description},
      );
      return BackendDataMapper.mapWorkspaceResponse(response);
    } catch (e) {
      if (e is TeamApiException) {
        rethrow;
      }
      throw TeamApiException('Failed to create workspace: $e');
    }
  }

  Future<TeamWorkspace> getWorkspace(String workspaceId) async {
    try {
      final response = await _request(
        'GET',
        '${ApiConstants.workspaces}/$workspaceId',
      );
      return BackendDataMapper.mapWorkspaceResponse(response);
    } catch (e) {
      if (e is TeamApiException) {
        rethrow;
      }
      throw TeamApiException('Failed to load workspace: $e');
    }
  }

  Future<TeamWorkspace> updateWorkspace(
    String workspaceId, {
    String? name,
    String? description,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final response = await _request(
        'PUT',
        '${ApiConstants.workspaces}/$workspaceId',
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (settings != null) 'settings': settings,
        },
      );
      return BackendDataMapper.mapWorkspaceResponse(response);
    } catch (e) {
      if (e is TeamApiException) {
        rethrow;
      }
      throw TeamApiException('Failed to update workspace: $e');
    }
  }

  Future<void> deleteWorkspace(String workspaceId) async {
    try {
      await _request('DELETE', '${ApiConstants.workspaces}/$workspaceId');
    } catch (e) {
      if (e is TeamApiException) {
        rethrow;
      }
      throw TeamApiException('Failed to delete workspace: $e');
    }
  }

  // Team Member Management
  Future<TeamWorkspace> addMember(
    String workspaceId,
    String userIdToAdd,
    WorkspaceRole role,
  ) async {
    try {
      final response = await _request(
        'POST',
        '${ApiConstants.workspaces}/$workspaceId${ApiConstants.members}',
        data: {
          'user_id': userIdToAdd,
          'role': BackendDataMapper.mapFlutterRoleToBackend(role),
        },
      );
      return BackendDataMapper.mapWorkspaceResponse(response);
    } catch (e) {
      if (e is TeamApiException) {
        rethrow;
      }
      throw TeamApiException('Failed to add member: $e');
    }
  }

  Future<TeamWorkspace> updateMemberRole(
    String workspaceId,
    String memberId,
    WorkspaceRole newRole,
  ) async {
    try {
      final response = await _request(
        'PUT',
        '${ApiConstants.workspaces}/$workspaceId${ApiConstants.members}/$memberId/role',
        data: {'role': BackendDataMapper.mapFlutterRoleToBackend(newRole)},
      );
      return BackendDataMapper.mapWorkspaceResponse(response);
    } catch (e) {
      if (e is TeamApiException) {
        rethrow;
      }
      throw TeamApiException('Failed to update member role: $e');
    }
  }

  Future<void> removeMember(String workspaceId, String memberId) async {
    try {
      await _request(
        'DELETE',
        '${ApiConstants.workspaces}/$workspaceId${ApiConstants.members}/$memberId',
      );
    } catch (e) {
      if (e is TeamApiException) {
        rethrow;
      }
      throw TeamApiException('Failed to remove member: $e');
    }
  }

  // Team Wallet Management
  Future<TokenRequest> requestTokens(
    String workspaceId, {
    required double amount,
    required String purpose,
    String? description,
  }) async {
    try {
      final endpoint =
          '${ApiConstants.workspaces}/$workspaceId${ApiConstants.tokenRequests}';
      final response = await _request(
        'POST',
        endpoint,
        data: {
          'amount': amount,
          'purpose': purpose,
          if (description != null) 'description': description,
        },
      );
      return BackendDataMapper.mapTokenRequestResponse(response);
    } catch (e) {
      if (e is TeamApiException) {
        rethrow;
      }
      throw TeamApiException('Failed to request tokens: $e');
    }
  }

  Future<List<TokenRequest>> getTokenRequests(String workspaceId) async {
    try {
      final endpoint =
          '${ApiConstants.workspaces}/$workspaceId${ApiConstants.tokenRequests}/pending';
      final response = await _request('GET', endpoint);

      final data =
          (response['requests'] ?? response['items'] ?? response) as List;
      return data.map((raw) {
        final Map<String, dynamic> json = Map<String, dynamic>.from(raw as Map);
        return BackendDataMapper.mapTokenRequestResponse(json);
      }).toList();
    } catch (e) {
      if (e is TeamApiException) {
        rethrow;
      }
      throw TeamApiException('Failed to load token requests: $e');
    }
  }

  Future<TokenRequest> approveTokenRequest(
    String workspaceId,
    String requestId,
  ) async {
    try {
      final endpoint =
          '${ApiConstants.workspaces}/$workspaceId${ApiConstants.tokenRequests}/$requestId/review';
      final response = await _request(
        'POST',
        endpoint,
        data: {'action': 'approve', 'reviewer_notes': ''},
      );
      return BackendDataMapper.mapTokenRequestResponse(response);
    } catch (e) {
      if (e is TeamApiException) {
        rethrow;
      }
      throw TeamApiException('Failed to approve token request: $e');
    }
  }

  Future<TokenRequest> rejectTokenRequest(
    String workspaceId,
    String requestId,
    String reason,
  ) async {
    try {
      final endpoint =
          '${ApiConstants.workspaces}/$workspaceId${ApiConstants.tokenRequests}/$requestId/review';
      final response = await _request(
        'POST',
        endpoint,
        data: {'action': 'deny', 'reviewer_notes': reason},
      );
      return BackendDataMapper.mapTokenRequestResponse(response);
    } catch (e) {
      if (e is TeamApiException) {
        rethrow;
      }
      throw TeamApiException('Failed to reject token request: $e');
    }
  }

  Future<TeamWallet> getTeamWallet(String workspaceId) async {
    try {
      final response = await _request(
        'GET',
        '${ApiConstants.workspaces}/$workspaceId${ApiConstants.wallet}',
      );
      return BackendDataMapper.mapTeamWalletResponse(response);
    } catch (e) {
      if (e is TeamApiException) {
        rethrow;
      }
      throw TeamApiException('Failed to load wallet: $e');
    }
  }

  Future<TeamWallet> initializeTeamWallet(
    String workspaceId, {
    required double initialBalance,
    required String currency,
    required String walletName,
  }) async {
    try {
      final response = await _request(
        'POST',
        '${ApiConstants.workspaces}/$workspaceId${ApiConstants.walletInit}',
        data: {
          'initial_balance': initialBalance,
          'currency': currency,
          'wallet_name': walletName,
        },
      );
      return BackendDataMapper.mapTeamWalletResponse(response);
    } catch (e) {
      if (e is TeamApiException) {
        rethrow;
      }
      throw TeamApiException('Failed to initialize wallet: $e');
    }
  }

  Future<TeamWallet> updateWalletPermissions(
    String workspaceId,
    Map<String, Map<String, dynamic>> permissions,
  ) async {
    try {
      final response = await _request(
        'PUT',
        '${ApiConstants.workspaces}/$workspaceId${ApiConstants.walletSettings}',
        data: {'permissions': permissions},
      );
      return BackendDataMapper.mapTeamWalletResponse(response);
    } catch (e) {
      if (e is TeamApiException) {
        rethrow;
      }
      throw TeamApiException('Failed to update permissions: $e');
    }
  }

  Future<TeamWallet> freezeWallet(String workspaceId, String reason) async {
    try {
      final response = await _request(
        'POST',
        '${ApiConstants.workspaces}/$workspaceId${ApiConstants.wallet}/freeze',
        data: {'reason': reason},
      );
      return BackendDataMapper.mapTeamWalletResponse(response);
    } catch (e) {
      if (e is TeamApiException) {
        rethrow;
      }
      throw TeamApiException('Failed to freeze wallet: $e');
    }
  }

  Future<TeamWallet> unfreezeWallet(String workspaceId) async {
    try {
      final response = await _request(
        'POST',
        '${ApiConstants.workspaces}/$workspaceId${ApiConstants.wallet}/unfreeze',
      );
      return BackendDataMapper.mapTeamWalletResponse(response);
    } catch (e) {
      if (e is TeamApiException) {
        rethrow;
      }
      throw TeamApiException('Failed to unfreeze wallet: $e');
    }
  }

  // Audit & Compliance
  Future<List<AuditEntry>> getAuditTrail(
    String workspaceId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }
      queryParams['limit'] = limit.toString();

      final endpoint =
          '${ApiConstants.workspaces}/$workspaceId${ApiConstants.wallet}${ApiConstants.audit}';
      final url = Uri.parse(
        '$_baseUrl$endpoint',
      ).replace(queryParameters: queryParams);

      final headers = await _getHeaders();
      final response = await HttpUtil.get(url, headers: headers);
      final data = await _processResponse(response);
      final items = (data['items'] ?? data) as List;
      return items
          .map((json) => BackendDataMapper.mapAuditEntry(json))
          .toList();
    } catch (e) {
      if (e is TeamApiException) {
        rethrow;
      }
      throw TeamApiException('Failed to load audit trail: $e');
    }
  }

  Future<ComplianceReport> generateComplianceReport(
    String workspaceId,
    String reportType, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{'report_type': reportType};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final endpoint =
          '${ApiConstants.workspaces}/$workspaceId${ApiConstants.wallet}${ApiConstants.compliance}';
      final url = Uri.parse(
        '$_baseUrl$endpoint',
      ).replace(queryParameters: queryParams);

      final headers = await _getHeaders();
      final response = await HttpUtil.get(url, headers: headers);
      final data = await _processResponse(response);
      return BackendDataMapper.mapComplianceReport(data);
    } catch (e) {
      if (e is TeamApiException) {
        rethrow;
      }
      throw TeamApiException('Failed to generate compliance report: $e');
    }
  }

  // Emergency Recovery
  Future<Map<String, dynamic>> designateBackupAdmin(
    String workspaceId,
    String backupAdminId,
  ) async {
    try {
      final response = await _request(
        'POST',
        '${ApiConstants.workspaces}/$workspaceId${ApiConstants.wallet}${ApiConstants.backupAdmin}',
        data: {'backup_admin_id': backupAdminId},
      );
      return response;
    } catch (e) {
      if (e is TeamApiException) {
        rethrow;
      }
      throw TeamApiException('Failed to designate backup admin: $e');
    }
  }

  Future<Map<String, dynamic>> removeBackupAdmin(
    String workspaceId,
    String backupAdminId,
  ) async {
    try {
      final response = await _request(
        'DELETE',
        '${ApiConstants.workspaces}/$workspaceId${ApiConstants.wallet}${ApiConstants.backupAdmin}/$backupAdminId',
      );
      return response;
    } catch (e) {
      if (e is TeamApiException) {
        rethrow;
      }
      throw TeamApiException('Failed to remove backup admin: $e');
    }
  }

  Future<Map<String, dynamic>> emergencyUnfreeze(
    String workspaceId,
    String emergencyReason,
  ) async {
    try {
      final response = await _request(
        'POST',
        '${ApiConstants.workspaces}/$workspaceId${ApiConstants.wallet}${ApiConstants.emergencyUnfreeze}',
        data: {'emergency_reason': emergencyReason},
      );
      return response;
    } catch (e) {
      if (e is TeamApiException) {
        rethrow;
      }
      throw TeamApiException('Failed to perform emergency unfreeze: $e');
    }
  }

  // Diagnostic & Support
  Future<Map<String, dynamic>> getWorkspaceDiagnostic() async {
    try {
      final response = await _request('GET', ApiConstants.diagnostic);
      return response;
    } catch (e) {
      if (e is TeamApiException) {
        rethrow;
      }
      throw TeamApiException('Failed to get workspace diagnostic: $e');
    }
  }
}
