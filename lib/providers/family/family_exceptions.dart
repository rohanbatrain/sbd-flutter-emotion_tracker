/// Custom exceptions for Family API operations
/// Provides specific error types for different edge cases

/// Base class for all family-related API exceptions
class FamilyApiException implements Exception {
  final String message;
  final int? statusCode;

  FamilyApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// 400 - Validation Errors

class ValidationException extends FamilyApiException {
  ValidationException(String message) : super(message, statusCode: 400);
}

class DuplicateInvitationException extends ValidationException {
  DuplicateInvitationException(String message) : super(message);

  /// Extract days remaining from backend message like "already has a pending invitation (expires in 5 days)"
  int? get daysRemaining {
    final match = RegExp(r'expires in (\d+) days').firstMatch(message);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }
}

class RecentlyDeclinedException extends ValidationException {
  RecentlyDeclinedException(String message) : super(message);

  /// Extract hours remaining from backend message like "Please wait 12 hours before sending another"
  int? get hoursRemaining {
    final match = RegExp(r'wait (\d+) hours').firstMatch(message);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }
}

class AlreadyMemberException extends ValidationException {
  AlreadyMemberException(String message) : super(message);
}

class SelfInviteException extends ValidationException {
  SelfInviteException(String message) : super(message);
}

class InvalidRelationshipException extends ValidationException {
  InvalidRelationshipException(String message) : super(message);
}

class FamilyLimitReachedException extends ValidationException {
  FamilyLimitReachedException(String message) : super(message);

  /// Extract current/max from message like "Maximum family members limit reached (10/10)"
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

class InvitationExpiredException extends ValidationException {
  InvitationExpiredException(String message) : super(message);
}

/// 401 - Authentication Errors

class UnauthorizedException extends FamilyApiException {
  UnauthorizedException(String message) : super(message, statusCode: 401);
}

/// 403 - Permission Errors

class PermissionDeniedException extends FamilyApiException {
  PermissionDeniedException(String message) : super(message, statusCode: 403);
}

class NotFamilyAdminException extends PermissionDeniedException {
  NotFamilyAdminException(String message) : super(message);
}

/// 404 - Not Found Errors

class NotFoundException extends FamilyApiException {
  NotFoundException(String message) : super(message, statusCode: 404);
}

class UserNotFoundException extends NotFoundException {
  UserNotFoundException(String message) : super(message);
}

class FamilyNotFoundException extends NotFoundException {
  FamilyNotFoundException(String message) : super(message);
}

class InvitationNotFoundException extends NotFoundException {
  InvitationNotFoundException(String message) : super(message);
}

/// 429 - Rate Limit Errors

class RateLimitException extends FamilyApiException {
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

class ServerException extends FamilyApiException {
  ServerException(String message) : super(message, statusCode: 500);
}

/// Network Errors

class NetworkException extends FamilyApiException {
  NetworkException(String message) : super(message);
}

/// Helper: Convert user-friendly error messages
class FamilyErrorMessages {
  static String getUserFriendlyMessage(Exception e) {
    if (e is DuplicateInvitationException) {
      final days = e.daysRemaining;
      if (days != null) {
        return 'This person already has a pending invitation that expires in $days days. Please wait for them to respond.';
      }
      return 'This person already has a pending invitation. Please wait for them to respond.';
    } else if (e is RecentlyDeclinedException) {
      final hours = e.hoursRemaining;
      if (hours != null) {
        return 'This person recently declined your invitation. Please wait $hours more hours before inviting again.';
      }
      return 'This person recently declined. Please wait 24 hours before inviting again.';
    } else if (e is AlreadyMemberException) {
      return 'This person is already a member of your family.';
    } else if (e is SelfInviteException) {
      return 'You cannot invite yourself to a family.';
    } else if (e is FamilyLimitReachedException) {
      final limits = e.limits;
      if (limits != null) {
        return 'Your family has reached the maximum member limit (${limits['current']}/${limits['max']}).';
      }
      return 'Your family has reached the maximum member limit.';
    } else if (e is InvalidRelationshipException) {
      return 'Invalid relationship type. Please select a valid relationship.';
    } else if (e is InvitationExpiredException) {
      return 'This invitation has expired and can no longer be accepted.';
    } else if (e is RateLimitException) {
      return 'You\'ve sent too many invitations. Please wait an hour and try again.';
    } else if (e is NotFamilyAdminException) {
      return 'Only family administrators can send invitations.';
    } else if (e is PermissionDeniedException) {
      return 'You don\'t have permission to perform this action.';
    } else if (e is UserNotFoundException) {
      return 'User not found. Please check the email or username.';
    } else if (e is FamilyNotFoundException) {
      return 'Family not found. It may have been deleted.';
    } else if (e is InvitationNotFoundException) {
      return 'Invitation not found. It may have been cancelled or expired.';
    } else if (e is NotFoundException) {
      return 'The requested resource was not found.';
    } else if (e is UnauthorizedException) {
      return 'Your session has expired. Please log in again.';
    } else if (e is NetworkException) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (e is ServerException) {
      return 'Server error. Please try again later.';
    } else if (e is FamilyApiException) {
      return e.message;
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Get a short title for the error (for dialog headers)
  static String getErrorTitle(Exception e) {
    if (e is DuplicateInvitationException) {
      return 'Duplicate Invitation';
    } else if (e is RecentlyDeclinedException) {
      return 'Recently Declined';
    } else if (e is AlreadyMemberException) {
      return 'Already a Member';
    } else if (e is SelfInviteException) {
      return 'Cannot Invite Yourself';
    } else if (e is FamilyLimitReachedException) {
      return 'Family Full';
    } else if (e is RateLimitException) {
      return 'Too Many Requests';
    } else if (e is PermissionDeniedException) {
      return 'Permission Denied';
    } else if (e is NotFoundException) {
      return 'Not Found';
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
