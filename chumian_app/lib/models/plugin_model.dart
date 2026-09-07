/// ============================================================================
/// PluginModel —— 插件数据模型
///
/// 承载一个可安装插件的完整元信息，包括名称、描述、版本、作者、
/// 所需权限、安装状态以及分类。支持插件市场展示与本地安装管理。
/// ============================================================================

/// 插件分类枚举
enum PluginCategory {
  /// 效率工具
  productivity,

  /// 娱乐
  entertainment,

  /// 开发
  developer,

  /// 社交
  social,

  /// 媒体
  media,

  /// 教育
  education,

  /// 其他
  other,
}

/// PluginCategory 枚举的字符串扩展
extension PluginCategoryExtension on PluginCategory {
  String get value {
    switch (this) {
      case PluginCategory.productivity:
        return 'productivity';
      case PluginCategory.entertainment:
        return 'entertainment';
      case PluginCategory.developer:
        return 'developer';
      case PluginCategory.social:
        return 'social';
      case PluginCategory.media:
        return 'media';
      case PluginCategory.education:
        return 'education';
      case PluginCategory.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case PluginCategory.productivity:
        return '效率工具';
      case PluginCategory.entertainment:
        return '娱乐';
      case PluginCategory.developer:
        return '开发';
      case PluginCategory.social:
        return '社交';
      case PluginCategory.media:
        return '媒体';
      case PluginCategory.education:
        return '教育';
      case PluginCategory.other:
        return '其他';
    }
  }

  static PluginCategory fromString(String? category) {
    switch (category) {
      case 'productivity':
        return PluginCategory.productivity;
      case 'entertainment':
        return PluginCategory.entertainment;
      case 'developer':
        return PluginCategory.developer;
      case 'social':
        return PluginCategory.social;
      case 'media':
        return PluginCategory.media;
      case 'education':
        return PluginCategory.education;
      default:
        return PluginCategory.other;
    }
  }
}

/// 插件权限枚举
enum PluginPermission {
  /// 网络访问
  internet,

  /// 本地存储
  storage,

  /// 相机
  camera,

  /// 麦克风
  microphone,

  /// 位置信息
  location,

  /// 通知
  notification,

  /// 联系人
  contacts,

  /// 日历
  calendar,
}

/// PluginPermission 枚举的字符串扩展
extension PluginPermissionExtension on PluginPermission {
  String get value {
    switch (this) {
      case PluginPermission.internet:
        return 'internet';
      case PluginPermission.storage:
        return 'storage';
      case PluginPermission.camera:
        return 'camera';
      case PluginPermission.microphone:
        return 'microphone';
      case PluginPermission.location:
        return 'location';
      case PluginPermission.notification:
        return 'notification';
      case PluginPermission.contacts:
        return 'contacts';
      case PluginPermission.calendar:
        return 'calendar';
    }
  }

  String get label {
    switch (this) {
      case PluginPermission.internet:
        return '网络访问';
      case PluginPermission.storage:
        return '本地存储';
      case PluginPermission.camera:
        return '相机';
      case PluginPermission.microphone:
        return '麦克风';
      case PluginPermission.location:
        return '位置信息';
      case PluginPermission.notification:
        return '通知';
      case PluginPermission.contacts:
        return '联系人';
      case PluginPermission.calendar:
        return '日历';
    }
  }

  static PluginPermission fromString(String? permission) {
    switch (permission) {
      case 'internet':
        return PluginPermission.internet;
      case 'storage':
        return PluginPermission.storage;
      case 'camera':
        return PluginPermission.camera;
      case 'microphone':
        return PluginPermission.microphone;
      case 'location':
        return PluginPermission.location;
      case 'notification':
        return PluginPermission.notification;
      case 'contacts':
        return PluginPermission.contacts;
      case 'calendar':
        return PluginPermission.calendar;
      default:
        return PluginPermission.internet;
    }
  }
}

/// 插件数据模型
class PluginModel {
  /// 插件唯一标识
  final String id;

  /// 插件名称
  final String name;

  /// 插件描述
  final String description;

  /// 版本号（语义化版本）
  final String version;

  /// 作者
  final String author;

  /// 所需权限列表
  final List<PluginPermission> permissions;

  /// 是否已安装
  bool isInstalled;

  /// 插件分类
  final PluginCategory category;

  /// 图标资源路径或 URL
  final String icon;

  /// 下载量
  final int downloadCount;

  /// 评分（0-5）
  final double rating;

  /// 评分人数
  final int ratingCount;

  /// 更新时间
  final DateTime updatedAt;

  /// 插件入口页面路由
  final String entryRoute;

  /// 是否启用
  bool isEnabled;

  PluginModel({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.author,
    List<PluginPermission>? permissions,
    this.isInstalled = false,
    this.category = PluginCategory.other,
    this.icon = '',
    this.downloadCount = 0,
    this.rating = 0.0,
    this.ratingCount = 0,
    DateTime? updatedAt,
    this.entryRoute = '',
    this.isEnabled = true,
  })  : permissions = permissions ?? [],
        updatedAt = updatedAt ?? DateTime.now();

  /// 从 JSON 反序列化
  factory PluginModel.fromJson(Map<String, dynamic> json) {
    return PluginModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      version: json['version']?.toString() ?? '1.0.0',
      author: json['author']?.toString() ?? '',
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => PluginPermissionExtension.fromString(e.toString()))
              .toList() ??
          [],
      isInstalled: json['is_installed'] == true,
      category: PluginCategoryExtension.fromString(json['category']?.toString()),
      icon: json['icon']?.toString() ?? '',
      downloadCount: (json['download_count'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      entryRoute: json['entry_route']?.toString() ?? '',
      isEnabled: json['is_enabled'] != false,
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'version': version,
      'author': author,
      'permissions': permissions.map((e) => e.value).toList(),
      'is_installed': isInstalled,
      'category': category.value,
      'icon': icon,
      'download_count': downloadCount,
      'rating': rating,
      'rating_count': ratingCount,
      'updated_at': updatedAt.toIso8601String(),
      'entry_route': entryRoute,
      'is_enabled': isEnabled,
    };
  }

  /// 格式化下载量
  String get formattedDownloads {
    if (downloadCount >= 10000) {
      return '${(downloadCount / 10000).toStringAsFixed(1)}万';
    }
    if (downloadCount >= 1000) {
      return '${(downloadCount / 1000).toStringAsFixed(1)}k';
    }
    return '$downloadCount';
  }

  /// 是否有危险权限
  bool get hasSensitivePermission {
    return permissions.any((p) =>
        p == PluginPermission.camera ||
        p == PluginPermission.microphone ||
        p == PluginPermission.location ||
        p == PluginPermission.contacts);
  }

  /// 搜索匹配
  bool matches(String keyword) {
    if (keyword.isEmpty) return true;
    final lower = keyword.toLowerCase();
    return name.toLowerCase().contains(lower) ||
        description.toLowerCase().contains(lower) ||
        author.toLowerCase().contains(lower);
  }

  /// 复制一份插件
  PluginModel copyWith({
    String? id,
    String? name,
    String? description,
    String? version,
    String? author,
    List<PluginPermission>? permissions,
    bool? isInstalled,
    PluginCategory? category,
    String? icon,
    int? downloadCount,
    double? rating,
    int? ratingCount,
    DateTime? updatedAt,
    String? entryRoute,
    bool? isEnabled,
  }) {
    return PluginModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      author: author ?? this.author,
      permissions: permissions ?? this.permissions,
      isInstalled: isInstalled ?? this.isInstalled,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      downloadCount: downloadCount ?? this.downloadCount,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      updatedAt: updatedAt ?? this.updatedAt,
      entryRoute: entryRoute ?? this.entryRoute,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
