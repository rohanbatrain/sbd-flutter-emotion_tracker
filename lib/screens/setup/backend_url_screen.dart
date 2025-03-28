import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackendUrlScreen extends StatefulWidget {
  const BackendUrlScreen({super.key});

  @override
  BackendUrlScreenState createState() => BackendUrlScreenState();
}

class BackendUrlScreenState extends State<BackendUrlScreen> {
  final _controller = TextEditingController();

  // Save the backend URL to SharedPreferences and navigate to login page
  Future<void> _saveUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('backend_url', url);

    // Check if offline_mode is true and navigate accordingly
    final isOfflineMode = prefs.getBool('offline_mode') ?? false;
    if (isOfflineMode) {
      Navigator.pushReplacementNamed(context, '/offline/home_screen');
    } else if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // Navigate to offline home screen
  Future<void> _useOffline() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline_mode', true); // Store offline mode preference
    Navigator.pushReplacementNamed(context, '/offline/home_screen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enter Backend URL')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(labelText: 'Backend URL'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _saveUrl(_controller.text);
                    }
                  },
                  child: Text('Save URL'),
                ),
              ],
            ),
            GestureDetector(
              onTap: _useOffline,  // Navigate to offline homepage
              child: Text(
                'Use Offline',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline, // Add underline
                  fontSize: 16,
                  fontWeight: FontWeight.w600, // Optional: make it bold for emphasis
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
