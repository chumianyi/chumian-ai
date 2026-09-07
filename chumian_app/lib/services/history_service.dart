import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================================
/// HistoryService —— 浏览历史服务
///
/// 记录用户在应用内的页面访问历史，支持按日期分组、
/// 搜索、清除与本地持久化。
/// ============================================================================

/// 浏览历史记录
class HistoryRecord {
  final String id;
  final String pageRoute;
  final String pageTitle;
  final String pageIcon;
  final String extra;
  final DateTime visitedAt;
  final Map<String, dynamic> params;

  HistoryRecord({
    required this.id,
    required this.pageRoute,
    this.pageTitle = '',
    this.pageIcon = '',
    this.extra = '',
    DateTime? visitedAt,
    Map<String, dynamic>? params,
  })  : visitedAt = visitedAt ?? DateTime.now(),
        params = params ?? {};

  factory HistoryRecord.fromJson(Map<String, dynamic> json) {
    return HistoryRecord(
      id: json['id']?.toString() ?? '',
      pageRoute: json['page_route']?.toString() ?? '',
      pageTitle: json['page_title']?.toString() ?? '',
      pageIcon: json['page_icon']?.toString() ?? '',
      extra: json['extra']?.toString() ?? '',
      visitedAt: json['visited_at'] != null
          ? DateTime.tryParse(json['visited_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      params: json['params'] != null
          ? Map<String, dynamic>.from(json['params'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'page_route': pageRoute,
      'page_title': pageTitle,
      'page_icon': pageIcon,
      'extra': extra,
      'visited_at': visitedAt.toIso8601String(),
      'params': params,
    };
  }

  factory HistoryRecord.create({
    required String pageRoute,
    String pageTitle = '',
    String pageIcon = '',
    String extra = '',
    Map<String, dynamic>? params,
  }) {
    return HistoryRecord(
      id: 'hist_${DateTime.now().microsecondsSinceEpoch}',
      pageRoute: pageRoute,
      pageTitle: pageTitle,
      pageIcon: pageIcon,
      extra: extra,
      params: params,
    );
  }

  bool matches(String keyword) {
    if (keyword.isEmpty) return true;
    final lower = keyword.toLowerCase();
    return pageTitle.toLowerCase().contains(lower) ||
        pageRoute.toLowerCase().contains(lower) ||
        extra.toLowerCase().contains(lower);
  }

  HistoryRecord copyWith({
    String? id,
    String? pageRoute,
    String? pageTitle,
    String? pageIcon,
    String? extra,
    DateTime? visitedAt,
    Map<String, dynamic>? params,
  }) {
    return HistoryRecord(
      id: id ?? this.id,
      pageRoute: pageRoute ?? this.pageRoute,
      pageTitle: pageTitle ?? this.pageTitle,
      pageIcon: pageIcon ?? this.pageIcon,
      extra: extra ?? this.extra,
      visitedAt: visitedAt ?? this.visitedAt,
      params: params ?? this.params,
    );
  }
}

/// 按日期分组的历史记录
class HistoryGroup {
  final String dateLabel;
  final DateTime date;
  final List<HistoryRecord> records;

  HistoryGroup({
    required this.dateLabel,
    required this.date,
    required this.records,
  });
}

/// 浏览历史服务
class HistoryService {
  static const String _keyHistory = 'browse_history';
  static const int _maxRecords = 500;

  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _ensurePrefs async {
    if (_prefs == null) await init();
    return _prefs!;
  }

  // ===== 内部读写 =====

  Future<List<HistoryRecord>> _loadAll() async {
    final prefs = await _ensurePrefs;
    final raw = prefs.getString(_keyHistory);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) =>
              HistoryRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAll(List<HistoryRecord> records) async {
    final prefs = await _ensurePrefs;
    // 限制最大数量
    if (records.length > _maxRecords) {
      records.removeRange(_maxRecords, records.length);
    }
    await prefs.setString(
        _keyHistory, jsonEncode(records.map((e) => e.toJson()).toList()));
  }

  // ===== CRUD =====

  /// 记录一次页面访问（同一页面短时间内去重）
  Future<HistoryRecord> addRecord({
    required String pageRoute,
    String pageTitle = '',
    String pageIcon = '',
    String extra = '',
    Map<String, dynamic>? params,
  }) async {
    final records = await _loadAll();
    // 去重：如果最近一条记录的路由相同且在 5 分钟内，则更新时间
    if (records.isNotEmpty) {
      final last = records.first;
      if (last.pageRoute == pageRoute &&
          DateTime.now().difference(last.visitedAt).inMinutes < 5) {
        final updated = last.copyWith(
          pageTitle: pageTitle.isNotEmpty ? pageTitle : last.pageTitle,
          pageIcon: pageIcon.isNotEmpty ? pageIcon : last.pageIcon,
          extra: extra.isNotEmpty ? extra : last.extra,
          visitedAt: DateTime.now(),
          params: params ?? last.params,
        );
        records[0] = updated;
        await _saveAll(records);
        return updated;
      }
    }

    final record = HistoryRecord.create(
      pageRoute: pageRoute,
      pageTitle: pageTitle,
      pageIcon: pageIcon,
      extra: extra,
      params: params,
    );
    records.insert(0, record);
    await _saveAll(records);
    return record;
  }

  /// 获取所有历史记录（按时间倒序）
  Future<List<HistoryRecord>> getAll({int limit = 100}) async {
    final records = await _loadAll();
    records.sort((a, b) => b.visitedAt.compareTo(a.visitedAt));
    if (records.length > limit) return records.sublist(0, limit);
    return records;
  }

  /// 获取单条记录
  Future<HistoryRecord?> getById(String id) async {
    final records = await _loadAll();
    for (final record in records) {
      if (record.id == id) return record;
    }
    return null;
  }

  /// 删除单条记录
  Future<bool> delete(String id) async {
    final records = await _loadAll();
    final originalLength = records.length;
    records.removeWhere((e) => e.id == id);
    if (records.length == originalLength) return false;
    await _saveAll(records);
    return true;
  }

  /// 批量删除
  Future<int> deleteBatch(List<String> ids) async {
    final records = await _loadAll();
    final idSet = ids.toSet();
    final remaining = records.where((e) => !idSet.contains(e.id)).toList();
    final count = records.length - remaining.length;
    await _saveAll(remaining);
    return count;
  }

  /// 按页面路由删除
  Future<int> deleteByRoute(String pageRoute) async {
    final records = await _loadAll();
    final remaining =
        records.where((e) => e.pageRoute != pageRoute).toList();
    final count = records.length - remaining.length;
    await _saveAll(remaining);
    return count;
  }

  /// 清除指定日期之前的记录
  Future<int> clearBefore(DateTime date) async {
    final records = await _loadAll();
    final remaining =
        records.where((e) => e.visitedAt.isAfter(date)).toList();
    final count = records.length - remaining.length;
    await _saveAll(remaining);
    return count;
  }

  /// 清除所有历史
  Future<void> clearAll() async {
    final prefs = await _ensurePrefs;
    await prefs.remove(_keyHistory);
  }

  // ===== 查询与分组 =====

  /// 搜索历史
  Future<List<HistoryRecord>> search(String keyword,
      {int limit = 50}) async {
    final records = await getAll(limit: 1000);
    if (keyword.isEmpty) return records.take(limit).toList();
    return records.where((e) => e.matches(keyword)).take(limit).toList();
  }

  /// 按日期分组
  Future<List<HistoryGroup>> getGroupedByDate({int limit = 100}) async {
    final records = await getAll(limit: limit);
    final groups = <String, HistoryGroup>{};

    for (final record in records) {
      final date = DateTime(
        record.visitedAt.year,
        record.visitedAt.month,
        record.visitedAt.day,
      );
      final key = '${date.year}-${date.month}-${date.day}';
      final label = _formatDateLabel(date);

      if (!groups.containsKey(key)) {
        groups[key] = HistoryGroup(
          dateLabel: label,
          date: date,
          records: [],
        );
      }
      groups[key]!.records.add(record);
    }

    return groups.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return '今天';
    if (date == yesterday) return '昨天';

    final diff = today.difference(date).inDays;
    if (diff < 7) return '$diff天前';

    return '${date.month}月${date.day}日';
  }

  /// 获取最近访问的页面（去重，取前 N）
  Future<List<HistoryRecord>> getRecentPages({int limit = 10}) async {
    final records = await getAll(limit: 100);
    final seenRoutes = <String>{};
    final result = <HistoryRecord>[];
    for (final record in records) {
      if (!seenRoutes.contains(record.pageRoute)) {
        seenRoutes.add(record.pageRoute);
        result.add(record);
        if (result.length >= limit) break;
      }
    }
    return result;
  }

  /// 获取总记录数
  Future<int> getTotalCount() async {
    final records = await _loadAll();
    return records.length;
  }

  /// 获取今日访问次数
  Future<int> getTodayCount() async {
    final records = await _loadAll();
    final now = DateTime.now();
    return records
        .where((e) =>
            e.visitedAt.year == now.year &&
            e.visitedAt.month == now.month &&
            e.visitedAt.day == now.day)
        .length;
  }
}
