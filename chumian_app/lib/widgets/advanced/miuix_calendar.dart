import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixCalendar —— Miuix 风格日历组件
/// 月视图，粉色选中态，今日高亮，签到标记，滑动切换月份，弹簧动画，范围选择
/// ============================================================

/// 日历选择模式
enum MiuixCalendarMode {
  /// 单选
  single,

  /// 范围选择
  range,

  /// 多选
  multi,
}

/// Miuix 风格日历组件
///
/// 用法：
/// ```dart
/// MiuixCalendar(
///   mode: MiuixCalendarMode.range,
///   onDateSelected: (date) {},
/// )
/// ```
class MiuixCalendar extends StatefulWidget {
  const MiuixCalendar({
    super.key,
    this.mode = MiuixCalendarMode.single,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.selectedDate,
    this.rangeStart,
    this.rangeEnd,
    this.markedDates = const {},
    this.onDateSelected,
    this.onRangeSelected,
    this.onMonthChanged,
    this.showHeader = true,
    this.showWeekdays = true,
    this.weekdayLabels = const ['日', '一', '二', '三', '四', '五', '六'],
  });

  /// 选择模式
  final MiuixCalendarMode mode;

  /// 初始显示日期
  final DateTime? initialDate;

  /// 最早可选日期
  final DateTime? firstDate;

  /// 最晚可选日期
  final DateTime? lastDate;

  /// 单选模式下的选中日期
  final DateTime? selectedDate;

  /// 范围选择开始
  final DateTime? rangeStart;

  /// 范围选择结束
  final DateTime? rangeEnd;

  /// 标记日期集合（签到等）
  final Set<DateTime> markedDates;

  /// 单选回调
  final ValueChanged<DateTime>? onDateSelected;

  /// 范围选择回调
  final void Function(DateTime? start, DateTime? end)? onRangeSelected;

  /// 月份切换回调
  final ValueChanged<DateTime>? onMonthChanged;

  /// 是否显示头部（年月+切换按钮）
  final bool showHeader;

  /// 是否显示星期栏
  final bool showWeekdays;

  /// 星期标签
  final List<String> weekdayLabels;

  @override
  State<MiuixCalendar> createState() => _MiuixCalendarState();
}

class _MiuixCalendarState extends State<MiuixCalendar>
    with SingleTickerProviderStateMixin {
  late DateTime _currentMonth;
  DateTime? _selectedDate;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _rangeSelecting = false;

  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;
  int _slideDirection = 0; // -1 向左, 1 向右

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.initialDate ?? DateTime.now();
    _selectedDate = widget.selectedDate;
    _rangeStart = widget.rangeStart;
    _rangeEnd = widget.rangeEnd;
    _slideController = AnimationController(
      vsync: this,
      duration: MiuixDuration.normal,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: MiuixCurves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(MiuixCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _selectedDate = widget.selectedDate;
    }
    if (widget.rangeStart != oldWidget.rangeStart) {
      _rangeStart = widget.rangeStart;
    }
    if (widget.rangeEnd != oldWidget.rangeEnd) {
      _rangeEnd = widget.rangeEnd;
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _slideDirection = delta > 0 ? -1 : 1;
      _slideController.reset();
      _slideController.forward().then((_) {
        _currentMonth = DateTime(
          _currentMonth.year,
          _currentMonth.month + delta,
          1,
        );
        widget.onMonthChanged?.call(_currentMonth);
        _slideDirection = 0;
        _slideController.reset();
      });
    });
  }

  void _onDayTap(DateTime date) {
    final isDisabled = _isDateDisabled(date);
    if (isDisabled) return;

    switch (widget.mode) {
      case MiuixCalendarMode.single:
        setState(() => _selectedDate = date);
        widget.onDateSelected?.call(date);
        break;
      case MiuixCalendarMode.range:
        if (!_rangeSelecting || _rangeStart != null) {
          setState(() {
            _rangeStart = date;
            _rangeEnd = null;
            _rangeSelecting = true;
          });
        } else {
          if (date.isBefore(_rangeStart!)) {
            setState(() {
              _rangeEnd = _rangeStart;
              _rangeStart = date;
            });
          } else {
            setState(() => _rangeEnd = date);
          }
          _rangeSelecting = false;
          widget.onRangeSelected?.call(_rangeStart, _rangeEnd);
        }
        break;
      case MiuixCalendarMode.multi:
        widget.onDateSelected?.call(date);
        break;
    }
  }

  bool _isDateDisabled(DateTime date) {
    if (widget.firstDate != null && date.isBefore(_dateOnly(widget.firstDate!))) {
      return true;
    }
    if (widget.lastDate != null && date.isAfter(_dateOnly(widget.lastDate!))) {
      return true;
    }
    return false;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isInRange(DateTime date) {
    if (_rangeStart == null || _rangeEnd == null) return false;
    return date.isAfter(_rangeStart!) && date.isBefore(_rangeEnd!);
  }

  bool _isMarked(DateTime date) {
    return widget.markedDates.any((d) => _isSameDay(d, date));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MiuixColors.surface,
        borderRadius: BorderRadius.circular(MiuixRadius.lg),
        boxShadow: MiuixShadows.sm,
      ),
      padding: const EdgeInsets.all(MiuixSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showHeader) _buildHeader(),
          if (widget.showWeekdays) _buildWeekdays(),
          const SizedBox(height: MiuixSpacing.xs),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final monthText = '${_currentMonth.year}年${_currentMonth.month}月';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MiuixSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavButton(Icons.chevron_left, () => _changeMonth(-1)),
          Text(
            monthText,
            style: const TextStyle(
              color: MiuixColors.textPrimary,
              fontSize: MiuixFontSize.lg,
              fontWeight: FontWeight.w600,
            ),
          ),
          _buildNavButton(Icons.chevron_right, () => _changeMonth(1)),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: MiuixColors.surfaceVariant,
          borderRadius: BorderRadius.circular(MiuixRadius.sm),
        ),
        child: Icon(icon, size: 18, color: MiuixColors.primary),
      ),
    );
  }

  Widget _buildWeekdays() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MiuixSpacing.xs),
      child: Row(
        children: widget.weekdayLabels.map((label) {
          final isWeekend = label == '日' || label == '六';
          return Expanded(
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isWeekend
                      ? MiuixColors.primary
                      : MiuixColors.textTertiary,
                  fontSize: MiuixFontSize.sm,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = firstDayOfMonth.weekday % 7; // 周日=0

    final totalCells = ((firstWeekday + daysInMonth) / 7).ceil() * 7;
    final today = _dateOnly(DateTime.now());

    return SlideTransition(
      position: _slideAnimation,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.0,
        ),
        itemCount: totalCells,
        itemBuilder: (context, index) {
          final dayNumber = index - firstWeekday + 1;
          if (dayNumber < 1 || dayNumber > daysInMonth) {
            return const SizedBox.shrink();
          }
          final date = DateTime(year, month, dayNumber);
          final isToday = _isSameDay(date, today);
          final isSelected = _selectedDate != null &&
              _isSameDay(date, _selectedDate!);
          final isRangeStart =
              _rangeStart != null && _isSameDay(date, _rangeStart!);
          final isRangeEnd =
              _rangeEnd != null && _isSameDay(date, _rangeEnd!);
          final inRange = _isInRange(date);
          final isDisabled = _isDateDisabled(date);
          final isMarked = _isMarked(date);

          return _CalendarDayCell(
            day: dayNumber,
            isToday: isToday,
            isSelected: isSelected,
            isRangeStart: isRangeStart,
            isRangeEnd: isRangeEnd,
            inRange: inRange,
            isDisabled: isDisabled,
            isMarked: isMarked,
            onTap: () => _onDayTap(date),
          );
        },
      ),
    );
  }
}

/// 日历日期单元格
class _CalendarDayCell extends StatefulWidget {
  const _CalendarDayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.isRangeStart,
    required this.isRangeEnd,
    required this.inRange,
    required this.isDisabled,
    required this.isMarked,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final bool isSelected;
  final bool isRangeStart;
  final bool isRangeEnd;
  final bool inRange;
  final bool isDisabled;
  final bool isMarked;
  final VoidCallback onTap;

  @override
  State<_CalendarDayCell> createState() => _CalendarDayCellState();
}

class _CalendarDayCellState extends State<_CalendarDayCell>
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
        tween: Tween(begin: 1.0, end: 0.88)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.88, end: 1.0)
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

  void _handleTapDown(TapDownDetails details) {
    if (widget.isDisabled) return;
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isDisabled) return;
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final hasRangeBg = widget.inRange;
    final isRangeEndpoint = widget.isRangeStart || widget.isRangeEnd;
    final isHighlighted = widget.isSelected || isRangeEndpoint;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: () => _scaleController.reverse(),
      onTap: widget.isDisabled ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: hasRangeBg
                ? MiuixColors.primary.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(
                widget.isRangeStart ? MiuixRadius.pill : 0,
              ),
              right: Radius.circular(
                widget.isRangeEnd ? MiuixRadius.pill : 0,
              ),
            ),
          ),
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: isHighlighted
                    ? const LinearGradient(
                        colors: MiuixColors.primaryGradient,
                      )
                    : null,
                color: widget.isToday && !isHighlighted
                    ? MiuixColors.primary.withOpacity(0.1)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: widget.isToday && !isHighlighted
                    ? Border.all(color: MiuixColors.primary, width: 1.5)
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '${widget.day}',
                    style: TextStyle(
                      color: isHighlighted
                          ? Colors.white
                          : widget.isDisabled
                              ? MiuixColors.textTertiary.withOpacity(0.4)
                              : widget.isToday
                                  ? MiuixColors.primary
                                  : MiuixColors.textPrimary,
                      fontSize: MiuixFontSize.md,
                      fontWeight: isHighlighted
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  if (widget.isMarked)
                    Positioned(
                      bottom: 4,
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? Colors.white
                              : MiuixColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
