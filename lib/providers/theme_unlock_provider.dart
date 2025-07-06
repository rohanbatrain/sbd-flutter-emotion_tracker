import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/providers/shared_prefs_provider.dart';
import 'package:emotion_tracker/providers/user_agent_util.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Provider for theme unlock logic (local + server sync, robust enforcement)
final themeUnlockProvider = Provider<ThemeUnlockService>((ref) {
  return ThemeUnlockService(ref);
});

class ThemeUnlockService {
  final Ref ref;
  ThemeUnlockService(this.ref);

  /// Unlocks the theme for the user by updating secure storage with a 1-hour expiry.
  Future<void> unlockTheme(String themeKey) async {
    final storage = ref.read(secureStorageProvider);
    final unlockedJson = (await storage.read(key: 'unlocked_themes')) ?? '{}';
    Map<String, dynamic> unlockedMap;
    try {
      unlockedMap = Map<String, dynamic>.from(jsonDecode(unlockedJson));
    } catch (_) {
      unlockedMap = {};
    }
    unlockedMap[themeKey] = DateTime.now().millisecondsSinceEpoch;
    await storage.write(key: 'unlocked_themes', value: jsonEncode(unlockedMap));
  }

  /// Helper to fetch and merge server and local unlocks. Server always wins if locked.
  Future<Set<String>> getMergedUnlockedThemes() async {
    final storage = ref.read(secureStorageProvider);
    final accessToken = await storage.read(key: 'access_token');
    final protocol = ref.read(serverProtocolProvider);
    final domain = ref.read(serverDomainProvider);
    final apiUrl = Uri.parse('$protocol://$domain/themes/rented');
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
          final List<dynamic> rented = data['themes_rented'] ?? [];
          final Map<String, List<DateTime>> grouped = {};
          for (final entry in rented) {
            final themeId = entry['theme_id'] as String?;
            final validTillStr = entry['valid_till'] as String?;
            if (themeId != null && validTillStr != null) {
              final validTill = DateTime.parse(validTillStr).toUtc();
              if (validTill.isAfter(now)) {
                grouped.putIfAbsent(themeId, () => []).add(validTill);
              }
            }
          }
          for (final themeId in grouped.keys) {
            final latest = grouped[themeId]!.reduce((a, b) => a.isAfter(b) ? a : b);
            serverUnlocks[themeId] = latest;
          }
        }
      } catch (e) {
        // On error, treat as all locked except local unlocks
      }
    }

    // Get valid local unlocks
    final unlockedJson = (await storage.read(key: 'unlocked_themes')) ?? '{}';
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
      await storage.write(key: 'unlocked_themes', value: jsonEncode(unlockedMap));
    }

    // Merge: only themes present in serverUnlocks are considered unlocked (except always-free themes)
    final unlocked = <String>{};
    for (final themeKey in AppThemes.allThemes.keys) {
      if (themeKey == 'lightTheme' || themeKey == 'darkTheme') {
        unlocked.add(themeKey);
        continue;
      }
      final serverKey = 'emotion_tracker-$themeKey';
      final serverValid = serverUnlocks[serverKey];
      if (serverValid != null && serverValid.isAfter(now)) {
        unlocked.add(themeKey);
        continue;
      }
    }
    return unlocked;
  }

  /// Checks if a theme is currently unlocked (for global enforcement)
  Future<bool> isThemeUnlocked(String themeKey) async {
    final unlocked = await getMergedUnlockedThemes();
    return unlocked.contains(themeKey);
  }

  /// Loads and shows a rewarded ad for theme unlock, passing username as SSV custom data.
  Future<void> showThemeUnlockAd(BuildContext context, String themeKey, {VoidCallback? onThemeUnlocked}) async {
    final adUnitId = AppThemes.themeAdUnitIds[themeKey];
    if (adUnitId == null || adUnitId.isEmpty) return;
    final storage = ref.read(secureStorageProvider);
    final username = await storage.read(key: 'user_username');
    if (username == null || username.isEmpty) return;

    final theme = ref.read(currentThemeProvider);
    // Confirm with user, with notice about server-side verification delay
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unlock Theme', style: TextStyle(color: theme.primaryColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Watch a short ad to unlock this theme for 1 hour of usage. You can always buy it permanently later from shop.'),
            const SizedBox(height: 12),
            Text(
              'Note: It may take a few seconds after watching the ad for the theme to unlock, due to server-side verification.',
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
                if (reward.type == themeKey || reward.type != 'token') {
                  rewardGiven = true;
                  await unlockTheme(themeKey);
                  if (context.mounted) {
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Theme Unlocked!'),
                        content: const Text('You have unlocked the theme. You can now use it for 1 hour.'),
                        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
                      ),
                    );
                    // Only notify UI after all dialogs are closed
                    if (onThemeUnlocked != null) onThemeUnlocked();
                  }
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unexpected reward type. Theme not unlocked.')));
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
