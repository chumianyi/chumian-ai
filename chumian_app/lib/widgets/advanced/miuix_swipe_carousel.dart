import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixSwipeCarousel —— Miuix 风格滑动卡片轮播
/// 卡片堆叠滑动，左右滑出，粉色渐变，无限循环
/// ============================================================

/// 轮播卡片数据
class MiuixSwipeCard {
  const MiuixSwipeCard({
    required this.id,
    this.title,
    this.subtitle,
    this.imageUrl,
    this.color,
    this.child,
  });

  /// 唯一标识
  final String id;

  /// 标题
  final String? title;

  /// 副标题
  final String? subtitle;

  /// 图片URL
  final String? imageUrl;

  /// 背景色
  final Color? color;

  /// 自定义内容
  final Widget? child;
}

/// Miuix 风格滑动卡片轮播
///
/// 用法：
/// ```dart
/// MiuixSwipeCarousel(
///   cards: [
///     MiuixSwipeCard(id: '1', title: '卡片1'),
///     MiuixSwipeCard(id: '2', title: '卡片2'),
///   ],
/// )
/// ```
class MiuixSwipeCarousel extends StatefulWidget {
  const MiuixSwipeCarousel({
    super.key,
    required this.cards,
    this.cardHeight = 300,
    this.cardWidth,
    this.onCardChanged,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.showIndicator = true,
  });

  /// 卡片列表
  final List<MiuixSwipeCard> cards;

  /// 卡片高度
  final double cardHeight;

  /// 卡片宽度（默认撑满）
  final double? cardWidth;

  /// 卡片变化回调
  final ValueChanged<int>? onCardChanged;

  /// 是否自动播放
  final bool autoPlay;

  /// 自动播放间隔
  final Duration autoPlayInterval;

  /// 是否显示指示器
  final bool showIndicator;

  @override
  State<MiuixSwipeCarousel> createState() => _MiuixSwipeCarouselState();
}

class _MiuixSwipeCarouselState extends State<MiuixSwipeCarousel>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPage = 0;
  double _pageOffset = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: 0,
    );
    _pageController.addListener(() {
      setState(() {
        _pageOffset = _pageController.page ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < widget.cards.length - 1) {
      _pageController.nextPage(
        duration: MiuixDuration.page,
        curve: MiuixCurves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: MiuixDuration.page,
        curve: MiuixCurves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.cardHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.cards.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              widget.onCardChanged?.call(index);
            },
            itemBuilder: (context, index) {
              final card = widget.cards[index];
              final pageDiff = _pageOffset - index;
              final scale = (1 - pageDiff.abs() * 0.1).clamp(0.85, 1.0);
              final rotation = pageDiff * 0.05;

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scale(scale)
                  ..rotateZ(rotation),
                child: _buildCard(card),
              );
            },
          ),
        ),
        if (widget.showIndicator && widget.cards.length > 1) ...[
          const SizedBox(height: MiuixSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 左箭头
              GestureDetector(
                onTap: _prevPage,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _currentPage > 0
                        ? MiuixColors.primary
                        : MiuixColors.border,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: MiuixSpacing.md),
              // 指示器
              ...List.generate(widget.cards.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: MiuixDuration.fast,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                            colors: MiuixColors.primaryGradient,
                          )
                        : null,
                    color: isActive ? null : MiuixColors.border,
                    borderRadius: BorderRadius.circular(MiuixRadius.pill),
                  ),
                );
              }),
              const SizedBox(width: MiuixSpacing.md),
              // 右箭头
              GestureDetector(
                onTap: _nextPage,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _currentPage < widget.cards.length - 1
                        ? MiuixColors.primary
                        : MiuixColors.border,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCard(MiuixSwipeCard card) {
    return Container(
      width: widget.cardWidth,
      margin: const EdgeInsets.symmetric(horizontal: MiuixSpacing.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            card.color ?? MiuixColors.primaryLight,
            (card.color ?? MiuixColors.primary).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(MiuixRadius.xl),
        boxShadow: [
          BoxShadow(
            color: (card.color ?? MiuixColors.primary).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: card.child ??
          Stack(
            children: [
              if (card.imageUrl != null)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(MiuixRadius.xl),
                    child: Image.network(
                      card.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
              // 渐变遮罩
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(MiuixRadius.xl),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ),
              // 内容
              Positioned(
                left: MiuixSpacing.lg,
                right: MiuixSpacing.lg,
                bottom: MiuixSpacing.xl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (card.title != null)
                      Text(
                        card.title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: MiuixFontSize.xl,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (card.subtitle != null) ...[
                      const SizedBox(height: MiuixSpacing.sm),
                      Text(
                        card.subtitle!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: MiuixFontSize.md,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
    );
  }
}
