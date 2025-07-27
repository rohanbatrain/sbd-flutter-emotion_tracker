import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/custom_bundle.dart';
import 'package:emotion_tracker/providers/shop_cart_provider.dart';
import '../../utils/shop_constants.dart';
import '../dialogs/bundle_detail_dialog.dart';

/// Widget that displays the bundles tab content in the shop screen
class BundlesTab extends ConsumerWidget {
  final bool isLoading;
  final Set<String> ownedBundles;
  final VoidCallback onRefresh;

  const BundlesTab({
    super.key,
    required this.isLoading,
    required this.ownedBundles,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final avatarBundles = bundles
        .where((b) => b.id.contains('avatars'))
        .toList();
    final themeBundles = bundles.where((b) => b.id.contains('themes')).toList();

    final Map<String, List<Bundle>> bundleCategories = {
      'Avatar Bundles 📦': avatarBundles,
      'Theme Bundles 🎨': themeBundles,
    };

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(ShopConstants.defaultPadding),
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
                  crossAxisCount: ShopConstants.bundleGridCrossAxisCount,
                  crossAxisSpacing: ShopConstants.bannerGridCrossAxisSpacing,
                  mainAxisSpacing: ShopConstants.bannerGridMainAxisSpacing,
                  childAspectRatio:
                      0.74, // Adjusted aspect ratio to resolve overflow
                ),
                itemCount: categoryBundles.length,
                itemBuilder: (context, index) {
                  final bundle = categoryBundles[index];
                  return _buildBundleCard(context, ref, theme, bundle);
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBundleCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Bundle bundle,
  ) {
    final isOwned = ownedBundles.contains(bundle.id);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showBundleDialog(context, bundle, isOwned),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                    theme.colorScheme.secondary.withValues(alpha: 0.1),
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
                              isOwned
                                  ? ShopConstants.ownedLabel
                                  : '${bundle.price} SBD',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isOwned
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.secondary,
                                fontWeight: isOwned
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (!isOwned)
                              IconButton(
                                icon: const Icon(
                                  Icons.add_shopping_cart_outlined,
                                ),
                                iconSize: 22,
                                color: theme.colorScheme.secondary,
                                tooltip: 'Add to Cart',
                                onPressed: () =>
                                    _addToCart(context, ref, bundle),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isOwned)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ShopConstants.ownedLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBundleDialog(
    BuildContext context,
    Bundle bundle,
    bool isOwned,
  ) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => BundleDetailDialog(
        bundle: bundle,
        isOwned: isOwned,
        onBundleBought: () async {
          onRefresh();
        },
      ),
    );
  }

  Future<void> _addToCart(
    BuildContext context,
    WidgetRef ref,
    Bundle bundle,
  ) async {
    final cartService = ref.read(shopCartProvider);
    try {
      await cartService.addToCart(itemId: bundle.id, itemType: 'bundle');
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
