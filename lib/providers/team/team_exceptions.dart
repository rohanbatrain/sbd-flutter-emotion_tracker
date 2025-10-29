/// Custom exceptions for Team API operations
/// Provides specific error types for different edge cases

/// Base class for all team-related API exceptions
class TeamApiException implements Exception {
  final String message;
  final int? statusCode;

  TeamApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// 400 - Validation Errors

class ValidationException extends TeamApiException {
  ValidationException(String message) : super(message, statusCode: 400);
}

class DuplicateWorkspaceException extends ValidationException {
  DuplicateWorkspaceException(String message) : super(message);

  /// Extract workspace name from message like "Workspace 'team-alpha' already exists"
  String? get workspaceName {
    final match = RegExp(r"Workspace '([^']+)'").firstMatch(message);
    return match?.group(1);
  }
}

class InvalidWorkspaceNameException extends ValidationException {
  InvalidWorkspaceNameException(String message) : super(message);
}

class WorkspaceLimitReachedException extends ValidationException {
  WorkspaceLimitReachedException(String message) : super(message);

  /// Extract current/max from message like "Maximum workspaces limit reached (5/5)"
  Map<String, int>? get limits {
    final match = RegExp(r'\((\d+)/(\d+)\)').firstMatch(message);
    if (match != null) {
      return {
        'current': int.parse(match.group(1) ?? '0'),
        'max': int.parse(match.group(2) ?? '0'),
      };
    }
    return null;
  }
}

/// 401 - Authentication Errors

class UnauthorizedException extends TeamApiException {
  UnauthorizedException(String message) : super(message, statusCode: 401);
}

/// 403 - Permission Errors

class PermissionDeniedException extends TeamApiException {
  PermissionDeniedException(String message) : super(message, statusCode: 403);
}

class NotWorkspaceAdminException extends PermissionDeniedException {
  NotWorkspaceAdminException(String message) : super(message);
}

class NotWorkspaceMemberException extends PermissionDeniedException {
  NotWorkspaceMemberException(String message) : super(message);
}

/// 404 - Not Found Errors

class NotFoundException extends TeamApiException {
  NotFoundException(String message) : super(message, statusCode: 404);
}

class WorkspaceNotFoundException extends NotFoundException {
  WorkspaceNotFoundException(String message) : super(message);
}

class MemberNotFoundException extends NotFoundException {
  MemberNotFoundException(String message) : super(message);
}

class WalletNotFoundException extends NotFoundException {
  WalletNotFoundException(String message) : super(message);
}

/// 409 - Conflict Errors

class ConflictException extends TeamApiException {
  ConflictException(String message) : super(message, statusCode: 409);
}

class MemberAlreadyExistsException extends ConflictException {
  MemberAlreadyExistsException(String message) : super(message);
}

/// 429 - Rate Limit Errors

class RateLimitException extends TeamApiException {
  RateLimitException(String message) : super(message, statusCode: 429);

  /// Extract retry-after seconds if provided
  int? get retryAfterSeconds {
    final match = RegExp(r'try again in (\d+)').firstMatch(message);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }
}

/// 500 - Server Errors

class ServerException extends TeamApiException {
  ServerException(String message) : super(message, statusCode: 500);
}

/// Network Errors

class NetworkException extends TeamApiException {
  NetworkException(String message) : super(message);
}

/// Wallet-specific Errors

class WalletNotInitializedException extends TeamApiException {
  WalletNotInitializedException()
    : super('Team wallet not initialized', statusCode: 404);
}

class InsufficientFundsException extends TeamApiException {
  InsufficientFundsException(String message) : super(message, statusCode: 400);

  /// Extract required/available amounts from message
  Map<String, double>? get amounts {
    final match = RegExp(
      r'(\d+(?:\.\d+)?).*?(\d+(?:\.\d+)?)',
    ).firstMatch(message);
    if (match != null) {
      return {
        'required': double.parse(match.group(1) ?? '0'),
        'available': double.parse(match.group(2) ?? '0'),
      };
    }
    return null;
  }
}

class WalletFrozenException extends TeamApiException {
  WalletFrozenException(String message) : super(message, statusCode: 403);
}

/// Helper: Convert user-friendly error messages
class TeamErrorMessages {
  static String getUserFriendlyMessage(Exception e) {
    if (e is DuplicateWorkspaceException) {
      final name = e.workspaceName;
      if (name != null) {
        return 'A workspace named "$name" already exists. Please choose a different name.';
      }
      return 'A workspace with this name already exists. Please choose a different name.';
    } else if (e is InvalidWorkspaceNameException) {
      return 'Invalid workspace name. Use only letters, numbers, hyphens, and underscores.';
    } else if (e is WorkspaceLimitReachedException) {
      final limits = e.limits;
      if (limits != null) {
        return 'You\'ve reached the maximum number of workspaces (${limits['current']}/${limits['max']}).';
      }
      return 'You\'ve reached the maximum number of workspaces.';
    } else if (e is RateLimitException) {
      return 'You\'ve made too many requests. Please wait a moment and try again.';
    } else if (e is NotWorkspaceAdminException) {
      return 'Only workspace administrators can perform this action.';
    } else if (e is NotWorkspaceMemberException) {
      return 'You must be a member of this workspace to perform this action.';
    } else if (e is WorkspaceNotFoundException) {
      return 'Workspace not found. It may have been deleted.';
    } else if (e is MemberNotFoundException) {
      return 'Team member not found. They may have been removed.';
    } else if (e is WalletNotFoundException) {
      return 'Team wallet not found. It may not be initialized yet.';
    } else if (e is MemberAlreadyExistsException) {
      return 'This person is already a member of the workspace.';
    } else if (e is WalletNotInitializedException) {
      return 'The team wallet hasn\'t been set up yet. Ask an admin to initialize it.';
    } else if (e is InsufficientFundsException) {
      final amounts = e.amounts;
      if (amounts != null) {
        return 'Insufficient funds. Required: ${amounts['required']} SBD, Available: ${amounts['available']} SBD.';
      }
      return 'Insufficient funds in the team wallet.';
    } else if (e is WalletFrozenException) {
      return 'The team wallet is currently frozen and cannot be used.';
    } else if (e is PermissionDeniedException) {
      return 'You don\'t have permission to perform this action.';
    } else if (e is NotFoundException) {
      return 'The requested resource was not found.';
    } else if (e is UnauthorizedException) {
      return 'Your session has expired. Please log in again.';
    } else if (e is NetworkException) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (e is ServerException) {
      return 'Server error. Please try again later.';
    } else if (e is TeamApiException) {
      return e.message;
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Get a short title for the error (for dialog headers)
  static String getErrorTitle(Exception e) {
    if (e is DuplicateWorkspaceException) {
      return 'Workspace Exists';
    } else if (e is InvalidWorkspaceNameException) {
      return 'Invalid Name';
    } else if (e is WorkspaceLimitReachedException) {
      return 'Limit Reached';
    } else if (e is RateLimitException) {
      return 'Too Many Requests';
    } else if (e is PermissionDeniedException) {
      return 'Permission Denied';
    } else if (e is NotFoundException) {
      return 'Not Found';
    } else if (e is ConflictException) {
      return 'Conflict';
    } else if (e is WalletNotInitializedException) {
      return 'Wallet Not Ready';
    } else if (e is InsufficientFundsException) {
      return 'Insufficient Funds';
    } else if (e is WalletFrozenException) {
      return 'Wallet Frozen';
    } else if (e is UnauthorizedException) {
      return 'Session Expired';
    } else if (e is NetworkException) {
      return 'Network Error';
    } else if (e is ServerException) {
      return 'Server Error';
    } else {
      return 'Error';
    }
  }

  /// Check if error should trigger a retry button
  static bool shouldShowRetry(Exception e) {
    return e is NetworkException ||
        e is ServerException ||
        e is RateLimitException;
  }

  /// Check if error should redirect to login
  static bool shouldRedirectToLogin(Exception e) {
    return e is UnauthorizedException;
  }
}
