import 'dart:convert';
import 'dart:async';

import 'package:emotion_tracker/utils/http_util.dart';
import 'package:emotion_tracker/providers/user_agent_util.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/models/profile.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:emotion_tracker/providers/app_providers.dart' show loginWithApi;

class ProfilesState {
  final List<Profile> profiles;
  final Profile? current;

  ProfilesState({required this.profiles, this.current});

  ProfilesState copyWith({List<Profile>? profiles, Profile? current}) {
    return ProfilesState(
      profiles: profiles ?? this.profiles,
      current: current ?? this.current,
    );
  }
}

class ProfilesNotifier extends StateNotifier<ProfilesState> {
  final Ref _ref;
  bool _isRefreshing = false;

  ProfilesNotifier(this._ref)
    : super(ProfilesState(profiles: [], current: null)) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final storage = _ref.read(secureStorageProvider);
    // New secure key for profiles list (JSON array)
    try {
      final raw = await storage.read(key: 'profiles_list_secure');
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        final profiles = list
            .whereType<Map<String, dynamic>>()
            .map((m) => Profile.fromJson(m))
            .toList();
        String? currentId = await storage.read(key: 'current_profile_id');
        Profile? current;
        if (currentId != null) {
          current = profiles.firstWhere(
            (p) => p.id == currentId,
            orElse: () => profiles.isNotEmpty
                ? profiles.first
                : throw StateError('No profiles available'),
          );
        } else if (profiles.isNotEmpty) {
          current = profiles.first;
        }
        state = state.copyWith(profiles: profiles, current: current);
        return;
      }
    } catch (_) {}

    // If no profiles stored, attempt to migrate from legacy single-token storage
    try {
      final accessToken = await storage.read(key: 'access_token');
      final username = await storage.read(key: 'user_username');
      final email = await storage.read(key: 'user_email');
      // Build a single profile representing the current user (migration)
      final display = username ?? email ?? 'You';
      final p = Profile(
        id: 'me',
        displayName: display,
        email: email,
        accessToken: accessToken,
        expiresAtMs: null,
      );
      final listJson = jsonEncode([p.toJson()]);
      await storage.write(key: 'profiles_list_secure', value: listJson);
      await storage.write(key: 'current_profile_id', value: p.id);
      state = state.copyWith(profiles: [p], current: p);
      return;
    } catch (_) {}

    // Fallback: create a default ephemeral profile
    final username = await storage.read(key: 'user_username');
    final email = await storage.read(key: 'user_email');
    final display = username ?? email ?? 'You';
    final p = Profile(id: 'me', displayName: display, email: email);
    state = state.copyWith(profiles: [p], current: p);
  }

  Future<void> switchTo(String profileId) async {
    final found = state.profiles.firstWhere(
      (p) => p.id == profileId,
      orElse: () => state.current!,
    );
    state = state.copyWith(current: found);
    // Persist selection
    try {
      await _ref
          .read(secureStorageProvider)
          .write(key: 'current_profile_id', value: found.id);
    } catch (_) {}
  }

  Future<void> addProfile(Profile profile) async {
    final list = [...state.profiles, profile];
    state = state.copyWith(profiles: list);
    // Persist minimal info (not fully implemented)
    try {
      final storage = _ref.read(secureStorageProvider);
      final jsonList = jsonEncode(list.map((p) => p.toJson()).toList());
      await storage.write(key: 'profiles_list_secure', value: jsonList);
      await storage.write(key: 'current_profile_id', value: profile.id);
    } catch (_) {}
  }

  /// Add a profile by performing a login flow without replacing the current active session.
  /// This will temporarily call the standard login API (which stores auth data), capture
  /// the returned tokens to create a new Profile entry, then restore the original auth
  /// data so the current session remains active.
  Future<Profile> addProfileViaLogin(
    String usernameOrEmail,
    String password, {
    String? twoFaCode,
    String? twoFaMethod,
  }) async {
    final storage = _ref.read(secureStorageProvider);
    final authNotifier = _ref.read(authProvider.notifier);

    // Snapshot current auth storage and prefs
    String? oldAccess;
    String? oldUserEmail;
    String? oldUserName;
    String? oldTokenType;
    try {
      oldAccess = await storage.read(key: 'access_token');
      oldUserEmail = await storage.read(key: 'user_email');
      oldUserName = await storage.read(key: 'user_username');
      oldTokenType = await storage.read(key: 'token_type');
    } catch (_) {}

    Map<String, dynamic> result;
    try {
      // Perform login (this will call storeAuthData internally)
      result = await loginWithApi(
        _ref as WidgetRef,
        usernameOrEmail,
        password,
        twoFaCode: twoFaCode,
        twoFaMethod: twoFaMethod,
      );
    } catch (e) {
      rethrow;
    }

    // Build Profile from result
    final access = result['access_token'] as String?;
    final refresh = result['refresh_token'] as String?;
    final expiresAtStr = result['expires_at'] ?? result['expiresAt'];
    int? expiresAtMs;
    if (expiresAtStr != null) {
      try {
        final dt = DateTime.parse(expiresAtStr.toString());
        expiresAtMs = dt.millisecondsSinceEpoch;
      } catch (_) {
        expiresAtMs = int.tryParse(expiresAtStr.toString());
      }
    }
    final display = result['username'] ?? result['email'] ?? usernameOrEmail;
    final id = 'profile_${DateTime.now().millisecondsSinceEpoch}';
    final profile = Profile(
      id: id,
      displayName: display.toString(),
      email: result['email'] as String?,
      accessToken: access,
      refreshToken: refresh,
      expiresAtMs: expiresAtMs,
      lastRefreshMs: DateTime.now().millisecondsSinceEpoch,
    );

    // Persist profile into profiles_list_secure without changing current active session
    try {
      final raw = await storage.read(key: 'profiles_list_secure');
      List<dynamic> list = [];
      if (raw != null && raw.isNotEmpty) {
        list = jsonDecode(raw) as List<dynamic>;
      }
      list.add(profile.toJson());
      await storage.write(key: 'profiles_list_secure', value: jsonEncode(list));
    } catch (_) {}

    // Restore previous auth data to keep current session unchanged
    try {
      if (oldAccess != null) {
        await storage.write(key: 'access_token', value: oldAccess);
      } else {
        await storage.delete(key: 'access_token');
      }
      if (oldUserEmail != null) {
        await storage.write(key: 'user_email', value: oldUserEmail);
      }
      if (oldUserName != null) {
        await storage.write(key: 'user_username', value: oldUserName);
      }
      if (oldTokenType != null) {
        await storage.write(key: 'token_type', value: oldTokenType);
      }
      // Refresh AuthNotifier state from storage
      await authNotifier.login(oldUserEmail ?? '');
    } catch (_) {}

    // Update in-memory profiles state and leave current unchanged
    final updatedList = [...state.profiles, profile];
    state = state.copyWith(profiles: updatedList);
    return profile;
  }

  Future<void> logout() async {
    // Delegate to authProvider via ref
    try {
      await _ref.read(authProvider.notifier).logout();
    } catch (_) {}
  }

  /// Attempt to refresh the active profile's tokens using its refreshToken.
  /// Returns true if refresh succeeded and profile was updated.
  Future<bool> refreshActiveProfile({int minAgeSeconds = 300}) async {
    if (_isRefreshing) return false;
    try {
      final current = state.current;
      if (current == null || current.refreshToken == null) return false;

      // Avoid frequent refreshes: check lastRefreshMs
      final now = DateTime.now().millisecondsSinceEpoch;
      if (current.lastRefreshMs != null) {
        final age = (now - current.lastRefreshMs!) ~/ 1000;
        if (age < minAgeSeconds) return false;
      }

      _isRefreshing = true;

      final baseUrl = _ref.read(apiBaseUrlProvider);
      final url = Uri.parse('$baseUrl/auth/refresh');
      final userAgent = await getUserAgent();
      final headers = {
        'Content-Type': 'application/json',
        'User-Agent': userAgent,
        'X-User-Agent': userAgent,
      };
      final body = jsonEncode({'refresh_token': current.refreshToken});
      final response = await HttpUtil.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccess = data['access_token'] as String?;
        final newRefresh =
            data['refresh_token'] as String? ?? current.refreshToken;
        final expiresAtStr = data['expires_at'] ?? data['expiresAt'];
        int? expiresAtMs;
        if (expiresAtStr != null) {
          try {
            final dt = DateTime.parse(expiresAtStr.toString());
            expiresAtMs = dt.millisecondsSinceEpoch;
          } catch (_) {
            expiresAtMs = int.tryParse(expiresAtStr.toString());
          }
        }

        final updated = current.copyWith(
          accessToken: newAccess ?? current.accessToken,
          refreshToken: newRefresh,
          expiresAtMs: expiresAtMs ?? current.expiresAtMs,
          lastRefreshMs: now,
        );

        // Persist updated profiles list
        try {
          final storage = _ref.read(secureStorageProvider);
          final raw = await storage.read(key: 'profiles_list_secure');
          if (raw != null && raw.isNotEmpty) {
            final list = jsonDecode(raw) as List<dynamic>;
            final profiles = list
                .whereType<Map<String, dynamic>>()
                .map((m) => Profile.fromJson(m))
                .toList();
            final newList = profiles
                .map((p) => p.id == updated.id ? updated.toJson() : p.toJson())
                .toList();
            await storage.write(
              key: 'profiles_list_secure',
              value: jsonEncode(newList),
            );
          }
        } catch (_) {}

        // Update in-memory state
        final updatedList = state.profiles
            .map((p) => p.id == updated.id ? updated : p)
            .toList();
        state = state.copyWith(profiles: updatedList, current: updated);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }
}

final profilesProvider = StateNotifierProvider<ProfilesNotifier, ProfilesState>(
  (ref) {
    return ProfilesNotifier(ref);
  },
);
