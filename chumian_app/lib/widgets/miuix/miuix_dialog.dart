import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';

/// ============================================================
/// MiuixDialog —— Miuix 风格弹窗
/// 缩放淡入动画，毛玻璃背景遮罩，连续曲率圆角，粉色标题栏
/// 支持确认/取消/自定义内容
/// ============================================================

/// 弹窗类型
enum MiuixDialogType {
  /// 信息提示
  info,

  /// 成功
  success,

  /// 警告
  warning,

  /// 错误
  error,

  /// 自定义
  custom,
}

/// Miuix 风格弹窗
///
/// 用法：
/// ```dart
/// MiuixDialog.show(
///   context,
///   title: '提示',
///   content: '确定要删除吗？',
///   onConfirm: () {},
/// );
/// ```
class MiuixDialog extends StatefulWidget {
  const MiuixDialog({
    super.key,
    this.title,
    this.content,
    this.contentWidget,
    this.type = MiuixDialogType.info,
    this.confirmText = '确认',
    this.cancelText = '取消',
    this.onConfirm,
    this.onCancel,
    this.showCancel = true,
    this.icon,
    this.customIcon,
    this.actions,
    this.barrierDismissible = true,
  });

  /// 标题
  final String? title;

  /// 内容文字
  final String? content;

  /// 自定义内容 Widget
  final Widget? contentWidget;

  /// 弹窗类型
  final MiuixDialogType type;

  /// 确认按钮文字
  final String confirmText;

  /// 取消按钮文字
  final String cancelText;

  /// 确认回调
  final VoidCallback? onConfirm;

  /// 取消回调
  final VoidCallback? onCancel;

  /// 是否显示取消按钮
  final bool showCancel;

  /// 图标
  final IconData? icon;

  /// 自定义图标 Widget
  final Widget? customIcon;

  /// 自定义操作按钮
  final List<Widget>? actions;

  /// 点击遮罩是否关闭
  final bool barrierDismissible;

  /// 显示弹窗
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    String? content,
    Widget? contentWidget,
    MiuixDialogType type = MiuixDialogType.info,
    String confirmText = '确认',
    String cancelText = '取消',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool showCancel = true,
    IconData? icon,
    Widget? customIcon,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: MiuixDuration.normal,
      pageBuilder: (context, animation, secondaryAnimation) {
        return MiuixDialog(
          title: title,
          content: content,
          contentWidget: contentWidget,
          type: type,
          confirmText: confirmText,
          cancelText: cancelText,
          onConfirm: onConfirm,
          onCancel: onCancel,
          showCancel: showCancel,
          icon: icon,
          customIcon: customIcon,
          actions: actions,
          barrierDismissible: barrierDismissible,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return _MiuixDialogTransition(animation: animation, child: child);
      },
    );
  }

  @override
  State<MiuixDialog> createState() => _MiuixDialogState();
}

class _MiuixDialogState extends State<MiuixDialog> {
  /// 根据类型获取图标颜色
  Color _getTypeColor() {
    switch (widget.type) {
      case MiuixDialogType.success:
        return MiuixColors.success;
      case MiuixDialogType.warning:
        return MiuixColors.warning;
      case MiuixDialogType.error:
        return MiuixColors.error;
      case MiuixDialogType.info:
      case MiuixDialogType.custom:
        return MiuixColors.primary;
    }
  }

  /// 根据类型获取图标
  IconData _getTypeIcon() {
    if (widget.icon != null) return widget.icon!;
    switch (widget.type) {
      case MiuixDialogType.success:
        return Icons.check_circle_outline;
      case MiuixDialogType.warning:
        return Icons.warning_amber_outlined;
      case MiuixDialogType.error:
        return Icons.error_outline;
      case MiuixDialogType.info:
        return Icons.info_outline;
      case MiuixDialogType.custom:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color typeColor = _getTypeColor();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: MiuixSpacing.xl),
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(MiuixRadius.xl),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 340),
                decoration: BoxDecoration(
                  color: MiuixColors.surface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(MiuixRadius.xl),
                  border: Border.all(
                    color: MiuixColors.glassBorder,
                    width: 1,
                  ),
                  boxShadow: MiuixShadows.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 粉色标题栏
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: MiuixSpacing.lg,
                        horizontal: MiuixSpacing.xl,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            typeColor.withOpacity(0.1),
                            typeColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        children: [
                          // 图标
                          if (widget.customIcon != null)
                            widget.customIcon!
                          else
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getTypeIcon(),
                                size: 30,
                                color: typeColor,
                              ),
                            ),
                          if (widget.title != null) ...[
                            const SizedBox(height: MiuixSpacing.md),
                            Text(
                              widget.title!,
                              style: TextStyle(
                                color: MiuixColors.textPrimary,
                                fontSize: MiuixFontSize.xl,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // 内容
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        MiuixSpacing.xl,
                        MiuixSpacing.lg,
                        MiuixSpacing.xl,
                        MiuixSpacing.lg,
                      ),
                      child: widget.contentWidget ??
                          Text(
                            widget.content ?? '',
                            style: TextStyle(
                              color: MiuixColors.textSecondary,
                              fontSize: MiuixFontSize.md,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                    ),
                    // 操作按钮
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        MiuixSpacing.xl,
                        0,
                        MiuixSpacing.xl,
                        MiuixSpacing.lg,
                      ),
                      child: widget.actions ??
                          Row(
                            children: [
                              if (widget.showCancel) ...[
                                Expanded(
                                  child: MiuixButton(
                                    label: widget.cancelText,
                                    type: MiuixButtonType.secondary,
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      widget.onCancel?.call();
                                    },
                                  ),
                                ),
                                const SizedBox(width: MiuixSpacing.md),
                              ],
                              Expanded(
                                child: MiuixButton(
                                  label: widget.confirmText,
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    widget.onConfirm?.call();
                                  },
                                ),
                              ),
                            ],
                          ),
                    ),
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

/// 弹窗转场动画：缩放 + 淡入
class _MiuixDialogTransition extends StatelessWidget {
  const _MiuixDialogTransition({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double scale = Curves.elasticOut.transform(animation.value);
        final double opacity = Curves.easeOut.transform(animation.value);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale.clamp(0.0, 1.1),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
