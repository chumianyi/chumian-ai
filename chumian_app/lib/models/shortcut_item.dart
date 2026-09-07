/// ============================================================================
/// ShortcutItem —— 快捷方式数据模型
///
/// 承载一个桌面/首页快捷方式的完整信息，包括动作、标签、图标、
/// 参数以及是否置顶。支持快捷方式的排序、固定与快速启动。
/// ============================================================================

/// 快捷方式动作类型枚举
enum ShortcutAction {
  /// 打开页面
  openPage,

  /// 执行工具
  runTool,

  /// 发起聊天
  startChat,

  /// 搜索
  search,

  /// 扫码
  scan,

  /// 分享
  share,

  /// 设置
  openSettings,

  /// 自定义
  custom,
}

/// ShortcutAction 枚举的字符串扩展
extension ShortcutActionExtension on ShortcutAction {
  String get value {
    switch (this) {
      case ShortcutAction.openPage:
        return 'open_page';
      case ShortcutAction.runTool:
        return 'run_tool';
      case ShortcutAction.startChat:
        return 'start_chat';
      case ShortcutAction.search:
        return 'search';
      case ShortcutAction.scan:
        return 'scan';
      case ShortcutAction.share:
        return 'share';
      case ShortcutAction.openSettings:
        return 'open_settings';
      case ShortcutAction.custom:
        return 'custom';
    }
  }

  String get label {
    switch (this) {
      case ShortcutAction.openPage:
        return '打开页面';
      case ShortcutAction.runTool:
        return '执行工具';
      case ShortcutAction.startChat:
        return '发起聊天';
      case ShortcutAction.search:
        return '搜索';
      case ShortcutAction.scan:
        return '扫码';
      case ShortcutAction.share:
        return '分享';
      case ShortcutAction.openSettings:
        return '设置';
      case ShortcutAction.custom:
        return '自定义';
    }
  }

  static ShortcutAction fromString(String? action) {
    switch (action) {
      case 'open_page':
        return ShortcutAction.openPage;
      case 'run_tool':
        return ShortcutAction.runTool;
      case 'start_chat':
        return ShortcutAction.startChat;
      case 'search':
        return ShortcutAction.search;
      case 'scan':
        return ShortcutAction.scan;
      case 'share':
        return ShortcutAction.share;
      case 'open_settings':
        return ShortcutAction.openSettings;
      default:
        return ShortcutAction.custom;
    }
  }
}

/// 快捷方式数据模型
class ShortcutItem {
  /// 快捷方式唯一标识
  final String id;

  /// 动作类型
  final ShortcutAction action;

  /// 显示标签
  final String label;

  /// 图标（Material Icons 名称或资源路径）
  final String icon;

  /// 动作参数（如页面路由、工具类型、搜索关键词等）
  final Map<String, dynamic> params;

  /// 是否置顶固定
  bool isPinned;

  /// 排序权重（越小越靠前）
  int sortOrder;

  /// 使用次数
  int useCount;

  /// 最后使用时间
  DateTime? lastUsedAt;

  /// 创建时间
  final DateTime createdAt;

  /// 背景色（ARGB 值，用于自定义快捷方式卡片）
  final int? backgroundColor;

  ShortcutItem({
    required this.id,
    required this.action,
    required this.label,
    required this.icon,
    Map<String, dynamic>? params,
    this.isPinned = false,
    this.sortOrder = 0,
    this.useCount = 0,
    this.lastUsedAt,
    DateTime? createdAt,
    this.backgroundColor,
  })  : params = params ?? {},
        createdAt = createdAt ?? DateTime.now();

  /// 从 JSON 反序列化
  factory ShortcutItem.fromJson(Map<String, dynamic> json) {
    return ShortcutItem(
      id: json['id']?.toString() ?? '',
      action: ShortcutActionExtension.fromString(json['action']?.toString()),
      label: json['label']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      params: json['params'] != null
          ? Map<String, dynamic>.from(json['params'] as Map)
          : {},
      isPinned: json['is_pinned'] == true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      useCount: (json['use_count'] as num?)?.toInt() ?? 0,
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.tryParse(json['last_used_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      backgroundColor: (json['background_color'] as num?)?.toInt(),
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action.value,
      'label': label,
      'icon': icon,
      'params': params,
      'is_pinned': isPinned,
      'sort_order': sortOrder,
      'use_count': useCount,
      'last_used_at': lastUsedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'background_color': backgroundColor,
    };
  }

  /// 创建一个新的快捷方式
  factory ShortcutItem.create({
    required ShortcutAction action,
    required String label,
    required String icon,
    Map<String, dynamic>? params,
    bool isPinned = false,
    int sortOrder = 0,
    int? backgroundColor,
  }) {
    return ShortcutItem(
      id: 'sc_${DateTime.now().microsecondsSinceEpoch}',
      action: action,
      label: label,
      icon: icon,
      params: params,
      isPinned: isPinned,
      sortOrder: sortOrder,
      backgroundColor: backgroundColor,
    );
  }

  /// 目标路由（从 params 中提取）
  String? get targetRoute => params['route']?.toString();

  /// 是否最近使用（7天内）
  bool get isRecentlyUsed {
    if (lastUsedAt == null) return false;
    return DateTime.now().difference(lastUsedAt!).inDays <= 7;
  }

  /// 搜索匹配
  bool matches(String keyword) {
    if (keyword.isEmpty) return true;
    final lower = keyword.toLowerCase();
    return label.toLowerCase().contains(lower);
  }

  /// 复制一份快捷方式
  ShortcutItem copyWith({
    String? id,
    ShortcutAction? action,
    String? label,
    String? icon,
    Map<String, dynamic>? params,
    bool? isPinned,
    int? sortOrder,
    int? useCount,
    DateTime? lastUsedAt,
    DateTime? createdAt,
    int? backgroundColor,
  }) {
    return ShortcutItem(
      id: id ?? this.id,
      action: action ?? this.action,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      params: params ?? this.params,
      isPinned: isPinned ?? this.isPinned,
      sortOrder: sortOrder ?? this.sortOrder,
      useCount: useCount ?? this.useCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }
}
