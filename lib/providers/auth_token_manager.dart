import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/models/profile.dart';
import 'package:emotion_tracker/providers/profiles_provider.dart';

/// Manages token refresh operations with per-profile mutex to prevent concurrent refreshes
class AuthTokenManager {
  final Ref _ref;

  // Mutex map to prevent concurrent refreshes for the same profile
  final Map<String, Completer<bool>> _refreshMutexes = {};

  AuthTokenManager(this._ref);

  /// Refreshes tokens for a specific profile.
  /// Returns true if refresh succeeded and profile was updated.
  /// Uses mutex to prevent concurrent refreshes for the same profile.
  Future<bool> refreshProfile(String profileId) async {
    // Check if refresh is already in progress for this profile
    if (_refreshMutexes.containsKey(profileId)) {
      // Wait for existing refresh to complete
      return await _refreshMutexes[profileId]!.future;
    }

    // Start new refresh
    final completer = Completer<bool>();
    _refreshMutexes[profileId] = completer;

    try {
      final profilesNotifier = _ref.read(profilesProvider.notifier);
      final success = await profilesNotifier.refreshActiveProfile();
      completer.complete(success);
      return success;
    } catch (e) {
      completer.complete(false);
      return false;
    } finally {
      _refreshMutexes.remove(profileId);
    }
  }

  /// Checks if a profile's tokens are expired or about to expire
  bool isProfileExpired(
    Profile profile, {
    Duration buffer = const Duration(minutes: 5),
  }) {
    if (profile.expiresAtMs == null) return false;
    final expiryTime = DateTime.fromMillisecondsSinceEpoch(
      profile.expiresAtMs!,
    );
    final now = DateTime.now();
    return now.isAfter(expiryTime.subtract(buffer));
  }

  /// Gets the current active profile, refreshing if necessary
  Future<Profile?> getActiveProfile({bool autoRefresh = true}) async {
    final profilesState = _ref.read(profilesProvider);
    final current = profilesState.current;
    if (current == null) return null;

    if (autoRefresh && isProfileExpired(current)) {
      await refreshProfile(current.id);
      // Re-read after potential refresh
      final updatedState = _ref.read(profilesProvider);
      return updatedState.current;
    }

    return current;
  }
}

final authTokenManagerProvider = Provider<AuthTokenManager>((ref) {
  return AuthTokenManager(ref);
});
