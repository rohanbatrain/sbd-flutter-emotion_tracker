import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/providers/shared_prefs_provider.dart';
import 'package:emotion_tracker/providers/user_agent_util.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:emotion_tracker/avatars/custom_avatar.dart';

/// Provider for avatar unlock logic (local + server sync, robust enforcement)
final avatarUnlockProvider = Provider<AvatarUnlockService>((ref) {
  return AvatarUnlockService(ref);
});

class AvatarUnlockService {
  final Ref ref;
  AvatarUnlockService(this.ref);

  // In-memory cache: avatarId -> { unlocked: bool, unlockTime: DateTime? }
  final Map<String, _AvatarUnlockCache> _unlockCache = {};

  /// Unlocks the avatar for the user by updating secure storage with a 1-hour expiry.
  Future<void> unlockAvatar(String avatarId) async {
    final storage = ref.read(secureStorageProvider);
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

  /// Returns unlock status and unlock timestamp for UI logic.
  /// Always checks server if cache is expired (older than 1 hour), else uses cache.
  Future<AvatarUnlockInfo> getAvatarUnlockInfo(String avatarId) async {
    final now = DateTime.now().toUtc();
    final cache = _unlockCache[avatarId];
    if (cache != null && now.difference(cache.lastChecked).inMinutes < 60) {
      // Use cache if less than 1 hour old
      return AvatarUnlockInfo(
        isUnlocked: cache.isUnlocked,
        unlockTime: cache.unlockTime,
      );
    }
    // Fetch from storage/server
    final unlocks = await _getMergedUnlockedAvatarsWithTimes();
    final info = unlocks[avatarId] ?? AvatarUnlockInfo(isUnlocked: false, unlockTime: null);
    _unlockCache[avatarId] = _AvatarUnlockCache(
      isUnlocked: info.isUnlocked,
      unlockTime: info.unlockTime,
      lastChecked: now,
    );
    return info;
  }

  /// Helper: like getMergedUnlockedAvatars, but returns unlock time for each avatar.
  Future<Map<String, AvatarUnlockInfo>> _getMergedUnlockedAvatarsWithTimes() async {
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

    // Merge: only avatars present in serverUnlocks are considered unlocked (except always-free/default avatar)
    final result = <String, AvatarUnlockInfo>{};
    for (final avatar in allAvatars) {
      if (avatar.id == 'person') {
        result[avatar.id] = AvatarUnlockInfo(isUnlocked: true, unlockTime: null);
        continue;
      }
      final serverValid = serverUnlocks[avatar.id];
      if (serverValid != null && serverValid.isAfter(now)) {
        // Use server unlock time (subtract 1 hour to get unlock time)
        result[avatar.id] = AvatarUnlockInfo(
          isUnlocked: true,
          unlockTime: serverValid.subtract(const Duration(hours: 1)),
        );
        continue;
      }
      final localValid = validLocal[avatar.id];
      if (localValid != null && now.isBefore(localValid.add(const Duration(hours: 1)))) {
        result[avatar.id] = AvatarUnlockInfo(
          isUnlocked: true,
          unlockTime: localValid,
        );
        continue;
      }
      result[avatar.id] = AvatarUnlockInfo(isUnlocked: false, unlockTime: null);
    }
    return result;
  }

  /// Helper to fetch and merge server and local unlocks. Server always wins if locked.
  Future<Set<String>> getMergedUnlockedAvatars() async {
    final unlocks = await _getMergedUnlockedAvatarsWithTimes();
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
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Avatar Rented!'),
                      content: const Text('You have rented the avatar. You can now use it for 1 hour.'),
                      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
                    ),
                  );
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
}

class AvatarUnlockInfo {
  final bool isUnlocked;
  final DateTime? unlockTime;
  AvatarUnlockInfo({required this.isUnlocked, required this.unlockTime});
}

class _AvatarUnlockCache {
  final bool isUnlocked;
  final DateTime? unlockTime;
  final DateTime lastChecked;
  _AvatarUnlockCache({required this.isUnlocked, required this.unlockTime, required this.lastChecked});
}
