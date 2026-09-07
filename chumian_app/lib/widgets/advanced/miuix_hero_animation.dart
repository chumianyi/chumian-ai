import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixHeroAnimation —— Miuix 风格 Hero 动画封装
/// 共享元素转场，粉色光晕，飞行动画
/// ============================================================

/// Miuix 风格 Hero 动画封装
///
/// 用法：
/// ```dart
/// MiuixHeroAnimation(
///   tag: 'avatar_1',
///   child: CircleAvatar(radius: 40),
/// )
/// ```
class MiuixHeroAnimation extends StatelessWidget {
  const MiuixHeroAnimation({
    super.key,
    required this.tag,
    required this.child,
    this.flightShuttleBuilder,
    this.placeholderBuilder,
    this.createRectTween,
  });

  /// Hero 标签（源和目标必须一致）
  final Object tag;

  /// 子组件
  final Widget child;

  /// 自定义飞行组件构建器
  final HeroFlightShuttleBuilder? flightShuttleBuilder;

  /// 占位符构建器
  final HeroPlaceholderBuilder? placeholderBuilder;

  /// 自定义矩形补间
  final CreateRectTween? createRectTween;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      createRectTween: createRectTween ?? _defaultCreateRectTween,
      flightShuttleBuilder: flightShuttleBuilder ?? _defaultFlightShuttle,
      placeholderBuilder: placeholderBuilder,
      child: child,
    );
  }

  static RectTween _defaultCreateRectTween(Rect? begin, Rect? end) {
    return MaterialRectArcTween(begin: begin, end: end);
  }

  static Widget _defaultFlightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final Hero toHero = toHeroContext.widget as Hero;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final glowOpacity =
            (flightDirection == HeroFlightDirection.push ? 1 - animation.value : animation.value) * 0.5;
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: MiuixColors.primary.withValues(alpha: glowOpacity),
                blurRadius: 24 + animation.value * 16,
                spreadRadius: animation.value * 4,
              ),
            ],
          ),
          child: toHero.child,
        );
      },
    );
  }
}

/// ============================================================
/// MiuixHeroPage —— 带 Hero 转场的详情页包装
/// 提供粉色渐变背景和返回按钮
/// ============================================================
class MiuixHeroPage extends StatefulWidget {
  const MiuixHeroPage({
    super.key,
    required this.tag,
    required this.heroChild,
    required this.content,
    this.title,
    this.backgroundColor,
  });

  final Object tag;
  final Widget heroChild;
  final Widget content;
  final String? title;
  final Color? backgroundColor;

  @override
  State<MiuixHeroPage> createState() => _MiuixHeroPageState();
}

class _MiuixHeroPageState extends State<MiuixHeroPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 30),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: MiuixCurves.miuixSpring),
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? MiuixColors.background,
      body: Stack(
        children: [
          // 粉色渐变背景
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFE8F0),
                  MiuixColors.background,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 顶部导航
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MiuixSpacing.md,
                    vertical: MiuixSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius:
                                BorderRadius.circular(MiuixRadius.pill),
                            boxShadow: MiuixShadows.xs,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: MiuixColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                      if (widget.title != null) ...[
                        const SizedBox(width: MiuixSpacing.md),
                        Text(
                          widget.title!,
                          style: const TextStyle(
                            color: MiuixColors.textPrimary,
                            fontSize: MiuixFontSize.lg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: MiuixSpacing.lg),
                // Hero 元素
                MiuixHeroAnimation(
                  tag: widget.tag,
                  child: widget.heroChild,
                ),
                const SizedBox(height: MiuixSpacing.xl),
                // 内容
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: widget.content,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// MiuixHeroCard —— 可点击的 Hero 卡片
/// 点击后导航到 MiuixHeroPage，自带粉色渐变和按压缩放
/// ============================================================
class MiuixHeroCard extends StatefulWidget {
  const MiuixHeroCard({
    super.key,
    required this.tag,
    required this.heroChild,
    required this.detailContent,
    this.title,
    this.subtitle,
    this.cardColor,
    this.width = 160,
    this.height = 200,
    this.detailTitle,
  });

  final Object tag;
  final Widget heroChild;
  final Widget detailContent;
  final String? title;
  final String? subtitle;
  final Color? cardColor;
  final double width;
  final double height;
  final String? detailTitle;

  @override
  State<MiuixHeroCard> createState() => _MiuixHeroCardState();
}

class _MiuixHeroCardState extends State<MiuixHeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: MiuixDuration.fast,
      reverseDuration: MiuixDuration.elastic,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.93)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.93, end: 1.0)
            .chain(CurveTween(curve: MiuixCurves.miuixSpring)),
        weight: 70,
      ),
    ]).animate(_scaleController);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _navigateToDetail() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: MiuixHeroPage(
              tag: widget.tag,
              heroChild: widget.heroChild,
              content: widget.detailContent,
              title: widget.detailTitle ?? widget.title,
            ),
          );
        },
        transitionDuration: MiuixDuration.page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        _navigateToDetail();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.cardColor ?? MiuixColors.primaryLight,
                (widget.cardColor ?? MiuixColors.primary)
                    .withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(MiuixRadius.lg),
            boxShadow: [
              BoxShadow(
                color: (widget.cardColor ?? MiuixColors.primary)
                    .withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(MiuixRadius.lg),
                  child: MiuixHeroAnimation(
                    tag: widget.tag,
                    child: widget.heroChild,
                  ),
                ),
              ),
              if (widget.title != null || widget.subtitle != null)
                Positioned(
                  left: MiuixSpacing.md,
                  right: MiuixSpacing.md,
                  bottom: MiuixSpacing.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.title != null)
                        Text(
                          widget.title!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: MiuixFontSize.md,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
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

/// ============================================================
/// MiuixHeroImage —— 带 Hero 动画的图片组件
/// 自动添加粉色圆角和阴影
/// ============================================================
class MiuixHeroImage extends StatelessWidget {
  const MiuixHeroImage({
    super.key,
    required this.tag,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = MiuixRadius.lg,
    this.fit = BoxFit.cover,
    this.onTap,
  });

  final Object tag;
  final String imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MiuixHeroAnimation(
      tag: tag,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: MiuixColors.primary.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.network(
              imageUrl,
              fit: fit,
              errorBuilder: (_, __, ___) => Container(
                color: MiuixColors.surfaceVariant,
                child: const Center(
                  child: Icon(Icons.broken_image,
                      color: MiuixColors.textTertiary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
