import 'package:flutter/material.dart';

class ViewNotesScreen extends StatelessWidget {
  final Map<String, dynamic> emotion;

  const ViewNotesScreen({super.key, required this.emotion});

  @override
  Widget build(BuildContext context) {
    final String emotionFelt = emotion['emotion_felt'] ?? 'Unknown';
    final int intensity = emotion['emotion_intensity'] ?? 0;
    final String timestamp = emotion['timestamp'] ?? 'Unknown';
    final List<String> notes = List<String>.from(emotion['notes'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notes for $emotionFelt'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emotion: $emotionFelt',
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
            Text(
              'Notes:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            notes.isEmpty
                ? Text('No notes available.')
                : Expanded(
                    child: ListView.builder(
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 4.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              notes[index],
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
