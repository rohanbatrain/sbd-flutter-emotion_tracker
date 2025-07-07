import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/widgets/app_scaffold.dart';
import 'package:emotion_tracker/screens/settings/variant1.dart';
import 'package:emotion_tracker/avatars/custom_avatar.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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
      body: SafeArea(
        child: Column(
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
                Tab(text: 'Avatars'),
                Tab(text: 'Themes'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAvatarsGrid(theme),
                  _buildThemesGrid(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarsGrid(ThemeData theme) {
    final Map<String, List<Avatar>> avatarCategories = {
      'Cats 🐱': catAvatars,
      'Dogs 🐶': dogAvatars,
      'Pandas 🐼': pandaAvatars,
      'People 👤': peopleAvatars,
      'Animated ✨': animatedAvatars,
    };

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: avatarCategories.length,
      itemBuilder: (context, index) {
        final category = avatarCategories.keys.elementAt(index);
        final avatars = avatarCategories[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                category,
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
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: avatars.length,
              itemBuilder: (context, index) {
                final avatar = avatars[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      // TODO: Handle avatar tap
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AvatarDisplay(
                          avatar: avatar,
                          size: 60,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          avatar.name,
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${avatar.price} SBD',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildThemesGrid(ThemeData theme) {
    final lightThemes = AppThemes.allThemes.entries
        .where((entry) => entry.value.brightness == Brightness.light)
        .toList();
    final darkThemes = AppThemes.allThemes.entries
        .where((entry) => entry.value.brightness == Brightness.dark)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (lightThemes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Light Themes',
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
              childAspectRatio: 1.0,
            ),
            itemCount: lightThemes.length,
            itemBuilder: (context, index) {
              final themeKey = lightThemes[index].key;
              final appTheme = lightThemes[index].value;
              final themeName = AppThemes.themeNames[themeKey]!;
              final themePrice = AppThemes.themePrices[themeKey]!;

              return _buildThemeCard(theme, appTheme, themeName, themePrice);
            },
          ),
          const SizedBox(height: 16),
        ],
        if (darkThemes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Dark Themes',
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
              childAspectRatio: 1.0,
            ),
            itemCount: darkThemes.length,
            itemBuilder: (context, index) {
              final themeKey = darkThemes[index].key;
              final appTheme = darkThemes[index].value;
              final themeName = AppThemes.themeNames[themeKey]!;
              final themePrice = AppThemes.themePrices[themeKey]!;

              return _buildThemeCard(theme, appTheme, themeName, themePrice);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildThemeCard(ThemeData theme, ThemeData appTheme, String themeName, int themePrice) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // TODO: Handle theme tap
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              Flexible(
                child: Text(
                  themeName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
      ),
    );
  }
}
