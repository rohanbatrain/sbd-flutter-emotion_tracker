import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/currency_pack.dart';
import '../../utils/shop_constants.dart';

/// Widget that displays the currency tab content in the shop screen
class CurrencyTab extends ConsumerWidget {
  const CurrencyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(ShopConstants.defaultPadding),
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
            return _buildCurrencyPackCard(context, theme, pack);
          },
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Your purchases support the maintenance of our entire ecosystem of apps, and this currency works across all of them. Thank you for your support! ❤️',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyPackCard(
    BuildContext context,
    ThemeData theme,
    CurrencyPack pack,
  ) {
    return Stack(
      children: [
        Card(
          elevation: ShopConstants.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ShopConstants.cardBorderRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              // TODO: Handle currency pack purchase
              _handleCurrencyPackPurchase(context, pack);
            },
            child: Padding(
              padding: const EdgeInsets.only(
                top: 24.0,
                left: 12.0,
                right: 12.0,
                bottom: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${pack.coins} Coins',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (pack.bonus > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '+ ${pack.bonus} Bonus',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        pack.description,
                        style: theme.textTheme.bodySmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
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
                color: pack.tag.contains('Best Value')
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(ShopConstants.cardBorderRadius),
                  bottomLeft: Radius.circular(ShopConstants.cardBorderRadius),
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
  }

  void _handleCurrencyPackPurchase(BuildContext context, CurrencyPack pack) {
    // TODO: Implement currency pack purchase logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Currency pack purchase for ${pack.name} not yet implemented',
        ),
        duration: ShopConstants.snackbarDuration,
      ),
    );
  }
}
