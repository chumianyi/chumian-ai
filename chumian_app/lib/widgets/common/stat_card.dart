import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_number_ticker.dart';

/// ============================================================================
/// StatCard —— 统计卡片组件
///
/// 大数字 + 标签 + 趋势箭头 + 图标，粉色渐变背景，
/// 数字滚动动画，错落入场效果。用于数据概览、仪表盘等场景。
/// ============================================================================
class StatCard extends StatefulWidget {
  /// 数值
  final num value;

  /// 标签
  final String label;

  /// 图标
  final IconData? icon;

  /// 趋势变化百分比（正数上升，负数下降）
  final double? trend;

  /// 趋势文字
  final String? trendText;

  /// 前缀（如 ¥、$）
  final String? prefix;

  /// 后缀（如 次、个）
  final String? suffix;

  /// 小数位数
  final int decimalPlaces;

  /// 是否千分位
  final bool thousandsSeparator;

  /// 卡片宽度
  final double? width;

  /// 卡片高度
  final double? height;

  /// 入场延迟
  final Duration delay;

  /// 点击回调
  final VoidCallback? onTap;

  /// 渐变色（自定义）
  final List<Color>? gradientColors;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.trend,
    this.trendText,
    this.prefix,
    this.suffix,
    this.decimalPlaces = 0,
    this.thousandsSeparator = true,
    this.width,
    this.height,
    this.delay = Duration.zero,
    this.onTap,
    this.gradientColors,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(curve);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(curve);

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradientColors ?? MiuixColors.primaryGradient;
    final isUp = (widget.trend ?? 0) >= 0;
    final trendColor = isUp ? const Color(0xFF52C41A) : MiuixColors.error;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: widget.width,
              height: widget.height,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(MiuixRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: MiuixColors.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 顶部：图标 + 趋势
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.icon != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius:
                                BorderRadius.circular(MiuixRadius.sm),
                          ),
                          child: Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 20,
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      // 趋势
                      if (widget.trend != null ||
                          widget.trendText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius:
                                BorderRadius.circular(MiuixRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isUp
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                widget.trendText ??
                                    '${isUp ? '+' : ''}${(widget.trend ?? 0).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 大数字
                  MiuixNumberTicker(
                    value: widget.value,
                    prefix: widget.prefix,
                    suffix: widget.suffix,
                    decimalPlaces: widget.decimalPlaces,
                    thousandsSeparator: widget.thousandsSeparator,
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                  const SizedBox(height: 4),
                  // 标签
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: MiuixFontSize.md,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
