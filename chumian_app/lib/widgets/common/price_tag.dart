import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================================
/// PriceTag —— 价格标签组件
///
/// 粉色渐变，原价删除线，折扣标签，动画效果。
/// 用于商品展示、会员购买、付费功能等需要展示价格的场景。
/// ============================================================================
class PriceTag extends StatefulWidget {
  /// 当前价格
  final double price;

  /// 原价（显示删除线）
  final double? originalPrice;

  /// 货币符号
  final String currencySymbol;

  /// 价格文字大小
  final double priceFontSize;

  /// 原价文字大小
  final double originalFontSize;

  /// 折扣（如 8.5 表示 8.5 折，null 表示自动计算）
  final double? discount;

  /// 是否显示折扣标签
  final bool showDiscount;

  /// 折扣标签位置
  final DiscountPosition discountPosition;

  /// 价格颜色
  final Color? priceColor;

  /// 是否使用渐变背景
  final bool useGradientBackground;

  /// 内边距
  final EdgeInsetsGeometry padding;

  /// 入场动画延迟
  final Duration delay;

  const PriceTag({
    super.key,
    required this.price,
    this.originalPrice,
    this.currencySymbol = '¥',
    this.priceFontSize = 24.0,
    this.originalFontSize = 13.0,
    this.discount,
    this.showDiscount = true,
    this.discountPosition = DiscountPosition.right,
    this.priceColor,
    this.useGradientBackground = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.delay = Duration.zero,
  });

  @override
  State<PriceTag> createState() => _PriceTagState();
}

/// 折扣标签位置
enum DiscountPosition {
  left,
  right,
  top,
  bottom,
}

class _PriceTagState extends State<PriceTag>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(curve);

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 计算折扣
  double? get _calculatedDiscount {
    if (widget.discount != null) return widget.discount;
    if (widget.originalPrice != null && widget.originalPrice! > 0) {
      return (widget.price / widget.originalPrice! * 10).clamp(0.1, 9.9);
    }
    return null;
  }

  /// 格式化价格
  String _formatPrice(double price) {
    if (price == price.toInt()) {
      return price.toStringAsFixed(0);
    }
    return price.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.priceColor ?? MiuixColors.primary;
    final discount = _calculatedDiscount;
    final showDiscountTag =
        widget.showDiscount && discount != null && widget.originalPrice != null;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: widget.padding,
          decoration: widget.useGradientBackground
              ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.1),
                      color.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(MiuixRadius.md),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 折扣标签（左侧）
              if (showDiscountTag &&
                  widget.discountPosition == DiscountPosition.left) ...[
                _buildDiscountTag(discount, color),
                const SizedBox(width: 8),
              ],
              // 价格主体
              _buildPriceContent(color),
              // 折扣标签（右侧）
              if (showDiscountTag &&
                  widget.discountPosition == DiscountPosition.right) ...[
                const SizedBox(width: 8),
                _buildDiscountTag(discount, color),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceContent(Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // 货币符号
        Text(
          widget.currencySymbol,
          style: TextStyle(
            color: color,
            fontSize: widget.priceFontSize * 0.6,
            fontWeight: FontWeight.w600,
          ),
        ),
        // 价格整数部分
        Text(
          _formatPrice(widget.price).split('.').first,
          style: TextStyle(
            color: color,
            fontSize: widget.priceFontSize,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
        // 价格小数部分
        if (_formatPrice(widget.price).contains('.'))
          Text(
            '.${_formatPrice(widget.price).split('.').last}',
            style: TextStyle(
              color: color,
              fontSize: widget.priceFontSize * 0.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        // 原价
        if (widget.originalPrice != null) ...[
          const SizedBox(width: 8),
          Text(
            '${widget.currencySymbol}${_formatPrice(widget.originalPrice!)}',
            style: TextStyle(
              color: MiuixColors.textTertiary,
              fontSize: widget.originalFontSize,
              decoration: TextDecoration.lineThrough,
              decorationColor: MiuixColors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDiscountTag(double? discount, Color color) {
    if (discount == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(MiuixRadius.xs),
      ),
      child: Text(
        '${discount.toStringAsFixed(1)}折',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// ============================================================================
/// PriceCard —— 价格卡片（用于会员套餐展示）
/// ============================================================================
class PriceCard extends StatefulWidget {
  final String title;
  final double price;
  final double? originalPrice;
  final String? unit;
  final List<String> features;
  final bool isRecommended;
  final String? recommendedLabel;
  final VoidCallback? onSelect;
  final bool isSelected;

  const PriceCard({
    super.key,
    required this.title,
    required this.price,
    this.originalPrice,
    this.unit = '/月',
    this.features = const [],
    this.isRecommended = false,
    this.recommendedLabel,
    this.onSelect,
    this.isSelected = false,
  });

  @override
  State<PriceCard> createState() => _PriceCardState();
}

class _PriceCardState extends State<PriceCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: widget.isRecommended
              ? const LinearGradient(
                  colors: MiuixColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: widget.isRecommended ? null : MiuixColors.surface,
          borderRadius: BorderRadius.circular(MiuixRadius.lg),
          border: Border.all(
            color: widget.isSelected
                ? MiuixColors.primary
                : widget.isRecommended
                    ? Colors.transparent
                    : MiuixColors.borderLight,
            width: widget.isSelected ? 2 : 1,
          ),
          boxShadow: widget.isRecommended
              ? [
                  BoxShadow(
                    color: MiuixColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : MiuixShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题 + 推荐标签
            Row(
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: MiuixFontSize.lg,
                    fontWeight: FontWeight.w700,
                    color: widget.isRecommended
                        ? Colors.white
                        : MiuixColors.textPrimary,
                  ),
                ),
                if (widget.isRecommended) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(MiuixRadius.pill),
                    ),
                    child: Text(
                      widget.recommendedLabel ?? '推荐',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // 价格
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '¥',
                  style: TextStyle(
                    color: widget.isRecommended
                        ? Colors.white
                        : MiuixColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.price.toStringAsFixed(0),
                  style: TextStyle(
                    color: widget.isRecommended
                        ? Colors.white
                        : MiuixColors.primary,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
                if (widget.unit != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    widget.unit!,
                    style: TextStyle(
                      color: (widget.isRecommended
                              ? Colors.white
                              : MiuixColors.textSecondary)
                          .withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
                if (widget.originalPrice != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '¥${widget.originalPrice!.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: (widget.isRecommended
                              ? Colors.white
                              : MiuixColors.textTertiary)
                          .withValues(alpha: 0.5),
                      fontSize: 13,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
            // 功能列表
            if (widget.features.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...widget.features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: widget.isRecommended
                            ? Colors.white
                            : MiuixColors.success,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 13,
                            color: widget.isRecommended
                                ? Colors.white.withValues(alpha: 0.9)
                                : MiuixColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
