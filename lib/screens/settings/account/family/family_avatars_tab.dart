import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/family/family_provider.dart';
import 'package:emotion_tracker/providers/family/family_models.dart' as models;

class FamilyAvatarsTab extends ConsumerWidget {
  final String familyId;
  final Function(models.ShopItem) onPurchase;

  const FamilyAvatarsTab({
    super.key,
    required this.familyId,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final shopState = ref.watch(familyShopProvider(familyId));

    final Map<String, List<models.ShopItem>> avatarCategories = {
      'Cats 🐱': [],
      'Dogs 🐶': [],
      'Pandas 🐼': [],
      'People 👤': [],
      'Animated ✨': [],
    };

    // Categorize avatars based on item ID patterns
    for (final item in shopState.shopItems.where(
      (item) => item.itemType == 'avatar',
    )) {
      final itemId = item.itemId.toLowerCase();
      if (itemId.contains('cat')) {
        avatarCategories['Cats 🐱']!.add(item);
      } else if (itemId.contains('dog')) {
        avatarCategories['Dogs 🐶']!.add(item);
      } else if (itemId.contains('panda')) {
        avatarCategories['Pandas 🐼']!.add(item);
      } else if (itemId.contains('person')) {
        avatarCategories['People 👤']!.add(item);
      } else if (itemId.contains('animated') ||
          item.metadata?['avatar_type'] == 'AvatarType.animated') {
        avatarCategories['Animated ✨']!.add(item);
      }
    }

    if (shopState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (shopState.error != null) {
      return Center(child: Text('Error: ${shopState.error}'));
    }

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(familyShopProvider(familyId).notifier).loadShopItems(),
      child: CustomScrollView(
        slivers: [
          // Build each category as a SliverToBoxAdapter with GridView
          ...avatarCategories.entries.map((entry) {
            final category = entry.key;
            final avatars = entry.value;

            if (avatars.isEmpty)
              return const SliverToBoxAdapter(child: SizedBox.shrink());

            return SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Text(
                      category,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: avatars.length,
                    itemBuilder: (context, index) {
                      final item = avatars[index];
                      final isOwned = shopState.ownedItems.any(
                        (owned) => owned.itemId == item.itemId,
                      );

                      return _buildAvatarCard(context, theme, item, isOwned);
                    },
                  ),
                  const SizedBox(height: 8), // Small spacing between categories
                ],
              ),
            );
          }),
          // Add bottom padding to prevent overflow
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _buildAvatarCard(
    BuildContext context,
    ThemeData theme,
    models.ShopItem item,
    bool isOwned,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isOwned ? null : () => onPurchase(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: theme.colorScheme.onSurface.withOpacity(0.05),
                child: Icon(
                  _getItemIcon(item.itemType),
                  size: 50,
                  color: theme.primaryColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  if (!isOwned) ...[
                    Text(
                      '${item.price} SBD',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () => onPurchase(item),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Buy',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                  if (isOwned)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.9),
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

  IconData _getItemIcon(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'avatar':
        return Icons.person;
      default:
        return Icons.shopping_bag;
    }
  }
}
