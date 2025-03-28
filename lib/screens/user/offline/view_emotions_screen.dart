import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'view_notes_screen.dart';

class OfflineViewEmotionsScreen extends StatefulWidget {
  const OfflineViewEmotionsScreen({super.key});

  @override
  _OfflineViewEmotionsScreenState createState() =>
      _OfflineViewEmotionsScreenState();
}

class _OfflineViewEmotionsScreenState extends State<OfflineViewEmotionsScreen> {
  List<Map<String, dynamic>> _emotions = [];

  @override
  void initState() {
    super.initState();
    _fetchEmotions();
  }

  Future<void> _fetchEmotions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> emotions = prefs.getStringList('offline_emotions') ?? [];
    final bool isEncryptionEnabled = prefs.getBool('is_encryption_enabled') ?? false;
    final String? encryptionKey = prefs.getString('encryption_key');

    List<Map<String, dynamic>> tempEmotions = [];
    for (String emotion in emotions) {
      try {
        var decodedEmotion = jsonDecode(emotion);
        if (decodedEmotion is Map<String, dynamic>) {
          if (isEncryptionEnabled && encryptionKey != null) {
            decodedEmotion['notes'] = await _decryptNotes(
              List<String>.from(decodedEmotion['notes'] ?? []),
              encryptionKey,
            );
          }
          tempEmotions.add(decodedEmotion);
        }
      } catch (error) {
        print('Error decoding emotion: $error');
      }
    }

    setState(() {
      _emotions = tempEmotions;
    });
  }

  Future<List<String>> _decryptNotes(List<String> encryptedNotes, String encryptionKey) async {
    final key = encrypt.Key.fromUtf8(encryptionKey.padRight(32, ' '));
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    return encryptedNotes.map((encryptedNoteWithIv) {
      try {
        final parts = encryptedNoteWithIv.split(':');
        if (parts.length != 2) throw Exception('Invalid format');
        final encryptedNote = encrypt.Encrypted.fromBase64(parts[0]);
        final iv = encrypt.IV.fromBase64(parts[1]);
        return encrypter.decrypt(encryptedNote, iv: iv);
      } catch (e) {
        print('Error decrypting note: $e');
        return 'Invalid note format';
      }
    }).toList();
  }

  Future<void> _addNewNoteToEmotion(Map<String, dynamic> emotion) async {
    final prefs = await SharedPreferences.getInstance();
    final bool isEncryptionEnabled = prefs.getBool('is_encryption_enabled') ?? false;
    final String? encryptionKey = prefs.getString('encryption_key');

    final TextEditingController _noteController = TextEditingController();

    final newNote = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Note'),
          content: TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Enter your note',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_noteController.text.isNotEmpty) {
                  Navigator.pop(context, _noteController.text);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (newNote != null) {
      String noteToAdd = newNote;

      if (isEncryptionEnabled && encryptionKey != null) {
        noteToAdd = await _encryptNote(newNote, encryptionKey);
      }

      setState(() {
        emotion['notes'].add(noteToAdd);
      });

      // Update SharedPreferences
      final List<String> emotions = prefs.getStringList('offline_emotions') ?? [];
      final index = emotions.indexWhere((e) => jsonDecode(e)['timestamp'] == emotion['timestamp']);
      if (index != -1) {
        emotions[index] = jsonEncode(emotion);
        await prefs.setStringList('offline_emotions', emotions);
      }
    }
  }

  Future<String> _encryptNote(String note, String encryptionKey) async {
    final key = encrypt.Key.fromUtf8(encryptionKey.padRight(32, ' ')); // AES key needs to be 32 bytes
    final iv = encrypt.IV.fromLength(16); // Generate a random IV

    try {
      // Encrypt the note using AES
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final encryptedNote = encrypter.encrypt(note, iv: iv);

      // Combine the encrypted note and IV into a single string
      return '${encryptedNote.base64}:${iv.base64}';
    } catch (e) {
      print('Error encrypting note: $e');
      return 'Invalid note format'; // Fallback for invalid formats
    }
  }

  void _navigateToViewNotesScreen(Map<String, dynamic> emotion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewNotesScreen(emotion: emotion),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Emotions'),
      ),
      body: _emotions.isEmpty
          ? const Center(child: Text('No emotions logged yet.'))
          : ListView.builder(
              itemCount: _emotions.length,
              itemBuilder: (context, index) {
                final emotion = _emotions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: Text(emotion['emotion_felt'] ?? 'No emotion'),
                    subtitle: Text('Intensity: ${emotion['emotion_intensity'] ?? 'N/A'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _addNewNoteToEmotion(emotion),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () => _navigateToViewNotesScreen(emotion),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
