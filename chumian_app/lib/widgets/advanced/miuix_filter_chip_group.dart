import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixFilterChipGroup —— Miuix 风格筛选标签组
/// 可多选/单选标签，粉色选中态，展开/收起，动画
/// ============================================================

/// 筛选标签数据
class MiuixFilterChip {
  const MiuixFilterChip({
    required this.label,
    this.value,
    this.icon,
  });

  /// 标签文字
  final String label;

  /// 关联值
  final dynamic value;

  /// 图标
  final IconData? icon;
}

/// Miuix 风格筛选标签组
///
/// 用法：
/// ```dart
/// MiuixFilterChipGroup(
///   chips: [
///     MiuixFilterChip(label: '全部'),
///     MiuixFilterChip(label: '推荐'),
///   ],
///   onSelectionChanged: (selected) {},
/// )
/// ```
class MiuixFilterChipGroup extends StatefulWidget {
  const MiuixFilterChipGroup({
    super.key,
    required this.chips,
    this.initialSelected = const [],
    this.multiSelect = false,
    this.onSelectionChanged,
    this.collapsible = false,
    this.collapsedCount = 4,
    this.spacing = 8,
    this.runSpacing = 8,
  });

  /// 标签列表
  final List<MiuixFilterChip> chips;

  /// 初始选中索引
  final List<int> initialSelected;

  /// 是否多选
  final bool multiSelect;

  /// 选中变化回调
  final void Function(List<int> selectedIndices, List<MiuixFilterChip> selectedChips)?
      onSelectionChanged;

  /// 是否可折叠
  final bool collapsible;

  /// 折叠时显示数量
  final int collapsedCount;

  /// 水平间距
  final double spacing;

  /// 垂直间距
  final double runSpacing;

  @override
  State<MiuixFilterChipGroup> createState() => _MiuixFilterChipGroupState();
}

class _MiuixFilterChipGroupState extends State<MiuixFilterChipGroup> {
  late List<int> _selected;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelected);
  }

  void _toggleChip(int index) {
    setState(() {
      if (widget.multiSelect) {
        if (_selected.contains(index)) {
          _selected.remove(index);
        } else {
          _selected.add(index);
        }
      } else {
        _selected = [index];
      }
    });
    final selectedChips =
        _selected.map((i) => widget.chips[i]).toList();
    widget.onSelectionChanged?.call(List.from(_selected), selectedChips);
  }

  @override
  Widget build(BuildContext context) {
    final visibleChips = widget.collapsible && !_expanded
        ? widget.chips.take(widget.collapsedCount).toList()
        : widget.chips;
    final hasMore = widget.collapsible &&
        widget.chips.length > widget.collapsedCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: MiuixDuration.normal,
          curve: MiuixCurves.easeInOut,
          child: Wrap(
            spacing: widget.spacing,
            runSpacing: widget.runSpacing,
            children: [
              ...visibleChips.asMap().entries.map((entry) {
                final index = entry.key;
                final chip = entry.value;
                final isSelected = _selected.contains(index);
                return _FilterChipItem(
                  chip: chip,
                  isSelected: isSelected,
                  onTap: () => _toggleChip(index),
                );
              }),
              if (hasMore)
                _FilterChipItem(
                  chip: MiuixFilterChip(
                    label: _expanded ? '收起' : '更多',
                    icon: _expanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  isSelected: false,
                  onTap: () => setState(() => _expanded = !_expanded),
                  isMoreButton: true,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 单个筛选标签
class _FilterChipItem extends StatefulWidget {
  const _FilterChipItem({
    required this.chip,
    required this.isSelected,
    required this.onTap,
    this.isMoreButton = false,
  });

  final MiuixFilterChip chip;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isMoreButton;

  @override
  State<_FilterChipItem> createState() => _FilterChipItemState();
}

class _FilterChipItemState extends State<_FilterChipItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: MiuixDuration.fast,
      reverseDuration: MiuixDuration.elastic,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.92)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: MiuixCurves.miuixSpring)),
        weight: 70,
      ),
    ]).animate(_scaleController);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: MiuixDuration.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: MiuixSpacing.md,
            vertical: MiuixSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? const LinearGradient(
                    colors: MiuixColors.primaryGradient,
                  )
                : null,
            color: widget.isSelected ? null : MiuixColors.surface,
            borderRadius: BorderRadius.circular(MiuixRadius.pill),
            border: Border.all(
              color: widget.isSelected
                  ? Colors.transparent
                  : MiuixColors.borderLight,
              width: 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: MiuixColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.chip.icon != null) ...[
                Icon(
                  widget.chip.icon,
                  size: 14,
                  color: widget.isSelected
                      ? Colors.white
                      : MiuixColors.textSecondary,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                widget.chip.label,
                style: TextStyle(
                  color: widget.isSelected
                      ? Colors.white
                      : MiuixColors.textSecondary,
                  fontSize: MiuixFontSize.sm,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (widget.isSelected && !widget.isMoreButton) ...[
                const SizedBox(width: 4),
                const Icon(Icons.check, size: 12, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// MiuixChoiceChip —— 单选标签
/// 类似 ChoiceChip 的粉色风格
/// ============================================================
class MiuixChoiceChip extends StatelessWidget {
  const MiuixChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.avatar,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Widget? avatar;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      avatar: avatar,
      selectedColor: MiuixColors.primary,
      backgroundColor: MiuixColors.surface,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : MiuixColors.textSecondary,
        fontSize: MiuixFontSize.sm,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MiuixRadius.pill),
        side: BorderSide(
          color: selected ? Colors.transparent : MiuixColors.borderLight,
        ),
      ),
      elevation: selected ? 4 : 0,
      shadowColor: MiuixColors.primary.withValues(alpha: 0.3),
    );
  }
}

/// ============================================================
/// MiuixInputChip —— 可删除标签
/// 带删除按钮的输入标签
/// ============================================================
class MiuixInputChip extends StatelessWidget {
  const MiuixInputChip({
    super.key,
    required this.label,
    this.onDeleted,
    this.avatar,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onDeleted;
  final Widget? avatar;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      onDeleted: onDeleted,
      avatar: avatar,
      onPressed: onPressed,
      backgroundColor: MiuixColors.primary.withValues(alpha: 0.1),
      deleteIconColor: MiuixColors.primary,
      labelStyle: const TextStyle(
        color: MiuixColors.primary,
        fontSize: MiuixFontSize.sm,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MiuixRadius.pill),
        side: BorderSide(color: MiuixColors.primary.withValues(alpha: 0.3)),
      ),
    );
  }
}

/// ============================================================
/// MiuixActionChip —— 操作标签
/// 点击触发操作的粉色标签
/// ============================================================
class MiuixActionChip extends StatelessWidget {
  const MiuixActionChip({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onPressed,
      avatar: icon != null
          ? Icon(icon, size: 16, color: MiuixColors.primary)
          : null,
      backgroundColor: MiuixColors.surface,
      labelStyle: const TextStyle(
        color: MiuixColors.primary,
        fontSize: MiuixFontSize.sm,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MiuixRadius.pill),
        side: BorderSide(color: MiuixColors.primary.withValues(alpha: 0.3)),
      ),
    );
  }
}
