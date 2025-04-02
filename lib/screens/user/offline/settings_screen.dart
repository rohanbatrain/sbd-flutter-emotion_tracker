import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:emotion_tracker/main.dart'; // Import MyApp to access the ValueNotifier
import 'package:emotion_tracker/widgets/buy_me_coffee_button.dart';

class OfflineSettingsScreen extends StatefulWidget {
  const OfflineSettingsScreen({super.key});

  @override
  _OfflineSettingsScreenState createState() => _OfflineSettingsScreenState();
}

class _OfflineSettingsScreenState extends State<OfflineSettingsScreen> {
  bool _isEncryptionEnabled = false;
  final TextEditingController _encryptionKeyController = TextEditingController();
  bool _isKeyVisible = false;

  // Debug mode flag
  bool _isDebugEnabled = false;

  // Dark mode flag
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isEncryptionEnabled = prefs.getBool('is_encryption_enabled') ?? false;
      _encryptionKeyController.text = prefs.getString('encryption_key') ?? '';
      _isDebugEnabled = prefs.getBool('is_debug_enabled') ?? false;
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false; // Load dark mode setting
    });
  }

  // Save dark mode setting
  Future<void> _saveDarkModeSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', value);
  }

  void _toggleEncryption(bool value) async {
    if (!value) {
      bool? shouldDisable = await _showEncryptionWarningDialog();
      if (shouldDisable == true) {
        setState(() {
          _isEncryptionEnabled = value;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_encryption_enabled', value);
        _clearEncryptionKey();
        await prefs.remove('encryption_key');
      }
    } else {
      setState(() {
        _isEncryptionEnabled = value;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_encryption_enabled', value);
      if (_isEncryptionEnabled) {
        _saveEncryptionKey();
      }
    }
  }

  Future<bool?> _showEncryptionWarningDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Important Warning!'),
          content: const Text(
            'Disabling encryption will remove the current encryption key and make your data unencrypted. Proceed with caution. All of the encrypted notes cannot be decrypted and should be deleted, use clear all data after this step.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    );
  }

  void _clearEncryptionKey() {
    _encryptionKeyController.clear();
  }

  Future<void> _saveEncryptionKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('encryption_key', _encryptionKeyController.text);
  }

  String _generateRandomKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      32,
      (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
    ));
  }

  @override
  void dispose() {
    _encryptionKeyController.dispose();
    super.dispose();
  }

  Future<void> _clearAllData() async {
    final prefs = await SharedPreferences.getInstance();

    // List of keys to keep (e.g., 'encryption_key')
    const List<String> keysToKeep = ['encryption_key', 'is_encryption_enabled', 'is_debug_enabled', 'is_dark_mode'];

    // Get all keys stored in SharedPreferences
    final keys = prefs.getKeys();

    // Loop through all keys and remove those that are not in the keysToKeep list
    for (String key in keys) {
      if (!keysToKeep.contains(key)) {
        await prefs.remove(key);
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data cleared successfully, except encryption settings!')),
    );
  }

  Future<void> _showClearDataConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Data Confirmation'),
          content: const Text('Are you sure you want to clear all data? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Clear Data'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _clearAllData();
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleDebugMode(bool value) async {
    setState(() {
      _isDebugEnabled = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_debug_enabled', value);
  }

  void _toggleDarkMode(bool value) async {
    setState(() {
      _isDarkMode = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', value);

    // Notify the app to update the theme
    (context.findAncestorWidgetOfExactType<MyApp>()?.isDarkModeNotifier)?.value = value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Appearance Settings
            const Text(
              'Appearance',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(thickness: 1, height: 20),

            // Dark Mode
            SwitchListTile(
              title: const Text(
                'Enable Dark Mode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              value: _isDarkMode,
              onChanged: (bool value) {
                _toggleDarkMode(value);
              },
            ),
            const SizedBox(height: 24),

            // Application Settings
            const Text(
              'Application',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(thickness: 1, height: 20),

            // Debug Mode
            SwitchListTile(
              title: const Text(
                'Enable Debug Mode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              value: _isDebugEnabled,
              onChanged: (bool value) {
                _toggleDebugMode(value);
              },
            ),
            if (_isDebugEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  color: Colors.yellow[200],
                  padding: const EdgeInsets.all(8.0),
                  child: const Text(
                    'Warning: Debug mode is enabled. This can leak sensitive information. You might have to restart the app in order to see the changes. Proceed with caution!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Toggle Encryption
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: const Text(
                      'Enable Encryption',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    value: _isEncryptionEnabled,
                    onChanged: (bool value) {
                      _toggleEncryption(value);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.blue),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Encryption Info'),
                          content: const Text(
                            'Turning off encryption after enabling it may cause abnormal behavior. '
                            'We recommend not disabling encryption once it is enabled, as edge cases are not yet fully tested.'
                            'If you need to disable it, please clear all data first.'
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Close'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),

            // Encryption key input field
            if (_isEncryptionEnabled)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Enter Encryption Key (max 32 chars):',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _encryptionKeyController,
                    decoration: InputDecoration(
                      hintText: 'Enter a strong encryption key',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isKeyVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isKeyVisible = !_isKeyVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !_isKeyVisible,
                    onChanged: (text) {
                      if (text.length > 32) {
                        _encryptionKeyController.text = text.substring(0, 32);
                        _encryptionKeyController.selection = TextSelection.collapsed(offset: 32);
                      }
                      _saveEncryptionKey();
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      String randomKey = _generateRandomKey();
                      _encryptionKeyController.text = randomKey;
                      _saveEncryptionKey();
                    },
                    icon: const Icon(Icons.shuffle),
                    label: const Text('Generate Random Key'),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Load Online Version
            ListTile(
              title: const Text('Load Online Version'),
              subtitle: const Text('Switch to the online version of the app.'),
              trailing: const Icon(Icons.cloud),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('offline_mode', false); // Disable offline mode
                if (!mounted) return;

                // Restart the app and navigate to the backend URL screen
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/backend_url',
                  (route) => false, // Clear the navigation stack
                );
              },
            ),
            const SizedBox(height: 24),

            // Clear All Data
            ListTile(
              title: const Text('Clear All Data'),
              subtitle: const Text('Remove all stored data from the app.'),
              trailing: const Icon(Icons.delete),
              onTap: _showClearDataConfirmationDialog,
            ),
            
            const SizedBox(height: 24),
            
            // Add a section header for support options
            const Text(
              'Support',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(thickness: 1, height: 20),
            
            const BuyMeCoffeeButton(),
          ],
        ),
      ),
    );
  }
}
