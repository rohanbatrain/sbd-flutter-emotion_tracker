import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isEncryptionEnabled = false;
  final TextEditingController _encryptionKeyController = TextEditingController();
  bool _isKeyVisible = false; // Tracks whether the encryption key is visible
  bool _isDebugEnabled = false; // Debug mode flag

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load the encryption status, key, and debug mode from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isEncryptionEnabled = prefs.getBool('is_encryption_enabled') ?? false;
      _encryptionKeyController.text = prefs.getString('encryption_key') ?? '';
      _isDebugEnabled = prefs.getBool('is_debug_enabled') ?? false; // Load debug mode setting
    });
  }

  // Handle the switch toggle for encryption
  void _toggleEncryption(bool value) async {
    if (!value) {
      // Show warning dialog before disabling encryption
      bool? shouldDisable = await _showEncryptionWarningDialog();
      if (shouldDisable == true) {
        setState(() {
          _isEncryptionEnabled = value;
        });
        // Save the encryption status to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_encryption_enabled', value);

        // Clear the encryption key if encryption is turned off
        _clearEncryptionKey();
        await prefs.remove('encryption_key'); // Remove the key from SharedPreferences
      }
    } else {
      // If the encryption is being enabled, just toggle it
      setState(() {
        _isEncryptionEnabled = value;
      });
      // Save the encryption status to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_encryption_enabled', value);

      // If encryption is enabled, make sure the key is saved
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
          title: const Text(
            'Important Warning!',
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const <Widget>[
              SizedBox(height: 16),
              Text(
                'By disabling encryption, you are risking permanent loss of access to your encrypted data.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              ),
              SizedBox(height: 12),
              Text(
                'If you do not have the encryption key, you will not be able to decrypt your notes in the future.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              ),
              SizedBox(height: 12),
              Text(
                'Make sure to keep your encryption key in a safe place. If you lose it, there is no way to recover your data.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              ),
              SizedBox(height: 12),
              Text(
                'Disabling encryption will also remove the current encryption key from the app storage.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User cancels the action
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User confirms the action
              },
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    );
  }

  // Clear encryption key when encryption is disabled
  void _clearEncryptionKey() {
    _encryptionKeyController.clear();
  }

  // Save the encryption key to SharedPreferences
  Future<void> _saveEncryptionKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('encryption_key', _encryptionKeyController.text);
  }

  // Generate a random 32-character key
  String _generateRandomKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      32, 
      (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
    ));
  }

  void _toggleDebugMode(bool value) async {
    setState(() {
      _isDebugEnabled = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_debug_enabled', value);
  }

  @override
  void dispose() {
    _encryptionKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            // Section Header: Encryption Settings
            const Text(
              'Encryption Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(thickness: 1, height: 20),

            // Toggle Encryption
            SwitchListTile(
              title: const Text(
                'Enable Encryption',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              value: _isEncryptionEnabled,
              onChanged: (bool value) {
                _toggleEncryption(value);
              },
            ),
            const SizedBox(height: 10),

            // Encryption key input field with the eye icon
            if (_isEncryptionEnabled)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Encryption Key',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _encryptionKeyController,
                    decoration: InputDecoration(
                      hintText: 'Enter a strong encryption key',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
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
                  const SizedBox(height: 10),

                  // Random key generator button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        String randomKey = _generateRandomKey();
                        _encryptionKeyController.text = randomKey;
                        _saveEncryptionKey();
                      },
                      icon: const Icon(Icons.shuffle),
                      label: const Text('Generate Key'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),

            // Section Header: Debug Settings
            const Text(
              'Debug Settings',
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
                  decoration: BoxDecoration(
                    color: Colors.yellow[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(12.0),
                  child: const Text(
                    'Warning: Debug mode is enabled. This can leak sensitive information. Proceed with caution!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Section Header: App Information
            const Text(
              'App Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(thickness: 1, height: 20),

            // Load Offline Version
            ListTile(
              leading: const Icon(Icons.cloud_off, color: Colors.blue),
              title: const Text(
                'Load Offline Version',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('offline_mode', true); // Enable offline mode
                if (!mounted) return;

                // Navigate to the offline home screen
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/offline_home', // Ensure this route is defined in your app
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 10),

            // About App
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.green),
              title: const Text(
                'About App',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('About Emotion Tracker'),
                      content: const Text(
                        'Emotion Tracker is an app designed to help you track and manage your emotions securely. '
                        'Your data is encrypted to ensure privacy and security.',
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
            const SizedBox(height: 10),

            // Contribute on GitHub
            ListTile(
              leading: const Icon(Icons.code, color: Colors.purple),
              title: const Text(
                'Contribute on GitHub',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('GitHub Repository'),
                      content: const Text('https://github.com/rohanbatrain/emotion_tracker'),
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
            const SizedBox(height: 10),

            // Donate (Coming Soon)
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: const Text(
                'Donate (Coming Soon)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Donation feature coming soon!')),
                );
              },
            ),
            const SizedBox(height: 20),

            // Save Button
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('is_encryption_enabled', _isEncryptionEnabled);
                  if (_isEncryptionEnabled) {
                    await prefs.setString('encryption_key', _encryptionKeyController.text);
                  } else {
                    await prefs.remove('encryption_key');
                  }
                  await prefs.setBool('is_debug_enabled', _isDebugEnabled);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings saved successfully!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
