// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeamWorkspace _$TeamWorkspaceFromJson(Map<String, dynamic> json) =>
    TeamWorkspace(
      workspaceId: json['workspace_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      ownerId: json['owner_id'] as String,
      members: (json['members'] as List<dynamic>)
          .map((e) => WorkspaceMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      settings: WorkspaceSettings.fromJson(
        json['settings'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$TeamWorkspaceToJson(TeamWorkspace instance) =>
    <String, dynamic>{
      'workspace_id': instance.workspaceId,
      'name': instance.name,
      'description': instance.description,
      'owner_id': instance.ownerId,
      'members': instance.members,
      'settings': instance.settings,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

WorkspaceMember _$WorkspaceMemberFromJson(Map<String, dynamic> json) =>
    WorkspaceMember(
      userId: json['user_id'] as String,
      role: $enumDecode(_$WorkspaceRoleEnumMap, json['role']),
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );

Map<String, dynamic> _$WorkspaceMemberToJson(WorkspaceMember instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'role': _$WorkspaceRoleEnumMap[instance.role]!,
      'joined_at': instance.joinedAt.toIso8601String(),
    };

const _$WorkspaceRoleEnumMap = {
  WorkspaceRole.admin: 'admin',
  WorkspaceRole.editor: 'editor',
  WorkspaceRole.viewer: 'viewer',
};

WorkspaceSettings _$WorkspaceSettingsFromJson(Map<String, dynamic> json) =>
    WorkspaceSettings(
      allowMemberInvites: json['allow_member_invites'] as bool,
      defaultNewMemberRole: $enumDecode(
        _$WorkspaceRoleEnumMap,
        json['default_new_member_role'],
      ),
    );

Map<String, dynamic> _$WorkspaceSettingsToJson(WorkspaceSettings instance) =>
    <String, dynamic>{
      'allow_member_invites': instance.allowMemberInvites,
      'default_new_member_role':
          _$WorkspaceRoleEnumMap[instance.defaultNewMemberRole]!,
    };

TeamWallet _$TeamWalletFromJson(Map<String, dynamic> json) => TeamWallet(
  workspaceId: json['workspace_id'] as String,
  accountUsername: json['account_username'] as String,
  balance: (json['balance'] as num).toInt(),
  isFrozen: json['is_frozen'] as bool,
  frozenBy: json['frozen_by'] as String?,
  frozenAt: json['frozen_at'] == null
      ? null
      : DateTime.parse(json['frozen_at'] as String),
  userPermissions: json['user_permissions'] as Map<String, dynamic>,
  notificationSettings: json['notification_settings'] as Map<String, dynamic>,
  recentTransactions: (json['recent_transactions'] as List<dynamic>)
      .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$TeamWalletToJson(TeamWallet instance) =>
    <String, dynamic>{
      'workspace_id': instance.workspaceId,
      'account_username': instance.accountUsername,
      'balance': instance.balance,
      'is_frozen': instance.isFrozen,
      'frozen_by': instance.frozenBy,
      'frozen_at': instance.frozenAt?.toIso8601String(),
      'user_permissions': instance.userPermissions,
      'notification_settings': instance.notificationSettings,
      'recent_transactions': instance.recentTransactions,
    };

WalletTransaction _$WalletTransactionFromJson(Map<String, dynamic> json) =>
    WalletTransaction(
      transactionId: json['transaction_id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toInt(),
      fromUser: json['from_user'] as String?,
      toUser: json['to_user'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      description: json['description'] as String,
    );

Map<String, dynamic> _$WalletTransactionToJson(WalletTransaction instance) =>
    <String, dynamic>{
      'transaction_id': instance.transactionId,
      'type': instance.type,
      'amount': instance.amount,
      'from_user': instance.fromUser,
      'to_user': instance.toUser,
      'timestamp': instance.timestamp.toIso8601String(),
      'description': instance.description,
    };

TokenRequest _$TokenRequestFromJson(Map<String, dynamic> json) => TokenRequest(
  requestId: json['request_id'] as String,
  requesterUserId: json['requester_user_id'] as String,
  amount: (json['amount'] as num).toInt(),
  reason: json['reason'] as String,
  status: $enumDecode(_$TokenRequestStatusEnumMap, json['status']),
  autoApproved: json['auto_approved'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
  expiresAt: DateTime.parse(json['expires_at'] as String),
  adminComments: json['admin_comments'] as String?,
);

Map<String, dynamic> _$TokenRequestToJson(TokenRequest instance) =>
    <String, dynamic>{
      'request_id': instance.requestId,
      'requester_user_id': instance.requesterUserId,
      'amount': instance.amount,
      'reason': instance.reason,
      'status': _$TokenRequestStatusEnumMap[instance.status]!,
      'auto_approved': instance.autoApproved,
      'created_at': instance.createdAt.toIso8601String(),
      'expires_at': instance.expiresAt.toIso8601String(),
      'admin_comments': instance.adminComments,
    };

const _$TokenRequestStatusEnumMap = {
  TokenRequestStatus.pending: 'pending',
  TokenRequestStatus.approved: 'approved',
  TokenRequestStatus.denied: 'denied',
  TokenRequestStatus.expired: 'expired',
};

AuditEntry _$AuditEntryFromJson(Map<String, dynamic> json) => AuditEntry(
  id: json['_id'] as String,
  teamId: json['team_id'] as String,
  eventType: $enumDecode(_$AuditEventTypeEnumMap, json['event_type']),
  adminUserId: json['admin_user_id'] as String?,
  adminUsername: json['admin_username'] as String?,
  action: json['action'] as String?,
  memberPermissions: json['memberPermissions'] as Map<String, dynamic>?,
  reason: json['reason'] as String?,
  timestamp: DateTime.parse(json['timestamp'] as String),
  transactionContext: json['transaction_context'] as Map<String, dynamic>?,
  integrityHash: json['integrity_hash'] as String,
);

Map<String, dynamic> _$AuditEntryToJson(AuditEntry instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'team_id': instance.teamId,
      'event_type': _$AuditEventTypeEnumMap[instance.eventType]!,
      'admin_user_id': instance.adminUserId,
      'admin_username': instance.adminUsername,
      'action': instance.action,
      'memberPermissions': instance.memberPermissions,
      'reason': instance.reason,
      'timestamp': instance.timestamp.toIso8601String(),
      'transaction_context': instance.transactionContext,
      'integrity_hash': instance.integrityHash,
    };

const _$AuditEventTypeEnumMap = {
  AuditEventType.sbdTransaction: 'sbd_transaction',
  AuditEventType.permissionChange: 'permission_change',
  AuditEventType.accountFreeze: 'account_freeze',
  AuditEventType.adminAction: 'admin_action',
  AuditEventType.complianceExport: 'compliance_export',
};

ComplianceReport _$ComplianceReportFromJson(Map<String, dynamic> json) =>
    ComplianceReport(
      teamId: json['team_id'] as String,
      reportType: json['report_type'] as String,
      generatedAt: DateTime.parse(json['generated_at'] as String),
      period: json['period'] as Map<String, dynamic>,
      summary: json['summary'] as Map<String, dynamic>,
      auditTrails: (json['audit_trails'] as List<dynamic>)
          .map((e) => AuditEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ComplianceReportToJson(ComplianceReport instance) =>
    <String, dynamic>{
      'team_id': instance.teamId,
      'report_type': instance.reportType,
      'generated_at': instance.generatedAt.toIso8601String(),
      'period': instance.period,
      'summary': instance.summary,
      'audit_trails': instance.auditTrails,
    };

SpendingPermissions _$SpendingPermissionsFromJson(Map<String, dynamic> json) =>
    SpendingPermissions(
      memberPermissions: (json['member_permissions'] as Map<String, dynamic>)
          .map((k, e) => MapEntry(k, e as Map<String, dynamic>)),
    );

Map<String, dynamic> _$SpendingPermissionsToJson(
  SpendingPermissions instance,
) => <String, dynamic>{'member_permissions': instance.memberPermissions};

RateLimitInfo _$RateLimitInfoFromJson(Map<String, dynamic> json) =>
    RateLimitInfo(
      limit: (json['limit'] as num).toInt(),
      remaining: (json['remaining'] as num).toInt(),
      reset: (json['reset'] as num).toInt(),
    );

Map<String, dynamic> _$RateLimitInfoToJson(RateLimitInfo instance) =>
    <String, dynamic>{
      'limit': instance.limit,
      'remaining': instance.remaining,
      'reset': instance.reset,
    };
