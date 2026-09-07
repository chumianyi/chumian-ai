import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================================
/// CountdownTimer —— 倒计时组件
///
/// 天/时/分/秒显示，粉色数字，翻转动画，结束回调。
/// 用于活动倒计时、秒杀倒计时、限时优惠等场景。
/// ============================================================================
class CountdownTimer extends StatefulWidget {
  /// 结束时间
  final DateTime endTime;

  /// 开始时间（默认当前时间）
  final DateTime? startTime;

  /// 倒计时结束回调
  final VoidCallback? onEnd;

  /// 每秒回调
  final ValueChanged<Duration>? onTick;

  /// 数字背景色
  final Color? digitBackgroundColor;

  /// 数字颜色
  final Color? digitColor;

  /// 分隔符颜色
  final Color? separatorColor;

  /// 数字大小
  final double digitSize;

  /// 数字圆角
  final double digitBorderRadius;

  /// 数字内边距
  final EdgeInsetsGeometry digitPadding;

  /// 分隔符大小
  final double separatorSize;

  /// 是否显示天
  final bool showDays;

  /// 是否显示标签（天/时/分/秒）
  final bool showLabels;

  /// 标签文字大小
  final double labelFontSize;

  /// 紧凑模式（无背景）
  final bool compact;

  const CountdownTimer({
    super.key,
    required this.endTime,
    this.startTime,
    this.onEnd,
    this.onTick,
    this.digitBackgroundColor,
    this.digitColor,
    this.separatorColor,
    this.digitSize = 20.0,
    this.digitBorderRadius = 6.0,
    this.digitPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    this.separatorSize = 18.0,
    this.showDays = true,
    this.showLabels = false,
    this.labelFontSize = 10.0,
    this.compact = false,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Duration _remaining;
  bool _isEnded = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.endTime.difference(DateTime.now());
    if (_remaining.isNegative) {
      _remaining = Duration.zero;
      _isEnded = true;
    }
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      final remaining = widget.endTime.difference(DateTime.now());
      if (remaining.isNegative || remaining.inSeconds <= 0) {
        if (!_isEnded) {
          setState(() {
            _remaining = Duration.zero;
            _isEnded = true;
          });
          widget.onEnd?.call();
        }
        return false;
      }
      setState(() => _remaining = remaining);
      widget.onTick?.call(remaining);
      return true;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 格式化数字为两位
  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.digitBackgroundColor ?? MiuixColors.primary;
    final digitColor = widget.digitColor ?? Colors.white;
    final sepColor = widget.separatorColor ?? MiuixColors.primary;

    final days = _remaining.inDays;
    final hours = _remaining.inHours.remainder(24);
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 天
        if (widget.showDays && days > 0) ...[
          _buildDigitBlock(_twoDigits(days), '天', bgColor, digitColor),
          _buildSeparator(sepColor),
        ],
        // 时
        _buildDigitBlock(_twoDigits(hours), '时', bgColor, digitColor),
        _buildSeparator(sepColor),
        // 分
        _buildDigitBlock(_twoDigits(minutes), '分', bgColor, digitColor),
        _buildSeparator(sepColor),
        // 秒
        _buildDigitBlock(_twoDigits(seconds), '秒', bgColor, digitColor),
      ],
    );
  }

  Widget _buildDigitBlock(
      String value, String label, Color bgColor, Color digitColor) {
    if (widget.compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AnimatedDigit(
            value: value,
            textStyle: TextStyle(
              color: bgColor,
              fontSize: widget.digitSize,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (widget.showLabels) ...[
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: MiuixColors.textTertiary,
                fontSize: widget.labelFontSize,
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: widget.digitPadding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [bgColor, bgColor.withValues(alpha: 0.85)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(widget.digitBorderRadius),
            boxShadow: [
              BoxShadow(
                color: bgColor.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _AnimatedDigit(
            value: value,
            textStyle: TextStyle(
              color: digitColor,
              fontSize: widget.digitSize,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
        ),
        if (widget.showLabels) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: MiuixColors.textTertiary,
              fontSize: widget.labelFontSize,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSeparator(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ':',
            style: TextStyle(
              color: color,
              fontSize: widget.separatorSize,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (widget.showLabels)
            SizedBox(height: widget.labelFontSize + 4),
        ],
      ),
    );
  }
}

/// 数字翻转动画
class _AnimatedDigit extends StatefulWidget {
  final String value;
  final TextStyle textStyle;

  const _AnimatedDigit({
    required this.value,
    required this.textStyle,
  });

  @override
  State<_AnimatedDigit> createState() => _AnimatedDigitState();
}

class _AnimatedDigitState extends State<_AnimatedDigit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String _oldValue = '';

  @override
  void initState() {
    super.initState();
    _oldValue = widget.value;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(covariant _AnimatedDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _oldValue = oldWidget.value;
      _controller.forward(from: 0);
    }
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
        final t = Curves.easeOutCubic.transform(_controller.value);
        return SizedBox(
          width: widget.textStyle.fontSize! * 1.2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 旧数字（向上滑出）
              if (_controller.value < 1.0)
                Transform.translate(
                  offset: Offset(0, -t * 20),
                  child: Opacity(
                    opacity: 1 - t,
                    child: Text(_oldValue, style: widget.textStyle),
                  ),
                ),
              // 新数字（从下滑入）
              Transform.translate(
                offset: Offset(0, (1 - t) * 20),
                child: Opacity(
                  opacity: t,
                  child: Text(widget.value, style: widget.textStyle),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ============================================================================
/// CountdownBanner —— 倒计时横幅（活动顶部）
/// ============================================================================
class CountdownBanner extends StatelessWidget {
  final String title;
  final DateTime endTime;
  final IconData? icon;
  final VoidCallback? onTap;
  final double height;

  const CountdownBanner({
    super.key,
    required this.title,
    required this.endTime,
    this.icon = Icons.local_fire_department,
    this.onTap,
    this.height = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF6B9D),
              Color(0xFFFF8FB5),
              Color(0xFFFFA5C4),
            ],
          ),
          borderRadius: BorderRadius.circular(MiuixRadius.md),
          boxShadow: [
            BoxShadow(
              color: MiuixColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            CountdownTimer(
              endTime: endTime,
              compact: true,
              showDays: false,
              digitSize: 16,
              digitColor: Colors.white,
              separatorColor: Colors.white,
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
