import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================================
/// SectionHeader —— 分区标题组件
///
/// 粉色图标 + 标题 + 查看更多，支持动画入场与右侧自定义操作。
/// 用于页面中各功能区块的标题栏。
/// ============================================================================
class SectionHeader extends StatefulWidget {
  /// 标题文字
  final String title;

  /// 左侧图标
  final IconData? icon;

  /// 右侧操作文字（默认"查看更多"）
  final String? actionText;

  /// 右侧操作回调
  final VoidCallback? onAction;

  /// 右侧自定义操作组件（优先级高于 actionText）
  final Widget? trailing;

  /// 副标题
  final String? subtitle;

  /// 是否显示粉色图标背景
  final bool showIconBackground;

  /// 入场动画延迟
  final Duration delay;

  /// 内边距
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.actionText,
    this.onAction,
    this.trailing,
    this.subtitle,
    this.showIconBackground = true,
    this.delay = Duration.zero,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  State<SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<SectionHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.05, 0.0),
      end: Offset.zero,
    ).animate(curve);

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: widget.padding,
          child: Row(
            children: [
              // 左侧图标
              if (widget.icon != null) ...[
                if (widget.showIconBackground)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: MiuixColors.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(MiuixRadius.sm),
                      boxShadow: [
                        BoxShadow(
                          color: MiuixColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 18,
                    ),
                  )
                else
                  Icon(
                    widget.icon,
                    color: MiuixColors.primary,
                    size: 22,
                  ),
                const SizedBox(width: 10),
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
                        fontSize: MiuixFontSize.xl,
                        fontWeight: FontWeight.w700,
                        color: MiuixColors.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (widget.subtitle != null &&
                        widget.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          fontSize: MiuixFontSize.sm,
                          color: MiuixColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // 右侧操作
              if (widget.trailing != null)
                widget.trailing!
              else if (widget.actionText != null && widget.onAction != null)
                GestureDetector(
                  onTap: widget.onAction,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.actionText!,
                        style: TextStyle(
                          fontSize: MiuixFontSize.md,
                          color: MiuixColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        color: MiuixColors.primary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
