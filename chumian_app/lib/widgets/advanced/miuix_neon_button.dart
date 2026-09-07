import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixNeonButton —— Miuix 风格霓虹按钮
/// 粉色霓虹发光效果，脉冲动画，按压缩放，暗色背景下特别明显
/// ============================================================

/// Miuix 风格霓虹按钮
///
/// 用法：
/// ```dart
/// MiuixNeonButton(
///   label: '霓虹按钮',
///   onPressed: () {},
/// )
/// ```
class MiuixNeonButton extends StatefulWidget {
  const MiuixNeonButton({
    super.key,
    required this.label,
    this.onPressed,
    this.width,
    this.height = 52,
    this.icon,
    this.neonColor = MiuixColors.primary,
    this.pulseEnabled = true,
    this.disabled = false,
  });

  /// 按钮文字
  final String label;

  /// 点击回调
  final VoidCallback? onPressed;

  /// 宽度
  final double? width;

  /// 高度
  final double height;

  /// 图标
  final IconData? icon;

  /// 霓虹颜色
  final Color neonColor;

  /// 是否启用脉冲动画
  final bool pulseEnabled;

  /// 是否禁用
  final bool disabled;

  @override
  State<MiuixNeonButton> createState() => _MiuixNeonButtonState();
}

class _MiuixNeonButtonState extends State<MiuixNeonButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: MiuixDuration.fast,
      reverseDuration: MiuixDuration.elastic,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.92)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: MiuixCurves.miuixSpring)),
        weight: 70,
      ),
    ]).animate(_scaleController);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    if (widget.pulseEnabled && !widget.disabled) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MiuixNeonButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.disabled) {
      _pulseController.stop();
    } else if (widget.pulseEnabled) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.disabled) return;
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.disabled) return;
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.disabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
        builder: (context, child) {
          final glowIntensity = widget.pulseEnabled && !widget.disabled
              ? _pulseAnimation.value
              : 1.0;
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: widget.disabled ? 0.4 : 1.0,
              child: Container(
                width: widget.width,
                height: widget.height,
                padding: const EdgeInsets.symmetric(
                    horizontal: MiuixSpacing.xl),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(MiuixRadius.pill),
                  border: Border.all(
                    color: widget.neonColor,
                    width: 2,
                  ),
                  boxShadow: [
                    // 外层霓虹光晕
                    BoxShadow(
                      color: widget.neonColor
                          .withOpacity(0.6 * glowIntensity),
                      blurRadius: 20 * glowIntensity,
                      spreadRadius: 2,
                    ),
                    // 内层霓虹光晕
                    BoxShadow(
                      color: widget.neonColor
                          .withOpacity(0.3 * glowIntensity),
                      blurRadius: 40 * glowIntensity,
                      spreadRadius: 4,
                    ),
                    // 内发光
                    BoxShadow(
                      color: widget.neonColor
                          .withOpacity(0.15),
                      blurRadius: 10,
                      spreadRadius: 1,
                      blurStyle: BlurStyle.inner,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: widget.neonColor,
                        size: 18,
                        shadows: [
                          Shadow(
                            color: widget.neonColor,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.neonColor,
                        fontSize: MiuixFontSize.md,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: widget.neonColor,
                            blurRadius: 8 * glowIntensity,
                          ),
                          Shadow(
                            color: widget.neonColor,
                            blurRadius: 16 * glowIntensity,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ============================================================
/// MiuixNeonText —— 霓虹文字效果
/// 粉色发光文字，带脉冲动画，适合暗色背景
/// ============================================================
class MiuixNeonText extends StatefulWidget {
  const MiuixNeonText(
    this.text, {
    super.key,
    this.fontSize = 24,
    this.fontWeight = FontWeight.w700,
    this.color = MiuixColors.primary,
    this.pulse = true,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final bool pulse;
  final TextAlign textAlign;

  @override
  State<MiuixNeonText> createState() => _MiuixNeonTextState();
}

class _MiuixNeonTextState extends State<MiuixNeonText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.pulse) _controller.repeat(reverse: true);
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
        final intensity = widget.pulse ? 0.5 + _controller.value * 0.5 : 1.0;
        return Text(
          widget.text,
          textAlign: widget.textAlign,
          style: TextStyle(
            fontSize: widget.fontSize,
            fontWeight: widget.fontWeight,
            color: widget.color,
            shadows: [
              Shadow(
                color: widget.color.withOpacity(intensity),
                blurRadius: 8 * intensity,
              ),
              Shadow(
                color: widget.color.withOpacity(intensity * 0.6),
                blurRadius: 16 * intensity,
              ),
              Shadow(
                color: widget.color.withOpacity(intensity * 0.3),
                blurRadius: 32 * intensity,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ============================================================
/// MiuixNeonCard —— 霓虹边框卡片
/// 粉色发光边框，带脉冲动画
/// ============================================================
class MiuixNeonCard extends StatefulWidget {
  const MiuixNeonCard({
    super.key,
    required this.child,
    this.color = MiuixColors.primary,
    this.padding = const EdgeInsets.all(MiuixSpacing.lg),
    this.borderRadius = MiuixRadius.lg,
    this.pulse = true,
    this.width,
    this.height,
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final double borderRadius;
  final bool pulse;
  final double? width;
  final double? height;

  @override
  State<MiuixNeonCard> createState() => _MiuixNeonCardState();
}

class _MiuixNeonCardState extends State<MiuixNeonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.pulse) _controller.repeat(reverse: true);
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
        final intensity = widget.pulse ? 0.4 + _controller.value * 0.6 : 1.0;
        return Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(color: widget.color, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.5 * intensity),
                blurRadius: 16 * intensity,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: widget.color.withOpacity(0.2 * intensity),
                blurRadius: 32 * intensity,
                spreadRadius: 2,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}
