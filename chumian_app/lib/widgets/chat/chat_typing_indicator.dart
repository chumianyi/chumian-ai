import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// ChatTypingIndicator —— AI 输入指示器
/// 三点跳动 + mascot 头像，粉色动画
/// ============================================================

class ChatTypingIndicator extends StatefulWidget {
  const ChatTypingIndicator({
    super.key,
    this.showAvatar = true,
    this.text = '正在输入...',
  });

  /// 是否显示头像
  final bool showAvatar;

  /// 提示文字
  final String text;

  @override
  State<ChatTypingIndicator> createState() => _ChatTypingIndicatorState();
}

class _ChatTypingIndicatorState extends State<ChatTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MiuixSpacing.md,
        vertical: MiuixSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (widget.showAvatar) _buildAvatar(),
          if (widget.showAvatar) const SizedBox(width: MiuixSpacing.sm),
          _buildBubble(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final bounce = 1.0 + 0.05 * (_controller.value < 0.5
            ? _controller.value * 2
            : (1 - _controller.value) * 2);
        return Transform.scale(
          scale: bounce,
          child: child,
        );
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: MiuixColors.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: MiuixShadows.sm,
        ),
        child: const Icon(
          Icons.auto_awesome,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MiuixSpacing.lg,
        vertical: MiuixSpacing.md,
      ),
      decoration: BoxDecoration(
        color: MiuixColors.surface.withValues(alpha: 0.85),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(MiuixRadius.lg),
          topRight: Radius.circular(MiuixRadius.lg),
          bottomLeft: Radius.circular(MiuixRadius.sm),
          bottomRight: Radius.circular(MiuixRadius.lg),
        ),
        border: Border.all(color: MiuixColors.borderLight, width: 1),
        boxShadow: MiuixShadows.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(0),
          const SizedBox(width: 6),
          _buildDot(1),
          const SizedBox(width: 6),
          _buildDot(2),
          const SizedBox(width: MiuixSpacing.md),
          Text(
            widget.text,
            style: const TextStyle(
              fontSize: MiuixFontSize.sm,
              color: MiuixColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final delay = index * 0.15;
        final t = ((_controller.value + delay) % 1.0);
        final height = 6.0 + 10.0 * (t < 0.5 ? t * 2 : (1 - t) * 2);
        return Container(
          width: 8,
          height: height,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: MiuixColors.primaryGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}
