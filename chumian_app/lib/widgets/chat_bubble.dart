/// 聊天气泡与思考折叠面板组件。
library;

import 'package:flutter/material.dart';
import 'context_ext.dart';
import '../models/chat_message.dart';
import '../theme.dart';
import '../utils/animations.dart';
import 'avatar.dart';

/// 用户消息气泡。
class UserBubble extends StatelessWidget {
  final String content;
  final String? imageUrl;
  final VoidCallback? onImageTap;

  const UserBubble({
    super.key,
    required this.content,
    this.imageUrl,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: context.vibrantGradient,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty) ...[
              GestureDetector(
                onTap: onImageTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl!,
                    width: 220,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 220,
                      height: 140,
                      color: Colors.white10,
                      child: const Icon(Icons.broken_image_outlined, color: Colors.white54),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              content,
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: context.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AI 消息气泡（含思考折叠 + Markdown 内容插槽）。
class AiBubble extends StatelessWidget {
  final ChatMessage message;
  final Widget markdownBuilder;
  final VoidCallback? onImageTap;
  final VoidCallback? onVideoTap;
  final VoidCallback? onStop;

  const AiBubble({
    super.key,
    required this.message,
    required this.markdownBuilder,
    this.onImageTap,
    this.onVideoTap,
    this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.86),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const AppAvatar(
                  name: '初眠',
                  size: 24,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  message.model ?? '初眠AI',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondary,
                  ),
                ),
                const Spacer(),
                if (message.isThinking)
                  const TypingDots(color: AppTheme.primaryColor, size: 6),
              ],
            ),
            const SizedBox(height: 8),
            if (message.isThinking && message.thinkContent != null &&
                message.thinkContent!.isNotEmpty)
              ThinkPanel(message: message),
            if (message.isThinking && message.thinkContent == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: TypingDots(),
              ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              markdownBuilder,
            ],
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _imageBlock(context, message.imageUrl!),
            ],
            if (message.videoLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Spinner(size: 18),
                    SizedBox(width: 10),
                    Text('视频生成中…', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            if (message.isThinking && message.thinkContent != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onStop,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('停止生成', style: TextStyle(fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _imageBlock(BuildContext context, String url) {
    return GestureDetector(
      onTap: onImageTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          width: 240,
          height: 160,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 240,
              height: 160,
              color: context.surfaceSubtle,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            width: 240,
            height: 160,
            color: context.surfaceSubtle,
            child: Icon(Icons.broken_image_outlined, color: context.textTertiary, size: 32),
          ),
        ),
      ),
    );
  }
}

/// 思考过程折叠面板。
class ThinkPanel extends StatelessWidget {
  final ChatMessage message;

  const ThinkPanel({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: context.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.primary.withValues(alpha: 0.12)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: message.isExpanded,
          onExpansionChanged: (expanded) => message.isExpanded = expanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          leading: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: context.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.psychology_alt_outlined, size: 13, color: context.primary),
          ),
          title: Row(
            children: [
              Text(
                '思考过程',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.primary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${message.thinkContent?.length ?? 0}字',
                  style: TextStyle(fontSize: 10, color: context.primary),
                ),
              ),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message.thinkContent ?? '',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: context.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
