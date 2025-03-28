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
  String _selectedFilter = 'Timestamp'; // Default filter

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

      if (mounted) {
        setState(() {
          _emotions = _applyFilter(emotions);
        });
      }
    }
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> emotions) {
    switch (_selectedFilter) {
      case 'Name (A-Z)':
        emotions.sort((a, b) => (a['emotion_felt'] ?? '').compareTo(b['emotion_felt'] ?? ''));
        break;
      case 'Name (Z-A)':
        emotions.sort((a, b) => (b['emotion_felt'] ?? '').compareTo(a['emotion_felt'] ?? ''));
        break;
      case 'Intensity (High to Low)':
        emotions.sort((a, b) => (b['emotion_intensity'] ?? 0).compareTo(a['emotion_intensity'] ?? 0));
        break;
      case 'Intensity (Low to High)':
        emotions.sort((a, b) => (a['emotion_intensity'] ?? 0).compareTo(b['emotion_intensity'] ?? 0));
        break;
      case 'Timestamp':
      default:
        emotions.sort((a, b) => (b['timestamp'] ?? '').compareTo(a['timestamp'] ?? ''));
        break;
    }
    return emotions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Emotions'),
        actions: [
          DropdownButton<String>(
            value: _selectedFilter,
            items: [
              'Timestamp',
              'Name (A-Z)',
              'Name (Z-A)',
              'Intensity (High to Low)',
              'Intensity (Low to High)'
            ]
                .map((filter) => DropdownMenuItem(
                      value: filter,
                      child: Text(filter),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedFilter = value;
                  _emotions = _applyFilter(_emotions); // Reapply filter
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
                  child: ListTile(
                    title: Text(emotion['emotion_felt']),
                    subtitle: Text('Intensity: ${emotion['emotion_intensity']}'),
                    onTap: () async {
                      final refresh = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewEmotionDetailsScreen(
                            emotion: emotion,
                          ),
                        ),
                      );
                      if (refresh == true) {
                        _fetchEmotions(); // Refresh emotions when returning from the details screen
                      }
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
  String _selectedView = 'Grid View'; // Default view
  int _currentPage = 0; // Track the current page in the carousel

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
      final url = Uri.parse('$backendUrl/user/v1/notes/basic/get/$id');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final noteContent = response.body;
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

  Future<void> _addNewNote() async {
    final TextEditingController noteController = TextEditingController();
    final prefs = await SharedPreferences.getInstance();
    final backendUrl = prefs.getString('backend_url') ?? '';
    final authToken = prefs.getString('auth_token') ?? '';
    final emotionId = widget.emotion['_id'];

    if (emotionId == null || backendUrl.isEmpty || authToken.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Text('Add New Note'),
              Spacer(),
              IconButton(
                icon: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Notice'),
                      content: Text(
                        'New notes will appear after reloading the "View Emotions" screen. This reduces backend costs by minimizing GET requests.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          content: TextField(
            controller: noteController,
            decoration: InputDecoration(
              hintText: 'Enter your note here',
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
              onPressed: () async {
                final noteContent = noteController.text.trim();
                if (noteContent.isNotEmpty) {
                  final url = Uri.parse('$backendUrl/user/v1/emotion_tracker/append_note/$emotionId');
                  final response = await http.post(
                    url,
                    headers: {
                      'Content-Type': 'application/json',
                      'Authorization': 'Bearer $authToken',
                    },
                    body: jsonEncode({'note': noteContent}),
                  );

                  if (response.statusCode == 200) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Note added successfully')),
                    );
                  } else {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add note')),
                    );
                  }
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotesView() {
    switch (_selectedView) {
      case 'List View':
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _notes.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: _AnimatedNoteCard(note: _notes[index]),
            );
          },
        );
      case 'Carousel View':
        return Column(
          children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: _notes.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _AnimatedNoteCard(note: _notes[index]),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _notes.length,
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
            itemCount: _notes.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: _AnimatedNoteCard(note: _notes[index]),
              );
            },
          ),
        );
      case 'Staggered Grid View':
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            _notes.length,
            (index) {
              return SizedBox(
                width: (index % 3 == 0) ? 150 : 100, // Staggered sizes
                child: _AnimatedNoteCard(note: _notes[index]),
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
          itemCount: _notes.length,
          itemBuilder: (context, index) {
            return _AnimatedNoteCard(note: _notes[index]);
          },
        );
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
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
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
                      _buildNotesView(),
                    ],
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewNote,
        child: Icon(Icons.add),
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
      onTap: () {},
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
