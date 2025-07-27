import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/theme_unlock_provider.dart';
import 'package:emotion_tracker/providers/shop_cart_provider.dart';
import '../../utils/shop_constants.dart';
import '../dialogs/theme_detail_dialog.dart';

/// Widget that displays the themes tab content in the shop screen
class ThemesTab extends ConsumerWidget {
  final bool isLoading;
  final List<String>? ownedThemes;
  final Map<String, ThemeUnlockInfo> themeUnlockInfo;
  final VoidCallback onRefresh;

  const ThemesTab({
    super.key,
    required this.isLoading,
    required this.ownedThemes,
    required this.themeUnlockInfo,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final lightThemes = AppThemes.allThemes.entries
        .where((entry) => entry.value.brightness == Brightness.light)
        .toList();
    final darkThemes = AppThemes.allThemes.entries
        .where((entry) => entry.value.brightness == Brightness.dark)
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: ListView(
        padding: const EdgeInsets.all(ShopConstants.defaultPadding),
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
                crossAxisCount: ShopConstants.themeGridCrossAxisCount,
                crossAxisSpacing: ShopConstants.themeGridCrossAxisSpacing,
                mainAxisSpacing: ShopConstants.themeGridMainAxisSpacing,
                childAspectRatio: ShopConstants.themeGridChildAspectRatio,
              ),
              itemCount: lightThemes.length,
              itemBuilder: (context, index) {
                final themeKey = lightThemes[index].key;
                final appTheme = lightThemes[index].value;
                final themeName = AppThemes.themeNames[themeKey]!;
                final themePrice = AppThemes.themePrices[themeKey]!;

                return _buildThemeCard(
                  context,
                  ref,
                  theme,
                  appTheme,
                  themeName,
                  themePrice,
                  themeKey,
                );
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
                crossAxisCount: ShopConstants.themeGridCrossAxisCount,
                crossAxisSpacing: ShopConstants.themeGridCrossAxisSpacing,
                mainAxisSpacing: ShopConstants.themeGridMainAxisSpacing,
                childAspectRatio: ShopConstants.themeGridChildAspectRatio,
              ),
              itemCount: darkThemes.length,
              itemBuilder: (context, index) {
                final themeKey = darkThemes[index].key;
                final appTheme = darkThemes[index].value;
                final themeName = AppThemes.themeNames[themeKey]!;
                final themePrice = AppThemes.themePrices[themeKey]!;

                return _buildThemeCard(
                  context,
                  ref,
                  theme,
                  appTheme,
                  themeName,
                  themePrice,
                  themeKey,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ThemeData appTheme,
    String themeName,
    int themePrice,
    String themeKey,
  ) {
    // Use cached unlock info instead of making API calls
    final info = themeUnlockInfo[themeKey];
    final isUnlocked =
        (info?.isUnlocked ?? false) ||
        (ownedThemes?.contains(themeKey) ?? false) ||
        themePrice == 0;
    final unlockTime = info?.unlockTime;
    final now = DateTime.now().toUtc();
    Duration? timeLeft;
    bool isOwned = false;
    bool isRented = false;

    if (isUnlocked && unlockTime != null) {
      final expiry = unlockTime.add(
        Duration(hours: ShopConstants.rentalDurationHours),
      );
      timeLeft = expiry.difference(now);
      if (timeLeft.isNegative) timeLeft = Duration.zero;
      isRented = timeLeft > Duration.zero;
    }
    isOwned = isUnlocked && (!isRented);

    return Card(
      elevation: ShopConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShopConstants.cardBorderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            _showThemeDialog(context, themeKey, theme, themePrice, isOwned),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                child: Center(
                  child: Icon(
                    Icons.palette_rounded,
                    size: 48,
                    color: appTheme.primaryColor,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 4.0,
              ),
              child: Column(
                children: [
                  Text(
                    themeName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  if (!isOwned && !isRented) ...[
                    Text(
                      themePrice == 0
                          ? ShopConstants.freeLabel
                          : '$themePrice SBD',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 30,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.add_shopping_cart_outlined),
                        iconSize: 22,
                        color: theme.colorScheme.secondary,
                        tooltip: 'Add to Cart',
                        onPressed: () => _addToCart(context, ref, themeKey),
                      ),
                    ),
                  ],
                  if (isOwned)
                    _buildStatusBadge(
                      theme,
                      ShopConstants.ownedLabel,
                      theme.colorScheme.primary,
                    ),
                  if (isRented)
                    _buildStatusBadge(
                      theme,
                      ShopConstants.rentedLabel,
                      Colors.green,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _showThemeDialog(
    BuildContext context,
    String themeKey,
    ThemeData theme,
    int themePrice,
    bool isOwned,
  ) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => ThemeDetailDialog(
        themeKey: themeKey,
        theme: theme,
        price: themePrice,
        isOwned: isOwned,
        adUnitId: isOwned ? null : AppThemes.themeAdUnitIds[themeKey],
        onThemeUnlocked: isOwned
            ? null
            : () async {
                onRefresh();
              },
        onThemeBought: isOwned
            ? null
            : () async {
                onRefresh();
              },
      ),
    );
  }

  Future<void> _addToCart(
    BuildContext context,
    WidgetRef ref,
    String themeKey,
  ) async {
    final cartService = ref.read(shopCartProvider);
    try {
      await cartService.addToCart(itemId: themeKey, itemType: 'theme');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(ShopConstants.addToCartSuccess),
            duration: ShopConstants.snackbarDuration,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            duration: ShopConstants.snackbarDuration,
          ),
        );
      }
    }
  }
}
