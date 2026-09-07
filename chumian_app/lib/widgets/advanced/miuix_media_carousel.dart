import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixMediaCarousel —— Miuix 风格媒体轮播
/// 图片/视频轮播，自动播放，指示器，粉色渐变遮罩，滑动动画
/// ============================================================

/// 轮播项数据
class MiuixCarouselItem {
  const MiuixCarouselItem({
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.onTap,
  });

  /// 图片URL
  final String imageUrl;

  /// 标题
  final String? title;

  /// 副标题
  final String? subtitle;

  /// 点击回调
  final VoidCallback? onTap;
}

/// Miuix 风格媒体轮播
///
/// 用法：
/// ```dart
/// MiuixMediaCarousel(
///   items: [
///     MiuixCarouselItem(imageUrl: '...', title: '标题1'),
///     MiuixCarouselItem(imageUrl: '...', title: '标题2'),
///   ],
/// )
/// ```
class MiuixMediaCarousel extends StatefulWidget {
  const MiuixMediaCarousel({
    super.key,
    required this.items,
    this.height = 200,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.showIndicator = true,
    this.showOverlay = true,
    this.onPageChanged,
    this.viewportFraction = 1.0,
    this.borderRadius = MiuixRadius.lg,
  });

  /// 轮播项列表
  final List<MiuixCarouselItem> items;

  /// 高度
  final double height;

  /// 是否自动播放
  final bool autoPlay;

  /// 自动播放间隔
  final Duration autoPlayInterval;

  /// 是否显示指示器
  final bool showIndicator;

  /// 是否显示文字遮罩
  final bool showOverlay;

  /// 页面变化回调
  final ValueChanged<int>? onPageChanged;

  /// 视口比例（<1 时显示相邻卡片）
  final double viewportFraction;

  /// 圆角
  final double borderRadius;

  @override
  State<MiuixMediaCarousel> createState() => _MiuixMediaCarouselState();
}

class _MiuixMediaCarouselState extends State<MiuixMediaCarousel> {
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: widget.viewportFraction,
    );
    if (widget.autoPlay && widget.items.length > 1) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(widget.autoPlayInterval, (_) {
      if (_currentPage < widget.items.length - 1) {
        _pageController.nextPage(
          duration: MiuixDuration.page,
          curve: MiuixCurves.easeInOut,
        );
      } else {
        _pageController.animateToPage(
          0,
          duration: MiuixDuration.page,
          curve: MiuixCurves.easeInOut,
        );
      }
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.items.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              widget.onPageChanged?.call(index);
            },
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = (_pageController.page ?? index) - index;
                    value = (1 - (value.abs() * 0.1)).clamp(0.8, 1.0);
                  }
                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * widget.height,
                      child: child,
                    ),
                  );
                },
                child: _buildCarouselCard(item),
              );
            },
          ),
          // 指示器
          if (widget.showIndicator && widget.items.length > 1)
            Positioned(
              bottom: MiuixSpacing.md,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.items.length, (index) {
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
                      color: isActive ? null : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(MiuixRadius.pill),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCarouselCard(MiuixCarouselItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: widget.viewportFraction < 1 ? MiuixSpacing.sm : 0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            BoxShadow(
              color: MiuixColors.primary.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 图片
              Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: MiuixColors.surfaceVariant,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: MiuixColors.textTertiary,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
              // 粉色渐变遮罩
              if (widget.showOverlay &&
                  (item.title != null || item.subtitle != null))
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          MiuixColors.primary.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.6),
                        ],
                        stops: const [0.3, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
              // 文字内容
              if (widget.showOverlay &&
                  (item.title != null || item.subtitle != null))
                Positioned(
                  left: MiuixSpacing.lg,
                  right: MiuixSpacing.lg,
                  bottom: MiuixSpacing.xl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.title != null)
                        Text(
                          item.title!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: MiuixFontSize.xl,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(
                                color: Color(0x44000000),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      if (item.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: MiuixFontSize.sm,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
