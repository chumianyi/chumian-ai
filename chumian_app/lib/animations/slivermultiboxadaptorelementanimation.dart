import 'package:flutter/material.dart';
import 'animation_constants.dart';

/// Sliver multi box adaptor element animation widget
class SliverMultiBoxAdaptorElementAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final VoidCallback? onComplete;
  final bool autoPlay;
  final bool repeat;
  final bool reverse;
  final double begin;
  final double end;
  final Offset? beginOffset;
  final Offset? endOffset;
  final double beginOpacity;
  final double endOpacity;
  final double beginScale;
  final double endScale;
  final double beginRotate;
  final double endRotate;
  final AlignmentGeometry alignment;
  final Clip clipBehavior;

  const SliverMultiBoxAdaptorElementAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.curve = Curves.easeInOut,
    this.onComplete,
    this.autoPlay = true,
    this.repeat = false,
    this.reverse = false,
    this.begin = 0.0,
    this.end = 1.0,
    this.beginOffset,
    this.endOffset,
    this.beginOpacity = 0.0,
    this.endOpacity = 1.0,
    this.beginScale = 0.1,
    this.endScale = 1.0,
    this.beginRotate = 0.0,
    this.endRotate = 0.0,
    this.alignment = Alignment.center,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  State<SliverMultiBoxAdaptorElementAnimation> createState() => _SliverMultiBoxAdaptorElementAnimationState();
}

class _SliverMultiBoxAdaptorElementAnimationState extends State<SliverMultiBoxAdaptorElementAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  late Animation<double> _rotate;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _animation = Tween<double>(begin: widget.begin, end: widget.end).animate(curvedAnimation);
    _opacity = Tween<double>(begin: widget.beginOpacity, end: widget.endOpacity).animate(curvedAnimation);
    _scale = Tween<double>(begin: widget.beginScale, end: widget.endScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _rotate = Tween<double>(begin: widget.beginRotate, end: widget.endRotate).animate(curvedAnimation);
    _slide = Tween<Offset>(
      begin: widget.beginOffset ?? const Offset(0, 0.3),
      end: widget.endOffset ?? Offset.zero,
    ).animate(curvedAnimation);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
        if (widget.repeat) {
          if (widget.reverse) {
            _controller.reverse();
          } else {
            _controller.forward(from: 0);
          }
        }
      } else if (status == AnimationStatus.dismissed && widget.repeat && widget.reverse) {
        _controller.forward();
      }
    });

    if (widget.autoPlay) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Plays the animation
  void play() {
    _controller.forward();
  }

  /// Reverses the animation
  void reverse() {
    _controller.reverse();
  }

  /// Resets the animation
  void reset() {
    _controller.reset();
  }

  /// Repeats the animation
  void repeat({bool reverse = false}) {
    _controller.repeat(reverse: reverse);
  }

  /// Stops the animation
  void stop() {
    _controller.stop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            alignment: widget.alignment,
            child: Transform.rotate(
              angle: _rotate.value,
              alignment: widget.alignment,
              child: SlideTransition(
                position: _slide,
                child: child,
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
