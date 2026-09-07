import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixSearchBar —— Miuix 风格搜索栏
/// 展开/收起动画，搜索建议列表，历史记录，粉色聚焦态，清除按钮
/// ============================================================

/// Miuix 风格搜索栏
///
/// 用法：
/// ```dart
/// MiuixSearchBar(
///   onSearch: (query) {},
///   suggestions: ['热门搜索1', '热门搜索2'],
/// )
/// ```
class MiuixSearchBar extends StatefulWidget {
  const MiuixSearchBar({
    super.key,
    this.hintText = '搜索',
    this.onSearch,
    this.onChanged,
    this.suggestions = const [],
    this.history = const [],
    this.onHistoryCleared,
    this.onHistoryRemoved,
    this.expandable = false,
    this.initialExpanded = false,
    this.backgroundColor,
    this.prefixIcon,
  });

  /// 提示文字
  final String hintText;

  /// 搜索回调（提交时）
  final ValueChanged<String>? onSearch;

  /// 文本变化回调
  final ValueChanged<String>? onChanged;

  /// 搜索建议
  final List<String> suggestions;

  /// 历史记录
  final List<String> history;

  /// 清除历史回调
  final VoidCallback? onHistoryCleared;

  /// 删除单条历史回调
  final ValueChanged<String>? onHistoryRemoved;

  /// 是否可展开/收起
  final bool expandable;

  /// 初始是否展开
  final bool initialExpanded;

  /// 背景色
  final Color? backgroundColor;

  /// 前缀图标
  final IconData? prefixIcon;

  @override
  State<MiuixSearchBar> createState() => _MiuixSearchBarState();
}

class _MiuixSearchBarState extends State<MiuixSearchBar>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;
  bool _isExpanded = false;
  bool _isFocused = false;
  List<String> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
    _expandController = AnimationController(
      vsync: this,
      duration: MiuixDuration.normal,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: MiuixCurves.easeInOut,
    );
    if (_isExpanded) _expandController.value = 1.0;
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _expandController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  void _onTextChange() {
    final query = _controller.text;
    widget.onChanged?.call(query);
    if (query.isNotEmpty) {
      _filteredSuggestions = widget.suggestions
          .where((s) => s.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } else {
      _filteredSuggestions = [];
    }
    setState(() {});
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
        _focusNode.requestFocus();
      } else {
        _expandController.reverse();
        _focusNode.unfocus();
        _controller.clear();
      }
    });
  }

  void _clearText() {
    _controller.clear();
    _onTextChange();
  }

  void _submitSearch(String query) {
    widget.onSearch?.call(query);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.expandable) {
      return _buildExpandable();
    }
    return _buildNormal();
  }

  Widget _buildNormal() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSearchField(),
        if (_isFocused &&
            (_filteredSuggestions.isNotEmpty || widget.history.isNotEmpty))
          _buildSuggestionPanel(),
      ],
    );
  }

  Widget _buildExpandable() {
    return Row(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _expandAnimation.value,
                child: Align(
                  alignment: Alignment.centerRight,
                  widthFactor: _expandAnimation.value,
                  child: child,
                ),
              );
            },
            child: _buildSearchField(),
          ),
        ),
        if (!_isExpanded)
          GestureDetector(
            onTap: _toggleExpand,
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(left: MiuixSpacing.sm),
              decoration: BoxDecoration(
                color: MiuixColors.surface,
                borderRadius: BorderRadius.circular(MiuixRadius.pill),
                boxShadow: MiuixShadows.xs,
              ),
              child: const Icon(
                Icons.search,
                color: MiuixColors.primary,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    return AnimatedContainer(
      duration: MiuixDuration.fast,
      height: 48,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? MiuixColors.surface,
        borderRadius: BorderRadius.circular(MiuixRadius.pill),
        border: Border.all(
          color: _isFocused ? MiuixColors.primary : MiuixColors.borderLight,
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: MiuixColors.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ]
            : MiuixShadows.xs,
      ),
      child: Row(
        children: [
          const SizedBox(width: MiuixSpacing.md),
          Icon(
            widget.prefixIcon ?? Icons.search,
            size: 20,
            color: _isFocused ? MiuixColors.primary : MiuixColors.textTertiary,
          ),
          const SizedBox(width: MiuixSpacing.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: _submitSearch,
              style: const TextStyle(
                color: MiuixColors.textPrimary,
                fontSize: MiuixFontSize.md,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  color: MiuixColors.textTertiary,
                  fontSize: MiuixFontSize.md,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: _clearText,
              child: Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: MiuixSpacing.sm),
                decoration: BoxDecoration(
                  color: MiuixColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: MiuixColors.textSecondary,
                ),
              ),
            ),
          if (widget.expandable && _isExpanded)
            GestureDetector(
              onTap: _toggleExpand,
              child: const Padding(
                padding: EdgeInsets.only(right: MiuixSpacing.md),
                child: Text(
                  '取消',
                  style: TextStyle(
                    color: MiuixColors.primary,
                    fontSize: MiuixFontSize.md,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionPanel() {
    return Container(
      margin: const EdgeInsets.only(top: MiuixSpacing.sm),
      padding: const EdgeInsets.all(MiuixSpacing.md),
      decoration: BoxDecoration(
        color: MiuixColors.surface,
        borderRadius: BorderRadius.circular(MiuixRadius.lg),
        boxShadow: MiuixShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_filteredSuggestions.isNotEmpty) ...[
            const Text(
              '搜索建议',
              style: TextStyle(
                color: MiuixColors.textSecondary,
                fontSize: MiuixFontSize.sm,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: MiuixSpacing.sm),
            ..._filteredSuggestions.map((s) => _buildSuggestionItem(s)),
          ],
          if (widget.history.isNotEmpty && _controller.text.isEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '搜索历史',
                  style: TextStyle(
                    color: MiuixColors.textSecondary,
                    fontSize: MiuixFontSize.sm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onHistoryCleared,
                  child: const Text(
                    '清除',
                    style: TextStyle(
                      color: MiuixColors.primary,
                      fontSize: MiuixFontSize.sm,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MiuixSpacing.sm),
            Wrap(
              spacing: MiuixSpacing.sm,
              runSpacing: MiuixSpacing.sm,
              children: widget.history.map((h) {
                return _buildHistoryChip(h);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String text) {
    return GestureDetector(
      onTap: () {
        _controller.text = text;
        _submitSearch(text);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: MiuixSpacing.sm),
        child: Row(
          children: [
            const Icon(
              Icons.north_west,
              size: 14,
              color: MiuixColors.textTertiary,
            ),
            const SizedBox(width: MiuixSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: MiuixColors.textPrimary,
                  fontSize: MiuixFontSize.md,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryChip(String text) {
    return GestureDetector(
      onTap: () {
        _controller.text = text;
        _submitSearch(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MiuixSpacing.md,
          vertical: MiuixSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: MiuixColors.surfaceVariant,
          borderRadius: BorderRadius.circular(MiuixRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: MiuixColors.textSecondary,
                fontSize: MiuixFontSize.sm,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => widget.onHistoryRemoved?.call(text),
              child: const Icon(
                Icons.close,
                size: 12,
                color: MiuixColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
