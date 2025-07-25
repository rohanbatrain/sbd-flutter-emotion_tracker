import 'package:flutter/material.dart';

/// Reusable widget for displaying consistent loading states across the application
/// Provides smooth transitions and RefreshIndicator compatibility
class LoadingStateWidget extends StatelessWidget {
  /// Custom loading message to display below the indicator
  final String? message;

  /// Whether to show the loading in a compact format (smaller indicator and text)
  final bool compact;

  /// Custom color for the loading indicator (defaults to theme primary color)
  final Color? color;

  /// Size of the loading indicator
  final double? size;

  /// Whether to show the loading message
  final bool showMessage;

  /// Custom widget to display instead of the default loading indicator
  final Widget? customIndicator;

  /// Duration for smooth transitions when loading state changes
  final Duration transitionDuration;

  const LoadingStateWidget({
    super.key,
    this.message,
    this.compact = false,
    this.color,
    this.size,
    this.showMessage = true,
    this.customIndicator,
    this.transitionDuration = const Duration(milliseconds: 300),
  });

  /// Factory constructor for creating a loading widget compatible with RefreshIndicator
  factory LoadingStateWidget.refresh({String? message, Color? color}) {
    return LoadingStateWidget(
      message: message ?? 'Refreshing...',
      compact: true,
      color: color,
      showMessage: false, // RefreshIndicator shows its own loading
    );
  }

  /// Factory constructor for creating a compact loading widget for inline use
  factory LoadingStateWidget.inline({
    String? message,
    Color? color,
    double? size,
  }) {
    return LoadingStateWidget(
      message: message,
      compact: true,
      color: color,
      size: size ?? 16.0,
      showMessage: message != null,
    );
  }

  /// Factory constructor for creating a full-screen loading widget
  factory LoadingStateWidget.fullScreen({String? message, Color? color}) {
    return LoadingStateWidget(
      message: message ?? 'Loading...',
      compact: false,
      color: color,
      showMessage: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = color ?? theme.colorScheme.primary;
    final indicatorSize = size ?? (compact ? 24.0 : 32.0);

    return AnimatedOpacity(
      opacity: 1.0,
      duration: transitionDuration,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(compact ? 16.0 : 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Loading Indicator
              _buildLoadingIndicator(indicatorColor, indicatorSize),

              // Loading Message
              if (showMessage && message != null) ...[
                SizedBox(height: compact ? 12.0 : 16.0),
                _buildLoadingMessage(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the loading indicator (custom or default CircularProgressIndicator)
  Widget _buildLoadingIndicator(Color indicatorColor, double indicatorSize) {
    if (customIndicator != null) {
      return customIndicator!;
    }

    return SizedBox(
      width: indicatorSize,
      height: indicatorSize,
      child: CircularProgressIndicator(
        color: indicatorColor,
        strokeWidth: compact ? 2.0 : 3.0,
      ),
    );
  }

  /// Builds the loading message text
  Widget _buildLoadingMessage(ThemeData theme) {
    return AnimatedSwitcher(
      duration: transitionDuration,
      child: Text(
        message!,
        key: ValueKey(message),
        style: (compact
                ? theme.textTheme.bodySmall
                : theme.textTheme.bodyMedium)
            ?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Extension to provide smooth loading transitions for common use cases
extension LoadingStateTransitions on Widget {
  /// Wraps the widget with smooth loading transition capabilities
  Widget withLoadingTransition({
    required bool isLoading,
    String? loadingMessage,
    bool compact = false,
    Duration transitionDuration = const Duration(milliseconds: 300),
  }) {
    return AnimatedSwitcher(
      duration: transitionDuration,
      child:
          isLoading
              ? LoadingStateWidget(
                key: const ValueKey('loading'),
                message: loadingMessage,
                compact: compact,
                transitionDuration: transitionDuration,
              )
              : this,
    );
  }
}

/// Utility class for creating loading states with RefreshIndicator compatibility
class LoadingStateHelper {
  /// Creates a RefreshIndicator with consistent styling and loading behavior
  static Widget createRefreshIndicator({
    required Widget child,
    required Future<void> Function() onRefresh,
    String? refreshMessage,
    Color? color,
  }) {
    return RefreshIndicator(onRefresh: onRefresh, color: color, child: child);
  }

  /// Creates a loading overlay that can be shown over existing content
  static Widget createLoadingOverlay({
    required Widget child,
    required bool isLoading,
    String? loadingMessage,
    Color? backgroundColor,
    Color? indicatorColor,
  }) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.black.withValues(alpha: 0.3),
            child: LoadingStateWidget(
              message: loadingMessage,
              color: indicatorColor,
            ),
          ),
      ],
    );
  }

  /// Creates a loading button that shows loading state when pressed
  static Widget createLoadingButton({
    required String text,
    required VoidCallback? onPressed,
    required bool isLoading,
    String? loadingText,
    IconData? icon,
    ButtonStyle? style,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child:
          isLoading
              ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(loadingText ?? 'Loading...'),
                ],
              )
              : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
                  Text(text),
                ],
              ),
    );
  }
}
