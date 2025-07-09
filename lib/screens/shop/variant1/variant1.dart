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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // Updated to 5 tabs
    // Preload the ad for the dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && defaultTargetPlatform != TargetPlatform.linux) {
        ref.read(adProvider.notifier).loadBannerAd(avatarDetailBannerAdId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    // We are not disposing the ad here anymore to keep it available.
    // The ad provider will manage its lifecycle.
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

    return ListView.builder(
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
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.7,
              ),
              itemCount: avatars.length,
              itemBuilder: (context, index) {
                final avatar = avatars[index];
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
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                avatar.name,
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '${avatar.price} SBD',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 30,
                                    width: 30,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.add_shopping_cart_outlined),
                                      iconSize: 20,
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
                                ],
                              ),
                            ],
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
    );
  }

  Widget _buildBannersGrid(ThemeData theme) {
    final earthBanners = allProfileBanners.where((b) => b.price > 0 && b.id.contains('earth')).toList();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (earthBanners.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Earth Banners',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
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
              final canShowRentButton = banner.rewardedAdId != null && banner.rewardedAdId!.isNotEmpty;

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
                      builder: (context) => BannerDetailDialog(
                        banner: banner,
                        adId: 'banner_detail_banner_ad',
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    banner.name ?? '',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                            const SizedBox(height: 4),
                            Text(
                              '${banner.price} SBD',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (!canShowRentButton)
                              ElevatedButton.icon(
                                onPressed: () {
                                  // TODO: Implement banner purchase logic
                                },
                                icon: const Icon(Icons.shopping_bag_outlined),
                                label: const Text('Buy'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
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
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildThemesGrid(ThemeData theme) {
    final lightThemes = AppThemes.allThemes.entries
        .where((entry) => entry.value.brightness == Brightness.light)
        .toList();
    final darkThemes = AppThemes.allThemes.entries
        .where((entry) => entry.value.brightness == Brightness.dark)
        .toList();

    return ListView(
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
    );
  }

  Widget _buildBundlesGrid(ThemeData theme) {
    final avatarBundles = bundles.where((b) => b.id.contains('avatars')).toList();
    final themeBundles = bundles.where((b) => b.id.contains('themes')).toList();

    final Map<String, List<Bundle>> bundleCategories = {
      'Avatar Bundles 📦': avatarBundles,
      'Theme Bundles 🎨': themeBundles,
    };

    return ListView.builder(
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
    );
  }

  Widget _buildThemeCard(ThemeData theme, ThemeData appTheme, String themeName, int themePrice, String themeKey) {
    final bool isOwned = themePrice == 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // TODO: Handle theme purchase or selection
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      appTheme.primaryColor.withOpacity(0.1),
                      appTheme.scaffoldBackgroundColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            appTheme.primaryColor,
                            appTheme.colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: appTheme.cardColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      themeName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    isOwned ? 'Owned' : '$themePrice SBD',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isOwned ? Colors.green : theme.colorScheme.primary,
                    ),
                  ),
                  if (!isOwned)
                    SizedBox(
                      height: 30,
                      width: 30,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.add_shopping_cart_outlined),
                        iconSize: 20,
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

  const AvatarDetailDialog({
    Key? key,
    required this.avatar,
    required this.adId,
  }) : super(key: key);

  @override
  _AvatarDetailDialogState createState() => _AvatarDetailDialogState();
}

class _AvatarDetailDialogState extends ConsumerState<AvatarDetailDialog> {
  late Future<AvatarUnlockInfo> _unlockInfoFuture;

  @override
  void initState() {
    super.initState();
    _unlockInfoFuture = ref.read(avatarUnlockProvider).getAvatarUnlockInfo(widget.avatar.id);
  }

  void _refreshUnlockInfo() {
    setState(() {
      _unlockInfoFuture = ref.read(avatarUnlockProvider).getAvatarUnlockInfo(widget.avatar.id);
    });
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
          // Dialog content card
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
                // Avatar name at the top
                Text(
                  widget.avatar.name,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // --- Rental Info Section (improved placement) ---
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
                    // Only show time left if rent button is NOT visible
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
                // --- End Rental Info Section ---
                const SizedBox(height: 8),
                // Action buttons
                FutureBuilder<AvatarUnlockInfo>(
                  future: _unlockInfoFuture,
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    final isUnlocked = info?.isUnlocked ?? false;
                    final unlockTime = info?.unlockTime;
                    final now = DateTime.now().toUtc();
                    Duration? timeSinceUnlock;
                    if (isUnlocked && unlockTime != null) {
                      timeSinceUnlock = now.difference(unlockTime);
                      if (timeSinceUnlock.isNegative) timeSinceUnlock = Duration.zero;
                    }
                    final canShowRentButton = !isUnlocked || (timeSinceUnlock != null && timeSinceUnlock.inMinutes >= 55);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                                child: Text('Buy (${widget.avatar.price} SBD)'),
                              ),
                            ),
                          ],
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
                        // Banner ad only when rented (not when rent button is visible)
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
          // Overlapping Avatar
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
          // Close button
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
            // Banner Preview
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.banner.name ?? 'Banner',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (widget.banner.description != null && widget.banner.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.description_outlined, size: 18, color: theme.hintColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.banner.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Price (conditionally hidden)
                  FutureBuilder<BannerUnlockInfo>(
                    future: _unlockInfoFuture,
                    builder: (context, snapshot) {
                      final isUnlocked = snapshot.data?.isUnlocked ?? false;
                      if (isUnlocked) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          Chip(
                            avatar: Icon(Icons.psychology, color: theme.colorScheme.secondary),
                            label: Text(
                              '${widget.banner.price} SBD',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),

                  // Rental Info Section
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

                  // Action Buttons
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final info = snapshot.data;
        final isUnlocked = info?.isUnlocked ?? false;
        final unlockTime = info?.unlockTime;
        final now = DateTime.now().toUtc();
        Duration? timeSinceUnlock;

        if (isUnlocked && unlockTime != null) {
          timeSinceUnlock = now.difference(unlockTime);
        }

        // Show rent button if not unlocked, or if unlocked more than 55 minutes ago
        final canShowRentButton = widget.banner.rewardedAdId != null &&
            widget.banner.rewardedAdId!.isNotEmpty &&
            (!isUnlocked || (timeSinceUnlock != null && timeSinceUnlock.inMinutes >= 55));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Buy feature coming soon!')),
                );
              },
              icon: const Icon(Icons.shopping_bag_outlined),
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
            if (canShowRentButton) ...[
              const SizedBox(height: 12),
              ElevatedButton(
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
                child: const Text('Rent by Watching an Ad'),
              ),
            ] else if (isUnlocked && isAdLoaded && bannerAd != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: AdWidget(ad: bannerAd),
              ),
            ],
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
                  height: 100, // Adjust height as needed
                  child: ListView.builder(
                    itemCount: bundle.includedItems.length,
                    itemBuilder: (context, index) {
                      return Text('• ${bundle.includedItems[index].split('-').last.capitalize()}');
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
