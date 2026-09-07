import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixSlider —— 粉色滑块
/// 轨道渐变，滑块有光晕，拖动回弹
/// ============================================================

/// Miuix 风格滑块
///
/// 用法：
/// ```dart
/// MiuixSlider(
///   value: _volume,
///   onChanged: (val) => setState(() => _volume = val),
///   min: 0,
///   max: 100,
/// )
/// ```
class MiuixSlider extends StatefulWidget {
  const MiuixSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.trackHeight = 6.0,
    this.thumbSize = 20.0,
    this.showValue = false,
    this.disabled = false,
  });

  /// 当前值
  final double value;

  /// 值变化回调
  final ValueChanged<double> onChanged;

  /// 开始拖动回调
  final ValueChanged<double>? onChangeStart;

  /// 结束拖动回调
  final ValueChanged<double>? onChangeEnd;

  /// 最小值
  final double min;

  /// 最大值
  final double max;

  /// 分段数
  final int? divisions;

  /// 标签
  final String? label;

  /// 激活颜色
  final Color? activeColor;

  /// 未激活颜色
  final Color? inactiveColor;

  /// 滑块颜色
  final Color? thumbColor;

  /// 轨道高度
  final double trackHeight;

  /// 滑块大小
  final double thumbSize;

  /// 是否显示数值
  final bool showValue;

  /// 是否禁用
  final bool disabled;

  @override
  State<MiuixSlider> createState() => _MiuixSliderState();
}

class _MiuixSliderState extends State<MiuixSlider>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: MiuixDuration.fast,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  double get _normalizedValue {
    if (widget.max == widget.min) return 0;
    return ((widget.value - widget.min) / (widget.max - widget.min))
        .clamp(0.0, 1.0);
  }

  void _handleDragStart(DragStartDetails details) {
    if (widget.disabled) return;
    setState(() => _isDragging = true);
    _glowController.forward();
    widget.onChangeStart?.call(widget.value);
  }

  void _handleDragUpdate(DragUpdateDetails details, double totalWidth) {
    if (widget.disabled) return;
    final double relative =
        (details.localPosition.dx / totalWidth).clamp(0.0, 1.0);
    double newValue = widget.min + relative * (widget.max - widget.min);

    if (widget.divisions != null) {
      final double step = (widget.max - widget.min) / widget.divisions!;
      newValue = (newValue / step).round() * step;
    }

    widget.onChanged(newValue.clamp(widget.min, widget.max));
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() => _isDragging = false);
    _glowController.reverse();
    widget.onChangeEnd?.call(widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.disabled ? 0.5 : 1.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showValue)
            Padding(
              padding: const EdgeInsets.only(bottom: MiuixSpacing.xs),
              child: Text(
                widget.label ?? widget.value.toStringAsFixed(0),
                style: TextStyle(
                  color: MiuixColors.primary,
                  fontSize: MiuixFontSize.sm,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final double totalWidth = constraints.maxWidth;
              final double thumbPos =
                  _normalizedValue * (totalWidth - widget.thumbSize);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: _handleDragStart,
                onHorizontalDragUpdate: (details) =>
                    _handleDragUpdate(details, totalWidth),
                onHorizontalDragEnd: _handleDragEnd,
                child: SizedBox(
                  height: widget.thumbSize + 16,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // 轨道背景
                      Container(
                        width: totalWidth,
                        height: widget.trackHeight,
                        decoration: BoxDecoration(
                          color: widget.inactiveColor ??
                              MiuixColors.border.withOpacity(0.5),
                          borderRadius:
                              BorderRadius.circular(widget.trackHeight / 2),
                        ),
                      ),
                      // 激活轨道（渐变）
                      Container(
                        width: _normalizedValue * totalWidth,
                        height: widget.trackHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.activeColor ?? MiuixColors.primaryLight,
                              widget.activeColor ?? MiuixColors.primary,
                            ],
                          ),
                          borderRadius:
                              BorderRadius.circular(widget.trackHeight / 2),
                        ),
                      ),
                      // 滑块
                      AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, child) {
                          return Positioned(
                            left: thumbPos,
                            child: Transform.scale(
                              scale: 1.0 + _glowController.value * 0.15,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          width: widget.thumbSize,
                          height: widget.thumbSize,
                          decoration: BoxDecoration(
                            color: widget.thumbColor ?? Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: MiuixColors.primary,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: MiuixColors.primary.withOpacity(0.4),
                                blurRadius: _isDragging ? 12 : 6,
                                spreadRadius: _isDragging ? 2 : 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: widget.thumbSize * 0.35,
                              height: widget.thumbSize * 0.35,
                              decoration: BoxDecoration(
                                color: MiuixColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
