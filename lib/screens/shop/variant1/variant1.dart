import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:emotion_tracker/providers/ad_provider.dart';
import 'package:emotion_tracker/providers/avatar_unlock_provider.dart';
import 'package:emotion_tracker/providers/banner_unlock_provider.dart';
import 'package:emotion_tracker/providers/bundle_unlock_provider.dart';
import 'package:emotion_tracker/providers/shop_cart_provider.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/theme_unlock_provider.dart';
import 'package:emotion_tracker/screens/settings/variant1.dart';
import 'package:emotion_tracker/widgets/app_scaffold.dart';

import '../cart/cart_view.dart';
import 'utils/shop_constants.dart';
import 'widgets/tabs/avatars_tab.dart';
import 'widgets/tabs/banners_tab.dart';
import 'widgets/tabs/bundles_tab.dart';
import 'widgets/tabs/currency_tab.dart';
import 'widgets/tabs/themes_tab.dart';

class ShopScreenV1 extends ConsumerStatefulWidget {
  const ShopScreenV1({super.key});

  @override
  ShopScreenV1State createState() => ShopScreenV1State();
}

class ShopScreenV1State extends ConsumerState<ShopScreenV1>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String>? _ownedThemes;
  Set<String> _ownedAvatars = {}; // Store owned avatar IDs
  Set<String> _ownedBanners = {}; // Store owned banner IDs
  Set<String> _ownedBundles = {}; // Store owned bundle IDs
  Map<String, AvatarUnlockInfo> _avatarUnlockInfo =
      {}; // Batch avatar unlock info
  Map<String, BannerUnlockInfo> _bannerUnlockInfo =
      {}; // Batch banner unlock info
  Map<String, ThemeUnlockInfo> _themeUnlockInfo = {}; // Batch theme unlock info
  bool _loadingAvatars = true;
  bool _loadingBanners = true;
  bool _loadingThemes = true;
  bool _loadingBundles = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: ShopConstants.tabCount, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && defaultTargetPlatform != TargetPlatform.linux) {
        ref
            .read(adProvider.notifier)
            .loadBannerAd(ShopConstants.avatarDetailBannerAdId);
      }
    });
    _loadOwnedCaches();
    _fetchOwnedAvatars();
    _fetchOwnedBanners();
    _fetchOwnedBundles();
  }

  Future<void> _loadOwnedCaches() async {
    setState(() {
      _loadingThemes = true;
    });
    try {
      final unlockService = ref.read(themeUnlockProvider);
      final owned = await unlockService.getMergedUnlockedThemes();

      // Create unlock info distinguishing between owned vs rented items
      final themeUnlockInfo = <String, ThemeUnlockInfo>{};
      for (final themeKey in owned) {
        // For owned items, set unlockTime to null (permanent ownership)
        // For rented items, we would need the actual unlock time from API
        // Since we're optimizing API calls, assume all items in "owned" are permanently owned
        themeUnlockInfo[themeKey] = ThemeUnlockInfo(
          isUnlocked: true,
          unlockTime: null, // null = permanently owned, not rented
        );
      }

      setState(() {
        _ownedThemes = owned.toList();
        _themeUnlockInfo = themeUnlockInfo;
        _loadingThemes = false;
      });
    } catch (_) {
      setState(() {
        _loadingThemes = false;
      });
    }
  }

  Future<void> _fetchOwnedAvatars() async {
    setState(() {
      _loadingAvatars = true;
    });
    try {
      final unlockService = ref.read(avatarUnlockProvider);

      // OPTIMIZATION: Use single batch call instead of individual calls
      // This reduces API calls from 2*N to just 2 total calls
      final owned = await unlockService.getMergedUnlockedAvatars();

      // Create unlock info distinguishing between owned vs rented items
      final avatarUnlockInfo = <String, AvatarUnlockInfo>{};
      for (final avatarId in owned) {
        // For owned items, set unlockTime to null (permanent ownership)
        // For rented items, we would need the actual unlock time from API
        // Since we're optimizing API calls, assume all items in "owned" are permanently owned
        avatarUnlockInfo[avatarId] = AvatarUnlockInfo(
          isUnlocked: true,
          unlockTime: null, // null = permanently owned, not rented
        );
      }

      setState(() {
        _ownedAvatars = owned;
        _avatarUnlockInfo = avatarUnlockInfo;
        _loadingAvatars = false;
      });
    } catch (_) {
      setState(() {
        _loadingAvatars = false;
      });
    }
  }

  Future<void> _fetchOwnedBanners() async {
    setState(() {
      _loadingBanners = true;
    });
    try {
      final unlockService = ref.read(bannerUnlockProvider);
      final owned = await unlockService.getMergedUnlockedBanners();

      // Create unlock info distinguishing between owned vs rented items
      final bannerUnlockInfo = <String, BannerUnlockInfo>{};
      for (final bannerId in owned) {
        // For owned items, set unlockTime to null (permanent ownership)
        // For rented items, we would need the actual unlock time from API
        // Since we're optimizing API calls, assume all items in "owned" are permanently owned
        bannerUnlockInfo[bannerId] = BannerUnlockInfo(
          isUnlocked: true,
          unlockTime: null, // null = permanently owned, not rented
        );
      }

      setState(() {
        _ownedBanners = owned;
        _bannerUnlockInfo = bannerUnlockInfo;
        _loadingBanners = false;
      });
    } catch (_) {
      setState(() {
        _loadingBanners = false;
      });
    }
  }

  Future<void> _fetchOwnedBundles() async {
    setState(() {
      _loadingBundles = true;
    });
    try {
      final unlockService = ref.read(bundleUnlockProvider);
      final owned = await unlockService.getOwnedBundles();
      setState(() {
        _ownedBundles = owned;
        _loadingBundles = false;
      });
    } catch (_) {
      setState(() {
        _loadingBundles = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onItemSelected(String item) {
    Navigator.of(context).pop();
    if (item == 'dashboard') {
      Navigator.of(context).pushReplacementNamed('/home/v1');
    } else if (item == 'settings') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SettingsScreenV1()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);

    return AppScaffold(
      title: 'Shop',
      selectedItem: 'shop',
      onItemSelected: _onItemSelected,
      actions: [
        Consumer(
          builder: (context, ref, _) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: ref.watch(shopCartProvider).getCart(),
              builder: (context, snapshot) {
                int count = (snapshot.data ?? []).length;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined),
                      tooltip: 'Cart',
                      onPressed: () async {
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => SafeArea(
                            child: const SizedBox(height: 500, child: CartView()),
                          ),
                        );
                        setState(() {}); // Refresh badge after modal closes
                      },
                    ),
                    if (count > 0)
                      Positioned(
                        right: ShopConstants.cartBadgePosition,
                        top: ShopConstants.cartBadgePosition,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: ShopConstants.cartBadgeMinSize,
                            minHeight: ShopConstants.cartBadgeMinSize,
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: ShopConstants.cartBadgeFontSize,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ],
      showCurrency: false,
      body: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.7,
              ),
              indicatorColor: theme.colorScheme.primary,
              indicator: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
              tabs: ShopConstants.tabLabels
                  .map((label) => Tab(text: label))
                  .toList(),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  AvatarsTab(
                    isLoading: _loadingAvatars,
                    ownedAvatars: _ownedAvatars,
                    avatarUnlockInfo: _avatarUnlockInfo,
                    onRefresh: _fetchOwnedAvatars,
                  ),
                  BannersTab(
                    isLoading: _loadingBanners,
                    ownedBanners: _ownedBanners,
                    bannerUnlockInfo: _bannerUnlockInfo,
                    onRefresh: _fetchOwnedBanners,
                  ),
                  ThemesTab(
                    isLoading: _loadingThemes,
                    ownedThemes: _ownedThemes,
                    themeUnlockInfo: _themeUnlockInfo,
                    onRefresh: _loadOwnedCaches,
                  ),
                  BundlesTab(
                    isLoading: _loadingBundles,
                    ownedBundles: _ownedBundles,
                    onRefresh: _fetchOwnedBundles,
                  ),
                  const CurrencyTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
