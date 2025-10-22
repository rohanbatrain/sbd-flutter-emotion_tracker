import 'dart:async';
import 'dart:convert';
import 'dart:io';
// dart:math not required here

import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/utils/http_util.dart';
import 'package:http/http.dart' as http;
import 'package:emotion_tracker/providers/user_agent_util.dart';
import 'package:emotion_tracker/core/exceptions.dart' as core_exceptions;
import 'family_models.dart' as models;
import 'family_exceptions.dart' as family_ex;

final familyApiServiceProvider = Provider((ref) => FamilyApiService(ref));

class FamilyApiService {
  final Ref _ref;

  FamilyApiService(this._ref);

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
      String errorMessage;
      try {
        final responseBody = json.decode(response.body);
        if (responseBody is Map && responseBody.containsKey('detail')) {
          errorMessage = responseBody['detail'];
        } else if (responseBody is Map && responseBody.containsKey('error')) {
          final error = responseBody['error'];
          if (error is Map && error.containsKey('message')) {
            errorMessage = error['message'];
          } else {
            errorMessage = error.toString();
          }
        } else {
          errorMessage = response.body;
        }
      } catch (e) {
        errorMessage = response.body;
      }
      throw Exception('API Error (${response.statusCode}): $errorMessage');
    }
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
      throw Exception('Request timed out. Please try again.');
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  // Attempt to refresh the active profile's token using its refreshToken.
  // Returns true if refresh succeeded and stored token is updated.

  // ==================== Core Family Management ====================

  Future<models.Family> createFamily({String? name}) async {
    final request = models.CreateFamilyRequest(name: name);
    final response = await _request(
      'POST',
      '/family/create',
      data: request.toJson(),
    );
    return models.Family.fromJson(response);
  }

  Future<List<models.Family>> getMyFamilies() async {
    final response = await _request('GET', '/family/my-families');
    // Handle empty response or missing families key
    if (response.isEmpty) {
      return [];
    }
    final families = (response['families'] ?? response['items'] ?? []) as List;
    return families.map((f) => models.Family.fromJson(f)).toList();
  }

  Future<models.Family> getFamilyDetails(String familyId) async {
    final response = await _request('GET', '/family/$familyId');

    // Debug: print raw family details response to help diagnose admin/role issues
    try {
      print('[FAMILY_API] ========== GET FAMILY DETAILS RESPONSE =========');
      print('[FAMILY_API] FamilyId: $familyId');
      print('[FAMILY_API] Raw response: $response');
      // response is expected to be a Map<String, dynamic>
      print('[FAMILY_API] - is_admin: ${response['is_admin']}');
      print('[FAMILY_API] - admin_user_ids: ${response['admin_user_ids']}');
      print('[FAMILY_API] - user_role: ${response['user_role']}');
      print('[FAMILY_API] =================================================');
    } catch (e) {
      // ignore logging errors
    }

    return models.Family.fromJson(response);
  }

  Future<models.Family> updateFamilySettings(
    String familyId,
    Map<String, dynamic> settings,
  ) async {
    final response = await _request('PUT', '/family/$familyId', data: settings);
    return models.Family.fromJson(response);
  }

  Future<void> deleteFamily(String familyId) async {
    await _request('DELETE', '/family/$familyId');
  }

  // ==================== Member Management ====================

  Future<List<models.FamilyMember>> getFamilyMembers(String familyId) async {
    final response = await _request('GET', '/family/$familyId/members');

    // Debug: print raw members response to inspect member roles/admin flags
    try {
      print('[FAMILY_API] ========== GET FAMILY MEMBERS RESPONSE =========');
      print('[FAMILY_API] FamilyId: $familyId');
      print('[FAMILY_API] Raw response: $response');
      final membersList =
          (response['members'] ?? response['items'] ?? []) as List?;
      print('[FAMILY_API] Members count: ${membersList?.length ?? 0}');
      if (membersList != null && membersList.isNotEmpty) {
        print('[FAMILY_API] First member raw data:');
        print(membersList[0]);
        print('[FAMILY_API] Fields check (first member):');
        print('  - user_id: ${membersList[0]['user_id']}');
        print('  - username: ${membersList[0]['username']}');
        print('  - role: ${membersList[0]['role']}');
        print('  - is_backup_admin: ${membersList[0]['is_backup_admin']}');
      }
      print('[FAMILY_API] =================================================');
    } catch (e) {
      // ignore logging errors
    }

    if (response.isEmpty) return [];
    final members = (response['members'] ?? response['items'] ?? []) as List;
    return members.map((m) => models.FamilyMember.fromJson(m)).toList();
  }

  Future<void> removeMember(String familyId, String memberId) async {
    await _request('DELETE', '/family/$familyId/members/$memberId');
  }

  Future<Map<String, dynamic>> promoteToAdmin(
    String familyId,
    String userId,
  ) async {
    final request = models.AdminActionRequest(action: 'promote');
    return await _request(
      'POST',
      '/family/$familyId/members/$userId/admin',
      data: request.toJson(),
    );
  }

  Future<Map<String, dynamic>> demoteFromAdmin(
    String familyId,
    String userId,
  ) async {
    final request = models.AdminActionRequest(action: 'demote');
    return await _request(
      'POST',
      '/family/$familyId/members/$userId/admin',
      data: request.toJson(),
    );
  }

  Future<Map<String, dynamic>> designateBackupAdmin(
    String familyId,
    String userId,
  ) async {
    final request = models.BackupAdminRequest(action: 'designate');
    return await _request(
      'POST',
      '/family/$familyId/members/$userId/backup-admin',
      data: request.toJson(),
    );
  }

  Future<Map<String, dynamic>> removeBackupAdmin(
    String familyId,
    String userId,
  ) async {
    final request = models.BackupAdminRequest(action: 'remove');
    return await _request(
      'POST',
      '/family/$familyId/members/$userId/backup-admin',
      data: request.toJson(),
    );
  }

  // ==================== Family Invitation System ====================

  Future<models.FamilyInvitation> inviteMember(
    String familyId,
    models.InviteMemberRequest request,
  ) async {
    try {
      final response = await _request(
        'POST',
        '/family/$familyId/invite',
        data: request.toJson(),
      );
      return models.FamilyInvitation.fromJson(response);
    } on Exception catch (e) {
      // Parse error message and throw specific exception types
      final errorMsg = e.toString();

      // Check for specific edge cases
      if (errorMsg.contains('already has a pending invitation')) {
        throw family_ex.DuplicateInvitationException(errorMsg);
      } else if (errorMsg.contains('recently declined') ||
          errorMsg.contains('wait') && errorMsg.contains('hours')) {
        throw family_ex.RecentlyDeclinedException(errorMsg);
      } else if (errorMsg.contains('already a member') ||
          errorMsg.contains('already in this family')) {
        throw family_ex.AlreadyMemberException(errorMsg);
      } else if (errorMsg.contains('cannot invite yourself') ||
          errorMsg.contains('self-invite')) {
        throw family_ex.SelfInviteException(
          'You cannot invite yourself to a family',
        );
      } else if (errorMsg.contains('Maximum family members limit') ||
          errorMsg.contains('family member limit reached')) {
        throw family_ex.FamilyLimitReachedException(errorMsg);
      } else if (errorMsg.contains('Invalid relationship')) {
        throw family_ex.InvalidRelationshipException(errorMsg);
      } else if (errorMsg.contains('Only') && errorMsg.contains('admin')) {
        throw family_ex.NotFamilyAdminException(
          'Only family administrators can send invitations',
        );
      } else if (errorMsg.contains('User not found')) {
        throw family_ex.UserNotFoundException(
          'User not found. Please check the email or username.',
        );
      } else if (errorMsg.contains('Family not found')) {
        throw family_ex.FamilyNotFoundException('Family not found');
      } else if (errorMsg.contains('Rate limit') ||
          errorMsg.contains('Too many')) {
        throw family_ex.RateLimitException(
          'You\'ve sent too many invitations. Please wait an hour.',
        );
      } else if (e is core_exceptions.UnauthorizedException) {
        throw family_ex.UnauthorizedException(
          'Your session has expired. Please log in again.',
        );
      }

      // Re-throw original exception if no specific match
      rethrow;
    }
  }

  Future<void> respondToInvitation(String invitationId, String action) async {
    final request = models.RespondToInvitationRequest(action: action);
    await _request(
      'POST',
      '/family/invitation/$invitationId/respond',
      data: request.toJson(),
    );
  }

  Future<void> acceptInvitationByToken(String invitationToken) async {
    await _request('GET', '/family/invitation/$invitationToken/accept');
  }

  Future<void> declineInvitationByToken(String invitationToken) async {
    await _request('GET', '/family/invitation/$invitationToken/decline');
  }

  Future<List<models.FamilyInvitation>> getFamilyInvitations(
    String familyId,
  ) async {
    final response = await _request('GET', '/family/$familyId/invitations');

    print('[FAMILY_API] ========== GET FAMILY INVITATIONS RESPONSE ==========');
    print('[FAMILY_API] FamilyId: $familyId');
    print('[FAMILY_API] Raw response: $response');

    if (response.isEmpty) return [];
    final invitations =
        (response['invitations'] ?? response['items'] ?? []) as List;

    print('[FAMILY_API] Invitations count: ${invitations.length}');
    if (invitations.isNotEmpty) {
      print('[FAMILY_API] First invitation raw data:');
      print(invitations[0]);
      print('[FAMILY_API] Fields check:');
      print('  - invitation_id: ${invitations[0]['invitation_id']}');
      print('  - family_id: ${invitations[0]['family_id']}');
      print('  - family_name: ${invitations[0]['family_name']}');
      print('  - invited_by: ${invitations[0]['invited_by']}');
      print(
        '  - invited_by_username: ${invitations[0]['invited_by_username']}',
      );
      print('  - invitee_email: ${invitations[0]['invitee_email']}');
      print('  - invitee_username: ${invitations[0]['invitee_username']}');
      print('  - relationship_type: ${invitations[0]['relationship_type']}');
      print('  - status: ${invitations[0]['status']}');
    }
    print('[FAMILY_API] ====================================================');

    return invitations.map((i) => models.FamilyInvitation.fromJson(i)).toList();
  }

  Future<void> resendInvitation(String familyId, String invitationId) async {
    await _request(
      'POST',
      '/family/$familyId/invitations/$invitationId/resend',
    );
  }

  Future<void> cancelInvitation(String familyId, String invitationId) async {
    await _request('DELETE', '/family/$familyId/invitations/$invitationId');
  }

  /// Get invitations received by the current user
  /// Optional status filter: 'pending', 'accepted', 'declined', 'expired'
  Future<List<models.ReceivedInvitation>> getMyInvitations({
    String? status,
  }) async {
    final queryString = status != null ? '?status=$status' : '';
    final response = await _request(
      'GET',
      '/family/my-invitations$queryString',
    );

    print('[FAMILY_API] ========== GET MY INVITATIONS RESPONSE ==========');
    print('[FAMILY_API] Raw response: $response');

    // API returns array directly
    if (response.isEmpty) return [];
    final invitations = (response['items'] ?? []) as List;

    print('[FAMILY_API] Invitations count: ${invitations.length}');
    if (invitations.isNotEmpty) {
      print('[FAMILY_API] First invitation raw data:');
      print(invitations[0]);
      print('[FAMILY_API] Fields check:');
      print('  - invitation_id: ${invitations[0]['invitation_id']}');
      print('  - family_id: ${invitations[0]['family_id']}');
      print('  - family_name: ${invitations[0]['family_name']}');
      print('  - inviter_user_id: ${invitations[0]['inviter_user_id']}');
      print('  - inviter_username: ${invitations[0]['inviter_username']}');
      print('  - relationship_type: ${invitations[0]['relationship_type']}');
      print('  - status: ${invitations[0]['status']}');
    }
    print('[FAMILY_API] ================================================');

    return invitations
        .map((i) => models.ReceivedInvitation.fromJson(i))
        .toList();
  }

  // ==================== SBD Account Management ====================

  Future<models.SBDAccount> getSBDAccount(String familyId) async {
    final response = await _request('GET', '/family/$familyId/sbd-account');
    return models.SBDAccount.fromJson(response);
  }

  /// Update a member's spending permissions.
  /// New backend contract returns a wrapper object with `new_permissions` and metadata.
  Future<Map<String, dynamic>> updateSpendingPermissions(
    String familyId,
    models.UpdateSpendingPermissionsRequest request,
  ) async {
    // New endpoint includes the target user id in the path
    final userId = request.userId;
    final response = await _request(
      'PUT',
      '/family/$familyId/spending-permissions/$userId',
      data: request.toJson(),
    );

    // Return the raw wrapper so callers can inspect message/transaction_safe/new_permissions
    return Map<String, dynamic>.from(response);
  }

  Future<List<models.Transaction>> getTransactions(String familyId) async {
    final response = await _request(
      'GET',
      '/family/$familyId/sbd-account/transactions',
    );
    if (response.isEmpty) return [];
    final transactions =
        (response['transactions'] ?? response['items'] ?? []) as List;
    return transactions.map((t) => models.Transaction.fromJson(t)).toList();
  }

  Future<models.SBDAccount> freezeAccount(
    String familyId,
    String reason,
  ) async {
    final request = models.FreezeAccountRequest(
      action: 'freeze',
      reason: reason,
    );
    final response = await _request(
      'POST',
      '/family/$familyId/account/freeze',
      data: request.toJson(),
    );
    return models.SBDAccount.fromJson(response);
  }

  Future<models.SBDAccount> unfreezeAccount(String familyId) async {
    final request = models.FreezeAccountRequest(action: 'unfreeze');
    final response = await _request(
      'POST',
      '/family/$familyId/account/freeze',
      data: request.toJson(),
    );
    return models.SBDAccount.fromJson(response);
  }

  Future<models.SBDAccount> emergencyUnfreezeAccount(String familyId) async {
    final response = await _request(
      'POST',
      '/family/$familyId/account/emergency-unfreeze',
    );
    return models.SBDAccount.fromJson(response);
  }

  // ==================== Token Request System ====================

  Future<models.TokenRequest> createTokenRequest(
    String familyId,
    models.CreateTokenRequestRequest request,
  ) async {
    final response = await _request(
      'POST',
      '/family/$familyId/token-requests',
      data: request.toJson(),
    );
    return models.TokenRequest.fromJson(response);
  }

  Future<List<models.TokenRequest>> getPendingTokenRequests(
    String familyId,
  ) async {
    final response = await _request(
      'GET',
      '/family/$familyId/token-requests/pending',
    );
    if (response.isEmpty) return [];
    final requests =
        (response['token_requests'] ?? response['items'] ?? []) as List;
    return requests.map((r) => models.TokenRequest.fromJson(r)).toList();
  }

  Future<models.TokenRequest> reviewTokenRequest(
    String familyId,
    String requestId,
    models.ReviewTokenRequestRequest request,
  ) async {
    final response = await _request(
      'POST',
      '/family/$familyId/token-requests/$requestId/review',
      data: request.toJson(),
    );
    return models.TokenRequest.fromJson(response);
  }

  Future<List<models.TokenRequest>> getMyTokenRequests(String familyId) async {
    final response = await _request(
      'GET',
      '/family/$familyId/token-requests/my-requests',
    );
    if (response.isEmpty) return [];
    final requests =
        (response['token_requests'] ?? response['items'] ?? []) as List;
    return requests.map((r) => models.TokenRequest.fromJson(r)).toList();
  }

  // ==================== Notification System ====================

  Future<List<models.FamilyNotification>> getNotifications(
    String familyId,
  ) async {
    final response = await _request('GET', '/family/$familyId/notifications');
    if (response.isEmpty) return [];
    final notifications =
        (response['notifications'] ?? response['items'] ?? []) as List;
    return notifications
        .map((n) => models.FamilyNotification.fromJson(n))
        .toList();
  }

  Future<void> markNotificationsRead(
    String familyId,
    List<String> notificationIds,
  ) async {
    final request = models.MarkNotificationsReadRequest(
      notificationIds: notificationIds,
    );
    await _request(
      'POST',
      '/family/$familyId/notifications/mark-read',
      data: request.toJson(),
    );
  }

  Future<void> markAllNotificationsRead(String familyId) async {
    await _request('POST', '/family/$familyId/notifications/mark-all-read');
  }

  Future<models.NotificationPreferences> getNotificationPreferences() async {
    final response = await _request('GET', '/family/notifications/preferences');
    return models.NotificationPreferences.fromJson(response);
  }

  Future<models.NotificationPreferences> updateNotificationPreferences(
    models.NotificationPreferences preferences,
  ) async {
    final response = await _request(
      'PUT',
      '/family/notifications/preferences',
      data: preferences.toJson(),
    );
    return models.NotificationPreferences.fromJson(response);
  }

  // ==================== Administrative ====================

  Future<Map<String, dynamic>> getFamilyLimits() async {
    return await _request('GET', '/family/limits');
  }

  Future<List<models.AdminAction>> getAdminActions(
    String familyId, {
    int? limit,
    int? offset,
  }) async {
    final params = <String, dynamic>{};
    if (limit != null) params['limit'] = limit;
    if (offset != null) params['offset'] = offset;

    final queryString = params.isNotEmpty
        ? '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&')
        : '';

    final response = await _request(
      'GET',
      '/family/$familyId/admin-actions$queryString',
    );
    if (response.isEmpty) return [];
    final actions =
        (response['admin_actions'] ?? response['items'] ?? []) as List;
    return actions.map((a) => models.AdminAction.fromJson(a)).toList();
  }
}
