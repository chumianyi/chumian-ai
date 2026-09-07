/// ============================================================================
/// ThemePreset —— 主题预设数据模型
///
/// 承载一套完整的主题配色方案，包括主色、背景色、暗色模式标记
/// 以及是否为自定义主题。支持内置预设与用户自定义预设的持久化。
/// ============================================================================

/// 主题预设分类
enum ThemePresetCategory {
  /// 官方内置
  official,

  /// 用户自定义
  custom,

  /// 社区分享
  community,
}

/// ThemePresetCategory 枚举的字符串扩展
extension ThemePresetCategoryExtension on ThemePresetCategory {
  String get value {
    switch (this) {
      case ThemePresetCategory.official:
        return 'official';
      case ThemePresetCategory.custom:
        return 'custom';
      case ThemePresetCategory.community:
        return 'community';
    }
  }

  static ThemePresetCategory fromString(String? category) {
    switch (category) {
      case 'custom':
        return ThemePresetCategory.custom;
      case 'community':
        return ThemePresetCategory.community;
      default:
        return ThemePresetCategory.official;
    }
  }
}

/// 主题预设数据模型
class ThemePreset {
  /// 预设唯一标识
  final String id;

  /// 预设名称
  final String name;

  /// 主色（ARGB 十六进制值）
  final int primaryColor;

  /// 主色浅色
  final int primaryLightColor;

  /// 主色深色
  final int primaryDarkColor;

  /// 背景色
  final int backgroundColor;

  /// 表面色
  final int surfaceColor;

  /// 文字主色
  final int textPrimaryColor;

  /// 文字次色
  final int textSecondaryColor;

  /// 是否为暗色模式
  final bool isDark;

  /// 是否为自定义主题
  final bool isCustom;

  /// 预设分类
  final ThemePresetCategory category;

  /// 作者（社区主题）
  final String author;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;

  ThemePreset({
    required this.id,
    required this.name,
    required this.primaryColor,
    int? primaryLightColor,
    int? primaryDarkColor,
    required this.backgroundColor,
    int? surfaceColor,
    int? textPrimaryColor,
    int? textSecondaryColor,
    this.isDark = false,
    this.isCustom = false,
    this.category = ThemePresetCategory.official,
    this.author = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : primaryLightColor = primaryLightColor ?? primaryColor,
        primaryDarkColor = primaryDarkColor ?? primaryColor,
        surfaceColor = surfaceColor ?? backgroundColor,
        textPrimaryColor = textPrimaryColor ?? 0xFF2D2D3A,
        textSecondaryColor = textSecondaryColor ?? 0xFF6E6E80,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 从 JSON 反序列化
  factory ThemePreset.fromJson(Map<String, dynamic> json) {
    return ThemePreset(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      primaryColor: (json['primary_color'] as num?)?.toInt() ?? 0xFFFF6B9D,
      primaryLightColor: (json['primary_light_color'] as num?)?.toInt(),
      primaryDarkColor: (json['primary_dark_color'] as num?)?.toInt(),
      backgroundColor: (json['background_color'] as num?)?.toInt() ?? 0xFFFFF5F8,
      surfaceColor: (json['surface_color'] as num?)?.toInt(),
      textPrimaryColor: (json['text_primary_color'] as num?)?.toInt(),
      textSecondaryColor: (json['text_secondary_color'] as num?)?.toInt(),
      isDark: json['is_dark'] == true,
      isCustom: json['is_custom'] == true,
      category: ThemePresetCategoryExtension.fromString(json['category']?.toString()),
      author: json['author']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'primary_color': primaryColor,
      'primary_light_color': primaryLightColor,
      'primary_dark_color': primaryDarkColor,
      'background_color': backgroundColor,
      'surface_color': surfaceColor,
      'text_primary_color': textPrimaryColor,
      'text_secondary_color': textSecondaryColor,
      'is_dark': isDark,
      'is_custom': isCustom,
      'category': category.value,
      'author': author,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 创建一个自定义主题预设
  factory ThemePreset.createCustom({
    required String name,
    required int primaryColor,
    required int backgroundColor,
    int? primaryLightColor,
    int? primaryDarkColor,
    int? surfaceColor,
    int? textPrimaryColor,
    int? textSecondaryColor,
    bool isDark = false,
  }) {
    return ThemePreset(
      id: 'theme_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      primaryColor: primaryColor,
      primaryLightColor: primaryLightColor,
      primaryDarkColor: primaryDarkColor,
      backgroundColor: backgroundColor,
      surfaceColor: surfaceColor,
      textPrimaryColor: textPrimaryColor,
      textSecondaryColor: textSecondaryColor,
      isDark: isDark,
      isCustom: true,
      category: ThemePresetCategory.custom,
    );
  }

  /// 主色的 Color 对象
  Color get primary => Color(primaryColor);

  /// 主色浅色的 Color 对象
  Color get primaryLight => Color(primaryLightColor);

  /// 主色深色的 Color 对象
  Color get primaryDark => Color(primaryDarkColor);

  /// 背景色的 Color 对象
  Color get background => Color(backgroundColor);

  /// 表面色的 Color 对象
  Color get surface => Color(surfaceColor);

  /// 文字主色的 Color 对象
  Color get textPrimary => Color(textPrimaryColor);

  /// 文字次色的 Color 对象
  Color get textSecondary => Color(textSecondaryColor);

  /// 渐变色列表
  List<Color> get gradientColors => [primaryLight, primary, primaryDark];

  /// 复制一份主题预设
  ThemePreset copyWith({
    String? id,
    String? name,
    int? primaryColor,
    int? primaryLightColor,
    int? primaryDarkColor,
    int? backgroundColor,
    int? surfaceColor,
    int? textPrimaryColor,
    int? textSecondaryColor,
    bool? isDark,
    bool? isCustom,
    ThemePresetCategory? category,
    String? author,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ThemePreset(
      id: id ?? this.id,
      name: name ?? this.name,
      primaryColor: primaryColor ?? this.primaryColor,
      primaryLightColor: primaryLightColor ?? this.primaryLightColor,
      primaryDarkColor: primaryDarkColor ?? this.primaryDarkColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      textPrimaryColor: textPrimaryColor ?? this.textPrimaryColor,
      textSecondaryColor: textSecondaryColor ?? this.textSecondaryColor,
      isDark: isDark ?? this.isDark,
      isCustom: isCustom ?? this.isCustom,
      category: category ?? this.category,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
