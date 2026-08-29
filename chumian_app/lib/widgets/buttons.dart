/// 按钮组件：渐变按钮、胶囊按钮、图标按钮、底部操作栏。
library;

import 'package:flutter/material.dart';
import 'context_ext.dart';
import 'feedback.dart';

/// 渐变填充按钮。
class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final LinearGradient? gradient;
  final IconData? icon;
  final double height;
  final bool loading;
  final EdgeInsetsGeometry? padding;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.gradient,
    this.icon,
    this.height = 48,
    this.loading = false,
    this.padding,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: widget.gradient ?? context.vibrantGradient,
          borderRadius: BorderRadius.circular(widget.height / 2),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: InkWell(
          onTap: enabled ? widget.onPressed : null,
          borderRadius: BorderRadius.circular(widget.height / 2),
          child: Container(
            height: widget.height,
            padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.center,
            child: widget.loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: context.onPrimary,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 18, color: context.onPrimary),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          widget.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.onPrimary,
                          ),
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

/// 胶囊描边按钮。
class OutlinePill extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final double height;

  const OutlinePill({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
    this.height = 44,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.primary;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: c.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(height / 2),
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 17, color: c),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c,
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

/// 图标动作按钮（AppBar 用）。
class IconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color? color;

  const IconAction({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip = '',
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, color: color ?? context.textPrimary),
    );
  }
}

/// 底部固定操作栏。
class BottomActionBar extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final Color? background;

  const BottomActionBar({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 16),
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? context.background,
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(children.length, (i) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 0 : 6,
                  right: i == children.length - 1 ? 0 : 6,
                ),
                child: children[i],
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// 带加载状态的文本按钮。
class LoadingTextButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const LoadingTextButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: Spinner(size: 22));
    }
    return TextButton(onPressed: onPressed, child: Text(label));
  }
}
