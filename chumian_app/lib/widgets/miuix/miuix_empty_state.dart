import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';

/// ============================================================
/// MiuixEmptyState —— 空状态
/// 粉色图标 + 文字 + 按钮，支持 mascot 图片
/// ============================================================

/// 空状态类型
enum MiuixEmptyStateType {
  /// 无数据
  noData,

  /// 无网络
  noNetwork,

  /// 无消息
  noMessage,

  /// 搜索无结果
  noResult,

  /// 自定义
  custom,
}

/// Miuix 风格空状态
///
/// 用法：
/// ```dart
/// MiuixEmptyState(
///   title: '暂无数据',
///   description: '快去添加一些内容吧',
///   actionLabel: '刷新',
///   onAction: () {},
/// )
/// ```
class MiuixEmptyState extends StatelessWidget {
  const MiuixEmptyState({
    super.key,
    this.type = MiuixEmptyStateType.noData,
    this.title,
    this.description,
    this.icon,
    this.iconSize = 80,
    this.mascotImage,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.backgroundColor,
    this.padding,
    this.showAnimation = true,
  });

  /// 类型
  final MiuixEmptyStateType type;

  /// 标题
  final String? title;

  /// 描述
  final String? description;

  /// 图标
  final IconData? icon;

  /// 图标大小
  final double iconSize;

  /// mascot 图片
  final String? mascotImage;

  /// 主操作按钮文字
  final String? actionLabel;

  /// 主操作回调
  final VoidCallback? onAction;

  /// 次操作按钮文字
  final String? secondaryActionLabel;

  /// 次操作回调
  final VoidCallback? onSecondaryAction;

  /// 背景色
  final Color? backgroundColor;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 是否显示动画
  final bool showAnimation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: MiuixSpacing.xl,
            vertical: MiuixSpacing.xxxl,
          ),
      color: backgroundColor ?? Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 图标 / mascot
          _buildIcon(),
          const SizedBox(height: MiuixSpacing.lg),
          // 标题
          Text(
            title ?? _getDefaultTitle(),
            style: TextStyle(
              color: MiuixColors.textPrimary,
              fontSize: MiuixFontSize.xl,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          if (description != null) ...[
            const SizedBox(height: MiuixSpacing.sm),
            Text(
              description!,
              style: TextStyle(
                color: MiuixColors.textSecondary,
                fontSize: MiuixFontSize.md,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          // 操作按钮
          if (actionLabel != null) ...[
            const SizedBox(height: MiuixSpacing.xl),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (secondaryActionLabel != null) ...[
                  MiuixButton(
                    label: secondaryActionLabel!,
                    type: MiuixButtonType.secondary,
                    onPressed: onSecondaryAction,
                  ),
                  const SizedBox(width: MiuixSpacing.md),
                ],
                MiuixButton(
                  label: actionLabel!,
                  onPressed: onAction,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIcon() {
    if (mascotImage != null) {
      return Image.asset(
        mascotImage!,
        width: iconSize * 1.5,
        height: iconSize * 1.5,
        fit: BoxFit.contain,
      );
    }

    final IconData iconData = icon ?? _getDefaultIcon();

    return showAnimation
        ? _BouncingIcon(icon: iconData, size: iconSize)
        : Container(
            width: iconSize * 1.4,
            height: iconSize * 1.4,
            decoration: BoxDecoration(
              color: MiuixColors.primaryLight.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              size: iconSize * 0.6,
              color: MiuixColors.primary,
            ),
          );
  }

  IconData _getDefaultIcon() {
    switch (type) {
      case MiuixEmptyStateType.noData:
        return Icons.inbox_outlined;
      case MiuixEmptyStateType.noNetwork:
        return Icons.wifi_off_outlined;
      case MiuixEmptyStateType.noMessage:
        return Icons.chat_bubble_outline;
      case MiuixEmptyStateType.noResult:
        return Icons.search_off_outlined;
      case MiuixEmptyStateType.custom:
        return Icons.sentiment_neutral_outlined;
    }
  }

  String _getDefaultTitle() {
    switch (type) {
      case MiuixEmptyStateType.noData:
        return '暂无数据';
      case MiuixEmptyStateType.noNetwork:
        return '网络连接失败';
      case MiuixEmptyStateType.noMessage:
        return '暂无消息';
      case MiuixEmptyStateType.noResult:
        return '未找到结果';
      case MiuixEmptyStateType.custom:
        return '空空如也';
    }
  }
}

/// 弹跳图标动画
class _BouncingIcon extends StatefulWidget {
  const _BouncingIcon({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  State<_BouncingIcon> createState() => _BouncingIconState();
}

class _BouncingIconState extends State<_BouncingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: child,
        );
      },
      child: Container(
        width: widget.size * 1.4,
        height: widget.size * 1.4,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              MiuixColors.primaryLight.withOpacity(0.2),
              MiuixColors.primary.withOpacity(0.05),
            ],
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(
          widget.icon,
          size: widget.size * 0.6,
          color: MiuixColors.primary,
        ),
      ),
    );
  }
}
