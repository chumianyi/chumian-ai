/// 统一卡片组件库：普通卡片 / 渐变卡片 / 可点击卡片 / 分组区块。
library;

import 'package:flutter/material.dart';
import 'context_ext.dart';

/// 圆角统一卡片。
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final List<BoxShadow>? shadow;
  final BorderRadius? radius;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final double? height;
  final bool clip;
  final EdgeInsetsGeometry margin;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.shadow,
    this.radius,
    this.onTap,
    this.gradient,
    this.height,
    this.clip = true,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = radius ?? R.allLg;
    final effectiveShadow = shadow ??
        (onTap != null
            ? const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 3))]
            : const [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))]);

    Widget content = Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? (color != null ? null : _defaultGradient(context)),
        color: gradient != null
            ? null
            : (color ?? context.surface),
        borderRadius: effectiveRadius,
        boxShadow: effectiveShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          child: content,
        ),
      );
    }

    if (clip) {
      content = ClipRRect(borderRadius: effectiveRadius, child: content);
    }
    if (margin != EdgeInsets.zero) {
      content = Container(margin: margin, child: content);
    }
    return content;
  }

  LinearGradient _defaultGradient(BuildContext context) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [context.surface, context.surface],
    );
  }
}

/// 渐变卡片。
class GradientCard extends StatelessWidget {
  final Widget child;
  final LinearGradient? gradient;
  final EdgeInsetsGeometry padding;
  final BorderRadius? radius;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadow;

  const GradientCard({
    super.key,
    required this.child,
    this.gradient,
    this.padding = const EdgeInsets.all(20),
    this.radius,
    this.onTap,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      radius: radius,
      onTap: onTap,
      shadow: shadow ?? const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6))],
      gradient: gradient ?? context.vibrantGradient,
      child: child,
    );
  }
}

/// 分组卡片容器：带标题与可选右侧操作。
class CardSection extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry titlePadding;

  const CardSection({
    super.key,
    required this.title,
    this.trailing,
    this.children = const [],
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    this.titlePadding = const EdgeInsets.fromLTRB(20, 18, 16, 6),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: titlePadding,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: R.allLg,
            boxShadow: const [
              BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}

/// 紧凑小卡片（网格用）。
class MiniCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const MiniCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      radius: R.allMd,
      shadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 1))],
      onTap: onTap,
      child: child,
    );
  }
}

/// 横向信息行（图标 + 主文本 + 次文本 + 尾部件）。
class InfoRow extends StatelessWidget {
  final IconData? leadingIcon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const InfoRow({
    super.key,
    this.leadingIcon,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final leadingWidget = leading ??
        (leadingIcon != null
            ? Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: context.primary.withValues(alpha: 0.12),
                  borderRadius: R.allSm,
                ),
                child: Icon(leadingIcon, size: 20, color: context.primary),
              )
            : null);

    return InkWell(
      onTap: onTap,
      borderRadius: R.allMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (leadingWidget != null) ...[
              leadingWidget,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, color: context.textPrimary, fontWeight: FontWeight.w500),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: context.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
