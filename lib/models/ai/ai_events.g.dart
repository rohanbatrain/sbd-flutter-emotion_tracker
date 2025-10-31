// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AIEvent _$AIEventFromJson(Map<String, dynamic> json) => AIEvent(
  eventType: $enumDecode(_$AIEventTypeEnumMap, json['event_type']),
  sessionId: json['session_id'] as String,
  agentType: json['agent_type'] as String,
  data: json['data'] as Map<String, dynamic>,
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$AIEventToJson(AIEvent instance) => <String, dynamic>{
  'event_type': _$AIEventTypeEnumMap[instance.eventType]!,
  'session_id': instance.sessionId,
  'agent_type': instance.agentType,
  'data': instance.data,
  'timestamp': instance.timestamp.toIso8601String(),
};

const _$AIEventTypeEnumMap = {
  AIEventType.token: 'token',
  AIEventType.response: 'response',
  AIEventType.toolCall: 'tool_call',
  AIEventType.toolResult: 'tool_result',
  AIEventType.tts: 'tts',
  AIEventType.stt: 'stt',
  AIEventType.thinking: 'thinking',
  AIEventType.typing: 'typing',
  AIEventType.error: 'error',
};

AgentConfig _$AgentConfigFromJson(Map<String, dynamic> json) => AgentConfig(
  agentType: $enumDecode(_$AgentTypeEnumMap, json['agent_type']),
  name: json['name'] as String,
  description: json['description'] as String,
  capabilities: (json['capabilities'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  tools: (json['tools'] as List<dynamic>).map((e) => e as String).toList(),
  voiceEnabled: json['voice_enabled'] as bool,
  adminOnly: json['admin_only'] as bool? ?? false,
);

Map<String, dynamic> _$AgentConfigToJson(AgentConfig instance) =>
    <String, dynamic>{
      'agent_type': _$AgentTypeEnumMap[instance.agentType]!,
      'name': instance.name,
      'description': instance.description,
      'capabilities': instance.capabilities,
      'tools': instance.tools,
      'voice_enabled': instance.voiceEnabled,
      'admin_only': instance.adminOnly,
    };

const _$AgentTypeEnumMap = {
  AgentType.family: 'family',
  AgentType.personal: 'personal',
  AgentType.workspace: 'workspace',
  AgentType.commerce: 'commerce',
  AgentType.security: 'security',
  AgentType.voice: 'voice',
};

AISession _$AISessionFromJson(Map<String, dynamic> json) => AISession(
  sessionId: json['session_id'] as String,
  userId: json['user_id'] as String,
  agentType: $enumDecode(_$AgentTypeEnumMap, json['agent_type']),
  status: $enumDecode(_$SessionStatusEnumMap, json['status']),
  createdAt: DateTime.parse(json['created_at'] as String),
  lastActivity: DateTime.parse(json['last_activity'] as String),
  expiresAt: json['expires_at'] == null
      ? null
      : DateTime.parse(json['expires_at'] as String),
  websocketConnected: json['websocket_connected'] as bool? ?? false,
  voiceEnabled: json['voice_enabled'] as bool? ?? false,
  messageCount: (json['message_count'] as num?)?.toInt() ?? 0,
  preferences: json['preferences'] as Map<String, dynamic>? ?? const {},
  metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
  agentConfig: json['agent_config'] == null
      ? null
      : AgentConfig.fromJson(json['agent_config'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AISessionToJson(AISession instance) => <String, dynamic>{
  'session_id': instance.sessionId,
  'user_id': instance.userId,
  'agent_type': _$AgentTypeEnumMap[instance.agentType]!,
  'status': _$SessionStatusEnumMap[instance.status]!,
  'created_at': instance.createdAt.toIso8601String(),
  'last_activity': instance.lastActivity.toIso8601String(),
  'expires_at': instance.expiresAt?.toIso8601String(),
  'websocket_connected': instance.websocketConnected,
  'voice_enabled': instance.voiceEnabled,
  'message_count': instance.messageCount,
  'preferences': instance.preferences,
  'metadata': instance.metadata,
  'agent_config': instance.agentConfig,
};

const _$SessionStatusEnumMap = {
  SessionStatus.active: 'active',
  SessionStatus.inactive: 'inactive',
  SessionStatus.expired: 'expired',
  SessionStatus.terminated: 'terminated',
};

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  messageId: json['message_id'] as String,
  sessionId: json['session_id'] as String,
  content: json['content'] as String,
  role: $enumDecode(_$MessageRoleEnumMap, json['role']),
  agentType: json['agent_type'] as String?,
  timestamp: DateTime.parse(json['timestamp'] as String),
  messageType:
      $enumDecodeNullable(_$MessageTypeEnumMap, json['message_type']) ??
      MessageType.text,
  metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
  audioData: json['audio_data'] as String?,
  processingTimeMs: (json['processing_time_ms'] as num?)?.toInt(),
);

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'message_id': instance.messageId,
      'session_id': instance.sessionId,
      'content': instance.content,
      'role': _$MessageRoleEnumMap[instance.role]!,
      'agent_type': instance.agentType,
      'timestamp': instance.timestamp.toIso8601String(),
      'message_type': _$MessageTypeEnumMap[instance.messageType]!,
      'metadata': instance.metadata,
      'audio_data': instance.audioData,
      'processing_time_ms': instance.processingTimeMs,
    };

const _$MessageRoleEnumMap = {
  MessageRole.user: 'user',
  MessageRole.assistant: 'assistant',
  MessageRole.system: 'system',
  MessageRole.tool: 'tool',
};

const _$MessageTypeEnumMap = {
  MessageType.text: 'text',
  MessageType.voice: 'voice',
  MessageType.toolCall: 'tool_call',
  MessageType.toolResult: 'tool_result',
  MessageType.thinking: 'thinking',
  MessageType.typing: 'typing',
};

CreateAISessionRequest _$CreateAISessionRequestFromJson(
  Map<String, dynamic> json,
) => CreateAISessionRequest(
  agentType: $enumDecode(_$AgentTypeEnumMap, json['agent_type']),
  voiceEnabled: json['voice_enabled'] as bool? ?? false,
  preferences: json['preferences'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$CreateAISessionRequestToJson(
  CreateAISessionRequest instance,
) => <String, dynamic>{
  'agent_type': _$AgentTypeEnumMap[instance.agentType]!,
  'voice_enabled': instance.voiceEnabled,
  'preferences': instance.preferences,
};

SendMessageRequest _$SendMessageRequestFromJson(Map<String, dynamic> json) =>
    SendMessageRequest(
      content: json['content'] as String,
      messageType:
          $enumDecodeNullable(_$MessageTypeEnumMap, json['message_type']) ??
          MessageType.text,
      audioData: json['audio_data'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$SendMessageRequestToJson(SendMessageRequest instance) =>
    <String, dynamic>{
      'content': instance.content,
      'message_type': _$MessageTypeEnumMap[instance.messageType]!,
      'audio_data': instance.audioData,
      'metadata': instance.metadata,
    };

MessageResponse _$MessageResponseFromJson(Map<String, dynamic> json) =>
    MessageResponse(
      messageId: json['message_id'] as String,
      sessionId: json['session_id'] as String,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      processingTimeMs: (json['processing_time_ms'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MessageResponseToJson(MessageResponse instance) =>
    <String, dynamic>{
      'message_id': instance.messageId,
      'session_id': instance.sessionId,
      'status': instance.status,
      'timestamp': instance.timestamp.toIso8601String(),
      'processing_time_ms': instance.processingTimeMs,
    };

AIHealthResponse _$AIHealthResponseFromJson(Map<String, dynamic> json) =>
    AIHealthResponse(
      status: json['status'] as String,
      activeSessions: (json['active_sessions'] as num).toInt(),
      availableAgents: (json['available_agents'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      systemLoad: json['system_load'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$AIHealthResponseToJson(AIHealthResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'active_sessions': instance.activeSessions,
      'available_agents': instance.availableAgents,
      'system_load': instance.systemLoad,
      'timestamp': instance.timestamp.toIso8601String(),
    };
