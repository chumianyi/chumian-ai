import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixSlidableTile —— Miuix 风格可滑动列表项
/// 左滑/右滑操作按钮，粉色操作背景，弹簧回弹，删除/收藏/分享
/// ============================================================

/// 滑动操作
class MiuixSlidableAction {
  const MiuixSlidableAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  /// 图标
  final IconData icon;

  /// 标签
  final String label;

  /// 背景色
  final Color color;

  /// 点击回调
  final VoidCallback onPressed;
}

/// Miuix 风格可滑动列表项
///
/// 用法：
/// ```dart
/// MiuixSlidableTile(
///   leftActions: [
///     MiuixSlidableAction(icon: Icons.favorite, label: '收藏', color: Colors.pink, onPressed: () {}),
///   ],
///   rightActions: [
///     MiuixSlidableAction(icon: Icons.delete, label: '删除', color: Colors.red, onPressed: () {}),
///   ],
///   child: ListTile(title: Text('列表项')),
/// )
/// ```
class MiuixSlidableTile extends StatefulWidget {
  const MiuixSlidableTile({
    super.key,
    required this.child,
    this.leftActions = const [],
    this.rightActions = const [],
    this.actionExtent = 80,
    this.onDismissed,
  });

  /// 列表项内容
  final Widget child;

  /// 左侧操作（右滑显示）
  final List<MiuixSlidableAction> leftActions;

  /// 右侧操作（左滑显示）
  final List<MiuixSlidableAction> rightActions;

  /// 每个操作按钮宽度
  final double actionExtent;

  /// 完全滑出回调
  final VoidCallback? onDismissed;

  @override
  State<MiuixSlidableTile> createState() => _MiuixSlidableTileState();
}

class _MiuixSlidableTileState extends State<MiuixSlidableTile>
    with SingleTickerProviderStateMixin {
  double _dragExtent = 0;
  bool _isDragging = false;
  late final AnimationController _controller;
  late final Animation<double> _animation;
  double _animStart = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MiuixDuration.elastic,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: MiuixCurves.miuixSpring,
    );
    _animation.addListener(() {
      setState(() {
        _dragExtent = _animStart + (0 - _animStart) * _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _maxLeftExtent => widget.leftActions.length * widget.actionExtent;
  double get _maxRightExtent =>
      widget.rightActions.length * widget.actionExtent;

  void _onHorizontalDragStart(DragStartDetails details) {
    _isDragging = true;
    _controller.stop();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() {
      _dragExtent += details.primaryDelta!;
      // 阻尼
      if (_dragExtent > _maxLeftExtent) {
        _dragExtent = _maxLeftExtent +
            (_dragExtent - _maxLeftExtent) * 0.3;
      } else if (_dragExtent < -_maxRightExtent) {
        _dragExtent = -_maxRightExtent +
            (_dragExtent + _maxRightExtent) * 0.3;
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    _isDragging = false;
    final velocity = details.primaryVelocity ?? 0;

    // 判断是否需要吸附
    double target = 0;
    if (_dragExtent > 0) {
      if (velocity > 500 || _dragExtent > _maxLeftExtent * 0.5) {
        target = _maxLeftExtent;
      }
    } else if (_dragExtent < 0) {
      if (velocity < -500 || _dragExtent < -_maxRightExtent * 0.5) {
        target = -_maxRightExtent;
      }
    }

    _animStart = _dragExtent;
    _controller.reset();
    _controller.forward().then((_) {
      setState(() => _dragExtent = target);
      if (target.abs() > _maxLeftExtent * 1.5 ||
          target.abs() > _maxRightExtent * 1.5) {
        widget.onDismissed?.call();
      }
    });
    // 手动设置动画终点
    _animation.removeListener(() {});
    _animation.addListener(() {
      setState(() {
        _dragExtent = _animStart + (target - _animStart) * _animation.value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 左侧操作背景
        if (widget.leftActions.isNotEmpty && _dragExtent > 0)
          Positioned.fill(
            child: Row(
              children: widget.leftActions.map((action) {
                return Expanded(
                  child: _buildActionButton(action, isLeft: true),
                );
              }).toList(),
            ),
          ),
        // 右侧操作背景
        if (widget.rightActions.isNotEmpty && _dragExtent < 0)
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: widget.rightActions.map((action) {
                return Expanded(
                  child: _buildActionButton(action, isLeft: false),
                );
              }).toList(),
            ),
          ),
        // 前景内容
        GestureDetector(
          onHorizontalDragStart: _onHorizontalDragStart,
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: Transform.translate(
            offset: Offset(_dragExtent, 0),
            child: widget.child,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(MiuixSlidableAction action,
      {required bool isLeft}) {
    return GestureDetector(
      onTap: () {
        action.onPressed();
        // 回弹
        _animStart = _dragExtent;
        _controller.reset();
        _animation.removeListener(() {});
        _animation.addListener(() {
          setState(() {
            _dragExtent = _animStart * (1 - _animation.value);
          });
        });
        _controller.forward();
      },
      child: Container(
        color: action.color,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              action.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: MiuixFontSize.xs,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// MiuixSwipeAction —— 预定义的滑动操作
/// 提供删除、收藏、分享、编辑等常用操作
/// ============================================================
class MiuixSwipeActions {
  /// 删除操作
  static MiuixSlidableAction delete(VoidCallback onPressed) {
    return MiuixSlidableAction(
      icon: Icons.delete,
      label: '删除',
      color: MiuixColors.error,
      onPressed: onPressed,
    );
  }

  /// 收藏操作
  static MiuixSlidableAction favorite(VoidCallback onPressed) {
    return MiuixSlidableAction(
      icon: Icons.favorite,
      label: '收藏',
      color: MiuixColors.primary,
      onPressed: onPressed,
    );
  }

  /// 分享操作
  static MiuixSlidableAction share(VoidCallback onPressed) {
    return MiuixSlidableAction(
      icon: Icons.share,
      label: '分享',
      color: MiuixColors.info,
      onPressed: onPressed,
    );
  }

  /// 编辑操作
  static MiuixSlidableAction edit(VoidCallback onPressed) {
    return MiuixSlidableAction(
      icon: Icons.edit,
      label: '编辑',
      color: MiuixColors.warning,
      onPressed: onPressed,
    );
  }

  /// 归档操作
  static MiuixSlidableAction archive(VoidCallback onPressed) {
    return MiuixSlidableAction(
      icon: Icons.archive,
      label: '归档',
      color: MiuixColors.success,
      onPressed: onPressed,
    );
  }
}

/// ============================================================
/// MiuixSlidableList —— 可滑动列表
/// 封装了可滑动列表项的 ListView
/// ============================================================
class MiuixSlidableList extends StatelessWidget {
  const MiuixSlidableList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.leftActionsBuilder,
    this.rightActionsBuilder,
    this.itemExtent,
    this.padding,
  });

  final List<dynamic> items;
  final Widget Function(BuildContext context, int index, dynamic item)
      itemBuilder;
  final List<MiuixSlidableAction> Function(int index, dynamic item)?
      leftActionsBuilder;
  final List<MiuixSlidableAction> Function(int index, dynamic item)?
      rightActionsBuilder;
  final double? itemExtent;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemExtent: itemExtent,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return MiuixSlidableTile(
          leftActions: leftActionsBuilder?.call(index, item) ?? const [],
          rightActions: rightActionsBuilder?.call(index, item) ?? const [],
          child: itemBuilder(context, index, item),
        );
      },
    );
  }
}
