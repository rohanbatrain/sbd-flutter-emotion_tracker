import 'package:emotion_tracker/widgets/account_button.dart' show AccountButton;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
// app_providers import removed; AccountButton handles auth actions.
import 'package:emotion_tracker/providers/ad_provider.dart';

class SidebarWidget extends ConsumerStatefulWidget {
  final String selectedItem;
  final Function(String) onItemSelected;

  const SidebarWidget({
    super.key,
    required this.selectedItem,
    required this.onItemSelected,
  });

  @override
  ConsumerState<SidebarWidget> createState() => _SidebarWidgetState();
}

class _SidebarWidgetState extends ConsumerState<SidebarWidget> {
  static const String sidebarBannerAdId = 'sidebar_banner';
  AdNotifier? _adNotifier;
  // Local banner ad to avoid reusing a shared BannerAd instance across multiple
  // places in the widget tree which causes "This AdWidget is already in the
  // Widget tree" runtime exceptions. Each Sidebar gets its own BannerAd.
  BannerAd? _localBannerAd;
  bool _localBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    // Only load ads if not running on Linux
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && defaultTargetPlatform != TargetPlatform.linux) {
        _adNotifier = ref.read(adProvider.notifier);
        _adNotifier?.loadBannerAd(sidebarBannerAdId);
        // Create a local BannerAd for the sidebar to avoid sharing the same
        // BannerAd instance from the provider (which may be displayed in
        // multiple places). This local ad is independent and will be
        // disposed with this widget.
        try {
          _localBannerAd = BannerAd(
            adUnitId: AdUnitIds.bannerAdUnitId,
            request: const AdRequest(),
            size: AdSize.banner,
            listener: BannerAdListener(
              onAdLoaded: (ad) {
                if (!mounted) return;
                setState(() {
                  _localBannerAdReady = true;
                });
              },
              onAdFailedToLoad: (ad, error) {
                ad.dispose();
                if (!mounted) return;
                setState(() {
                  _localBannerAdReady = false;
                });
              },
            ),
          );
          _localBannerAd?.load();
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    // Only dispose ads if not running on Linux
    if (defaultTargetPlatform != TargetPlatform.linux) {
      _adNotifier?.disposeBannerAd(sidebarBannerAdId);
      // Dispose local ad if present
      try {
        _localBannerAd?.dispose();
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final isLinux = defaultTargetPlatform == TargetPlatform.linux;

    // We use a local BannerAd for the sidebar to avoid sharing a BannerAd
    // instance across multiple AdWidgets. Fall back to provider state for
    // non-local usages if needed.
    final bannerAd = _localBannerAd;
    final isBannerAdReady = !isLinux ? _localBannerAdReady : false;

    return SafeArea(
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: theme.primaryColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.fromLTRB(24, 40, 24, 24),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.8),
              ),
              child: Column(
                children: [
                  Text(
                    'Emotion Tracker',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: theme.colorScheme.onPrimary.withOpacity(0.3),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    _buildMenuItem(
                      theme: theme,
                      icon: Icons.dashboard_rounded,
                      title: 'Dashboard',
                      value: 'dashboard',
                      isSelected: widget.selectedItem == 'dashboard',
                    ),
                    SizedBox(height: 8),
                    _buildMenuItem(
                      theme: theme,
                      icon: Icons.settings_rounded,
                      title: 'Settings',
                      value: 'settings',
                      isSelected: widget.selectedItem == 'settings',
                    ),
                    SizedBox(height: 8),
                    _buildMenuItem(
                      theme: theme,
                      icon: Icons.shopping_bag_rounded,
                      title: 'Shop',
                      value: 'shop',
                      isSelected: widget.selectedItem == 'shop',
                    ),
                  ],
                ),
              ),
            ),

            // Footer: banner remains visible, but the account/copyright
            // area below the banner is placed on a contrasting card-style
            // panel so it doesn't visually merge with the sidebar primary color.
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Banner Ad (kept visually separate)
                  if (!isLinux && isBannerAdReady && bannerAd != null)
                    Container(
                      margin: EdgeInsets.only(bottom: 12),
                      width: 248, // Sidebar width (280) - padding (32)
                      height: bannerAd.size.height.toDouble(),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: bannerAd.size.width.toDouble(),
                          height: bannerAd.size.height.toDouble(),
                          child: AdWidget(ad: bannerAd),
                        ),
                      ),
                    ),

                  // Panel that contains the Account control only
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Account control (profile switcher + logout)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.0),
                              child: AccountButton(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Copyright separated from the card panel to provide visual separation
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        '© 2024 Emotion Tracker',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary.withOpacity(0.85),
                        ),
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

  Widget _buildMenuItem({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String value,
    required bool isSelected,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? theme.colorScheme.onPrimary.withOpacity(0.2)
            : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => widget.onItemSelected(value),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: theme.colorScheme.onPrimary, size: 22),
                SizedBox(width: 16),
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Logout is handled by the AccountButton/ProfileSwitcherSheet now.
}
