import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class AddNotesScreen extends StatelessWidget {
  final Map<String, dynamic> emotion;

  AddNotesScreen({super.key, required this.emotion});

  final TextEditingController _noteController = TextEditingController();

  Future<String> _encryptNote(String note, String key) async {
    final encrypt.Key aesKey = encrypt.Key.fromUtf8(key.padRight(32, ' '));
    final encrypt.IV iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(aesKey));
    final encrypted = encrypter.encrypt(note, iv: iv);
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
                final notes = List<String>.from(emotion['notes'] ?? []);
                if (_noteController.text.isNotEmpty) {
                  String noteToAdd = _noteController.text;

                  if (isEncryptionEnabled && encryptionKey != null) {
                    noteToAdd = await _encryptNote(noteToAdd, encryptionKey);
                  }

                  notes.add(noteToAdd);
                }
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
