import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackendUrlScreen extends StatefulWidget {
  const BackendUrlScreen({super.key});

  @override
  BackendUrlScreenState createState() => BackendUrlScreenState();
}

class BackendUrlScreenState extends State<BackendUrlScreen> {
  final _controller = TextEditingController();
  final String _exampleUrl = 'http://127.0.0.1:5000';

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

  // Load the example URL into the text field
  void _loadExampleUrl() {
    setState(() {
      _controller.text = _exampleUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Backend URL'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Example: http://127.0.0.1:5000',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Note: Do not include the trailing slash ("/").',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Backend URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loadExampleUrl,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Load Example URL'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_controller.text.isNotEmpty) {
                            _saveUrl(_controller.text);
                          }
                        },
                        child: const Text('Save URL'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GestureDetector(
              onTap: _useOffline, // Navigate to offline homepage
              child: const Text(
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
