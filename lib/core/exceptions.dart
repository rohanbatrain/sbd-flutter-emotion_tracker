// Centralized exception classes for error handling
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'Unauthorized']);
  @override
  String toString() => 'UnauthorizedException: $message';
}

class RateLimitException implements Exception {
  final String message;
  RateLimitException([this.message = 'Rate limit exceeded']);
  @override
  String toString() => 'RateLimitException: $message';
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class CloudflareTunnelException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;
  CloudflareTunnelException(this.message, [this.statusCode, this.body]);
  @override
  String toString() => 'CloudflareTunnelException($statusCode): $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Network error occurred']);
  @override
  String toString() => 'NetworkException: $message';
}
