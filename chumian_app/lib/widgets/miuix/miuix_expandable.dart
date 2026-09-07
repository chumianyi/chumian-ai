import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// MiuixExpandable —— 可展开折叠组件
/// 高度动画，箭头旋转
/// ============================================================

/// Miuix 可展开折叠组件
///
/// 用法：
/// ```dart
/// MiuixExpandable(
///   title: '展开更多',
///   child: Text('隐藏内容'),
/// )
/// ```
class MiuixExpandable extends StatefulWidget {
  const MiuixExpandable({
    super.key,
    this.title,
    this.titleWidget,
    required this.child,
    this.initiallyExpanded = false,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOutCubic,
    this.headerColor,
    this.expandedColor,
    this.borderRadius,
    this.showArrow = true,
    this.arrowIcon = Icons.keyboard_arrow_down,
    this.onExpansionChanged,
    this.trailing,
    this.leading,
    this.padding,
    this.contentPadding,
    this.divider = true,
  });

  /// 标题文字
  final String? title;

  /// 自定义标题 Widget
  final Widget? titleWidget;

  /// 展开内容
  final Widget child;

  /// 初始是否展开
  final bool initiallyExpanded;

  /// 动画时长
  final Duration duration;

  /// 动画曲线
  final Curve curve;

  /// 头部背景色
  final Color? headerColor;

  /// 展开时背景色
  final Color? expandedColor;

  /// 圆角
  final double? borderRadius;

  /// 是否显示箭头
  final bool showArrow;

  /// 箭头图标
  final IconData arrowIcon;

  /// 展开状态变化回调
  final ValueChanged<bool>? onExpansionChanged;

  /// 右侧自定义组件
  final Widget? trailing;

  /// 左侧自定义组件
  final Widget? leading;

  /// 头部内边距
  final EdgeInsetsGeometry? padding;

  /// 内容内边距
  final EdgeInsetsGeometry? contentPadding;

  /// 是否显示分割线
  final bool divider;

  @override
  State<MiuixExpandable> createState() => _MiuixExpandableState();
}

class _MiuixExpandableState extends State<MiuixExpandable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _heightFactor;
  late final Animation<double> _arrowTurns;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: _isExpanded ? 1.0 : 0.0,
    );
    _heightFactor = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
    _arrowTurns = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
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
    final double radius = widget.borderRadius ?? MiuixRadius.md;
    final bool isExpanded = _isExpanded;

    return Container(
      decoration: BoxDecoration(
        color: isExpanded
            ? (widget.expandedColor ??
                MiuixColors.primaryLight.withOpacity(0.05))
            : (widget.headerColor ?? MiuixColors.surface),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isExpanded
              ? MiuixColors.primary.withOpacity(0.3)
              : MiuixColors.border,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头部
          GestureDetector(
            onTap: _toggle,
            child: MiuixRipple(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(radius),
                bottom: isExpanded
                    ? Radius.zero
                    : Radius.circular(radius),
              ),
              color: MiuixColors.primary.withOpacity(0.1),
              child: Container(
                padding: widget.padding ??
                    const EdgeInsets.symmetric(
                      horizontal: MiuixSpacing.lg,
                      vertical: MiuixSpacing.md,
                    ),
                child: Row(
                  children: [
                    if (widget.leading != null) ...[
                      widget.leading!,
                      const SizedBox(width: MiuixSpacing.sm),
                    ],
                    Expanded(
                      child: widget.titleWidget ??
                          Text(
                            widget.title ?? '',
                            style: TextStyle(
                              color: isExpanded
                                  ? MiuixColors.primary
                                  : MiuixColors.textPrimary,
                              fontSize: MiuixFontSize.md,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                    ),
                    if (widget.trailing != null) ...[
                      widget.trailing!,
                      const SizedBox(width: MiuixSpacing.sm),
                    ],
                    if (widget.showArrow)
                      RotationTransition(
                        turns: _arrowTurns,
                        child: Icon(
                          widget.arrowIcon,
                          size: 20,
                          color: isExpanded
                              ? MiuixColors.primary
                              : MiuixColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // 分割线
          if (widget.divider && isExpanded)
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(
                horizontal: MiuixSpacing.lg,
              ),
              color: MiuixColors.divider,
            ),
          // 展开内容
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: _heightFactor.value,
              child: Padding(
                padding: widget.contentPadding ??
                    const EdgeInsets.fromLTRB(
                      MiuixSpacing.lg,
                      0,
                      MiuixSpacing.lg,
                      MiuixSpacing.md,
                    ),
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// MiuixExpandablePanel —— 手风琴面板组
/// ============================================================

/// 手风琴面板组
class MiuixExpandablePanel extends StatefulWidget {
  const MiuixExpandablePanel({
    super.key,
    required this.children,
    this.accordion = true,
    this.expansionCallback,
  });

  /// 面板列表
  final List<MiuixExpandable> children;

  /// 是否手风琴模式（一次只展开一个）
  final bool accordion;

  /// 展开回调
  final ValueChanged<int>? expansionCallback;

  @override
  State<MiuixExpandablePanel> createState() => _MiuixExpandablePanelState();
}

class _MiuixExpandablePanelState extends State<MiuixExpandablePanel> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.children.length, (index) {
        final MiuixExpandable child = widget.children[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < widget.children.length - 1
                ? MiuixSpacing.sm
                : 0,
          ),
          child: MiuixExpandable(
            key: child.key,
            title: child.title,
            titleWidget: child.titleWidget,
            initiallyExpanded: _expandedIndex == index,
            onExpansionChanged: (expanded) {
              if (widget.accordion) {
                setState(() {
                  _expandedIndex = expanded ? index : null;
                });
              }
              widget.expansionCallback?.call(index);
              child.onExpansionChanged?.call(expanded);
            },
            duration: child.duration,
            curve: child.curve,
            headerColor: child.headerColor,
            expandedColor: child.expandedColor,
            borderRadius: child.borderRadius,
            showArrow: child.showArrow,
            arrowIcon: child.arrowIcon,
            trailing: child.trailing,
            leading: child.leading,
            padding: child.padding,
            contentPadding: child.contentPadding,
            divider: child.divider,
            child: child.child,
          ),
        );
      }),
    );
  }
}
