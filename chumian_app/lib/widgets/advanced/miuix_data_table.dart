import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixDataTable —— Miuix 风格数据表格
/// 可排序表格，粉色表头，斑马纹，行点击水晕，固定表头，分页
/// ============================================================

/// 表格列定义
class MiuixDataColumn {
  const MiuixDataColumn({
    required this.label,
    required this.key,
    this.sortable = false,
    this.flex = 1,
    this.alignment = Alignment.centerLeft,
    this.formatter,
  });

  /// 列标题
  final String label;

  /// 数据键
  final String key;

  /// 是否可排序
  final bool sortable;

  /// 弹性系数
  final int flex;

  /// 对齐方式
  final Alignment alignment;

  /// 格式化函数
  final String Function(dynamic value)? formatter;
}

/// 表格行数据
class MiuixDataRow {
  const MiuixDataRow({
    required this.cells,
    this.onTap,
    this.selected = false,
  });

  /// 单元格数据（key-value）
  final Map<String, dynamic> cells;

  /// 行点击回调
  final VoidCallback? onTap;

  /// 是否选中
  final bool selected;
}

/// Miuix 风格数据表格
///
/// 用法：
/// ```dart
/// MiuixDataTable(
///   columns: [
///     MiuixDataColumn(label: '名称', key: 'name', sortable: true),
///     MiuixDataColumn(label: '数值', key: 'value', sortable: true),
///   ],
///   rows: [
///     MiuixDataRow(cells: {'name': '项目A', 'value': 100}),
///   ],
/// )
/// ```
class MiuixDataTable extends StatefulWidget {
  const MiuixDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.rowsPerPage = 10,
    this.showPagination = true,
    this.showCheckbox = false,
    this.onSort,
    this.initialSortColumn,
    this.initialSortAscending = true,
    this.headerColor,
    this.zebraStripe = true,
    this.fixedHeader = true,
  });

  /// 列定义
  final List<MiuixDataColumn> columns;

  /// 行数据
  final List<MiuixDataRow> rows;

  /// 每页行数
  final int rowsPerPage;

  /// 是否显示分页
  final bool showPagination;

  /// 是否显示复选框
  final bool showCheckbox;

  /// 排序回调
  final void Function(String columnKey, bool ascending)? onSort;

  /// 初始排序列
  final String? initialSortColumn;

  /// 初始排序方向
  final bool initialSortAscending;

  /// 表头颜色
  final Color? headerColor;

  /// 是否斑马纹
  final bool zebraStripe;

  /// 是否固定表头
  final bool fixedHeader;

  @override
  State<MiuixDataTable> createState() => _MiuixDataTableState();
}

class _MiuixDataTableState extends State<MiuixDataTable> {
  late String? _sortColumn;
  late bool _sortAscending;
  int _currentPage = 0;
  final Set<int> _selectedRows = {};

  @override
  void initState() {
    super.initState();
    _sortColumn = widget.initialSortColumn;
    _sortAscending = widget.initialSortAscending;
  }

  List<MiuixDataRow> get _sortedRows {
    if (_sortColumn == null) return widget.rows;
    final sorted = List<MiuixDataRow>.from(widget.rows);
    sorted.sort((a, b) {
      final aVal = a.cells[_sortColumn];
      final bVal = b.cells[_sortColumn];
      int result;
      if (aVal is num && bVal is num) {
        result = aVal.compareTo(bVal);
      } else {
        result = aVal.toString().compareTo(bVal.toString());
      }
      return _sortAscending ? result : -result;
    });
    return sorted;
  }

  List<MiuixDataRow> get _pagedRows {
    if (!widget.showPagination) return _sortedRows;
    final start = _currentPage * widget.rowsPerPage;
    final end = (start + widget.rowsPerPage).clamp(0, _sortedRows.length);
    if (start >= _sortedRows.length) return [];
    return _sortedRows.sublist(start, end);
  }

  int get _totalPages =>
      ((_sortedRows.length / widget.rowsPerPage).ceil()).clamp(1, 999);

  void _onSort(String columnKey) {
    final column = widget.columns.firstWhere((c) => c.key == columnKey);
    if (!column.sortable) return;

    setState(() {
      if (_sortColumn == columnKey) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = columnKey;
        _sortAscending = true;
      }
    });
    widget.onSort?.call(columnKey, _sortAscending);
  }

  void _toggleRowSelection(int index) {
    setState(() {
      if (_selectedRows.contains(index)) {
        _selectedRows.remove(index);
      } else {
        _selectedRows.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MiuixColors.surface,
        borderRadius: BorderRadius.circular(MiuixRadius.lg),
        boxShadow: MiuixShadows.sm,
      ),
      child: Column(
        children: [
          // 表头
          _buildHeader(),
          // 表体
          ..._pagedRows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            final globalIndex = _currentPage * widget.rowsPerPage + index;
            return _buildDataRow(row, index, globalIndex);
          }),
          // 分页
          if (widget.showPagination && _sortedRows.length > widget.rowsPerPage)
            _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.headerColor ?? MiuixColors.primaryLight,
            (widget.headerColor ?? MiuixColors.primary)
                .withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(MiuixRadius.lg),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MiuixSpacing.md,
          vertical: MiuixSpacing.md,
        ),
        child: Row(
          children: [
            if (widget.showCheckbox)
              SizedBox(
                width: 40,
                child: Checkbox(
                  value: _selectedRows.length == _sortedRows.length &&
                      _sortedRows.isNotEmpty,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedRows.addAll(
                            List.generate(_sortedRows.length, (i) => i));
                      } else {
                        _selectedRows.clear();
                      }
                    });
                  },
                  activeColor: Colors.white,
                  checkColor: MiuixColors.primary,
                ),
              ),
            ...widget.columns.map((col) {
              final isSorted = _sortColumn == col.key;
              return Expanded(
                flex: col.flex,
                child: GestureDetector(
                  onTap: () => _onSort(col.key),
                  child: Row(
                    mainAxisAlignment: col.alignment == Alignment.center
                        ? MainAxisAlignment.center
                        : col.alignment == Alignment.centerRight
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                    children: [
                      Text(
                        col.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: MiuixFontSize.sm,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (col.sortable) ...[
                        const SizedBox(width: 4),
                        Icon(
                          isSorted
                              ? (_sortAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward)
                              : Icons.unfold_more,
                          size: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(MiuixDataRow row, int index, int globalIndex) {
    final isSelected = _selectedRows.contains(globalIndex) || row.selected;
    final isEven = index % 2 == 0;

    return GestureDetector(
      onTap: row.onTap,
      child: _DataRowCell(
        isSelected: isSelected,
        isEven: isEven && widget.zebraStripe,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MiuixSpacing.md,
            vertical: MiuixSpacing.md,
          ),
          child: Row(
            children: [
              if (widget.showCheckbox)
                SizedBox(
                  width: 40,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleRowSelection(globalIndex),
                    activeColor: MiuixColors.primary,
                  ),
                ),
              ...widget.columns.map((col) {
                final value = row.cells[col.key];
                final displayValue =
                    col.formatter?.call(value) ?? value?.toString() ?? '-';
                return Expanded(
                  flex: col.flex,
                  child: Text(
                    displayValue,
                    textAlign: col.alignment == Alignment.center
                        ? TextAlign.center
                        : col.alignment == Alignment.centerRight
                            ? TextAlign.right
                            : TextAlign.left,
                    style: TextStyle(
                      color: isSelected
                          ? MiuixColors.primary
                          : MiuixColors.textPrimary,
                      fontSize: MiuixFontSize.sm,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MiuixSpacing.md,
        vertical: MiuixSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: MiuixColors.divider, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '共 ${_sortedRows.length} 条',
            style: const TextStyle(
              color: MiuixColors.textTertiary,
              fontSize: MiuixFontSize.sm,
            ),
          ),
          Row(
            children: [
              _buildPageButton(
                icon: Icons.chevron_left,
                enabled: _currentPage > 0,
                onTap: () => setState(() => _currentPage--),
              ),
              const SizedBox(width: MiuixSpacing.sm),
              Text(
                '${_currentPage + 1} / $_totalPages',
                style: const TextStyle(
                  color: MiuixColors.textSecondary,
                  fontSize: MiuixFontSize.sm,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: MiuixSpacing.sm),
              _buildPageButton(
                icon: Icons.chevron_right,
                enabled: _currentPage < _totalPages - 1,
                onTap: () => setState(() => _currentPage++),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled
              ? MiuixColors.primary.withOpacity(0.1)
              : MiuixColors.surfaceVariant,
          borderRadius: BorderRadius.circular(MiuixRadius.sm),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? MiuixColors.primary : MiuixColors.textTertiary,
        ),
      ),
    );
  }
}

/// 数据行单元格（带水晕效果）
class _DataRowCell extends StatefulWidget {
  const _DataRowCell({
    required this.child,
    required this.isSelected,
    required this.isEven,
  });

  final Widget child;
  final bool isSelected;
  final bool isEven;

  @override
  State<_DataRowCell> createState() => _DataRowCellState();
}

class _DataRowCellState extends State<_DataRowCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rippleController;
  Offset? _ripplePosition;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _ripplePosition = details.localPosition;
    });
    _rippleController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      child: AnimatedBuilder(
        animation: _rippleController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? MiuixColors.primary.withOpacity(0.08)
                  : widget.isEven
                      ? MiuixColors.surfaceVariant.withOpacity(0.5)
                      : Colors.transparent,
            ),
            child: Stack(
              children: [
                widget.child,
                if (_ripplePosition != null)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RipplePainter(
                        position: _ripplePosition!,
                        progress: _rippleController.value,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 水晕绘制器
class _RipplePainter extends CustomPainter {
  _RipplePainter({
    required this.position,
    required this.progress,
  });

  final Offset position;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final maxRadius = size.width > size.height ? size.width : size.height;
    final radius = maxRadius * progress;
    final paint = Paint()
      ..color = MiuixColors.primary.withOpacity(0.15 * (1 - progress))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
