import 'package:flutter/material.dart';

/// BannerType for future extensibility (static, animated, etc.)
enum BannerType { static }

class ProfileBanner {
  final String id;
  final BannerType type;
  final String imageAsset;
  final String? name;

  const ProfileBanner({
    required this.id,
    required this.type,
    required this.imageAsset,
    this.name,
  });
}

/// Example banners list (add your assets here)
final List<ProfileBanner> allProfileBanners = [
  const ProfileBanner(
    id: 'default-dark',
    type: BannerType.static,
    imageAsset: 'assets/banners/default/dark.png',
    name: 'Default Dark',
  ),
  const ProfileBanner(
    id: 'default-light',
    type: BannerType.static,
    imageAsset: 'assets/banners/default/light.png',
    name: 'Default Light',
  ),
  const ProfileBanner(
    id: 'emotion_tracker-static-banner-earth-1',
    type: BannerType.static,
    imageAsset: 'assets/banners/earth/earth-1.png',
    name: 'Earth',
    // Add credit as a comment for now:
    // Photo by Keith Misner on Unsplash: https://unsplash.com/photos/brown-wooden-board-h0Vxgz5tyXA
  ),
  // Add more banners as needed
];

ProfileBanner getBannerById(String id) {
  return allProfileBanners.firstWhere((b) => b.id == id, orElse: () => allProfileBanners.first);
}

/// Widget to render a banner with auto-cropping (top/bottom) for landscape images
typedef BannerCrop = double Function(Size imageSize, Size containerSize);

class ProfileBannerDisplay extends StatelessWidget {
  final ProfileBanner banner;
  final double height;
  final BoxFit fit;
  final Alignment alignment;

  const ProfileBannerDisplay({
    Key? key,
    required this.banner,
    this.height = 160,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.topCenter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(0),
        bottomRight: Radius.circular(0),
      ),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Image.asset(
          banner.imageAsset,
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
    );
  }
}
