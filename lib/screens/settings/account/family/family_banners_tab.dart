import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/family/family_provider.dart';
import 'package:emotion_tracker/providers/family/family_models.dart' as models;

class FamilyBannersTab extends ConsumerWidget {
  final String familyId;
  final Function(models.ShopItem) onPurchase;

  const FamilyBannersTab({
    super.key,
    required this.familyId,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final shopState = ref.watch(familyShopProvider(familyId));

    final banners = shopState.shopItems
        .where((item) => item.itemType == 'banner')
        .toList();

    if (shopState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (shopState.error != null) {
      return Center(child: Text('Error: ${shopState.error}'));
    }

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(familyShopProvider(familyId).notifier).loadShopItems(),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemCount: banners.length,
        itemBuilder: (context, index) {
          final item = banners[index];
          final isOwned = shopState.ownedItems.any(
            (owned) => owned.itemId == item.itemId,
          );

          return _buildBannerCard(context, theme, item, isOwned);
        },
      ),
    );
  }

  Widget _buildBannerCard(
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
              flex: 2,
              child: Container(
                color: theme.colorScheme.onSurface.withOpacity(0.05),
                child: Icon(
                  _getItemIcon(item.itemType),
                  size: 40,
                  color: theme.primaryColor,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '${item.price} SBD',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
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
                          )
                        else
                          SizedBox(
                            height: 28,
                            child: ElevatedButton(
                              onPressed: () => onPurchase(item),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
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
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getItemIcon(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'banner':
        return Icons.flag;
      default:
        return Icons.shopping_bag;
    }
  }
}
