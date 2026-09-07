import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixWaveform —— 语音波形动画
/// 5-7 根粉色柱体随机高度跳动
/// ============================================================

/// Miuix 语音波形动画
///
/// 用法：
/// ```dart
/// MiuixWaveform(
///   isPlaying: true,
///   barCount: 5,
/// )
/// ```
class MiuixWaveform extends StatefulWidget {
  const MiuixWaveform({
    super.key,
    this.isPlaying = true,
    this.barCount = 5,
    this.barWidth = 4.0,
    this.barSpacing = 3.0,
    this.maxHeight = 24.0,
    this.minHeight = 4.0,
    this.color,
    this.gradient,
    this.borderRadius = 2.0,
    this.duration = const Duration(milliseconds: 800),
  });

  /// 是否播放中
  final bool isPlaying;

  /// 柱体数量（5-7）
  final int barCount;

  /// 柱体宽度
  final double barWidth;

  /// 柱体间距
  final double barSpacing;

  /// 最大高度
  final double maxHeight;

  /// 最小高度
  final double minHeight;

  /// 颜色
  final Color? color;

  /// 渐变
  final Gradient? gradient;

  /// 圆角
  final double borderRadius;

  /// 动画周期
  final Duration duration;

  @override
  State<MiuixWaveform> createState() => _MiuixWaveformState();
}

class _MiuixWaveformState extends State<MiuixWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<double> _phases;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }

    // 为每根柱体生成随机相位
    _phases = List.generate(
      widget.barCount.clamp(5, 7),
      (index) => _random.nextDouble() * 2 * math.pi,
    );
  }

  @override
  void didUpdateWidget(covariant MiuixWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
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
    final int count = widget.barCount.clamp(5, 7);
    final double totalWidth =
        count * widget.barWidth + (count - 1) * widget.barSpacing;

    return SizedBox(
      width: totalWidth,
      height: widget.maxHeight,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(count, (index) {
              final double phase = _phases[index % _phases.length];
              // 正弦波计算高度
              final double t = _controller.value * 2 * math.pi;
              final double wave = math.sin(t + phase);
              final double normalized = (wave + 1) / 2; // 0-1
              final double height = widget.minHeight +
                  normalized * (widget.maxHeight - widget.minHeight);

              return Padding(
                padding: EdgeInsets.only(
                  right: index < count - 1 ? widget.barSpacing : 0,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: widget.barWidth,
                  height: widget.isPlaying ? height : widget.minHeight,
                  decoration: BoxDecoration(
                    gradient: widget.gradient ??
                        LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            widget.color ?? MiuixColors.primaryLight,
                            widget.color ?? MiuixColors.primary,
                          ],
                        ),
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.color ?? MiuixColors.primary)
                            .withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// ============================================================
/// MiuixAudioWaveform —— 带音量数据的波形
/// ============================================================

/// 音频波形（支持外部音量数据）
class MiuixAudioWaveform extends StatelessWidget {
  const MiuixAudioWaveform({
    super.key,
    required this.amplitudes,
    this.barWidth = 3.0,
    this.barSpacing = 2.0,
    this.maxHeight = 32.0,
    this.color,
    this.activeColor,
    this.activeRatio = 0.0,
    this.borderRadius = 1.5,
  });

  /// 振幅数据 0.0-1.0
  final List<double> amplitudes;

  /// 柱体宽度
  final double barWidth;

  /// 柱体间距
  final double barSpacing;

  /// 最大高度
  final double maxHeight;

  /// 未播放颜色
  final Color? color;

  /// 已播放颜色
  final Color? activeColor;

  /// 已播放比例
  final double activeRatio;

  /// 圆角
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: maxHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(amplitudes.length, (index) {
          final double amplitude = amplitudes[index].clamp(0.0, 1.0);
          final double height = 4 + amplitude * (maxHeight - 4);
          final bool isActive = index / amplitudes.length < activeRatio;

          return Padding(
            padding: EdgeInsets.only(
              right: index < amplitudes.length - 1 ? barSpacing : 0,
            ),
            child: Container(
              width: barWidth,
              height: height,
              decoration: BoxDecoration(
                color: isActive
                    ? (activeColor ?? MiuixColors.primary)
                    : (color ?? MiuixColors.border),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          );
        }),
      ),
    );
  }
}
