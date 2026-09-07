import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/services/api_service.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_dialog.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// HistoryPage —— 浏览历史
/// 历史记录列表，按日期分组，清除按钮
/// 粉色卡片，错落入场动画
/// ============================================================

class HistoryItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final DateTime date;
  final String type;

  const HistoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.date,
    required this.type,
  });

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    final typeStr = map['type']?.toString() ?? '聊天';
    return HistoryItem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString() ??
          map['summary']?.toString() ??
          map['description']?.toString() ??
          '',
      icon: _iconFromType(typeStr),
      date: map['date'] != null
          ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now()
          : map['created_at'] != null
              ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
              : DateTime.now(),
      type: typeStr,
    );
  }

  static IconData _iconFromType(String type) {
    switch (type) {
      case '帖子':
      case 'post':
      case 'article':
        return Icons.article;
      case '话题':
      case 'topic':
        return Icons.local_fire_department;
      case '聊天':
      case 'chat':
      case 'message':
      default:
        return Icons.chat;
    }
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  bool _isLoading = true;
  String? _errorMessage;
  bool _selectMode = false;
  final Set<String> _selectedIds = {};
  Map<String, List<HistoryItem>> _groupedHistory = {};

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _loadHistory();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await ApiService.getHistory();
      final items = data
          .map((e) => HistoryItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      setState(() {
        _groupedHistory = _groupByDate(items);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, List<HistoryItem>> _groupByDate(List<HistoryItem> items) {
    final Map<String, List<HistoryItem>> grouped = {};
    for (final item in items) {
      final key = _formatDateKey(item.date);
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return grouped;
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(itemDay).inDays;

    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    if (diff == 2) return '前天';
    if (diff < 7) return '$diff天前';
    return '${date.year}年${date.month}月${date.day}日';
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: MiuixRadius.lgRadius),
        title: const Text('清除历史记录', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600)),
        content: const Text('确定要清除所有浏览历史吗？此操作不可撤销。', style: TextStyle(fontSize: MiuixFontSize.md, color: MiuixColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消', style: TextStyle(color: MiuixColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _groupedHistory.clear();
              });
              Navigator.of(context).pop();
            },
            child: const Text('确定清除', style: TextStyle(color: MiuixColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '浏览历史',
        actions: [
          if (!_selectMode)
            MiuixIconButton(
              icon: Icons.delete_sweep_outlined,
              style: MiuixIconButtonStyle.ghost,
              onPressed: _clearHistory,
            ),
          if (!_selectMode)
            MiuixIconButton(
              icon: Icons.checklist,
              style: MiuixIconButtonStyle.ghost,
              onPressed: () => setState(() => _selectMode = true),
            ),
          if (_selectMode)
            TextButton(
              onPressed: () => setState(() {
                _selectMode = false;
                _selectedIds.clear();
              }),
              child: const Text('取消', style: TextStyle(color: MiuixColors.primary)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(MiuixColors.primary),
            ))
          : _errorMessage != null
              ? _buildErrorState()
              : _groupedHistory.isEmpty
                  ? _buildEmptyState()
                  : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(MiuixSpacing.md),
                        children: _groupedHistory.entries.map((entry) {
                          return _buildDateGroup(entry.key, entry.value);
                        }).toList(),
                      ),
                    ),
                    if (_selectMode && _selectedIds.isNotEmpty) _buildDeleteBar(),
                  ],
                ),
    );
  }

  Widget _buildDateGroup(String date, List<HistoryItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: MiuixSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: MiuixSpacing.sm),
              Text(
                date,
                style: const TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
              const SizedBox(width: MiuixSpacing.sm),
              Text(
                '${items.length}条',
                style: const TextStyle(fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary),
              ),
            ],
          ),
        ),
        ...items.asMap().entries.map((entry) {
          return _buildHistoryItem(entry.value, entry.key);
        }),
      ],
    );
  }

  Widget _buildHistoryItem(HistoryItem item, int index) {
    final anim = CurvedAnimation(
      parent: _entryController,
      curve: Interval(
        0.05 + index * 0.03,
        1.0,
        curve: MiuixCurves.easeOut,
      ),
    );
    final isSelected = _selectedIds.contains(item.id);

    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.05, 0),
          end: Offset.zero,
        ).animate(anim),
        child: MiuixCard(
          margin: const EdgeInsets.only(bottom: MiuixSpacing.sm),
          onTap: _selectMode ? () => _toggleSelect(item.id) : () {},
          child: Row(
            children: [
              if (_selectMode)
                Padding(
                  padding: const EdgeInsets.only(right: MiuixSpacing.sm),
                  child: AnimatedContainer(
                    duration: MiuixDuration.fast,
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isSelected ? MiuixColors.primary : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? MiuixColors.primary : MiuixColors.border,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: MiuixColors.primary.withValues(alpha: 0.08),
                  borderRadius: MiuixRadius.mdRadius,
                ),
                child: Icon(item.icon, size: 20, color: MiuixColors.primary),
              ),
              const SizedBox(width: MiuixSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: MiuixFontSize.md,
                        fontWeight: FontWeight.w500,
                        color: MiuixColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: MiuixFontSize.xs,
                        color: MiuixColors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: MiuixColors.surfaceVariant,
                  borderRadius: MiuixRadius.xsRadius,
                ),
                child: Text(
                  item.type,
                  style: const TextStyle(fontSize: 10, color: MiuixColors.textTertiary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteBar() {
    return Container(
      padding: const EdgeInsets.all(MiuixSpacing.md),
      decoration: BoxDecoration(
        color: MiuixColors.surface,
        border: Border(top: BorderSide(color: MiuixColors.borderLight, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Text(
              '已选 ${_selectedIds.length} 项',
              style: const TextStyle(fontSize: MiuixFontSize.md, color: MiuixColors.textSecondary),
            ),
            const Spacer(),
            MiuixButton(
              label: '删除选中',
              type: MiuixButtonType.danger,
              size: MiuixButtonSize.small,
              icon: Icons.delete_outline,
              onPressed: () {
                setState(() {
                  for (final group in _groupedHistory.values) {
                    group.removeWhere((item) => _selectedIds.contains(item.id));
                  }
                  _groupedHistory.removeWhere((key, value) => value.isEmpty);
                  _selectedIds.clear();
                  _selectMode = false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: MiuixColors.error),
          const SizedBox(height: 12),
          const Text('加载失败', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 4),
          SizedBox(width: 240, child: Text(_errorMessage ?? '未知错误', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis)),
          const SizedBox(height: 16),
          TextButton.icon(onPressed: _loadHistory, icon: const Icon(Icons.refresh, size: 18), label: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: MiuixColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history, size: 36, color: MiuixColors.textTertiary),
          ),
          const SizedBox(height: MiuixSpacing.lg),
          const Text(
            '暂无浏览历史',
            style: TextStyle(
              fontSize: MiuixFontSize.lg,
              fontWeight: FontWeight.w600,
              color: MiuixColors.textSecondary,
            ),
          ),
          const SizedBox(height: MiuixSpacing.sm),
          const Text(
            '你浏览过的内容会显示在这里',
            style: TextStyle(
              fontSize: MiuixFontSize.sm,
              color: MiuixColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
