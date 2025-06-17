import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/app_providers.dart';
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

  @override
  void initState() {
    super.initState();
    // Load banner ad using the ad provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _adNotifier = ref.read(adProvider.notifier);
        _adNotifier?.loadBannerAd(sidebarBannerAdId);
      }
    });
  }

  @override
  void dispose() {
    // Dispose the banner ad using stored reference
    _adNotifier?.disposeBannerAd(sidebarBannerAdId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final bannerAd = ref.watch(bannerAdProvider(sidebarBannerAdId));
    final isBannerAdReady = ref.watch(adProvider.notifier).isBannerAdReady(sidebarBannerAdId);

    return Container(
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
          
          // Footer
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Banner Ad
                if (isBannerAdReady && bannerAd != null)
                  Container(
                    margin: EdgeInsets.only(bottom: 16),
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
                // Logout Button
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _handleLogout(context, ref),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.onPrimary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: theme.colorScheme.onPrimary,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Logout',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Copyright
                Text(
                  '© 2024 Emotion Tracker',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                Icon(
                  icon,
                  color: theme.colorScheme.onPrimary,
                  size: 22,
                ),
                SizedBox(width: 16),
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final theme = ref.watch(currentThemeProvider);
        return AlertDialog(
          backgroundColor: theme.cardTheme.color,
          title: Text(
            'Logout',
            style: theme.textTheme.titleLarge,
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: theme.textTheme.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      // Perform logout
      await ref.read(authProvider.notifier).logout();
      
      // Navigate to auth screen
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/auth',
          (route) => false,
        );
      }
    }
  }
}