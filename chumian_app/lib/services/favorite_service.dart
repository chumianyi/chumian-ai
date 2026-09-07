import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================================
/// FavoriteService —— 通用收藏服务
///
/// 支持收藏多种类型的内容：消息、帖子、笑话、工具结果等。
/// 提供分类管理、CRUD、搜索与本地持久化能力。
/// ============================================================================

/// 收藏项类型枚举
enum FavoriteType {
  /// 聊天消息
  message,

  /// 社区帖子
  post,

  /// 笑话/娱乐内容
  entertainment,

  /// 工具结果
  toolResult,

  /// 图片
  image,

  /// 文章/链接
  article,

  /// 其他
  other,
}

/// FavoriteType 枚举扩展
extension FavoriteTypeExtension on FavoriteType {
  String get value {
    switch (this) {
      case FavoriteType.message:
        return 'message';
      case FavoriteType.post:
        return 'post';
      case FavoriteType.entertainment:
        return 'entertainment';
      case FavoriteType.toolResult:
        return 'tool_result';
      case FavoriteType.image:
        return 'image';
      case FavoriteType.article:
        return 'article';
      case FavoriteType.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case FavoriteType.message:
        return '消息';
      case FavoriteType.post:
        return '帖子';
      case FavoriteType.entertainment:
        return '娱乐';
      case FavoriteType.toolResult:
        return '工具结果';
      case FavoriteType.image:
        return '图片';
      case FavoriteType.article:
        return '文章';
      case FavoriteType.other:
        return '其他';
    }
  }

  static FavoriteType fromString(String? type) {
    switch (type) {
      case 'message':
        return FavoriteType.message;
      case 'post':
        return FavoriteType.post;
      case 'entertainment':
        return FavoriteType.entertainment;
      case 'tool_result':
        return FavoriteType.toolResult;
      case 'image':
        return FavoriteType.image;
      case 'article':
        return FavoriteType.article;
      default:
        return FavoriteType.other;
    }
  }
}

/// 收藏项数据模型
class FavoriteItem {
  final String id;
  final FavoriteType type;
  final String title;
  final String content;
  final String thumbnail;
  final String sourceId;
  final String extra;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  FavoriteItem({
    required this.id,
    required this.type,
    this.title = '',
    this.content = '',
    this.thumbnail = '',
    this.sourceId = '',
    this.extra = '',
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  })  : createdAt = createdAt ?? DateTime.now(),
        metadata = metadata ?? {};

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id']?.toString() ?? '',
      type: FavoriteTypeExtension.fromString(json['type']?.toString()),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString() ?? '',
      sourceId: json['source_id']?.toString() ?? '',
      extra: json['extra']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'title': title,
      'content': content,
      'thumbnail': thumbnail,
      'source_id': sourceId,
      'extra': extra,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory FavoriteItem.create({
    required FavoriteType type,
    String title = '',
    String content = '',
    String thumbnail = '',
    String sourceId = '',
    String extra = '',
    Map<String, dynamic>? metadata,
  }) {
    return FavoriteItem(
      id: 'fav_${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      title: title,
      content: content,
      thumbnail: thumbnail,
      sourceId: sourceId,
      extra: extra,
      metadata: metadata,
    );
  }

  bool matches(String keyword) {
    if (keyword.isEmpty) return true;
    final lower = keyword.toLowerCase();
    return title.toLowerCase().contains(lower) ||
        content.toLowerCase().contains(lower);
  }

  FavoriteItem copyWith({
    String? id,
    FavoriteType? type,
    String? title,
    String? content,
    String? thumbnail,
    String? sourceId,
    String? extra,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return FavoriteItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      thumbnail: thumbnail ?? this.thumbnail,
      sourceId: sourceId ?? this.sourceId,
      extra: extra ?? this.extra,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 收藏服务
class FavoriteService {
  static const String _keyFavorites = 'favorites_list';

  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;
  FavoriteService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _ensurePrefs async {
    if (_prefs == null) await init();
    return _prefs!;
  }

  // ===== CRUD =====

  Future<List<FavoriteItem>> _loadAll() async {
    final prefs = await _ensurePrefs;
    final raw = prefs.getString(_keyFavorites);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) =>
              FavoriteItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAll(List<FavoriteItem> items) async {
    final prefs = await _ensurePrefs;
    await prefs.setString(
        _keyFavorites, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  /// 添加收藏
  Future<FavoriteItem> add(FavoriteItem item) async {
    final items = await _loadAll();
    // 按 sourceId + type 去重
    if (item.sourceId.isNotEmpty) {
      final existing = items.indexWhere(
          (e) => e.sourceId == item.sourceId && e.type == item.type);
      if (existing != -1) return items[existing];
    }
    items.insert(0, item);
    await _saveAll(items);
    return item;
  }

  /// 快速添加收藏
  Future<FavoriteItem> addQuick({
    required FavoriteType type,
    String title = '',
    String content = '',
    String thumbnail = '',
    String sourceId = '',
    Map<String, dynamic>? metadata,
  }) async {
    final item = FavoriteItem.create(
      type: type,
      title: title,
      content: content,
      thumbnail: thumbnail,
      sourceId: sourceId,
      metadata: metadata,
    );
    return add(item);
  }

  /// 获取所有收藏
  Future<List<FavoriteItem>> getAll({FavoriteType? type}) async {
    final items = await _loadAll();
    if (type != null) {
      return items.where((e) => e.type == type).toList();
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// 获取单条收藏
  Future<FavoriteItem?> getById(String id) async {
    final items = await _loadAll();
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// 根据 sourceId 获取
  Future<FavoriteItem?> getBySourceId(
      String sourceId, FavoriteType type) async {
    final items = await _loadAll();
    for (final item in items) {
      if (item.sourceId == sourceId && item.type == type) return item;
    }
    return null;
  }

  /// 更新收藏
  Future<bool> update(FavoriteItem item) async {
    final items = await _loadAll();
    final index = items.indexWhere((e) => e.id == item.id);
    if (index == -1) return false;
    items[index] = item;
    await _saveAll(items);
    return true;
  }

  /// 删除收藏
  Future<bool> delete(String id) async {
    final items = await _loadAll();
    final originalLength = items.length;
    items.removeWhere((e) => e.id == id);
    if (items.length == originalLength) return false;
    await _saveAll(items);
    return true;
  }

  /// 按 sourceId 删除
  Future<bool> deleteBySourceId(String sourceId, FavoriteType type) async {
    final items = await _loadAll();
    final originalLength = items.length;
    items.removeWhere((e) => e.sourceId == sourceId && e.type == type);
    if (items.length == originalLength) return false;
    await _saveAll(items);
    return true;
  }

  /// 批量删除
  Future<int> deleteBatch(List<String> ids) async {
    final items = await _loadAll();
    final idSet = ids.toSet();
    final remaining = items.where((e) => !idSet.contains(e.id)).toList();
    final count = items.length - remaining.length;
    await _saveAll(remaining);
    return count;
  }

  /// 按类型清除
  Future<int> clearByType(FavoriteType type) async {
    final items = await _loadAll();
    final remaining = items.where((e) => e.type != type).toList();
    final count = items.length - remaining.length;
    await _saveAll(remaining);
    return count;
  }

  /// 清除所有
  Future<void> clearAll() async {
    final prefs = await _ensurePrefs;
    await prefs.remove(_keyFavorites);
  }

  // ===== 查询 =====

  /// 判断是否已收藏
  Future<bool> isFavorite(String sourceId, FavoriteType type) async {
    final item = await getBySourceId(sourceId, type);
    return item != null;
  }

  /// 切换收藏状态
  Future<bool> toggle({
    required FavoriteType type,
    String title = '',
    String content = '',
    String thumbnail = '',
    String sourceId = '',
    Map<String, dynamic>? metadata,
  }) async {
    if (sourceId.isNotEmpty && await isFavorite(sourceId, type)) {
      await deleteBySourceId(sourceId, type);
      return false;
    }
    await addQuick(
      type: type,
      title: title,
      content: content,
      thumbnail: thumbnail,
      sourceId: sourceId,
      metadata: metadata,
    );
    return true;
  }

  /// 搜索收藏
  Future<List<FavoriteItem>> search(String keyword,
      {FavoriteType? type}) async {
    final items = await getAll(type: type);
    if (keyword.isEmpty) return items;
    return items.where((e) => e.matches(keyword)).toList();
  }

  /// 获取收藏总数
  Future<int> getTotalCount() async {
    final items = await _loadAll();
    return items.length;
  }

  /// 获取各类型收藏数量
  Future<Map<FavoriteType, int>> getCountByType() async {
    final items = await _loadAll();
    final result = <FavoriteType, int>{};
    for (final item in items) {
      result[item.type] = (result[item.type] ?? 0) + 1;
    }
    return result;
  }
}
