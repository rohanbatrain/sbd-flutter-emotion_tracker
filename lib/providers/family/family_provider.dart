import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/family/family_models.dart' as models;
import 'package:emotion_tracker/providers/family/family_api_service.dart';

// State classes for family management
class FamilyListState {
  final List<models.Family> families;
  final bool isLoading;
  final String? error;

  FamilyListState({
    required this.families,
    required this.isLoading,
    this.error,
  });

  FamilyListState copyWith({
    List<models.Family>? families,
    bool? isLoading,
    String? error,
  }) {
    return FamilyListState(
      families: families ?? this.families,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FamilyDetailsState {
  final models.Family? family;
  final List<models.FamilyMember> members;
  final List<models.FamilyInvitation> invitations;
  final models.SBDAccount? sbdAccount;
  final bool isLoading;
  final String? error;

  FamilyDetailsState({
    this.family,
    required this.members,
    required this.invitations,
    this.sbdAccount,
    required this.isLoading,
    this.error,
  });

  FamilyDetailsState copyWith({
    models.Family? family,
    List<models.FamilyMember>? members,
    List<models.FamilyInvitation>? invitations,
    models.SBDAccount? sbdAccount,
    bool? isLoading,
    String? error,
  }) {
    return FamilyDetailsState(
      family: family ?? this.family,
      members: members ?? this.members,
      invitations: invitations ?? this.invitations,
      sbdAccount: sbdAccount ?? this.sbdAccount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Family List Provider
class FamilyListNotifier extends StateNotifier<FamilyListState> {
  final FamilyApiService _apiService;

  FamilyListNotifier(this._apiService)
    : super(FamilyListState(families: [], isLoading: false));

  Future<void> loadFamilies() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final families = await _apiService.getMyFamilies();
      state = state.copyWith(families: families, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<models.Family?> createFamily({String? name}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final family = await _apiService.createFamily(name: name);
      state = state.copyWith(
        families: [...state.families, family],
        isLoading: false,
      );
      return family;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> deleteFamily(String familyId) async {
    try {
      await _apiService.deleteFamily(familyId);
      state = state.copyWith(
        families: state.families.where((f) => f.familyId != familyId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final familyListProvider =
    StateNotifierProvider<FamilyListNotifier, FamilyListState>((ref) {
      final apiService = ref.watch(familyApiServiceProvider);
      return FamilyListNotifier(apiService);
    });

// Family Details Provider
class FamilyDetailsNotifier extends StateNotifier<FamilyDetailsState> {
  final FamilyApiService _apiService;
  final String familyId;

  FamilyDetailsNotifier(this._apiService, this.familyId)
    : super(FamilyDetailsState(members: [], invitations: [], isLoading: false));

  Future<void> loadFamilyDetails() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final family = await _apiService.getFamilyDetails(familyId);
      final members = await _apiService.getFamilyMembers(familyId);
      final invitations = await _apiService.getFamilyInvitations(familyId);

      models.SBDAccount? sbdAccount;
      try {
        sbdAccount = await _apiService.getSBDAccount(familyId);
      } catch (e) {
        // SBD account might not be accessible to non-admins
      }

      state = state.copyWith(
        family: family,
        members: members,
        invitations: invitations,
        sbdAccount: sbdAccount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> inviteMember({
    required String identifier,
    required String identifierType,
    required String relationshipType,
  }) async {
    try {
      final request = models.InviteMemberRequest(
        identifier: identifier,
        identifierType: identifierType,
        relationshipType: relationshipType,
      );
      final invitation = await _apiService.inviteMember(familyId, request);
      state = state.copyWith(invitations: [...state.invitations, invitation]);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> removeMember(String memberId) async {
    try {
      await _apiService.removeMember(familyId, memberId);
      state = state.copyWith(
        members: state.members.where((m) => m.userId != memberId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> cancelInvitation(String invitationId) async {
    try {
      await _apiService.cancelInvitation(familyId, invitationId);
      state = state.copyWith(
        invitations: state.invitations
            .where((i) => i.invitationId != invitationId)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> promoteToAdmin(String userId) async {
    try {
      await _apiService.promoteToAdmin(familyId, userId);
      await loadFamilyDetails(); // Refresh to get updated roles
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> demoteFromAdmin(String userId) async {
    try {
      await _apiService.demoteFromAdmin(familyId, userId);
      await loadFamilyDetails();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final familyDetailsProvider =
    StateNotifierProvider.family<
      FamilyDetailsNotifier,
      FamilyDetailsState,
      String
    >((ref, familyId) {
      final apiService = ref.watch(familyApiServiceProvider);
      return FamilyDetailsNotifier(apiService, familyId);
    });

// Token Requests Provider
class TokenRequestsState {
  final List<models.TokenRequest> pendingRequests;
  final List<models.TokenRequest> myRequests;
  final bool isLoading;
  final String? error;

  TokenRequestsState({
    required this.pendingRequests,
    required this.myRequests,
    required this.isLoading,
    this.error,
  });

  TokenRequestsState copyWith({
    List<models.TokenRequest>? pendingRequests,
    List<models.TokenRequest>? myRequests,
    bool? isLoading,
    String? error,
  }) {
    return TokenRequestsState(
      pendingRequests: pendingRequests ?? this.pendingRequests,
      myRequests: myRequests ?? this.myRequests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TokenRequestsNotifier extends StateNotifier<TokenRequestsState> {
  final FamilyApiService _apiService;
  final String familyId;

  TokenRequestsNotifier(this._apiService, this.familyId)
    : super(
        TokenRequestsState(
          pendingRequests: [],
          myRequests: [],
          isLoading: false,
        ),
      );

  Future<void> loadRequests() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final pending = await _apiService.getPendingTokenRequests(familyId);
      final myRequests = await _apiService.getMyTokenRequests(familyId);
      state = state.copyWith(
        pendingRequests: pending,
        myRequests: myRequests,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createRequest({
    required int amount,
    required String reason,
  }) async {
    try {
      final request = models.CreateTokenRequestRequest(
        amount: amount,
        reason: reason,
      );
      final tokenRequest = await _apiService.createTokenRequest(
        familyId,
        request,
      );
      state = state.copyWith(myRequests: [...state.myRequests, tokenRequest]);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> reviewRequest({
    required String requestId,
    required String action,
    String? comments,
  }) async {
    try {
      final request = models.ReviewTokenRequestRequest(
        action: action,
        comments: comments,
      );
      await _apiService.reviewTokenRequest(familyId, requestId, request);
      state = state.copyWith(
        pendingRequests: state.pendingRequests
            .where((r) => r.requestId != requestId)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final tokenRequestsProvider =
    StateNotifierProvider.family<
      TokenRequestsNotifier,
      TokenRequestsState,
      String
    >((ref, familyId) {
      final apiService = ref.watch(familyApiServiceProvider);
      return TokenRequestsNotifier(apiService, familyId);
    });

// Notifications Provider
class NotificationsState {
  final List<models.FamilyNotification> notifications;
  final bool isLoading;
  final String? error;

  NotificationsState({
    required this.notifications,
    required this.isLoading,
    this.error,
  });

  NotificationsState copyWith({
    List<models.FamilyNotification>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final FamilyApiService _apiService;
  final String familyId;

  NotificationsNotifier(this._apiService, this.familyId)
    : super(NotificationsState(notifications: [], isLoading: false));

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notifications = await _apiService.getNotifications(familyId);
      state = state.copyWith(notifications: notifications, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> markAsRead(List<String> notificationIds) async {
    try {
      await _apiService.markNotificationsRead(familyId, notificationIds);
      state = state.copyWith(
        notifications: state.notifications.map((n) {
          if (notificationIds.contains(n.notificationId)) {
            return models.FamilyNotification(
              notificationId: n.notificationId,
              familyId: n.familyId,
              userId: n.userId,
              type: n.type,
              title: n.title,
              message: n.message,
              metadata: n.metadata,
              isRead: true,
              createdAt: n.createdAt,
            );
          }
          return n;
        }).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await _apiService.markAllNotificationsRead(familyId);
      state = state.copyWith(
        notifications: state.notifications
            .map(
              (n) => models.FamilyNotification(
                notificationId: n.notificationId,
                familyId: n.familyId,
                userId: n.userId,
                type: n.type,
                title: n.title,
                message: n.message,
                metadata: n.metadata,
                isRead: true,
                createdAt: n.createdAt,
              ),
            )
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final notificationsProvider =
    StateNotifierProvider.family<
      NotificationsNotifier,
      NotificationsState,
      String
    >((ref, familyId) {
      final apiService = ref.watch(familyApiServiceProvider);
      return NotificationsNotifier(apiService, familyId);
    });

// Transactions Provider
class TransactionsState {
  final List<models.Transaction> transactions;
  final bool isLoading;
  final String? error;

  TransactionsState({
    required this.transactions,
    required this.isLoading,
    this.error,
  });

  TransactionsState copyWith({
    List<models.Transaction>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final FamilyApiService _apiService;
  final String familyId;

  TransactionsNotifier(this._apiService, this.familyId)
    : super(TransactionsState(transactions: [], isLoading: false));

  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final transactions = await _apiService.getTransactions(familyId);
      state = state.copyWith(transactions: transactions, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final transactionsProvider =
    StateNotifierProvider.family<
      TransactionsNotifier,
      TransactionsState,
      String
    >((ref, familyId) {
      final apiService = ref.watch(familyApiServiceProvider);
      return TransactionsNotifier(apiService, familyId);
    });
