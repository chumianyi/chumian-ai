import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_switch.dart';

/// ============================================================================
/// SettingTile —— 设置项组件
///
/// 支持开关/箭头/值显示三种模式，集成 MiuixSwitch，粉色主题。
/// 用于设置页面的各类配置项。
/// ============================================================================

/// 设置项类型
enum SettingTileType {
  /// 普通项（带箭头，可点击）
  navigation,

  /// 开关项
  toggle,

  /// 仅显示值
  value,
}

class SettingTile extends StatefulWidget {
  /// 左侧图标
  final IconData? icon;

  /// 图标背景色
  final Color? iconBackgroundColor;

  /// 标题
  final String title;

  /// 副标题/描述
  final String? subtitle;

  /// 类型
  final SettingTileType type;

  /// 开关值（toggle 类型）
  final bool? switchValue;

  /// 开关变化回调（toggle 类型）
  final ValueChanged<bool>? onSwitchChanged;

  /// 右侧值文本（value 类型）
  final String? value;

  /// 右侧自定义组件
  final Widget? trailing;

  /// 点击回调（navigation 类型）
  final VoidCallback? onTap;

  /// 是否显示底部分割线
  final bool showDivider;

  /// 是否禁用
  final bool disabled;

  /// 内边距
  final EdgeInsetsGeometry padding;

  const SettingTile({
    super.key,
    this.icon,
    this.iconBackgroundColor,
    required this.title,
    this.subtitle,
    this.type = SettingTileType.navigation,
    this.switchValue,
    this.onSwitchChanged,
    this.value,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.disabled = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });

  @override
  State<SettingTile> createState() => _SettingTileState();
}

class _SettingTileState extends State<SettingTile> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.type == SettingTileType.navigation &&
        widget.onTap != null &&
        !widget.disabled) {
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
    final iconBg = widget.iconBackgroundColor ?? MiuixColors.primary;

    return Opacity(
      opacity: widget.disabled ? 0.5 : 1.0,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.type == SettingTileType.navigation && !widget.disabled
            ? widget.onTap
            : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
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
                  Padding(
                    padding: widget.padding,
                    child: Row(
                      children: [
                        // 左侧图标
                        if (widget.icon != null) ...[
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  iconBg.withOpacity(0.8),
                                  iconBg,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius:
                                  BorderRadius.circular(MiuixRadius.sm),
                              boxShadow: [
                                BoxShadow(
                                  color: iconBg.withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 18,
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
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        // 右侧内容
                        _buildTrailing(),
                      ],
                    ),
                  ),
                  // 粉色分割线
                  if (widget.showDivider)
                    Padding(
                      padding: EdgeInsets.only(
                          left: widget.icon != null ? 64.0 : 16.0),
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
      ),
    );
  }

  Widget _buildTrailing() {
    if (widget.trailing != null) return widget.trailing!;

    switch (widget.type) {
      case SettingTileType.toggle:
        return MiuixSwitch(
          value: widget.switchValue ?? false,
          onChanged: widget.disabled
              ? null
              : (val) => widget.onSwitchChanged?.call(val),
          disabled: widget.disabled,
        );
      case SettingTileType.value:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.value != null)
              Flexible(
                child: Text(
                  widget.value!,
                  style: TextStyle(
                    fontSize: MiuixFontSize.md,
                    color: MiuixColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: MiuixColors.textTertiary,
              size: 20,
            ),
          ],
        );
      case SettingTileType.navigation:
      default:
        return Icon(
          Icons.chevron_right,
          color: MiuixColors.textTertiary,
          size: 22,
        );
    }
  }
}
