import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/providers/shared_prefs_provider.dart';
import 'package:emotion_tracker/providers/user_agent_util.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:emotion_tracker/providers/custom_banner.dart';

/// Provider for banner unlock logic (local + server sync, robust enforcement)
final bannerUnlockProvider = Provider<BannerUnlockService>((ref) {
  return BannerUnlockService(ref);
});

class BannerUnlockService {
  final Ref ref;
  BannerUnlockService(this.ref);

  // In-memory cache: bannerId -> { unlocked: bool, unlockTime: DateTime? }
  final Map<String, _BannerUnlockCache> _unlockCache = {};

  /// Clears the in-memory unlock cache (for pull-to-refresh or logout)
  void clearCache() {
    _unlockCache.clear();
  }

  /// Unlocks the banner for the user by updating secure storage with a 1-hour expiry.
  Future<void> unlockBanner(String bannerId) async {
    final storage = ref.read(secureStorageProvider);
    final unlockedJson = (await storage.read(key: 'unlocked_banners')) ?? '{}';
    Map<String, dynamic> unlockedMap;
    try {
      unlockedMap = Map<String, dynamic>.from(jsonDecode(unlockedJson));
    } catch (_) {
      unlockedMap = {};
    }
    unlockedMap[bannerId] = DateTime.now().millisecondsSinceEpoch;
    await storage.write(key: 'unlocked_banners', value: jsonEncode(unlockedMap));
  }

  /// Returns unlock status and unlock timestamp for UI logic.
  /// Always checks server if cache is expired (older than 1 hour), else uses cache.
  Future<BannerUnlockInfo> getBannerUnlockInfo(String bannerId) async {
    final now = DateTime.now().toUtc();
    final cache = _unlockCache[bannerId];
    if (cache != null && now.difference(cache.lastChecked).inMinutes < 60) {
      // Use cache if less than 1 hour old
      return BannerUnlockInfo(
        isUnlocked: cache.isUnlocked,
        unlockTime: cache.unlockTime,
      );
    }
    // Fetch from storage/server
    final unlocks = await _getMergedUnlockedBannersWithTimes();
    final info = unlocks[bannerId] ?? BannerUnlockInfo(isUnlocked: false, unlockTime: null);
    _unlockCache[bannerId] = _BannerUnlockCache(
      isUnlocked: info.isUnlocked,
      unlockTime: info.unlockTime,
      lastChecked: now,
    );
    return info;
  }

  /// Helper: like getMergedUnlockedBanners, but returns unlock time for each banner.
  Future<Map<String, BannerUnlockInfo>> _getMergedUnlockedBannersWithTimes() async {
    final storage = ref.read(secureStorageProvider);
    final accessToken = await storage.read(key: 'access_token');
    final protocol = ref.read(serverProtocolProvider);
    final domain = ref.read(serverDomainProvider);
    final apiUrl = Uri.parse('$protocol://$domain/banners/rented');
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
          final List<dynamic> rented = data['banners_rented'] ?? [];
          final Map<String, List<DateTime>> grouped = {};
          for (final entry in rented) {
            final bannerId = entry['banner_id'] as String?;
            final validTillStr = entry['valid_till'] as String?;
            if (bannerId != null && validTillStr != null) {
              final validTill = DateTime.parse(validTillStr).toUtc();
              if (validTill.isAfter(now)) {
                grouped.putIfAbsent(bannerId, () => []).add(validTill);
              }
            }
          }
          for (final bannerId in grouped.keys) {
            final latest = grouped[bannerId]!.reduce((a, b) => a.isAfter(b) ? a : b);
            serverUnlocks[bannerId] = latest;
          }
        }
      } catch (e) {
        // On error, treat as all locked except local unlocks
      }
    }

    // Get valid local unlocks
    final unlockedJson = (await storage.read(key: 'unlocked_banners')) ?? '{}';
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
      await storage.write(key: 'unlocked_banners', value: jsonEncode(unlockedMap));
    }

    // Merge: only banners present in serverUnlocks are considered unlocked (except always-free/default banners)
    final result = <String, BannerUnlockInfo>{};
    for (final banner in allProfileBanners) {
      if (banner.id == 'default-dark' || banner.id == 'default-light') {
        result[banner.id] = BannerUnlockInfo(isUnlocked: true, unlockTime: null);
        continue;
      }
      final serverValid = serverUnlocks[banner.id];
      if (serverValid != null && serverValid.isAfter(now)) {
        // Use server unlock time (subtract 1 hour to get unlock time)
        result[banner.id] = BannerUnlockInfo(
          isUnlocked: true,
          unlockTime: serverValid.subtract(const Duration(hours: 1)),
        );
        continue;
      }
      final localValid = validLocal[banner.id];
      if (localValid != null && now.isBefore(localValid.add(const Duration(hours: 1)))) {
        result[banner.id] = BannerUnlockInfo(
          isUnlocked: true,
          unlockTime: localValid,
        );
        continue;
      }
      result[banner.id] = BannerUnlockInfo(isUnlocked: false, unlockTime: null);
    }
    return result;
  }

  /// Helper to fetch and merge server and local unlocks. Server always wins if locked.
  Future<Set<String>> getMergedUnlockedBanners() async {
    final unlocks = await _getMergedUnlockedBannersWithTimes();
    return unlocks.entries.where((entry) => entry.value.isUnlocked).map((entry) => entry.key).toSet();
  }

  /// Checks if a banner is currently unlocked (for global enforcement)
  Future<bool> isBannerUnlocked(String bannerId) async {
    final info = await getBannerUnlockInfo(bannerId);
    return info.isUnlocked;
  }

  /// Loads and shows a rewarded ad for banner unlock, passing username as SSV custom data.
  /// No confirmation popup, ad loads immediately.
  Future<void> showBannerUnlockAd(BuildContext context, String bannerId, {VoidCallback? onBannerUnlocked}) async {
    final banner = allProfileBanners.firstWhere((b) => b.id == bannerId, orElse: () => allProfileBanners.first);
    final adUnitId = banner.rewardedAdId;
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ad failed to show: ${err.message}')));
                }
              },
            );
            ad.show(
              onUserEarnedReward: (ad, reward) async {
                rewardGiven = true;
                await unlockBanner(bannerId);
                _unlockCache.remove(bannerId); // Invalidate cache
                onBannerUnlocked?.call();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Banner unlocked for 1 hour!')));
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

class BannerUnlockInfo {
  final bool isUnlocked;
  final DateTime? unlockTime;
  BannerUnlockInfo({required this.isUnlocked, required this.unlockTime});
}

class _BannerUnlockCache {
  final bool isUnlocked;
  final DateTime? unlockTime;
  final DateTime lastChecked;
  _BannerUnlockCache({required this.isUnlocked, required this.unlockTime, required this.lastChecked});
}
