import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixDraggableSheet —— Miuix 风格可拖拽底部表
/// 多档位(半屏/全屏/收起)，弹簧物理，拖拽手柄，毛玻璃
/// ============================================================

/// 底部表档位
enum MiuixSheetSnap {
  /// 收起（隐藏）
  hidden,

  /// 小屏（25%）
  small,

  /// 半屏（50%）
  half,

  /// 全屏（90%）
  full,
}

/// Miuix 风格可拖拽底部表
///
/// 用法：
/// ```dart
/// MiuixDraggableSheet(
///   initialSnap: MiuixSheetSnap.half,
///   child: ListView(...),
/// )
/// ```
class MiuixDraggableSheet extends StatefulWidget {
  const MiuixDraggableSheet({
    super.key,
    required this.child,
    this.initialSnap = MiuixSheetSnap.half,
    this.snaps = const [
      MiuixSheetSnap.hidden,
      MiuixSheetSnap.small,
      MiuixSheetSnap.half,
      MiuixSheetSnap.full,
    ],
    this.showHandle = true,
    this.backgroundColor,
    this.onSnapChanged,
    this.header,
  });

  /// 内容
  final Widget child;

  /// 初始档位
  final MiuixSheetSnap initialSnap;

  /// 可用档位
  final List<MiuixSheetSnap> snaps;

  /// 是否显示拖拽手柄
  final bool showHandle;

  /// 背景色
  final Color? backgroundColor;

  /// 档位变化回调
  final ValueChanged<MiuixSheetSnap>? onSnapChanged;

  /// 头部内容
  final Widget? header;

  @override
  State<MiuixDraggableSheet> createState() => _MiuixDraggableSheetState();
}

class _MiuixDraggableSheetState extends State<MiuixDraggableSheet>
    with SingleTickerProviderStateMixin {
  late double _currentExtent;
  late MiuixSheetSnap _currentSnap;
  double _dragStartY = 0;
  double _dragStartExtent = 0;
  bool _isDragging = false;
  late final AnimationController _animController;
  late final Animation<double> _anim;

  static const Map<MiuixSheetSnap, double> _snapValues = {
    MiuixSheetSnap.hidden: 0.0,
    MiuixSheetSnap.small: 0.25,
    MiuixSheetSnap.half: 0.5,
    MiuixSheetSnap.full: 0.9,
  };

  @override
  void initState() {
    super.initState();
    _currentSnap = widget.initialSnap;
    _currentExtent = _snapValues[widget.initialSnap]!;
    _animController = AnimationController(
      vsync: this,
      duration: MiuixDuration.elastic,
    );
    _anim = CurvedAnimation(
      parent: _animController,
      curve: MiuixCurves.miuixSpring,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  double get _sheetHeight =>
      MediaQuery.of(context).size.height * _currentExtent;

  void _onVerticalDragStart(DragStartDetails details) {
    _isDragging = true;
    _dragStartY = details.globalPosition.dy;
    _dragStartExtent = _currentExtent;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    final screenHeight = MediaQuery.of(context).size.height;
    final delta = (details.globalPosition.dy - _dragStartY) / screenHeight;
    setState(() {
      _currentExtent = (_dragStartExtent - delta).clamp(0.0, 0.95);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _isDragging = false;
    // 找到最近的档位
    MiuixSheetSnap nearestSnap = widget.snaps.first;
    double nearestDist = double.infinity;
    for (final snap in widget.snaps) {
      final dist = (_snapValues[snap]! - _currentExtent).abs();
      if (dist < nearestDist) {
        nearestDist = dist;
        nearestSnap = snap;
      }
    }
    // 考虑速度
    if (details.primaryVelocity! < -500) {
      // 快速上滑，找更高档位
      final higher = widget.snaps
          .where((s) => _snapValues[s]! > _currentExtent)
          .toList();
      if (higher.isNotEmpty) nearestSnap = higher.first;
    } else if (details.primaryVelocity! > 500) {
      // 快速下滑，找更低档位
      final lower = widget.snaps
          .where((s) => _snapValues[s]! < _currentExtent)
          .toList();
      if (lower.isNotEmpty) nearestSnap = lower.last;
    }

    _animateToSnap(nearestSnap);
  }

  void _animateToSnap(MiuixSheetSnap snap) {
    final target = _snapValues[snap]!;
    final start = _currentExtent;
    _animController.reset();
    _anim.addListener(() {
      setState(() {
        _currentExtent = start + (target - start) * _anim.value;
      });
    });
    _animController.forward().then((_) {
      _anim.removeListener(() {});
      setState(() {
        _currentSnap = snap;
        _currentExtent = target;
      });
      widget.onSnapChanged?.call(snap);
    });
  }

  /// 公开方法：编程式切换档位
  void snapTo(MiuixSheetSnap snap) {
    if (mounted) _animateToSnap(snap);
  }

  /// 当前是否展开
  bool get isOpen => _currentExtent > 0.01;

  /// 当前档位
  MiuixSheetSnap get currentSnap => _currentSnap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 背景遮罩
        if (_currentExtent > 0.01)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _animateToSnap(MiuixSheetSnap.hidden),
              child: AnimatedOpacity(
                opacity: _currentExtent > 0.1 ? 0.4 : 0.0,
                duration: MiuixDuration.fast,
                child: Container(color: Colors.black),
              ),
            ),
          ),
        // 底部表
        AnimatedBuilder(
          animation: _anim,
          builder: (context, child) {
            return Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _sheetHeight,
              child: child!,
            );
          },
          child: GestureDetector(
            onVerticalDragStart: _onVerticalDragStart,
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            child: Container(
              decoration: BoxDecoration(
                color: widget.backgroundColor ??
                    Colors.white.withOpacity(0.85),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(MiuixRadius.xxl),
                ),
                boxShadow: [
                  BoxShadow(
                    color: MiuixColors.primary.withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(MiuixRadius.xxl),
                ),
                child: BackdropFilter(
                  filter: ColorFilter.mode(
                    Colors.white.withOpacity(0.7),
                    BlendMode.srcOver,
                  ),
                  child: Column(
                    children: [
                      // 拖拽手柄
                      if (widget.showHandle)
                        Padding(
                          padding: const EdgeInsets.only(top: MiuixSpacing.sm),
                          child: Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: MiuixColors.border,
                                borderRadius:
                                    BorderRadius.circular(MiuixRadius.pill),
                              ),
                            ),
                          ),
                        ),
                      if (widget.header != null) widget.header!,
                      Expanded(child: widget.child),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ============================================================
/// MiuixBottomSheet —— 静态底部弹窗
/// 带粉色手柄和圆角的底部表
/// ============================================================
class MiuixBottomSheet extends StatelessWidget {
  const MiuixBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.showHandle = true,
    this.maxHeight,
    this.backgroundColor,
  });

  final Widget child;
  final String? title;
  final bool showHandle;
  final double? maxHeight;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? MiuixColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(MiuixRadius.xxl),
        ),
        boxShadow: [
          BoxShadow(
            color: MiuixColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHandle)
            Padding(
              padding: const EdgeInsets.only(top: MiuixSpacing.sm),
              child: Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: MiuixColors.border,
                    borderRadius: BorderRadius.circular(MiuixRadius.pill),
                  ),
                ),
              ),
            ),
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MiuixSpacing.lg,
                MiuixSpacing.md,
                MiuixSpacing.lg,
                MiuixSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(
                    title!,
                    style: const TextStyle(
                      color: MiuixColors.textPrimary,
                      fontSize: MiuixFontSize.lg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
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
          Flexible(child: child),
        ],
      ),
    );
  }

  /// 显示底部弹窗
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    bool showHandle = true,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (context) => MiuixBottomSheet(
        title: title,
        showHandle: showHandle,
        backgroundColor: backgroundColor,
        child: child,
      ),
    );
  }
}

/// ============================================================
/// MiuixSheetActionList —— 底部操作列表
/// 带图标的操作项列表，常用于分享/操作菜单
/// ============================================================
class MiuixSheetActionList extends StatelessWidget {
  const MiuixSheetActionList({
    super.key,
    required this.actions,
  });

  final List<MiuixSheetAction> actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...actions.map((action) => _buildActionItem(context, action)),
          const SizedBox(height: MiuixSpacing.sm),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(
                horizontal: MiuixSpacing.md,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: MiuixSpacing.md,
              ),
              decoration: BoxDecoration(
                color: MiuixColors.surfaceVariant,
                borderRadius: BorderRadius.circular(MiuixRadius.md),
              ),
              child: const Center(
                child: Text(
                  '取消',
                  style: TextStyle(
                    color: MiuixColors.textSecondary,
                    fontSize: MiuixFontSize.md,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: MiuixSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, MiuixSheetAction action) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        action.onPressed?.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: MiuixSpacing.md,
          vertical: 2,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: MiuixSpacing.md,
          vertical: MiuixSpacing.md,
        ),
        decoration: BoxDecoration(
          color: MiuixColors.surface,
          borderRadius: BorderRadius.circular(MiuixRadius.md),
        ),
        child: Row(
          children: [
            Icon(action.icon, color: action.color ?? MiuixColors.primary, size: 20),
            const SizedBox(width: MiuixSpacing.md),
            Text(
              action.label,
              style: TextStyle(
                color: action.color ?? MiuixColors.textPrimary,
                fontSize: MiuixFontSize.md,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 底部操作项
class MiuixSheetAction {
  const MiuixSheetAction({
    required this.icon,
    required this.label,
    this.color,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onPressed;
}
