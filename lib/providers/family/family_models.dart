/// Family Management Data Models
/// All request/response models matching the backend API schema

class Family {
  final String familyId;
  final String name;
  final List<String> adminUserIds;
  final int memberCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isAdmin;
  final String userRole;
  final SBDAccount? sbdAccount;
  final FamilySettings? settings;
  final SuccessionPlan? successionPlan;
  final UsageStats? usageStats;

  Family({
    required this.familyId,
    required this.name,
    required this.adminUserIds,
    required this.memberCount,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.isAdmin,
    required this.userRole,
    this.sbdAccount,
    this.settings,
    this.successionPlan,
    this.usageStats,
  });

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      familyId: json['family_id'] ?? '',
      name: json['name'] ?? '',
      adminUserIds: List<String>.from(json['admin_user_ids'] ?? []),
      memberCount: json['member_count'] ?? 0,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      isActive: json['is_active'] ?? true,
      isAdmin: json['is_admin'] ?? false,
      userRole: json['user_role'] ?? 'member',
      sbdAccount: json['sbd_account'] != null
          ? SBDAccount.fromJson(json['sbd_account'])
          : null,
      settings: json['settings'] != null
          ? FamilySettings.fromJson(json['settings'])
          : null,
      successionPlan: json['succession_plan'] != null
          ? SuccessionPlan.fromJson(json['succession_plan'])
          : null,
      usageStats: json['usage_stats'] != null
          ? UsageStats.fromJson(json['usage_stats'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'family_id': familyId,
      'name': name,
      'admin_user_ids': adminUserIds,
      'member_count': memberCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'is_admin': isAdmin,
      'user_role': userRole,
      if (sbdAccount != null) 'sbd_account': sbdAccount!.toJson(),
      if (settings != null) 'settings': settings!.toJson(),
      if (successionPlan != null) 'succession_plan': successionPlan!.toJson(),
      if (usageStats != null) 'usage_stats': usageStats!.toJson(),
    };
  }
}

class FamilyMember {
  final String userId;
  final String username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String role;
  final String relationshipType;
  final DateTime joinedAt;
  final bool isBackupAdmin;
  final SpendingPermissions? spendingPermissions;

  FamilyMember({
    required this.userId,
    required this.username,
    this.email,
    this.firstName,
    this.lastName,
    required this.role,
    required this.relationshipType,
    required this.joinedAt,
    required this.isBackupAdmin,
    this.spendingPermissions,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      role: json['role'] ?? 'member',
      relationshipType: json['relationship_type'] ?? 'other',
      joinedAt: DateTime.parse(
        json['joined_at'] ?? DateTime.now().toIso8601String(),
      ),
      isBackupAdmin: json['is_backup_admin'] ?? false,
      spendingPermissions: json['spending_permissions'] != null
          ? SpendingPermissions.fromJson(json['spending_permissions'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      if (email != null) 'email': email,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      'role': role,
      'relationship_type': relationshipType,
      'joined_at': joinedAt.toIso8601String(),
      'is_backup_admin': isBackupAdmin,
      if (spendingPermissions != null)
        'spending_permissions': spendingPermissions!.toJson(),
    };
  }

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username;
  }
}

class SBDAccount {
  final String accountId;
  final String? accountUsername;
  final String? accountName;
  final int balance;
  final String currency;
  final bool isFrozen;
  final String? freezeReason;
  final DateTime? frozenAt;
  final Map<String, SpendingPermissions>? memberPermissions;

  SBDAccount({
    required this.accountId,
    this.accountUsername,
    this.accountName,
    required this.balance,
    required this.currency,
    required this.isFrozen,
    this.freezeReason,
    this.frozenAt,
    this.memberPermissions,
  });

  factory SBDAccount.fromJson(Map<String, dynamic> json) {
    Map<String, SpendingPermissions>? permissions;
    if (json['member_permissions'] != null) {
      permissions = {};
      (json['member_permissions'] as Map<String, dynamic>).forEach((
        key,
        value,
      ) {
        permissions![key] = SpendingPermissions.fromJson(value);
      });
    }

    return SBDAccount(
      accountId: json['account_id'] ?? '',
      accountUsername: json['account_username'],
      accountName: json['account_name'],
      balance: json['balance'] ?? 0,
      currency: json['currency'] ?? 'SBD',
      isFrozen: json['is_frozen'] ?? false,
      freezeReason: json['freeze_reason'],
      frozenAt: json['frozen_at'] != null
          ? DateTime.parse(json['frozen_at'])
          : null,
      memberPermissions: permissions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_id': accountId,
      if (accountUsername != null) 'account_username': accountUsername,
      if (accountName != null) 'account_name': accountName,
      'balance': balance,
      'currency': currency,
      'is_frozen': isFrozen,
      if (freezeReason != null) 'freeze_reason': freezeReason,
      if (frozenAt != null) 'frozen_at': frozenAt!.toIso8601String(),
      if (memberPermissions != null)
        'member_permissions': memberPermissions!.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
    };
  }

  /// Get the display name for the account (account_name if available, otherwise account_username)
  String get displayName => accountName ?? accountUsername ?? accountId;

  /// Get the username for QR codes and transfers (account_username if available, otherwise account_id)
  String get qrUsername => accountUsername ?? accountId;
}

class SpendingPermissions {
  final bool canSpend;
  final int spendingLimit;

  SpendingPermissions({required this.canSpend, required this.spendingLimit});

  factory SpendingPermissions.fromJson(Map<String, dynamic> json) {
    return SpendingPermissions(
      canSpend: json['can_spend'] ?? false,
      spendingLimit: json['spending_limit'] ?? -1,
    );
  }

  Map<String, dynamic> toJson() {
    return {'can_spend': canSpend, 'spending_limit': spendingLimit};
  }

  String get limitText {
    if (spendingLimit == -1) return 'Unlimited';
    return '$spendingLimit SBD';
  }
}

class FamilyInvitation {
  final String invitationId;
  final String familyId;
  final String familyName;
  final String invitedBy;
  final String invitedByUsername;
  final String? inviteeEmail;
  final String? inviteeUsername;
  final String relationshipType;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? invitationToken;

  FamilyInvitation({
    required this.invitationId,
    required this.familyId,
    required this.familyName,
    required this.invitedBy,
    required this.invitedByUsername,
    this.inviteeEmail,
    this.inviteeUsername,
    required this.relationshipType,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.invitationToken,
  });

  factory FamilyInvitation.fromJson(Map<String, dynamic> json) {
    // Handle family_name - treat null and empty string as "Unknown Family"
    final familyNameRaw = json['family_name'] as String?;
    final familyName = (familyNameRaw == null || familyNameRaw.trim().isEmpty)
        ? 'Unknown Family'
        : familyNameRaw;

    // Handle invited_by_username - backend might return inviter_username or invited_by_username
    final invitedByUsernameRaw =
        (json['invited_by_username'] ?? json['inviter_username']) as String?;
    final invitedByUsername =
        (invitedByUsernameRaw == null || invitedByUsernameRaw.trim().isEmpty)
        ? 'Unknown'
        : invitedByUsernameRaw;

    // Handle invitee_username - treat empty string as null
    final inviteeUsernameRaw = json['invitee_username'] as String?;
    final inviteeUsername =
        (inviteeUsernameRaw != null && inviteeUsernameRaw.trim().isNotEmpty)
        ? inviteeUsernameRaw
        : null;

    // Handle invitee_email - treat empty string as null
    final inviteeEmailRaw = json['invitee_email'] as String?;
    final inviteeEmail =
        (inviteeEmailRaw != null && inviteeEmailRaw.trim().isNotEmpty)
        ? inviteeEmailRaw
        : null;

    return FamilyInvitation(
      invitationId: json['invitation_id'] ?? '',
      familyId: json['family_id'] ?? '',
      familyName: familyName,
      invitedBy: json['invited_by'] ?? '',
      invitedByUsername: invitedByUsername,
      inviteeEmail: inviteeEmail,
      inviteeUsername: inviteeUsername,
      relationshipType: json['relationship_type'] ?? 'other',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      expiresAt: DateTime.parse(
        json['expires_at'] ??
            DateTime.now().add(Duration(days: 7)).toIso8601String(),
      ),
      invitationToken: json['invitation_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invitation_id': invitationId,
      'family_id': familyId,
      'family_name': familyName,
      'invited_by': invitedBy,
      'invited_by_username': invitedByUsername,
      if (inviteeEmail != null) 'invitee_email': inviteeEmail,
      if (inviteeUsername != null) 'invitee_username': inviteeUsername,
      'relationship_type': relationshipType,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      if (invitationToken != null) 'invitation_token': invitationToken,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isPending => status == 'pending';
}

/// Model for invitations received by the current user
/// Matches GET /family/my-invitations response
class ReceivedInvitation {
  final String invitationId;
  final String familyId;
  final String familyName;
  final String inviterUserId;
  final String inviterUsername;
  final String relationshipType;
  final String status;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String? invitationToken;

  ReceivedInvitation({
    required this.invitationId,
    required this.familyId,
    required this.familyName,
    required this.inviterUserId,
    required this.inviterUsername,
    required this.relationshipType,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    this.invitationToken,
  });

  factory ReceivedInvitation.fromJson(Map<String, dynamic> json) {
    // Get family_name and handle both null and empty string
    final familyNameRaw = json['family_name'] as String?;
    final familyName = (familyNameRaw == null || familyNameRaw.isEmpty)
        ? 'Unknown Family'
        : familyNameRaw;

    // Get inviter_username and handle both null and empty string
    final inviterUsernameRaw = json['inviter_username'] as String?;
    final inviterUsername =
        (inviterUsernameRaw == null || inviterUsernameRaw.isEmpty)
        ? 'Unknown'
        : inviterUsernameRaw;

    return ReceivedInvitation(
      invitationId: json['invitation_id'] ?? '',
      familyId: json['family_id'] ?? '',
      familyName: familyName,
      inviterUserId: json['inviter_user_id'] ?? '',
      inviterUsername: inviterUsername,
      relationshipType: json['relationship_type'] ?? 'other',
      status: json['status'] ?? 'pending',
      expiresAt: DateTime.parse(
        json['expires_at'] ??
            DateTime.now().add(Duration(days: 7)).toIso8601String(),
      ),
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      invitationToken: json['invitation_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invitation_id': invitationId,
      'family_id': familyId,
      'family_name': familyName,
      'inviter_user_id': inviterUserId,
      'inviter_username': inviterUsername,
      'relationship_type': relationshipType,
      'status': status,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      if (invitationToken != null) 'invitation_token': invitationToken,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  bool get isCancelled => status == 'cancelled';

  /// Check if invitation can be responded to (pending and not expired)
  bool get canRespond => isPending && !isExpired;

  /// Get days until expiry (negative if expired)
  int get daysUntilExpiry => expiresAt.difference(DateTime.now()).inDays;

  /// Get hours until expiry
  int get hoursUntilExpiry => expiresAt.difference(DateTime.now()).inHours;

  /// User-friendly expiry text
  String get expiryText {
    if (isExpired) return 'Expired';
    final days = daysUntilExpiry;
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';
    return 'Expires in $days days';
  }

  String get timeUntilExpiry {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
  }
}

class PurchaseRequest {
  final String requestId;
  final String familyId;
  final PurchaseRequester requester;
  final PurchaseItem item;
  final int cost;
  final String status;
  final DateTime createdAt;
  final PurchaseReviewer? reviewedBy;
  final DateTime? reviewedAt;
  final String? denialReason;
  final String? transactionId;

  PurchaseRequest({
    required this.requestId,
    required this.familyId,
    required this.requester,
    required this.item,
    required this.cost,
    required this.status,
    required this.createdAt,
    this.reviewedBy,
    this.reviewedAt,
    this.denialReason,
    this.transactionId,
  });

  factory PurchaseRequest.fromJson(Map<String, dynamic> json) {
    return PurchaseRequest(
      requestId: json['request_id'] ?? '',
      familyId: json['family_id'] ?? '',
      requester: PurchaseRequester.fromJson(json['requester'] ?? {}),
      item: PurchaseItem.fromJson(json['item'] ?? {}),
      cost: json['cost'] ?? 0,
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      reviewedBy: json['reviewed_by'] != null
          ? PurchaseReviewer.fromJson(json['reviewed_by'])
          : null,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'])
          : null,
      denialReason: json['denial_reason'],
      transactionId: json['transaction_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'family_id': familyId,
      'requester': requester.toJson(),
      'item': item.toJson(),
      'cost': cost,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      if (reviewedBy != null) 'reviewed_by': reviewedBy!.toJson(),
      if (reviewedAt != null) 'reviewed_at': reviewedAt!.toIso8601String(),
      if (denialReason != null) 'denial_reason': denialReason,
      if (transactionId != null) 'transaction_id': transactionId,
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isDenied => status == 'denied';
}

class PurchaseRequester {
  final String userId;
  final String username;

  PurchaseRequester({required this.userId, required this.username});

  factory PurchaseRequester.fromJson(Map<String, dynamic> json) {
    return PurchaseRequester(
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'user_id': userId, 'username': username};
  }
}

class PurchaseItem {
  final String itemId;
  final String name;
  final String itemType;
  final String? imageUrl;

  PurchaseItem({
    required this.itemId,
    required this.name,
    required this.itemType,
    this.imageUrl,
  });

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      itemId: json['item_id'] ?? '',
      name: json['name'] ?? '',
      itemType: json['item_type'] ?? '',
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'name': name,
      'item_type': itemType,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }
}

class TokenRequest {
  final String requestId;
  final TokenRequester requester;
  final String? fromUserId;
  final String? fromUsername;
  final int amount;
  final String reason;
  final String status;
  final DateTime createdAt;
  final TokenReviewer? reviewedBy;
  final DateTime? reviewedAt;
  final String? denialReason;
  final String? reviewComments;
  final bool? autoApproved;

  TokenRequest({
    required this.requestId,
    required this.requester,
    this.fromUserId,
    this.fromUsername,
    required this.amount,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reviewedBy,
    this.reviewedAt,
    this.denialReason,
    this.reviewComments,
    this.autoApproved,
  });

  factory TokenRequest.fromJson(Map<String, dynamic> json) {
    // If a nested 'requester' object exists, use it; otherwise allow TokenRequester
    // to inspect the top-level JSON for common fields (requester_username, from_username, username).
    final requesterSource = json['requester'] is Map
        ? Map<String, dynamic>.from(json['requester'])
        : Map<String, dynamic>.from(json);

    return TokenRequest(
      requestId: json['request_id'] ?? '',
      requester: TokenRequester.fromJson(requesterSource),
      fromUserId: json['from_user_id'] ?? json['fromUserId'],
      fromUsername: json['from_username'] ?? json['fromUsername'],
      amount: json['amount'] ?? 0,
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      reviewedBy: json['reviewed_by'] != null
          ? TokenReviewer.fromJson(json['reviewed_by'])
          : null,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'])
          : null,
      denialReason: json['denial_reason'],
      reviewComments: json['review_comments'],
      autoApproved: json['auto_approved'] ?? json['autoApproved'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'requester': requester.toJson(),
      if (fromUserId != null) 'from_user_id': fromUserId,
      if (fromUsername != null) 'from_username': fromUsername,
      'amount': amount,
      'reason': reason,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      if (reviewedBy != null) 'reviewed_by': reviewedBy!.toJson(),
      if (reviewedAt != null) 'reviewed_at': reviewedAt!.toIso8601String(),
      if (denialReason != null) 'denial_reason': denialReason,
      if (reviewComments != null) 'review_comments': reviewComments,
      if (autoApproved != null) 'auto_approved': autoApproved,
    };
  }

    TokenRequest copyWith({
      String? requestId,
      TokenRequester? requester,
      String? fromUserId,
      String? fromUsername,
      int? amount,
      String? reason,
      String? status,
      DateTime? createdAt,
      TokenReviewer? reviewedBy,
      DateTime? reviewedAt,
      String? denialReason,
      String? reviewComments,
      bool? autoApproved,
    }) {
      return TokenRequest(
        requestId: requestId ?? this.requestId,
        requester: requester ?? this.requester,
        fromUserId: fromUserId ?? this.fromUserId,
        fromUsername: fromUsername ?? this.fromUsername,
        amount: amount ?? this.amount,
        reason: reason ?? this.reason,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        reviewedBy: reviewedBy ?? this.reviewedBy,
        reviewedAt: reviewedAt ?? this.reviewedAt,
        denialReason: denialReason ?? this.denialReason,
        reviewComments: reviewComments ?? this.reviewComments,
        autoApproved: autoApproved ?? this.autoApproved,
      );
    }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isDenied => status == 'denied';
}

class TokenRequester {
  final String userId;
  final String username;

  TokenRequester({required this.userId, required this.username});

  factory TokenRequester.fromJson(Map<String, dynamic> json) {
    // Be defensive: backend may return different shapes for requester.
    // Try several keys / nested objects and fall back to userId or 'Unknown'.
    String userId = '';
    try {
      userId =
          (json['user_id'] ?? json['requester_user_id'] ?? json['userId'] ?? '')
              as String? ??
          '';
    } catch (_) {
      userId = '';
    }

    String username = '';
    try {
      // Common locations / keys
      if (json.containsKey('username') &&
          json['username'] != null &&
          json['username'].toString().trim().isNotEmpty) {
        username = json['username'].toString();
      } else if (json.containsKey('requester_username') &&
          json['requester_username'] != null &&
          json['requester_username'].toString().trim().isNotEmpty) {
        username = json['requester_username'].toString();
      } else if (json.containsKey('user') &&
          json['user'] is Map &&
          (json['user']['username'] ?? json['user']['user_name']) != null) {
        username = (json['user']['username'] ?? json['user']['user_name'])
            .toString();
      } else if (json.containsKey('requester') &&
          json['requester'] is Map &&
          (json['requester']['username'] ?? json['requester']['user_name']) !=
              null) {
        username =
            (json['requester']['username'] ?? json['requester']['user_name'])
                .toString();
      } else if (json.containsKey('email') &&
          json['email'] != null &&
          json['email'].toString().trim().isNotEmpty) {
        username = json['email'].toString();
      } else if (userId.isNotEmpty) {
        username = userId;
      } else {
        username = 'Unknown';
      }
    } catch (_) {
      username = userId.isNotEmpty ? userId : 'Unknown';
    }

    return TokenRequester(userId: userId, username: username);
  }

  Map<String, dynamic> toJson() {
    return {'user_id': userId, 'username': username};
  }
}

class TokenReviewer {
  final String userId;
  final String username;

  TokenReviewer({required this.userId, required this.username});

  factory TokenReviewer.fromJson(Map<String, dynamic> json) {
    return TokenReviewer(
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'user_id': userId, 'username': username};
  }
}

class PurchaseReviewer {
  final String userId;
  final String username;

  PurchaseReviewer({required this.userId, required this.username});

  factory PurchaseReviewer.fromJson(Map<String, dynamic> json) {
    return PurchaseReviewer(
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'user_id': userId, 'username': username};
  }
}

class FamilyNotification {
  final String notificationId;
  final String familyId;
  final String userId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime createdAt;

  FamilyNotification({
    required this.notificationId,
    required this.familyId,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.metadata,
    required this.isRead,
    required this.createdAt,
  });

  factory FamilyNotification.fromJson(Map<String, dynamic> json) {
    return FamilyNotification(
      notificationId: json['notification_id'] ?? '',
      familyId: json['family_id'] ?? '',
      userId: json['user_id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      metadata: json['metadata'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': notificationId,
      'family_id': familyId,
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      if (metadata != null) 'metadata': metadata,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class NotificationPreferences {
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;
  final bool notifyOnSpend;
  final bool notifyOnDeposit;
  final int largeTransactionThreshold;

  NotificationPreferences({
    required this.emailNotifications,
    required this.pushNotifications,
    required this.smsNotifications,
    required this.notifyOnSpend,
    required this.notifyOnDeposit,
    required this.largeTransactionThreshold,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      emailNotifications: json['email_notifications'] ?? true,
      pushNotifications: json['push_notifications'] ?? true,
      smsNotifications: json['sms_notifications'] ?? false,
      notifyOnSpend: json['notify_on_spend'] ?? true,
      notifyOnDeposit: json['notify_on_deposit'] ?? true,
      largeTransactionThreshold: json['large_transaction_threshold'] ?? 1000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email_notifications': emailNotifications,
      'push_notifications': pushNotifications,
      'sms_notifications': smsNotifications,
      'notify_on_spend': notifyOnSpend,
      'notify_on_deposit': notifyOnDeposit,
      'large_transaction_threshold': largeTransactionThreshold,
    };
  }
}

class Transaction {
  final String transactionId;
  final String familyId;
  final String userId;
  final String username;
  final String type;
  final int amount;
  final String? description;
  final DateTime createdAt;

  Transaction({
    required this.transactionId,
    required this.familyId,
    required this.userId,
    required this.username,
    required this.type,
    required this.amount,
    this.description,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      transactionId: json['transaction_id'] ?? '',
      familyId: json['family_id'] ?? '',
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      type: json['type'] ?? '',
      amount: json['amount'] ?? 0,
      description: json['description'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'family_id': familyId,
      'user_id': userId,
      'username': username,
      'type': type,
      'amount': amount,
      if (description != null) 'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class FamilySettings {
  final bool requireAdminApprovalForSpending;
  final int defaultSpendingLimit;
  final bool allowSelfInvite;

  FamilySettings({
    required this.requireAdminApprovalForSpending,
    required this.defaultSpendingLimit,
    required this.allowSelfInvite,
  });

  factory FamilySettings.fromJson(Map<String, dynamic> json) {
    return FamilySettings(
      requireAdminApprovalForSpending:
          json['require_admin_approval_for_spending'] ?? true,
      defaultSpendingLimit: json['default_spending_limit'] ?? 100,
      allowSelfInvite: json['allow_self_invite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'require_admin_approval_for_spending': requireAdminApprovalForSpending,
      'default_spending_limit': defaultSpendingLimit,
      'allow_self_invite': allowSelfInvite,
    };
  }
}

class SuccessionPlan {
  final List<String> backupAdminIds;
  final DateTime? lastUpdated;

  SuccessionPlan({required this.backupAdminIds, this.lastUpdated});

  factory SuccessionPlan.fromJson(Map<String, dynamic> json) {
    return SuccessionPlan(
      backupAdminIds: List<String>.from(json['backup_admin_ids'] ?? []),
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'backup_admin_ids': backupAdminIds,
      if (lastUpdated != null) 'last_updated': lastUpdated!.toIso8601String(),
    };
  }
}

class UsageStats {
  final int totalTransactions;
  final int totalSpent;
  final int totalReceived;
  final DateTime? lastActivity;

  UsageStats({
    required this.totalTransactions,
    required this.totalSpent,
    required this.totalReceived,
    this.lastActivity,
  });

  factory UsageStats.fromJson(Map<String, dynamic> json) {
    return UsageStats(
      totalTransactions: json['total_transactions'] ?? 0,
      totalSpent: json['total_spent'] ?? 0,
      totalReceived: json['total_received'] ?? 0,
      lastActivity: json['last_activity'] != null
          ? DateTime.parse(json['last_activity'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_transactions': totalTransactions,
      'total_spent': totalSpent,
      'total_received': totalReceived,
      if (lastActivity != null)
        'last_activity': lastActivity!.toIso8601String(),
    };
  }
}

class AdminAction {
  final String actionId;
  final String familyId;
  final String performedBy;
  final String performedByUsername;
  final String actionType;
  final String? targetUserId;
  final String? targetUsername;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  AdminAction({
    required this.actionId,
    required this.familyId,
    required this.performedBy,
    required this.performedByUsername,
    required this.actionType,
    this.targetUserId,
    this.targetUsername,
    this.metadata,
    required this.createdAt,
  });

  factory AdminAction.fromJson(Map<String, dynamic> json) {
    return AdminAction(
      actionId: json['action_id'] ?? '',
      familyId: json['family_id'] ?? '',
      performedBy: json['performed_by'] ?? '',
      performedByUsername: json['performed_by_username'] ?? '',
      actionType: json['action_type'] ?? '',
      targetUserId: json['target_user_id'],
      targetUsername: json['target_username'],
      metadata: json['metadata'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action_id': actionId,
      'family_id': familyId,
      'performed_by': performedBy,
      'performed_by_username': performedByUsername,
      'action_type': actionType,
      if (targetUserId != null) 'target_user_id': targetUserId,
      if (targetUsername != null) 'target_username': targetUsername,
      if (metadata != null) 'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Request models
class CreateFamilyRequest {
  final String? name;

  CreateFamilyRequest({this.name});

  Map<String, dynamic> toJson() {
    return {if (name != null) 'name': name};
  }
}

class InviteMemberRequest {
  final String identifier;
  final String identifierType;
  final String relationshipType;

  InviteMemberRequest({
    required this.identifier,
    required this.identifierType,
    required this.relationshipType,
  });

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'identifier_type': identifierType,
      'relationship_type': relationshipType,
    };
  }
}

class UpdateSpendingPermissionsRequest {
  final String userId;
  final int spendingLimit;
  final bool canSpend;

  UpdateSpendingPermissionsRequest({
    required this.userId,
    required this.spendingLimit,
    required this.canSpend,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'spending_limit': spendingLimit,
      'can_spend': canSpend,
    };
  }
}

class FreezeAccountRequest {
  final String action;
  final String? reason;

  FreezeAccountRequest({required this.action, this.reason});

  Map<String, dynamic> toJson() {
    return {'action': action, if (reason != null) 'reason': reason};
  }
}

class CreateTokenRequestRequest {
  final int amount;
  final String reason;

  CreateTokenRequestRequest({required this.amount, required this.reason});

  Map<String, dynamic> toJson() {
    return {'amount': amount, 'reason': reason};
  }
}

class ReviewTokenRequestRequest {
  final String action;
  final String? comments;

  ReviewTokenRequestRequest({required this.action, this.comments});

  Map<String, dynamic> toJson() {
    return {'action': action, if (comments != null) 'comments': comments};
  }
}

class RespondToInvitationRequest {
  final String action;

  RespondToInvitationRequest({required this.action});

  Map<String, dynamic> toJson() {
    return {'action': action};
  }
}

class AdminActionRequest {
  final String action;

  AdminActionRequest({required this.action});

  Map<String, dynamic> toJson() {
    return {'action': action};
  }
}

class BackupAdminRequest {
  final String action;

  BackupAdminRequest({required this.action});

  Map<String, dynamic> toJson() {
    return {'action': action};
  }
}

class MarkNotificationsReadRequest {
  final List<String> notificationIds;

  MarkNotificationsReadRequest({required this.notificationIds});

  Map<String, dynamic> toJson() {
    return {'notification_ids': notificationIds};
  }
}
