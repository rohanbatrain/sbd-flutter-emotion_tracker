import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/widgets/app_scaffold.dart';
import 'themes/variant1.dart';
import 'account/variant1.dart';
import 'developer/variant1.dart';
import 'package:emotion_tracker/screens/shop/variant1.dart';

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
    final isDeveloperAsync = ref.watch(_isDeveloperProvider);

    void _onItemSelected(String item) {
      Navigator.of(context).pop();
      if (item == 'dashboard') {
        Navigator.of(context).pushReplacementNamed('/home/v1');
      } else if (item == 'shop') {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ShopScreenV1()),
        );
      }
    }

    return AppScaffold(
      title: 'Settings',
      selectedItem: 'settings',
      onItemSelected: _onItemSelected,
      body: ListView(
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
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ThemeSelectionScreenV1()),
              ),
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
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AccountSettingsScreenV1()),
              ),
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
                                color: theme.colorScheme.secondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'DEV',
                                style: TextStyle(
                                  color: theme.colorScheme.onSecondary,
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
                                theme.colorScheme.secondary.withOpacity(0.1),
                                theme.colorScheme.tertiary.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
                              child: Icon(Icons.developer_mode, color: theme.colorScheme.secondary, size: 26),
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
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => DeveloperOptionsScreenV1()),
                            ),
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
    );
  }
}