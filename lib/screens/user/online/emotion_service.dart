// emotion_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class EmotionService {
  final logger = Logger();  // Fix the logger initialization

  // Encrypt note using AES with random IV
  Future<String> _encryptNote(String note, String encryptionKey) async {
    final key = encrypt.Key.fromUtf8(encryptionKey.padRight(32, ' ')); // AES key needs to be 32 bytes
    final iv = encrypt.IV.fromLength(16); // Random 16-byte IV for AES
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    // Encrypt the note value
    final encrypted = encrypter.encrypt(note, iv: iv);

    // Combine the encrypted note and IV into a single string
    return '${encrypted.base64}:${iv.base64}';
  }

  // Decrypt note using AES with stored IV
  Future<String> _decryptNote(String encryptedNote, String encryptionKey) async {
    final key = encrypt.Key.fromUtf8(encryptionKey.padRight(32, ' ')); // AES key needs to be 32 bytes

    try {
      // Split the encrypted note and IV
      final parts = encryptedNote.split(':');
      if (parts.length != 2) throw Exception('Invalid encrypted note format');

      final encryptedData = encrypt.Encrypted.fromBase64(parts[0]); // Decode the encrypted note
      final iv = encrypt.IV.fromBase64(parts[1]); // Decode the base64 IV

      // Decrypt the note using AES
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      return encrypter.decrypt(encryptedData, iv: iv);
    } catch (e) {
      logger.e('Error decrypting note: $e');
      return 'Invalid note format'; // Fallback for invalid formats
    }
  }

  // Function to send emotion data to the backend
  Future<void> sendEmotionData(
    String backendUrl,
    String authToken,
    String emotionFelt,
    int emotionIntensity,
    String note,
  ) async {
    // Retrieve the encryption key and encryption status from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final bool isEncryptionEnabled = prefs.getBool('is_encryption_enabled') ?? false;
    final String? encryptionKey = prefs.getString('encryption_key');

    if (isEncryptionEnabled && encryptionKey != null) {
      // Encrypt the note with AES (random IV)
      note = await _encryptNote(note, encryptionKey);
    }

    final url = Uri.parse('$backendUrl/user/v1/emotion_tracker/add');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    };

    final body = json.encode({
      'emotion_felt': emotionFelt,
      'emotion_intensity': emotionIntensity,
      'note': note,
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
    final prefs = await SharedPreferences.getInstance();
    final bool isEncryptionEnabled = prefs.getBool('is_encryption_enabled') ?? false;
    final String? encryptionKey = prefs.getString('encryption_key');

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

        // Decrypt notes if encryption is enabled
        final emotions = responseData.map((emotion) async {
          final emotionMap = emotion as Map<String, dynamic>;
          if (isEncryptionEnabled && encryptionKey != null && emotionMap['note'] != null) {
            emotionMap['note'] = await _decryptNote(emotionMap['note'], encryptionKey);
          }
          return emotionMap;
        });

        return await Future.wait(emotions);
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
