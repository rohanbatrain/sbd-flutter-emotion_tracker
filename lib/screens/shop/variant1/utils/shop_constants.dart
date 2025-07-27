/// Constants used throughout the shop screen
class ShopConstants {
  // Ad IDs
  static const String avatarDetailBannerAdId = 'avatar_detail_banner';
  static const String bannerDetailBannerAdId = 'banner_detail_banner_ad';

  // Tab configuration
  static const int tabCount = 5;
  static const List<String> tabLabels = [
    'Avatars',
    'Banners',
    'Themes',
    'Bundles',
    'Currency',
  ];

  // Grid configuration
  static const int avatarGridCrossAxisCount = 3;
  static const int bannerGridCrossAxisCount = 2;
  static const int themeGridCrossAxisCount = 2;
  static const int bundleGridCrossAxisCount = 2;

  static const double avatarGridCrossAxisSpacing = 12.0;
  static const double avatarGridMainAxisSpacing = 16.0;
  static const double avatarGridChildAspectRatio = 0.65;

  static const double bannerGridCrossAxisSpacing = 16.0;
  static const double bannerGridMainAxisSpacing = 16.0;
  static const double bannerGridChildAspectRatio = 0.75;

  static const double themeGridCrossAxisSpacing = 16.0;
  static const double themeGridMainAxisSpacing = 16.0;
  static const double themeGridChildAspectRatio = 0.85;

  // UI spacing
  static const double defaultPadding = 16.0;
  static const double cardElevation = 2.0;
  static const double cardBorderRadius = 12.0;

  // Loading delays
  static const Duration themeLoadingDelay = Duration(milliseconds: 400);

  // Cart badge configuration
  static const double cartBadgeMinSize = 14.0;
  static const double cartBadgePosition = 6.0;
  static const double cartBadgeFontSize = 9.0;

  // Snackbar configuration
  static const Duration snackbarDuration = Duration(seconds: 2);

  // Avatar categories
  static const Map<String, String> avatarCategories = {
    'Cats 🐱': 'cats',
    'Dogs 🐶': 'dogs',
    'Pandas 🐼': 'pandas',
    'People 👤': 'people',
    'Animated ✨': 'animated',
  };

  // Banner categories
  static const Map<String, String> bannerCategories = {
    'Earth Banners': 'earth',
  };

  // Theme categories
  static const Map<String, String> themeCategories = {
    'Light Themes': 'light',
    'Dark Themes': 'dark',
  };

  // Error messages
  static const String addToCartError = 'Failed to add item to cart';
  static const String loadingError = 'Failed to load items';
  static const String purchaseError = 'Failed to complete purchase';

  // Success messages
  static const String addToCartSuccess = 'Added to cart!';
  static const String purchaseSuccess = 'Purchase completed successfully!';

  // Status labels
  static const String ownedLabel = 'Owned';
  static const String rentedLabel = 'Rented';
  static const String freeLabel = 'Free';

  // Rental configuration
  static const int rentalDurationHours = 1;
}
