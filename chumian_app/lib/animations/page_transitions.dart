import 'package:flutter/material.dart';

/// ============================================================================
/// PageTransitions —— 自定义页面转场动画集合
///
/// 提供多种 Miuix 风格的页面转场效果：
///   - 缩放淡入（ScaleFadeTransition）
///   - 共享轴（SharedAxisTransition，水平/垂直/缩放）
///   - 滑动（SlideTransition，各方向）
///   - Miuix 风格（缩放 + 淡入 + 轻微位移）
///
/// 用法：
///   Navigator.of(context).push(
///     PageTransitions.miuix(page: NextPage()),
///   );
/// ============================================================================
class PageTransitions {
  /// Miuix 风格转场：缩放淡入 + 轻微上移
  ///
  /// 新页面从 0.95 倍缩放 + 10px 偏移 + 透明，
  /// 动画到 1.0 倍 + 原位 + 不透明，曲线为 easeOutCubic。
  static Route<T> miuix<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 350),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curve),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(curve),
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// 缩放淡入转场
  static Route<T> scaleFade<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
    double beginScale = 0.9,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: beginScale, end: 1.0).animate(curve),
            child: child,
          ),
        );
      },
    );
  }

  /// 共享轴转场（水平方向）
  ///
  /// 新页面从右侧滑入，旧页面向左滑出并淡出，
  /// 模拟 Material Design 的 Shared X Axis 转场。
  static Route<T> sharedAxisHorizontal<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        );
        final secondaryCurve = CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeInOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.3, 0),
            end: Offset.zero,
          ).animate(curve),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(-0.3, 0),
              ).animate(secondaryCurve),
              child: FadeTransition(
                opacity: Tween<double>(begin: 1.0, end: 0.0)
                    .animate(secondaryCurve),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  /// 共享轴转场（垂直方向，从底部滑入）
  static Route<T> sharedAxisVertical<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(curve),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
            child: child,
          ),
        );
      },
    );
  }

  /// 滑动转场（从右侧滑入）
  static Route<T> slideFromRight<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
  }

  /// 滑动转场（从底部滑入，类似 BottomSheet）
  static Route<T> slideFromBottom<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 350),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      opaque: false,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
    );
  }

  /// 淡入淡出转场
  static Route<T> fade<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
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
}
