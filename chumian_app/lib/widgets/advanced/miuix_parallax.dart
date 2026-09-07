import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixParallax —— Miuix 风格视差滚动
/// 头部图片视差效果，折叠工具栏，粉色渐变遮罩
/// ============================================================

/// Miuix 风格视差滚动组件
///
/// 用法：
/// ```dart
/// MiuixParallax(
///   headerHeight: 240,
///   header: Image.network('...', fit: BoxFit.cover),
///   title: '详情页',
///   body: ListView(...),
/// )
/// ```
class MiuixParallax extends StatefulWidget {
  const MiuixParallax({
    super.key,
    required this.header,
    required this.body,
    this.headerHeight = 240,
    this.title,
    this.collapsedTitle,
    this.actions,
    this.leading,
    this.showGradientOverlay = true,
    this.onHeaderTap,
  });

  /// 头部组件（通常是图片）
  final Widget header;

  /// 内容区域
  final Widget body;

  /// 头部高度
  final double headerHeight;

  /// 展开时的标题
  final String? title;

  /// 折叠时的标题
  final String? collapsedTitle;

  /// 右侧操作按钮
  final List<Widget>? actions;

  /// 左侧返回按钮
  final Widget? leading;

  /// 是否显示粉色渐变遮罩
  final bool showGradientOverlay;

  /// 头部点击回调
  final VoidCallback? onHeaderTap;

  @override
  State<MiuixParallax> createState() => _MiuixParallaxState();
}

class _MiuixParallaxState extends State<MiuixParallax> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  double get _headerScale {
    if (_scrollOffset < 0) {
      return 1.0 + (-_scrollOffset) / widget.headerHeight * 0.5;
    }
    return 1.0;
  }

  double get _titleOpacity {
    final threshold = widget.headerHeight - kToolbarHeight - 20;
    if (_scrollOffset < threshold - 40) return 1.0;
    if (_scrollOffset > threshold) return 0.0;
    return (threshold - _scrollOffset) / 40;
  }

  double get _collapsedTitleOpacity {
    final threshold = widget.headerHeight - kToolbarHeight - 20;
    if (_scrollOffset < threshold - 20) return 0.0;
    if (_scrollOffset > threshold + 20) return 1.0;
    return (_scrollOffset - threshold + 20) / 40;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 滚动内容
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: widget.headerHeight,
                pinned: true,
                floating: false,
                backgroundColor: MiuixColors.surface,
                leading: widget.leading ??
                    (_collapsedTitleOpacity > 0.5
                        ? _buildBackButton(dark: true)
                        : _buildBackButton(dark: false)),
                actions: widget.actions,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final top = constraints.biggest.height;
                    final isCollapsed = top <= kToolbarHeight + 20;
                    return FlexibleSpaceBar(
                      title: isCollapsed
                          ? Text(
                              widget.collapsedTitle ?? widget.title ?? '',
                              style: const TextStyle(
                                color: MiuixColors.textPrimary,
                                fontSize: MiuixFontSize.lg,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                      background: GestureDetector(
                        onTap: widget.onHeaderTap,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 视差图片
                            Transform.scale(
                              scale: _headerScale,
                              child: widget.header,
                            ),
                            // 粉色渐变遮罩
                            if (widget.showGradientOverlay)
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        MiuixColors.primary
                                            .withValues(alpha: 0.15),
                                        MiuixColors.background
                                            .withValues(alpha: 0.9),
                                      ],
                                      stops: const [0.4, 0.75, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            // 展开标题
                            if (widget.title != null)
                              Positioned(
                                left: MiuixSpacing.lg,
                                right: MiuixSpacing.lg,
                                bottom: MiuixSpacing.xl,
                                child: Opacity(
                                  opacity: _titleOpacity,
                                  child: Text(
                                    widget.title!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: MiuixFontSize.xxl,
                                      fontWeight: FontWeight.w700,
                                      shadows: [
                                        Shadow(
                                          color: Color(0x44000000),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: widget.body,
              ),
            ],
          ),
          // 折叠时的粉色底部边框
          if (_collapsedTitleOpacity > 0.3)
            Positioned(
              top: kToolbarHeight + MediaQuery.of(context).padding.top - 1,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: _collapsedTitleOpacity,
                child: Container(
                  height: 2,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        MiuixColors.primary,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackButton({required bool dark}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: dark
              ? Colors.white.withValues(alpha: 0.9)
              : Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(MiuixRadius.pill),
        ),
        child: Icon(
          Icons.arrow_back,
          color: dark ? MiuixColors.primary : Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

/// ============================================================
/// MiuixParallaxImage —— 视差图片组件
/// 可嵌入任意滚动视图，根据滚动位置产生视差
/// ============================================================
class MiuixParallaxImage extends StatelessWidget {
  const MiuixParallaxImage({
    super.key,
    required this.imageUrl,
    required this.controller,
    this.height = 200,
    this.parallaxFactor = 0.3,
    this.overlayGradient,
  });

  final String imageUrl;
  final ScrollController controller;
  final double height;
  final double parallaxFactor;
  final Gradient? overlayGradient;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final offset = controller.hasClients ? controller.offset : 0;
          final parallaxOffset = offset * parallaxFactor;
          return Stack(
            fit: StackFit.expand,
            children: [
              Transform.translate(
                offset: Offset(0, -parallaxOffset * 0.5),
                child: OverflowBox(
                  maxHeight: height * 1.5,
                  minHeight: height * 1.5,
                  alignment: Alignment.topCenter,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: MiuixColors.surfaceVariant,
                    ),
                  ),
                ),
              ),
              if (overlayGradient != null)
                Positioned.fill(
                  child: DecoratedBox(decoration: BoxDecoration(gradient: overlayGradient)),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// ============================================================
/// MiuixCollapsibleHeader —— 可折叠头部
/// 粉色渐变背景，随滚动折叠
/// ============================================================
class MiuixCollapsibleHeader extends StatelessWidget {
  const MiuixCollapsibleHeader({
    super.key,
    required this.title,
    this.expandedHeight = 200,
    this.background,
    this.actions,
    this.leading,
  });

  final String title;
  final double expandedHeight;
  final Widget? background;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      floating: false,
      backgroundColor: MiuixColors.surface,
      leading: leading,
      actions: actions,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final top = constraints.biggest.height;
          final isCollapsed = top <= kToolbarHeight + 20;
          return FlexibleSpaceBar(
            title: AnimatedOpacity(
              opacity: isCollapsed ? 1.0 : 0.0,
              duration: MiuixDuration.fast,
              child: Text(
                title,
                style: const TextStyle(
                  color: MiuixColors.textPrimary,
                  fontSize: MiuixFontSize.lg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (background != null) background!,
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
                Positioned(
                  left: MiuixSpacing.lg,
                  bottom: MiuixSpacing.xl,
                  child: AnimatedOpacity(
                    opacity: isCollapsed ? 0.0 : 1.0,
                    duration: MiuixDuration.fast,
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: MiuixColors.primaryDeep,
                        fontSize: MiuixFontSize.xxl,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
