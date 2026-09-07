import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================================
/// EmptySearch —— 搜索空状态组件
///
/// 粉色放大镜动画，提示文字，热门搜索标签。
/// 用于搜索无结果时的空状态展示。
/// ============================================================================
class EmptySearch extends StatefulWidget {
  /// 搜索关键词
  final String keyword;

  /// 提示标题
  final String? title;

  /// 提示副标题
  final String? subtitle;

  /// 热门搜索标签
  final List<String> hotSearches;

  /// 标签点击回调
  final ValueChanged<String>? onHotSearchTap;

  /// 清除搜索回调
  final VoidCallback? onClear;

  /// 图标大小
  final double iconSize;

  const EmptySearch({
    super.key,
    this.keyword = '',
    this.title,
    this.subtitle,
    this.hotSearches = const [],
    this.onHotSearchTap,
    this.onClear,
    this.iconSize = 80.0,
  });

  @override
  State<EmptySearch> createState() => _EmptySearchState();
}

class _EmptySearchState extends State<EmptySearch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounceAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(curve);
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 动画放大镜
            _buildAnimatedIcon(),
            const SizedBox(height: 24),
            // 标题
            Text(
              widget.title ??
                  (widget.keyword.isNotEmpty
                      ? '未找到"${widget.keyword}"相关结果'
                      : '暂无搜索结果'),
              style: TextStyle(
                fontSize: MiuixFontSize.xl,
                fontWeight: FontWeight.w600,
                color: MiuixColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // 副标题
            Text(
              widget.subtitle ?? '换个关键词试试，或看看热门搜索',
              style: TextStyle(
                fontSize: MiuixFontSize.md,
                color: MiuixColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            // 清除按钮
            if (widget.keyword.isNotEmpty && widget.onClear != null) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: widget.onClear,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: MiuixColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(MiuixRadius.pill),
                    border: Border.all(
                      color: MiuixColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh,
                          color: MiuixColors.primary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '清除搜索',
                        style: TextStyle(
                          color: MiuixColors.primary,
                          fontSize: MiuixFontSize.md,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            // 热门搜索
            if (widget.hotSearches.isNotEmpty) ...[
              const SizedBox(height: 28),
              _buildHotSearches(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // 脉冲光圈
            Container(
              width: widget.iconSize * _pulseAnimation.value,
              height: widget.iconSize * _pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MiuixColors.primary
                    .withValues(alpha: 0.1 * (1 - _bounceAnimation.value + 0.5)),
              ),
            ),
            // 放大镜图标
            Transform.translate(
              offset: Offset(
                sin(_bounceAnimation.value * pi * 2) * 8,
                cos(_bounceAnimation.value * pi * 2) * 4,
              ),
              child: Container(
                width: widget.iconSize * 0.7,
                height: widget.iconSize * 0.7,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: MiuixColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: MiuixColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.search,
                  color: Colors.white,
                  size: widget.iconSize * 0.35,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHotSearches() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_fire_department,
                color: MiuixColors.warning, size: 18),
            const SizedBox(width: 6),
            Text(
              '热门搜索',
              style: TextStyle(
                fontSize: MiuixFontSize.md,
                fontWeight: FontWeight.w600,
                color: MiuixColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: List.generate(widget.hotSearches.length, (index) {
            final isHot = index < 3;
            return GestureDetector(
              onTap: () => widget.onHotSearchTap?.call(widget.hotSearches[index]),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isHot
                      ? MiuixColors.primary.withValues(alpha: 0.08)
                      : MiuixColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(MiuixRadius.pill),
                  border: Border.all(
                    color: isHot
                        ? MiuixColors.primary.withValues(alpha: 0.2)
                        : MiuixColors.borderLight,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isHot) ...[
                      Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: index == 0
                              ? MiuixColors.error
                              : index == 1
                                  ? MiuixColors.warning
                                  : MiuixColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      widget.hotSearches[index],
                      style: TextStyle(
                        fontSize: MiuixFontSize.md,
                        color: isHot
                            ? MiuixColors.primary
                            : MiuixColors.textSecondary,
                        fontWeight:
                            isHot ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
