/// Custom exceptions for AI API operations
/// Provides specific error types for different AI-related edge cases

/// Base class for all AI-related API exceptions
class AIApiException implements Exception {
  final String message;
  final int? statusCode;

  AIApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// 400 - Validation Errors

class ValidationException extends AIApiException {
  ValidationException(String message) : super(message, statusCode: 400);
}

class InvalidSessionException extends ValidationException {
  InvalidSessionException(String message) : super(message);
}

class InvalidAgentTypeException extends ValidationException {
  InvalidAgentTypeException(String message) : super(message);
}

class InvalidMessageFormatException extends ValidationException {
  InvalidMessageFormatException(String message) : super(message);
}

class SessionLimitReachedException extends ValidationException {
  SessionLimitReachedException(String message) : super(message);

  /// Extract maximum sessions from backend message like "Maximum 5 concurrent sessions allowed"
  int? get maxSessions {
    final match = RegExp(r'Maximum (\d+) concurrent sessions').firstMatch(message);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }
}

class MessageTooLongException extends ValidationException {
  MessageTooLongException(String message) : super(message);

  /// Extract character limit from backend message like "Message exceeds 4000 character limit"
  int? get characterLimit {
    final match = RegExp(r'exceeds (\d+) character limit').firstMatch(message);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }
}

/// 401 - Authentication Errors

class UnauthorizedException extends AIApiException {
  UnauthorizedException(String message) : super(message, statusCode: 401);
}

class SessionExpiredException extends UnauthorizedException {
  SessionExpiredException(String message) : super(message);
}

/// 403 - Permission Errors

class PermissionDeniedException extends AIApiException {
  PermissionDeniedException(String message) : super(message, statusCode: 403);
}

class AgentAccessDeniedException extends PermissionDeniedException {
  AgentAccessDeniedException(String message) : super(message);
}

class AdminOnlyAgentException extends PermissionDeniedException {
  AdminOnlyAgentException(String message) : super(message);
}

class VoiceFeatureDisabledException extends PermissionDeniedException {
  VoiceFeatureDisabledException(String message) : super(message);
}

/// 404 - Not Found Errors

class NotFoundException extends AIApiException {
  NotFoundException(String message) : super(message, statusCode: 404);
}

class SessionNotFoundException extends NotFoundException {
  SessionNotFoundException(String message) : super(message);
}

class AgentNotFoundException extends NotFoundException {
  AgentNotFoundException(String message) : super(message);
}

class MessageNotFoundException extends NotFoundException {
  MessageNotFoundException(String message) : super(message);
}

/// 409 - Conflict Errors

class ConflictException extends AIApiException {
  ConflictException(String message) : super(message, statusCode: 409);
}

class SessionAlreadyActiveException extends ConflictException {
  SessionAlreadyActiveException(String message) : super(message);
}

class AgentSwitchInProgressException extends ConflictException {
  AgentSwitchInProgressException(String message) : super(message);
}

/// 429 - Rate Limit Errors

class RateLimitException extends AIApiException {
  RateLimitException(String message) : super(message, statusCode: 429);

  /// Extract retry time from backend message like "Rate limit exceeded. Try again in 60 seconds"
  int? get retryAfterSeconds {
    final match = RegExp(r'Try again in (\d+) seconds').firstMatch(message);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }
}

/// 500 - Server Errors

class ServerException extends AIApiException {
  ServerException(String message) : super(message, statusCode: 500);
}

class AIServiceUnavailableException extends ServerException {
  AIServiceUnavailableException(String message) : super(message);
}

class ToolExecutionException extends ServerException {
  ToolExecutionException(String message) : super(message);
}

/// Network Errors

class NetworkException extends AIApiException {
  NetworkException(String message) : super(message);
}

class WebSocketConnectionException extends NetworkException {
  WebSocketConnectionException(String message) : super(message);
}

class WebSocketTimeoutException extends NetworkException {
  WebSocketTimeoutException(String message) : super(message);
}

/// Voice-specific Errors

class VoiceException extends AIApiException {
  VoiceException(String message) : super(message, statusCode: 400);
}

class MicrophonePermissionException extends VoiceException {
  MicrophonePermissionException(String message) : super(message);
}

class AudioRecordingException extends VoiceException {
  AudioRecordingException(String message) : super(message);
}

class AudioPlaybackException extends VoiceException {
  AudioPlaybackException(String message) : super(message);
}

class SpeechToTextException extends VoiceException {
  SpeechToTextException(String message) : super(message);
}

class TextToSpeechException extends VoiceException {
  TextToSpeechException(String message) : super(message);
}

/// Tool Execution Errors

class ToolException extends AIApiException {
  ToolException(String message) : super(message, statusCode: 500);
}

class ToolNotAvailableException extends ToolException {
  ToolNotAvailableException(String message) : super(message);
}

class ToolExecutionTimeoutException extends ToolException {
  ToolExecutionTimeoutException(String message) : super(message);
}

class ToolPermissionException extends ToolException {
  ToolPermissionException(String message) : super(message);
}

/// Session Management Errors

class SessionException extends AIApiException {
  SessionException(String message) : super(message, statusCode: 400);
}

class SessionTimeoutException extends SessionException {
  SessionTimeoutException(String message) : super(message);

  /// Extract timeout duration from backend message like "Session timed out after 30 minutes"
  int? get timeoutMinutes {
    final match = RegExp(r'timed out after (\d+) minutes').firstMatch(message);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }
}

class SessionCleanupException extends SessionException {
  SessionCleanupException(String message) : super(message);
}