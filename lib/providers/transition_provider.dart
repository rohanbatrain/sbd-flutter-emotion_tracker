import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TransitionType {
  slideFromRight,
  slideFromLeft,
  slideFromBottom,
  slideFromTop,
  fade,
  scale,
  rotation,
  slideAndFade,
  scaleAndFade,
  pageTransition,
  customCurve,
}

class TransitionConfig {
  final TransitionType type;
  final Duration duration;
  final Duration reverseDuration;
  final Curve curve;
  final Curve? reverseCurve;

  const TransitionConfig({
    required this.type,
    this.duration = const Duration(milliseconds: 300),
    this.reverseDuration = const Duration(milliseconds: 200),
    this.curve = Curves.easeInOut,
    this.reverseCurve,
  });
}

class PageTransitionService {
  static Route<T> createRoute<T extends Object?>({
    required Widget page,
    TransitionConfig config = const TransitionConfig(type: TransitionType.slideFromRight),
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: config.duration,
      reverseTransitionDuration: config.reverseDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _buildTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
          config: config,
        );
      },
    );
  }

  static Widget _buildTransition({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    required TransitionConfig config,
  }) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: config.curve,
      reverseCurve: config.reverseCurve ?? config.curve,
    );

    switch (config.type) {
      case TransitionType.slideFromRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case TransitionType.slideFromLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case TransitionType.slideFromBottom:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case TransitionType.slideFromTop:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case TransitionType.fade:
        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );

      case TransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(curvedAnimation),
          child: child,
        );

      case TransitionType.rotation:
        return RotationTransition(
          turns: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(curvedAnimation),
          child: child,
        );

      case TransitionType.slideAndFade:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );

      case TransitionType.scaleAndFade:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );

      case TransitionType.pageTransition:
        // Modern iOS-style page transition
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final slideTween = Tween(begin: begin, end: end);
        final slideAnimation = slideTween.animate(curvedAnimation);

        return SlideTransition(
          position: slideAnimation,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(-5, 0),
                ),
              ],
            ),
            child: child,
          ),
        );

      case TransitionType.customCurve:
        // Beautiful elastic transition
        final elasticAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(elasticAnimation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
    }
  }

  // Predefined beautiful transition configs
  static const splashToAuth = TransitionConfig(
    type: TransitionType.scaleAndFade,
    duration: Duration(milliseconds: 800),
    curve: Curves.easeOutQuart,
  );

  static const splashToHome = TransitionConfig(
    type: TransitionType.slideAndFade,
    duration: Duration(milliseconds: 600),
    curve: Curves.easeOutCubic,
  );

  static const authToHome = TransitionConfig(
    type: TransitionType.pageTransition,
    duration: Duration(milliseconds: 400),
    curve: Curves.easeOut,
  );

  static const homeToSettings = TransitionConfig(
    type: TransitionType.slideFromRight,
    duration: Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );

  static const modalTransition = TransitionConfig(
    type: TransitionType.slideFromBottom,
    duration: Duration(milliseconds: 400),
    curve: Curves.easeOutCubic,
  );

  static const elasticTransition = TransitionConfig(
    type: TransitionType.customCurve,
    duration: Duration(milliseconds: 1000),
    curve: Curves.elasticOut,
  );
}

// Provider for managing global transition settings
class TransitionNotifier extends StateNotifier<TransitionConfig> {
  TransitionNotifier() : super(const TransitionConfig(type: TransitionType.slideFromRight));

  void setDefaultTransition(TransitionConfig config) {
    state = config;
  }

  void setTransitionType(TransitionType type) {
    state = TransitionConfig(
      type: type,
      duration: state.duration,
      curve: state.curve,
    );
  }

  void setTransitionDuration(Duration duration) {
    state = TransitionConfig(
      type: state.type,
      duration: duration,
      curve: state.curve,
    );
  }

  void setTransitionCurve(Curve curve) {
    state = TransitionConfig(
      type: state.type,
      duration: state.duration,
      curve: curve,
    );
  }
}

// Provider for the transition configuration
final transitionProvider = StateNotifierProvider<TransitionNotifier, TransitionConfig>((ref) {
  return TransitionNotifier();
});

// Helper extension for easy navigation with transitions
extension NavigationTransitions on NavigatorState {
  Future<T?> pushWithTransition<T extends Object?>(
    Widget page, {
    TransitionConfig? config,
    String? routeName,
  }) {
    final route = PageTransitionService.createRoute<T>(
      page: page,
      config: config ?? const TransitionConfig(type: TransitionType.slideFromRight),
      settings: routeName != null ? RouteSettings(name: routeName) : null,
    );
    return push(route);
  }

  Future<T?> pushReplacementWithTransition<T extends Object?, TO extends Object?>(
    Widget page, {
    TransitionConfig? config,
    String? routeName,
    TO? result,
  }) {
    final route = PageTransitionService.createRoute<T>(
      page: page,
      config: config ?? const TransitionConfig(type: TransitionType.slideFromRight),
      settings: routeName != null ? RouteSettings(name: routeName) : null,
    );
    return pushReplacement(route, result: result);
  }

  Future<T?> pushAndRemoveUntilWithTransition<T extends Object?>(
    Widget page,
    RoutePredicate predicate, {
    TransitionConfig? config,
    String? routeName,
  }) {
    final route = PageTransitionService.createRoute<T>(
      page: page,
      config: config ?? const TransitionConfig(type: TransitionType.slideFromRight),
      settings: routeName != null ? RouteSettings(name: routeName) : null,
    );
    return pushAndRemoveUntil(route, predicate);
  }
}
