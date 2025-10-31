import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:emotion_tracker/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/secure_storage_provider.dart';
import 'package:emotion_tracker/utils/http_util.dart';
import 'package:http/http.dart' as http;
import 'package:emotion_tracker/providers/user_agent_util.dart';
import 'package:emotion_tracker/core/exceptions.dart' as core_exceptions;
import 'package:emotion_tracker/models/ai/ai_events.dart';

final aiApiServiceProvider = Provider((ref) => AIApiService(ref));

class AIApiService {
  final Ref _ref;

  AIApiService(this._ref);

  String get _baseUrl => _ref.read(apiBaseUrlProvider);

  Future<String?> _getAccessToken() async {
    final secureStorage = _ref.read(secureStorageProvider);
    final token = await secureStorage.read(key: 'access_token');
    return token;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAccessToken();
    if (token == null) {
      throw core_exceptions.UnauthorizedException(
        'Session expired. Please log in again.',
      );
    }
    final userAgent = await getUserAgent();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'User-Agent': userAgent,
      'X-User-Agent': userAgent,
    };
  }

  Future<Map<String, dynamic>> _processResponse(http.Response response) async {
    if (response.statusCode == 401) {
      throw core_exceptions.UnauthorizedException(
        'Session expired. Please log in again.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {}; // Return empty map for empty responses
      }
      final decoded = json.decode(response.body);
      // Handle case where response is just an empty array
      if (decoded is List) {
        return {'items': decoded};
      }
      return decoded;
    } else {
      String errorMessage;
      try {
        final responseBody = json.decode(response.body);
        if (responseBody is Map && responseBody.containsKey('detail')) {
          errorMessage = responseBody['detail'];
        } else if (responseBody is Map && responseBody.containsKey('error')) {
          final error = responseBody['error'];
          if (error is Map && error.containsKey('message')) {
            errorMessage = error['message'];
          } else {
            errorMessage = error.toString();
          }
        } else {
          errorMessage = response.body;
        }
      } catch (e) {
        errorMessage = response.body;
      }
      throw Exception('AI API Error (${response.statusCode}): $errorMessage');
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? data,
    Duration? timeout,
  }) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    final headers = await _getHeaders();
    http.Response response;
    final timeoutDuration = timeout ?? const Duration(seconds: 30);

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await HttpUtil.get(
            url,
            headers: headers,
            timeout: timeoutDuration,
          );
          break;
        case 'POST':
          response = await HttpUtil.post(
            url,
            headers: headers,
            body: data != null ? json.encode(data) : null,
            timeout: timeoutDuration,
          );
          break;
        case 'PUT':
          response = await HttpUtil.put(
            url,
            headers: headers,
            body: data != null ? json.encode(data) : null,
            timeout: timeoutDuration,
          );
          break;
        case 'DELETE':
          response = await HttpUtil.delete(
            url,
            headers: headers,
            body: data != null ? json.encode(data) : null,
            timeout: timeoutDuration,
          );
          break;
        default:
          throw UnsupportedError('HTTP method $method not supported.');
      }
      return _processResponse(response);
    } on TimeoutException catch (_) {
      throw Exception('AI request timed out. Please try again.');
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  // ==================== AI Session Management ====================

  /// Create a new AI chat session
  Future<AISession> createSession({
    required AgentType agentType,
    bool voiceEnabled = false,
    Map<String, dynamic>? preferences,
  }) async {
    final request = {
      'agent_type': agentType.name,
      'voice_enabled': voiceEnabled,
      if (preferences != null) 'preferences': preferences,
    };
    
    print('[AI_API] Creating AI session: $request');
    
    try {
      final response = await _request(
        'POST',
        '/ai/sessions',
        data: request,
      );
      print('[AI_API] AI session created: $response');
      return AISession.fromJson(response);
    } catch (e) {
      print('[AI_API] Failed to create AI session: ${e.toString()}');
      rethrow;
    }
  }

  /// Create a new AI chat session (legacy method for backward compatibility)
  Future<Map<String, dynamic>> createAISession({
    required String agentType,
    bool voiceEnabled = false,
    Map<String, dynamic>? preferences,
  }) async {
    final request = {
      'agent_type': agentType,
      'voice_enabled': voiceEnabled,
      if (preferences != null) 'preferences': preferences,
    };
    
    print('[AI_API] Creating AI session: $request');
    
    try {
      final response = await _request(
        'POST',
        '/ai/sessions',
        data: request,
      );
      print('[AI_API] AI session created: $response');
      return response;
    } catch (e) {
      print('[AI_API] Failed to create AI session: ${e.toString()}');
      rethrow;
    }
  }

  /// Get list of active AI sessions
  Future<List<Map<String, dynamic>>> getAISessions({int limit = 50}) async {
    try {
      final response = await _request(
        'GET',
        '/ai/sessions?limit=$limit',
      );
      
      print('[AI_API] Retrieved AI sessions: $response');
      
      if (response.isEmpty) return [];
      final sessions = (response['sessions'] ?? response['items'] ?? []) as List;
      return sessions.cast<Map<String, dynamic>>();
    } catch (e) {
      print('[AI_API] Failed to get AI sessions: ${e.toString()}');
      rethrow;
    }
  }

  /// Get specific AI session details
  Future<Map<String, dynamic>> getAISession(String sessionId) async {
    try {
      final response = await _request(
        'GET',
        '/ai/sessions/$sessionId',
      );
      
      print('[AI_API] Retrieved AI session $sessionId: $response');
      return response;
    } catch (e) {
      print('[AI_API] Failed to get AI session $sessionId: ${e.toString()}');
      rethrow;
    }
  }

  /// Send a message to an AI session
  Future<Map<String, dynamic>> sendMessage({
    required String sessionId,
    required String content,
    MessageType messageType = MessageType.text,
    String? audioData,
    Map<String, dynamic>? metadata,
  }) async {
    final request = {
      'content': content,
      'message_type': messageType.name,
      if (audioData != null) 'audio_data': audioData,
      if (metadata != null) 'metadata': metadata,
    };
    
    print('[AI_API] Sending message to session $sessionId: ${request['message_type']} message');
    
    try {
      final response = await _request(
        'POST',
        '/ai/sessions/$sessionId/message',
        data: request,
      );
      print('[AI_API] Message sent successfully: $response');
      return response;
    } catch (e) {
      print('[AI_API] Failed to send message: ${e.toString()}');
      rethrow;
    }
  }

  /// End an AI session
  Future<void> endSession(String sessionId) async {
    try {
      await _request(
        'DELETE',
        '/ai/sessions/$sessionId',
      );
      print('[AI_API] AI session $sessionId ended successfully');
    } catch (e) {
      print('[AI_API] Failed to end AI session $sessionId: ${e.toString()}');
      rethrow;
    }
  }

  /// End an AI session (legacy method for backward compatibility)
  Future<void> endAISession(String sessionId) async {
    return endSession(sessionId);
  }

  /// Get conversation history for a session
  Future<List<ChatMessage>> getSessionHistory({
    required String sessionId,
    int limit = 50,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (offset != null) queryParams['offset'] = offset;
      
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      
      final response = await _request(
        'GET',
        '/ai/sessions/$sessionId/history?$queryString',
      );
      
      print('[AI_API] Retrieved session history for $sessionId');
      
      if (response.isEmpty) return [];
      final messages = (response['messages'] ?? response['items'] ?? []) as List;
      return messages.map((msg) => ChatMessage.fromJson(msg as Map<String, dynamic>)).toList();
    } catch (e) {
      print('[AI_API] Failed to get session history: ${e.toString()}');
      rethrow;
    }
  }

  // ==================== Agent Management ====================

  /// Get available AI agents
  Future<List<Map<String, dynamic>>> getAvailableAgents() async {
    try {
      final response = await _request(
        'GET',
        '/ai/agents',
      );
      
      print('[AI_API] Retrieved available agents: $response');
      
      if (response.isEmpty) return [];
      final agents = (response['agents'] ?? response['items'] ?? []) as List;
      return agents.cast<Map<String, dynamic>>();
    } catch (e) {
      print('[AI_API] Failed to get available agents: ${e.toString()}');
      rethrow;
    }
  }

  /// Switch agent in an active session
  Future<AISession> switchAgent({
    required String sessionId,
    required AgentType newAgentType,
  }) async {
    final request = {
      'agent_type': newAgentType.name,
    };
    
    print('[AI_API] Switching agent in session $sessionId to ${newAgentType.name}');
    
    try {
      final response = await _request(
        'PUT',
        '/ai/sessions/$sessionId/agent',
        data: request,
      );
      print('[AI_API] Agent switched successfully: $response');
      return AISession.fromJson(response);
    } catch (e) {
      print('[AI_API] Failed to switch agent: ${e.toString()}');
      rethrow;
    }
  }

  // ==================== Health Check ====================

  /// Check AI service health
  Future<Map<String, dynamic>> getAIHealth() async {
    try {
      final response = await _request(
        'GET',
        '/ai/health',
      );
      
      print('[AI_API] AI service health: $response');
      return response;
    } catch (e) {
      print('[AI_API] Failed to get AI health: ${e.toString()}');
      rethrow;
    }
  }
}