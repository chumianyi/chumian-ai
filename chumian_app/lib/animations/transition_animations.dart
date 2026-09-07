import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================================
/// TransitionAnimations —— 转场动画集合
///
/// 提供多种页面/组件转场动画：淡入淡出、滑动、缩放、旋转、共享元素等。
/// 可用于页面路由切换、弹窗展示、内容切换等场景，粉色调。
/// ============================================================================

/// 淡入淡出转场
class FadeTransitionPage extends PageRouteBuilder {
  final Widget page;
  final Duration duration;

  FadeTransitionPage({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
}

/// 滑动转场（从右侧滑入）
class SlideRightTransitionPage extends PageRouteBuilder {
  final Widget page;
  final Duration duration;

  SlideRightTransitionPage({
    required this.page,
    this.duration = const Duration(milliseconds: 350),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(curve),
              child: child,
            );
          },
        );
}

/// 底部滑入转场（Modal 风格）
class SlideUpTransitionPage extends PageRouteBuilder {
  final Widget page;
  final Duration duration;

  SlideUpTransitionPage({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          barrierColor: Colors.black54,
          opaque: false,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(curve),
              child: child,
            );
          },
        );
}

/// 缩放转场
class ScaleTransitionPage extends PageRouteBuilder {
  final Widget page;
  final Duration duration;

  ScaleTransitionPage({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(curve),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        );
}

/// 旋转缩放转场
class RotateScaleTransitionPage extends PageRouteBuilder {
  final Widget page;
  final Duration duration;

  RotateScaleTransitionPage({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return RotationTransition(
              turns: Tween<double>(begin: -0.1, end: 0.0).animate(curve),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(curve),
                child: FadeTransition(opacity: animation, child: child),
              ),
            );
          },
        );
}

/// 共享元素转场封装
class SharedElementTransition extends StatelessWidget {
  final String tag;
  final Widget child;
  final Duration duration;

  const SharedElementTransition({
    super.key,
    required this.tag,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      transitionOnUserGestures: true,
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        );
        return AnimatedBuilder(
          animation: curve,
          builder: (context, child) {
            return Material(
              color: Colors.transparent,
              child: child,
            );
          },
          child: toHeroContext.widget,
        );
      },
      child: child,
    );
  }
}

/// 内容切换动画（淡入淡出 + 缩放，用于 Tab 切换）
class AnimatedContentSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const AnimatedContentSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: curve),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// 粉色渐变遮罩转场（页面进入时粉色渐变覆盖后淡出）
class PinkMaskTransitionPage extends PageRouteBuilder {
  final Widget page;
  final Duration duration;

  PinkMaskTransitionPage({
    required this.page,
    this.duration = const Duration(milliseconds: 500),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return Stack(
              children: [
                FadeTransition(opacity: animation, child: child),
                // 粉色遮罩从全屏淡出
                Positioned.fill(
                  child: IgnorePointer(
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: const Interval(0.0, 0.6,
                              curve: Curves.easeOut),
                        ),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: MiuixColors.primaryGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
}

/// 展开转场（从指定位置展开，类似 Circular Reveal）
class ExpandTransitionPage extends PageRouteBuilder {
  final Widget page;
  final Duration duration;
  final Alignment beginAlignment;

  ExpandTransitionPage({
    required this.page,
    this.duration = const Duration(milliseconds: 450),
    this.beginAlignment = Alignment.center,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return ClipPath(
              clipper: _CircleRevealClipper(
                fraction: curve.value,
                center: beginAlignment,
              ),
              child: child,
            );
          },
        );
}

class _CircleRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Alignment center;

  _CircleRevealClipper({required this.fraction, required this.center});

  @override
  Path getClip(Size size) {
    final centerOffset = center.alongSize(size);
    final maxRadius = size.width + size.height;
    final radius = maxRadius * fraction;
    return Path()
      ..addOval(Rect.fromCircle(center: centerOffset, radius: radius));
  }

  @override
  bool shouldReclip(covariant _CircleRevealClipper oldClipper) {
    return oldClipper.fraction != fraction || oldClipper.center != center;
  }
}
