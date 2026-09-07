import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixBottomSheet —— 底部弹出表
/// 从底部滑入 + 弹簧动画，圆角顶部，拖拽手柄，毛玻璃，支持可滚动内容
/// ============================================================

/// Miuix 风格底部弹出表
///
/// 用法：
/// ```dart
/// MiuixBottomSheet.show(
///   context,
///   title: '选择操作',
///   child: Column(children: [...]),
/// );
/// ```
class MiuixBottomSheet extends StatefulWidget {
  const MiuixBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.showHandle = true,
    this.showCloseButton = true,
    this.maxHeightFactor = 0.85,
    this.minHeightFactor = 0.3,
    this.enableDrag = true,
    this.backgroundColor,
    this.onDismiss,
  });

  /// 标题
  final String? title;

  /// 内容
  final Widget child;

  /// 是否显示拖拽手柄
  final bool showHandle;

  /// 是否显示关闭按钮
  final bool showCloseButton;

  /// 最大高度比例
  final double maxHeightFactor;

  /// 最小高度比例
  final double minHeightFactor;

  /// 是否启用拖拽
  final bool enableDrag;

  /// 背景色
  final Color? backgroundColor;

  /// 关闭回调
  final VoidCallback? onDismiss;

  /// 显示底部弹出表
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required Widget child,
    bool showHandle = true,
    bool showCloseButton = true,
    double maxHeightFactor = 0.85,
    double minHeightFactor = 0.3,
    bool enableDrag = true,
    Color? backgroundColor,
    VoidCallback? onDismiss,
    bool isScrollControlled = true,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return MiuixBottomSheet(
          title: title,
          child: child,
          showHandle: showHandle,
          showCloseButton: showCloseButton,
          maxHeightFactor: maxHeightFactor,
          minHeightFactor: minHeightFactor,
          enableDrag: enableDrag,
          backgroundColor: backgroundColor,
          onDismiss: onDismiss,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return _MiuixBottomSheetTransition(animation: animation, child: child);
      },
    );
  }

  @override
  State<MiuixBottomSheet> createState() => _MiuixBottomSheetState();
}

class _MiuixBottomSheetState extends State<MiuixBottomSheet> {
  double _dragOffset = 0;
  double _startDragY = 0;

  void _onDragStart(DragStartDetails details) {
    _startDragY = details.globalPosition.dy;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.enableDrag) return;
    setState(() {
      _dragOffset = details.globalPosition.dy - _startDragY;
      if (_dragOffset < 0) _dragOffset = 0;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.enableDrag) return;
    // 拖拽超过 100px 或速度足够快则关闭
    if (_dragOffset > 100 || details.velocity.pixelsPerSecond.dy > 500) {
      Navigator.of(context).pop();
      widget.onDismiss?.call();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double maxHeight = screenHeight * widget.maxHeightFactor;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Transform.translate(
        offset: Offset(0, _dragOffset),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.backgroundColor ??
                MiuixColors.surface.withOpacity(0.97),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(MiuixRadius.xxl),
            ),
            boxShadow: [
              BoxShadow(
                color: MiuixColors.primary.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(MiuixRadius.xxl),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 拖拽区域（手柄 + 标题）
                  GestureDetector(
                    onVerticalDragStart: _onDragStart,
                    onVerticalDragUpdate: _onDragUpdate,
                    onVerticalDragEnd: _onDragEnd,
                    child: Column(
                      children: [
                        // 拖拽手柄
                        if (widget.showHandle)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: MiuixSpacing.md,
                              bottom: MiuixSpacing.sm,
                            ),
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: MiuixColors.border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        // 标题栏
                        if (widget.title != null || widget.showCloseButton)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: MiuixSpacing.lg,
                              vertical: MiuixSpacing.sm,
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                if (widget.title != null)
                                  Text(
                                    widget.title!,
                                    style: TextStyle(
                                      color: MiuixColors.textPrimary,
                                      fontSize: MiuixFontSize.lg,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                                if (widget.showCloseButton)
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      widget.onDismiss?.call();
                                    },
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: MiuixColors.surfaceVariant,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: MiuixColors.textSecondary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // 分割线
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(
                      horizontal: MiuixSpacing.lg,
                    ),
                    color: MiuixColors.divider,
                  ),
                  // 可滚动内容
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(MiuixSpacing.lg),
                      child: widget.child,
                    ),
                  ),
                  // 底部安全区
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 底部弹出表转场：从底部滑入 + 弹簧
class _MiuixBottomSheetTransition extends StatelessWidget {
  const _MiuixBottomSheetTransition({
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
  }
}
