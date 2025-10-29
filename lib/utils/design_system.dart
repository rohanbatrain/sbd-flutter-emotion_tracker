import 'package:flutter/material.dart';

/// Design System for Emotion Tracker
/// Builds on existing theme patterns with consistent animations and components
class DesignSystem {
  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Border Radius
  static const double smallRadius = 8.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 16.0;
  static const double extraLargeRadius = 20.0;
  static const double hugeRadius = 24.0;

  // Spacing
  static const double tinySpacing = 4.0;
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;
  static const double hugeSpacing = 48.0;

  // Elevation
  static const double lowElevation = 2.0;
  static const double mediumElevation = 4.0;
  static const double highElevation = 8.0;
  static const double extraHighElevation = 12.0;

  // Opacity
  static const double lowOpacity = 0.1;
  static const double mediumOpacity = 0.2;
  static const double highOpacity = 0.3;
  static const double extraHighOpacity = 0.5;

  // Common Curves
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticOut = Curves.elasticOut;

  /// Creates a fade in animation for widgets
  static Widget fadeIn({
    required Widget child,
    Duration duration = normalAnimation,
    Curve curve = easeOut,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }

  /// Creates a slide in animation for widgets
  static Widget slideIn({
    required Widget child,
    required Offset beginOffset,
    Duration duration = normalAnimation,
    Curve curve = easeOut,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(begin: beginOffset, end: Offset.zero),
      duration: duration,
      curve: curve,
      builder: (context, offset, child) {
        return Transform.translate(offset: offset, child: child);
      },
      child: child,
    );
  }

  /// Creates a scale animation for widgets
  static Widget scaleIn({
    required Widget child,
    Duration duration = normalAnimation,
    Curve curve = elasticOut,
    double begin = 0.8,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: child,
    );
  }

  /// Creates a staggered animation for lists
  static Widget staggeredFadeIn({
    required Widget child,
    required int index,
    Duration baseDelay = Duration.zero,
    Duration staggerDelay = const Duration(milliseconds: 100),
    Duration duration = normalAnimation,
  }) {
    final delay = baseDelay + (staggerDelay * index);
    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return fadeIn(child: child, duration: duration);
        }
        return Opacity(opacity: 0, child: child);
      },
    );
  }

  /// Standard card with consistent styling
  static Card standardCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    double? elevation,
    Color? color,
    BorderRadius? borderRadius,
    BoxShadow? shadow,
  }) {
    return Card(
      elevation: elevation ?? mediumElevation,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(largeRadius),
      ),
      color: color,
      shadowColor: shadow?.color ?? Colors.black.withOpacity(mediumOpacity),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(mediumSpacing),
        child: child,
      ),
    );
  }

  /// Gradient card for special content
  static Container gradientCard({
    required Widget child,
    required List<Color> colors,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    double? elevation,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(largeRadius),
        boxShadow: elevation != null
            ? [
                BoxShadow(
                  color: colors.first.withOpacity(mediumOpacity),
                  blurRadius: elevation,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(mediumSpacing),
        child: child,
      ),
    );
  }

  /// Standard button with consistent styling
  static ElevatedButton standardButton({
    required Widget child,
    required VoidCallback? onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor ?? Colors.white,
        elevation: elevation ?? mediumElevation,
        shadowColor: backgroundColor?.withOpacity(mediumOpacity),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(mediumRadius),
        ),
        padding:
            padding ??
            const EdgeInsets.symmetric(
              horizontal: largeSpacing,
              vertical: mediumSpacing,
            ),
      ),
      child: child,
    );
  }

  /// Outlined button variant
  static OutlinedButton outlinedButton({
    required Widget child,
    required VoidCallback? onPressed,
    Color? borderColor,
    Color? foregroundColor,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor,
        side: BorderSide(color: borderColor ?? Colors.grey),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(mediumRadius),
        ),
        padding:
            padding ??
            const EdgeInsets.symmetric(
              horizontal: largeSpacing,
              vertical: mediumSpacing,
            ),
      ),
      child: child,
    );
  }

  /// Status indicator chip
  static Chip statusChip({
    required String label,
    required Color color,
    Color? textColor,
    IconData? icon,
  }) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color:
              textColor ??
              (color.computeLuminance() > 0.5 ? Colors.black : Colors.white),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      avatar: icon != null
          ? Icon(
              icon,
              color:
                  textColor ??
                  (color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white),
              size: 16,
            )
          : null,
      backgroundColor: color.withOpacity(mediumOpacity),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(hugeRadius),
        side: BorderSide(color: color.withOpacity(highOpacity)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: smallSpacing,
        vertical: tinySpacing,
      ),
    );
  }

  /// Loading indicator with consistent styling
  static Widget loadingIndicator({Color? color, double size = 24.0}) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.blue),
      ),
    );
  }

  /// Empty state widget
  static Widget emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
    Color? iconColor,
    double iconSize = 64.0,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(extraLargeSpacing),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: iconColor ?? Colors.grey),
            const SizedBox(height: mediumSpacing),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: iconColor ?? Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: smallSpacing),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: largeSpacing),
              action,
            ],
          ],
        ),
      ),
    );
  }

  /// Error state widget
  static Widget errorState({
    required String message,
    VoidCallback? onRetry,
    IconData icon = Icons.error,
    Color? iconColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(extraLargeSpacing),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: iconColor ?? Colors.red),
            const SizedBox(height: mediumSpacing),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: iconColor ?? Colors.red,
              ),
            ),
            const SizedBox(height: smallSpacing),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: largeSpacing),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Success state widget
  static Widget successState({
    required String message,
    Widget? action,
    IconData icon = Icons.check_circle,
    Color? iconColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(extraLargeSpacing),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: iconColor ?? Colors.green),
            const SizedBox(height: mediumSpacing),
            Text(
              'Success!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: iconColor ?? Colors.green,
              ),
            ),
            const SizedBox(height: smallSpacing),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: largeSpacing),
              action,
            ],
          ],
        ),
      ),
    );
  }

  /// Page transition wrapper
  static PageRouteBuilder<T> fadePageRoute<T>({
    required Widget page,
    Duration duration = normalAnimation,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: duration,
    );
  }

  /// Slide page transition
  static PageRouteBuilder<T> slidePageRoute<T>({
    required Widget page,
    Offset beginOffset = const Offset(1.0, 0.0),
    Duration duration = normalAnimation,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: easeInOut)),
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  /// Scale page transition
  static PageRouteBuilder<T> scalePageRoute<T>({
    required Widget page,
    Duration duration = normalAnimation,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(parent: animation, curve: easeOut)),
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }
}

/// Extension methods for common animations
extension AnimationExtensions on Widget {
  /// Fade in animation
  Widget fadeIn({
    Duration duration = DesignSystem.normalAnimation,
    Curve curve = DesignSystem.easeOut,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return DesignSystem.fadeIn(
      child: this,
      duration: duration,
      curve: curve,
      begin: begin,
      end: end,
    );
  }

  /// Slide in animation
  Widget slideIn({
    required Offset beginOffset,
    Duration duration = DesignSystem.normalAnimation,
    Curve curve = DesignSystem.easeOut,
  }) {
    return DesignSystem.slideIn(
      child: this,
      beginOffset: beginOffset,
      duration: duration,
      curve: curve,
    );
  }

  /// Scale in animation
  Widget scaleIn({
    Duration duration = DesignSystem.normalAnimation,
    Curve curve = DesignSystem.elasticOut,
    double begin = 0.8,
    double end = 1.0,
  }) {
    return DesignSystem.scaleIn(
      child: this,
      duration: duration,
      curve: curve,
      begin: begin,
      end: end,
    );
  }

  /// Staggered fade in for lists
  Widget staggeredFadeIn({
    required int index,
    Duration baseDelay = Duration.zero,
    Duration staggerDelay = const Duration(milliseconds: 100),
    Duration duration = DesignSystem.normalAnimation,
  }) {
    return DesignSystem.staggeredFadeIn(
      child: this,
      index: index,
      baseDelay: baseDelay,
      staggerDelay: staggerDelay,
      duration: duration,
    );
  }
}

/// Extension methods for common styling
extension StylingExtensions on BuildContext {
  /// Get theme with design system consistency
  ThemeData get theme => Theme.of(this);

  /// Get text theme
  TextTheme get textTheme => theme.textTheme;

  /// Get color scheme
  ColorScheme get colorScheme => theme.colorScheme;

  /// Standard spacing
  double get tinySpace => DesignSystem.tinySpacing;
  double get smallSpace => DesignSystem.smallSpacing;
  double get mediumSpace => DesignSystem.mediumSpacing;
  double get largeSpace => DesignSystem.largeSpacing;
  double get extraLargeSpace => DesignSystem.extraLargeSpacing;
  double get hugeSpace => DesignSystem.hugeSpacing;

  /// Standard border radius
  BorderRadius get smallRadius =>
      BorderRadius.circular(DesignSystem.smallRadius);
  BorderRadius get mediumRadius =>
      BorderRadius.circular(DesignSystem.mediumRadius);
  BorderRadius get largeRadius =>
      BorderRadius.circular(DesignSystem.largeRadius);
  BorderRadius get extraLargeRadius =>
      BorderRadius.circular(DesignSystem.extraLargeRadius);
  BorderRadius get hugeRadius => BorderRadius.circular(DesignSystem.hugeRadius);
}
