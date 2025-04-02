import 'package:emotion_tracker/screens/user/offline/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  _DebugScreenState createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  bool _isDebugEnabled = false;
  String _selectedView = 'Select View';
  Map<String, dynamic> _sharedPreferencesData = {};

  @override
  void initState() {
    super.initState();
    _loadDebugSettings();
  }

  Future<void> _loadDebugSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDebugEnabled = prefs.getBool('is_debug_enabled') ?? false;
    });
  }

  Future<void> _loadSharedPreferencesData() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> data = {};
    prefs.getKeys().forEach((key) {
      data[key] = prefs.get(key);
    });
    setState(() {
      _sharedPreferencesData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Screen'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: DropdownButton<String>(
              value: _selectedView,
              icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface),
              elevation: 16,
              style: TextStyle(color: theme.colorScheme.onSurface),
              dropdownColor: theme.colorScheme.surface,
              underline: Container(
                height: 2,
                color: theme.colorScheme.primary,
              ),
              onChanged: _isDebugEnabled
                  ? (String? newValue) {
                      setState(() {
                        _selectedView = newValue!;
                        if (_selectedView == 'Shared Preference') {
                          _loadSharedPreferencesData();
                        }
                      });
                    }
                  : null,
              items: <String>[
                'Select View',
                'Shared Preference',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: _isDebugEnabled
          ? _selectedView == 'Select View'
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bug_report,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Debug Mode Active',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select an option from the dropdown to view debug info.',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : _selectedView == 'Shared Preference'
                  ? _buildSharedPreferencesView()
                  : Center(
                      child: Text(
                        'Other debug views coming soon...',
                        style: theme.textTheme.bodyLarge,
                      ),
                    )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Debug Mode Disabled',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please enable debug mode in the settings to access debugging tools.',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OfflineSettingsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Go to Settings'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSharedPreferencesView() {
    final theme = Theme.of(context);

    if (_sharedPreferencesData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.data_object,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Shared Preferences Data',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _sharedPreferencesData.length,
              itemBuilder: (context, index) {
                final entry = _sharedPreferencesData.entries.elementAt(index);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ExpansionTile(
                    title: Text(
                      entry.key,
                      style: theme.textTheme.titleMedium,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(
                              entry.value.toString(),
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(
                                    text: '${entry.key}: ${entry.value}',
                                  ));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Copied to clipboard'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy),
                                label: const Text('Copy'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
