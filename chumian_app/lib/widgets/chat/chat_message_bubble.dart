import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/models/chat_message.dart';
import 'package:chumian_ai/utils/markdown_stripper.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// ChatMessageBubble —— 聊天消息气泡组件
/// 用户/AI 双样式：粉色渐变用户气泡，毛玻璃 AI 气泡
/// 思考过程折叠展开，Markdown 渲染，代码块高亮
/// 图片/视频/文件消息，按压缩放，水晕反馈，长按菜单
/// ============================================================

/// 消息气泡样式
enum BubbleStyle { user, assistant, system }

/// 代码块语言高亮配色
class _CodeHighlightColors {
  static const keyword = Color(0xFFC678DD);
  static const string = Color(0xFF98C379);
  static const comment = Color(0xFF5C6370);
  static const function = Color(0xFF61AFEF);
  static const number = Color(0xFFD19A66);
  static const operator = Color(0xFF56B6C2);
}

class ChatMessageBubble extends StatefulWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onLongPress,
    this.onTap,
    this.onImageTap,
    this.onVideoTap,
    this.onFileTap,
    this.onThinkToggle,
    this.showAvatar = true,
    this.avatarUrl,
    this.maxWidth,
    this.animation,
  });

  /// 消息数据
  final ChatMessage message;

  /// 长按回调
  final VoidCallback? onLongPress;

  /// 点击回调
  final VoidCallback? onTap;

  /// 图片点击回调
  final ValueChanged<String>? onImageTap;

  /// 视频点击回调
  final ValueChanged<String>? onVideoTap;

  /// 文件点击回调
  final ValueChanged<String>? onFileTap;

  /// 思考过程展开/折叠回调
  final ValueChanged<bool>? onThinkToggle;

  /// 是否显示头像
  final bool showAvatar;

  /// 头像 URL（AI 头像）
  final String? avatarUrl;

  /// 最大宽度
  final double? maxWidth;

  /// 入场动画
  final Animation<double>? animation;

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: MiuixDuration.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: MiuixCurves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  BubbleStyle get _style {
    switch (widget.message.role) {
      case MessageRole.user:
        return BubbleStyle.user;
      case MessageRole.assistant:
        return BubbleStyle.assistant;
      case MessageRole.system:
        return BubbleStyle.system;
    }
  }

  bool get _isUser => _style == BubbleStyle.user;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bubbleMaxWidth = widget.maxWidth ?? screenWidth * 0.78;

    Widget bubble = GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _pressController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _pressController.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _pressController.reverse();
      },
      onLongPress: widget.onLongPress,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildBubbleContent(bubbleMaxWidth),
      ),
    );

    if (widget.animation != null) {
      bubble = FadeTransition(
        opacity: widget.animation!,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(_isUser ? 0.3 : -0.3, 0.05),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: widget.animation!,
            curve: MiuixCurves.easeOut,
          )),
          child: bubble,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MiuixSpacing.md,
        vertical: MiuixSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment:
            _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!_isUser && widget.showAvatar) _buildAvatar(),
          if (!_isUser && widget.showAvatar)
            const SizedBox(width: MiuixSpacing.sm),
          Flexible(child: bubble),
          if (_isUser && widget.showAvatar)
            const SizedBox(width: MiuixSpacing.sm),
          if (_isUser && widget.showAvatar) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
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
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: MiuixColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MiuixColors.border, width: 1.5),
      ),
      child: const Icon(
        Icons.person,
        color: MiuixColors.primary,
        size: 20,
      ),
    );
  }

  Widget _buildBubbleContent(double maxWidth) {
    if (_style == BubbleStyle.system) {
      return _buildSystemBubble();
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        crossAxisAlignment:
            _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (widget.message.thinkContent.isNotEmpty) _buildThinkSection(),
          _buildMainBubble(),
          if (widget.message.imageUrl != null) _buildImageMessage(),
          if (widget.message.videoUrl != null) _buildVideoMessage(),
          if (widget.message.tokensUsed != null) _buildTokenInfo(),
        ],
      ),
    );
  }

  Widget _buildSystemBubble() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MiuixSpacing.md,
          vertical: MiuixSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: MiuixColors.surfaceVariant,
          borderRadius: MiuixRadius.pillRadius,
        ),
        child: Text(
          widget.message.content,
          style: const TextStyle(
            fontSize: MiuixFontSize.sm,
            color: MiuixColors.textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildThinkSection() {
    final isExpanded = widget.message.isExpanded;
    return Padding(
      padding: const EdgeInsets.only(bottom: MiuixSpacing.xs),
      child: MiuixRipple(
        onTap: () {
          widget.onThinkToggle?.call(!isExpanded);
        },
        borderRadius: MiuixRadius.md,
        child: AnimatedContainer(
          duration: MiuixDuration.normal,
          curve: MiuixCurves.easeInOut,
          padding: const EdgeInsets.symmetric(
            horizontal: MiuixSpacing.md,
            vertical: MiuixSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: MiuixColors.surfaceVariant.withOpacity(0.6),
            borderRadius: MiuixRadius.mdRadius,
            border: Border.all(
              color: MiuixColors.borderLight,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: MiuixColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.message.isThinking ? '正在思考...' : '思考过程',
                    style: const TextStyle(
                      fontSize: MiuixFontSize.sm,
                      color: MiuixColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.message.isThinking) ...[
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          MiuixColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: MiuixSpacing.sm),
                Text(
                  widget.message.thinkContent,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.sm,
                    color: MiuixColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainBubble() {
    if (widget.message.content.isEmpty && widget.message.isThinking) {
      return _buildTypingPlaceholder();
    }
    if (widget.message.content.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasCode = widget.message.content.contains('```');
    final content = hasCode
        ? _buildRichContent(widget.message.content)
        : _buildPlainContent(widget.message.content);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MiuixSpacing.lg,
        vertical: MiuixSpacing.md,
      ),
      decoration: _isUser ? _userBubbleDecoration() : _assistantBubbleDecoration(),
      child: content,
    );
  }

  BoxDecoration _userBubbleDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: MiuixColors.primaryGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(MiuixRadius.lg),
        topRight: Radius.circular(MiuixRadius.lg),
        bottomLeft: Radius.circular(MiuixRadius.lg),
        bottomRight: Radius.circular(MiuixRadius.sm),
      ),
      boxShadow: [
        BoxShadow(
          color: MiuixColors.primary.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  BoxDecoration _assistantBubbleDecoration() {
    return BoxDecoration(
      color: MiuixColors.surface.withOpacity(0.85),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(MiuixRadius.lg),
        topRight: Radius.circular(MiuixRadius.lg),
        bottomLeft: Radius.circular(MiuixRadius.sm),
        bottomRight: Radius.circular(MiuixRadius.lg),
      ),
      border: Border.all(
        color: MiuixColors.borderLight,
        width: 1,
      ),
      boxShadow: MiuixShadows.sm,
    );
  }

  Widget _buildPlainContent(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: MiuixFontSize.md,
        height: 1.6,
        color: _isUser ? Colors.white : MiuixColors.textPrimary,
      ),
    );
  }

  Widget _buildRichContent(String text) {
    final segments = <InlineSpan>[];
    final codeBlockRegex = RegExp(r'```(\w*)\n([\s\S]*?)```');
    int lastEnd = 0;

    for (final match in codeBlockRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        segments.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(
            fontSize: MiuixFontSize.md,
            height: 1.6,
            color: _isUser ? Colors.white : MiuixColors.textPrimary,
          ),
        ));
      }
      final language = match.group(1) ?? '';
      final code = match.group(2) ?? '';
      segments.add(WidgetSpan(
        child: _buildCodeBlock(language, code),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      segments.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(
          fontSize: MiuixFontSize.md,
          height: 1.6,
          color: _isUser ? Colors.white : MiuixColors.textPrimary,
        ),
      ));
    }

    if (segments.isEmpty) {
      return _buildPlainContent(text);
    }

    return RichText(text: TextSpan(children: segments));
  }

  Widget _buildCodeBlock(String language, String code) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: MiuixSpacing.sm),
      padding: const EdgeInsets.all(MiuixSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF282C34),
        borderRadius: MiuixRadius.smRadius,
        border: Border.all(color: const Color(0xFF3E4451), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MiuixSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: MiuixColors.primary.withOpacity(0.2),
                  borderRadius: MiuixRadius.xsRadius,
                ),
                child: Text(
                  language.isEmpty ? 'code' : language,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.xs,
                    color: MiuixColors.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              MiuixRipple(
                onTap: () {
                  // 复制代码
                },
                borderRadius: MiuixRadius.xs,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.copy,
                    size: 14,
                    color: Color(0xFFABB2BF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MiuixSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              code,
              style: const TextStyle(
                fontSize: MiuixFontSize.sm,
                height: 1.5,
                color: Color(0xFFABB2BF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingPlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MiuixSpacing.lg,
        vertical: MiuixSpacing.md,
      ),
      decoration: _assistantBubbleDecoration(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return Padding(
            padding: EdgeInsets.only(right: i == 2 ? 0 : 6),
            child: _TypingDot(index: i),
          );
        }),
      ),
    );
  }

  Widget _buildImageMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: MiuixSpacing.sm),
      child: MiuixRipple(
        onTap: () => widget.onImageTap?.call(widget.message.imageUrl!),
        borderRadius: MiuixRadius.md,
        child: ClipRRect(
          borderRadius: MiuixRadius.mdRadius,
          child: Image.network(
            widget.message.imageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 200,
                color: MiuixColors.surfaceVariant,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(MiuixColors.primary),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: MiuixColors.surfaceVariant,
                child: const Icon(
                  Icons.broken_image,
                  color: MiuixColors.textTertiary,
                  size: 40,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVideoMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: MiuixSpacing.sm),
      child: MiuixRipple(
        onTap: () => widget.onVideoTap?.call(widget.message.videoUrl!),
        borderRadius: MiuixRadius.md,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: MiuixRadius.mdRadius,
              child: Container(
                height: 180,
                width: double.infinity,
                color: MiuixColors.darkSurface,
                child: const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    size: 56,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
            if (widget.message.videoLoading)
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: MiuixRadius.mdRadius,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          MiuixColors.primary,
                        ),
                      ),
                      const SizedBox(height: MiuixSpacing.sm),
                      const Text(
                        '视频生成中...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: MiuixFontSize.sm,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenInfo() {
    return Padding(
      padding: const EdgeInsets.only(top: MiuixSpacing.xs, right: 4),
      child: Text(
        '${widget.message.tokensUsed} tokens',
        style: const TextStyle(
          fontSize: MiuixFontSize.xs,
          color: MiuixColors.textTertiary,
        ),
      ),
    );
  }
}

/// 打字指示器跳动圆点
class _TypingDot extends StatefulWidget {
  final int index;
  const _TypingDot({required this.index});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final delay = widget.index * 0.15;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = (_controller.value + delay) % 1.0;
        final scale = 0.6 + 0.4 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: MiuixColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
