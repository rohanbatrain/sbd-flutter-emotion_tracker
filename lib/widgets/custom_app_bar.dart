import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showThemeSelector;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.leading,
    this.showThemeSelector = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: Text(title),
      leading: leading,
      actions: [
        if (showThemeSelector)
          IconButton(
            icon: const Icon(Icons.palette),
            onPressed: () => _showThemeSelector(context, ref),
          ),
        ...?actions,
      ],
    );
  }

  void _showThemeSelector(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.read(themeProvider);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ThemeSelector(currentTheme: currentTheme),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ThemeSelector extends ConsumerWidget {
  final String currentTheme;
  
  const ThemeSelector({Key? key, required this.currentTheme}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Theme',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: AppThemes.allThemes.length,
              itemBuilder: (context, index) {
                final themeKey = AppThemes.allThemes.keys.elementAt(index);
                final themeName = AppThemes.themeNames[themeKey] ?? themeKey;
                final themeData = AppThemes.allThemes[themeKey]!;
                final isSelected = themeKey == currentTheme;
                
                // Special handling for light and dark themes
                Color tileColor;
                Color textColor;
                Color iconColor;
                
                if (themeKey == 'lightTheme') {
                  tileColor = Colors.white;
                  textColor = Colors.black87;
                  iconColor = Colors.black87;
                } else if (themeKey == 'darkTheme') {
                  tileColor = Colors.grey[900]!;
                  textColor = Colors.white;
                  iconColor = Colors.white;
                } else {
                  tileColor = themeData.primaryColor;
                  textColor = Colors.white;
                  iconColor = Colors.white;
                }
                
                return GestureDetector(
                  onTap: () {
                    ref.read(themeProvider.notifier).setTheme(themeKey);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: tileColor,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: theme.primaryColor, width: 3)
                          : Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: tileColor == Colors.white 
                              ? Colors.grey.withOpacity(0.3)
                              : tileColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            themeName,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Icon(
                              Icons.check_circle,
                              color: iconColor,
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
    );
  }
}