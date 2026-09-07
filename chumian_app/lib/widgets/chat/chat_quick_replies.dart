import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// ChatQuickReplies —— 快捷回复组件
/// AI 回复后的建议操作按钮
/// 继续追问/换个说法/更详细/更简洁
/// 粉色胶囊，横向滚动，水晕反馈
/// ============================================================

/// 快捷回复类型
enum QuickReplyType {
  followUp,
  rephrase,
  moreDetail,
  moreConcise,
  custom,
}

/// 快捷回复项
class QuickReplyItem {
  final QuickReplyType type;
  final String label;
  final IconData icon;
  final String? prompt;

  const QuickReplyItem({
    required this.type,
    required this.label,
    required this.icon,
    this.prompt,
  });
}

class ChatQuickReplies extends StatefulWidget {
  const ChatQuickReplies({
    super.key,
    this.items,
    this.onTap,
    this.showDivider = true,
  });

  /// 快捷回复项列表，为空时使用默认四项
  final List<QuickReplyItem>? items;

  /// 点击回调
  final ValueChanged<QuickReplyItem>? onTap;

  /// 是否显示分割线
  final bool showDivider;

  @override
  State<ChatQuickReplies> createState() => _ChatQuickRepliesState();
}

class _ChatQuickRepliesState extends State<ChatQuickReplies>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const List<QuickReplyItem> _defaultItems = [
    QuickReplyItem(
      type: QuickReplyType.followUp,
      label: '继续追问',
      icon: Icons.arrow_forward,
      prompt: '请继续深入讲解',
    ),
    QuickReplyItem(
      type: QuickReplyType.rephrase,
      label: '换个说法',
      icon: Icons.refresh,
      prompt: '请换一种方式重新解释',
    ),
    QuickReplyItem(
      type: QuickReplyType.moreDetail,
      label: '更详细',
      icon: Icons.expand,
      prompt: '请更详细地展开说明',
    ),
    QuickReplyItem(
      type: QuickReplyType.moreConcise,
      label: '更简洁',
      icon: Icons.compress,
      prompt: '请用更简洁的语言总结',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<QuickReplyItem> get _items => widget.items ?? _defaultItems;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: MiuixCurves.easeOut,
        )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showDivider)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MiuixSpacing.lg,
                  vertical: MiuixSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: MiuixColors.divider,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: MiuixSpacing.sm),
                      child: Text(
                        '快捷操作',
                        style: TextStyle(
                          fontSize: MiuixFontSize.xs,
                          color: MiuixColors.textTertiary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: MiuixColors.divider,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: MiuixSpacing.md,
                ),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(width: MiuixSpacing.sm),
                itemBuilder: (context, index) {
                  return _buildQuickReplyChip(_items[index], index);
                },
              ),
            ),
            const SizedBox(height: MiuixSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplyChip(QuickReplyItem item, int index) {
    final anim = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        0.1 + index * 0.08,
        1.0,
        curve: MiuixCurves.easeOut,
      ),
    );

    return FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(anim),
        child: MiuixRipple(
          onTap: () => widget.onTap?.call(item),
          borderRadius: MiuixRadius.pill,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MiuixSpacing.md,
              vertical: MiuixSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: MiuixColors.primary.withValues(alpha: 0.06),
              borderRadius: MiuixRadius.pillRadius,
              border: Border.all(
                color: MiuixColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: 14,
                  color: MiuixColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.sm,
                    fontWeight: FontWeight.w500,
                    color: MiuixColors.primary,
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
