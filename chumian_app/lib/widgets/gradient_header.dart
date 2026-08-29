/// 渐变头部与强调区块：Hero 渐变头、数字面板、统计块、进度条等。
library;

import 'package:flutter/material.dart';
import 'context_ext.dart';
import '../utils/animations.dart';

/// 渐变 Hero 头部。
class GradientHero extends StatelessWidget {
  final Widget child;
  final LinearGradient? gradient;
  final double height;
  final EdgeInsetsGeometry padding;
  final bool bottomRounded;

  const GradientHero({
    super.key,
    required this.child,
    this.gradient,
    this.height = 160,
    this.padding = const EdgeInsets.all(20),
    this.bottomRounded = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: height,
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? context.vibrantGradient,
        borderRadius: bottomRounded
            ? const BorderRadius.vertical(bottom: Radius.circular(28))
            : null,
      ),
      child: child,
    );
    if (!bottomRounded) return content;
    return content;
  }
}

/// 渐变数字/余额面板。
class GradientStatPanel extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? subtitle;
  final LinearGradient? gradient;
  final VoidCallback? onTap;

  const GradientStatPanel({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.subtitle,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final fg = isLight ? Colors.white : Colors.black87;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: R.allLg,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: gradient ?? context.vibrantGradient,
            borderRadius: R.allLg,
            boxShadow: const [
              BoxShadow(color: Color(0x18000000), blurRadius: 16, offset: Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: fg.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 17, color: fg),
                  ),
                  const Spacer(),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.85)),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: fg.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: CountUpText(
                  value: double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
                  builder: (v) => _styledValue(value, v),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: fg,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _styledValue(String raw, double v) {
    if (raw.contains('%')) return '${v.toStringAsFixed(0)}%';
    if (raw.endsWith('万')) return '${v.toStringAsFixed(1)}万';
    if (raw.endsWith('亿')) return '${v.toStringAsFixed(1)}亿';
    return raw;
  }
}

/// 纯文本统计块（数值 + 标签）。
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: R.allMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: valueColor ?? context.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// 水平进度条（渐变）。
class GradientProgress extends StatelessWidget {
  final double value;
  final double height;
  final LinearGradient? gradient;

  const GradientProgress({
    super.key,
    required this.value,
    this.height = 8,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Stack(
        children: [
          Container(
            height: height,
            color: context.surfaceSubtle,
          ),
          FractionallySizedBox(
            widthFactor: clamped,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                gradient: gradient ?? context.primaryGradient,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 徽章式标签。
class PillTag extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? background;
  final IconData? icon;
  final double fontSize;

  const PillTag({
    super.key,
    required this.text,
    this.color,
    this.background,
    this.icon,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: c),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

/// 区块标题（左侧短条 + 标题 + 可选副标题/操作）。
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showAccent;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showAccent = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Row(
        children: [
          if (showAccent) ...[
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                gradient: context.primaryGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 12, color: context.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// 圆形图标块。
class IconCircle extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;
  final double iconSize;

  const IconCircle({
    super.key,
    required this.icon,
    this.color,
    this.size = 48,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: iconSize, color: c),
    );
  }
}
