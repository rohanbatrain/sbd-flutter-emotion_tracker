import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/providers/shared_prefs_provider.dart';
import 'package:emotion_tracker/providers/user_agent_util.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:emotion_tracker/providers/custom_avatar.dart';

/// Provider for avatar unlock logic (local + server sync, robust enforcement)
final avatarUnlockProvider = Provider<AvatarUnlockService>((ref) {
  return AvatarUnlockService(ref);
});

class AvatarUnlockService {
  final Ref ref;
  AvatarUnlockService(this.ref);

  // In-memory cache: avatarId -> { unlocked: bool, unlockTime: DateTime?, permanent: bool }
  final Map<String, _AvatarUnlockCache> _unlockCache = {};

  /// Clears the in-memory unlock cache (for pull-to-refresh or logout)
  void clearCache() {
    _unlockCache.clear();
  }

  /// Unlocks the avatar for the user by updating secure storage with a 1-hour expiry or permanent ownership.
  Future<void> unlockAvatar(String avatarId, {bool permanent = false}) async {
    final storage = ref.read(secureStorageProvider);
    if (permanent) {
      final ownedJson = (await storage.read(key: 'owned_avatars')) ?? '[]';
      List<String> ownedList;
      try {
        ownedList = List<String>.from(jsonDecode(ownedJson));
      } catch (_) {
        ownedList = [];
      }
      if (!ownedList.contains(avatarId)) {
        ownedList.add(avatarId);
        await storage.write(key: 'owned_avatars', value: jsonEncode(ownedList));
      }
    } else {
      final unlockedJson = (await storage.read(key: 'unlocked_avatars')) ?? '{}';
      Map<String, dynamic> unlockedMap;
      try {
        unlockedMap = Map<String, dynamic>.from(jsonDecode(unlockedJson));
      } catch (_) {
        unlockedMap = {};
      }
      unlockedMap[avatarId] = DateTime.now().millisecondsSinceEpoch;
      await storage.write(key: 'unlocked_avatars', value: jsonEncode(unlockedMap));
    }
  }

  /// Returns unlock status, unlock timestamp, and permanent ownership for UI logic.
  /// Always checks server if cache is expired (older than 1 hour), else uses cache.
  Future<AvatarUnlockInfo> getAvatarUnlockInfo(String avatarId) async {
    final now = DateTime.now().toUtc();
    final cache = _unlockCache[avatarId];
    bool _safePermanent(dynamic value) {
      if (value is bool) return value;
      return false;
    }
    if (cache != null && now.difference(cache.lastChecked).inMinutes < 60) {
      // Use cache if less than 1 hour old
      return AvatarUnlockInfo(
        isUnlocked: cache.isUnlocked,
        unlockTime: cache.unlockTime,
        permanent: _safePermanent(cache.permanent),
      );
    }
    // Fetch from storage/server
    final unlocks = await getMergedUnlockedAvatarsWithTimes();
    final info = unlocks[avatarId] ?? AvatarUnlockInfo(isUnlocked: false, unlockTime: null, permanent: false);
    _unlockCache[avatarId] = _AvatarUnlockCache(
      isUnlocked: info.isUnlocked,
      unlockTime: info.unlockTime,
      permanent: _safePermanent(info.permanent),
      lastChecked: now,
    );
    return AvatarUnlockInfo(
      isUnlocked: info.isUnlocked,
      unlockTime: info.unlockTime,
      permanent: _safePermanent(info.permanent),
    );
  }

  /// Helper: like getMergedUnlockedAvatars, but returns unlock time and permanent ownership for each avatar.
  Future<Map<String, AvatarUnlockInfo>> getMergedUnlockedAvatarsWithTimes() async {
    final storage = ref.read(secureStorageProvider);
    final accessToken = await storage.read(key: 'access_token');
    final protocol = ref.read(serverProtocolProvider);
    final domain = ref.read(serverDomainProvider);
    final apiUrl = Uri.parse('$protocol://$domain/avatars/rented');
    final now = DateTime.now().toUtc();
    Map<String, DateTime> serverUnlocks = {};

    // Fetch server unlocks
    if (accessToken != null && accessToken.isNotEmpty) {
      try {
        final userAgent = await getUserAgent();
        final response = await http.get(
          apiUrl,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'User-Agent': userAgent,
          },
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> rented = data['avatars_rented'] ?? [];
          final Map<String, List<DateTime>> grouped = {};
          for (final entry in rented) {
            final avatarId = entry['avatar_id'] as String?;
            final validTillStr = entry['valid_till'] as String?;
            if (avatarId != null && validTillStr != null) {
              final validTill = DateTime.parse(validTillStr).toUtc();
              if (validTill.isAfter(now)) {
                grouped.putIfAbsent(avatarId, () => []).add(validTill);
              }
            }
          }
          for (final avatarId in grouped.keys) {
            final latest = grouped[avatarId]!.reduce((a, b) => a.isAfter(b) ? a : b);
            serverUnlocks[avatarId] = latest;
          }
        }
      } catch (e) {
        // On error, treat as all locked except local unlocks
      }
    }

    // Get valid local unlocks
    final unlockedJson = (await storage.read(key: 'unlocked_avatars')) ?? '{}';
    Map<String, dynamic> unlockedMap;
    try {
      unlockedMap = Map<String, dynamic>.from(jsonDecode(unlockedJson));
    } catch (_) {
      unlockedMap = {};
    }
    final hourMs = 60 * 60 * 1000;
    final validLocal = <String, DateTime>{};
    final expired = <String>[];
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    unlockedMap.forEach((key, value) {
      if (value is int && nowMs - value < hourMs) {
        validLocal[key] = DateTime.fromMillisecondsSinceEpoch(value).toUtc();
      } else if (value is int && nowMs - value >= hourMs) {
        expired.add(key);
      }
    });
    for (final key in expired) {
      unlockedMap.remove(key);
    }
    if (expired.isNotEmpty) {
      await storage.write(key: 'unlocked_avatars', value: jsonEncode(unlockedMap));
    }

    // Get owned avatars
    final ownedJson = (await storage.read(key: 'owned_avatars')) ?? '[]';
    List<String> ownedList;
    try {
      ownedList = List<String>.from(jsonDecode(ownedJson));
    } catch (_) {
      ownedList = [];
    }

    // Merge: owned avatars always permanent, then server unlocks, then local unlocks
    final result = <String, AvatarUnlockInfo>{};
    for (final avatar in allAvatars) {
      if (avatar.id == 'person') {
        result[avatar.id] = AvatarUnlockInfo(isUnlocked: true, unlockTime: null, permanent: true);
        continue;
      }
      if (ownedList.contains(avatar.id)) {
        result[avatar.id] = AvatarUnlockInfo(isUnlocked: true, unlockTime: null, permanent: true);
        continue;
      }
      final serverValid = serverUnlocks[avatar.id];
      if (serverValid != null && serverValid.isAfter(now)) {
        result[avatar.id] = AvatarUnlockInfo(
          isUnlocked: true,
          unlockTime: serverValid.subtract(const Duration(hours: 1)),
          permanent: false,
        );
        continue;
      }
      final localValid = validLocal[avatar.id];
      if (localValid != null && now.isBefore(localValid.add(const Duration(hours: 1)))) {
        result[avatar.id] = AvatarUnlockInfo(
          isUnlocked: true,
          unlockTime: localValid,
          permanent: false,
        );
        continue;
      }
      result[avatar.id] = AvatarUnlockInfo(isUnlocked: false, unlockTime: null, permanent: false);
    }
    return result;
  }

  /// Helper to fetch and merge server and local unlocks. Server always wins if locked.
  Future<Set<String>> getMergedUnlockedAvatars() async {
    final unlocks = await getMergedUnlockedAvatarsWithTimes();
    return unlocks.entries.where((entry) => entry.value.isUnlocked).map((entry) => entry.key).toSet();
  }

  /// Checks if an avatar is currently unlocked (for global enforcement)
  Future<bool> isAvatarUnlocked(String avatarId) async {
    final info = await getAvatarUnlockInfo(avatarId);
    return info.isUnlocked;
  }

  /// Loads and shows a rewarded ad for avatar unlock, passing username as SSV custom data.
  /// No confirmation popup, ad loads immediately.
  Future<void> showAvatarUnlockAd(BuildContext context, String avatarId, {VoidCallback? onAvatarUnlocked}) async {
    // Defensive: Prevent ad/rent for owned avatars
    final info = await getAvatarUnlockInfo(avatarId);
    if (info.permanent == true) return;
    final avatar = allAvatars.firstWhere((a) => a.id == avatarId, orElse: () => allAvatars.first);
    final adUnitId = avatar.rewardedAdId;
    if (adUnitId == null || adUnitId.isEmpty) return;
    final storage = ref.read(secureStorageProvider);
    final username = await storage.read(key: 'user_username');
    if (username == null || username.isEmpty) return;

    // Show loading dialog and keep it until ad is actually shown
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    bool rewardGiven = false;
    try {
      RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) async {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();

            ad.setServerSideOptions(ServerSideVerificationOptions(userId: username));
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                if (!rewardGiven && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ad closed before reward.')));
                }
              },
              onAdFailedToShowFullScreenContent: (ad, err) {
                ad.dispose();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to show ad.')));
                }
              },
            );
            ad.show(
              onUserEarnedReward: (ad, reward) async {
                rewardGiven = true;
                await unlockAvatar(avatarId);
                // Invalidate cache for this avatar
                _unlockCache.remove(avatarId);
                if (context.mounted) {
                  if (onAvatarUnlocked != null) onAvatarUnlocked();
                }
              },
            );
          },
          onAdFailedToLoad: (err) {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load ad.')));
            }
          },
        ),
      );
    } catch (e) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ad error: $e')));
      }
    }
  }

  /// Buys the avatar from the backend shop API and updates local unlock state.
  Future<void> buyAvatar(String avatarId, BuildContext context) async {
    final storage = ref.read(secureStorageProvider);
    final accessToken = await storage.read(key: 'access_token');
    final protocol = ref.read(serverProtocolProvider);
    final domain = ref.read(serverDomainProvider);
    final apiUrl = Uri.parse('$protocol://$domain/shop/avatars/buy');
    final userAgent = await getUserAgent();

    if (accessToken == null || accessToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated. Please log in.')),
      );
      return;
    }

    try {
      final response = await http.post(
        apiUrl,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'User-Agent': userAgent,
        },
        body: jsonEncode({'avatar_id': avatarId}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        final isPermanent = data['avatar']?['permanent'] == true;
        await unlockAvatar(avatarId, permanent: isPermanent);
        _unlockCache.remove(avatarId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isPermanent ? 'Avatar purchased and owned forever!' : 'Avatar rented!')),
        );
        return;
      } else if (response.statusCode == 400 && data['detail'] == 'Avatar already owned') {
        await unlockAvatar(avatarId, permanent: true);
        _unlockCache.remove(avatarId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar already owned.')),
        );
        return;
      } else if (response.statusCode == 400 && data['detail'] == 'Not enough SBD tokens') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not enough SBD tokens.')),
        );
        return;
      } else if (response.statusCode == 400 && data['detail'] == 'Insufficient SBD tokens or race condition') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insufficient SBD tokens or race condition.')),
        );
        return;
      } else if (response.statusCode == 400 && data['detail'] == 'Invalid or missing avatar_id') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid or missing avatar ID.')),
        );
        return;
      } else if (response.statusCode == 404 && data['detail'] == 'User not found') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found.')),
        );
        return;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not authenticated.')),
        );
        return;
      } else if (response.statusCode == 500) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Internal server error: ${data['error'] ?? ''}')),
        );
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unknown error: ${data['detail'] ?? response.body}')),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
      return;
    }
  }
}

class AvatarUnlockInfo {
  final bool isUnlocked;
  final DateTime? unlockTime;
  final bool permanent;
  AvatarUnlockInfo({required this.isUnlocked, required this.unlockTime, this.permanent = false});
}

class _AvatarUnlockCache {
  final bool isUnlocked;
  final DateTime? unlockTime;
  final bool permanent;
  final DateTime lastChecked;
  _AvatarUnlockCache({required this.isUnlocked, required this.unlockTime, required this.permanent, required this.lastChecked});
}
