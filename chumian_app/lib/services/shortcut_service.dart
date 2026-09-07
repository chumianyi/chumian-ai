import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// ============================================================================
/// ShortcutService —— 应用快捷方式服务
///
/// 职责：
///   1. 应用快捷方式：管理 Android Shortcuts / iOS Quick Actions
///   2. 快捷操作创建：动态创建带图标、标题、跳转路由的快捷方式
///   3. 动态更新：运行时增删改快捷方式
///   4. 点击处理：接收快捷方式点击事件，路由到对应页面
///   5. 最多4个快捷方式：系统限制，超出时自动替换优先级最低的
/// ============================================================================

/// 快捷方式定义
class AppShortcut {
  final String id;
  final String shortLabel;
  final String longLabel;
  final String iconName;
  final String route;
  final Map<String, dynamic> arguments;
  final int priority;
  final bool isPinned;

  AppShortcut({
    required this.id,
    required this.shortLabel,
    required this.longLabel,
    this.iconName = 'ic_launcher',
    required this.route,
    this.arguments = const {},
    this.priority = 0,
    this.isPinned = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'short_label': shortLabel,
        'long_label': longLabel,
        'icon_name': iconName,
        'route': route,
        'arguments': arguments,
        'priority': priority,
        'is_pinned': isPinned,
      };

  factory AppShortcut.fromJson(Map<String, dynamic> json) => AppShortcut(
        id: json['id']?.toString() ?? '',
        shortLabel: json['short_label']?.toString() ?? '',
        longLabel: json['long_label']?.toString() ?? '',
        iconName: json['icon_name']?.toString() ?? 'ic_launcher',
        route: json['route']?.toString() ?? '/',
        arguments: Map<String, dynamic>.from(json['arguments'] ?? {}),
        priority: (json['priority'] as num?)?.toInt() ?? 0,
        isPinned: json['is_pinned'] == true,
      );
}

/// 快捷方式点击事件
class ShortcutAction {
  final String shortcutId;
  final String route;
  final Map<String, dynamic> arguments;
  final DateTime timestamp;

  ShortcutAction({
    required this.shortcutId,
    required this.route,
    required this.arguments,
    required this.timestamp,
  });
}

class ShortcutService {
  /// 单例实例
  static final ShortcutService _instance = ShortcutService._internal();
  factory ShortcutService() => _instance;
  ShortcutService._internal();

  // ===== 配置 =====
  /// 最大快捷方式数量（Android 系统限制）
  static const int _maxShortcuts = 4;

  /// 快捷方式配置文件名
  static const String _shortcutsFileName = 'app_shortcuts.json';

  // ===== 状态 =====
  final List<AppShortcut> _shortcuts = [];
  final StreamController<ShortcutAction> _actionController =
      StreamController<ShortcutAction>.broadcast();
  final StreamController<List<AppShortcut>> _shortcutsController =
      StreamController<List<AppShortcut>>.broadcast();
  bool _initialized = false;
  ShortcutAction? _pendingAction;

  // ==========================================================================
  // 初始化
  // ==========================================================================

  /// 初始化快捷方式服务
  Future<void> init() async {
    if (_initialized) return;
    await _loadShortcuts();
    // 如果没有快捷方式，设置默认快捷方式
    if (_shortcuts.isEmpty) {
      await _setupDefaultShortcuts();
    }
    _initialized = true;
  }

  /// 设置默认快捷方式
  Future<void> _setupDefaultShortcuts() async {
    final defaults = [
      AppShortcut(
        id: 'new_chat',
        shortLabel: '新对话',
        longLabel: '开始新的 AI 对话',
        iconName: 'ic_chat',
        route: '/chat/new',
        priority: 100,
        isPinned: true,
      ),
      AppShortcut(
        id: 'search',
        shortLabel: '搜索',
        longLabel: '搜索聊天记录和内容',
        iconName: 'ic_search',
        route: '/search',
        priority: 90,
      ),
      AppShortcut(
        id: 'image_gen',
        shortLabel: 'AI 绘画',
        longLabel: '使用 AI 生成图片',
        iconName: 'ic_image',
        route: '/image/generate',
        priority: 80,
      ),
      AppShortcut(
        id: 'writing',
        shortLabel: 'AI 写作',
        longLabel: '使用 AI 辅助写作',
        iconName: 'ic_edit',
        route: '/writing',
        priority: 70,
      ),
    ];
    _shortcuts.addAll(defaults);
    await _persistShortcuts();
    _notifyShortcutsChanged();
  }

  // ==========================================================================
  // 快捷方式管理
  // ==========================================================================

  /// 获取所有快捷方式
  List<AppShortcut> get shortcuts => List.unmodifiable(_shortcuts);

  /// 快捷方式变化流
  Stream<List<AppShortcut>> get shortcutsStream =>
      _shortcutsController.stream;

  /// 添加快捷方式
  ///
  /// 如果已达上限，会替换优先级最低且未固定的快捷方式
  Future<bool> addShortcut(AppShortcut shortcut) async {
    // 检查是否已存在
    if (_shortcuts.any((s) => s.id == shortcut.id)) {
      return updateShortcut(shortcut);
    }

    if (_shortcuts.length >= _maxShortcuts) {
      // 查找可替换的最低优先级未固定快捷方式
      final replaceable = _shortcuts
          .where((s) => !s.isPinned)
          .toList()
        ..sort((a, b) => a.priority.compareTo(b.priority));

      if (replaceable.isEmpty) {
        return false; // 全部固定，无法替换
      }

      final toRemove = replaceable.first;
      _shortcuts.removeWhere((s) => s.id == toRemove.id);
    }

    _shortcuts.add(shortcut);
    _sortShortcuts();
    await _persistShortcuts();
    _notifyShortcutsChanged();
    return true;
  }

  /// 更新快捷方式
  Future<bool> updateShortcut(AppShortcut shortcut) async {
    final index = _shortcuts.indexWhere((s) => s.id == shortcut.id);
    if (index < 0) return false;
    _shortcuts[index] = shortcut;
    _sortShortcuts();
    await _persistShortcuts();
    _notifyShortcutsChanged();
    return true;
  }

  /// 移除快捷方式
  Future<bool> removeShortcut(String shortcutId) async {
    final shortcut = _shortcuts.firstWhere(
      (s) => s.id == shortcutId,
      orElse: () => _emptyShortcut(),
    );
    if (shortcut.id.isEmpty) return false;
    if (shortcut.isPinned) return false; // 固定的不可移除

    _shortcuts.removeWhere((s) => s.id == shortcutId);
    await _persistShortcuts();
    _notifyShortcutsChanged();
    return true;
  }

  /// 获取快捷方式
  AppShortcut? getShortcut(String shortcutId) {
    try {
      return _shortcuts.firstWhere((s) => s.id == shortcutId);
    } catch (_) {
      return null;
    }
  }

  /// 按优先级排序（高优先级在前）
  void _sortShortcuts() {
    _shortcuts.sort((a, b) {
      // 固定的排前面
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.priority.compareTo(a.priority);
    });
  }

  AppShortcut _emptyShortcut() => AppShortcut(
        id: '',
        shortLabel: '',
        longLabel: '',
        route: '',
      );

  // ==========================================================================
  // 点击处理
  // ==========================================================================

  /// 快捷方式点击事件流
  Stream<ShortcutAction> get actionStream => _actionController.stream;

  /// 处理快捷方式点击（由原生层调用）
  void handleShortcutClick(String shortcutId) {
    final shortcut = getShortcut(shortcutId);
    if (shortcut == null) return;

    final action = ShortcutAction(
      shortcutId: shortcutId,
      route: shortcut.route,
      arguments: shortcut.arguments,
      timestamp: DateTime.now(),
    );

    _pendingAction = action;
    _actionController.add(action);
  }

  /// 获取并清除待处理的点击事件
  ShortcutAction? consumePendingAction() {
    final action = _pendingAction;
    _pendingAction = null;
    return action;
  }

  /// 是否有待处理的点击事件
  bool get hasPendingAction => _pendingAction != null;

  // ==========================================================================
  // 固定快捷方式
  // ==========================================================================

  /// 固定/取消固定快捷方式
  Future<bool> setPinned(String shortcutId, bool pinned) async {
    final index = _shortcuts.indexWhere((s) => s.id == shortcutId);
    if (index < 0) return false;

    final old = _shortcuts[index];
    _shortcuts[index] = AppShortcut(
      id: old.id,
      shortLabel: old.shortLabel,
      longLabel: old.longLabel,
      iconName: old.iconName,
      route: old.route,
      arguments: old.arguments,
      priority: old.priority,
      isPinned: pinned,
    );

    _sortShortcuts();
    await _persistShortcuts();
    _notifyShortcutsChanged();
    return true;
  }

  /// 获取固定的快捷方式
  List<AppShortcut> get pinnedShortcuts =>
      _shortcuts.where((s) => s.isPinned).toList();

  // ==========================================================================
  // 批量操作
  // ==========================================================================

  /// 重置为默认快捷方式
  Future<void> resetToDefaults() async {
    _shortcuts.clear();
    await _setupDefaultShortcuts();
  }

  /// 清空所有快捷方式
  Future<void> clearAll() async {
    _shortcuts.clear();
    await _persistShortcuts();
    _notifyShortcutsChanged();
  }

  /// 当前快捷方式数量
  int get count => _shortcuts.length;

  /// 是否达到上限
  bool get isFull => _shortcuts.length >= _maxShortcuts;

  /// 最大快捷方式数
  int get maxShortcuts => _maxShortcuts;

  // ==========================================================================
  // 通知
  // ==========================================================================

  void _notifyShortcutsChanged() {
    _shortcutsController.add(List.unmodifiable(_shortcuts));
  }

  // ==========================================================================
  // 持久化
  // ==========================================================================

  Future<Directory> _getDocDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final shortcutDir = Directory('${dir.path}/shortcuts');
    if (!shortcutDir.existsSync()) {
      shortcutDir.createSync(recursive: true);
    }
    return shortcutDir;
  }

  Future<void> _persistShortcuts() async {
    try {
      final dir = await _getDocDir();
      final file = File('${dir.path}/$_shortcutsFileName');
      await file.writeAsString(
          jsonEncode(_shortcuts.map((s) => s.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _loadShortcuts() async {
    try {
      final dir = await _getDocDir();
      final file = File('${dir.path}/$_shortcutsFileName');
      if (!file.existsSync()) return;
      final content = await file.readAsString();
      final list = jsonDecode(content) as List;
      _shortcuts.clear();
      for (final item in list) {
        _shortcuts.add(AppShortcut.fromJson(
            Map<String, dynamic>.from(item as Map)));
      }
      _sortShortcuts();
    } catch (_) {}
  }

  /// 销毁服务
  void dispose() {
    _actionController.close();
    _shortcutsController.close();
  }
}
