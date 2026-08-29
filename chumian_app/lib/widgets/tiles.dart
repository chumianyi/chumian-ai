/// 列表型组件：设置项、菜单项、切换开关行。
library;

import 'package:flutter/material.dart';
import 'context_ext.dart';

/// 设置项（图标 + 标题 + 可选尾部件）。
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool showChevron;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? context.primary;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 15, color: context.textPrimary, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            )
          : null,
      trailing: trailing ??
          (showChevron
              ? Icon(Icons.chevron_right_rounded, size: 20, color: context.textTertiary)
              : null),
    );
  }
}

/// 可开关设置项。
class SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? iconColor;

  const SwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? context.primary;
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      activeColor: color,
      activeTrackColor: color.withValues(alpha: 0.4),
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 15, color: context.textPrimary, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            )
          : null,
    );
  }
}

/// 菜单项（图标 + 标题 + 副标题 + 箭头）。
class MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final VoidCallback onTap;
  final Color? iconColor;

  const MenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailingText,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? context.primary;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        title,
        style: TextStyle(fontSize: 15, color: context.textPrimary, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText!,
              style: TextStyle(fontSize: 12, color: context.textTertiary),
            ),
          const SizedBox(width: 2),
          Icon(Icons.chevron_right_rounded, size: 20, color: context.textTertiary),
        ],
      ),
    );
  }
}

/// 分隔行。
class ThinDivider extends StatelessWidget {
  final double indent;
  final double endIndent;

  const ThinDivider({super.key, this.indent = 16, this.endIndent = 16});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: indent,
      endIndent: endIndent,
      color: context.divider,
    );
  }
}
