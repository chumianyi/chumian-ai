import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixBadge —— 红色/粉色角标
/// 数字，缩放出现动画
/// ============================================================

/// 角标位置
enum MiuixBadgePosition {
  topRight,
  topLeft,
  bottomRight,
  bottomLeft,
}

/// Miuix 风格角标
///
/// 用法：
/// ```dart
/// MiuixBadge(
///   count: 5,
///   child: Icon(Icons.notifications),
/// )
/// ```
class MiuixBadge extends StatefulWidget {
  const MiuixBadge({
    super.key,
    required this.child,
    this.count,
    this.showZero = false,
    this.maxCount = 99,
    this.badgeColor,
    this.textColor = Colors.white,
    this.position = MiuixBadgePosition.topRight,
    this.size = 18.0,
    this.fontSize,
    this.padding,
    this.dotOnly = false,
    this.dotSize = 8.0,
    this.animate = true,
  });

  /// 子组件
  final Widget child;

  /// 数量
  final int? count;

  /// 数量为 0 时是否显示
  final bool showZero;

  /// 最大显示数量
  final int maxCount;

  /// 角标背景色
  final Color? badgeColor;

  /// 文字颜色
  final Color textColor;

  /// 位置
  final MiuixBadgePosition position;

  /// 角标尺寸
  final double size;

  /// 字体大小
  final double? fontSize;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 仅显示圆点
  final bool dotOnly;

  /// 圆点大小
  final double dotSize;

  /// 是否启用动画
  final bool animate;

  @override
  State<MiuixBadge> createState() => _MiuixBadgeState();
}

class _MiuixBadgeState extends State<MiuixBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    if (_shouldShow) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant MiuixBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool oldShow = _shouldShowCount(oldWidget);
    final bool newShow = _shouldShowCount(widget);
    if (!oldShow && newShow) {
      _controller.forward(from: 0);
    } else if (oldShow && !newShow) {
      _controller.reverse();
    }
  }

  bool get _shouldShow => _shouldShowCount(widget);

  bool _shouldShowCount(MiuixBadge w) {
    if (w.dotOnly) return true;
    if (w.count == null) return false;
    if (w.count == 0) return w.showZero;
    return w.count! > 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _displayText {
    if (widget.count == null) return '';
    if (widget.count! > widget.maxCount) return '${widget.maxCount}+';
    return '${widget.count}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return widget.child;

    final Color bgColor = widget.badgeColor ?? MiuixColors.error;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned(
          right: widget.position == MiuixBadgePosition.topRight ||
                  widget.position == MiuixBadgePosition.bottomRight
              ? -widget.size * 0.4
              : null,
          left: widget.position == MiuixBadgePosition.topLeft ||
                  widget.position == MiuixBadgePosition.bottomLeft
              ? -widget.size * 0.4
              : null,
          top: widget.position == MiuixBadgePosition.topRight ||
                  widget.position == MiuixBadgePosition.topLeft
              ? -widget.size * 0.3
              : null,
          bottom: widget.position == MiuixBadgePosition.bottomRight ||
                  widget.position == MiuixBadgePosition.bottomLeft
              ? -widget.size * 0.3
              : null,
          child: widget.animate
              ? ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildBadge(bgColor),
                )
              : _buildBadge(bgColor),
        ),
      ],
    );
  }

  Widget _buildBadge(Color bgColor) {
    if (widget.dotOnly) {
      return Container(
        width: widget.dotSize,
        height: widget.dotSize,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        minWidth: widget.size,
        minHeight: widget.size,
      ),
      padding: widget.padding ??
          const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(widget.size / 2),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.4),
            blurRadius: 4,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _displayText,
        style: TextStyle(
          color: widget.textColor,
          fontSize: widget.fontSize ?? widget.size * 0.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
