import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeveloperOptionsScreenV1 extends ConsumerStatefulWidget {
  const DeveloperOptionsScreenV1({Key? key}) : super(key: key);

  @override
  ConsumerState<DeveloperOptionsScreenV1> createState() =>
      _DeveloperOptionsScreenV1State();
}

class _DeveloperOptionsScreenV1State
    extends ConsumerState<DeveloperOptionsScreenV1>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;
  Map<String, dynamic> sharedPrefsData = {};
  Map<String, String> secureStorageData = {};
  Map<String, dynamic> inMemoryData = {};

  // All secure storage keys used in the app
  static const List<String> secureKeys = [
    'access_token',
    'token_type',
    'client_side_encryption',
    'client_side_encryption_key',
    'user_role',
    'user_email',
    'user_username',
    'user_first_name',
    'user_last_name',
    'user_avatar_id',
    'user_banner_id',
    'secure_currency_data',
    'currency_backup',
    '2fa_secret',
    '2fa_backup_codes',
    '2fa_backup_codes_regenerated_at',
    'temp_user_password',
    'activeTheme',
    'unlocked_themes',
    'unlocked_banners',
    'unlocked_avatars',
  ];

  // All shared preferences keys used in the app
  static const List<String> sharedPrefsKeys = [
    'issued_at',
    'expires_at',
    'is_verified',
    'server_domain',
    'server_protocol',
    'user_timezone',
    'saved_servers',
    'forgot_password_cooldown_until',
    'currency_last_update',
    'currency_today_earned',
    'currency_lifetime_earned',
    'currency_balance',
    'currency_daily_limit',
    'currency_next_goal',
    'onboarding_complete',
    'last_seen_version',
    'theme_mode',
    'activeTheme',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsMap = <String, dynamic>{};
      for (final key in sharedPrefsKeys) {
        prefsMap[key] = prefs.get(key);
      }

      final secureStorage = ref.read(secureStorageProvider);
      final secureMap = <String, String>{};
      for (final key in secureKeys) {
        final value = await secureStorage.read(key: key);
        if (value != null) secureMap[key] = value;
      }

      final memoryMap = <String, dynamic>{};
      memoryMap['currentTheme'] = ref
          .read(currentThemeProvider)
          .brightness
          .toString();

      setState(() {
        sharedPrefsData = prefsMap;
        secureStorageData = secureMap;
        inMemoryData = memoryMap;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearAllData() {
    final theme = ref.read(currentThemeProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to clear all SharedPreferences and Secure Storage data? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performClearAll();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _performClearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      final secureStorage = ref.read(secureStorageProvider);
      await secureStorage.deleteAll();
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error clearing data: $e')));
      }
    }
  }

  Widget _buildDataItem(
    ThemeData theme,
    String key,
    String value,
    bool isSecure, {
    bool editable = true,
  }) {
    final shouldMask =
        isSecure &&
        (key.contains('token') ||
            key.contains('key') ||
            key.contains('secret') ||
            key.contains('password'));
    final displayValue = shouldMask ? '•' * (value.length.clamp(8, 32)) : value;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    key,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
                if (shouldMask)
                  Icon(Icons.lock, color: theme.colorScheme.error, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SelectableText(
                    displayValue,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (shouldMask)
                      IconButton(
                        icon: const Icon(Icons.visibility, size: 20),
                        tooltip: 'Show',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(key),
                              content: SelectableText(
                                value,
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    _copyToClipboard(value, key);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Copy'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: 'Copy',
                      onPressed: () => _copyToClipboard(value, key),
                    ),
                    if (editable)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        tooltip: 'Edit',
                        onPressed: () async {
                          final newValue = await showDialog<String>(
                            context: context,
                            builder: (context) {
                              final controller = TextEditingController(
                                text: value,
                              );
                              return AlertDialog(
                                title: Text('Edit $key'),
                                content: TextField(
                                  controller: controller,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Value',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, controller.text),
                                    child: const Text('Save'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (newValue != null && newValue != value) {
                            if (isSecure) {
                              final secureStorage = ref.read(
                                secureStorageProvider,
                              );
                              await secureStorage.write(
                                key: key,
                                value: newValue,
                              );
                            } else {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setString(key, newValue);
                            }
                            await _loadData();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$key updated successfully'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent({
    required ThemeData theme,
    required Map<String, String> data,
    required bool isSecure,
    required Future<void> Function() onRefresh,
    bool editable = true,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: data.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Text(
                    'No data found',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: data.length,
              separatorBuilder: (context, i) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final entry = data.entries.elementAt(i);
                return _buildDataItem(
                  theme,
                  entry.key,
                  entry.value,
                  isSecure,
                  editable: editable,
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Developer Data Inspector'),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear All',
            onPressed: _clearAllData,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'about') {
                showAboutDialog(
                  context: context,
                  applicationName: 'Emotion Tracker',
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'about', child: Text('About App')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.secondary,
          tabs: const [
            Tab(icon: Icon(Icons.storage), text: 'SharedPrefs'),
            Tab(icon: Icon(Icons.security), text: 'Secure Storage'),
            Tab(icon: Icon(Icons.memory), text: 'In-Memory'),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(
                  theme: theme,
                  data: sharedPrefsData.map(
                    (k, v) => MapEntry(k, v.toString()),
                  ),
                  isSecure: false,
                  onRefresh: _loadData,
                ),
                _buildTabContent(
                  theme: theme,
                  data: secureStorageData,
                  isSecure: true,
                  onRefresh: _loadData,
                ),
                _buildTabContent(
                  theme: theme,
                  data: inMemoryData.map((k, v) => MapEntry(k, v.toString())),
                  isSecure: false,
                  onRefresh: _loadData,
                  editable: false,
                ),
              ],
            ),
    );
  }
}
