import 'package:flutter/material.dart';

/// ============================================================================
/// SlideAnimations —— 滑动动画集合
///
/// 提供 SlideInUp / SlideInDown / SlideInLeft / SlideInRight 滑动入场动画，
/// 支持视差滑动、抽屉动画、底部滑入。
/// ============================================================================

/// 从上方滑入动画
class SlideInUp extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double offset;
  final Curve curve;

  const SlideInUp({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.offset = 1.0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<SlideInUp> createState() => _SlideInUpState();
}

class _SlideInUpState extends State<SlideInUp>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _position = Tween<Offset>(
      begin: Offset(0, -widget.offset),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _position, child: widget.child);
  }
}

/// 从下方滑入动画
class SlideInDown extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double offset;
  final Curve curve;

  const SlideInDown({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.offset = 1.0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<SlideInDown> createState() => _SlideInDownState();
}

class _SlideInDownState extends State<SlideInDown>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _position = Tween<Offset>(
      begin: Offset(0, widget.offset),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _position, child: widget.child);
  }
}

/// 从左侧滑入动画
class SlideInLeft extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double offset;
  final Curve curve;

  const SlideInLeft({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.offset = 1.0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<SlideInLeft> createState() => _SlideInLeftState();
}

class _SlideInLeftState extends State<SlideInLeft>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _position = Tween<Offset>(
      begin: Offset(-widget.offset, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _position, child: widget.child);
  }
}

/// 从右侧滑入动画
class SlideInRight extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double offset;
  final Curve curve;

  const SlideInRight({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.offset = 1.0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<SlideInRight> createState() => _SlideInRightState();
}

class _SlideInRightState extends State<SlideInRight>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _position = Tween<Offset>(
      begin: Offset(widget.offset, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _position, child: widget.child);
  }
}

/// 视差滑动效果（根据滚动位置产生视差）
class ParallaxSlide extends StatelessWidget {
  final Widget child;
  final double parallaxFactor;
  final ScrollController? controller;
  final double scrollOffset;

  const ParallaxSlide({
    super.key,
    required this.child,
    this.parallaxFactor = 0.3,
    this.controller,
    this.scrollOffset = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller ?? const AlwaysScrollableScrollPhysics() as Listenable,
      builder: (context, child) {
        final offset = controller != null ? controller!.offset : scrollOffset;
        return Transform.translate(
          offset: Offset(0, offset * parallaxFactor),
          child: child,
        );
      },
      child: child,
    );
  }
}

/// 抽屉滑入动画（从左侧滑入，带背景遮罩）
class DrawerSlide extends StatefulWidget {
  final Widget child;
  final bool isOpen;
  final Duration duration;
  final double widthFactor;
  final VoidCallback? onClose;

  const DrawerSlide({
    super.key,
    required this.child,
    required this.isOpen,
    this.duration = const Duration(milliseconds: 300),
    this.widthFactor = 0.75,
    this.onClose,
  });

  @override
  State<DrawerSlide> createState() => _DrawerSlideState();
}

class _DrawerSlideState extends State<DrawerSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isOpen) _controller.value = 1;
  }

  @override
  void didUpdateWidget(DrawerSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 背景遮罩
        FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: widget.onClose,
            child: Container(color: Colors.black54),
          ),
        ),
        // 抽屉内容
        SlideTransition(
          position: _slideAnimation,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: widget.widthFactor,
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}

/// 底部滑入面板
class BottomSlideIn extends StatefulWidget {
  final Widget child;
  final bool isVisible;
  final Duration duration;
  final double heightFactor;
  final VoidCallback? onDismiss;

  const BottomSlideIn({
    super.key,
    required this.child,
    required this.isVisible,
    this.duration = const Duration(milliseconds: 300),
    this.heightFactor = 0.5,
    this.onDismiss,
  });

  @override
  State<BottomSlideIn> createState() => _BottomSlideInState();
}

class _BottomSlideInState extends State<BottomSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    if (widget.isVisible) _controller.value = 1;
  }

  @override
  void didUpdateWidget(BottomSlideIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: widget.onDismiss,
            child: Container(color: Colors.black54),
          ),
        ),
        SlideTransition(
          position: _slideAnimation,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: widget.heightFactor,
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}
