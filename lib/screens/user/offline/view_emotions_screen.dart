import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class OfflineViewEmotionsScreen extends StatefulWidget {
  const OfflineViewEmotionsScreen({super.key});

  @override
  _OfflineViewEmotionsScreenState createState() =>
      _OfflineViewEmotionsScreenState();
}

class _OfflineViewEmotionsScreenState extends State<OfflineViewEmotionsScreen> {
  List<Map<String, dynamic>> _emotions = []; // List to hold emotions data
  String _selectedView = 'Grid View'; // Default view
  int _currentPage = 0; // Track the current page in the carousel

  @override
  void initState() {
    super.initState();
    _fetchEmotions();
  }

  // Fetch the emotions from SharedPreferences
  Future<void> _fetchEmotions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> emotions = prefs.getStringList('offline_emotions') ?? [];

    // Decode the emotions and store them in _emotions list
    List<Map<String, dynamic>> tempEmotions = [];

    for (String emotion in emotions) {
      try {
        // Attempt to decode the emotion
        var decodedEmotion = jsonDecode(emotion);

        // Check if the decoded data is a Map<String, dynamic>
        if (decodedEmotion is Map<String, dynamic>) {
          // Check if encryption is enabled and if there's encrypted data
          bool isEncryptionEnabled = prefs.getBool('is_encryption_enabled') ?? false;
          String? encryptionKey = prefs.getString('encryption_key');

          if (isEncryptionEnabled && encryptionKey != null) {
            // Check if there's an encrypted note
            List<String>? encryptedNotesWithIv = List<String>.from(decodedEmotion['notes'] ?? []);

            if (encryptedNotesWithIv.isNotEmpty) {
              // Decrypt the notes if encryption is enabled
              List<String> decryptedNotes = [];
              for (String encryptedNoteWithIv in encryptedNotesWithIv) {
                String decryptedNote = await _decryptNote(encryptedNoteWithIv, encryptionKey);
                decryptedNotes.add(decryptedNote); // Replace encrypted notes with decrypted ones
              }
              decodedEmotion['notes'] = decryptedNotes;
            }
          }

          tempEmotions.add(decodedEmotion);
        }
      } catch (error) {
        // Handle the error if decoding fails
        print('Error decoding emotion: $error');
      }
    }

    setState(() {
      _emotions = tempEmotions;
    });
  }

  // Decrypt the note value using stored IV
  Future<String> _decryptNote(String encryptedNoteWithIv, String encryptionKey) async {
    final key = encrypt.Key.fromUtf8(encryptionKey.padRight(32, ' ')); // AES key needs to be 32 bytes

    try {
      // Split the encrypted note and IV
      final parts = encryptedNoteWithIv.split(':');
      if (parts.length != 2) throw Exception('Invalid encrypted note format');

      final encryptedNote = encrypt.Encrypted.fromBase64(parts[0]); // Decode the encrypted note
      final iv = encrypt.IV.fromBase64(parts[1]); // Decode the base64 IV

      // Decrypt the note using AES
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      return encrypter.decrypt(encryptedNote, iv: iv);
    } catch (e) {
      print('Error decrypting note: $e');
      return 'Invalid note format'; // Fallback for invalid formats
    }
  }

  void _navigateToAddNotesScreen(Map<String, dynamic> emotion) async {
    final updatedNotes = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddNotesScreen(emotion: emotion),
      ),
    );

    if (updatedNotes != null) {
      setState(() {
        emotion['notes'] = updatedNotes; // Update the notes array
      });

      // Save the updated emotion back to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final List<String> emotions = prefs.getStringList('offline_emotions') ?? [];
      final index = _emotions.indexOf(emotion);
      if (index != -1) {
        emotions[index] = jsonEncode(emotion);
        await prefs.setStringList('offline_emotions', emotions);
      }
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

  Widget _buildNotesView(List<String> notes) {
    switch (_selectedView) {
      case 'List View':
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: _AnimatedNoteCard(note: notes[index]),
            );
          },
        );
      case 'Carousel View':
        return Column(
          children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: notes.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _AnimatedNoteCard(note: notes[index]),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                notes.length,
                (index) => AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 4.0),
                  width: _currentPage == index ? 12.0 : 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ),
            ),
          ],
        );
      case 'Horizontal List View':
        return SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: notes.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _AnimatedNoteCard(note: notes[index]),
              );
            },
          ),
        );
      case 'Staggered Grid View':
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            notes.length,
            (index) {
              return SizedBox(
                width: (index % 3 == 0) ? 150 : 100, // Staggered sizes
                child: _AnimatedNoteCard(note: notes[index]),
              );
            },
          ),
        );
      case 'Grid View':
      default:
        return GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            return _AnimatedNoteCard(note: notes[index]);
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Emotions'),
        actions: [
          DropdownButton<String>(
            value: _selectedView,
            items: [
              'Grid View',
              'List View',
              'Carousel View',
              'Horizontal List View',
              'Staggered Grid View'
            ]
                .map((view) => DropdownMenuItem(
                      value: view,
                      child: Text(view),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedView = value;
                });
              }
            },
          ),
        ],
      ),
      body: _emotions.isEmpty
          ? Center(child: Text('No emotions logged yet.'))
          : ListView.builder(
              itemCount: _emotions.length,
              itemBuilder: (context, index) {
                final emotion = _emotions[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: Text(emotion['emotion_felt'] ?? 'No emotion'),
                    subtitle: Text('Intensity: ${emotion['emotion_intensity'] ?? 'N/A'}'),
                    trailing: Icon(Icons.arrow_forward),
                    onTap: () => _navigateToViewNotesScreen(emotion),
                  ),
                );
              },
            ),
    );
  }
}

// New screen to add more notes
class AddNotesScreen extends StatelessWidget {
  final Map<String, dynamic> emotion;

  AddNotesScreen({required this.emotion});

  final TextEditingController _noteController = TextEditingController();

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
              onPressed: () {
                final notes = List<String>.from(emotion['notes'] ?? []);
                if (_noteController.text.isNotEmpty) {
                  notes.add(_noteController.text); // Add the new note
                }
                Navigator.pop(context, notes); // Return the updated notes array
              },
              child: Text('Save Note'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedNoteCard extends StatelessWidget {
  final String note;

  const _AnimatedNoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          note,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class ViewNotesScreen extends StatelessWidget {
  final Map<String, dynamic> emotion;

  const ViewNotesScreen({required this.emotion});

  @override
  Widget build(BuildContext context) {
    final notes = List<String>.from(emotion['notes'] ?? []);
    return Scaffold(
      appBar: AppBar(
        title: Text('View Notes'),
      ),
      body: notes.isEmpty
          ? Center(child: Text('No notes available.'))
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: Text(notes[index]),
                  ),
                );
              },
            ),
    );
  }
}
