import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/providers/shared_prefs_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:emotion_tracker/providers/user_agent_util.dart';
import 'package:emotion_tracker/providers/theme_unlock_provider.dart';

class ThemeSelectionScreenV1 extends ConsumerStatefulWidget {
  const ThemeSelectionScreenV1({Key? key}) : super(key: key);

  @override
  ConsumerState<ThemeSelectionScreenV1> createState() => _ThemeSelectionScreenV1State();
}

class _ThemeSelectionScreenV1State extends ConsumerState<ThemeSelectionScreenV1> {
  int toggleState = 0; // 0 = Light, 1 = Dark

  /// Unlocks the theme for the user by updating secure storage with a 1-hour expiry.
  Future<void> _unlockTheme(String themeKey) async {
    final storage = ref.read(secureStorageProvider);
    final unlockedJson = (await storage.read(key: 'unlocked_themes')) ?? '{}';
    Map<String, dynamic> unlockedMap;
    try {
      unlockedMap = Map<String, dynamic>.from(jsonDecode(unlockedJson));
    } catch (_) {
      unlockedMap = {};
    }
    // Set unlock time to now (ms since epoch)
    unlockedMap[themeKey] = DateTime.now().millisecondsSinceEpoch;
    await storage.write(key: 'unlocked_themes', value: jsonEncode(unlockedMap));
  }

  /// Helper to fetch and merge server and local unlocks. Server always wins if locked.
  Future<Set<String>> _getMergedUnlockedThemes() async {
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
          // Group by theme_id, take latest valid_till in the future
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
            // Use the latest valid_till for each theme
            final latest = grouped[themeId]!.reduce((a, b) => a.isAfter(b) ? a : b);
            serverUnlocks[themeId] = latest;
          }
        }
      } catch (e) {
        // On error, treat as all locked except local unlocks
      }
    }

    // Get valid local unlocks (current logic: one per theme)
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
      // Server wins: must be present and valid in serverUnlocks
      // Fix: match by stripping prefix
      final serverKey = 'emotion_tracker-$themeKey';
      final serverValid = serverUnlocks[serverKey];
      if (serverValid != null && serverValid.isAfter(now)) {
        unlocked.add(themeKey);
        continue;
      }
      // If not present in server, treat as locked, regardless of local
    }
    return unlocked;
  }

  /// Loads and shows a rewarded ad for theme unlock, passing username as SSV custom data.
  Future<void> showThemeUnlockAd(String themeKey) async {
    final adUnitId = AppThemes.themeAdUnitIds[themeKey];
    print('[ThemeSelectionScreen] [reinvented] Unlock theme: $themeKey, adUnitId: $adUnitId');
    if (adUnitId == null || adUnitId.isEmpty) return;
    final storage = ref.read(secureStorageProvider);
    final username = await storage.read(key: 'user_username');
    if (username == null || username.isEmpty) return;

    // Confirm with user
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlock Theme'),
        content: const Text('Watch a short ad to unlock this theme for 1 hour of usage. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Watch Ad')),
        ],
      ),
    );
    if (proceed != true) return;

    // Show loading
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    bool rewardGiven = false;
    try {
      RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) async {
            // Hide loading spinner just before showing the ad
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            // Pass username for SSV
            ad.setServerSideOptions(ServerSideVerificationOptions(userId: username));
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                if (!rewardGiven) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ad closed before reward.')));
                }
              },
              onAdFailedToShowFullScreenContent: (ad, err) {
                ad.dispose();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to show ad.')));
              },
            );
            ad.show(
              onUserEarnedReward: (ad, reward) async {
                print('[ThemeAd] Reward type: '+reward.type+', amount: '+reward.amount.toString());
                // Only unlock if reward type matches themeKey or is not 'token'
                if (reward.type == themeKey || reward.type != 'token') {
                  rewardGiven = true;
                  await _unlockTheme(themeKey);
                  if (mounted) {
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Theme Unlocked!'),
                        content: Text('You have unlocked the theme. You can now use it for 1 hour.'),
                        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
                      ),
                    );
                    setState(() {});
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unexpected reward type. Theme not unlocked.')));
                }
              },
            );
          },
          onAdFailedToLoad: (err) {
            // Hide loading spinner if ad fails to load
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load ad.')));
          },
        ),
      );
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ad error: $e')));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentThemeKey = ref.read(themeProvider);
    if (AppThemes.darkThemeKeys.contains(currentThemeKey)) {
      if (toggleState != 1) setState(() => toggleState = 1);
    } else if (AppThemes.lightThemeKeys.contains(currentThemeKey)) {
      if (toggleState != 0) setState(() => toggleState = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final currentThemeKey = ref.watch(themeProvider);
    final isLight = toggleState == 0;
    final themeKeys = isLight ? AppThemes.lightThemeKeys : AppThemes.darkThemeKeys;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Theme Selection',
        showHamburger: false,
        showCurrency: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh themes',
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            // Toggle for Light/Dark with swipe support
            GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < 0 && toggleState == 0) {
                    // Swipe left: Light -> Dark
                    setState(() => toggleState = 1);
                  } else if (details.primaryVelocity! > 0 && toggleState == 1) {
                    // Swipe right: Dark -> Light
                    setState(() => toggleState = 0);
                  }
                }
              },
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ThemeToggleButton(
                        label: 'Light',
                        selected: isLight,
                        onTap: () => setState(() => toggleState = 0),
                        icon: Icons.wb_sunny_outlined,
                      ),
                      _ThemeToggleButton(
                        label: 'Dark',
                        selected: !isLight,
                        onTap: () => setState(() => toggleState = 1),
                        icon: Icons.nightlight_round,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Choose your preferred theme:',
              style: theme.textTheme.bodyLarge,
            ),
            SizedBox(height: 16),
            // Swipe support for theme grid as well
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < 0 && toggleState == 0) {
                      setState(() => toggleState = 1);
                    } else if (details.primaryVelocity! > 0 && toggleState == 1) {
                      setState(() => toggleState = 0);
                    }
                  }
                },
                child: FutureBuilder<Set<String>>(
                  future: _getMergedUnlockedThemes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 32),
                            SizedBox(height: 12),
                            Text('Failed to load theme unlocks.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            ElevatedButton.icon(
                              icon: Icon(Icons.refresh),
                              label: Text('Retry'),
                              onPressed: () => setState(() {}),
                            ),
                          ],
                        ),
                      );
                    }
                    final unlockedThemes = snapshot.data ?? {};
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: themeKeys.length,
                      itemBuilder: (context, index) {
                        final themeKey = themeKeys[index];
                        final themeName = AppThemes.themeNames[themeKey];
                        final themeData = AppThemes.allThemes[themeKey];
                        if (themeName == null || themeData == null) {
                          return Container(
                            alignment: Alignment.center,
                            child: Text(
                              'Theme config error: $themeKey',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        final isSelected = currentThemeKey == themeKey;
                        final isUnlocked = themeKey == 'lightTheme' || themeKey == 'darkTheme' || unlockedThemes.contains(themeKey);
                        return GestureDetector(
                          onTap: () async {
                            if (!isUnlocked) {
                              // Use provider's ad unlock logic with callback to refresh UI only after ad is finished
                              final themeUnlockService = ref.read(themeUnlockProvider);
                              await themeUnlockService.showThemeUnlockAd(context, themeKey, onThemeUnlocked: () {
                                setState(() {});
                              });
                              return;
                            }
                            ref.read(themeProvider.notifier).setTheme(themeKey);
                          },
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? themeData.primaryColor : Colors.grey.withOpacity(0.3),
                                    width: isSelected ? 3 : 1,
                                  ),
                                  color: themeData.primaryColor.withOpacity(0.1),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: themeData.primaryColor,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        themeName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: themeData.primaryColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (!isUnlocked)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Icon(Icons.lock, color: themeData.primaryColor, size: 18),
                                ),
                              if (isSelected)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Icon(
                                    Icons.check_circle,
                                    color: themeData.primaryColor,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Beautiful toggle button widget
class _ThemeToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  const _ThemeToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.white : Theme.of(context).iconTheme.color),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
