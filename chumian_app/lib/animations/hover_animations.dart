import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================================
/// HoverAnimations —— 悬停动画集合
///
/// 提供多种悬停/按压交互动画：上移、放大、阴影加深、颜色变化等。
/// 支持鼠标悬停与触摸按压两种交互方式，粉色主题。
/// ============================================================================

/// 悬停上移动画
///
/// 鼠标悬停或手指按下时，子组件向上移动并伴随阴影加深。
///
/// 用法：
/// ```dart
/// HoverLift(
///   child: Container(width: 200, height: 100, color: Colors.pink),
///   onTap: () => print('tapped'),
/// )
/// ```
class HoverLift extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double liftOffset;
  final Duration duration;
  final Curve curve;
  final bool enabled;

  const HoverLift({
    super.key,
    required this.child,
    this.onTap,
    this.liftOffset = -8.0,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeOutCubic,
    this.enabled = true,
  });

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _isHovering = false;
  bool _isPressed = false;

  bool get _isActive => (_isHovering || _isPressed) && widget.enabled;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTapDown: widget.enabled
            ? (_) => setState(() => _isPressed = true)
            : null,
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _isPressed = false);
                widget.onTap?.call();
              }
            : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _isPressed = false) : null,
        child: AnimatedContainer(
          duration: widget.duration,
          curve: widget.curve,
          transform: Matrix4.translationValues(
            0,
            _isActive ? widget.liftOffset : 0,
            0,
          ),
          decoration: BoxDecoration(
            boxShadow: _isActive
                ? [
                    BoxShadow(
                      color: MiuixColors.primary.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: MiuixColors.shadowSoft,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// 悬停放大动画
class HoverScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;
  final Curve curve;
  final bool enabled;

  const HoverScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 1.05,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeOutCubic,
    this.enabled = true,
  });

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _isHovering = false;
  bool _isPressed = false;

  bool get _isActive => (_isHovering || _isPressed) && widget.enabled;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTapDown: widget.enabled
            ? (_) => setState(() => _isPressed = true)
            : null,
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _isPressed = false);
                widget.onTap?.call();
              }
            : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _isPressed = false) : null,
        child: AnimatedScale(
          scale: _isActive ? widget.scale : 1.0,
          duration: widget.duration,
          curve: widget.curve,
          child: widget.child,
        ),
      ),
    );
  }
}

/// 悬停阴影加深动画
class HoverShadow extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final List<BoxShadow> normalShadow;
  final List<BoxShadow> hoverShadow;
  final Duration duration;
  final bool enabled;

  const HoverShadow({
    super.key,
    required this.child,
    this.onTap,
    this.normalShadow = const [],
    this.hoverShadow = const [
      BoxShadow(
        color: Color(0x33FF6B9D),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
    this.duration = const Duration(milliseconds: 250),
    this.enabled = true,
  });

  @override
  State<HoverShadow> createState() => _HoverShadowState();
}

class _HoverShadowState extends State<HoverShadow> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: widget.duration,
          decoration: BoxDecoration(
            boxShadow:
                _isHovering && widget.enabled ? widget.hoverShadow : widget.normalShadow,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// 悬停颜色变化动画
class HoverColor extends StatefulWidget {
  final Widget Function(Color color) builder;
  final Color normalColor;
  final Color hoverColor;
  final VoidCallback? onTap;
  final Duration duration;
  final bool enabled;

  const HoverColor({
    super.key,
    required this.builder,
    this.normalColor = MiuixColors.primary,
    this.hoverColor = MiuixColors.primaryDark,
    this.onTap,
    this.duration = const Duration(milliseconds: 200),
    this.enabled = true,
  });

  @override
  State<HoverColor> createState() => _HoverColorState();
}

class _HoverColorState extends State<HoverColor> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: TweenAnimationBuilder<Color>(
          tween: ColorTween(
            begin: widget.normalColor,
            end: _isHovering && widget.enabled
                ? widget.hoverColor
                : widget.normalColor,
          ),
          duration: widget.duration,
          builder: (context, color, _) => widget.builder(color),
        ),
      ),
    );
  }
}

/// 组合悬停动画：上移 + 放大 + 阴影加深
class HoverCombo extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double liftOffset;
  final double scale;
  final Duration duration;
  final bool enabled;

  const HoverCombo({
    super.key,
    required this.child,
    this.onTap,
    this.liftOffset = -6.0,
    this.scale = 1.03,
    this.duration = const Duration(milliseconds: 220),
    this.enabled = true,
  });

  @override
  State<HoverCombo> createState() => _HoverComboState();
}

class _HoverComboState extends State<HoverCombo> {
  bool _isHovering = false;
  bool _isPressed = false;

  bool get _isActive => (_isHovering || _isPressed) && widget.enabled;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTapDown: widget.enabled
            ? (_) => setState(() => _isPressed = true)
            : null,
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _isPressed = false);
                widget.onTap?.call();
              }
            : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _isPressed = false) : null,
        child: AnimatedContainer(
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..translate(0.0, _isActive ? widget.liftOffset : 0.0)
            ..scale(_isActive ? widget.scale : 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MiuixRadius.md),
            boxShadow: _isActive
                ? [
                    BoxShadow(
                      color: MiuixColors.primary.withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: MiuixColors.shadowSoft,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
