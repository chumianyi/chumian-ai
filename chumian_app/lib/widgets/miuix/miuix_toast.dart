import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixToast —— 顶部/底部 Toast
/// 滑入淡入，粉色半透明毛玻璃，自动消失
/// 支持 success/error/warning/info 图标
/// ============================================================

/// Toast 类型
enum MiuixToastType {
  success,
  error,
  warning,
  info,
  custom,
}

/// Toast 位置
enum MiuixToastPosition {
  top,
  bottom,
  center,
}

/// Miuix 风格 Toast
///
/// 用法：
/// ```dart
/// MiuixToast.show(
///   context,
///   message: '操作成功',
///   type: MiuixToastType.success,
/// );
/// ```
class MiuixToast {
  MiuixToast._();

  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  /// 显示 Toast
  static void show(
    BuildContext context, {
    required String message,
    MiuixToastType type = MiuixToastType.info,
    MiuixToastPosition position = MiuixToastPosition.top,
    Duration duration = const Duration(seconds: 2),
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
  }) {
    // 如果已有 Toast 显示，先移除
    if (_isShowing) {
      _overlayEntry?.remove();
      _isShowing = false;
    }

    final OverlayState overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => _MiuixToastWidget(
        message: message,
        type: type,
        position: position,
        icon: icon,
        backgroundColor: backgroundColor,
        textColor: textColor,
        onDismiss: () {
          _overlayEntry?.remove();
          _isShowing = false;
        },
      ),
    );

    _isShowing = true;
    overlayState.insert(_overlayEntry!);

    // 自动消失
    Future.delayed(duration, () {
      if (_isShowing) {
        _overlayEntry?.remove();
        _isShowing = false;
      }
    });
  }

  /// 成功 Toast
  static void success(BuildContext context, String message) {
    show(context, message: message, type: MiuixToastType.success);
  }

  /// 错误 Toast
  static void error(BuildContext context, String message) {
    show(context, message: message, type: MiuixToastType.error);
  }

  /// 警告 Toast
  static void warning(BuildContext context, String message) {
    show(context, message: message, type: MiuixToastType.warning);
  }

  /// 信息 Toast
  static void info(BuildContext context, String message) {
    show(context, message: message, type: MiuixToastType.info);
  }
}

/// Toast 内部 Widget
class _MiuixToastWidget extends StatefulWidget {
  const _MiuixToastWidget({
    required this.message,
    required this.type,
    required this.position,
    this.icon,
    this.backgroundColor,
    this.textColor,
    required this.onDismiss,
  });

  final String message;
  final MiuixToastType type;
  final MiuixToastPosition position;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback onDismiss;

  @override
  State<_MiuixToastWidget> createState() => _MiuixToastWidgetState();
}

class _MiuixToastWidgetState extends State<_MiuixToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MiuixDuration.normal,
    );

    _slideAnimation = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 根据类型获取颜色
  Color _getTypeColor() {
    switch (widget.type) {
      case MiuixToastType.success:
        return MiuixColors.success;
      case MiuixToastType.error:
        return MiuixColors.error;
      case MiuixToastType.warning:
        return MiuixColors.warning;
      case MiuixToastType.info:
        return MiuixColors.info;
      case MiuixToastType.custom:
        return MiuixColors.primary;
    }
  }

  /// 根据类型获取图标
  IconData _getTypeIcon() {
    if (widget.icon != null) return widget.icon!;
    switch (widget.type) {
      case MiuixToastType.success:
        return Icons.check_circle;
      case MiuixToastType.error:
        return Icons.error;
      case MiuixToastType.warning:
        return Icons.warning;
      case MiuixToastType.info:
        return Icons.info;
      case MiuixToastType.custom:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color typeColor = _getTypeColor();
    final double topInset = MediaQuery.of(context).padding.top + 20;
    final double bottomInset = MediaQuery.of(context).padding.bottom + 20;

    Alignment alignment;
    EdgeInsets padding;
    switch (widget.position) {
      case MiuixToastPosition.top:
        alignment = Alignment.topCenter;
        padding = EdgeInsets.only(top: topInset);
        break;
      case MiuixToastPosition.bottom:
        alignment = Alignment.bottomCenter;
        padding = EdgeInsets.only(bottom: bottomInset);
        break;
      case MiuixToastPosition.center:
        alignment = Alignment.center;
        padding = EdgeInsets.zero;
        break;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: widget.position == MiuixToastPosition.top
              ? topInset + _slideAnimation.value * 80
              : null,
          bottom: widget.position == MiuixToastPosition.bottom
              ? bottomInset - _slideAnimation.value * 80
              : null,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: padding,
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(MiuixRadius.lg),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: MiuixSpacing.xl,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: MiuixSpacing.lg,
                    vertical: MiuixSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor ??
                        MiuixColors.surface.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(MiuixRadius.lg),
                    border: Border.all(
                      color: typeColor.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: typeColor.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTypeIcon(),
                        size: 20,
                        color: typeColor,
                      ),
                      const SizedBox(width: MiuixSpacing.sm),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            color: widget.textColor ??
                                MiuixColors.textPrimary,
                            fontSize: MiuixFontSize.md,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
