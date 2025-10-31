import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

/// AI-specific animations and haptic feedback utilities
/// Requirement 8.2: Efficient state updates and smooth animations
class AIAnimations {
  static const Duration _fastAnimation = Duration(milliseconds: 150);
  static const Duration _mediumAnimation = Duration(milliseconds: 300);
  static const Duration _slowAnimation = Duration(milliseconds: 500);

  /// Slide up animation for UI elements
  static Widget slideUp({
    required Widget child,
    Duration duration = _mediumAnimation,
    double offset = 50.0,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: offset, end: 0.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: Opacity(
            opacity: 1.0 - (value / offset),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Fade in animation for messages
  static Widget fadeIn({
    required Widget child,
    Duration duration = _fastAnimation,
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Scale animation for buttons
  static Widget scaleOnTap({
    required Widget child,
    required VoidCallback onTap,
    double scale = 0.95,
  }) {
    return TweenAnimationBuilder<double>(
      duration: _fastAnimation,
      tween: Tween(begin: 1.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTapDown: (_) => (context as Element).markNeedsBuild(),
            onTapUp: (_) => (context as Element).markNeedsBuild(),
            onTapCancel: () => (context as Element).markNeedsBuild(),
            onTap: onTap,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Typing indicator animation
  static Widget typingIndicator({
    required Color color,
    double size = 8.0,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600 + (index * 100)),
          tween: Tween(begin: 0.4, end: 1.0),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: size * 0.2),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color.withOpacity(value),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }

  /// Pulse animation for voice recording
  static Widget voicePulse({
    required Widget child,
    required bool isActive,
    Color? color,
  }) {
    if (!isActive) return child;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 1.0, end: 1.2),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (color ?? Colors.red).withOpacity(0.3),
                  blurRadius: 20 * value,
                  spreadRadius: 5 * value,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Shimmer effect for loading states
  static Widget shimmer({
    required Widget child,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween(begin: -1.0, end: 2.0),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor ?? Colors.grey[300]!,
                highlightColor ?? Colors.grey[100]!,
                baseColor ?? Colors.grey[300]!,
              ],
              stops: [
                (value - 0.3).clamp(0.0, 1.0),
                value.clamp(0.0, 1.0),
                (value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }
}

/// AI-specific haptic feedback utilities
class AIHaptics {
  /// Light tap for UI interactions
  static void lightTap() {
    HapticFeedback.lightImpact();
  }

  /// Medium tap for important actions
  static void mediumTap() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy tap for critical actions
  static void heavyTap() {
    HapticFeedback.heavyImpact();
  }

  /// Selection feedback for agent switching
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Message sent feedback
  static void messageSent() {
    HapticFeedback.mediumImpact();
  }

  /// Voice recording start/stop
  static void voiceAction() {
    HapticFeedback.heavyImpact();
  }

  /// Error feedback
  static void error() {
    HapticFeedback.vibrate();
  }
}

/// AI-specific sound effects
class AISounds {
  static final AudioPlayer _player = AudioPlayer();

  /// Message sent sound
  static void messageSent() {
    // In a real implementation, you would play a sound file
    // For now, we'll use haptic feedback as a substitute
    AIHaptics.messageSent();
  }

  /// Message received sound
  static void messageReceived() {
    // In a real implementation, you would play a sound file
    AIHaptics.lightTap();
  }

  /// Voice recording start
  static void voiceStart() {
    AIHaptics.voiceAction();
  }

  /// Voice recording stop
  static void voiceStop() {
    AIHaptics.voiceAction();
  }

  /// Error sound
  static void error() {
    AIHaptics.error();
  }

  /// Dispose audio player
  static void dispose() {
    _player.dispose();
  }
}

/// Extension methods for common animations
extension AIAnimationExtensions on Widget {
  /// Animate slide up
  Widget animateSlideUp({Duration? duration}) {
    return AIAnimations.slideUp(
      child: this,
      duration: duration ?? const Duration(milliseconds: 300),
    );
  }

  /// Animate fade in
  Widget animateFadeIn({Duration? duration}) {
    return AIAnimations.fadeIn(
      child: this,
      duration: duration ?? const Duration(milliseconds: 150),
    );
  }

  /// Animate button press
  Widget animateButtonPress({VoidCallback? onTap}) {
    return AIAnimations.scaleOnTap(
      child: this,
      onTap: onTap ?? () {},
    );
  }

  /// Add shimmer loading effect
  Widget addShimmer({Color? baseColor, Color? highlightColor}) {
    return AIAnimations.shimmer(
      child: this,
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
  }
}