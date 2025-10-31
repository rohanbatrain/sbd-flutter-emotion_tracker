import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/core/error_constants.dart';
import 'package:emotion_tracker/core/error_state.dart';
import 'package:emotion_tracker/core/session_manager.dart';
import 'package:emotion_tracker/providers/api_token_service.dart';
import 'package:emotion_tracker/providers/ai/ai_exceptions.dart' as ai_exceptions;
import 'package:emotion_tracker/utils/http_util.dart';

/// Global error handler service that processes and categorizes all application errors
class GlobalErrorHandler {
  /// Processes any error and returns an appropriate ErrorState
  static ErrorState processError(dynamic error) {
    // Handle AI-specific exceptions first
    if (error is ai_exceptions.AIApiException) {
      return _createAIError(error);
    } else if (error is UnauthorizedException) {
      return _createUnauthorizedError(error);
    } else if (error is RateLimitException) {
      return _createRateLimitError(error);
    } else if (error is CloudflareTunnelException) {
      return _createCloudflareError(error);
    } else if (error is NetworkException) {
      return _createNetworkError(error);
    } else if (error is ApiException) {
      return _createApiError(error);
    } else {
      return _createGenericError(error);
    }
  }

  /// Creates an ErrorState for UnauthorizedException
  static ErrorState _createUnauthorizedError(UnauthorizedException error) {
    final config = ErrorConfigs.getConfig(ErrorType.unauthorized);
    return ErrorState.fromConfig(
      type: ErrorType.unauthorized,
      config: config,
      title: ErrorConstants.unauthorizedTitle,
      message: ErrorConstants.sessionExpired,
      metadata: {'originalError': error},
    );
  }

  /// Creates an ErrorState for RateLimitException
  static ErrorState _createRateLimitError(RateLimitException error) {
    final config = ErrorConfigs.getConfig(ErrorType.rateLimited);
    return ErrorState.fromConfig(
      type: ErrorType.rateLimited,
      config: config,
      title: ErrorConstants.rateLimitTitle,
      message: error.message.isNotEmpty
          ? error.message
          : ErrorConstants.rateLimited,
      metadata: {'originalError': error},
    );
  }

  /// Creates an ErrorState for CloudflareTunnelException
  static ErrorState _createCloudflareError(CloudflareTunnelException error) {
    final config = ErrorConfigs.getConfig(ErrorType.cloudflareError);
    return ErrorState.fromConfig(
      type: ErrorType.cloudflareError,
      config: config,
      title: ErrorConstants.cloudflareTitle,
      message: error.message.isNotEmpty
          ? error.message
          : ErrorConstants.cloudflareDown,
      metadata: {
        'originalError': error,
        'statusCode': error.statusCode,
        'responseBody': error.responseBody,
      },
    );
  }

  /// Creates an ErrorState for NetworkException
  static ErrorState _createNetworkError(NetworkException error) {
    final config = ErrorConfigs.getConfig(ErrorType.networkError);
    return ErrorState.fromConfig(
      type: ErrorType.networkError,
      config: config,
      title: ErrorConstants.networkTitle,
      message: error.message.isNotEmpty
          ? error.message
          : ErrorConstants.networkError,
      metadata: {'originalError': error},
    );
  }

  /// Creates an ErrorState for ApiException with status code handling
  static ErrorState _createApiError(ApiException error) {
    final statusCode = error.statusCode;

    // Determine error type and message based on status code
    if (statusCode == 401) {
      // This should have been caught as UnauthorizedException, but handle it anyway
      return _createUnauthorizedError(UnauthorizedException(error.message));
    } else if (statusCode == 429) {
      // This should have been caught as RateLimitException, but handle it anyway
      return _createRateLimitError(RateLimitException(error.message));
    } else if (statusCode != null && statusCode >= 500) {
      // Server errors
      final config = ErrorConfigs.getConfig(ErrorType.serverError);
      String message = _getServerErrorMessage(statusCode, error.message);

      return ErrorState.fromConfig(
        type: ErrorType.serverError,
        config: config,
        title: ErrorConstants.serverTitle,
        message: message,
        metadata: {'originalError': error, 'statusCode': statusCode},
      );
    } else {
      // Client errors (4xx) or other errors
      final config = ErrorConfigs.getConfig(ErrorType.generic);
      String message = _getClientErrorMessage(statusCode, error.message);

      return ErrorState.fromConfig(
        type: ErrorType.generic,
        config: config,
        title: ErrorConstants.genericTitle,
        message: message,
        metadata: {'originalError': error, 'statusCode': statusCode},
      );
    }
  }

  /// Creates an ErrorState for generic/unknown errors
  static ErrorState _createGenericError(dynamic error) {
    final config = ErrorConfigs.getConfig(ErrorType.generic);
    return ErrorState.fromConfig(
      type: ErrorType.generic,
      config: config,
      title: ErrorConstants.genericTitle,
      message: ErrorConstants.unknown,
      metadata: {'originalError': error},
    );
  }

  /// Creates an ErrorState for AI-specific exceptions
  static ErrorState _createAIError(ai_exceptions.AIApiException error) {
    // Handle AI authentication errors with session management
    if (error is ai_exceptions.UnauthorizedException || error is ai_exceptions.SessionExpiredException) {
      return _createAIUnauthorizedError(error);
    }
    
    // Handle AI rate limiting
    if (error is ai_exceptions.RateLimitException) {
      return _createAIRateLimitError(error);
    }
    
    // Handle voice-specific errors
    if (error is ai_exceptions.VoiceException) {
      return _createAIVoiceError(error);
    }
    
    // Handle WebSocket connection errors
    if (error is ai_exceptions.WebSocketConnectionException || error is ai_exceptions.WebSocketTimeoutException) {
      return _createAIWebSocketError(error as ai_exceptions.NetworkException);
    }
    
    // Handle tool execution errors
    if (error is ai_exceptions.ToolException) {
      return _createAIToolError(error);
    }
    
    // Handle session-related errors
    if (error is ai_exceptions.SessionException || error is ai_exceptions.SessionNotFoundException || 
        error is ai_exceptions.SessionLimitReachedException || error is ai_exceptions.SessionAlreadyActiveException) {
      return _createAISessionError(error);
    }
    
    // Handle agent-related errors
    if (error is ai_exceptions.AgentNotFoundException || error is ai_exceptions.AgentAccessDeniedException || 
        error is ai_exceptions.AdminOnlyAgentException || error is ai_exceptions.InvalidAgentTypeException) {
      return _createAIAgentError(error);
    }
    
    // Default AI error handling
    return _createAIGenericError(error);
  }

  /// Creates an ErrorState for AI authentication errors
  static ErrorState _createAIUnauthorizedError(ai_exceptions.AIApiException error) {
    final config = ErrorConfigs.getConfig(ErrorType.unauthorized);
    return ErrorState.fromConfig(
      type: ErrorType.unauthorized,
      config: config,
      title: 'AI Session Expired',
      message: 'Your AI session has expired. Please log in again to continue chatting.',
      metadata: {'originalError': error, 'aiSpecific': true},
    );
  }

  /// Creates an ErrorState for AI rate limiting errors
  static ErrorState _createAIRateLimitError(ai_exceptions.RateLimitException error) {
    final config = ErrorConfigs.getConfig(ErrorType.rateLimited);
    final retrySeconds = error.retryAfterSeconds;
    String message = error.message;
    
    if (retrySeconds != null) {
      message = 'AI rate limit exceeded. Please wait $retrySeconds seconds before trying again.';
    }
    
    return ErrorState.fromConfig(
      type: ErrorType.rateLimited,
      config: config,
      title: 'AI Rate Limit Exceeded',
      message: message,
      metadata: {'originalError': error, 'retryAfterSeconds': retrySeconds},
    );
  }

  /// Creates an ErrorState for AI voice errors
  static ErrorState _createAIVoiceError(ai_exceptions.VoiceException error) {
    final config = ErrorConfigs.getConfig(ErrorType.aiVoiceError);
    String title = 'Voice Feature Error';
    String message = error.message;
    
    if (error is ai_exceptions.MicrophonePermissionException) {
      title = 'Microphone Permission Required';
      message = 'Please grant microphone permission to use voice features with AI assistants.';
    } else if (error is ai_exceptions.AudioRecordingException) {
      title = 'Recording Error';
      message = 'Unable to record audio. Please check your microphone and try again.';
    } else if (error is ai_exceptions.AudioPlaybackException) {
      title = 'Audio Playback Error';
      message = 'Unable to play AI voice response. Please check your audio settings.';
    }
    
    return ErrorState.fromConfig(
      type: ErrorType.aiVoiceError,
      config: config,
      title: title,
      message: message,
      metadata: {'originalError': error},
    );
  }

  /// Creates an ErrorState for AI WebSocket errors
  static ErrorState _createAIWebSocketError(ai_exceptions.NetworkException error) {
    final config = ErrorConfigs.getConfig(ErrorType.aiWebSocketError);
    String title = 'AI Connection Error';
    String message = 'Lost connection to AI service. Attempting to reconnect...';
    
    if (error is ai_exceptions.WebSocketTimeoutException) {
      title = 'AI Connection Timeout';
      message = 'Connection to AI service timed out. Please check your internet connection.';
    }
    
    return ErrorState.fromConfig(
      type: ErrorType.aiWebSocketError,
      config: config,
      title: title,
      message: message,
      metadata: {'originalError': error},
    );
  }

  /// Creates an ErrorState for AI tool execution errors
  static ErrorState _createAIToolError(ai_exceptions.ToolException error) {
    final config = ErrorConfigs.getConfig(ErrorType.aiToolError);
    String title = 'AI Tool Error';
    String message = error.message;
    
    if (error is ai_exceptions.ToolNotAvailableException) {
      title = 'AI Tool Unavailable';
      message = 'The requested AI tool is currently unavailable. Please try again later.';
    } else if (error is ai_exceptions.ToolExecutionTimeoutException) {
      title = 'AI Tool Timeout';
      message = 'AI tool execution timed out. The operation may have been too complex.';
    } else if (error is ai_exceptions.ToolPermissionException) {
      title = 'AI Tool Permission Denied';
      message = 'You don\'t have permission to use this AI tool. Contact your administrator.';
    }
    
    return ErrorState.fromConfig(
      type: ErrorType.aiToolError,
      config: config,
      title: title,
      message: message,
      metadata: {'originalError': error},
    );
  }

  /// Creates an ErrorState for AI session errors
  static ErrorState _createAISessionError(ai_exceptions.AIApiException error) {
    final config = ErrorConfigs.getConfig(ErrorType.aiSessionError);
    String title = 'AI Session Error';
    String message = error.message;
    
    if (error is ai_exceptions.SessionNotFoundException) {
      title = 'AI Session Not Found';
      message = 'Your AI session has ended or expired. Please start a new conversation.';
    } else if (error is ai_exceptions.SessionLimitReachedException) {
      title = 'AI Session Limit Reached';
      final maxSessions = error.maxSessions;
      if (maxSessions != null) {
        message = 'You have reached the maximum of $maxSessions concurrent AI sessions. Please close an existing session first.';
      }
    } else if (error is ai_exceptions.SessionTimeoutException) {
      title = 'AI Session Timeout';
      final timeoutMinutes = error.timeoutMinutes;
      if (timeoutMinutes != null) {
        message = 'Your AI session timed out after $timeoutMinutes minutes of inactivity.';
      }
    }
    
    return ErrorState.fromConfig(
      type: ErrorType.aiSessionError,
      config: config,
      title: title,
      message: message,
      metadata: {'originalError': error},
    );
  }

  /// Creates an ErrorState for AI agent errors
  static ErrorState _createAIAgentError(ai_exceptions.AIApiException error) {
    final config = ErrorConfigs.getConfig(ErrorType.aiAgentError);
    String title = 'AI Agent Error';
    String message = error.message;
    
    if (error is ai_exceptions.AgentNotFoundException) {
      title = 'AI Agent Not Found';
      message = 'The requested AI agent is not available. Please select a different agent.';
    } else if (error is ai_exceptions.AgentAccessDeniedException) {
      title = 'AI Agent Access Denied';
      message = 'You don\'t have access to this AI agent. Please contact your administrator.';
    } else if (error is ai_exceptions.AdminOnlyAgentException) {
      title = 'Admin Only AI Agent';
      message = 'This AI agent is restricted to administrators only.';
    }
    
    return ErrorState.fromConfig(
      type: ErrorType.aiAgentError,
      config: config,
      title: title,
      message: message,
      metadata: {'originalError': error},
    );
  }

  /// Creates an ErrorState for generic AI errors
  static ErrorState _createAIGenericError(ai_exceptions.AIApiException error) {
    final config = ErrorConfigs.getConfig(ErrorType.generic);
    return ErrorState.fromConfig(
      type: ErrorType.generic,
      config: config,
      title: 'AI Service Error',
      message: error.message.isNotEmpty ? error.message : 'An error occurred with the AI service. Please try again.',
      metadata: {'originalError': error, 'aiSpecific': true},
    );
  }

  /// Gets appropriate server error message based on status code
  static String _getServerErrorMessage(int statusCode, String originalMessage) {
    switch (statusCode) {
      case 500:
        return 'Internal server error occurred. Please try again later.';
      case 502:
        return 'Bad gateway error. The server is temporarily unavailable.';
      case 503:
        return ErrorConstants.serviceUnavailable;
      case 504:
        return ErrorConstants.gatewayTimeout;
      default:
        return originalMessage.isNotEmpty
            ? originalMessage
            : ErrorConstants.serverError;
    }
  }

  /// Gets appropriate client error message based on status code
  static String _getClientErrorMessage(
    int? statusCode,
    String originalMessage,
  ) {
    if (statusCode == null) {
      return originalMessage.isNotEmpty
          ? originalMessage
          : ErrorConstants.unknown;
    }

    switch (statusCode) {
      case 400:
        return originalMessage.isNotEmpty
            ? originalMessage
            : ErrorConstants.badRequest;
      case 403:
        return ErrorConstants.accessDenied;
      case 404:
        return ErrorConstants.notFound;
      case 422:
        return originalMessage.isNotEmpty
            ? 'Invalid data: $originalMessage'
            : ErrorConstants.badRequest;
      default:
        return originalMessage.isNotEmpty
            ? originalMessage
            : ErrorConstants.unknown;
    }
  }

  /// Handles unauthorized errors by delegating to SessionManager
  /// Uses the new SessionManager for consistent session handling
  static Future<void> handleUnauthorized(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await SessionManager.handleSessionExpiry(context, ref);
  }

  /// Shows an error snackbar with appropriate styling
  static void showErrorSnackbar(
    BuildContext context,
    String message,
    ErrorType type,
  ) {
    final config = ErrorConfigs.getConfig(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(config.icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: config.color,
        duration: ErrorConstants.snackbarDuration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Determines if an error is retryable
  static bool isRetryable(ErrorState errorState) {
    switch (errorState.type) {
      case ErrorType.unauthorized:
        return false; // Don't retry unauthorized errors
      case ErrorType.rateLimited:
      case ErrorType.networkError:
      case ErrorType.serverError:
      case ErrorType.cloudflareError:
      case ErrorType.generic:
      case ErrorType.aiSessionError:
      case ErrorType.aiVoiceError:
      case ErrorType.aiToolError:
      case ErrorType.aiAgentError:
      case ErrorType.aiWebSocketError:
        return true;
    }
  }

  /// Gets retry delay based on error type
  static Duration getRetryDelay(ErrorState errorState, int retryCount) {
    switch (errorState.type) {
      case ErrorType.rateLimited:
        // Longer delay for rate limiting
        return Duration(seconds: (retryCount + 1) * 5);
      case ErrorType.networkError:
      case ErrorType.serverError:
      case ErrorType.cloudflareError:
      case ErrorType.aiWebSocketError:
        // Exponential backoff for other retryable errors
        return Duration(seconds: (1 << retryCount).clamp(1, 30));
      case ErrorType.aiSessionError:
      case ErrorType.aiVoiceError:
      case ErrorType.aiToolError:
      case ErrorType.aiAgentError:
        // AI-specific errors use default delay
        return ErrorConstants.retryDelay;
      case ErrorType.unauthorized:
        // These errors are not retryable, but return default delay just in case
        return ErrorConstants.retryDelay;
      case ErrorType.generic:
        return ErrorConstants.retryDelay;
    }
  }

  /// Checks if the maximum retry count has been reached
  static bool hasExceededMaxRetries(int retryCount) {
    return retryCount >= ErrorConstants.maxRetries;
  }
}
