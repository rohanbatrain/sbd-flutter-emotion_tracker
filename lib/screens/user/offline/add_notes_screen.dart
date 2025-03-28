import 'package:flutter/material.dart';

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
