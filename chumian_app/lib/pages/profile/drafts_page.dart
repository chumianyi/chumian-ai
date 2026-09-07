import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/services/api_service.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_chip.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// DraftsPage —— 草稿箱
/// 未发布的帖子/写作草稿，编辑/删除/发布
/// 粉色卡片，错落入场动画
/// ============================================================

enum DraftType { post, writing, note }

class DraftItem {
  final String id;
  final DraftType type;
  final String title;
  final String content;
  final DateTime updatedAt;
  final int wordCount;
  final List<String> tags;

  const DraftItem({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.updatedAt,
    required this.wordCount,
    this.tags = const [],
  });

  factory DraftItem.fromMap(Map<String, dynamic> map) {
    final typeStr = map['type']?.toString() ?? 'post';
    DraftType type;
    switch (typeStr) {
      case 'writing': type = DraftType.writing; break;
      case 'note': type = DraftType.note; break;
      default: type = DraftType.post;
    }
    final content = map['content']?.toString() ?? '';
    return DraftItem(
      id: map['id']?.toString() ?? '',
      type: type,
      title: map['title']?.toString() ?? '无标题',
      content: content,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : map['created_at'] != null
              ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
              : DateTime.now(),
      wordCount: (map['word_count'] as num?)?.toInt() ??
          (map['wordCount'] as num?)?.toInt() ??
          content.length,
      tags: (map['tags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class DraftsPage extends StatefulWidget {
  const DraftsPage({super.key});

  @override
  State<DraftsPage> createState() => _DraftsPageState();
}

class _DraftsPageState extends State<DraftsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  int _selectedTab = 0;
  bool _isLoading = true;
  String? _errorMessage;
  List<DraftItem> _allDrafts = [];
  List<DraftItem> _filteredDrafts = [];

  static const List<String> _tabs = ['全部', '帖子', '写作', '笔记'];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _loadDrafts();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _loadDrafts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await ApiService.getDrafts();
      setState(() {
        _allDrafts = data
            .map((e) => DraftItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        _filteredDrafts = _allDrafts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterByTab(int index) {
    setState(() {
      _selectedTab = index;
      if (index == 0) {
        _filteredDrafts = _allDrafts;
      } else {
        final typeMap = {1: DraftType.post, 2: DraftType.writing, 3: DraftType.note};
        _filteredDrafts = _allDrafts.where((d) => d.type == typeMap[index]).toList();
      }
    });
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${date.month}月${date.day}日';
  }

  (IconData, String, Color) _getTypeInfo(DraftType type) {
    switch (type) {
      case DraftType.post:
        return (Icons.article_outlined, '帖子', MiuixColors.primary);
      case DraftType.writing:
        return (Icons.edit_note, '写作', MiuixColors.info);
      case DraftType.note:
        return (Icons.note_outlined, '笔记', MiuixColors.success);
    }
  }

  void _deleteDraft(String id) {
    setState(() {
      _allDrafts.removeWhere((d) => d.id == id);
      _filteredDrafts.removeWhere((d) => d.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '草稿箱',
        actions: [
          MiuixIconButton(
            icon: Icons.edit_note,
            style: MiuixIconButtonStyle.ghost,
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(MiuixColors.primary),
                  ))
                : _errorMessage != null
                    ? _buildErrorState()
                    : _filteredDrafts.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(MiuixSpacing.md),
                            itemCount: _filteredDrafts.length,
                            itemBuilder: (context, index) =>
                                _buildDraftCard(_filteredDrafts[index], index),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: MiuixSpacing.md),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: MiuixSpacing.sm),
        itemBuilder: (context, index) {
          return MiuixChip(
            label: _tabs[index],
            isSelected: _selectedTab == index,
            onTap: () => _filterByTab(index),
          );
        },
      ),
    );
  }

  Widget _buildDraftCard(DraftItem draft, int index) {
    final anim = CurvedAnimation(
      parent: _entryController,
      curve: Interval(
        0.1 + index * 0.06,
        1.0,
        curve: MiuixCurves.easeOut,
      ),
    );
    final (icon, typeLabel, color) = _getTypeInfo(draft.type);

    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(anim),
        child: Dismissible(
          key: Key(draft.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: MiuixSpacing.xl),
            decoration: BoxDecoration(
              color: MiuixColors.error.withValues(alpha: 0.1),
              borderRadius: MiuixRadius.lgRadius,
            ),
            child: const Icon(Icons.delete_outline, color: MiuixColors.error),
          ),
          onDismissed: (_) => _deleteDraft(draft.id),
          child: MiuixCard(
            margin: const EdgeInsets.only(bottom: MiuixSpacing.md),
            onTap: () {},
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: MiuixRadius.smRadius,
                      ),
                      child: Icon(icon, size: 16, color: color),
                    ),
                    const SizedBox(width: MiuixSpacing.sm),
                    Expanded(
                      child: Text(
                        draft.title,
                        style: const TextStyle(
                          fontSize: MiuixFontSize.md,
                          fontWeight: FontWeight.w600,
                          color: MiuixColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    MiuixRipple(
                      onTap: () => _deleteDraft(draft.id),
                      borderRadius: MiuixRadius.pill,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline, size: 18, color: MiuixColors.textTertiary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MiuixSpacing.sm),
                Text(
                  draft.content,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.sm,
                    color: MiuixColors.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: MiuixSpacing.md),
                if (draft.tags.isNotEmpty)
                  Wrap(
                    spacing: MiuixSpacing.xs,
                    runSpacing: MiuixSpacing.xs,
                    children: draft.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: MiuixColors.primary.withValues(alpha: 0.06),
                          borderRadius: MiuixRadius.xsRadius,
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(fontSize: MiuixFontSize.xs, color: MiuixColors.primary),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: MiuixSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: MiuixColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(draft.updatedAt),
                      style: const TextStyle(fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary),
                    ),
                    const SizedBox(width: MiuixSpacing.md),
                    Icon(Icons.text_fields, size: 12, color: MiuixColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      '${draft.wordCount}字',
                      style: const TextStyle(fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary),
                    ),
                    const Spacer(),
                    MiuixButton(
                      label: '继续编辑',
                      type: MiuixButtonType.secondary,
                      size: MiuixButtonSize.small,
                      icon: Icons.edit,
                      onPressed: () {},
                    ),
                    const SizedBox(width: MiuixSpacing.xs),
                    MiuixButton(
                      label: '发布',
                      type: MiuixButtonType.primary,
                      size: MiuixButtonSize.small,
                      icon: Icons.send,
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
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
          TextButton.icon(onPressed: _loadDrafts, icon: const Icon(Icons.refresh, size: 18), label: const Text('重试')),
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
            child: const Icon(Icons.drafts_outlined, size: 36, color: MiuixColors.textTertiary),
          ),
          const SizedBox(height: MiuixSpacing.lg),
          const Text(
            '暂无草稿',
            style: TextStyle(
              fontSize: MiuixFontSize.lg,
              fontWeight: FontWeight.w600,
              color: MiuixColors.textSecondary,
            ),
          ),
          const SizedBox(height: MiuixSpacing.sm),
          const Text(
            '未完成的内容会自动保存到这里',
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
