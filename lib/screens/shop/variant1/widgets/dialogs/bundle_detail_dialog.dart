import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/bundle_unlock_provider.dart';
import 'package:emotion_tracker/providers/custom_bundle.dart';
import 'package:emotion_tracker/providers/custom_avatar.dart';
import '../../utils/string_extensions.dart';

class BundleDetailDialog extends ConsumerWidget {
  final Bundle bundle;
  final bool isOwned;
  final VoidCallback? onBundleBought;

  const BundleDetailDialog({
    Key? key,
    required this.bundle,
    this.isOwned = false,
    this.onBundleBought,
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
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    itemCount: bundle.includedItems.length,
                    itemBuilder: (context, index) {
                      final itemId = bundle.includedItems[index];
                      String itemName = 'Unknown Item';

                      if (bundle.id.contains('avatars')) {
                        try {
                          final avatar = allAvatars.firstWhere(
                            (a) => a.id == itemId,
                          );
                          itemName = avatar.name;
                        } catch (e) {}
                      } else if (bundle.id.contains('themes')) {
                        itemName =
                            AppThemes.themeNames[itemId] ??
                            itemId
                                .replaceFirst('emotion_tracker-', '')
                                .split(RegExp(r'(?=[A-Z])'))
                                .map((word) => word.capitalize())
                                .join(' ');
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text('• $itemName'),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (isOwned)
                  ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.verified, color: Colors.white),
                    label: const Text('Owned'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary.withOpacity(
                        0.9,
                      ),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () async {
                      final bundleUnlockService = ref.read(
                        bundleUnlockProvider,
                      );
                      try {
                        await bundleUnlockService.buyBundle(context, bundle.id);
                        if (onBundleBought != null) onBundleBought!();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: theme.colorScheme.error,
                            ),
                          );
                        }
                      }
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
                  ),
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
                icon: Icon(
                  Icons.close,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
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
