import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/custom_banner.dart';
import 'package:emotion_tracker/providers/banner_unlock_provider.dart';
import 'package:emotion_tracker/providers/shop_cart_provider.dart';
import '../../utils/shop_constants.dart';
import '../dialogs/banner_detail_dialog.dart';

/// Widget that displays the banners tab content in the shop screen
class BannersTab extends ConsumerWidget {
  final bool isLoading;
  final Set<String> ownedBanners;
  final Map<String, BannerUnlockInfo> bannerUnlockInfo;
  final VoidCallback onRefresh;

  const BannersTab({
    super.key,
    required this.isLoading,
    required this.ownedBanners,
    required this.bannerUnlockInfo,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final earthBanners = allProfileBanners
        .where((b) => b.price > 0 && b.id.contains('earth'))
        .toList();

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: ListView(
        padding: const EdgeInsets.all(ShopConstants.defaultPadding),
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
                crossAxisCount: ShopConstants.bannerGridCrossAxisCount,
                crossAxisSpacing: ShopConstants.bannerGridCrossAxisSpacing,
                mainAxisSpacing: ShopConstants.bannerGridMainAxisSpacing,
                childAspectRatio: ShopConstants.bannerGridChildAspectRatio,
              ),
              itemCount: earthBanners.length,
              itemBuilder: (context, index) {
                final banner = earthBanners[index];
                return _buildBannerCard(context, ref, theme, banner);
              },
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildBannerCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ProfileBanner banner,
  ) {
    final isUnlocked = ownedBanners.contains(banner.id);
    // Use cached unlock info instead of making API calls
    final info = bannerUnlockInfo[banner.id];
    final isRented =
        (info?.isUnlocked ?? false) &&
        (info?.unlockTime != null) &&
        DateTime.now().toUtc().difference(info!.unlockTime!).inHours <
            ShopConstants.rentalDurationHours;
    final isOwned = isUnlocked && (!isRented);

    return Card(
      elevation: ShopConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShopConstants.cardBorderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            barrierColor: Colors.black.withValues(alpha: 0.5),
            builder: (context) => BannerDetailDialog(
              banner: banner,
              adId: ShopConstants.bannerDetailBannerAdId,
            ),
          ).then((_) => onRefresh());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  if (!isUnlocked) ...[
                    Text(
                      '${banner.price} SBD',
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
                        onPressed: () => _addToCart(context, ref, banner),
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

  Future<void> _addToCart(
    BuildContext context,
    WidgetRef ref,
    ProfileBanner banner,
  ) async {
    final cartService = ref.read(shopCartProvider);
    try {
      await cartService.addToCart(itemId: banner.id, itemType: 'banner');
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
