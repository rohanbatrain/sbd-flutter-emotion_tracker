import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/team/team_api_service.dart';
import 'package:emotion_tracker/providers/team/team_exceptions.dart';
import 'package:emotion_tracker/models/team/team_models.dart';
import 'package:emotion_tracker/providers/app_providers.dart';

// API Service Provider
final teamApiServiceProvider = Provider<TeamApiService>((ref) {
  return TeamApiService(ref);
});

// Auth token provider (connected to real auth system)
final authTokenProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.accessToken;
});

// Team Workspaces Provider
final teamWorkspacesProvider =
    NotifierProvider<TeamWorkspacesNotifier, AsyncValue<List<TeamWorkspace>>>(
      TeamWorkspacesNotifier.new,
    );

class TeamWorkspacesNotifier extends Notifier<AsyncValue<List<TeamWorkspace>>> {
  late final TeamApiService _api;

  @override
  AsyncValue<List<TeamWorkspace>> build() {
    _api = ref.watch(teamApiServiceProvider);
    return AsyncValue.data([]); // Start with empty, screen will load
  }

  Future<void> loadWorkspaces() async {
    state = const AsyncValue.loading();
    try {
      final workspaces = await _api.getWorkspaces();
      state = AsyncValue.data(workspaces);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createWorkspace(String name, {String? description}) async {
    try {
      final newWorkspace = await _api.createWorkspace(
        name,
        description: description,
      );
      state = state.maybeWhen(
        data: (workspaces) => AsyncValue.data([...workspaces, newWorkspace]),
        orElse: () => AsyncValue.data([newWorkspace]),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateWorkspace(
    String workspaceId, {
    String? name,
    String? description,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final updatedWorkspace = await _api.updateWorkspace(
        workspaceId,
        name: name,
        description: description,
        settings: settings,
      );
      state = state.maybeWhen(
        data: (workspaces) => AsyncValue.data(
          workspaces
              .map((w) => w.workspaceId == workspaceId ? updatedWorkspace : w)
              .toList(),
        ),
        orElse: () => state,
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteWorkspace(String workspaceId) async {
    try {
      await _api.deleteWorkspace(workspaceId);
      state = state.maybeWhen(
        data: (workspaces) => AsyncValue.data(
          workspaces.where((w) => w.workspaceId != workspaceId).toList(),
        ),
        orElse: () => state,
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addMember(
    String workspaceId,
    String userId,
    WorkspaceRole role,
  ) async {
    try {
      final updatedWorkspace = await _api.addMember(workspaceId, userId, role);
      state = state.maybeWhen(
        data: (workspaces) => AsyncValue.data(
          workspaces
              .map((w) => w.workspaceId == workspaceId ? updatedWorkspace : w)
              .toList(),
        ),
        orElse: () => state,
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateMemberRole(
    String workspaceId,
    String memberId,
    WorkspaceRole newRole,
  ) async {
    try {
      final updatedWorkspace = await _api.updateMemberRole(
        workspaceId,
        memberId,
        newRole,
      );
      state = state.maybeWhen(
        data: (workspaces) => AsyncValue.data(
          workspaces
              .map((w) => w.workspaceId == workspaceId ? updatedWorkspace : w)
              .toList(),
        ),
        orElse: () => state,
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> removeMember(String workspaceId, String memberId) async {
    try {
      await _api.removeMember(workspaceId, memberId);
      // Reload workspace to get updated member list
      final updatedWorkspace = await _api.getWorkspace(workspaceId);
      state = state.maybeWhen(
        data: (workspaces) => AsyncValue.data(
          workspaces
              .map((w) => w.workspaceId == workspaceId ? updatedWorkspace : w)
              .toList(),
        ),
        orElse: () => state,
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Individual Workspace Provider
final teamWorkspaceProvider = FutureProvider.family<TeamWorkspace?, String>((
  ref,
  workspaceId,
) async {
  final api = ref.watch(teamApiServiceProvider);
  return api.getWorkspace(workspaceId);
});

// Team Wallet Providers
final teamWalletProvider =
    NotifierProvider.family<
      TeamWalletNotifier,
      AsyncValue<TeamWallet?>,
      String
    >(TeamWalletNotifier.new);

class TeamWalletNotifier
    extends FamilyNotifier<AsyncValue<TeamWallet?>, String> {
  late final TeamApiService _api;

  @override
  AsyncValue<TeamWallet?> build(String arg) {
    _api = ref.watch(teamApiServiceProvider);
    return const AsyncValue.data(null); // Start with null, screen will load
  }

  Future<void> loadWallet() async {
    state = const AsyncValue.loading();
    try {
      final wallet = await _api.getTeamWallet(arg);
      state = AsyncValue.data(wallet);
    } catch (error, stackTrace) {
      if (error is WalletNotInitializedException) {
        state = const AsyncValue.data(null); // Wallet not initialized
      } else {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> initializeWallet({
    required double initialBalance,
    required String currency,
    required String walletName,
  }) async {
    try {
      final wallet = await _api.initializeTeamWallet(
        arg,
        initialBalance: initialBalance,
        currency: currency,
        walletName: walletName,
      );
      state = AsyncValue.data(wallet);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createTokenRequest(double amount, String reason) async {
    try {
      await _api.requestTokens(arg, amount: amount, purpose: reason);
      // Optionally refresh wallet or token requests
      await loadWallet();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> freezeWallet(String reason) async {
    try {
      final updatedWallet = await _api.freezeWallet(arg, reason);
      state = AsyncValue.data(updatedWallet);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> unfreezeWallet() async {
    try {
      final updatedWallet = await _api.unfreezeWallet(arg);
      state = AsyncValue.data(updatedWallet);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updatePermissions(
    Map<String, Map<String, dynamic>> permissions,
  ) async {
    try {
      final updatedWallet = await _api.updateWalletPermissions(
        arg,
        permissions,
      );
      state = AsyncValue.data(updatedWallet);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Token Requests Provider
final tokenRequestsProvider =
    NotifierProvider.family<
      TokenRequestsNotifier,
      AsyncValue<List<TokenRequest>>,
      String
    >(TokenRequestsNotifier.new);

class TokenRequestsNotifier
    extends FamilyNotifier<AsyncValue<List<TokenRequest>>, String> {
  late final TeamApiService _api;

  @override
  AsyncValue<List<TokenRequest>> build(String arg) {
    _api = ref.watch(teamApiServiceProvider);
    return AsyncValue.data([]); // Start with empty, screen will load
  }

  Future<void> loadPendingRequests() async {
    state = const AsyncValue.loading();
    try {
      final requests = await _api.getTokenRequests(arg);
      state = AsyncValue.data(requests);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> reviewRequest(
    String requestId,
    String action, {
    String? comments,
  }) async {
    try {
      if (action == 'approve') {
        await _api.approveTokenRequest(arg, requestId);
      } else if (action == 'deny') {
        await _api.rejectTokenRequest(
          arg,
          requestId,
          comments ?? 'No reason provided',
        );
      }
      await loadPendingRequests(); // Refresh the list
      // Invalidate wallet to ensure balance is fresh
      ref.invalidate(teamWalletProvider(arg));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Aggregated Pending Requests Provider (across all workspaces)
final allPendingRequestsProvider = NotifierProvider<
  AllPendingRequestsNotifier,
  AsyncValue<List<TokenRequest>>
>(AllPendingRequestsNotifier.new);

class AllPendingRequestsNotifier extends Notifier<AsyncValue<List<TokenRequest>>> {
  late final TeamApiService _api;

  @override
  AsyncValue<List<TokenRequest>> build() {
    _api = ref.watch(teamApiServiceProvider);
    return AsyncValue.data([]); // Start with empty, screen will load
  }

  Future<void> loadAllPendingRequests() async {
    state = const AsyncValue.loading();
    try {
      // Get all workspaces first
      final workspacesAsync = ref.read(teamWorkspacesProvider);
      final workspaces = await workspacesAsync.maybeWhen(
        data: (data) => data,
        orElse: () => <TeamWorkspace>[],
      );

      // Load pending requests for all workspaces concurrently
      final futures = workspaces.map((workspace) => _api.getTokenRequests(workspace.workspaceId));
      final results = await Future.wait(futures);

      // Flatten all requests into a single list
      final allRequests = results.expand((requests) => requests).toList();
      state = AsyncValue.data(allRequests);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Audit Trail Provider
final auditTrailProvider =
    NotifierProvider.family<
      AuditTrailNotifier,
      AsyncValue<List<AuditEntry>>,
      String
    >(AuditTrailNotifier.new);

class AuditTrailNotifier
    extends FamilyNotifier<AsyncValue<List<AuditEntry>>, String> {
  late final TeamApiService _api;

  @override
  AsyncValue<List<AuditEntry>> build(String arg) {
    _api = ref.watch(teamApiServiceProvider);
    return AsyncValue.data([]); // Start with empty, screen will load
  }

  Future<void> loadAuditTrail({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    state = const AsyncValue.loading();
    try {
      final auditEntries = await _api.getAuditTrail(
        arg,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
      state = AsyncValue.data(auditEntries);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// Compliance Report Provider
final complianceReportProvider =
    FutureProvider.family<ComplianceReport?, String>((ref, workspaceId) async {
      final api = ref.watch(teamApiServiceProvider);
      return api.generateComplianceReport(workspaceId, 'json');
    });

// Error Provider for global error handling
final teamErrorProvider = StateProvider<TeamApiException?>((ref) => null);

// Rate Limit Provider
final rateLimitProvider = StateProvider<RateLimitInfo?>((ref) => null);
