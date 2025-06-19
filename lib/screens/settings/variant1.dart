import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'themes/variant1.dart';

final _showThemesProvider = StateProvider<bool>((ref) => false);

class SettingsScreenV1 extends ConsumerWidget {
  const SettingsScreenV1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    final showThemes = ref.watch(_showThemesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(showThemes ? 'Theme Selection' : 'Settings'),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
        leading: showThemes
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => ref.read(_showThemesProvider.notifier).state = false,
              )
            : null,
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 400),
        child: showThemes
            ? ThemeSelectionScreenV1(key: ValueKey('themes'))
            : ListView(
                key: ValueKey('main'),
                padding: EdgeInsets.all(16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, top: 20, bottom: 10),
                    child: Text(
                      'Appearance',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                        letterSpacing: 0.8,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: theme.primaryColor.withOpacity(0.13),
                        child: Icon(Icons.color_lens, color: theme.primaryColor, size: 26),
                      ),
                      title: Text('Themes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 18)),
                      trailing: Icon(Icons.arrow_forward_ios, size: 20, color: theme.hintColor),
                      onTap: () => ref.read(_showThemesProvider.notifier).state = true,
                    ),
                  ),
                  SizedBox(height: 28),
                  // Add more settings here as needed
                ],
              ),
      ),
    );
  }
}