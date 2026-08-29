/// 通用动画辅助与页面转场定义。
/// 纯 UI 表现层，不涉及网络。
library;

import 'package:flutter/material.dart';
import '../theme.dart';

class AppAnimations {
  AppAnimations._();

  /// 从右下角滑入的页面转场。
  static PageRouteBuilder slideUp(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: AppDurations.page,
      reverseTransitionDuration: AppDurations.fast,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppEasings.standard,
          reverseCurve: AppEasings.decelerate,
        );
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curved);
        final opacity = Tween<double>(begin: 0, end: 1).animate(curved);
        return FadeTransition(
          opacity: opacity,
          child: SlideTransition(position: offset, child: child),
        );
      },
    );
  }

  /// 淡入淡出转场。
  static PageRouteBuilder fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: AppDurations.normal,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  /// 从底部弹起的转场。
  static PageRouteBuilder bottom(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: AppDurations.normal,
      reverseTransitionDuration: AppDurations.fast,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(curved);
        return SlideTransition(position: slide, child: child);
      },
    );
  }

  /// 缩放淡入转场（弹窗感）。
  static PageRouteBuilder zoom(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: AppDurations.normal,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        final scale = Tween<double>(begin: 0.9, end: 1.0).animate(curved);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
    );
  }
}

/// 通用数字滚动动画控件。
class CountUpText extends StatefulWidget {
  final double value;
  final String Function(double value) builder;
  final Duration duration;
  final Curve curve;
  final TextStyle? style;

  const CountUpText({
    super.key,
    required this.value,
    required this.builder,
    this.duration = AppDurations.slower,
    this.curve = AppEasings.standard,
    this.style,
  });

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  double _display = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    _animation.addListener(() {
      setState(() => _display = widget.value * _animation.value);
    });
    _controller.forward();
  }

  @override
  void didUpdateWidget(CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(widget.builder(_display), style: widget.style);
  }
}

/// 呼吸动画容器（用于等待 / 强调态）。
class BreathingContainer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const BreathingContainer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1600),
    this.minScale = 0.96,
    this.maxScale = 1.02,
  });

  @override
  State<BreathingContainer> createState() => _BreathingContainerState();
}

class _BreathingContainerState extends State<BreathingContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale =
            widget.minScale + (widget.maxScale - widget.minScale) * _controller.value;
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}

/// 渐入渐出切换（页面区块出现动效）。
class FadeInSlide extends StatefulWidget {
  final Widget child;
  final double offset;
  final Duration duration;
  final Curve curve;

  const FadeInSlide({
    super.key,
    required this.child,
    this.offset = 16,
    this.duration = AppDurations.normal,
    this.curve = AppEasings.standard,
  });

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _offset = Tween<Offset>(
      begin: Offset(0, widget.offset),
      end: Offset.zero,
    ).animate(curved);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

/// 序列交错动画（列表项依次浮现）。
class StaggeredList extends StatefulWidget {
  final List<Widget> children;
  final double offset;
  final Duration step;

  const StaggeredList({
    super.key,
    required this.children,
    this.offset = 14,
    this.step = AppDurations.fast,
  });

  @override
  State<StaggeredList> createState() => _StaggeredListState();
}

class _StaggeredListState extends State<StaggeredList> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.children.length, (_) {
      return AnimationController(
        vsync: this,
        duration: AppDurations.normal,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (var i = 0; i < _controllers.length; i++) {
        Future.delayed(widget.step * i, () {
          if (mounted) _controllers[i].forward();
        });
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(widget.children.length, (index) {
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            final value = Curves.easeOutCubic.transform(_controllers[index].value);
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, widget.offset * (1 - value)),
                child: child,
              ),
            );
          },
          child: widget.children[index],
        );
      }),
    );
  }
}

/// 心跳指示器（流式输出时的动画圆点）。
class TypingDots extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;

  const TypingDots({
    super.key,
    this.color = AppTheme.primaryColor,
    this.size = 8,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_controller.value + i * 0.2) % 1.0;
            final scale = 0.6 + 0.4 * phase;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.5 + 0.5 * phase),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// 旋转加载容器。
class Spinner extends StatelessWidget {
  final double size;
  final Color? color;

  const Spinner({super.key, this.size = 28, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
