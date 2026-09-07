import 'package:flutter/foundation.dart';
import 'package:chumian_ai/models/note_model.dart';
import 'package:chumian_ai/services/local_storage_service.dart';

/// ============================================================================
/// NoteProvider —— 便签状态管理 Provider
///
/// 职责：
///   1. 便签 CRUD 操作
///   2. 颜色标记与置顶管理
///   3. 便签搜索
///   4. 本地持久化
/// ============================================================================
class NoteProvider extends ChangeNotifier {
  /// 本地存储服务
  final LocalStorageService _storage = LocalStorageService();

  /// 便签列表
  final List<Note> _notes = [];

  /// 是否加载完成
  bool _isLoaded = false;

  /// 当前搜索关键词
  String _searchKeyword = '';

  /// 当前筛选颜色
  NoteColor? _filterColor;

  /// 是否只显示置顶
  bool _showPinnedOnly = false;

  // ===== Getters =====
  List<Note> get notes => List.unmodifiable(_notes);
  bool get isLoaded => _isLoaded;
  String get searchKeyword => _searchKeyword;
  NoteColor? get filterColor => _filterColor;
  bool get showPinnedOnly => _showPinnedOnly;
  bool get hasNotes => _notes.isNotEmpty;

  /// 便签总数
  int get totalCount => _notes.length;

  /// 置顶便签数
  int get pinnedCount => _notes.where((n) => n.isPinned).length;

  /// 筛选后的便签列表
  List<Note> get filteredNotes {
    var result = _notes;

    // 搜索过滤
    if (_searchKeyword.isNotEmpty) {
      result = result.where((n) => n.matches(_searchKeyword)).toList();
    }

    // 颜色过滤
    if (_filterColor != null) {
      result = result.where((n) => n.color == _filterColor).toList();
    }

    // 置顶过滤
    if (_showPinnedOnly) {
      result = result.where((n) => n.isPinned).toList();
    }

    return result;
  }

  // ==========================================================================
  // 初始化与加载
  // ==========================================================================

  /// 初始化：加载所有便签
  Future<void> init() async {
    await _storage.init();
    await loadNotes();
  }

  /// 从本地存储加载便签
  Future<void> loadNotes() async {
    try {
      final notes = await _storage.getAllNotes();
      _notes.clear();
      _notes.addAll(notes);
      _isLoaded = true;
      notifyListeners();
    } catch (_) {
      _isLoaded = true;
      notifyListeners();
    }
  }

  // ==========================================================================
  // CRUD 操作
  // ==========================================================================

  /// 创建新便签
  Future<Note> createNote({
    String title = '',
    String content = '',
    NoteColor color = NoteColor.white,
  }) async {
    final note = Note.create(
      title: title,
      content: content,
      color: color,
    );
    _notes.insert(0, note);
    await _storage.saveNote(note);
    _sortNotes();
    notifyListeners();
    return note;
  }

  /// 更新便签
  Future<void> updateNote(Note note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      note.updatedAt = DateTime.now();
      _notes[index] = note;
      await _storage.saveNote(note);
      _sortNotes();
      notifyListeners();
    }
  }

  /// 更新便签标题
  Future<void> updateTitle(String id, String title) async {
    final note = _getNoteById(id);
    if (note != null) {
      note.title = title;
      note.updatedAt = DateTime.now();
      await _storage.saveNote(note);
      _sortNotes();
      notifyListeners();
    }
  }

  /// 更新便签内容
  Future<void> updateContent(String id, String content) async {
    final note = _getNoteById(id);
    if (note != null) {
      note.content = content;
      note.updatedAt = DateTime.now();
      await _storage.saveNote(note);
      _sortNotes();
      notifyListeners();
    }
  }

  /// 删除便签
  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await _storage.deleteNote(id);
    notifyListeners();
  }

  /// 批量删除便签
  Future<void> deleteNotes(List<String> ids) async {
    _notes.removeWhere((n) => ids.contains(n.id));
    await _storage.deleteNotes(ids);
    notifyListeners();
  }

  /// 清空所有便签
  Future<void> clearAllNotes() async {
    _notes.clear();
    await _storage.clearAllNotes();
    notifyListeners();
  }

  /// 根据 ID 获取便签
  Note? getNoteById(String id) {
    return _getNoteById(id);
  }

  Note? _getNoteById(String id) {
    for (final note in _notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  // ==========================================================================
  // 颜色标记
  // ==========================================================================

  /// 设置便签颜色
  Future<void> setColor(String id, NoteColor color) async {
    final note = _getNoteById(id);
    if (note != null) {
      note.color = color;
      note.updatedAt = DateTime.now();
      await _storage.saveNote(note);
      notifyListeners();
    }
  }

  /// 获取所有使用中的颜色
  List<NoteColor> getUsedColors() {
    final colors = <NoteColor>{};
    for (final note in _notes) {
      colors.add(note.color);
    }
    return colors.toList();
  }

  // ==========================================================================
  // 置顶管理
  // ==========================================================================

  /// 切换置顶状态
  Future<void> togglePin(String id) async {
    final note = _getNoteById(id);
    if (note != null) {
      note.isPinned = !note.isPinned;
      note.updatedAt = DateTime.now();
      await _storage.saveNote(note);
      _sortNotes();
      notifyListeners();
    }
  }

  /// 设置置顶状态
  Future<void> setPinned(String id, bool pinned) async {
    final note = _getNoteById(id);
    if (note != null) {
      note.isPinned = pinned;
      note.updatedAt = DateTime.now();
      await _storage.saveNote(note);
      _sortNotes();
      notifyListeners();
    }
  }

  // ==========================================================================
  // 搜索与筛选
  // ==========================================================================

  /// 设置搜索关键词
  void setSearchKeyword(String keyword) {
    _searchKeyword = keyword;
    notifyListeners();
  }

  /// 清除搜索
  void clearSearch() {
    _searchKeyword = '';
    notifyListeners();
  }

  /// 设置颜色筛选
  void setFilterColor(NoteColor? color) {
    _filterColor = color;
    notifyListeners();
  }

  /// 清除颜色筛选
  void clearFilterColor() {
    _filterColor = null;
    notifyListeners();
  }

  /// 切换只显示置顶
  void togglePinnedOnly() {
    _showPinnedOnly = !_showPinnedOnly;
    notifyListeners();
  }

  /// 清除所有筛选
  void clearFilters() {
    _searchKeyword = '';
    _filterColor = null;
    _showPinnedOnly = false;
    notifyListeners();
  }

  // ==========================================================================
  // 内部工具
  // ==========================================================================

  /// 排序便签：置顶优先，然后按更新时间倒序
  void _sortNotes() {
    _notes.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }

  /// 刷新便签列表
  Future<void> refresh() async {
    await loadNotes();
  }

  /// 统计便签字数
  int get totalWordCount {
    return _notes.fold(0, (sum, note) => sum + note.wordCount);
  }
}
