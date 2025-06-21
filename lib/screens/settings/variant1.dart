import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'themes/variant1.dart';
import 'account/variant1.dart';
import 'developer/variant1.dart';

final _showThemesProvider = StateProvider<bool>((ref) => false);
final _showAccountProvider = StateProvider<bool>((ref) => false);
final _showDeveloperProvider = StateProvider<bool>((ref) => false);

// Provider to check if user has developer role
final _isDeveloperProvider = FutureProvider<bool>((ref) async {
  final secureStorage = ref.read(secureStorageProvider);
  final userRole = await secureStorage.read(key: 'user_role');
  
  // Debug: Print the actual role value
  print('DEBUG: Current user_role in secure storage: "$userRole"');
  print('DEBUG: Is developer? ${userRole == 'developer'}');
  
  return userRole == 'developer';
});

class SettingsScreenV1 extends ConsumerWidget {
  const SettingsScreenV1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    final showThemes = ref.watch(_showThemesProvider);
    final showAccount = ref.watch(_showAccountProvider);
    final showDeveloper = ref.watch(_showDeveloperProvider);
    final isDeveloperAsync = ref.watch(_isDeveloperProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(showThemes
            ? 'Theme Selection'
            : showAccount
                ? 'Account Settings'
                : showDeveloper
                    ? 'Developer Options'
                    : 'Settings'),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
        leading: (showThemes || showAccount || showDeveloper)
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  if (showThemes) {
                    ref.read(_showThemesProvider.notifier).state = false;
                  } else if (showAccount) {
                    ref.read(_showAccountProvider.notifier).state = false;
                  } else if (showDeveloper) {
                    ref.read(_showDeveloperProvider.notifier).state = false;
                  }
                },
              )
            : null,
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 400),
        child: showThemes
            ? ThemeSelectionScreenV1(key: ValueKey('themes'))
            : showAccount
                ? AccountSettingsScreenV1(key: ValueKey('account'))
                : showDeveloper
                    ? DeveloperOptionsScreenV1(key: ValueKey('developer'))
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
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0, top: 10, bottom: 10),
                            child: Text(
                              'Account',
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
                                child: Icon(Icons.person, color: theme.primaryColor, size: 26),
                              ),
                              title: Text('Account', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 18)),
                              trailing: Icon(Icons.arrow_forward_ios, size: 20, color: theme.hintColor),
                              onTap: () => ref.read(_showAccountProvider.notifier).state = true,
                            ),
                          ),
                          
                          // Developer Options (only visible for developers)
                          isDeveloperAsync.when(
                            data: (isDeveloper) => isDeveloper
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 28),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4.0, top: 10, bottom: 10),
                                        child: Row(
                                          children: [
                                            Text(
                                              'Developer',
                                              style: theme.textTheme.titleLarge?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: theme.primaryColor,
                                                letterSpacing: 0.8,
                                                fontSize: 22,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.orange,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                'DEV',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Card(
                                        elevation: 3,
                                        margin: EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(18),
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.orange.withOpacity(0.1),
                                                Colors.red.withOpacity(0.05),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: ListTile(
                                            contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                            leading: CircleAvatar(
                                              radius: 22,
                                              backgroundColor: Colors.orange.withOpacity(0.2),
                                              child: Icon(Icons.developer_mode, color: Colors.orange, size: 26),
                                            ),
                                            title: Text(
                                              'Developer Options',
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 18,
                                              ),
                                            ),
                                            subtitle: Text(
                                              'View storage data & debug tools',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.hintColor,
                                              ),
                                            ),
                                            trailing: Icon(Icons.arrow_forward_ios, size: 20, color: theme.hintColor),
                                            onTap: () => ref.read(_showDeveloperProvider.notifier).state = true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : SizedBox.shrink(),
                            loading: () => SizedBox.shrink(),
                            error: (_, __) => SizedBox.shrink(),
                          ),
                          
                          SizedBox(height: 28),
                          // Add more settings here as needed
                        ],
                      ),
      ),
    );
  }
}