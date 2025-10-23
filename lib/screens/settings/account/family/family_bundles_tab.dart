import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/family/family_provider.dart';
import 'package:emotion_tracker/providers/family/family_models.dart' as models;

class FamilyBundlesTab extends ConsumerWidget {
  final String familyId;
  final Function(models.ShopItem) onPurchase;

  const FamilyBundlesTab({
    super.key,
    required this.familyId,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final shopState = ref.watch(familyShopProvider(familyId));

    final bundles = shopState.shopItems
        .where((item) => item.itemType == 'bundle')
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
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bundles.length,
        itemBuilder: (context, index) {
          final item = bundles[index];
          final isOwned = shopState.ownedItems.any(
            (owned) => owned.itemId == item.itemId,
          );

          return _buildBundleCard(context, theme, item, isOwned);
        },
      ),
    );
  }

  Widget _buildBundleCard(
    BuildContext context,
    ThemeData theme,
    models.ShopItem item,
    bool isOwned,
  ) {
    final includedItems =
        item.metadata?['included_items'] as List<dynamic>? ?? [];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isOwned ? null : () => onPurchase(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getItemIcon(item.itemType),
                      color: theme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${item.price} SBD',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOwned)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Owned',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: () => onPurchase(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Buy Bundle'),
                    ),
                ],
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  item.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
              if (includedItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Includes:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: includedItems.map<Widget>((included) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        included.toString(),
                        style: theme.textTheme.bodySmall,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getItemIcon(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'bundle':
        return Icons.inventory;
      default:
        return Icons.shopping_bag;
    }
  }
}
