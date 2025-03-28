import 'package:emotion_tracker/screens/user/offline/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Screen'),
        actions: [
          DropdownButton<String>(
            value: _selectedView,
            icon: const Icon(Icons.more_vert),
            elevation: 16,
            style: const TextStyle(color: Colors.black),
            underline: Container(
              height: 2,
              color: Colors.grey,
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
              'Shared Preference', // Removed Offline Emotion from the dropdown
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
      body: _isDebugEnabled
          ? Center(
              child: _selectedView == 'Select View'
                  ? const Text(
                      'Select an option from the dropdown to view debug info.',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    )
                  : _selectedView == 'Shared Preference'
                      ? _buildSharedPreferencesView()
                      : const Text(
                          'Other debug views coming soon...',
                          style:
                              TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Debug mode is disabled. Please enable debug mode in the settings.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to the settings screen where the user can enable debug mode
                        Navigator.push(context,
  MaterialPageRoute(builder: (context) => const OfflineSettingsScreen()),
);

                        
                      },
                      child: const Text('Go to Settings'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Build Shared Preferences View
  Widget _buildSharedPreferencesView() {
    if (_sharedPreferencesData.isEmpty) {
      return const CircularProgressIndicator();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shared Preferences Data:',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: _sharedPreferencesData.entries.map((entry) {
                return entry.key == 'offline_emotion'
                    ? _buildOfflineEmotion(entry.value)
                    : Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: SelectableText(entry.key), // Making the key text copyable
                          subtitle: SelectableText(entry.value.toString()), // Making the value copyable
                        ),
                      );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Build Offline Emotion directly inside Shared Preferences View
  Widget _buildOfflineEmotion(dynamic value) {
    final offlineEmotionData = value as List?;
    if (offlineEmotionData == null || offlineEmotionData.isEmpty) {
      return const ListTile(
        title: Text('Offline Emotion'),
        subtitle: Text('No offline emotion data available'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Offline Emotions:',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            itemCount: offlineEmotionData.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: SelectableText('Emotion ${index + 1}'), // Making the emotion number copyable
                  subtitle: SelectableText(offlineEmotionData[index].toString()), // Making the emotion value copyable
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
