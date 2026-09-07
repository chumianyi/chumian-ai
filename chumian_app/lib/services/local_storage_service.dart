import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chumian_ai/models/note_model.dart';

/// ============================================================================
/// LocalStorageService —— 结构化本地存储服务
///
/// 基于 SharedPreferences 提供键值对之上的结构化存储能力，
/// 支持便签、搜索历史、设置缓存、草稿等数据的 CRUD 操作，
/// 内置 JSON 序列化与容量管理。
/// ============================================================================
class LocalStorageService {
  // ===== 存储键前缀 =====
  static const String _prefixNotes = 'note_';
  static const String _prefixSearchHistory = 'search_history_';
  static const String _keySearchHistoryList = 'search_history_list';
  static const String _prefixDraft = 'draft_';
  static const String _keySettingsCache = 'settings_cache';
  static const String _keyUsageStats = 'usage_stats';

  /// 单例实例
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  SharedPreferences? _prefs;

  /// 初始化：获取 SharedPreferences 实例
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 确保已初始化
  Future<SharedPreferences> get _ensurePrefs async {
    if (_prefs == null) await init();
    return _prefs!;
  }

  // ==========================================================================
  // 通用键值操作
  // ==========================================================================

  /// 存储字符串
  Future<void> setString(String key, String value) async {
    final prefs = await _ensurePrefs;
    await prefs.setString(key, value);
  }

  /// 读取字符串
  Future<String?> getString(String key) async {
    final prefs = await _ensurePrefs;
    return prefs.getString(key);
  }

  /// 存储 JSON 对象
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    await setString(key, jsonEncode(value));
  }

  /// 读取 JSON 对象
  Future<Map<String, dynamic>?> getJson(String key) async {
    final raw = await getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  /// 存储 JSON 列表
  Future<void> setJsonList(String key, List<dynamic> value) async {
    await setString(key, jsonEncode(value));
  }

  /// 读取 JSON 列表
  Future<List<dynamic>> getJsonList(String key) async {
    final raw = await getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  /// 删除指定键
  Future<bool> remove(String key) async {
    final prefs = await _ensurePrefs;
    return prefs.remove(key);
  }

  /// 判断键是否存在
  Future<bool> contains(String key) async {
    final prefs = await _ensurePrefs;
    return prefs.containsKey(key);
  }

  // ==========================================================================
  // 便签管理
  // ==========================================================================

  /// 保存便签（新增或更新）
  Future<void> saveNote(Note note) async {
    await setJson('$_prefixNotes${note.id}', note.toJson());
  }

  /// 获取单条便签
  Future<Note?> getNote(String id) async {
    final json = await getJson('$_prefixNotes$id');
    if (json == null) return null;
    return Note.fromJson(json);
  }

  /// 获取所有便签
  Future<List<Note>> getAllNotes() async {
    final prefs = await _ensurePrefs;
    final notes = <Note>[];
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_prefixNotes)) {
        final raw = prefs.getString(key);
        if (raw != null && raw.isNotEmpty) {
          try {
            notes.add(Note.fromJson(
                Map<String, dynamic>.from(jsonDecode(raw) as Map)));
          } catch (_) {
            // 跳过损坏的数据
          }
        }
      }
    }
    // 置顶优先，然后按更新时间倒序
    notes.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return notes;
  }

  /// 删除便签
  Future<bool> deleteNote(String id) async {
    return remove('$_prefixNotes$id');
  }

  /// 批量删除便签
  Future<int> deleteNotes(List<String> ids) async {
    int count = 0;
    for (final id in ids) {
      if (await deleteNote(id)) count++;
    }
    return count;
  }

  /// 清空所有便签
  Future<int> clearAllNotes() async {
    final prefs = await _ensurePrefs;
    int count = 0;
    final keysToRemove = prefs
        .getKeys()
        .where((k) => k.startsWith(_prefixNotes))
        .toList();
    for (final key in keysToRemove) {
      await prefs.remove(key);
      count++;
    }
    return count;
  }

  // ==========================================================================
  // 搜索历史管理
  // ==========================================================================

  /// 添加搜索历史（自动去重，最多保留 50 条）
  Future<void> addSearchHistory(String keyword, {int maxItems = 50}) async {
    if (keyword.trim().isEmpty) return;
    final history = await getSearchHistory();
    // 移除已存在的相同关键词
    history.removeWhere((k) => k.toLowerCase() == keyword.toLowerCase());
    // 插入到最前面
    history.insert(0, keyword.trim());
    // 限制数量
    if (history.length > maxItems) {
      history.removeRange(maxItems, history.length);
    }
    await setJsonList(_keySearchHistoryList, history);
  }

  /// 获取搜索历史
  Future<List<String>> getSearchHistory() async {
    final list = await getJsonList(_keySearchHistoryList);
    return list.map((e) => e.toString()).toList();
  }

  /// 删除单条搜索历史
  Future<void> removeSearchHistory(String keyword) async {
    final history = await getSearchHistory();
    history.removeWhere((k) => k.toLowerCase() == keyword.toLowerCase());
    await setJsonList(_keySearchHistoryList, history);
  }

  /// 清空搜索历史
  Future<void> clearSearchHistory() async {
    await remove(_keySearchHistoryList);
  }

  // ==========================================================================
  // 草稿管理
  // ==========================================================================

  /// 保存草稿
  Future<void> saveDraft(String draftKey, String content) async {
    await setString('$_prefixDraft$draftKey', content);
  }

  /// 获取草稿
  Future<String?> getDraft(String draftKey) async {
    return getString('$_prefixDraft$draftKey');
  }

  /// 删除草稿
  Future<bool> deleteDraft(String draftKey) async {
    return remove('$_prefixDraft$draftKey');
  }

  /// 判断草稿是否存在且非空
  Future<bool> hasDraft(String draftKey) async {
    final content = await getDraft(draftKey);
    return content != null && content.trim().isNotEmpty;
  }

  // ==========================================================================
  // 设置缓存
  // ==========================================================================

  /// 保存设置缓存
  Future<void> saveSettingsCache(Map<String, dynamic> settings) async {
    await setJson(_keySettingsCache, settings);
  }

  /// 获取设置缓存
  Future<Map<String, dynamic>> getSettingsCache() async {
    final json = await getJson(_keySettingsCache);
    return json ?? {};
  }

  /// 更新单个设置项
  Future<void> updateSetting(String key, dynamic value) async {
    final settings = await getSettingsCache();
    settings[key] = value;
    await saveSettingsCache(settings);
  }

  /// 获取单个设置项
  Future<dynamic> getSetting(String key, {dynamic defaultValue}) async {
    final settings = await getSettingsCache();
    return settings[key] ?? defaultValue;
  }

  // ==========================================================================
  // 容量管理
  // ==========================================================================

  /// 估算已使用存储大小（字节）
  Future<int> getUsedSize() async {
    final prefs = await _ensurePrefs;
    int total = 0;
    for (final key in prefs.getKeys()) {
      final value = prefs.get(key);
      total += key.length;
      if (value is String) {
        total += value.length;
      } else if (value is List) {
        total += value.length * 8;
      } else {
        total += 8;
      }
    }
    return total;
  }

  /// 获取存储项数量
  Future<int> getItemCount() async {
    final prefs = await _ensurePrefs;
    return prefs.getKeys().length;
  }

  /// 按前缀清除数据
  Future<int> clearByPrefix(String prefix) async {
    final prefs = await _ensurePrefs;
    int count = 0;
    final keysToRemove =
        prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
    for (final key in keysToRemove) {
      await prefs.remove(key);
      count++;
    }
    return count;
  }

  /// 清除所有数据（谨慎使用）
  Future<bool> clearAll() async {
    final prefs = await _ensurePrefs;
    return prefs.clear();
  }
}
