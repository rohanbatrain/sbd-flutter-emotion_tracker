import 'package:emotion_tracker/avatars/custom_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/widgets/app_scaffold.dart';
import 'package:emotion_tracker/screens/settings/variant1.dart';

class ShopScreenV1 extends ConsumerStatefulWidget {
  const ShopScreenV1({Key? key}) : super(key: key);

  @override
  _ShopScreenV1State createState() => _ShopScreenV1State();
}

class _ShopScreenV1State extends ConsumerState<ShopScreenV1> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onItemSelected(String item) {
    Navigator.of(context).pop();
    if (item == 'dashboard') {
      Navigator.of(context).pushReplacementNamed('/home/v1');
    } else if (item == 'settings') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SettingsScreenV1()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final tabTitles = ['Avatars', 'Animated Avatars', 'Themes'];
    return AppScaffold(
      title: 'Shop',
      selectedItem: 'shop',
      onItemSelected: _onItemSelected,
      actions: [
        IconButton(
          icon: Icon(Icons.shopping_cart_outlined),
          tooltip: 'Cart',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Cart feature coming soon!')),
            );
          },
        ),
      ],
      showCurrency: false,
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
            indicatorColor: theme.colorScheme.primary,
            indicator: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Static Avatars'),
              Tab(text: 'Animated Avatars'),
              Tab(text: 'Themes'),
            ],
          ),
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                tabTitles[_tabController.index],
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAvatarsGrid(theme, AvatarType.static),
                _buildAvatarsGrid(theme, AvatarType.animated),
                _buildThemesGrid(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarsGrid(ThemeData theme, AvatarType type) {
    final avatars = allAvatars.where((a) => a.type == type).toList();
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: avatars.length,
      itemBuilder: (context, index) {
        final avatar = avatars[index];
        return Card(
          elevation: 4,
          color: theme.colorScheme.surface,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AvatarDisplay(avatar: avatar, size: 40),
                const SizedBox(height: 8),
                Text(
                  avatar.name, 
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  avatar.price == 0 ? 'Free' : '${avatar.price} SBD',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: avatar.isPremium ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    fontWeight: avatar.isPremium ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemesGrid(ThemeData theme) {
    final themeKeys = AppThemes.allThemes.keys.toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0, // Adjusted for better layout
      ),
      itemCount: themeKeys.length,
      itemBuilder: (context, index) {
        final themeKey = themeKeys[index];
        final appTheme = AppThemes.allThemes[themeKey]!;
        final themeName = AppThemes.themeNames[themeKey]!;
        final themePrice = AppThemes.themePrices[themeKey]!;

        return Card(
          elevation: 4,
          color: theme.colorScheme.surface,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Color preview
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        appTheme.primaryColor,
                        appTheme.colorScheme.secondary,
                        appTheme.scaffoldBackgroundColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  themeName, 
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ), 
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  themePrice == 0 ? 'Free' : '$themePrice SBD',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: themePrice > 0 ? FontWeight.bold : FontWeight.w600,
                    color: themePrice > 0 ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
