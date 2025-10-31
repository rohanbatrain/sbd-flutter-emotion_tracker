import 'package:json_annotation/json_annotation.dart';

part 'ai_events.g.dart';

/// Enum for AI event types that can be received via WebSocket
@JsonEnum(valueField: 'value')
enum AIEventType {
  token('token'),
  response('response'),
  toolCall('tool_call'),
  toolResult('tool_result'),
  tts('tts'),
  stt('stt'),
  thinking('thinking'),
  typing('typing'),
  error('error');

  const AIEventType(this.value);
  final String value;
}

/// Enum for AI agent types available in the system
@JsonEnum(valueField: 'value')
enum AgentType {
  family('family'),
  personal('personal'),
  workspace('workspace'),
  commerce('commerce'),
  security('security'),
  voice('voice');

  const AgentType(this.value);
  final String value;
}

/// Enum for session status
@JsonEnum(valueField: 'value')
enum SessionStatus {
  active('active'),
  inactive('inactive'),
  expired('expired'),
  terminated('terminated');

  const SessionStatus(this.value);
  final String value;
}

/// Enum for message roles in chat
@JsonEnum(valueField: 'value')
enum MessageRole {
  user('user'),
  assistant('assistant'),
  system('system'),
  tool('tool');

  const MessageRole(this.value);
  final String value;
}

/// Enum for message types
@JsonEnum(valueField: 'value')
enum MessageType {
  text('text'),
  voice('voice'),
  toolCall('tool_call'),
  toolResult('tool_result'),
  thinking('thinking'),
  typing('typing');

  const MessageType(this.value);
  final String value;
}

/// AI Event model for WebSocket communication
@JsonSerializable()
class AIEvent {
  @JsonKey(name: 'event_type')
  final AIEventType eventType;
  
  @JsonKey(name: 'session_id')
  final String sessionId;
  
  @JsonKey(name: 'agent_type')
  final String agentType;
  
  final Map<String, dynamic> data;
  
  final DateTime timestamp;

  const AIEvent({
    required this.eventType,
    required this.sessionId,
    required this.agentType,
    required this.data,
    required this.timestamp,
  });

  factory AIEvent.fromJson(Map<String, dynamic> json) => _$AIEventFromJson(json);
  Map<String, dynamic> toJson() => _$AIEventToJson(this);

  AIEvent copyWith({
    AIEventType? eventType,
    String? sessionId,
    String? agentType,
    Map<String, dynamic>? data,
    DateTime? timestamp,
  }) {
    return AIEvent(
      eventType: eventType ?? this.eventType,
      sessionId: sessionId ?? this.sessionId,
      agentType: agentType ?? this.agentType,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'AIEvent(eventType: $eventType, sessionId: $sessionId, agentType: $agentType, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIEvent &&
        other.eventType == eventType &&
        other.sessionId == sessionId &&
        other.agentType == agentType &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return eventType.hashCode ^
        sessionId.hashCode ^
        agentType.hashCode ^
        timestamp.hashCode;
  }
}

/// Agent Configuration model
@JsonSerializable()
class AgentConfig {
  @JsonKey(name: 'agent_type')
  final AgentType agentType;
  
  final String name;
  final String description;
  final List<String> capabilities;
  final List<String> tools;
  
  @JsonKey(name: 'voice_enabled')
  final bool voiceEnabled;
  
  @JsonKey(name: 'admin_only')
  final bool adminOnly;

  const AgentConfig({
    required this.agentType,
    required this.name,
    required this.description,
    required this.capabilities,
    required this.tools,
    required this.voiceEnabled,
    this.adminOnly = false,
  });

  factory AgentConfig.fromJson(Map<String, dynamic> json) => _$AgentConfigFromJson(json);
  Map<String, dynamic> toJson() => _$AgentConfigToJson(this);

  AgentConfig copyWith({
    AgentType? agentType,
    String? name,
    String? description,
    List<String>? capabilities,
    List<String>? tools,
    bool? voiceEnabled,
    bool? adminOnly,
  }) {
    return AgentConfig(
      agentType: agentType ?? this.agentType,
      name: name ?? this.name,
      description: description ?? this.description,
      capabilities: capabilities ?? this.capabilities,
      tools: tools ?? this.tools,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      adminOnly: adminOnly ?? this.adminOnly,
    );
  }

  @override
  String toString() {
    return 'AgentConfig(agentType: $agentType, name: $name, voiceEnabled: $voiceEnabled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgentConfig &&
        other.agentType == agentType &&
        other.name == name &&
        other.description == description &&
        other.voiceEnabled == voiceEnabled &&
        other.adminOnly == adminOnly;
  }

  @override
  int get hashCode {
    return agentType.hashCode ^
        name.hashCode ^
        description.hashCode ^
        voiceEnabled.hashCode ^
        adminOnly.hashCode;
  }
}

/// AI Session model
@JsonSerializable()
class AISession {
  @JsonKey(name: 'session_id')
  final String sessionId;
  
  @JsonKey(name: 'user_id')
  final String userId;
  
  @JsonKey(name: 'agent_type')
  final AgentType agentType;
  
  final SessionStatus status;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'last_activity')
  final DateTime lastActivity;
  
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;
  
  @JsonKey(name: 'websocket_connected')
  final bool websocketConnected;
  
  @JsonKey(name: 'voice_enabled')
  final bool voiceEnabled;
  
  @JsonKey(name: 'message_count')
  final int messageCount;
  
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> metadata;
  
  @JsonKey(name: 'agent_config')
  final AgentConfig? agentConfig;

  const AISession({
    required this.sessionId,
    required this.userId,
    required this.agentType,
    required this.status,
    required this.createdAt,
    required this.lastActivity,
    this.expiresAt,
    this.websocketConnected = false,
    this.voiceEnabled = false,
    this.messageCount = 0,
    this.preferences = const {},
    this.metadata = const {},
    this.agentConfig,
  });

  factory AISession.fromJson(Map<String, dynamic> json) => _$AISessionFromJson(json);
  Map<String, dynamic> toJson() => _$AISessionToJson(this);

  AISession copyWith({
    String? sessionId,
    String? userId,
    AgentType? agentType,
    SessionStatus? status,
    DateTime? createdAt,
    DateTime? lastActivity,
    DateTime? expiresAt,
    bool? websocketConnected,
    bool? voiceEnabled,
    int? messageCount,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? metadata,
    AgentConfig? agentConfig,
  }) {
    return AISession(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      agentType: agentType ?? this.agentType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
      expiresAt: expiresAt ?? this.expiresAt,
      websocketConnected: websocketConnected ?? this.websocketConnected,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      messageCount: messageCount ?? this.messageCount,
      preferences: preferences ?? this.preferences,
      metadata: metadata ?? this.metadata,
      agentConfig: agentConfig ?? this.agentConfig,
    );
  }

  /// Check if the session is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if the session is active and not expired
  bool get isActive {
    return status == SessionStatus.active && !isExpired;
  }

  @override
  String toString() {
    return 'AISession(sessionId: $sessionId, agentType: $agentType, status: $status, messageCount: $messageCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AISession &&
        other.sessionId == sessionId &&
        other.userId == userId &&
        other.agentType == agentType &&
        other.status == status;
  }

  @override
  int get hashCode {
    return sessionId.hashCode ^
        userId.hashCode ^
        agentType.hashCode ^
        status.hashCode;
  }
}

/// Chat Message model
@JsonSerializable()
class ChatMessage {
  @JsonKey(name: 'message_id')
  final String messageId;
  
  @JsonKey(name: 'session_id')
  final String sessionId;
  
  final String content;
  final MessageRole role;
  
  @JsonKey(name: 'agent_type')
  final String? agentType;
  
  final DateTime timestamp;
  
  @JsonKey(name: 'message_type')
  final MessageType messageType;
  
  final Map<String, dynamic> metadata;
  
  @JsonKey(name: 'audio_data')
  final String? audioData;
  
  @JsonKey(name: 'processing_time_ms')
  final int? processingTimeMs;

  const ChatMessage({
    required this.messageId,
    required this.sessionId,
    required this.content,
    required this.role,
    this.agentType,
    required this.timestamp,
    this.messageType = MessageType.text,
    this.metadata = const {},
    this.audioData,
    this.processingTimeMs,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  ChatMessage copyWith({
    String? messageId,
    String? sessionId,
    String? content,
    MessageRole? role,
    String? agentType,
    DateTime? timestamp,
    MessageType? messageType,
    Map<String, dynamic>? metadata,
    String? audioData,
    int? processingTimeMs,
  }) {
    return ChatMessage(
      messageId: messageId ?? this.messageId,
      sessionId: sessionId ?? this.sessionId,
      content: content ?? this.content,
      role: role ?? this.role,
      agentType: agentType ?? this.agentType,
      timestamp: timestamp ?? this.timestamp,
      messageType: messageType ?? this.messageType,
      metadata: metadata ?? this.metadata,
      audioData: audioData ?? this.audioData,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
    );
  }

  /// Check if this is a user message
  bool get isUserMessage => role == MessageRole.user;

  /// Check if this is an assistant message
  bool get isAssistantMessage => role == MessageRole.assistant;

  /// Check if this is a voice message
  bool get isVoiceMessage => messageType == MessageType.voice;

  /// Check if this is a tool call or result
  bool get isToolMessage => messageType == MessageType.toolCall || messageType == MessageType.toolResult;

  @override
  String toString() {
    return 'ChatMessage(messageId: $messageId, role: $role, messageType: $messageType, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.messageId == messageId &&
        other.sessionId == sessionId &&
        other.content == content &&
        other.role == role &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return messageId.hashCode ^
        sessionId.hashCode ^
        content.hashCode ^
        role.hashCode ^
        timestamp.hashCode;
  }
}

/// Request model for creating a new AI session
@JsonSerializable()
class CreateAISessionRequest {
  @JsonKey(name: 'agent_type')
  final AgentType agentType;
  
  @JsonKey(name: 'voice_enabled')
  final bool voiceEnabled;
  
  final Map<String, dynamic> preferences;

  const CreateAISessionRequest({
    required this.agentType,
    this.voiceEnabled = false,
    this.preferences = const {},
  });

  factory CreateAISessionRequest.fromJson(Map<String, dynamic> json) => _$CreateAISessionRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateAISessionRequestToJson(this);

  CreateAISessionRequest copyWith({
    AgentType? agentType,
    bool? voiceEnabled,
    Map<String, dynamic>? preferences,
  }) {
    return CreateAISessionRequest(
      agentType: agentType ?? this.agentType,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  String toString() {
    return 'CreateAISessionRequest(agentType: $agentType, voiceEnabled: $voiceEnabled)';
  }
}

/// Request model for sending a message
@JsonSerializable()
class SendMessageRequest {
  final String content;
  
  @JsonKey(name: 'message_type')
  final MessageType messageType;
  
  @JsonKey(name: 'audio_data')
  final String? audioData;
  
  final Map<String, dynamic> metadata;

  const SendMessageRequest({
    required this.content,
    this.messageType = MessageType.text,
    this.audioData,
    this.metadata = const {},
  });

  factory SendMessageRequest.fromJson(Map<String, dynamic> json) => _$SendMessageRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SendMessageRequestToJson(this);

  SendMessageRequest copyWith({
    String? content,
    MessageType? messageType,
    String? audioData,
    Map<String, dynamic>? metadata,
  }) {
    return SendMessageRequest(
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      audioData: audioData ?? this.audioData,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'SendMessageRequest(messageType: $messageType, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content})';
  }
}

/// Response model for message operations
@JsonSerializable()
class MessageResponse {
  @JsonKey(name: 'message_id')
  final String messageId;
  
  @JsonKey(name: 'session_id')
  final String sessionId;
  
  final String status;
  final DateTime timestamp;
  
  @JsonKey(name: 'processing_time_ms')
  final int? processingTimeMs;

  const MessageResponse({
    required this.messageId,
    required this.sessionId,
    required this.status,
    required this.timestamp,
    this.processingTimeMs,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json) => _$MessageResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MessageResponseToJson(this);

  MessageResponse copyWith({
    String? messageId,
    String? sessionId,
    String? status,
    DateTime? timestamp,
    int? processingTimeMs,
  }) {
    return MessageResponse(
      messageId: messageId ?? this.messageId,
      sessionId: sessionId ?? this.sessionId,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
    );
  }

  @override
  String toString() {
    return 'MessageResponse(messageId: $messageId, status: $status, processingTimeMs: $processingTimeMs)';
  }
}

/// AI Health response model
@JsonSerializable()
class AIHealthResponse {
  final String status;
  
  @JsonKey(name: 'active_sessions')
  final int activeSessions;
  
  @JsonKey(name: 'available_agents')
  final List<String> availableAgents;
  
  @JsonKey(name: 'system_load')
  final Map<String, dynamic> systemLoad;
  
  final DateTime timestamp;

  const AIHealthResponse({
    required this.status,
    required this.activeSessions,
    required this.availableAgents,
    required this.systemLoad,
    required this.timestamp,
  });

  factory AIHealthResponse.fromJson(Map<String, dynamic> json) => _$AIHealthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AIHealthResponseToJson(this);

  AIHealthResponse copyWith({
    String? status,
    int? activeSessions,
    List<String>? availableAgents,
    Map<String, dynamic>? systemLoad,
    DateTime? timestamp,
  }) {
    return AIHealthResponse(
      status: status ?? this.status,
      activeSessions: activeSessions ?? this.activeSessions,
      availableAgents: availableAgents ?? this.availableAgents,
      systemLoad: systemLoad ?? this.systemLoad,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'AIHealthResponse(status: $status, activeSessions: $activeSessions, availableAgents: ${availableAgents.length})';
  }
}