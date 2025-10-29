import 'package:emotion_tracker/models/team/team_models.dart';

/// Utility class to map backend API responses to Flutter model format
/// The backend uses different field names than what Flutter expects
class BackendDataMapper {
  /// Maps backend workspace response to Flutter TeamWorkspace model
  static TeamWorkspace mapWorkspaceResponse(Map<String, dynamic> backendData) {
    return TeamWorkspace(
      workspaceId: backendData['workspace_id'],
      name: backendData['name'],
      description: backendData['description'],
      ownerId: backendData['owner_id'],
      members:
          (backendData['members'] as List<dynamic>?)
              ?.map(
                (member) => mapMemberResponse(member as Map<String, dynamic>),
              )
              .toList() ??
          [],
      settings: WorkspaceSettings(
        allowMemberInvites: true, // Default value, backend may not provide
        defaultNewMemberRole: WorkspaceRole.viewer, // Default value
      ),
      createdAt: DateTime.parse(backendData['created_at']),
      updatedAt: DateTime.parse(backendData['updated_at']),
    );
  }

  /// Maps backend member response to Flutter WorkspaceMember model
  static WorkspaceMember mapMemberResponse(Map<String, dynamic> backendData) {
    return WorkspaceMember(
      userId: backendData['user_id'],
      role: mapBackendRoleToFlutter(backendData['role']),
      joinedAt: DateTime.parse(backendData['joined_at']),
    );
  }

  /// Maps backend team wallet response to Flutter TeamWallet model
  static TeamWallet mapTeamWalletResponse(Map<String, dynamic> backendData) {
    return TeamWallet(
      workspaceId: backendData['workspace_id'],
      accountUsername: backendData['account_username'] ?? '',
      balance: (backendData['balance'] as num?)?.toInt() ?? 0,
      isFrozen: backendData['is_frozen'] ?? false,
      frozenBy: backendData['frozen_by'],
      frozenAt: backendData['frozen_at'] != null
          ? DateTime.parse(backendData['frozen_at'])
          : null,
      userPermissions: backendData['user_permissions'] ?? {},
      notificationSettings: backendData['notification_settings'] ?? {},
      recentTransactions:
          (backendData['recent_transactions'] as List<dynamic>?)
              ?.map((tx) => mapWalletTransaction(tx as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Maps backend wallet transaction to Flutter WalletTransaction model
  static WalletTransaction mapWalletTransaction(
    Map<String, dynamic> backendData,
  ) {
    return WalletTransaction(
      transactionId: backendData['transaction_id'] ?? '',
      type: backendData['type'] ?? '',
      amount: (backendData['amount'] as num?)?.toInt() ?? 0,
      fromUser: backendData['from_user'],
      toUser: backendData['to_user'],
      timestamp: DateTime.parse(
        backendData['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      description: backendData['description'] ?? '',
    );
  }

  /// Maps backend token request response to Flutter TokenRequest model
  static TokenRequest mapTokenRequestResponse(
    Map<String, dynamic> backendData,
  ) {
    return TokenRequest(
      requestId: backendData['request_id'],
      requesterUserId: backendData['requester_id'],
      amount: (backendData['amount'] as num?)?.toInt() ?? 0,
      reason: backendData['purpose'] ?? '',
      status: _mapTokenRequestStatus(backendData['status']),
      autoApproved: backendData['auto_approved'] ?? false,
      createdAt: DateTime.parse(backendData['created_at']),
      expiresAt: DateTime.parse(
        backendData['expires_at'] ??
            DateTime.now().add(Duration(days: 7)).toIso8601String(),
      ),
      adminComments: backendData['review_comment'],
    );
  }

  /// Maps backend audit entry to Flutter AuditEntry model
  static AuditEntry mapAuditEntry(Map<String, dynamic> backendData) {
    return AuditEntry(
      id: backendData['_id'] ?? backendData['id'] ?? '',
      teamId: backendData['team_id'] ?? backendData['workspace_id'],
      eventType: _mapAuditEventType(backendData['event_type']),
      adminUserId: backendData['admin_user_id'],
      adminUsername: backendData['admin_username'],
      action: backendData['action'],
      memberPermissions: backendData['member_permissions'],
      reason: backendData['reason'],
      timestamp: DateTime.parse(
        backendData['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      transactionContext: backendData['transaction_context'],
      integrityHash: backendData['integrity_hash'] ?? '',
    );
  }

  /// Maps backend compliance report to Flutter ComplianceReport model
  static ComplianceReport mapComplianceReport(
    Map<String, dynamic> backendData,
  ) {
    return ComplianceReport(
      teamId: backendData['team_id'] ?? backendData['workspace_id'],
      reportType: backendData['report_type'],
      generatedAt: DateTime.parse(backendData['generated_at']),
      period: backendData['period'] ?? {},
      summary: backendData['summary'] ?? {},
      auditTrails:
          (backendData['audit_trails'] as List<dynamic>?)
              ?.map((entry) => mapAuditEntry(entry as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Converts backend role strings to Flutter WorkspaceRole enum
  static WorkspaceRole mapBackendRoleToFlutter(String backendRole) {
    switch (backendRole.toLowerCase()) {
      case 'admin':
        return WorkspaceRole.admin;
      case 'editor':
        return WorkspaceRole.editor;
      case 'viewer':
        return WorkspaceRole.viewer;
      default:
        return WorkspaceRole.viewer; // Default fallback
    }
  }

  /// Converts Flutter WorkspaceRole to backend role string
  static String mapFlutterRoleToBackend(WorkspaceRole flutterRole) {
    switch (flutterRole) {
      case WorkspaceRole.admin:
        return 'admin';
      case WorkspaceRole.editor:
        return 'editor';
      case WorkspaceRole.viewer:
        return 'viewer';
    }
  }

  /// Maps backend token request status to Flutter TokenRequestStatus
  static TokenRequestStatus _mapTokenRequestStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return TokenRequestStatus.pending;
      case 'approved':
        return TokenRequestStatus.approved;
      case 'denied':
      case 'rejected':
        return TokenRequestStatus.denied;
      case 'expired':
        return TokenRequestStatus.expired;
      default:
        return TokenRequestStatus.pending;
    }
  }

  /// Maps backend audit event type to Flutter AuditEventType
  static AuditEventType _mapAuditEventType(String? eventType) {
    switch (eventType?.toLowerCase()) {
      case 'sbd_transaction':
        return AuditEventType.sbdTransaction;
      case 'permission_change':
        return AuditEventType.permissionChange;
      case 'account_freeze':
        return AuditEventType.accountFreeze;
      case 'admin_action':
        return AuditEventType.adminAction;
      case 'compliance_export':
        return AuditEventType.complianceExport;
      default:
        return AuditEventType.adminAction; // Default fallback
    }
  }
}
