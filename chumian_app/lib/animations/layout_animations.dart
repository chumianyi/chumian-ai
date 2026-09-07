import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================================
/// LayoutAnimations —— 布局动画集合
///
/// 提供多种布局变化动画：展开/折叠、大小变化、位置移动、
/// 列表项插入/删除等。基于 AnimatedSize、AnimatedPositioned 等实现。
/// ============================================================================

/// 可展开/折叠的容器
class ExpandableContainer extends StatefulWidget {
  final Widget child;
  final bool expanded;
  final Duration duration;
  final Curve curve;
  final double collapsedHeight;

  const ExpandableContainer({
    super.key,
    required this.child,
    this.expanded = false,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOutCubic,
    this.collapsedHeight = 0.0,
  });

  @override
  State<ExpandableContainer> createState() => _ExpandableContainerState();
}

class _ExpandableContainerState extends State<ExpandableContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _heightFactor;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.expanded ? 1.0 : 0.0,
    );
    final curve = CurvedAnimation(parent: _controller, curve: widget.curve);
    _heightFactor = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(curve);
  }

  @override
  void didUpdateWidget(covariant ExpandableContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded != widget.expanded) {
      if (widget.expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
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
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _heightFactor.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// 带动画的尺寸变化容器
class AnimatedSizeContainer extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Alignment alignment;

  const AnimatedSizeContainer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOutCubic,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      curve: curve,
      alignment: alignment,
      child: child,
    );
  }
}

/// 带动画的位置变化容器
class AnimatedPositionedContainer extends StatelessWidget {
  final Widget child;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? width;
  final double? height;
  final Duration duration;
  final Curve curve;

  const AnimatedPositionedContainer({
    super.key,
    required this.child,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.width,
    this.height,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: duration,
      curve: curve,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      width: width,
      height: height,
      child: child,
    );
  }
}

/// 可展开的列表项（带旋转箭头）
class ExpandableListItem extends StatefulWidget {
  final String title;
  final Widget expandedContent;
  final IconData? leadingIcon;
  final Color? accentColor;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  const ExpandableListItem({
    super.key,
    required this.title,
    required this.expandedContent,
    this.leadingIcon,
    this.accentColor,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
  });

  @override
  State<ExpandableListItem> createState() => _ExpandableListItemState();
}

class _ExpandableListItemState extends State<ExpandableListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _rotateAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: _isExpanded ? 1.0 : 0.0,
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _expandAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _rotateAnimation =
        Tween<double>(begin: 0.0, end: 0.5).animate(curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
    widget.onExpansionChanged?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? MiuixColors.primary;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: MiuixColors.surface,
        borderRadius: BorderRadius.circular(MiuixRadius.md),
        border: Border.all(color: MiuixColors.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(MiuixRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  if (widget.leadingIcon != null) ...[
                    Icon(widget.leadingIcon, color: accent, size: 20),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: MiuixFontSize.lg,
                        fontWeight: FontWeight.w600,
                        color: MiuixColors.textPrimary,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: _rotateAnimation,
                    child: Icon(
                      Icons.expand_more,
                      color: accent,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: _expandAnimation.value,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: widget.expandedContent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 带动画的交叉淡入（两个子组件交替显示）
class AnimatedCrossFadeSwitcher extends StatelessWidget {
  final Widget firstChild;
  final Widget secondChild;
  final bool showSecond;
  final Duration duration;
  final CrossFadeState crossFadeState;

  const AnimatedCrossFadeSwitcher({
    super.key,
    required this.firstChild,
    required this.secondChild,
    this.showSecond = false,
    this.duration = const Duration(milliseconds: 300),
  }) : crossFadeState = showSecond
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst;

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: firstChild,
      secondChild: secondChild,
      crossFadeState: crossFadeState,
      duration: duration,
      firstCurve: Curves.easeInOutCubic,
      secondCurve: Curves.easeInOutCubic,
      sizeCurve: Curves.easeInOutCubic,
      layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              key: bottomChildKey,
              left: 0,
              right: 0,
              child: bottomChild,
            ),
            Positioned(
              key: topChildKey,
              child: topChild,
            ),
          ],
        );
      },
    );
  }
}

/// 列表项插入/删除动画封装
class AnimatedListItemBuilder extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final Axis axis;

  const AnimatedListItemBuilder({
    super.key,
    required this.child,
    required this.animation,
    this.axis = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return SizeTransition(
      sizeFactor: curve,
      axis: axis,
      child: FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: axis == Axis.vertical
                ? const Offset(0, -0.3)
                : const Offset(-0.3, 0),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        ),
      ),
    );
  }
}

/// 带动画的 Padding 变化
class AnimatedPaddingContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Duration duration;
  final Curve curve;

  const AnimatedPaddingContainer({
    super.key,
    required this.child,
    required this.padding,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      padding: padding,
      duration: duration,
      curve: curve,
      child: child,
    );
  }
}

/// 带动画的装饰变化（背景色、边框、圆角等）
class AnimatedDecorationContainer extends StatelessWidget {
  final Widget child;
  final BoxDecoration decoration;
  final Duration duration;
  final Curve curve;

  const AnimatedDecorationContainer({
    super.key,
    required this.child,
    required this.decoration,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      decoration: decoration,
      child: child,
    );
  }
}
