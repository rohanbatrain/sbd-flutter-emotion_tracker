import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/services.dart';

class ViewNotesScreen extends StatefulWidget {
  final Map<String, dynamic> emotion;

  const ViewNotesScreen({super.key, required this.emotion});

  @override
  _ViewNotesScreenState createState() => _ViewNotesScreenState();
}

class _ViewNotesScreenState extends State<ViewNotesScreen> {
  String _selectedView = 'List View'; // Default view
  List<String> _decryptedNotes = [];

  @override
  void initState() {
    super.initState();
    _decryptNotes();
  }

  Future<void> _decryptNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isEncryptionEnabled = prefs.getBool('is_encryption_enabled') ?? false;
    final String? encryptionKey = prefs.getString('encryption_key');

    if (isEncryptionEnabled && encryptionKey != null) {
      final notes = List<String>.from(widget.emotion['notes'] ?? []);
      final List<String> decryptedNotes = [];

      for (String note in notes) {
        try {
          final parts = note.split(':');
          if (parts.length == 2) {
            final key = encrypt.Key.fromUtf8(encryptionKey.padRight(32, ' '));
            final encrypter = encrypt.Encrypter(encrypt.AES(key));
            final encryptedNote = encrypt.Encrypted.fromBase64(parts[0]);
            final iv = encrypt.IV.fromBase64(parts[1]);
            decryptedNotes.add(encrypter.decrypt(encryptedNote, iv: iv));
          } else {
            decryptedNotes.add(note); // If not encrypted, add as is
          }
        } catch (e) {
          print('Error decrypting note: $e');
          decryptedNotes.add('Invalid note format'); // Fallback for invalid formats
        }
      }

      setState(() {
        _decryptedNotes = decryptedNotes;
      });
    } else {
      setState(() {
        _decryptedNotes = List<String>.from(widget.emotion['notes'] ?? []);
      });
    }
  }

  Widget _buildNotesView(List<String> notes) {
    switch (_selectedView) {
      case 'Grid View':
        return GridView.builder(
          shrinkWrap: true, // Allow the grid to shrink and expand dynamically
          physics: NeverScrollableScrollPhysics(), // Prevent internal scrolling
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0, // Increased spacing for better layout
            mainAxisSpacing: 16.0, // Increased spacing for better layout
            childAspectRatio: 3 / 2, // Adjusted aspect ratio for better card fit
          ),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(8.0), // Added padding around cards
              child: _AnimatedNoteCard(note: notes[index]),
            );
          },
        );
      case 'Carousel View':
        return SizedBox(
          height: 300, // Provide a fixed height
          child: PageView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              return Center(
                child: _AnimatedNoteCard(note: notes[index]),
              );
            },
          ),
        );
      case 'Horizontal List View':
        return SizedBox(
          height: 150, // Provide a fixed height
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: notes.length,
            itemBuilder: (context, index) {
              return Container(
                width: 200,
                margin: EdgeInsets.symmetric(horizontal: 8.0),
                child: _AnimatedNoteCard(note: notes[index]),
              );
            },
          ),
        );
      case 'Staggered Grid View':
        return SizedBox(
          height: 300, // Provide a fixed height
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisSpacing: 8.0,
              crossAxisSpacing: 8.0,
            ),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              return _AnimatedNoteCard(note: notes[index]);
            },
          ),
        );
      case 'List View':
      default:
        return SizedBox(
          height: 300, // Provide a fixed height
          child: ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              return _NoteCardWithCopy(note: notes[index]);
            },
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String emotionFelt = widget.emotion['emotion_felt'] ?? 'Unknown';
    final int intensity = widget.emotion['emotion_intensity'] ?? 0;
    final String timestamp = widget.emotion['timestamp'] ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: Text('Emotion Details'),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emotion Felt: $emotionFelt',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8),
              Text(
                'Intensity: $intensity',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 8),
              Text(
                'Timestamp: $timestamp',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 16),
              if (_decryptedNotes.isNotEmpty) ...[
                Text(
                  'Notes:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 8),
                _buildNotesView(_decryptedNotes),
              ] else
                Center(child: Text('No notes available.')),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          final bool isEncryptionEnabled = prefs.getBool('is_encryption_enabled') ?? false;
          final String? encryptionKey = prefs.getString('encryption_key');

          final TextEditingController noteController = TextEditingController();

          final newNote = await showDialog<String>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Add New Note'),
                content: TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    labelText: 'Enter your note',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (noteController.text.isNotEmpty) {
                        Navigator.pop(context, noteController.text);
                      }
                    },
                    child: Text('Add'),
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
              _decryptedNotes.add(newNote);
              widget.emotion['notes'] = List<String>.from(widget.emotion['notes'] ?? [])..add(noteToAdd);
            });

            // Update SharedPreferences
            final List<String> emotions = prefs.getStringList('offline_emotions') ?? [];
            final index = emotions.indexWhere((e) => jsonDecode(e)['timestamp'] == widget.emotion['timestamp']);
            if (index != -1) {
              emotions[index] = jsonEncode(widget.emotion);
              await prefs.setStringList('offline_emotions', emotions);
            }
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<String> _encryptNote(String note, String key) async {
    final keyObj = encrypt.Key.fromUtf8(key.padRight(32, ' '));
    final encrypter = encrypt.Encrypter(encrypt.AES(keyObj));
    final iv = encrypt.IV.fromLength(16);
    final encryptedNote = encrypter.encrypt(note, iv: iv);
    return '${encryptedNote.base64}:${iv.base64}';
  }
}

class _AnimatedNoteCard extends StatelessWidget {
  final String note;

  const _AnimatedNoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          note,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class _NoteCardWithCopy extends StatelessWidget {
  final String note;

  const _NoteCardWithCopy({required this.note});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        title: Text(note),
        trailing: IconButton(
          icon: const Icon(Icons.copy),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: note));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Note copied to clipboard')),
            );
          },
        ),
      ),
    );
  }
}
