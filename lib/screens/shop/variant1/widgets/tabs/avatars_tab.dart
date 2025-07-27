import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/custom_avatar.dart';
import 'package:emotion_tracker/providers/avatar_unlock_provider.dart';
import 'package:emotion_tracker/providers/shop_cart_provider.dart';
import '../../utils/shop_constants.dart';
import '../dialogs/avatar_detail_dialog.dart';

/// Widget that displays the avatars tab content in the shop screen
class AvatarsTab extends ConsumerWidget {
  final bool isLoading;
  final Set<String> ownedAvatars;
  final Map<String, AvatarUnlockInfo> avatarUnlockInfo;
  final VoidCallback onRefresh;

  const AvatarsTab({
    super.key,
    required this.isLoading,
    required this.ownedAvatars,
    required this.avatarUnlockInfo,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final Map<String, List<Avatar>> avatarCategories = {
      'Cats 🐱': catAvatars,
      'Dogs 🐶': dogAvatars,
      'Pandas 🐼': pandaAvatars,
      'People 👤': peopleAvatars,
      'Animated ✨': animatedAvatars,
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
                  crossAxisCount: ShopConstants.avatarGridCrossAxisCount,
                  crossAxisSpacing: ShopConstants.avatarGridCrossAxisSpacing,
                  mainAxisSpacing: ShopConstants.avatarGridMainAxisSpacing,
                  childAspectRatio: ShopConstants.avatarGridChildAspectRatio,
                ),
                itemCount: avatars.length,
                itemBuilder: (context, index) {
                  final avatar = avatars[index];
                  return _buildAvatarCard(context, ref, theme, avatar);
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvatarCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Avatar avatar,
  ) {
    final isUnlocked = ownedAvatars.contains(avatar.id);
    // Use cached unlock info instead of making API calls
    final info = avatarUnlockInfo[avatar.id];
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
            builder: (context) => AvatarDetailDialog(
              avatar: avatar,
              adId: ShopConstants.avatarDetailBannerAdId,
              onAvatarBought: () async {
                onRefresh();
              },
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                padding: const EdgeInsets.all(8),
                child: AvatarDisplay(avatar: avatar, size: 50),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    avatar.name,
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
                      avatar.price == 0
                          ? ShopConstants.freeLabel
                          : '${avatar.price} SBD',
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
                        onPressed: () => _addToCart(context, ref, avatar),
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
    Avatar avatar,
  ) async {
    final cartService = ref.read(shopCartProvider);
    try {
      await cartService.addToCart(itemId: avatar.id, itemType: 'avatar');
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
