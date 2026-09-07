import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================================
/// InfoTile —— 信息列表项组件
///
/// 图标 + 标题 + 副标题 + 右侧值/箭头，支持按压缩放、水晕效果、
/// 粉色分割线。用于设置页、个人中心等信息展示列表。
/// ============================================================================
class InfoTile extends StatefulWidget {
  /// 左侧图标
  final IconData? icon;

  /// 图标背景色
  final Color? iconBackgroundColor;

  /// 标题
  final String title;

  /// 副标题
  final String? subtitle;

  /// 右侧显示的值
  final String? value;

  /// 右侧自定义组件（优先级高于 value）
  final Widget? trailing;

  /// 是否显示箭头
  final bool showArrow;

  /// 点击回调
  final VoidCallback? onTap;

  /// 长按回调
  final VoidCallback? onLongPress;

  /// 是否显示底部分割线
  final bool showDivider;

  /// 分割线缩进
  final double dividerIndent;

  /// 高度
  final double? height;

  /// 内边距
  final EdgeInsetsGeometry padding;

  const InfoTile({
    super.key,
    this.icon,
    this.iconBackgroundColor,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.showArrow = true,
    this.onTap,
    this.onLongPress,
    this.showDivider = true,
    this.dividerIndent = 56.0,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });

  @override
  State<InfoTile> createState() => _InfoTileState();
}

class _InfoTileState extends State<InfoTile> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final iconBg = widget.iconBackgroundColor ?? MiuixColors.primaryLight;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: _isPressed
                  ? MiuixColors.surfaceHover
                  : Colors.transparent,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: widget.height,
                  padding: widget.padding,
                  child: Row(
                    children: [
                      // 左侧图标
                      if (widget.icon != null) ...[
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: iconBg.withOpacity(0.15),
                            borderRadius:
                                BorderRadius.circular(MiuixRadius.sm),
                          ),
                          child: Icon(
                            widget.icon,
                            color: iconBg,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                      ],
                      // 标题 + 副标题
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: MiuixFontSize.lg,
                                fontWeight: FontWeight.w500,
                                color: MiuixColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.subtitle != null &&
                                widget.subtitle!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                widget.subtitle!,
                                style: TextStyle(
                                  fontSize: MiuixFontSize.sm,
                                  color: MiuixColors.textTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      // 右侧内容
                      if (widget.trailing != null)
                        widget.trailing!
                      else ...[
                        if (widget.value != null &&
                            widget.value!.isNotEmpty) ...[
                          Flexible(
                            child: Text(
                              widget.value!,
                              style: TextStyle(
                                fontSize: MiuixFontSize.md,
                                color: MiuixColors.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (widget.showArrow)
                          Icon(
                            Icons.chevron_right,
                            color: MiuixColors.textTertiary,
                            size: 20,
                          ),
                      ],
                    ],
                  ),
                ),
                // 粉色分割线
                if (widget.showDivider)
                  Padding(
                    padding: EdgeInsets.only(left: widget.dividerIndent),
                    child: Container(
                      height: 0.5,
                      color: MiuixColors.divider,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
