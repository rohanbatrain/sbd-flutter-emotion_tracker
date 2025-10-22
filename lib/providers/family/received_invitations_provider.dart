import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'family_api_service.dart';
import 'family_models.dart';

/// State for received invitations
class ReceivedInvitationsState {
  final List<ReceivedInvitation> invitations;
  final bool isLoading;
  final String? error;
  final DateTime? lastRefresh;

  ReceivedInvitationsState({
    this.invitations = const [],
    this.isLoading = false,
    this.error,
    this.lastRefresh,
  });

  ReceivedInvitationsState copyWith({
    List<ReceivedInvitation>? invitations,
    bool? isLoading,
    String? error,
    DateTime? lastRefresh,
  }) {
    return ReceivedInvitationsState(
      invitations: invitations ?? this.invitations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastRefresh: lastRefresh ?? this.lastRefresh,
    );
  }

  List<ReceivedInvitation> get pendingInvitations =>
      invitations.where((inv) => inv.isPending && !inv.isExpired).toList();

  List<ReceivedInvitation> get acceptedInvitations =>
      invitations.where((inv) => inv.isAccepted).toList();

  List<ReceivedInvitation> get declinedInvitations =>
      invitations.where((inv) => inv.isDeclined).toList();

  List<ReceivedInvitation> get expiredInvitations =>
      invitations.where((inv) => inv.isExpired).toList();
}

/// Provider for managing received invitations
class ReceivedInvitationsNotifier
    extends StateNotifier<ReceivedInvitationsState> {
  final FamilyApiService _apiService;

  ReceivedInvitationsNotifier(this._apiService)
    : super(ReceivedInvitationsState());

  /// Load all invitations
  Future<void> loadInvitations({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final invitations = await _apiService.getMyInvitations(status: status);
      state = state.copyWith(
        invitations: invitations,
        isLoading: false,
        lastRefresh: DateTime.now(),
      );
    } catch (e) {
      // Check if it's a 404 error indicating endpoint not implemented
      if (e.toString().contains('404') ||
          e.toString().contains('Family not found: my-invitations')) {
        state = state.copyWith(
          isLoading: false,
          error:
              'BACKEND_NOT_READY: The /family/my-invitations endpoint is not yet implemented on the backend. Please contact your backend team to add this endpoint.',
        );
      } else {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  /// Load only pending invitations
  Future<void> loadPendingInvitations() async {
    await loadInvitations(status: 'pending');
  }

  /// Respond to an invitation (accept or decline)
  Future<bool> respondToInvitation(String invitationId, String action) async {
    try {
      await _apiService.respondToInvitation(invitationId, action);
      // Reload invitations after responding
      await loadInvitations();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Accept an invitation
  Future<bool> acceptInvitation(String invitationId) async {
    return await respondToInvitation(invitationId, 'accept');
  }

  /// Decline an invitation
  Future<bool> declineInvitation(String invitationId) async {
    return await respondToInvitation(invitationId, 'decline');
  }

  /// Refresh invitations (pull-to-refresh)
  Future<void> refresh() async {
    await loadInvitations();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider instance
final receivedInvitationsProvider =
    StateNotifierProvider<
      ReceivedInvitationsNotifier,
      ReceivedInvitationsState
    >((ref) {
      final apiService = ref.watch(familyApiServiceProvider);
      return ReceivedInvitationsNotifier(apiService);
    });
