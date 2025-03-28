import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  _DebugScreenState createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  Map<String, dynamic> _sharedPreferencesData = {};

  @override
  void initState() {
    super.initState();
    _loadSharedPreferencesData();
  }

  Future<void> _loadSharedPreferencesData() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> data = {};
    prefs.getKeys().forEach((key) {
      data[key] = prefs.get(key);
    });
    setState(() {
      _sharedPreferencesData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Screen'),
      ),
      body: _sharedPreferencesData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: _sharedPreferencesData.entries.map((entry) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: SelectableText(entry.key),
                    subtitle: SelectableText(entry.value.toString()),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
