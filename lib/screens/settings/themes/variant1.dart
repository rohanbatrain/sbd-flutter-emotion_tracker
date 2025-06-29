import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/screens/settings/variant1.dart';
import 'package:emotion_tracker/screens/shop/variant1.dart';
import 'package:emotion_tracker/widgets/custom_app_bar.dart';

class ThemeSelectionScreenV1 extends ConsumerStatefulWidget {
  const ThemeSelectionScreenV1({Key? key}) : super(key: key);

  @override
  ConsumerState<ThemeSelectionScreenV1> createState() => _ThemeSelectionScreenV1State();
}

class _ThemeSelectionScreenV1State extends ConsumerState<ThemeSelectionScreenV1> {
  int toggleState = 0; // 0 = Light, 1 = Dark

  void _onItemSelected(BuildContext context, String item) {
    Navigator.of(context).pop();
    if (item == 'dashboard') {
      Navigator.of(context).pushReplacementNamed('/home/v1');
    } else if (item == 'settings') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SettingsScreenV1()),
      );
    } else if (item == 'shop') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ShopScreenV1()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final currentThemeKey = ref.watch(themeProvider);
    final isLight = toggleState == 0;
    final themeKeys = isLight ? AppThemes.lightThemeKeys : AppThemes.darkThemeKeys;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Theme Selection',
        showHamburger: false,
        showCurrency: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            // Toggle for Light/Dark
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ThemeToggleButton(
                      label: 'Light',
                      selected: isLight,
                      onTap: () => setState(() => toggleState = 0),
                      icon: Icons.wb_sunny_outlined,
                    ),
                    _ThemeToggleButton(
                      label: 'Dark',
                      selected: !isLight,
                      onTap: () => setState(() => toggleState = 1),
                      icon: Icons.nightlight_round,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Choose your preferred theme:',
              style: theme.textTheme.bodyLarge,
            ),
            SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                ),
                itemCount: themeKeys.length,
                itemBuilder: (context, index) {
                  final themeKey = themeKeys[index];
                  final themeName = AppThemes.themeNames[themeKey]!;
                  final themeData = AppThemes.allThemes[themeKey]!;
                  final isSelected = currentThemeKey == themeKey;
                  return GestureDetector(
                    onTap: () {
                      ref.read(themeProvider.notifier).setTheme(themeKey);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? themeData.primaryColor : Colors.grey.withOpacity(0.3),
                          width: isSelected ? 3 : 1,
                        ),
                        color: themeData.primaryColor.withOpacity(0.1),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 40,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: themeData.primaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  themeName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: themeData.primaryColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Icon(
                                Icons.check_circle,
                                color: themeData.primaryColor,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Beautiful toggle button widget
class _ThemeToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  const _ThemeToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.white : Theme.of(context).iconTheme.color),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
