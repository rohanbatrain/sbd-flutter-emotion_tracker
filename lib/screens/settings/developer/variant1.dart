import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/theme_provider.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeveloperOptionsScreenV1 extends ConsumerStatefulWidget {
  const DeveloperOptionsScreenV1({Key? key}) : super(key: key);

  @override
  ConsumerState<DeveloperOptionsScreenV1> createState() => _DeveloperOptionsScreenV1State();
}

class _DeveloperOptionsScreenV1State extends ConsumerState<DeveloperOptionsScreenV1> {
  Map<String, dynamic> sharedPrefsData = {};
  Map<String, String> secureStorageData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      // Load SharedPreferences data
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final Map<String, dynamic> prefsMap = {};
      
      for (String key in keys) {
        final value = prefs.get(key);
        prefsMap[key] = value;
      }
      
      // Load Secure Storage data
      final secureStorage = ref.read(secureStorageProvider);
      final Map<String, String> secureMap = {};
      
      // List of known secure storage keys
      final secureKeys = [
        'access_token',
        'token_type',
        'client_side_encryption',
        'client_side_encryption_key',
        'user_role',
        'user_email',
        'user_username',
      ];
      
      for (String key in secureKeys) {
        final value = await secureStorage.read(key: key);
        if (value != null) {
          secureMap[key] = value;
        }
      }
      
      setState(() {
        sharedPrefsData = prefsMap;
        secureStorageData = secureMap;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearAllData() {
    final theme = ref.read(currentThemeProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Data'),
        content: Text('Are you sure you want to clear all SharedPreferences and Secure Storage data? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performClearAll();
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error),
            child: Text('Clear All'),
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
          SnackBar(content: Text('All data cleared successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: CustomScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Header
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.developer_mode, color: Colors.white, size: 28),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Developer Options',
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'View and manage application storage data',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Actions
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _loadData,
                                  icon: Icon(Icons.refresh),
                                  label: Text('Refresh'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _clearAllData,
                                  icon: Icon(Icons.delete_forever),
                                  label: Text('Clear All'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 32),
                          
                          // Secure Storage Section
                          _buildSection(
                            theme: theme,
                            title: 'Flutter Secure Storage',
                            icon: Icons.security,
                            color: Colors.green,
                            data: secureStorageData,
                            isSecure: true,
                          ),
                          
                          SizedBox(height: 24),
                          
                          // SharedPreferences Section
                          _buildSection(
                            theme: theme,
                            title: 'SharedPreferences',
                            icon: Icons.storage,
                            color: Colors.blue,
                            data: sharedPrefsData.map((k, v) => MapEntry(k, v.toString())),
                            isSecure: false,
                          ),
                          
                          SizedBox(height: 24),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSection({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required Color color,
    required Map<String, String> data,
    required bool isSecure,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Chip(
                  label: Text('${data.length}'),
                  backgroundColor: color,
                  labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Data Items with height constraint
          if (data.isEmpty)
            Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No data found',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.hintColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4, // Max 40% of screen height
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: BouncingScrollPhysics(),
                itemCount: data.length,
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = data.entries.elementAt(index);
                  return _buildDataItem(theme, entry.key, entry.value, isSecure);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDataItem(ThemeData theme, String key, String value, bool isSecure) {
    final shouldMask = isSecure && (key.contains('token') || key.contains('key'));
    final displayValue = shouldMask ? '*' * (value.length.clamp(8, 20)) : value;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key
          Text(
            key,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
          SizedBox(height: 8),
          
          // Value container with action buttons
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Value container
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
                  ),
                  child: SelectableText(
                    displayValue,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              
              // Action buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (shouldMask)
                    IconButton(
                      icon: Icon(Icons.visibility, size: 20),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(key),
                            content: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: MediaQuery.of(context).size.height * 0.6,
                                maxWidth: MediaQuery.of(context).size.width * 0.8,
                              ),
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  value,
                                  style: TextStyle(fontFamily: 'monospace'),
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Close'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  _copyToClipboard(value, key);
                                  Navigator.pop(context);
                                },
                                child: Text('Copy'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  IconButton(
                    icon: Icon(Icons.copy, size: 20),
                    onPressed: () => _copyToClipboard(value, key),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, size: 20),
                    onPressed: () async {
                      final newValue = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          final controller = TextEditingController(text: value);
                          return AlertDialog(
                            title: Text('Edit $key'),
                            content: TextField(
                              controller: controller,
                              maxLines: 3,
                              decoration: InputDecoration(labelText: 'Value'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, controller.text),
                                child: Text('Save'),
                              ),
                            ],
                          );
                        },
                      );
                      if (newValue != null && newValue != value) {
                        if (isSecure) {
                          final secureStorage = ref.read(secureStorageProvider);
                          await secureStorage.write(key: key, value: newValue);
                        } else {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString(key, newValue);
                        }
                        await _loadData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$key updated successfully')),
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
    );
  }
}