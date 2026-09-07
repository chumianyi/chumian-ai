import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixStackedCard —— Miuix 风格堆叠卡片
/// 卡片堆叠效果，拖拽切换，滑出动画，粉色渐变，类似 Tinder 卡片
/// ============================================================

/// 堆叠卡片数据
class MiuixStackedCardData {
  const MiuixStackedCardData({
    required this.id,
    this.title,
    this.description,
    this.imageUrl,
    this.color,
    this.child,
  });

  /// 唯一标识
  final String id;

  /// 标题
  final String? title;

  /// 描述
  final String? description;

  /// 图片URL
  final String? imageUrl;

  /// 背景色
  final Color? color;

  /// 自定义内容
  final Widget? child;
}

/// 滑动方向
enum MiuixSwipeDirection { left, right, up }

/// Miuix 风格堆叠卡片
///
/// 用法：
/// ```dart
/// MiuixStackedCard(
///   cards: [
///     MiuixStackedCardData(id: '1', title: '卡片1'),
///     MiuixStackedCardData(id: '2', title: '卡片2'),
///   ],
///   onSwipe: (direction, card) {},
/// )
/// ```
class MiuixStackedCard extends StatefulWidget {
  const MiuixStackedCard({
    super.key,
    required this.cards,
    this.cardHeight = 360,
    this.onSwipe,
    this.onEmpty,
    this.showActions = true,
  });

  /// 卡片列表
  final List<MiuixStackedCardData> cards;

  /// 卡片高度
  final double cardHeight;

  /// 滑动回调
  final void Function(MiuixSwipeDirection direction, MiuixStackedCardData card)?
      onSwipe;

  /// 卡片耗尽回调
  final VoidCallback? onEmpty;

  /// 是否显示操作按钮
  final bool showActions;

  @override
  State<MiuixStackedCard> createState() => _MiuixStackedCardState();
}

class _MiuixStackedCardState extends State<MiuixStackedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  int _currentIndex = 0;
  MiuixSwipeDirection? _swipeDirection;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MiuixDuration.elastic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _isDragging = true;
    _controller.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _isDragging = false;
    final velocity = details.velocity.pixelsPerSecond;
    final threshold = 100.0;

    if (_dragOffset.dx > threshold || velocity.dx > 500) {
      _swipeOut(MiuixSwipeDirection.right);
    } else if (_dragOffset.dx < -threshold || velocity.dx < -500) {
      _swipeOut(MiuixSwipeDirection.left);
    } else if (_dragOffset.dy < -threshold || velocity.dy < -500) {
      _swipeOut(MiuixSwipeDirection.up);
    } else {
      // 回弹
      _animateBack();
    }
  }

  void _swipeOut(MiuixSwipeDirection direction) {
    _swipeDirection = direction;
    final startOffset = _dragOffset;
    final endOffset = switch (direction) {
      MiuixSwipeDirection.left => const Offset(-600, 0),
      MiuixSwipeDirection.right => const Offset(600, 0),
      MiuixSwipeDirection.up => const Offset(0, -600),
    };

    _controller.reset();
    _controller.addListener(() {
      setState(() {
        _dragOffset = Offset.lerp(
          startOffset,
          endOffset,
          Curves.easeIn.transform(_controller.value),
        )!;
      });
    });
    _controller.forward().then((_) {
      if (mounted) {
        final card = widget.cards[_currentIndex];
        widget.onSwipe?.call(direction, card);
        setState(() {
          _currentIndex++;
          _dragOffset = Offset.zero;
          _swipeDirection = null;
        });
        if (_currentIndex >= widget.cards.length) {
          widget.onEmpty?.call();
        }
      }
    });
  }

  void _animateBack() {
    final startOffset = _dragOffset;
    _controller.reset();
    _controller.addListener(() {
      setState(() {
        _dragOffset = Offset.lerp(
          startOffset,
          Offset.zero,
          MiuixCurves.miuixSpring.transform(_controller.value),
        )!;
      });
    });
    _controller.forward();
  }

  void _triggerSwipe(MiuixSwipeDirection direction) {
    _swipeOut(direction);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.cardHeight,
          child: Stack(
            children: _buildStackedCards(),
          ),
        ),
        if (widget.showActions && _currentIndex < widget.cards.length)
          Padding(
            padding: const EdgeInsets.only(top: MiuixSpacing.xl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  icon: Icons.close,
                  color: MiuixColors.error,
                  onTap: () => _triggerSwipe(MiuixSwipeDirection.left),
                ),
                const SizedBox(width: MiuixSpacing.xl),
                _buildActionButton(
                  icon: Icons.star,
                  color: MiuixColors.info,
                  onTap: () => _triggerSwipe(MiuixSwipeDirection.up),
                  size: 48,
                ),
                const SizedBox(width: MiuixSpacing.xl),
                _buildActionButton(
                  icon: Icons.favorite,
                  color: MiuixColors.primary,
                  onTap: () => _triggerSwipe(MiuixSwipeDirection.right),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _buildStackedCards() {
    final visibleCards = <Widget>[];
    final maxVisible = 3;

    for (int i = math.min(_currentIndex + maxVisible - 1, widget.cards.length - 1);
        i >= _currentIndex;
        i--) {
      final stackIndex = i - _currentIndex;
      final card = widget.cards[i];
      final isTop = stackIndex == 0;

      visibleCards.add(
        AnimatedPositioned(
          duration: _isDragging ? Duration.zero : MiuixDuration.normal,
          curve: MiuixCurves.miuixSpring,
          top: stackIndex * 12.0,
          left: stackIndex * 8.0,
          right: stackIndex * 8.0,
          bottom: -stackIndex * 12.0,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translate(
                isTop ? _dragOffset.dx : 0,
                isTop ? _dragOffset.dy : 0,
              )
              ..rotateZ(
                isTop ? _dragOffset.dx / 800 * math.pi / 12 : 0,
              )
              ..scale(1 - stackIndex * 0.05),
            child: isTop
                ? GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: _buildCard(card, isTop: true),
                  )
                : _buildCard(card, isTop: false),
          ),
        ),
      );
    }

    if (_currentIndex >= widget.cards.length) {
      visibleCards.add(
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: MiuixColors.textTertiary,
              ),
              const SizedBox(height: MiuixSpacing.md),
              const Text(
                '没有更多卡片了',
                style: TextStyle(
                  color: MiuixColors.textTertiary,
                  fontSize: MiuixFontSize.md,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return visibleCards;
  }

  Widget _buildCard(MiuixStackedCardData card, {required bool isTop}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            card.color ?? MiuixColors.primaryLight,
            (card.color ?? MiuixColors.primary).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(MiuixRadius.xl),
        boxShadow: [
          BoxShadow(
            color: (card.color ?? MiuixColors.primary).withOpacity(0.3),
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
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
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
                          fontSize: MiuixFontSize.xxl,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(color: Color(0x44000000), blurRadius: 4),
                          ],
                        ),
                      ),
                    if (card.description != null) ...[
                      const SizedBox(height: MiuixSpacing.sm),
                      Text(
                        card.description!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: MiuixFontSize.md,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // 滑动指示标签
              if (isTop && _dragOffset.dx.abs() > 40)
                Positioned(
                  top: MiuixSpacing.lg,
                  left: _dragOffset.dx > 0 ? MiuixSpacing.lg : null,
                  right: _dragOffset.dx < 0 ? MiuixSpacing.lg : null,
                  child: Transform.rotate(
                    angle: _dragOffset.dx > 0 ? -0.3 : 0.3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MiuixSpacing.md,
                        vertical: MiuixSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _dragOffset.dx > 0
                              ? Colors.green
                              : Colors.red,
                          width: 3,
                        ),
                        borderRadius:
                            BorderRadius.circular(MiuixRadius.sm),
                      ),
                      child: Text(
                        _dragOffset.dx > 0 ? '喜欢' : '跳过',
                        style: TextStyle(
                          color: _dragOffset.dx > 0
                              ? Colors.green
                              : Colors.red,
                          fontSize: MiuixFontSize.lg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 56,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }
}
