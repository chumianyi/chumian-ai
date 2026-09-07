import 'package:flutter/material.dart';

/// ============================================================================
/// GestureAnimations —— 手势动画封装
///
/// 提供拖拽缩放、双指缩放、长按放大、滑动删除、3D 倾斜跟随等
/// 手势驱动的动画封装。
/// ============================================================================

/// 可拖拽缩放组件
class DraggableScale extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final VoidCallback? onTap;

  const DraggableScale({
    super.key,
    required this.child,
    this.minScale = 0.5,
    this.maxScale = 3.0,
    this.onTap,
  });

  @override
  State<DraggableScale> createState() => _DraggableScaleState();
}

class _DraggableScaleState extends State<DraggableScale>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  double _previousScale = 1.0;
  Offset _position = Offset.zero;
  Offset _previousPosition = Offset.zero;

  void _onScaleStart(ScaleStartDetails details) {
    _previousScale = _scale;
    _previousPosition = details.localFocalPoint - _position;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_previousScale * details.scale)
          .clamp(widget.minScale, widget.maxScale);
      _position = details.localFocalPoint - _previousPosition;
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    // 回弹动画可以在这里添加
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      onTap: widget.onTap,
      child: Transform(
        transform: Matrix4.identity()
          ..translate(_position.dx, _position.dy)
          ..scale(_scale),
        alignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}

/// 双指缩放组件（仅缩放，不拖拽）
class PinchScale extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration animationDuration;

  const PinchScale({
    super.key,
    required this.child,
    this.minScale = 0.5,
    this.maxScale = 3.0,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<PinchScale> createState() => _PinchScaleState();
}

class _PinchScaleState extends State<PinchScale>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  double _previousScale = 1.0;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = Tween<double>(begin: 1, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScaleStart(ScaleStartDetails details) {
    _previousScale = _scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_previousScale * details.scale)
          .clamp(widget.minScale, widget.maxScale);
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    // 回弹到 1.0
    _animation = Tween<double>(begin: _scale, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    )..addListener(() {
        setState(() => _scale = _animation.value);
      });
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      child: Transform.scale(scale: _scale, child: widget.child),
    );
  }
}

/// 长按放大组件
class LongPressScale extends StatefulWidget {
  final Widget child;
  final double pressedScale;
  final Duration duration;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  const LongPressScale({
    super.key,
    required this.child,
    this.pressedScale = 1.2,
    this.duration = const Duration(milliseconds: 200),
    this.onLongPress,
    this.onTap,
  });

  @override
  State<LongPressScale> createState() => _LongPressScaleState();
}

class _LongPressScaleState extends State<LongPressScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scale = Tween<double>(begin: 1, end: widget.pressedScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPressStart: (_) {
        _controller.forward();
      },
      onLongPressEnd: (_) {
        _controller.reverse();
      },
      onLongPress: widget.onLongPress,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// 滑动删除组件
class SwipeToDismiss extends StatefulWidget {
  final Widget child;
  final Widget? background;
  final VoidCallback? onDismissed;
  final double dismissThreshold;
  final Duration duration;

  const SwipeToDismiss({
    super.key,
    required this.child,
    this.background,
    this.onDismissed,
    this.dismissThreshold = 0.4,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<SwipeToDismiss> createState() => _SwipeToDismissState();
}

class _SwipeToDismissState extends State<SwipeToDismiss>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.primaryDelta ?? 0;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final width = context.size?.width ?? 300;
    final threshold = width * widget.dismissThreshold;

    if (_dragExtent.abs() > threshold) {
      // 滑出屏幕
      final direction = _dragExtent > 0 ? 1.0 : -1.0;
      _controller.value = _dragExtent.abs() / width;
      _controller.animateTo(1.0, curve: Curves.easeOut).then((_) {
        setState(() => _isDismissed = true);
        widget.onDismissed?.call();
      });
      setState(() {
        _dragExtent = direction * width;
      });
    } else {
      // 回弹
      setState(() => _dragExtent = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        children: [
          if (widget.background != null)
            Positioned.fill(child: widget.background!),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final offset = _controller.isAnimating
                  ? _controller.value *
                      (context.size?.width ?? 300) *
                      (_dragExtent >= 0 ? 1 : -1)
                  : _dragExtent;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

/// 3D 倾斜跟随组件（根据手势倾斜）
class TiltGesture extends StatefulWidget {
  final Widget child;
  final double maxTiltX;
  final double maxTiltY;
  final Duration duration;

  const TiltGesture({
    super.key,
    required this.child,
    this.maxTiltX = 0.2,
    this.maxTiltY = 0.2,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<TiltGesture> createState() => _TiltGestureState();
}

class _TiltGestureState extends State<TiltGesture> {
  double _tiltX = 0;
  double _tiltY = 0;

  void _onPanUpdate(DragUpdateDetails details) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final position = box.globalToLocal(details.globalPosition);
    final center = box.size.center(Offset.zero);
    final dx = (position.dx - center.dx) / center.dx;
    final dy = (position.dy - center.dy) / center.dy;
    setState(() {
      _tiltX = (-dy * widget.maxTiltX).clamp(-widget.maxTiltX, widget.maxTiltX);
      _tiltY = (dx * widget.maxTiltY).clamp(-widget.maxTiltY, widget.maxTiltY);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _tiltX = 0;
      _tiltY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.002)
          ..rotateX(_tiltX)
          ..rotateY(_tiltY),
        child: widget.child,
      ),
    );
  }
}

/// 可拖拽排序项
class DraggableItem extends StatefulWidget {
  final Widget child;
  final Widget? feedback;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragCompleted;

  const DraggableItem({
    super.key,
    required this.child,
    this.feedback,
    this.onDragStarted,
    this.onDragCompleted,
  });

  @override
  State<DraggableItem> createState() => _DraggableItemState();
}

class _DraggableItemState extends State<DraggableItem> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable(
      onDragStarted: () {
        setState(() => _isDragging = true);
        widget.onDragStarted?.call();
      },
      onDragCompleted: () {
        setState(() => _isDragging = false);
        widget.onDragCompleted?.call();
      },
      onDraggableCanceled: (_, __) {
        setState(() => _isDragging = false);
      },
      feedback: widget.feedback ??
          Material(
            elevation: 8,
            color: Colors.transparent,
            child: Opacity(opacity: 0.9, child: widget.child),
          ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: widget.child,
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isDragging ? 0.3 : 1,
        child: widget.child,
      ),
    );
  }
}
