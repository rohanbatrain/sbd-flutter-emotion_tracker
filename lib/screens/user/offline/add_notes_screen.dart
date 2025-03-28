import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class AddNotesScreen extends StatelessWidget {
  final Map<String, dynamic> emotion;

  AddNotesScreen({super.key, required this.emotion});

  final TextEditingController _noteController = TextEditingController();

  Future<String> _encryptNote(String note, String key) async {
    if (key.length < 32) {
      key = key.padRight(32, ' '); // Ensure the key is 32 characters long
    }
    final encrypt.Key aesKey = encrypt.Key.fromUtf8(key);
    final encrypt.IV iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(aesKey));
    final encrypted = encrypter.encrypt(note, iv: iv);
    print('Encrypted Note: ${encrypted.base64}:${iv.base64}'); // Debug log
    return '${encrypted.base64}:${iv.base64}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Notes')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Emotion: ${emotion['emotion_felt']}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Add a Note',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final bool isEncryptionEnabled = prefs.getBool('is_encryption_enabled') ?? false;
                final String? encryptionKey = prefs.getString('encryption_key');

                final notes = List<String>.from(emotion['notes'] ?? []);
                if (_noteController.text.isNotEmpty) {
                  String noteToAdd = _noteController.text;

                  if (isEncryptionEnabled && encryptionKey != null) {
                    noteToAdd = await _encryptNote(noteToAdd, encryptionKey); // Ensure encryption
                  }

                  notes.add(noteToAdd);
                }

                emotion['notes'] = notes; // Update the emotion's notes
                Navigator.pop(context, notes);
              },
              child: Text('Save Note'),
            ),
          ],
        ),
      ),
    );
  }
}
