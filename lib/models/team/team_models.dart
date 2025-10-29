import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'team_models.g.dart';

enum WorkspaceRole {
  @JsonValue('admin')
  admin,
  @JsonValue('editor')
  editor,
  @JsonValue('viewer')
  viewer;

  String get displayName {
    switch (this) {
      case WorkspaceRole.admin:
        return 'Admin';
      case WorkspaceRole.editor:
        return 'Editor';
      case WorkspaceRole.viewer:
        return 'Viewer';
    }
  }

  bool get canEdit => this == admin || this == editor;
  bool get canInvite => this == admin;
  bool get canDelete => this == admin;
}

enum TokenRequestStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('denied')
  denied,
  @JsonValue('expired')
  expired;

  String get displayName {
    switch (this) {
      case TokenRequestStatus.pending:
        return 'Pending';
      case TokenRequestStatus.approved:
        return 'Approved';
      case TokenRequestStatus.denied:
        return 'Denied';
      case TokenRequestStatus.expired:
        return 'Expired';
    }
  }

  Color get color {
    switch (this) {
      case TokenRequestStatus.pending:
        return Colors.orange;
      case TokenRequestStatus.approved:
        return Colors.green;
      case TokenRequestStatus.denied:
        return Colors.red;
      case TokenRequestStatus.expired:
        return Colors.grey;
    }
  }
}

enum AuditEventType {
  @JsonValue('sbd_transaction')
  sbdTransaction,
  @JsonValue('permission_change')
  permissionChange,
  @JsonValue('account_freeze')
  accountFreeze,
  @JsonValue('admin_action')
  adminAction,
  @JsonValue('compliance_export')
  complianceExport;

  String get displayName {
    switch (this) {
      case AuditEventType.sbdTransaction:
        return 'SBD Transaction';
      case AuditEventType.permissionChange:
        return 'Permission Change';
      case AuditEventType.accountFreeze:
        return 'Account Freeze';
      case AuditEventType.adminAction:
        return 'Admin Action';
      case AuditEventType.complianceExport:
        return 'Compliance Export';
    }
  }
}

@JsonSerializable()
class TeamWorkspace {
  @JsonKey(name: 'workspace_id')
  final String workspaceId;
  final String name;
  final String? description;
  @JsonKey(name: 'owner_id')
  final String ownerId;
  final List<WorkspaceMember> members;
  final WorkspaceSettings settings;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  TeamWorkspace({
    required this.workspaceId,
    required this.name,
    this.description,
    required this.ownerId,
    required this.members,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeamWorkspace.fromJson(Map<String, dynamic> json) =>
      _$TeamWorkspaceFromJson(json);
  Map<String, dynamic> toJson() => _$TeamWorkspaceToJson(this);

  TeamWorkspace copyWith({
    String? workspaceId,
    String? name,
    String? description,
    String? ownerId,
    List<WorkspaceMember>? members,
    WorkspaceSettings? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamWorkspace(
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      members: members ?? this.members,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@JsonSerializable()
class WorkspaceMember {
  @JsonKey(name: 'user_id')
  final String userId;
  final WorkspaceRole role;
  @JsonKey(name: 'joined_at')
  final DateTime joinedAt;

  WorkspaceMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  factory WorkspaceMember.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceMemberFromJson(json);
  Map<String, dynamic> toJson() => _$WorkspaceMemberToJson(this);

  WorkspaceMember copyWith({
    String? userId,
    WorkspaceRole? role,
    DateTime? joinedAt,
  }) {
    return WorkspaceMember(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

@JsonSerializable()
class WorkspaceSettings {
  @JsonKey(name: 'allow_member_invites')
  final bool allowMemberInvites;
  @JsonKey(name: 'default_new_member_role')
  final WorkspaceRole defaultNewMemberRole;

  WorkspaceSettings({
    required this.allowMemberInvites,
    required this.defaultNewMemberRole,
  });

  factory WorkspaceSettings.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$WorkspaceSettingsToJson(this);

  WorkspaceSettings copyWith({
    bool? allowMemberInvites,
    WorkspaceRole? defaultNewMemberRole,
  }) {
    return WorkspaceSettings(
      allowMemberInvites: allowMemberInvites ?? this.allowMemberInvites,
      defaultNewMemberRole: defaultNewMemberRole ?? this.defaultNewMemberRole,
    );
  }
}

@JsonSerializable()
class TeamWallet {
  @JsonKey(name: 'workspace_id')
  final String workspaceId;
  @JsonKey(name: 'account_username')
  final String accountUsername;
  final int balance;
  @JsonKey(name: 'is_frozen')
  final bool isFrozen;
  @JsonKey(name: 'frozen_by')
  final String? frozenBy;
  @JsonKey(name: 'frozen_at')
  final DateTime? frozenAt;
  @JsonKey(name: 'user_permissions')
  final Map<String, dynamic> userPermissions;
  @JsonKey(name: 'notification_settings')
  final Map<String, dynamic> notificationSettings;
  @JsonKey(name: 'recent_transactions')
  final List<WalletTransaction> recentTransactions;

  TeamWallet({
    required this.workspaceId,
    required this.accountUsername,
    required this.balance,
    required this.isFrozen,
    this.frozenBy,
    this.frozenAt,
    required this.userPermissions,
    required this.notificationSettings,
    required this.recentTransactions,
  });

  factory TeamWallet.fromJson(Map<String, dynamic> json) =>
      _$TeamWalletFromJson(json);
  Map<String, dynamic> toJson() => _$TeamWalletToJson(this);
}

@JsonSerializable()
class WalletTransaction {
  @JsonKey(name: 'transaction_id')
  final String transactionId;
  final String type;
  final int amount;
  @JsonKey(name: 'from_user')
  final String? fromUser;
  @JsonKey(name: 'to_user')
  final String? toUser;
  final DateTime timestamp;
  final String description;

  WalletTransaction({
    required this.transactionId,
    required this.type,
    required this.amount,
    this.fromUser,
    this.toUser,
    required this.timestamp,
    required this.description,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      _$WalletTransactionFromJson(json);
  Map<String, dynamic> toJson() => _$WalletTransactionToJson(this);
}

@JsonSerializable()
class TokenRequest {
  @JsonKey(name: 'request_id')
  final String requestId;
  @JsonKey(name: 'requester_user_id')
  final String requesterUserId;
  final int amount;
  final String reason;
  final TokenRequestStatus status;
  @JsonKey(name: 'auto_approved')
  final bool autoApproved;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;
  @JsonKey(name: 'admin_comments')
  final String? adminComments;

  TokenRequest({
    required this.requestId,
    required this.requesterUserId,
    required this.amount,
    required this.reason,
    required this.status,
    required this.autoApproved,
    required this.createdAt,
    required this.expiresAt,
    this.adminComments,
  });

  factory TokenRequest.fromJson(Map<String, dynamic> json) =>
      _$TokenRequestFromJson(json);
  Map<String, dynamic> toJson() => _$TokenRequestToJson(this);
}

@JsonSerializable()
class AuditEntry {
  @JsonKey(name: '_id')
  final String id;
  @JsonKey(name: 'team_id')
  final String teamId;
  @JsonKey(name: 'event_type')
  final AuditEventType eventType;
  @JsonKey(name: 'admin_user_id')
  final String? adminUserId;
  @JsonKey(name: 'admin_username')
  final String? adminUsername;
  final String? action;
  final Map<String, dynamic>? memberPermissions;
  final String? reason;
  final DateTime timestamp;
  @JsonKey(name: 'transaction_context')
  final Map<String, dynamic>? transactionContext;
  @JsonKey(name: 'integrity_hash')
  final String integrityHash;

  AuditEntry({
    required this.id,
    required this.teamId,
    required this.eventType,
    this.adminUserId,
    this.adminUsername,
    this.action,
    this.memberPermissions,
    this.reason,
    required this.timestamp,
    this.transactionContext,
    required this.integrityHash,
  });

  factory AuditEntry.fromJson(Map<String, dynamic> json) =>
      _$AuditEntryFromJson(json);
  Map<String, dynamic> toJson() => _$AuditEntryToJson(this);
}

@JsonSerializable()
class ComplianceReport {
  @JsonKey(name: 'team_id')
  final String teamId;
  @JsonKey(name: 'report_type')
  final String reportType;
  @JsonKey(name: 'generated_at')
  final DateTime generatedAt;
  final Map<String, dynamic> period;
  final Map<String, dynamic> summary;
  @JsonKey(name: 'audit_trails')
  final List<AuditEntry> auditTrails;

  ComplianceReport({
    required this.teamId,
    required this.reportType,
    required this.generatedAt,
    required this.period,
    required this.summary,
    required this.auditTrails,
  });

  factory ComplianceReport.fromJson(Map<String, dynamic> json) =>
      _$ComplianceReportFromJson(json);
  Map<String, dynamic> toJson() => _$ComplianceReportToJson(this);
}

@JsonSerializable()
class SpendingPermissions {
  @JsonKey(name: 'member_permissions')
  final Map<String, Map<String, dynamic>> memberPermissions;

  SpendingPermissions({required this.memberPermissions});

  factory SpendingPermissions.fromJson(Map<String, dynamic> json) =>
      _$SpendingPermissionsFromJson(json);
  Map<String, dynamic> toJson() => _$SpendingPermissionsToJson(this);
}

@JsonSerializable()
class RateLimitInfo {
  final int limit;
  final int remaining;
  final int reset;

  RateLimitInfo({
    required this.limit,
    required this.remaining,
    required this.reset,
  });

  factory RateLimitInfo.fromJson(Map<String, dynamic> json) =>
      _$RateLimitInfoFromJson(json);
  Map<String, dynamic> toJson() => _$RateLimitInfoToJson(this);

  bool get isExceeded => remaining <= 0;
  Duration get timeUntilReset =>
      Duration(seconds: reset - DateTime.now().millisecondsSinceEpoch ~/ 1000);
}
