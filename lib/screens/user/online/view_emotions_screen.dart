import 'package:flutter/material.dart';
import 'emotion_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ViewEmotionsScreen extends StatefulWidget {
  const ViewEmotionsScreen({super.key});

  @override
  _ViewEmotionsScreenState createState() => _ViewEmotionsScreenState();
}

class _ViewEmotionsScreenState extends State<ViewEmotionsScreen> {
  final EmotionService _emotionService = EmotionService();
  List<Map<String, dynamic>> _emotions = [];

  @override
  void initState() {
    super.initState();
    _fetchEmotions();
  }

  void _fetchEmotions() async {
    final prefs = await SharedPreferences.getInstance();
    final backendUrl = prefs.getString('backend_url') ?? '';
    final authToken = prefs.getString('auth_token') ?? '';

    if (backendUrl.isNotEmpty && authToken.isNotEmpty) {
      final emotions = await _emotionService.fetchEmotions(backendUrl, authToken);

      // Check if the widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _emotions = emotions.reversed.toList();  // Reverse to show the latest first
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('View Emotions')),
      body: _emotions.isEmpty
          ? Center(child: Text('No emotions logged yet.'))
          : ListView.builder(
              itemCount: _emotions.length,
              itemBuilder: (context, index) {
                final emotion = _emotions[index];
                return Card(
                  child: ListTile(
                    title: Text(emotion['emotion_felt']),
                    subtitle: Text('Intensity: ${emotion['emotion_intensity']}'),
                    onTap: () {
                      // Navigate to a new screen with emotion details
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewEmotionDetailsScreen(
                            emotion: emotion,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class ViewEmotionDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> emotion;

  const ViewEmotionDetailsScreen({super.key, required this.emotion});

  @override
  State<ViewEmotionDetailsScreen> createState() => _ViewEmotionDetailsScreenState();
}

class _ViewEmotionDetailsScreenState extends State<ViewEmotionDetailsScreen> {
  List<String> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    final dynamic noteData = widget.emotion['note_ids'];
    final List<String> noteIds = noteData is List
        ? noteData.map((e) => e.toString()).toList()
        : (noteData != null ? [noteData.toString()] : []);

    List<String> fetchedNotes = [];
    final prefs = await SharedPreferences.getInstance();
    final backendUrl = prefs.getString('backend_url') ?? '';
    final authToken = prefs.getString('auth_token') ?? '';

    for (String id in noteIds) {
      final url = Uri.parse('$backendUrl/user/v1/notes/get/$id');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final noteContent = response.body; // Assuming the response body contains the note content as plain text or JSON
        fetchedNotes.add(noteContent);
      } else {
        fetchedNotes.add('Error fetching note for ID: $id');
      }
    }

    if (mounted) {
      setState(() {
        _notes = fetchedNotes;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String emotionFelt = widget.emotion['emotion_felt'] ?? 'Unknown';
    final int intensity = widget.emotion['emotion_intensity'] ?? 'Unknown';
    final String date = widget.emotion['timestamp'] ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: Text('Emotion Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView( // Wrap the content in a SingleChildScrollView
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
                      'Date: $date',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    SizedBox(height: 16),
                    if (_notes.isNotEmpty) ...[
                      Text(
                        'Notes:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _notes.length,
                        itemBuilder: (context, index) {
                          return _AnimatedNoteCard(note: _notes[index]);
                        },
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _AnimatedNoteCard extends StatefulWidget {
  final String note;

  const _AnimatedNoteCard({required this.note});

  @override
  State<_AnimatedNoteCard> createState() => _AnimatedNoteCardState();
}

class _AnimatedNoteCardState extends State<_AnimatedNoteCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Parse the JSON and extract the "content" key
    String content;
    try {
      final Map<String, dynamic> noteJson = widget.note.isNotEmpty
          ? Map<String, dynamic>.from(jsonDecode(widget.note))
          : {};
      content = noteJson['content'] ?? 'No content available';
    } catch (e) {
      content = 'Invalid note format';
    }

    return InkWell(
      onTap: () {
        // Handle card tap if needed
      },
      onHover: (hovering) {
        setState(() {
          _isHovered = hovering;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: _isHovered
              ? colorScheme.primary.withOpacity(0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.5),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.2),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
