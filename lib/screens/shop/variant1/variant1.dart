import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/widgets/app_scaffold.dart';
import 'package:emotion_tracker/screens/settings/variant1.dart';
import 'package:emotion_tracker/providers/custom_avatar.dart';
import 'package:emotion_tracker/providers/custom_banner.dart';
import 'package:emotion_tracker/providers/banner_unlock_provider.dart';
import 'package:emotion_tracker/providers/ad_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:emotion_tracker/providers/avatar_unlock_provider.dart';
import 'package:emotion_tracker/providers/custom_bundle.dart';
import 'package:emotion_tracker/providers/theme_unlock_provider.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class CurrencyPack {
  final String name;
  final String description;
  final int coins;
  final int price;
  final int bonus;
  final String tag;

  const CurrencyPack({
    required this.name,
    required this.description,
    required this.coins,
    required this.price,
    this.bonus = 0,
    this.tag = '',
  });

  String get effectiveRate {
    return (price / (coins + bonus)).toStringAsFixed(3);
  }

  String get bonusText {
    return bonus > 0 ? '+${bonus}' : '—';
  }
}

final List<CurrencyPack> currencyPacks = [
  const CurrencyPack(
    name: 'Nano',
    description: 'A small token to support our ecosystem of apps.',
    coins: 200,
    price: 79,
  ),
  const CurrencyPack(
    name: 'Micro',
    description: 'Help us improve our apps and add new features.',
    coins: 500,
    price: 179,
    bonus: 50,
  ),
  const CurrencyPack(
    name: 'Standard',
    description: 'A popular choice for enhancing your experience across our apps.',
    coins: 1200,
    price: 399,
    bonus: 200,
  ),
  const CurrencyPack(
    name: 'Mega',
    description: 'For those who love our ecosystem and want to see it thrive.',
    coins: 2500,
    price: 799,
    bonus: 500,
    tag: '🔥 Best Value',
  ),
  const CurrencyPack(
    name: 'Giga',
    description: 'The ultimate support for our ecosystem of apps.',
    coins: 6000,
    price: 1599,
    bonus: 1500,
    tag: '💎 Premium',
  ),
];

class ShopScreenV1 extends ConsumerStatefulWidget {
  const ShopScreenV1({Key? key}) : super(key: key);

  @override
  _ShopScreenV1State createState() => _ShopScreenV1State();
}

class _ShopScreenV1State extends ConsumerState<ShopScreenV1> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const String avatarDetailBannerAdId = 'avatar_detail_banner';
  List<String>? _ownedThemes;
  Set<String> _ownedAvatars = {}; // Store owned avatar IDs
  Set<String> _ownedBanners = {}; // Store owned banner IDs
  bool _loadingAvatars = true;
  bool _loadingBanners = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // Updated to 5 tabs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && defaultTargetPlatform != TargetPlatform.linux) {
        ref.read(adProvider.notifier).loadBannerAd(avatarDetailBannerAdId);
      }
    });
    _loadOwnedCaches();
    _fetchOwnedAvatars();
    _fetchOwnedBanners();
  }

  Future<void> _loadOwnedCaches() async {
    // Simulate loading owned themes from a cache or provider
    _ownedThemes = ['theme1', 'theme2']; // Example owned themes
  }

  Future<void> _fetchOwnedAvatars() async {
    setState(() {
      _loadingAvatars = true;
    });
    try {
      final unlockService = ref.read(avatarUnlockProvider);
      final owned = await unlockService.getMergedUnlockedAvatars();
      setState(() {
        _ownedAvatars = owned;
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
      setState(() {
        _ownedBanners = owned;
        _loadingBanners = false;
      });
    } catch (_) {
      setState(() {
        _loadingBanners = false;
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
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SettingsScreenV1()),
      );
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
        IconButton(
          icon: Icon(Icons.shopping_cart_outlined),
          tooltip: 'Cart',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Cart feature coming soon!')),
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
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
              indicatorColor: theme.colorScheme.primary,
              indicator: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
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
              tabs: const [
                Tab(text: 'Avatars'),
                Tab(text: 'Banners'),
                Tab(text: 'Themes'),
                Tab(text: 'Bundles'),
                Tab(text: 'Currency'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAvatarsGrid(theme),
                  _buildBannersGrid(theme),
                  _buildThemesGrid(theme),
                  _buildBundlesGrid(theme),
                  _buildCurrencyShop(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarsGrid(ThemeData theme) {
    final Map<String, List<Avatar>> avatarCategories = {
      'Cats 🐱': catAvatars,
      'Dogs 🐶': dogAvatars,
      'Pandas 🐼': pandaAvatars,
      'People 👤': peopleAvatars,
      'Animated ✨': animatedAvatars,
    };

    if (_loadingAvatars) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchOwnedAvatars();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: avatarCategories.length,
        itemBuilder: (context, index) {
          final category = avatarCategories.keys.elementAt(index);
          final avatars = avatarCategories[category]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  category,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.65, // Adjusted for better layout
                ),
                itemCount: avatars.length,
                itemBuilder: (context, index) {
                  final avatar = avatars[index];
                  final isUnlocked = _ownedAvatars.contains(avatar.id);
                  final unlockInfo = ref.read(avatarUnlockProvider).getAvatarUnlockInfo(avatar.id);
                  return FutureBuilder<AvatarUnlockInfo>(
                    future: unlockInfo,
                    builder: (context, snapshot) {
                      final info = snapshot.data;
                      final isRented = (info?.isUnlocked ?? false) &&
                          (info?.unlockTime != null) &&
                          DateTime.now().toUtc().difference(info!.unlockTime!).inHours < 1;
                      final isOwned = isUnlocked && (!isRented);
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(0.5),
                              builder: (context) => AvatarDetailDialog(
                                avatar: avatar,
                                adId: avatarDetailBannerAdId,
                                onAvatarBought: () async {
                                  await _fetchOwnedAvatars();
                                },
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Container(
                                  color: theme.colorScheme.onSurface.withOpacity(0.05),
                                  padding: const EdgeInsets.all(8),
                                  child: AvatarDisplay(
                                    avatar: avatar,
                                    size: 50,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      avatar.name,
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    if (!isUnlocked)
                                      Text(
                                        avatar.price == 0 ? 'Free' : '${avatar.price} SBD',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.secondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 4),
                                    if (!isUnlocked)
                                      SizedBox(
                                        height: 30,
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(Icons.add_shopping_cart_outlined),
                                          iconSize: 22,
                                          color: theme.colorScheme.secondary,
                                          tooltip: 'Add to Cart',
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Added to cart (feature coming soon!)'),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    if (isOwned)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Owned',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    if (isRented)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Rented',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBannersGrid(ThemeData theme) {
    final earthBanners = allProfileBanners.where((b) => b.price > 0 && b.id.contains('earth')).toList();

    if (_loadingBanners) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchOwnedBanners();
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (earthBanners.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Earth Banners',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: earthBanners.length,
              itemBuilder: (context, index) {
                final banner = earthBanners[index];
                final isUnlocked = _ownedBanners.contains(banner.id);
                final unlockInfo = ref.read(bannerUnlockProvider).getBannerUnlockInfo(banner.id);
                return FutureBuilder<BannerUnlockInfo>(
                  future: unlockInfo,
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    final isRented = (info?.isUnlocked ?? false) &&
                        (info?.unlockTime != null) &&
                        DateTime.now().toUtc().difference(info!.unlockTime!).inHours < 1;
                    final isOwned = isUnlocked && (!isRented);
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            barrierColor: Colors.black.withOpacity(0.5),
                            builder: (context) => BannerDetailDialog(
                              banner: banner,
                              adId: 'banner_detail_banner_ad',
                            ),
                          ).then((_) => _fetchOwnedBanners());
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Container(
                                color: theme.colorScheme.onSurface.withOpacity(0.05),
                                child: ProfileBannerDisplay(
                                  banner: banner,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    banner.name ?? '',
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  if (!isUnlocked)
                                    Text(
                                      '${banner.price} SBD',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.secondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 4),
                                  if (!isUnlocked)
                                    SizedBox(
                                      height: 30,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.add_shopping_cart_outlined),
                                        iconSize: 22,
                                        color: theme.colorScheme.secondary,
                                        tooltip: 'Add to Cart',
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Added to cart (feature coming soon!)'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  if (isOwned)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Owned',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  if (isRented)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Rented',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildThemesGrid(ThemeData theme) {
    final lightThemes = AppThemes.allThemes.entries
        .where((entry) => entry.value.brightness == Brightness.light)
        .toList();
    final darkThemes = AppThemes.allThemes.entries
        .where((entry) => entry.value.brightness == Brightness.dark)
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (lightThemes.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Light Themes',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: lightThemes.length,
              itemBuilder: (context, index) {
                final themeKey = lightThemes[index].key;
                final appTheme = lightThemes[index].value;
                final themeName = AppThemes.themeNames[themeKey]!;
                final themePrice = AppThemes.themePrices[themeKey]!;

                return _buildThemeCard(theme, appTheme, themeName, themePrice, themeKey);
              },
            ),
            const SizedBox(height: 16),
          ],
          if (darkThemes.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Dark Themes',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: darkThemes.length,
              itemBuilder: (context, index) {
                final themeKey = darkThemes[index].key;
                final appTheme = darkThemes[index].value;
                final themeName = AppThemes.themeNames[themeKey]!;
                final themePrice = AppThemes.themePrices[themeKey]!;

                return _buildThemeCard(theme, appTheme, themeName, themePrice, themeKey);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBundlesGrid(ThemeData theme) {
    final avatarBundles = bundles.where((b) => b.id.contains('avatars')).toList();
    final themeBundles = bundles.where((b) => b.id.contains('themes')).toList();

    final Map<String, List<Bundle>> bundleCategories = {
      'Avatar Bundles 📦': avatarBundles,
      'Theme Bundles 🎨': themeBundles,
    };

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: bundleCategories.length,
        itemBuilder: (context, index) {
          final category = bundleCategories.keys.elementAt(index);
          final categoryBundles = bundleCategories[category]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  category,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.74, // Adjusted aspect ratio to resolve overflow
                ),
                itemCount: categoryBundles.length,
                itemBuilder: (context, index) {
                  final bundle = categoryBundles[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierColor: Colors.black.withOpacity(0.5),
                          builder: (context) => BundleDetailDialog(
                            bundle: bundle,
                          ),
                        );
                      },
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary.withOpacity(0.1),
                                  theme.colorScheme.secondary.withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                  child: Image.asset(
                                    bundle.image,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bundle.name,
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${bundle.price} SBD',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: theme.colorScheme.secondary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add_shopping_cart_outlined),
                                            iconSize: 22,
                                            color: theme.colorScheme.secondary,
                                            tooltip: 'Add to Cart',
                                            onPressed: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Added to cart (feature coming soon!)'),
                                                  duration: Duration(seconds: 2),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'New',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeCard(ThemeData theme, ThemeData appTheme, String themeName, int themePrice, String themeKey) {
    final isThemeOwned = (_ownedThemes?.contains(themeKey) ?? false) || themePrice == 0;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          if (!isThemeOwned) {
            await showDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.5),
              builder: (context) => ThemeDetailDialog(
                themeKey: themeKey,
                theme: theme,
                price: themePrice,
                isOwned: false,
                adUnitId: AppThemes.themeAdUnitIds[themeKey],
                onThemeUnlocked: () async {
                  await _loadOwnedCaches();
                  setState(() {});
                },
                onThemeBought: () async {
                  await _loadOwnedCaches();
                  setState(() {});
                },
              ),
            );
          } else {
            // Show owned dialog
            await showDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.5),
              builder: (context) => ThemeDetailDialog(
                themeKey: themeKey,
                theme: theme,
                price: themePrice,
                isOwned: true,
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: theme.colorScheme.onSurface.withOpacity(0.05),
                child: Center(
                  child: Icon(Icons.palette_rounded, size: 48, color: appTheme.primaryColor),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Column(
                children: [
                  Text(
                    themeName,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  if (!isThemeOwned)
                    Text(
                      themePrice == 0 ? 'Free' : '$themePrice SBD',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  if (!isThemeOwned) // Only show Add to Cart if not owned
                    SizedBox(
                      height: 30,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.add_shopping_cart_outlined),
                        iconSize: 22,
                        color: theme.colorScheme.secondary,
                        tooltip: 'Add to Cart',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added to cart (feature coming soon!)'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  if (isThemeOwned)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Owned',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyShop(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Currency Packs',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7, // Adjust as needed
          ),
          itemCount: currencyPacks.length,
          itemBuilder: (context, index) {
            final pack = currencyPacks[index];
            return Stack(
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      // TODO: Handle currency pack purchase
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24.0, left: 12.0, right: 12.0, bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pack.name,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${pack.coins} Coins',
                                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                pack.description,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          Text(
                            '₹${pack.price}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (pack.tag.isNotEmpty)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: pack.tag.contains('Best Value') ? theme.colorScheme.secondary : theme.colorScheme.primary,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        pack.tag,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Your purchases support the maintenance of our entire ecosystem of apps, and this currency works across all of them. Thank you for your support! ❤️',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
          ),
        ),
      ],
    );
  }
}

class AvatarDetailDialog extends ConsumerStatefulWidget {
  final Avatar avatar;
  final String adId;
  final VoidCallback? onAvatarBought;

  const AvatarDetailDialog({
    Key? key,
    required this.avatar,
    required this.adId,
    this.onAvatarBought,
  }) : super(key: key);

  @override
  _AvatarDetailDialogState createState() => _AvatarDetailDialogState();
}

class _AvatarDetailDialogState extends ConsumerState<AvatarDetailDialog> {
  late Future<AvatarUnlockInfo> _unlockInfoFuture;
  bool _hasRefreshed = false;

  @override
  void initState() {
    super.initState();
    _unlockInfoFuture = ref.read(avatarUnlockProvider).getAvatarUnlockInfo(widget.avatar.id);
  }

  void _refreshUnlockInfo() {
    if (!_hasRefreshed) {
      setState(() {
        _unlockInfoFuture = ref.read(avatarUnlockProvider).getAvatarUnlockInfo(widget.avatar.id);
        _hasRefreshed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final bannerAd = (defaultTargetPlatform != TargetPlatform.linux)
        ? ref.watch(bannerAdProvider(widget.adId))
        : null;
    final isBannerAdReady = (defaultTargetPlatform != TargetPlatform.linux)
        ? ref.watch(adProvider.notifier).isBannerAdReady(widget.adId)
        : false;
    final avatarUnlockService = ref.watch(avatarUnlockProvider);

    const double avatarSize = 120;
    const double dialogCornerRadius = 20;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(top: avatarSize / 2),
            padding: const EdgeInsets.only(
              top: avatarSize / 2 + 16,
              left: 24,
              right: 24,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(dialogCornerRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.avatar.name,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FutureBuilder<AvatarUnlockInfo>(
                  future: _unlockInfoFuture,
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    final isUnlocked = info?.isUnlocked ?? false;
                    final unlockTime = info?.unlockTime;
                    final now = DateTime.now().toUtc();
                    Duration? timeLeft;
                    Duration? timeSinceUnlock;
                    if (isUnlocked && unlockTime != null) {
                      final expiry = unlockTime.add(const Duration(hours: 1));
                      timeLeft = expiry.difference(now);
                      if (timeLeft.isNegative) timeLeft = Duration.zero;
                      timeSinceUnlock = now.difference(unlockTime);
                      if (timeSinceUnlock.isNegative) timeSinceUnlock = Duration.zero;
                    }
                    final canShowRentButton = !isUnlocked || (timeSinceUnlock != null && timeSinceUnlock.inMinutes >= 55);
                    if (isUnlocked && timeLeft != null && !canShowRentButton) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Card(
                          color: Colors.green.withOpacity(0.12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.verified, color: Colors.green, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  'Rented',
                                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Time left: '
                                  '${timeLeft.inMinutes > 0 ? '${timeLeft.inMinutes} min' : '${timeLeft.inSeconds} sec'}',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 8),
                FutureBuilder<AvatarUnlockInfo>(
                  future: _unlockInfoFuture,
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    final isUnlocked = info?.isUnlocked ?? false;
                    final unlockTime = info?.unlockTime;
                    final now = DateTime.now().toUtc();
                    Duration? timeLeft;
                    Duration? timeSinceUnlock;
                    if (isUnlocked && unlockTime != null) {
                      final expiry = unlockTime.add(const Duration(hours: 1));
                      timeLeft = expiry.difference(now);
                      if (timeLeft.isNegative) timeLeft = Duration.zero;
                      timeSinceUnlock = now.difference(unlockTime);
                      if (timeSinceUnlock.isNegative) timeSinceUnlock = Duration.zero;
                    }
                    final canShowRentButton = !isUnlocked || (timeSinceUnlock != null && timeSinceUnlock.inMinutes >= 55);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!(info?.isUnlocked ?? false))
                          Row(
                            children: [
                              if (canShowRentButton && widget.avatar.rewardedAdId != null && widget.avatar.rewardedAdId!.isNotEmpty)
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await avatarUnlockService.showAvatarUnlockAd(
                                        context,
                                        widget.avatar.id,
                                        onAvatarUnlocked: () {
                                          _refreshUnlockInfo();
                                        },
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                                      foregroundColor: theme.colorScheme.secondary,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text('Rent (Ad)'),
                                  ),
                                ),
                              if (canShowRentButton && widget.avatar.rewardedAdId != null && widget.avatar.rewardedAdId!.isNotEmpty)
                                const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      await ref.read(avatarUnlockProvider).buyAvatar(context, widget.avatar.id);
                                      _refreshUnlockInfo();
                                      if (widget.onAvatarBought != null) {
                                        widget.onAvatarBought!();
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(e.toString()), backgroundColor: theme.colorScheme.error),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor,
                                    foregroundColor: theme.colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Text('Buy (${widget.avatar.price} SBD)'),
                                ),
                              ),
                            ],
                          ),
                        // Show Buy button if rented (unlocked and timeLeft > 0), instead of Rented
                        if (isUnlocked && timeLeft != null && timeLeft > Duration.zero)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  await ref.read(avatarUnlockProvider).buyAvatar(context, widget.avatar.id);
                                  _refreshUnlockInfo();
                                  if (widget.onAvatarBought != null) {
                                    widget.onAvatarBought!();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString()), backgroundColor: theme.colorScheme.error),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: Text('Buy (${widget.avatar.price} SBD)'),
                            ),
                          ),
                        if (isUnlocked && (timeLeft == null || timeLeft <= Duration.zero))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ElevatedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.verified, color: Colors.white),
                              label: const Text('Owned'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary.withOpacity(0.9),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        if (canShowRentButton && widget.avatar.rewardedAdId != null && widget.avatar.rewardedAdId!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0, left: 4.0, right: 4.0),
                            child: Text(
                              'Watch an ad to rent this avatar for 1 hour.',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (!canShowRentButton && bannerAd != null) ...[
                          if (!isBannerAdReady) ...[
                            FutureBuilder<void>(
                              future: Future(() async {
                                if (bannerAd.responseInfo == null) await bannerAd.load();
                              }),
                              builder: (context, snapshot) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 28.0),
                                  child: SizedBox(
                                    width: bannerAd.size.width.toDouble(),
                                    height: bannerAd.size.height.toDouble(),
                                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  ),
                                );
                              },
                            ),
                          ] else ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 28.0),
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: SizedBox(
                                  width: bannerAd.size.width.toDouble(),
                                  height: bannerAd.size.height.toDouble(),
                                  child: AdWidget(ad: bannerAd),
                                ),
                              ),
                            ),
                          ]
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: AvatarDisplay(
                avatar: widget.avatar,
                size: avatarSize,
              ),
            ),
          ),
          Positioned(
            top: (avatarSize / 2) + 5,
            right: 5,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(Icons.close, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BannerDetailDialog extends ConsumerStatefulWidget {
  final ProfileBanner banner;
  final String adId;

  const BannerDetailDialog({
    Key? key,
    required this.banner,
    required this.adId,
  }) : super(key: key);

  @override
  _BannerDetailDialogState createState() => _BannerDetailDialogState();
}

class _BannerDetailDialogState extends ConsumerState<BannerDetailDialog> {
  late Future<BannerUnlockInfo> _unlockInfoFuture;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _unlockInfoFuture = ref.read(bannerUnlockProvider).getBannerUnlockInfo(widget.banner.id);
    _loadBannerAd();
  }

  void _loadBannerAd() {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.linux) {
      return;
    }
    _bannerAd = BannerAd(
      adUnitId: AdUnitIds.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _refreshUnlockInfo() {
    setState(() {
      _unlockInfoFuture = ref.read(bannerUnlockProvider).getBannerUnlockInfo(widget.banner.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      backgroundColor: theme.cardColor,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: ProfileBannerDisplay(
                    banner: widget.banner,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black.withOpacity(0.5),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      splashRadius: 20,
                      tooltip: 'Close',
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.banner.name ?? 'Banner',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.banner.description != null && widget.banner.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.banner.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  FutureBuilder<BannerUnlockInfo>(
                    future: _unlockInfoFuture,
                    builder: (context, snapshot) {
                      final isUnlocked = snapshot.data?.isUnlocked ?? false;
                      if (isUnlocked) {
                        return const SizedBox.shrink();
                      }
                      return Column();
                    },
                  ),
                  FutureBuilder<BannerUnlockInfo>(
                    future: _unlockInfoFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final info = snapshot.data;
                      final isUnlocked = info?.isUnlocked ?? false;
                      final unlockTime = info?.unlockTime;
                      final now = DateTime.now().toUtc();
                      Duration? timeLeft;

                      if (isUnlocked && unlockTime != null) {
                        final expiry = unlockTime.add(const Duration(hours: 1));
                        timeLeft = expiry.difference(now);
                        if (timeLeft.isNegative) timeLeft = Duration.zero;
                      }

                      if (isUnlocked && timeLeft != null && timeLeft > Duration.zero) {
                        return Card(
                          color: Colors.green.withOpacity(0.12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.verified, color: Colors.green, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  'Rented',
                                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Time left: ${timeLeft.inMinutes > 0 ? '${timeLeft.inMinutes} min' : '${timeLeft.inSeconds} sec'}',
                                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  _buildActionButtons(theme, _isAdLoaded, _bannerAd),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, bool isAdLoaded, BannerAd? bannerAd) {
    final bannerUnlockService = ref.watch(bannerUnlockProvider);
    return FutureBuilder<BannerUnlockInfo>(
      future: _unlockInfoFuture,
      builder: (context, snapshot) {
        final info = snapshot.data;
        final isUnlocked = info?.isUnlocked ?? false;
        final unlockTime = info?.unlockTime;
        final now = DateTime.now().toUtc();
        bool isRented = false;
        if (isUnlocked && unlockTime != null) {
          final expiry = unlockTime.add(const Duration(hours: 1));
          final timeLeft = expiry.difference(now);
          isRented = timeLeft > Duration.zero;
        }
        if (isRented) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart_outlined),
                label: Text('Buy (${widget.banner.price} SBD)', style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  try {
                    await bannerUnlockService.buyBanner(context, widget.banner.id);
                    _refreshUnlockInfo();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: theme.colorScheme.error),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          );
        }
        if (isUnlocked && !isRented) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.verified, color: Colors.white),
              label: const Text('Owned'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          );
        }
        if (isUnlocked) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Owned',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (widget.banner.rewardedAdId != null && widget.banner.rewardedAdId!.isNotEmpty)
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await bannerUnlockService.showBannerUnlockAd(
                      context,
                      widget.banner.id,
                      onBannerUnlocked: _refreshUnlockInfo,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                    foregroundColor: theme.colorScheme.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Rent (Ad)'),
                ),
              ),
            if (widget.banner.rewardedAdId != null && widget.banner.rewardedAdId!.isNotEmpty)
              const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await bannerUnlockService.buyBanner(context, widget.banner.id);
                    _refreshUnlockInfo();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: theme.colorScheme.error),
                      );
                    }
                  }
                },
                label: Text('Buy (${widget.banner.price} SBD)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class BundleDetailDialog extends ConsumerWidget {
  final Bundle bundle;

  const BundleDetailDialog({
    Key? key,
    required this.bundle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    const double imageSize = 120;
    const double dialogCornerRadius = 20;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(top: imageSize / 2),
            padding: const EdgeInsets.only(
              top: imageSize / 2 + 16,
              left: 24,
              right: 24,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(dialogCornerRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  bundle.name,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  bundle.description,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Included Items:',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    itemCount: bundle.includedItems.length,
                    itemBuilder: (context, index) {
                      final itemId = bundle.includedItems[index];
                      String itemName = 'Unknown Item';

                      if (bundle.id.contains('avatars')) {
                        try {
                          final avatar = allAvatars.firstWhere((a) => a.id == itemId);
                          itemName = avatar.name;
                        } catch (e) {}
                      } else if (bundle.id.contains('themes')) {
                        itemName = AppThemes.themeNames[itemId] ??
                            itemId
                                .replaceFirst('emotion_tracker-', '')
                                .split(RegExp(r'(?=[A-Z])'))
                                .map((word) => word.capitalize())
                                .join(' ');
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text('• $itemName'),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Buy feature coming soon!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text('Buy (${bundle.price} SBD)'),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(imageSize / 2),
                child: Image.asset(
                  bundle.image,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            top: (imageSize / 2) + 5,
            right: 5,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Icon(Icons.close, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ThemeDetailDialog extends ConsumerWidget {
  final String themeKey;
  final ThemeData theme;
  final int price;
  final bool isOwned;
  final String? adUnitId;
  final VoidCallback? onThemeUnlocked;
  final VoidCallback? onThemeBought;

  const ThemeDetailDialog({
    Key? key,
    required this.themeKey,
    required this.theme,
    required this.price,
    required this.isOwned,
    this.adUnitId,
    this.onThemeUnlocked,
    this.onThemeBought,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFree = price == 0;
    final Gradient themeGradient = _getThemeGradient(themeKey, theme);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      backgroundColor: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppThemes.themeNames[themeKey] ?? 'Theme',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: themeGradient,
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (isOwned || isFree)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Owned',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              Row(
                children: [
                  if (adUnitId != null && adUnitId!.isNotEmpty) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final themeUnlockService = ref.read(themeUnlockProvider);
                          try {
                            await themeUnlockService.showThemeUnlockAd(
                              context,
                              themeKey,
                              onThemeUnlocked: () {
                                if (onThemeUnlocked != null) onThemeUnlocked!();
                              },
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString()), backgroundColor: theme.colorScheme.error),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                          foregroundColor: theme.colorScheme.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Rent'),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final themeUnlockService = ref.read(themeUnlockProvider);
                        try {
                          await themeUnlockService.buyTheme(context, themeKey);
                          if (onThemeBought != null) {
                            onThemeBought!();
                          }
                          Navigator.of(context).pop();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: theme.colorScheme.error),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text('Buy (${price} SBD)'),
                    ),
                  ),
                ],
              ),
              if (adUnitId != null && adUnitId!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Watch an ad to rent this theme for 1 hour',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Gradient _getThemeGradient(String themeKey, ThemeData fallbackTheme) {
    const gradients = {
      'serenityGreen': LinearGradient(colors: [Color(0xFF43E97B), Color(0xFF38F9D7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      'pacificBlue': LinearGradient(colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      'blushRose': LinearGradient(colors: [Color(0xFFFFAFBD), Color(0xFFFFC3A0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      'cloudGray': LinearGradient(colors: [Color(0xFFbdc3c7), Color(0xFF2c3e50)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      'sunsetPeach': LinearGradient(colors: [Color(0xFFFF9966), Color(0xFFFF5E62)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      'midnightLavender': LinearGradient(colors: [Color(0xFF232526), Color(0xFF414345)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      'crimsonRed': LinearGradient(colors: [Color(0xFFcb2d3e), Color(0xFFef473a)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      'forestGreen': LinearGradient(colors: [Color(0xFF56ab2f), Color(0xFFa8e063)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      'goldenYellow': LinearGradient(colors: [Color(0xFFf7971e), Color(0xFFffd200)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      'deepPurple': LinearGradient(colors: [Color(0xFF8e2de2), Color(0xFF4a00e0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      'royalOrange': LinearGradient(colors: [Color(0xFFf857a6), Color(0xFFFF5858)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    };
    final key = themeKey.replaceAll('Dark', '').replaceAll('Light', '');
    if (gradients.containsKey(themeKey)) return gradients[themeKey]!;
    if (gradients.containsKey(key)) return gradients[key]!;
    return LinearGradient(
      colors: [fallbackTheme.primaryColor, fallbackTheme.colorScheme.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
