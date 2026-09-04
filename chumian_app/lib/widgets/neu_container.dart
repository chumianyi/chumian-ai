/// Neumorphism 容器组件。
library;

import 'package:flutter/material.dart';
import '../theme.dart';

class NeuContainer extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final bool pressed;
  final Color? color;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const NeuContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.pressed = false,
    this.color,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  State<NeuContainer> createState() => _NeuContainerState();
}

class _NeuContainerState extends State<NeuContainer> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.color ?? const Color(0xFFE8ECF0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadows = (widget.pressed || _isPressed)
        ? (isDark
            ? [
                BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(2, 2)),
                BoxShadow(color: Colors.white.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(-2, -2)),
              ]
            : NeuShadows.pressed(base))
        : (isDark
            ? [
                BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(3, 3)),
                BoxShadow(color: Colors.white.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(-3, -3)),
              ]
            : NeuShadows.raised(base));

    final container = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: widget.width,
      height: widget.height,
      padding: widget.padding,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: shadows,
      ),
      child: widget.child,
    );

    if (widget.onTap == null) return container;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap!();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: container,
    );
  }
}

/// Neumorphism 圆形按钮（点击旋转一圈）。
class NeuCircleButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final Color? color;
  final Color? iconColor;

  const NeuCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 52,
    this.color,
    this.iconColor,
  });

  @override
  State<NeuCircleButton> createState() => _NeuCircleButtonState();
}

class _NeuCircleButtonState extends State<NeuCircleButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) widget.onPressed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.color ?? const Color(0xFFE8ECF0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadows = _isPressed
        ? (isDark
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(1, 1))]
            : NeuShadows.pressed(base))
        : (isDark
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(3, 3))]
            : NeuShadows.raised(base));

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _handleTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * 2 * 3.14159,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: base,
                shape: BoxShape.circle,
                boxShadow: shadows,
              ),
              child: Icon(
                widget.icon,
                color: widget.iconColor ?? const Color(0xFFFF6B9D),
                size: widget.size * 0.42,
              ),
            ),
          );
        },
      ),
    );
  }
}
