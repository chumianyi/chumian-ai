import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// ChatMessageActions —— 消息操作菜单
/// 复制(纯文本)、重新生成、删除、收藏、分享、翻译
/// 底部弹出表，水晕反馈，粉色主题
/// ============================================================

/// 消息操作类型
enum MessageAction {
  copy,
  regenerate,
  delete,
  favorite,
  share,
  translate,
}

/// 消息操作菜单
class ChatMessageActions {
  static Future<MessageAction?> show(
    BuildContext context, {
    bool isUserMessage = false,
    bool isFavorited = false,
  }) {
    return showModalBottomSheet<MessageAction>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black26,
      builder: (context) => _MessageActionsSheet(
        isUserMessage: isUserMessage,
        isFavorited: isFavorited,
      ),
    );
  }
}

class _MessageActionsSheet extends StatefulWidget {
  final bool isUserMessage;
  final bool isFavorited;

  const _MessageActionsSheet({
    required this.isUserMessage,
    required this.isFavorited,
  });

  @override
  State<_MessageActionsSheet> createState() => _MessageActionsSheetState();
}

class _MessageActionsSheetState extends State<_MessageActionsSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<_ActionItem> _allActions = [
    _ActionItem(
      action: MessageAction.copy,
      icon: Icons.copy_all,
      label: '复制',
      color: MiuixColors.primary,
    ),
    _ActionItem(
      action: MessageAction.regenerate,
      icon: Icons.refresh,
      label: '重新生成',
      color: MiuixColors.info,
    ),
    _ActionItem(
      action: MessageAction.translate,
      icon: Icons.translate,
      label: '翻译',
      color: MiuixColors.success,
    ),
    _ActionItem(
      action: MessageAction.favorite,
      icon: Icons.favorite_border,
      label: '收藏',
      color: MiuixColors.warning,
    ),
    _ActionItem(
      action: MessageAction.share,
      icon: Icons.share,
      label: '分享',
      color: MiuixColors.primaryDark,
    ),
    _ActionItem(
      action: MessageAction.delete,
      icon: Icons.delete_outline,
      label: '删除',
      color: MiuixColors.error,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MiuixDuration.normal,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_ActionItem> get _visibleActions {
    if (widget.isUserMessage) {
      return _allActions
          .where((a) => a.action != MessageAction.regenerate)
          .where((a) => a.action != MessageAction.translate)
          .toList();
    }
    return _allActions;
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: MiuixCurves.easeOut,
      )),
      child: Container(
        decoration: BoxDecoration(
          color: MiuixColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(MiuixRadius.xl),
          ),
          boxShadow: MiuixShadows.lg,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(MiuixSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MiuixColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: MiuixSpacing.lg),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: MiuixSpacing.md,
                    crossAxisSpacing: MiuixSpacing.md,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: _visibleActions.length,
                  itemBuilder: (context, index) {
                    final action = _visibleActions[index];
                    return _buildActionItem(action, index);
                  },
                ),
                const SizedBox(height: MiuixSpacing.lg),
                MiuixRipple(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: MiuixRadius.lg,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: MiuixSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: MiuixColors.surfaceVariant,
                      borderRadius: MiuixRadius.lgRadius,
                    ),
                    child: const Center(
                      child: Text(
                        '取消',
                        style: TextStyle(
                          fontSize: MiuixFontSize.md,
                          fontWeight: FontWeight.w500,
                          color: MiuixColors.textSecondary,
                        ),
                      ),
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

  Widget _buildActionItem(_ActionItem action, int index) {
    final anim = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        0.1 + index * 0.05,
        1.0,
        curve: MiuixCurves.easeOut,
      ),
    );

    final isFav = action.action == MessageAction.favorite && widget.isFavorited;

    return FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(anim),
        child: MiuixRipple(
          onTap: () => Navigator.of(context).pop(action.action),
          borderRadius: MiuixRadius.md,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.1),
                  borderRadius: MiuixRadius.lgRadius,
                ),
                child: Icon(
                  isFav ? Icons.favorite : action.icon,
                  size: 24,
                  color: isFav ? MiuixColors.error : action.color,
                ),
              ),
              const SizedBox(height: MiuixSpacing.sm),
              Text(
                isFav ? '已收藏' : action.label,
                style: const TextStyle(
                  fontSize: MiuixFontSize.sm,
                  color: MiuixColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionItem {
  final MessageAction action;
  final IconData icon;
  final String label;
  final Color color;

  const _ActionItem({
    required this.action,
    required this.icon,
    required this.label,
    required this.color,
  });
}
