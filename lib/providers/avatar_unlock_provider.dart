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

  /// Helper to fetch and merge server and local unlocks. Server always wins if locked.
  Future<Set<String>> getMergedUnlockedAvatars() async {
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
        validLocal[key] = DateTime.fromMillisecondsSinceEpoch(value).toUtc().add(Duration(hours: 1));
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
    final unlocked = <String>{};
    for (final avatar in allAvatars) {
      if (avatar.id == 'person') {
        unlocked.add(avatar.id);
        continue;
      }
      final serverValid = serverUnlocks[avatar.id];
      if (serverValid != null && serverValid.isAfter(now)) {
        unlocked.add(avatar.id);
        continue;
      }
    }
    return unlocked;
  }

  /// Checks if an avatar is currently unlocked (for global enforcement)
  Future<bool> isAvatarUnlocked(String avatarId) async {
    final unlocked = await getMergedUnlockedAvatars();
    return unlocked.contains(avatarId);
  }

  /// Loads and shows a rewarded ad for avatar unlock, passing username as SSV custom data.
  Future<void> showAvatarUnlockAd(BuildContext context, String avatarId, {VoidCallback? onAvatarUnlocked}) async {
    final avatar = allAvatars.firstWhere((a) => a.id == avatarId, orElse: () => allAvatars.first);
    final adUnitId = avatar.rewardedAdId;
    if (adUnitId == null || adUnitId.isEmpty) return;
    final storage = ref.read(secureStorageProvider);
    final username = await storage.read(key: 'user_username');
    if (username == null || username.isEmpty) return;

    final theme = Theme.of(context);
    // Confirm with user, with notice about server-side verification delay
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rent Avatar', style: TextStyle(color: theme.primaryColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Watch a short ad to rent this avatar for 1 hour of usage.'),
            const SizedBox(height: 12),
            Text(
              'Note: It may take a few seconds after watching the ad for the avatar to unlock, due to server-side verification.',
              style: TextStyle(fontSize: 12, color: theme.primaryColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
            style: TextButton.styleFrom(foregroundColor: theme.primaryColor),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Watch Ad'),
            style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor),
          ),
        ],
      ),
    );
    if (proceed != true) return;

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
            // Dismiss the loading dialog right before showing the ad
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
                if (context.mounted) {
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Avatar Rented!'),
                      content: const Text('You have rented the avatar. You can now use it for 1 hour.'),
                      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
                    ),
                  );
                  // Only notify UI after all dialogs are closed
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
