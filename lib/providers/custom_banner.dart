import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// BannerType for future extensibility (static, animated, etc.)
enum BannerType { static, animated }

class ProfileBanner {
  final String id;
  final BannerType type;
  final String? imageAsset; // For static
  final String? animationAsset; // For animated
  final String? name;
  final int price; // SBD Tokens
  final String? rewardedAdId;

  const ProfileBanner({
    required this.id,
    required this.type,
    this.imageAsset,
    this.animationAsset,
    this.name,
    this.price = 0,
    this.rewardedAdId,
  }) : assert(
          (type == BannerType.static && imageAsset != null) ||
              (type == BannerType.animated && animationAsset != null),
          'Static banners must have an imageAsset, and animated banners must have an animationAsset.',
        );
}

// --- Banner Data ---
final List<ProfileBanner> defaultBanners = [
  const ProfileBanner(
    id: 'default-dark',
    type: BannerType.static,
    imageAsset: 'assets/banners/default/dark.png',
    name: 'Default Dark',
    price: 0,
  ),
  const ProfileBanner(
    id: 'default-light',
    type: BannerType.static,
    imageAsset: 'assets/banners/default/light.png',
    name: 'Default Light',
    price: 0,
  ),
];

final List<ProfileBanner> earthBanners = [
  const ProfileBanner(
    id: 'emotion_tracker-static-banner-earth-1',
    type: BannerType.static,
    imageAsset: 'assets/banners/earth/earth-1.jpg',
    name: 'Earth 1',
    price: 100,
    rewardedAdId: 'ca-app-pub-2845453539708646/2291871786',
    // Photo by Keith Misner on Unsplash: https://unsplash.com/photos/brown-wooden-board-h0Vxgz5tyXA
  ),
];

// final List<ProfileBanner> animatedBanners = [
//   const ProfileBanner(
//     id: 'emotion_tracker-animated-banner-fireworks',
//     type: BannerType.animated,
//     animationAsset: 'assets/Animation - 1750273841544.json',
//     name: 'Fireworks',
//     price: 2500,
//   ),
// ];

final List<ProfileBanner> allProfileBanners = [
  ...defaultBanners,
  ...earthBanners,
  // ...animatedBanners,
];

final List<String> defaultBannerKeys = defaultBanners.map((e) => e.id).toList();
final List<String> earthBannerKeys = earthBanners.map((e) => e.id).toList();
// final List<String> animatedBannerKeys = animatedBanners.map((e) => e.id).toList();

ProfileBanner getBannerById(String id) {
  return allProfileBanners.firstWhere((b) => b.id == id, orElse: () => allProfileBanners.first);
}

// Example: how to check if a banner is unlocked (by id)
bool isBannerUnlocked(String bannerId, Set<String> unlockedBannerIds) {
  return unlockedBannerIds.contains(bannerId);
}

// Example: get all unlocked banners
List<ProfileBanner> getUnlockedBanners(Set<String> unlockedBannerIds) {
  return allProfileBanners.where((b) => unlockedBannerIds.contains(b.id)).toList();
}

// --- UI Widgets ---

typedef BannerCrop = double Function(Size imageSize, Size containerSize);

class ProfileBannerDisplay extends StatelessWidget {
  final ProfileBanner banner;
  final double height;
  final BoxFit fit;
  final Alignment alignment;
  final double scale;

  const ProfileBannerDisplay({
    Key? key,
    required this.banner,
    this.height = 160,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.scale = 1.2, // Zoom factor for better image display
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (banner.type == BannerType.animated) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: Transform.scale(
          scale: scale,
          child: Transform.translate(
            offset: const Offset(0, -10), // Shift upward slightly
            child: Lottie.asset(
              banner.animationAsset!,
              fit: fit,
            ),
          ),
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Transform.scale(
            scale: scale,
            child: Transform.translate(
              offset: const Offset(0, -10), // Shift upward slightly
              child: Image.asset(
                banner.imageAsset!,
                fit: fit,
                alignment: alignment,
                width: double.infinity,
                height: height,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.black,
                  width: double.infinity,
                  height: height,
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}

class BannerSelectionDialog extends ConsumerWidget {
  final String currentBannerId;
  final Set<String>? unlockedBanners;

  const BannerSelectionDialog({Key? key, required this.currentBannerId, this.unlockedBanners}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    if (unlockedBanners != null) {
      final unlocked = unlockedBanners!;
      final Map<String, List<ProfileBanner>> bannerCategories = {
        'Default': defaultBanners.where((b) => unlocked.contains(b.id)).toList(),
        'Earth': earthBanners.where((b) => unlocked.contains(b.id)).toList(),
        // 'Animated ✨': animatedBanners.where((b) => unlocked.contains(b.id)).toList(),
      };
      final hasAny = bannerCategories.values.any((list) => list.isNotEmpty);
      return AlertDialog(
        title: const Text('Choose your Banner'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
        content: Container(
          width: double.maxFinite,
          child: hasAny
              ? ListView.separated(
                  shrinkWrap: true,
                  itemCount: bannerCategories.keys.length,
                  separatorBuilder: (context, index) => const Divider(height: 30),
                  itemBuilder: (context, index) {
                    final category = bannerCategories.keys.elementAt(index);
                    final banners = bannerCategories[category]!;
                    if (banners.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            category,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 2.5,
                          ),
                          itemCount: banners.length,
                          itemBuilder: (context, bannerIndex) {
                            final banner = banners[bannerIndex];
                            final isSelected = banner.id == currentBannerId;
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop(banner.id);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? theme.primaryColor.withOpacity(0.3) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? theme.primaryColor : Colors.grey.withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                child: Tooltip(
                                  message: banner.name ?? '',
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      ProfileBannerDisplay(banner: banner),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image, size: 64, color: theme.primaryColor),
                      const SizedBox(height: 16),
                      Text('No banners available. Using default.', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      );
    }
    // Fallback: show spinner if unlockedBanners is not provided (should not happen)
    return const Center(child: CircularProgressIndicator());
  }
}
