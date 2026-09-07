import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/services/api_service.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_chip.dart';
import 'package:chumian_ai/widgets/miuix/miuix_empty_state.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_snackbar.dart';

/// ============================================================
/// CollectionPage —— 我的收藏
/// 收藏的消息/帖子列表，分类标签，取消收藏
/// 粉色卡片，错落入场动画
/// ============================================================

enum CollectionType { message, post, note, link }

class CollectionItem {
  final String id;
  final CollectionType type;
  final String title;
  final String content;
  final String author;
  final DateTime createdAt;
  final String? tag;

  const CollectionItem({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.author,
    required this.createdAt,
    this.tag,
  });

  factory CollectionItem.fromMap(Map<String, dynamic> map) {
    final typeStr = map['type']?.toString() ?? 'message';
    CollectionType type;
    switch (typeStr) {
      case 'post': type = CollectionType.post; break;
      case 'note': type = CollectionType.note; break;
      case 'link': type = CollectionType.link; break;
      default: type = CollectionType.message;
    }
    return CollectionItem(
      id: map['id']?.toString() ?? '',
      type: type,
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? map['summary']?.toString() ?? '',
      author: map['author']?.toString() ??
          map['nickname']?.toString() ??
          map['user_nickname']?.toString() ??
          '未知',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : map['createdAt'] != null
              ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now(),
      tag: map['tag']?.toString(),
    );
  }
}

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  int _selectedCategory = 0;
  bool _isLoading = true;
  String? _errorMessage;
  List<CollectionItem> _allItems = [];
  List<CollectionItem> _filteredItems = [];

  static const List<String> _categories = ['全部', '消息', '帖子', '笔记', '链接'];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _loadCollections();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _loadCollections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await ApiService.getFavorites();
      setState(() {
        _allItems = data
            .map((e) => CollectionItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        _filteredItems = _allItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterByCategory(int index) {
    setState(() {
      _selectedCategory = index;
      if (index == 0) {
        _filteredItems = _allItems;
      } else {
        final typeMap = {
          1: CollectionType.message,
          2: CollectionType.post,
          3: CollectionType.note,
          4: CollectionType.link,
        };
        _filteredItems = _allItems
            .where((item) => item.type == typeMap[index])
            .toList();
      }
    });
  }

  void _removeCollection(String id) {
    setState(() {
      _allItems.removeWhere((item) => item.id == id);
      _filteredItems.removeWhere((item) => item.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已取消收藏'),
        backgroundColor: MiuixColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: MiuixRadius.lgRadius),
      ),
    );
  }

  (IconData, Color) _getTypeInfo(CollectionType type) {
    switch (type) {
      case CollectionType.message:
        return (Icons.chat_bubble_outline, MiuixColors.primary);
      case CollectionType.post:
        return (Icons.article_outlined, MiuixColors.info);
      case CollectionType.note:
        return (Icons.note_outlined, MiuixColors.success);
      case CollectionType.link:
        return (Icons.link, MiuixColors.warning);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '我的收藏',
        actions: [
          MiuixIconButton(
            icon: Icons.search,
            style: MiuixIconButtonStyle.ghost,
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryTabs(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(MiuixColors.primary),
                  ))
                : _errorMessage != null
                    ? _buildErrorState()
                    : _filteredItems.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: MiuixColors.primary,
                            onRefresh: _loadCollections,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(MiuixSpacing.md),
                              itemCount: _filteredItems.length,
                              itemBuilder: (context, index) =>
                                  _buildCollectionCard(_filteredItems[index], index),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: MiuixSpacing.md),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: MiuixSpacing.sm),
        itemBuilder: (context, index) {
          final isSelected = _selectedCategory == index;
          return MiuixChip(
            label: _categories[index],
            isSelected: isSelected,
            onTap: () => _filterByCategory(index),
          );
        },
      ),
    );
  }

  Widget _buildCollectionCard(CollectionItem item, int index) {
    final anim = CurvedAnimation(
      parent: _entryController,
      curve: Interval(
        0.1 + index * 0.05,
        1.0,
        curve: MiuixCurves.easeOut,
      ),
    );
    final (icon, color) = _getTypeInfo(item.type);

    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(anim),
        child: Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: MiuixSpacing.xl),
            decoration: BoxDecoration(
              color: MiuixColors.error.withOpacity(0.1),
              borderRadius: MiuixRadius.lgRadius,
            ),
            child: const Icon(Icons.delete_outline, color: MiuixColors.error),
          ),
          onDismissed: (_) => _removeCollection(item.id),
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
                        color: color.withOpacity(0.1),
                        borderRadius: MiuixRadius.smRadius,
                      ),
                      child: Icon(icon, size: 16, color: color),
                    ),
                    const SizedBox(width: MiuixSpacing.sm),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: MiuixFontSize.md,
                          fontWeight: FontWeight.w600,
                          color: MiuixColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.tag != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: MiuixColors.primary.withOpacity(0.08),
                          borderRadius: MiuixRadius.xsRadius,
                        ),
                        child: Text(
                          item.tag!,
                          style: const TextStyle(
                            fontSize: MiuixFontSize.xs,
                            color: MiuixColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: MiuixSpacing.sm),
                Text(
                  item.content,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.sm,
                    color: MiuixColors.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: MiuixSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 12, color: MiuixColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      item.author,
                      style: const TextStyle(fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary),
                    ),
                    const Spacer(),
                    MiuixRipple(
                      onTap: () => _removeCollection(item.id),
                      borderRadius: MiuixRadius.pill,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.favorite, size: 16, color: MiuixColors.error),
                      ),
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
          TextButton.icon(onPressed: _loadCollections, icon: const Icon(Icons.refresh, size: 18), label: const Text('重试')),
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
            child: const Icon(Icons.favorite_border, size: 36, color: MiuixColors.textTertiary),
          ),
          const SizedBox(height: MiuixSpacing.lg),
          const Text(
            '还没有收藏内容',
            style: TextStyle(
              fontSize: MiuixFontSize.lg,
              fontWeight: FontWeight.w600,
              color: MiuixColors.textSecondary,
            ),
          ),
          const SizedBox(height: MiuixSpacing.sm),
          const Text(
            '看到喜欢的内容，点击收藏按钮保存吧',
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
