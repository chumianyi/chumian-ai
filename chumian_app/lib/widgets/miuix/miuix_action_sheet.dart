import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// MiuixActionSheet —— 操作表
/// 从底部弹出，每项带图标+文字，取消项分离，水晕反馈
/// ============================================================

/// 操作表项
class MiuixActionSheetItem {
  const MiuixActionSheetItem({
    required this.label,
    this.icon,
    this.iconColor,
    this.textColor,
    this.isDestructive = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final Color? iconColor;
  final Color? textColor;
  final bool isDestructive;
  final VoidCallback? onTap;
}

/// Miuix 风格操作表
///
/// 用法：
/// ```dart
/// MiuixActionSheet.show(
///   context,
///   title: '选择操作',
///   items: [
///     MiuixActionSheetItem(label: '编辑', icon: Icons.edit),
///     MiuixActionSheetItem(label: '删除', icon: Icons.delete, isDestructive: true),
///   ],
/// );
/// ```
class MiuixActionSheet {
  MiuixActionSheet._();

  /// 显示操作表
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required List<MiuixActionSheetItem> items,
    String cancelText = '取消',
    bool showCancel = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _MiuixActionSheetWidget(
          title: title,
          items: items,
          cancelText: cancelText,
          showCancel: showCancel,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final double offset =
                (1 - Curves.elasticOut.transform(animation.value)) *
                    MediaQuery.of(context).size.height;
            return Transform.translate(
              offset: Offset(0, offset),
              child: child,
            );
          },
          child: child,
        );
      },
    );
  }
}

/// 操作表内部 Widget
class _MiuixActionSheetWidget extends StatelessWidget {
  const _MiuixActionSheetWidget({
    required this.items,
    this.title,
    this.cancelText = '取消',
    this.showCancel = true,
  });

  final List<MiuixActionSheetItem> items;
  final String? title;
  final String cancelText;
  final bool showCancel;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(MiuixSpacing.md),
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(MiuixRadius.xl),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: MiuixColors.surface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(MiuixRadius.xl),
                  border: Border.all(color: MiuixColors.glassBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题
                    if (title != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: MiuixSpacing.md,
                        ),
                        child: Text(
                          title!,
                          style: TextStyle(
                            color: MiuixColors.textTertiary,
                            fontSize: MiuixFontSize.sm,
                          ),
                        ),
                      ),
                      Container(
                        height: 0.5,
                        color: MiuixColors.divider,
                      ),
                    ],
                    // 操作项
                    ...items.asMap().entries.map((entry) {
                      final int index = entry.key;
                      final MiuixActionSheetItem item = entry.value;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ActionSheetItemWidget(item: item),
                          if (index < items.length - 1)
                            Container(
                              height: 0.5,
                              margin: const EdgeInsets.only(left: 56),
                              color: MiuixColors.divider,
                            ),
                        ],
                      );
                    }),
                    SizedBox(height: bottomInset > 0 ? 8 : 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 单个操作项
class _ActionSheetItemWidget extends StatefulWidget {
  const _ActionSheetItemWidget({required this.item});

  final MiuixActionSheetItem item;

  @override
  State<_ActionSheetItemWidget> createState() => _ActionSheetItemWidgetState();
}

class _ActionSheetItemWidgetState extends State<_ActionSheetItemWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MiuixDuration.fast,
      reverseDuration: MiuixDuration.elastic,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.96),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.96, end: 1.0)
            .chain(CurveTween(curve: MiuixCurves.miuixSpring)),
        weight: 70,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = widget.item.isDestructive
        ? MiuixColors.error
        : (widget.item.textColor ?? MiuixColors.textPrimary);
    final Color iconColor = widget.item.isDestructive
        ? MiuixColors.error
        : (widget.item.iconColor ?? MiuixColors.primary);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        Navigator.of(context).pop();
        widget.item.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: MiuixRipple(
          color: MiuixColors.primary.withOpacity(0.1),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: MiuixSpacing.lg,
              vertical: MiuixSpacing.md + 2,
            ),
            child: Row(
              children: [
                if (widget.item.icon != null) ...[
                  Icon(widget.item.icon, size: 22, color: iconColor),
                  const SizedBox(width: MiuixSpacing.md),
                ],
                Expanded(
                  child: Text(
                    widget.item.label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: MiuixFontSize.lg,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: MiuixColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
