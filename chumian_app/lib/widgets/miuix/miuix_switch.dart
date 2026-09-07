import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixSwitch —— Miuix 风格开关
/// 粉色轨道 + 白色滑块，滑块有弹簧动画，开启时粉色渐变
/// ============================================================

/// Miuix 风格开关
///
/// 用法：
/// ```dart
/// MiuixSwitch(
///   value: _enabled,
///   onChanged: (val) => setState(() => _enabled = val),
/// )
/// ```
class MiuixSwitch extends StatefulWidget {
  const MiuixSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.activeThumbColor,
    this.inactiveThumbColor,
    this.width = 52.0,
    this.height = 30.0,
    this.disabled = false,
  });

  /// 当前状态
  final bool value;

  /// 状态变化回调
  final ValueChanged<bool> onChanged;

  /// 开启时轨道颜色
  final Color? activeColor;

  /// 关闭时轨道颜色
  final Color? inactiveColor;

  /// 开启时滑块颜色
  final Color? activeThumbColor;

  /// 关闭时滑块颜色
  final Color? inactiveThumbColor;

  /// 宽度，默认 52
  final double width;

  /// 高度，默认 30
  final double height;

  /// 是否禁用
  final bool disabled;

  @override
  State<MiuixSwitch> createState() => _MiuixSwitchState();
}

class _MiuixSwitchState extends State<MiuixSwitch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _positionAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MiuixDuration.normal,
    );

    // 滑块位置动画：从左到右
    _positionAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: MiuixCurves.miuixSpring),
    );

    // 按压缩放动画
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.85),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.85, end: 1.0)
            .chain(CurveTween(curve: MiuixCurves.miuixSpring)),
        weight: 70,
      ),
    ]).animate(_controller);

    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant MiuixSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
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

  void _handleTap() {
    if (widget.disabled) return;
    widget.onChanged(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final double thumbSize = widget.height - 6;
    final double travelDistance = widget.width - thumbSize - 6;

    return GestureDetector(
      onTap: _handleTap,
      child: Opacity(
        opacity: widget.disabled ? 0.5 : 1.0,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                // 轨道颜色渐变过渡
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(
                      widget.inactiveColor ?? MiuixColors.border,
                      widget.activeColor ?? MiuixColors.primaryLight,
                      _positionAnimation.value,
                    )!,
                    Color.lerp(
                      widget.inactiveColor ?? MiuixColors.border,
                      widget.activeColor ?? MiuixColors.primary,
                      _positionAnimation.value,
                    )!,
                  ],
                ),
                borderRadius: BorderRadius.circular(widget.height / 2),
                boxShadow: widget.value
                    ? [
                        BoxShadow(
                          color: MiuixColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  // 滑块
                  Positioned(
                    left: 3 + _positionAnimation.value * travelDistance,
                    top: 3,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: thumbSize,
                        height: thumbSize,
                        decoration: BoxDecoration(
                          color: widget.value
                              ? (widget.activeThumbColor ?? Colors.white)
                              : (widget.inactiveThumbColor ?? Colors.white),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        // 开启时滑块内显示小对勾圆点
                        child: widget.value
                            ? Center(
                                child: Container(
                                  width: thumbSize * 0.35,
                                  height: thumbSize * 0.35,
                                  decoration: BoxDecoration(
                                    color: MiuixColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
