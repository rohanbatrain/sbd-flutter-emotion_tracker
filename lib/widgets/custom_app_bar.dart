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
                
                return GestureDetector(
                  onTap: () {
                    ref.read(themeProvider.notifier).setTheme(themeKey);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: themeData.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: theme.primaryColor, width: 3)
                          : Border.all(color: Colors.transparent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: themeData.primaryColor.withOpacity(0.3),
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (isSelected)
                          const Positioned(
                            top: 8,
                            right: 8,
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.white,
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