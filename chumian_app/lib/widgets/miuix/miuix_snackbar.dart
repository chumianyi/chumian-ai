import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixSnackBar —— 底部消息条
/// 粉色毛玻璃，滑入动画，操作按钮
/// ============================================================

/// Miuix 风格 SnackBar
///
/// 用法：
/// ```dart
/// MiuixSnackBar.show(
///   context,
///   message: '消息已发送',
///   actionLabel: '撤销',
///   onAction: () {},
/// );
/// ```
class MiuixSnackBar {
  MiuixSnackBar._();

  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  /// 显示 SnackBar
  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
    Color? backgroundColor,
    Color? actionColor,
  }) {
    if (_isShowing) {
      _overlayEntry?.remove();
      _isShowing = false;
    }

    final OverlayState overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => _MiuixSnackBarWidget(
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
        icon: icon,
        backgroundColor: backgroundColor,
        actionColor: actionColor,
        onDismiss: () {
          _overlayEntry?.remove();
          _isShowing = false;
        },
      ),
    );

    _isShowing = true;
    overlayState.insert(_overlayEntry!);

    Future.delayed(duration, () {
      if (_isShowing) {
        _overlayEntry?.remove();
        _isShowing = false;
      }
    });
  }
}

/// SnackBar 内部 Widget
class _MiuixSnackBarWidget extends StatefulWidget {
  const _MiuixSnackBarWidget({
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon,
    this.backgroundColor,
    this.actionColor,
    required this.onDismiss,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? actionColor;
  final VoidCallback onDismiss;

  @override
  State<_MiuixSnackBarWidget> createState() => _MiuixSnackBarWidgetState();
}

class _MiuixSnackBarWidgetState extends State<_MiuixSnackBarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
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

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom + 16;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          bottom: bottomInset,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: _slideAnimation,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: MiuixSpacing.lg),
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(MiuixRadius.lg),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MiuixSpacing.lg,
                  vertical: MiuixSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: widget.backgroundColor ??
                      MiuixColors.textPrimary.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(MiuixRadius.lg),
                  border: Border.all(
                    color: MiuixColors.primary.withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: MiuixColors.primary.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: 20,
                        color: MiuixColors.primaryLight,
                      ),
                      const SizedBox(width: MiuixSpacing.sm),
                    ],
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: MiuixFontSize.md,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (widget.actionLabel != null) ...[
                      const SizedBox(width: MiuixSpacing.md),
                      GestureDetector(
                        onTap: () {
                          widget.onAction?.call();
                          widget.onDismiss();
                        },
                        child: Text(
                          widget.actionLabel!,
                          style: TextStyle(
                            color: widget.actionColor ??
                                MiuixColors.primaryLight,
                            fontSize: MiuixFontSize.md,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
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
