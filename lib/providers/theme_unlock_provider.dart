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

  /// Helper to fetch and merge server and local unlocks, including permanent ownership.
  Future<Set<String>> getMergedUnlockedThemes() async {
    final storage = ref.read(secureStorageProvider);
    final accessToken = await storage.read(key: 'access_token');
    final protocol = ref.read(serverProtocolProvider);
    final domain = ref.read(serverDomainProvider);
    final rentedUrl = Uri.parse('$protocol://$domain/themes/rented');
    final ownedUrl = Uri.parse('$protocol://$domain/shop/themes/owned');
    final now = DateTime.now().toUtc();
    Map<String, DateTime> serverUnlocks = {};
    Set<String> ownedPermanent = {};

    // Fetch server rentals
    if (accessToken != null && accessToken.isNotEmpty) {
      try {
        final userAgent = await getUserAgent();
        final response = await http.get(
          rentedUrl,
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
      // Fetch permanent owned themes
      try {
        final userAgent = await getUserAgent();
        final ownedResp = await http.get(
          ownedUrl,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'User-Agent': userAgent,
          },
        );
        if (ownedResp.statusCode == 200) {
          final data = jsonDecode(ownedResp.body);
          final List<dynamic> owned = data['themes_owned'] ?? [];
          for (final entry in owned) {
            final themeId = entry['theme_id'] as String?;
            final permanent = entry['permanent'] == true;
            if (themeId != null && permanent) {
              // Remove prefix for local key
              final localKey = themeId.replaceFirst('emotion_tracker-', '');
              ownedPermanent.add(localKey);
            }
          }
        }
      } catch (e) {
        // On error, treat as not owned
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
        validLocal[key] = DateTime.fromMillisecondsSinceEpoch(value).toUtc();
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

    // Merge: ownedPermanent always unlocked, then server rentals, then local unlocks
    final unlocked = <String>{};
    for (final themeKey in AppThemes.allThemes.keys) {
      if (themeKey == 'lightTheme' || themeKey == 'darkTheme') {
        unlocked.add(themeKey);
        continue;
      }
      if (ownedPermanent.contains(themeKey)) {
        unlocked.add(themeKey);
        continue;
      }
      final serverKey = 'emotion_tracker-$themeKey';
      final serverValid = serverUnlocks[serverKey];
      if (serverValid != null && serverValid.isAfter(now)) {
        unlocked.add(themeKey);
        continue;
      }
      final localValid = validLocal[themeKey];
      if (localValid != null && now.isBefore(localValid.add(const Duration(hours: 1)))) {
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

  /// Attempts to buy a theme permanently via the /shop/themes/buy endpoint.
  /// Throws an Exception with a user-friendly message on failure.
  Future<void> buyTheme(BuildContext context, String themeKey) async {
    final storage = ref.read(secureStorageProvider);
    final accessToken = await storage.read(key: 'access_token');
    final protocol = ref.read(serverProtocolProvider);
    final domain = ref.read(serverDomainProvider);
    final apiUrl = Uri.parse('$protocol://$domain/shop/themes/buy');
    final userAgent = await getUserAgent();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('You must be logged in to buy themes.');
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.post(
        apiUrl,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'User-Agent': userAgent,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'theme_id': 'emotion_tracker-$themeKey'}),
      );
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      if (response.statusCode == 200) {
        // Success: update local cache by refetching owned themes
        await unlockTheme(themeKey); // Mark as unlocked locally
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Theme purchased successfully!')),
          );
        }
        return;
      }
      // Error handling
      final data = jsonDecode(response.body);
      final detail = data['detail'] ?? 'Unknown error';
      if (response.statusCode == 400 && detail == 'Theme already owned') {
        throw Exception('You already own this theme.');
      } else if (response.statusCode == 400 && (detail == 'Not enough SBD tokens' || detail == 'Insufficient SBD tokens or race condition')) {
        throw Exception('You do not have enough SBD tokens.');
      } else if (response.statusCode == 400 && detail == 'Invalid or missing theme_id') {
        throw Exception('Invalid theme.');
      } else if (response.statusCode == 403 && detail == 'Shop access denied: invalid client') {
        throw Exception('Shop access denied: invalid client.');
      } else if (response.statusCode == 404 && detail == 'User not found') {
        throw Exception('User not found. Please log in again.');
      } else if (response.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception(detail.toString());
      }
    } catch (e) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      rethrow;
    }
  }
}
