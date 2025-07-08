import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/widgets/app_scaffold.dart';
import 'package:emotion_tracker/screens/settings/variant1.dart';
import 'package:emotion_tracker/avatars/custom_avatar.dart';
import 'package:emotion_tracker/providers/ad_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:emotion_tracker/providers/avatar_unlock_provider.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
                Tab(text: 'Themes'),
                Tab(text: 'Currency'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAvatarsGrid(theme),
                  _buildThemesGrid(theme),
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
                    child: FittedBox(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AvatarDisplay(
                            avatar: avatar,
                            size: 50,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            avatar.name,
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${avatar.price} SBD',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
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

  Widget _buildThemeCard(ThemeData theme, ThemeData appTheme, String themeName, int themePrice, String themeKey) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // TODO: Handle theme purchase
        },
        child: FittedBox(
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        appTheme.primaryColor,
                        appTheme.colorScheme.secondary,
                        appTheme.scaffoldBackgroundColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Text(
                    themeName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  themePrice == 0 ? 'Owned' : '$themePrice SBD',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: themePrice > 0 ? FontWeight.bold : FontWeight.w600,
                    color: themePrice == 0
                        ? Colors.green
                        : (themePrice > 0
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 4),
                if (themePrice > 0)
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
          ),
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

class AvatarDetailDialog extends ConsumerWidget {
  final Avatar avatar;
  final String adId;

  const AvatarDetailDialog({
    Key? key,
    required this.avatar,
    required this.adId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    final bannerAd = (defaultTargetPlatform != TargetPlatform.linux)
        ? ref.watch(bannerAdProvider(adId))
        : null;
    final isBannerAdReady = (defaultTargetPlatform != TargetPlatform.linux)
        ? ref.watch(adProvider.notifier).isBannerAdReady(adId)
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
                  avatar.name,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // --- Rental Info Section (improved placement) ---
                FutureBuilder<AvatarUnlockInfo>(
                  future: avatarUnlockService.getAvatarUnlockInfo(avatar.id),
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
                  future: avatarUnlockService.getAvatarUnlockInfo(avatar.id),
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
                            if (canShowRentButton && avatar.rewardedAdId != null && avatar.rewardedAdId!.isNotEmpty)
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await avatarUnlockService.showAvatarUnlockAd(
                                      context,
                                      avatar.id,
                                      onAvatarUnlocked: () {
                                        (context as Element).markNeedsBuild();
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
                            if (canShowRentButton && avatar.rewardedAdId != null && avatar.rewardedAdId!.isNotEmpty)
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
                                child: Text('Buy (${avatar.price} SBD)'),
                              ),
                            ),
                          ],
                        ),
                        if (canShowRentButton && avatar.rewardedAdId != null && avatar.rewardedAdId!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0, left: 4.0, right: 4.0),
                            child: Text(
                              'Watch an ad to rent this avatar for 1 hour.',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        // Banner ad only when rented (not when rent button is visible)
                        if (!canShowRentButton && isBannerAdReady && bannerAd != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 28.0),
                            child: FittedBox(
                              child: Container(
                                width: bannerAd.size.width.toDouble(),
                                height: bannerAd.size.height.toDouble(),
                                child: AdWidget(ad: bannerAd),
                              ),
                            ),
                          ),
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
                avatar: avatar,
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
