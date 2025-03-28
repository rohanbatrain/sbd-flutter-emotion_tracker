import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart'; // Importing logger for logging instead of print
import 'emotion_service.dart';  // Import EmotionService for handling API calls

class LogEmotionScreen extends StatefulWidget {
  const LogEmotionScreen({super.key});

  @override
  _LogEmotionScreenState createState() => _LogEmotionScreenState();
}

class _LogEmotionScreenState extends State<LogEmotionScreen> {
  final EmotionService _emotionService = EmotionService();
  final TextEditingController _emotionController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  double _intensity = 5.0;
  final logger = Logger();

  void _logEmotion() async {
    final String emotionFelt = _emotionController.text;
    final int emotionIntensity = _intensity.toInt();
    final String noteContent = _noteController.text;

    if (emotionFelt.isEmpty || emotionIntensity == 0 || noteContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill all fields correctly!'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final backendUrl = prefs.getString('backend_url') ?? '';
    final authToken = prefs.getString('auth_token') ?? '';

    if (backendUrl.isNotEmpty && authToken.isNotEmpty) {
      // Generate a unique note ID and prepare the note data
      final String noteId = DateTime.now().millisecondsSinceEpoch.toString();

      await _emotionService.sendEmotionData(
        backendUrl,
        authToken,
        emotionFelt,
        emotionIntensity,
        noteContent, // Changed from noteIds to noteContent
      );

      // Optionally, save the note content locally or send it to the backend
      _emotionController.clear();
      _noteController.clear();
      setState(() {
        _intensity = 5.0;
      });
    } else {
      logger.e('No backend URL or auth token found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Log Emotion')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Emotion Felt Dropdown
            DropdownButtonFormField<String>(
              value: _emotionController.text.isNotEmpty ? _emotionController.text : null,
              decoration: InputDecoration(labelText: 'Select Emotion'),
              items: ['Anxiety', 'Happy', 'Sad', 'Stressed'].map((emotion) {
                return DropdownMenuItem(value: emotion, child: Text(emotion));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _emotionController.text = value ?? '';
                });
              },
            ),
            SizedBox(height: 20),

            // Note TextField
            TextField(
              controller: _noteController,
              decoration: InputDecoration(labelText: 'Note'),
            ),
            SizedBox(height: 20),

            // Intensity Slider
            Text('Intensity: ${_intensity.toInt()}'),
            Slider(
              value: _intensity,
              min: 1.0,
              max: 10.0,
              divisions: 9,
              onChanged: (value) {
                setState(() {
                  _intensity = value;
                });
              },
            ),
            SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              onPressed: _logEmotion,
              child: Text('Log Emotion'),
            ),
          ],
        ),
      ),
    );
  }
}
