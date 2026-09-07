import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixPageTransitions —— 页面转场动画集合
/// 共享轴转场、缩放淡入转场、滑动转场
/// 用 PageRouteBuilder 实现，粉色调
/// ============================================================

/// 转场类型
enum MiuixTransitionType {
  /// 缩放淡入
  scaleFade,

  /// 从右滑入
  slideRight,

  /// 从下滑入
  slideUp,

  /// 从左滑入
  slideLeft,

  /// 共享轴（X轴）
  sharedAxisX,

  /// 共享轴（Y轴）
  sharedAxisY,

  /// 淡入
  fade,
}

/// Miuix 页面转场工具类
class MiuixPageTransitions {
  MiuixPageTransitions._();

  /// 创建缩放淡入转场路由
  static Route<T> scaleFade<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? MiuixDuration.page,
      reverseTransitionDuration: duration ?? MiuixDuration.page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final double scale =
            Curves.elasticOut.transform(animation.value).clamp(0.0, 1.05);
        final double opacity = Curves.easeOut.transform(animation.value);

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
    );
  }

  /// 创建从右滑入转场路由
  static Route<T> slideRight<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? MiuixDuration.page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final Offset begin = const Offset(1.0, 0.0);
        final Offset end = Offset.zero;
        final Animatable<Offset> tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: Curves.easeOutCubic));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// 创建从下滑入转场路由
  static Route<T> slideUp<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final Offset begin = const Offset(0.0, 1.0);
        final Offset end = Offset.zero;
        final Animatable<Offset> tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: Curves.elasticOut));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// 创建共享轴 X 转场路由（旧页面左移淡出，新页面右移淡入）
  static Route<T> sharedAxisX<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? MiuixDuration.page,
      reverseTransitionDuration: duration ?? MiuixDuration.page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final double slide =
            Tween<double>(begin: 30, end: 0).evaluate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
        final double opacity = Curves.easeOut.transform(animation.value);

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(slide, 0),
            child: child,
          ),
        );
      },
    );
  }

  /// 创建共享轴 Y 转场路由
  static Route<T> sharedAxisY<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? MiuixDuration.page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final double slide =
            Tween<double>(begin: 30, end: 0).evaluate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
        final double opacity = Curves.easeOut.transform(animation.value);

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, slide),
            child: child,
          ),
        );
      },
    );
  }

  /// 创建淡入转场路由
  static Route<T> fade<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? MiuixDuration.normal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        );
      },
    );
  }

  /// 根据类型创建转场路由
  static Route<T> build<T>(
    Widget page, {
    MiuixTransitionType type = MiuixTransitionType.scaleFade,
    Duration? duration,
  }) {
    switch (type) {
      case MiuixTransitionType.scaleFade:
        return scaleFade<T>(page, duration: duration);
      case MiuixTransitionType.slideRight:
        return slideRight<T>(page, duration: duration);
      case MiuixTransitionType.slideUp:
        return slideUp<T>(page, duration: duration);
      case MiuixTransitionType.slideLeft:
        return _slideLeft<T>(page, duration: duration);
      case MiuixTransitionType.sharedAxisX:
        return sharedAxisX<T>(page, duration: duration);
      case MiuixTransitionType.sharedAxisY:
        return sharedAxisY<T>(page, duration: duration);
      case MiuixTransitionType.fade:
        return fade<T>(page, duration: duration);
    }
  }

  /// 从左滑入
  static Route<T> _slideLeft<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? MiuixDuration.page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final Offset begin = const Offset(-1.0, 0.0);
        final Offset end = Offset.zero;
        final Animatable<Offset> tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }
}

/// ============================================================
/// MiuixPageRoute —— 便捷的 Miuix 风格 MaterialPageRoute 替代
/// ============================================================

/// Miuix 风格页面路由
class MiuixPageRoute<T> extends PageRouteBuilder<T> {
  MiuixPageRoute({
    required Widget page,
    MiuixTransitionType type = MiuixTransitionType.scaleFade,
    Duration? transitionDuration,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration:
              transitionDuration ?? MiuixDuration.page,
          reverseTransitionDuration:
              transitionDuration ?? MiuixDuration.page,
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            switch (type) {
              case MiuixTransitionType.scaleFade:
                final double scale = Curves.elasticOut
                    .transform(animation.value)
                    .clamp(0.0, 1.05);
                final double opacity =
                    Curves.easeOut.transform(animation.value);
                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(scale: scale, child: child),
                );
              case MiuixTransitionType.slideRight:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                );
              case MiuixTransitionType.slideUp:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.elasticOut,
                  )),
                  child: child,
                );
              case MiuixTransitionType.slideLeft:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                );
              case MiuixTransitionType.sharedAxisX:
                final double slide = Tween<double>(begin: 30, end: 0)
                    .evaluate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOutCubic));
                return Opacity(
                  opacity: Curves.easeOut.transform(animation.value),
                  child: Transform.translate(
                    offset: Offset(slide, 0),
                    child: child,
                  ),
                );
              case MiuixTransitionType.sharedAxisY:
                final double slide = Tween<double>(begin: 30, end: 0)
                    .evaluate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOutCubic));
                return Opacity(
                  opacity: Curves.easeOut.transform(animation.value),
                  child: Transform.translate(
                    offset: Offset(0, slide),
                    child: child,
                  ),
                );
              case MiuixTransitionType.fade:
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  ),
                  child: child,
                );
            }
          },
        );
}
