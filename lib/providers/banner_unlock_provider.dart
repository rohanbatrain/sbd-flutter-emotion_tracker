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

  /// Force-invalidate the in-memory cache for a given banner (for pull-to-refresh or navigation).
  void invalidateBannerCache(String bannerId) {
    _unlockCache.remove(bannerId);
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
    // Invalidate cache for this banner
    invalidateBannerCache(bannerId);
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
    final ownedUrl = Uri.parse('$protocol://$domain/shop/banners/owned');
    final now = DateTime.now().toUtc();
    Map<String, DateTime> serverUnlocks = {};
    Set<String> ownedPermanent = {};

    // Fetch server rentals
    if (accessToken != null && accessToken.isNotEmpty) {
      try {
        final userAgent = await getUserAgent();
        final response = await http.get(
          apiUrl,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'User-Agent': userAgent,
            'X-User-Agent': userAgent,
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
      // Fetch permanent owned banners
      try {
        final userAgent = await getUserAgent();
        final ownedResp = await http.get(
          ownedUrl,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'User-Agent': userAgent,
            'X-User-Agent': userAgent,
          },
        );
        if (ownedResp.statusCode == 200) {
          final data = jsonDecode(ownedResp.body);
          final List<dynamic> owned = data['banners_owned'] ?? [];
          for (final entry in owned) {
            final bannerId = entry['banner_id'] as String?;
            final permanent = entry['permanent'] == true;
            if (bannerId != null && permanent) {
              ownedPermanent.add(bannerId);
            }
          }
        }
      } catch (e) {
        // On error, treat as not owned
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

    // Merge: ownedPermanent always unlocked, then server rentals, then local unlocks
    final result = <String, BannerUnlockInfo>{};
    for (final banner in allProfileBanners) {
      if (banner.id == 'default-dark' || banner.id == 'default-light') {
        result[banner.id] = BannerUnlockInfo(isUnlocked: true, unlockTime: null);
        continue;
      }
      if (ownedPermanent.contains(banner.id)) {
        result[banner.id] = BannerUnlockInfo(isUnlocked: true, unlockTime: null);
        continue;
      }
      final serverValid = serverUnlocks[banner.id];
      if (serverValid != null && serverValid.isAfter(now)) {
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

  /// Attempts to buy a banner permanently via the /shop/banners/buy endpoint.
  /// Throws an Exception with a user-friendly message on failure.
  Future<void> buyBanner(BuildContext context, String bannerId) async {
    final storage = ref.read(secureStorageProvider);
    final accessToken = await storage.read(key: 'access_token');
    final protocol = ref.read(serverProtocolProvider);
    final domain = ref.read(serverDomainProvider);
    final apiUrl = Uri.parse('$protocol://$domain/shop/banners/buy');
    final userAgent = await getUserAgent();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('You must be logged in to buy banners.');
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
          'X-User-Agent': userAgent,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'banner_id': bannerId}),
      );
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      if (response.statusCode == 200) {
        // Success: update local cache by refetching owned banners
        invalidateBannerCache(bannerId);
        await getBannerUnlockInfo(bannerId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Banner purchased successfully!')),
          );
        }
        return;
      }
      // Error handling
      final data = jsonDecode(response.body);
      final detail = data['detail'] ?? 'Unknown error';
      if (response.statusCode == 400 && detail == 'Banner already owned') {
        throw Exception('You already own this banner.');
      } else if (response.statusCode == 400 && (detail == 'Not enough SBD tokens' || detail == 'Insufficient SBD tokens or race condition')) {
        throw Exception('You do not have enough SBD tokens.');
      } else if (response.statusCode == 400 && detail == 'Invalid or missing banner_id') {
        throw Exception('Invalid banner.');
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
