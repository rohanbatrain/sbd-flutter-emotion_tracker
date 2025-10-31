import 'dart:convert';
import 'lib/models/ai/ai_events.dart';

void main() {
  // Test AIEvent serialization
  final aiEvent = AIEvent(
    eventType: AIEventType.token,
    sessionId: 'test-session-123',
    agentType: 'family',
    data: {'token': 'Hello'},
    timestamp: DateTime.now(),
  );
  
  print('AIEvent JSON: ${jsonEncode(aiEvent.toJson())}');
  
  // Test AISession serialization
  final aiSession = AISession(
    sessionId: 'session-123',
    userId: 'user-456',
    agentType: AgentType.family,
    status: SessionStatus.active,
    createdAt: DateTime.now(),
    lastActivity: DateTime.now(),
    voiceEnabled: true,
    messageCount: 5,
  );
  
  print('AISession JSON: ${jsonEncode(aiSession.toJson())}');
  
  // Test ChatMessage serialization
  final chatMessage = ChatMessage(
    messageId: 'msg-789',
    sessionId: 'session-123',
    content: 'Hello, how can I help you?',
    role: MessageRole.assistant,
    timestamp: DateTime.now(),
    messageType: MessageType.text,
  );
  
  print('ChatMessage JSON: ${jsonEncode(chatMessage.toJson())}');
  
  print('All models serialized successfully!');
}