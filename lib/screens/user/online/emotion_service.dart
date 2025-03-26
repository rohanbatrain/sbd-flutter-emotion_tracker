// emotion_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class EmotionService {
  final logger = Logger();  // Fix the logger initialization

  // Function to send emotion data to the backend
  Future<void> sendEmotionData(
    String backendUrl,
    String authToken,
    String emotionFelt,
    int emotionIntensity,
    List<String> noteIds,
  ) async {
    final url = Uri.parse('$backendUrl/user/v1/emotion_tracker/add');
    
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    };

    final body = json.encode({
      'emotion_felt': emotionFelt,
      'emotion_intensity': emotionIntensity,
      'note_ids': noteIds,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        // Handle success
        logger.i('Emotion data sent successfully!');
      } else {
        // Handle error
        logger.e('Failed to send emotion data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error sending emotion data: $e');
    }
  }

  // Function to fetch all emotions from the backend
  Future<List<Map<String, dynamic>>> fetchEmotions(
    String backendUrl,
    String authToken,
  ) async {
    final url = Uri.parse('$backendUrl/user/v1/emotion_tracker/get');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        // Parse the response body into a list of emotions
        final List<dynamic> responseData = json.decode(response.body);
        return responseData.map((emotion) => emotion as Map<String, dynamic>).toList();
      } else {
        // Handle error
        logger.e('Failed to fetch emotions. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      logger.e('Error fetching emotions: $e');
      return [];
    }
  }
}
