import 'package:flutter/material.dart';

/// Enumeration of different error types that can occur in the application
enum ErrorType {
  unauthorized,
  rateLimited,
  networkError,
  serverError,
  cloudflareError,
  webauthn,
  generic,
}

/// Configuration for each error type including UI properties
class ErrorConfig {
  final IconData icon;
  final Color color;
  final bool showRetry;
  final bool showInfo;
  final bool autoRedirect;

  const ErrorConfig({
    required this.icon,
    required this.color,
    this.showRetry = true,
    this.showInfo = false,
    this.autoRedirect = false,
  });
}

/// Model class representing an error state with UI configuration
class ErrorState {
  final ErrorType type;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final bool showRetry;
  final bool showInfo;
  final bool autoRedirect;
  final Map<String, dynamic>? metadata;

  const ErrorState({
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    this.showRetry = true,
    this.showInfo = false,
    this.autoRedirect = false,
    this.metadata,
  });

  /// Creates an ErrorState from an ErrorConfig and messages
  factory ErrorState.fromConfig({
    required ErrorType type,
    required ErrorConfig config,
    required String title,
    required String message,
    Map<String, dynamic>? metadata,
  }) {
    return ErrorState(
      type: type,
      title: title,
      message: message,
      icon: config.icon,
      color: config.color,
      showRetry: config.showRetry,
      showInfo: config.showInfo,
      autoRedirect: config.autoRedirect,
      metadata: metadata,
    );
  }

  /// Creates a copy of this ErrorState with updated properties
  ErrorState copyWith({
    ErrorType? type,
    String? title,
    String? message,
    IconData? icon,
    Color? color,
    bool? showRetry,
    bool? showInfo,
    bool? autoRedirect,
    Map<String, dynamic>? metadata,
  }) {
    return ErrorState(
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      showRetry: showRetry ?? this.showRetry,
      showInfo: showInfo ?? this.showInfo,
      autoRedirect: autoRedirect ?? this.autoRedirect,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'ErrorState(type: $type, title: $title, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ErrorState &&
        other.type == type &&
        other.title == title &&
        other.message == message &&
        other.icon == icon &&
        other.color == color &&
        other.showRetry == showRetry &&
        other.showInfo == showInfo &&
        other.autoRedirect == autoRedirect;
  }

  @override
  int get hashCode {
    return type.hashCode ^
        title.hashCode ^
        message.hashCode ^
        icon.hashCode ^
        color.hashCode ^
        showRetry.hashCode ^
        showInfo.hashCode ^
        autoRedirect.hashCode;
  }
}

/// Predefined error configurations for different error types
class ErrorConfigs {
  static const Map<ErrorType, ErrorConfig> configs = {
    ErrorType.unauthorized: ErrorConfig(
      icon: Icons.logout,
      color: Colors.orange,
      showRetry: false,
      autoRedirect: true,
    ),
    ErrorType.rateLimited: ErrorConfig(
      icon: Icons.hourglass_empty,
      color: Colors.orange,
      showRetry: true,
      showInfo: false,
    ),
    ErrorType.networkError: ErrorConfig(
      icon: Icons.wifi_off,
      color: Colors.red,
      showRetry: true,
      showInfo: false,
    ),
    ErrorType.serverError: ErrorConfig(
      icon: Icons.error_outline,
      color: Colors.red,
      showRetry: true,
      showInfo: true,
    ),
    ErrorType.cloudflareError: ErrorConfig(
      icon: Icons.cloud_off,
      color: Colors.red,
      showRetry: true,
      showInfo: true,
    ),
    ErrorType.webauthn: ErrorConfig(
      icon: Icons.fingerprint,
      color: Colors.orange,
      showRetry: true,
      showInfo: false,
    ),
    ErrorType.generic: ErrorConfig(
      icon: Icons.error_outline,
      color: Colors.red,
      showRetry: true,
      showInfo: false,
    ),
  };

  /// Gets the configuration for a specific error type
  static ErrorConfig getConfig(ErrorType type) {
    return configs[type] ?? configs[ErrorType.generic]!;
  }
}
