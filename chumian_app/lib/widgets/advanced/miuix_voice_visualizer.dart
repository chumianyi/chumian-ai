import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixVoiceVisualizer —— Miuix 风格语音可视化
/// 实时音频柱状图，粉色渐变，圆形波形，录音动画
/// ============================================================

/// 可视化样式
enum MiuixVoiceStyle {
  /// 柱状图
  bars,

  /// 圆形波形
  circular,
}

/// Miuix 风格语音可视化
///
/// 用法：
/// ```dart
/// MiuixVoiceVisualizer(
///   isRecording: true,
///   style: MiuixVoiceStyle.bars,
/// )
/// ```
class MiuixVoiceVisualizer extends StatefulWidget {
  const MiuixVoiceVisualizer({
    super.key,
    this.isRecording = false,
    this.style = MiuixVoiceStyle.bars,
    this.barCount = 30,
    this.size = 120,
    this.amplitude = 0.5,
    this.onAmplitudeChanged,
  });

  /// 是否正在录音
  final bool isRecording;

  /// 样式
  final MiuixVoiceStyle style;

  /// 柱状图数量
  final int barCount;

  /// 尺寸
  final double size;

  /// 振幅（0-1）
  final double amplitude;

  /// 振幅变化回调（用于接入真实音频数据）
  final ValueChanged<double>? onAmplitudeChanged;

  @override
  State<MiuixVoiceVisualizer> createState() => _MiuixVoiceVisualizerState();
}

class _MiuixVoiceVisualizerState extends State<MiuixVoiceVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _amplitudeTimer;
  double _currentAmplitude = 0;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat();
    _currentAmplitude = widget.amplitude;
    if (widget.isRecording) {
      _startAmplitudeSimulation();
    }
  }

  @override
  void didUpdateWidget(MiuixVoiceVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _startAmplitudeSimulation();
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _amplitudeTimer?.cancel();
      setState(() => _currentAmplitude = 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _amplitudeTimer?.cancel();
    super.dispose();
  }

  void _startAmplitudeSimulation() {
    _amplitudeTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        if (!mounted) return;
        setState(() {
          _currentAmplitude = 0.3 + _random.nextDouble() * 0.7;
        });
        widget.onAmplitudeChanged?.call(_currentAmplitude);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.style == MiuixVoiceStyle.circular) {
      return _buildCircular();
    }
    return _buildBars();
  }

  Widget _buildBars() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size * 2, widget.size),
          painter: _VoiceBarsPainter(
            barCount: widget.barCount,
            amplitude: _currentAmplitude,
            progress: _controller.value,
          ),
        );
      },
    );
  }

  Widget _buildCircular() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _VoiceCircularPainter(
            amplitude: _currentAmplitude,
            progress: _controller.value,
          ),
          child: Center(
            child: Container(
              width: widget.size * 0.35,
              height: widget.size * 0.35,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: MiuixColors.primaryGradient,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: MiuixColors.primary.withOpacity(0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Icon(
                widget.isRecording ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: widget.size * 0.18,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 柱状图绘制器
class _VoiceBarsPainter extends CustomPainter {
  _VoiceBarsPainter({
    required this.barCount,
    required this.amplitude,
    required this.progress,
  });

  final int barCount;
  final double amplitude;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / barCount * 0.6;
    final gap = size.width / barCount;
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final x = gap * i + gap * 0.2;
      // 模拟音频波形：正弦波 + 随机
      final wave = math.sin(i * 0.5 + progress * math.pi * 4) * 0.5 + 0.5;
      final wave2 = math.sin(i * 0.3 + progress * math.pi * 6) * 0.3 + 0.7;
      final barHeight = size.height * 0.8 * amplitude * wave * wave2;

      final barRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, centerY),
          width: barWidth,
          height: barHeight.clamp(2.0, size.height * 0.9),
        ),
        const Radius.circular(3),
      );

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            MiuixColors.primaryLight,
            MiuixColors.primary,
            MiuixColors.primaryDeep,
          ],
        ).createShader(Rect.fromLTWH(x, 0, barWidth, size.height));
      canvas.drawRRect(barRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceBarsPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.amplitude != amplitude;
}

/// 圆形波形绘制器
class _VoiceCircularPainter extends CustomPainter {
  _VoiceCircularPainter({
    required this.amplitude,
    required this.progress,
  });

  final double amplitude;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.35;
    const barCount = 60;

    for (int i = 0; i < barCount; i++) {
      final angle = i * 2 * math.pi / barCount;
      final wave = math.sin(i * 0.8 + progress * math.pi * 4) * 0.5 + 0.5;
      final wave2 = math.cos(i * 0.5 + progress * math.pi * 3) * 0.3 + 0.7;
      final barLength = 8 + amplitude * 20 * wave * wave2;

      final innerPoint = center +
          Offset(
            math.cos(angle) * baseRadius,
            math.sin(angle) * baseRadius,
          );
      final outerPoint = center +
          Offset(
            math.cos(angle) * (baseRadius + barLength),
            math.sin(angle) * (baseRadius + barLength),
          );

      final paint = Paint()
        ..color = Color.lerp(
          MiuixColors.primaryLight,
          MiuixColors.primaryDeep,
          wave,
        )!
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(innerPoint, outerPoint, paint);
    }

    // 外圈光晕
    final glowPaint = Paint()
      ..color = MiuixColors.primary.withOpacity(0.15 * amplitude)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, baseRadius + 25, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _VoiceCircularPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.amplitude != amplitude;
}

/// ============================================================
/// MiuixAudioWaveform —— 音频波形显示
/// 从音频数据生成的波形图
/// ============================================================
class MiuixAudioWaveform extends StatelessWidget {
  const MiuixAudioWaveform({
    super.key,
    required this.samples,
    this.height = 60,
    this.width,
    this.color = MiuixColors.primary,
    this.activeColor,
    this.progress = 1.0,
    this.barWidth = 3,
    this.barGap = 2,
  });

  /// 音频采样数据（0-1）
  final List<double> samples;

  /// 高度
  final double height;

  /// 宽度
  final double? width;

  /// 颜色
  final Color color;

  /// 已播放部分颜色
  final Color? activeColor;

  /// 播放进度（0-1）
  final double progress;

  /// 柱宽
  final double barWidth;

  /// 柱间距
  final double barGap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _AudioWaveformPainter(
          samples: samples,
          color: color,
          activeColor: activeColor ?? color,
          progress: progress,
          barWidth: barWidth,
          barGap: barGap,
        ),
      ),
    );
  }
}

class _AudioWaveformPainter extends CustomPainter {
  _AudioWaveformPainter({
    required this.samples,
    required this.color,
    required this.activeColor,
    required this.progress,
    required this.barWidth,
    required this.barGap,
  });

  final List<double> samples;
  final Color color;
  final Color activeColor;
  final double progress;
  final double barWidth;
  final double barGap;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;
    final centerY = size.height / 2;
    final totalWidth = samples.length * (barWidth + barGap);
    final scale = totalWidth > size.width
        ? size.width / totalWidth
        : 1.0;
    final activeIndex = (samples.length * progress).floor();

    for (int i = 0; i < samples.length; i++) {
      final x = i * (barWidth + barGap) * scale;
      final barHeight = samples[i].clamp(0.0, 1.0) * size.height * 0.9;
      final isActive = i <= activeIndex;

      final paint = Paint()
        ..color = isActive ? activeColor : color.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x + barWidth / 2, centerY),
            width: barWidth * scale,
            height: barHeight.clamp(2.0, size.height),
          ),
          Radius.circular(barWidth / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AudioWaveformPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.samples != samples;
}

/// ============================================================
/// MiuixRecordingIndicator —— 录音指示器
/// 红色圆点 + 录音时长 + 粉色波形
/// ============================================================
class MiuixRecordingIndicator extends StatefulWidget {
  const MiuixRecordingIndicator({
    super.key,
    this.isRecording = false,
    this.duration = Duration.zero,
    this.onStart,
    this.onStop,
  });

  final bool isRecording;
  final Duration duration;
  final VoidCallback? onStart;
  final VoidCallback? onStop;

  @override
  State<MiuixRecordingIndicator> createState() =>
      _MiuixRecordingIndicatorState();
}

class _MiuixRecordingIndicatorState extends State<MiuixRecordingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isRecording) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(MiuixRecordingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isRecording ? widget.onStop : widget.onStart,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MiuixSpacing.md,
          vertical: MiuixSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: widget.isRecording
              ? MiuixColors.error.withOpacity(0.1)
              : MiuixColors.surface,
          borderRadius: BorderRadius.circular(MiuixRadius.pill),
          border: Border.all(
            color: widget.isRecording
                ? MiuixColors.error
                : MiuixColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: widget.isRecording
                        ? MiuixColors.error
                        : MiuixColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: widget.isRecording
                        ? [
                            BoxShadow(
                              color: MiuixColors.error.withOpacity(0.3 + _pulseController.value * 0.4),
                              blurRadius: 8 + _pulseController.value * 8,
                            ),
                          ]
                        : null,
                  ),
                );
              },
            ),
            const SizedBox(width: MiuixSpacing.sm),
            Text(
              widget.isRecording
                  ? _formatDuration(widget.duration)
                  : '点击录音',
              style: TextStyle(
                color: widget.isRecording
                    ? MiuixColors.error
                    : MiuixColors.textSecondary,
                fontSize: MiuixFontSize.sm,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
