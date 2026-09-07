import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================================
/// TextLink —— 文字链接组件
///
/// 粉色下划线，点击水晕，hover效果，外部链接图标。
/// 用于页面中的可点击文字链接，支持内部跳转和外部URL。
/// ============================================================================
class TextLink extends StatefulWidget {
  /// 链接文字
  final String text;

  /// 链接 URL（外部链接）
  final String? url;

  /// 点击回调（优先级高于 url）
  final VoidCallback? onTap;

  /// 文字大小
  final double fontSize;

  /// 文字字重
  final FontWeight fontWeight;

  /// 链接颜色
  final Color? color;

  /// 是否显示下划线
  final bool showUnderline;

  /// 是否显示外部链接图标
  final bool showExternalIcon;

  /// 是否在新窗口打开（外部链接）
  final bool openInNewTab;

  const TextLink({
    super.key,
    required this.text,
    this.url,
    this.onTap,
    this.fontSize = 14.0,
    this.fontWeight = FontWeight.w400,
    this.color,
    this.showUnderline = true,
    this.showExternalIcon = true,
    this.openInNewTab = true,
  });

  @override
  State<TextLink> createState() => _TextLinkState();
}

class _TextLinkState extends State<TextLink> {
  bool _isHovering = false;
  bool _isPressed = false;

  bool get _isExternal => widget.url != null && widget.url!.isNotEmpty;

  Future<void> _handleTap() async {
    if (widget.onTap != null) {
      widget.onTap!.call();
      return;
    }
    if (_isExternal) {
      final uri = Uri.parse(widget.url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: widget.openInNewTab
              ? LaunchMode.externalApplication
              : LaunchMode.platformDefault,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final linkColor = widget.color ?? MiuixColors.textLink;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _handleTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: _isPressed
              ? const EdgeInsets.symmetric(horizontal: 2, vertical: 1)
              : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: _isPressed
                ? linkColor.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.text,
                style: TextStyle(
                  color: _isHovering
                      ? linkColor.withOpacity(0.8)
                      : linkColor,
                  fontSize: widget.fontSize,
                  fontWeight: widget.fontWeight,
                  decoration: widget.showUnderline
                      ? (_isHovering
                          ? TextDecoration.none
                          : TextDecoration.underline)
                      : TextDecoration.none,
                  decorationColor: linkColor.withOpacity(0.5),
                  decorationThickness: 1,
                ),
              ),
              if (_isExternal && widget.showExternalIcon) ...[
                const SizedBox(width: 3),
                Icon(
                  Icons.open_in_new,
                  color: linkColor.withOpacity(0.7),
                  size: widget.fontSize * 0.85,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// RichTextLink —— 富文本中的链接片段
/// ============================================================================
class RichTextLink extends TextSpan {
  final String linkText;
  final String? url;
  final VoidCallback? onTap;
  final Color? color;
  final double fontSize;

  RichTextLink({
    required this.linkText,
    this.url,
    this.onTap,
    this.color,
    this.fontSize = 14.0,
  }) : super(
          text: linkText,
          style: TextStyle(
            color: color ?? MiuixColors.textLink,
            fontSize: fontSize,
            decoration: TextDecoration.underline,
            decorationColor: (color ?? MiuixColors.textLink)
                .withOpacity(0.5),
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              if (onTap != null) {
                onTap.call();
                return;
              }
              if (url != null && url!.isNotEmpty) {
                final uri = Uri.parse(url!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              }
            },
        );
}
