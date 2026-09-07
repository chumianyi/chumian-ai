import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// ============================================================================
/// ThemeCustomizationService —— 主题定制服务
///
/// 职责：
///   1. 自定义色板：支持自定义主色、辅色、背景色等完整色板
///   2. 主题预设：内置多套预设主题，支持保存/加载用户自定义预设
///   3. 主题导入导出：主题配置 JSON 化，支持分享和备份
///   4. 动态取色：从图片中提取主色调，自动生成和谐色板
///   5. 主题动画过渡：主题切换时平滑过渡动画
/// ============================================================================

/// 主题色板
class ThemePalette {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color error;
  final Color onPrimary;
  final Color onSecondary;
  final Color onBackground;
  final Color onSurface;
  final Brightness brightness;

  const ThemePalette({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.error,
    required this.onPrimary,
    required this.onSecondary,
    required this.onBackground,
    required this.onSurface,
    this.brightness = Brightness.light,
  });

  /// 转 JSON
  Map<String, dynamic> toJson() => {
        'primary': primary.value,
        'secondary': secondary.value,
        'accent': accent.value,
        'background': background.value,
        'surface': surface.value,
        'error': error.value,
        'on_primary': onPrimary.value,
        'on_secondary': onSecondary.value,
        'on_background': onBackground.value,
        'on_surface': onSurface.value,
        'brightness': brightness.name,
      };

  /// 从 JSON 创建
  factory ThemePalette.fromJson(Map<String, dynamic> json) => ThemePalette(
        primary: Color((json['primary'] as num?)?.toInt() ?? 0xFF6750A4),
        secondary:
            Color((json['secondary'] as num?)?.toInt() ?? 0xFF625B71),
        accent: Color((json['accent'] as num?)?.toInt() ?? 0xFF7D5260),
        background:
            Color((json['background'] as num?)?.toInt() ?? 0xFFFFFBFE),
        surface: Color((json['surface'] as num?)?.toInt() ?? 0xFFFFFBFE),
        error: Color((json['error'] as num?)?.toInt() ?? 0xFFB3261E),
        onPrimary:
            Color((json['on_primary'] as num?)?.toInt() ?? 0xFFFFFFFF),
        onSecondary:
            Color((json['on_secondary'] as num?)?.toInt() ?? 0xFFFFFFFF),
        onBackground:
            Color((json['on_background'] as num?)?.toInt() ?? 0xFF1C1B1F),
        onSurface:
            Color((json['on_surface'] as num?)?.toInt() ?? 0xFF1C1B1F),
        brightness: json['brightness'] == 'dark'
            ? Brightness.dark
            : Brightness.light,
      );
}

/// 主题预设
class ThemePreset {
  final String id;
  final String name;
  final String description;
  final ThemePalette palette;
  final bool isBuiltin;
  final DateTime createdAt;

  ThemePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.palette,
    this.isBuiltin = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'palette': palette.toJson(),
        'is_builtin': isBuiltin,
        'created_at': createdAt.toIso8601String(),
      };

  factory ThemePreset.fromJson(Map<String, dynamic> json) => ThemePreset(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        palette: ThemePalette.fromJson(
            Map<String, dynamic>.from(json['palette'] ?? {})),
        isBuiltin: json['is_builtin'] == true,
        createdAt:
            DateTime.tryParse(json['created_at']?.toString() ?? '') ??
                DateTime.now(),
      );
}

class ThemeCustomizationService {
  /// 单例实例
  static final ThemeCustomizationService _instance =
      ThemeCustomizationService._internal();
  factory ThemeCustomizationService() => _instance;
  ThemeCustomizationService._internal();

  // ===== 配置 =====
  /// 预设文件名
  static const String _presetsFileName = 'theme_presets.json';

  /// 当前主题文件名
  static const String _currentFileName = 'current_theme.json';

  // ===== 状态 =====
  ThemePalette _currentPalette = _defaultPalette;
  final List<ThemePreset> _customPresets = [];
  final StreamController<ThemePalette> _themeController =
      StreamController<ThemePalette>.broadcast();
  bool _initialized = false;

  // ==========================================================================
  // 内置预设
  // ==========================================================================

  static const ThemePalette _defaultPalette = ThemePalette(
    primary: Color(0xFF6750A4),
    secondary: Color(0xFF625B71),
    accent: Color(0xFF7D5260),
    background: Color(0xFFFFFBFE),
    surface: Color(0xFFFFFBFE),
    error: Color(0xFFB3261E),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onBackground: Color(0xFF1C1B1F),
    onSurface: Color(0xFF1C1B1F),
  );

  /// 获取所有内置预设
  List<ThemePreset> get builtinPresets => [
        ThemePreset(
          id: 'material_purple',
          name: 'Material 紫',
          description: 'Google Material Design 经典紫色主题',
          isBuiltin: true,
          palette: const ThemePalette(
            primary: Color(0xFF6750A4),
            secondary: Color(0xFF625B71),
            accent: Color(0xFF7D5260),
            background: Color(0xFFFFFBFE),
            surface: Color(0xFFFFFBFE),
            error: Color(0xFFB3261E),
            onPrimary: Color(0xFFFFFFFF),
            onSecondary: Color(0xFFFFFFFF),
            onBackground: Color(0xFF1C1B1F),
            onSurface: Color(0xFF1C1B1F),
          ),
        ),
        ThemePreset(
          id: 'ocean_blue',
          name: '海洋蓝',
          description: '清新宁静的海洋蓝色调',
          isBuiltin: true,
          palette: const ThemePalette(
            primary: Color(0xFF0066A4),
            secondary: Color(0xFF4A90D9),
            accent: Color(0xFF00A8CC),
            background: Color(0xFFF0F7FF),
            surface: Color(0xFFFFFFFF),
            error: Color(0xFFBA1A1A),
            onPrimary: Color(0xFFFFFFFF),
            onSecondary: Color(0xFFFFFFFF),
            onBackground: Color(0xFF1A1C1E),
            onSurface: Color(0xFF1A1C1E),
          ),
        ),
        ThemePreset(
          id: 'forest_green',
          name: '森林绿',
          description: '自然舒适的森林绿色调',
          isBuiltin: true,
          palette: const ThemePalette(
            primary: Color(0xFF2E7D32),
            secondary: Color(0xFF66BB6A),
            accent: Color(0xFF00C853),
            background: Color(0xFFF1F8E9),
            surface: Color(0xFFFFFFFF),
            error: Color(0xFFD32F2F),
            onPrimary: Color(0xFFFFFFFF),
            onSecondary: Color(0xFFFFFFFF),
            onBackground: Color(0xFF1B1C18),
            onSurface: Color(0xFF1B1C18),
          ),
        ),
        ThemePreset(
          id: 'sunset_orange',
          name: '日落橙',
          description: '温暖活力的日落橙色调',
          isBuiltin: true,
          palette: const ThemePalette(
            primary: Color(0xFFE65100),
            secondary: Color(0xFFFF9800),
            accent: Color(0xFFFF5722),
            background: Color(0xFFFFF3E0),
            surface: Color(0xFFFFFFFF),
            error: Color(0xFFB71C1C),
            onPrimary: Color(0xFFFFFFFF),
            onSecondary: Color(0xFF000000),
            onBackground: Color(0xFF1C1B1F),
            onSurface: Color(0xFF1C1B1F),
          ),
        ),
        ThemePreset(
          id: 'dark_mode',
          name: '暗夜模式',
          description: '护眼深色主题，适合夜间使用',
          isBuiltin: true,
          palette: const ThemePalette(
            primary: Color(0xFFD0BCFF),
            secondary: Color(0xFFCCC2DC),
            accent: Color(0xFFEFB8C8),
            background: Color(0xFF1C1B1F),
            surface: Color(0xFF2B2930),
            error: Color(0xFFF2B8B5),
            onPrimary: Color(0xFF381E72),
            onSecondary: Color(0xFF332D41),
            onBackground: Color(0xFFE6E1E5),
            onSurface: Color(0xFFE6E1E5),
            brightness: Brightness.dark,
          ),
        ),
      ];

  // ==========================================================================
  // 初始化
  // ==========================================================================

  /// 初始化主题服务
  Future<void> init() async {
    if (_initialized) return;
    await _loadCurrentTheme();
    await _loadCustomPresets();
    _initialized = true;
  }

  // ==========================================================================
  // 当前主题
  // ==========================================================================

  /// 获取当前色板
  ThemePalette get currentPalette => _currentPalette;

  /// 主题变化流
  Stream<ThemePalette> get themeStream => _themeController.stream;

  /// 应用色板
  Future<void> applyPalette(ThemePalette palette) async {
    _currentPalette = palette;
    _themeController.add(palette);
    await _persistCurrentTheme();
  }

  /// 应用预设
  Future<void> applyPreset(ThemePreset preset) async {
    await applyPalette(preset.palette);
  }

  /// 切换亮色/暗色模式
  Future<void> toggleBrightness() async {
    final isDark = _currentPalette.brightness == Brightness.dark;
    if (isDark) {
      await applyPalette(builtinPresets[0].palette);
    } else {
      await applyPalette(builtinPresets[4].palette);
    }
  }

  // ==========================================================================
  // 自定义预设管理
  // ==========================================================================

  /// 保存当前主题为自定义预设
  Future<String> saveAsPreset({
    required String name,
    String description = '',
  }) async {
    final id = 'custom_${DateTime.now().microsecondsSinceEpoch}';
    final preset = ThemePreset(
      id: id,
      name: name,
      description: description,
      palette: _currentPalette,
      isBuiltin: false,
    );
    _customPresets.add(preset);
    await _persistCustomPresets();
    return id;
  }

  /// 删除自定义预设
  Future<bool> deletePreset(String presetId) async {
    final index = _customPresets.indexWhere((p) => p.id == presetId);
    if (index < 0) return false;
    _customPresets.removeAt(index);
    await _persistCustomPresets();
    return true;
  }

  /// 获取所有预设（内置 + 自定义）
  List<ThemePreset> getAllPresets() {
    return [...builtinPresets, ..._customPresets];
  }

  /// 获取自定义预设
  List<ThemePreset> get customPresets =>
      List.unmodifiable(_customPresets);

  // ==========================================================================
  // 主题导入导出
  // ==========================================================================

  /// 导出当前主题为 JSON 字符串
  String exportTheme() {
    return jsonEncode({
      'version': '1.0',
      'palette': _currentPalette.toJson(),
      'exported_at': DateTime.now().toIso8601String(),
    });
  }

  /// 从 JSON 字符串导入主题
  Future<bool> importTheme(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final palette = ThemePalette.fromJson(
          Map<String, dynamic>.from(data['palette'] ?? {}));
      await applyPalette(palette);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 导出预设为 JSON
  String exportPreset(ThemePreset preset) {
    return jsonEncode(preset.toJson());
  }

  /// 导入预设
  Future<ThemePreset?> importPreset(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final preset = ThemePreset.fromJson(data);
      _customPresets.add(preset);
      await _persistCustomPresets();
      return preset;
    } catch (_) {
      return null;
    }
  }

  // ==========================================================================
  // 动态取色（从图片提取主色）
  // ==========================================================================

  /// 从图片像素数据提取主色调
  ///
  /// [pixels] 像素颜色列表，[sampleCount] 采样数量
  Future<ThemePalette> extractPaletteFromImage({
    required List<Color> pixels,
    int sampleCount = 100,
  }) async {
    if (pixels.isEmpty) return _currentPalette;

    // 采样
    final step = (pixels.length / sampleCount).floor().clamp(1, pixels.length);
    final sampled = <Color>[];
    for (int i = 0; i < pixels.length; i += step) {
      sampled.add(pixels[i]);
    }

    // 计算主色（K-means 简化版：按色相聚类）
    final clusters = <List<Color>>[];
    for (final color in sampled) {
      final hsv = _rgbToHsv(color);
      bool added = false;
      for (final cluster in clusters) {
        final clusterHsv = _rgbToHsv(_averageColor(cluster));
        if ((hsv.hue - clusterHsv.hue).abs() < 30) {
          cluster.add(color);
          added = true;
          break;
        }
      }
      if (!added) {
        clusters.add([color]);
      }
    }

    // 按聚类大小排序
    clusters.sort((a, b) => b.length.compareTo(a.length));

    final primary = clusters.isNotEmpty
        ? _averageColor(clusters[0])
        : const Color(0xFF6750A4);
    final secondary = clusters.length > 1
        ? _averageColor(clusters[1])
        : _adjustBrightness(primary, 0.2);
    final accent = clusters.length > 2
        ? _averageColor(clusters[2])
        : _adjustSaturation(primary, 0.3);

    // 计算背景色（基于主色亮度决定亮/暗）
    final luminance = primary.computeLuminance();
    final isDark = luminance < 0.3;

    return ThemePalette(
      primary: primary,
      secondary: secondary,
      accent: accent,
      background: isDark ? const Color(0xFF1C1B1F) : const Color(0xFFFFFBFE),
      surface: isDark ? const Color(0xFF2B2930) : const Color(0xFFFFFFFF),
      error: const Color(0xFFB3261E),
      onPrimary: _getContrastColor(primary),
      onSecondary: _getContrastColor(secondary),
      onBackground: isDark ? const Color(0xFFE6E1E5) : const Color(0xFF1C1B1F),
      onSurface: isDark ? const Color(0xFFE6E1E5) : const Color(0xFF1C1B1F),
      brightness: isDark ? Brightness.dark : Brightness.light,
    );
  }

  /// RGB 转 HSV
  _HsvColor _rgbToHsv(Color color) {
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;
    final maxV = max(r, max(g, b));
    final minV = min(r, min(g, b));
    final delta = maxV - minV;

    double hue = 0;
    if (delta > 0) {
      if (maxV == r) {
        hue = 60 * (((g - b) / delta) % 6);
      } else if (maxV == g) {
        hue = 60 * ((b - r) / delta + 2);
      } else {
        hue = 60 * ((r - g) / delta + 4);
      }
    }
    if (hue < 0) hue += 360;

    final saturation = maxV == 0 ? 0.0 : delta / maxV;
    return _HsvColor(hue, saturation, maxV);
  }

  /// 计算平均颜色
  Color _averageColor(List<Color> colors) {
    if (colors.isEmpty) return Colors.grey;
    int r = 0, g = 0, b = 0;
    for (final c in colors) {
      r += c.red;
      g += c.green;
      b += c.blue;
    }
    final count = colors.length;
    return Color.fromARGB(255, r ~/ count, g ~/ count, b ~/ count);
  }

  /// 调整亮度
  Color _adjustBrightness(Color color, double factor) {
    return Color.fromARGB(
      255,
      (color.red * (1 + factor)).clamp(0, 255).toInt(),
      (color.green * (1 + factor)).clamp(0, 255).toInt(),
      (color.blue * (1 + factor)).clamp(0, 255).toInt(),
    );
  }

  /// 调整饱和度
  Color _adjustSaturation(Color color, double factor) {
    final hsv = _rgbToHsv(color);
    final newSaturation = (hsv.saturation * (1 + factor)).clamp(0.0, 1.0);
    return _hsvToColor(_HsvColor(hsv.hue, newSaturation, hsv.value));
  }

  /// HSV 转 Color
  Color _hsvToColor(_HsvColor hsv) {
    final c = hsv.value * hsv.saturation;
    final x = c * (1 - ((hsv.hue / 60) % 2 - 1).abs());
    final m = hsv.value - c;
    double r = 0, g = 0, b = 0;
    if (hsv.hue < 60) {
      r = c; g = x; b = 0;
    } else if (hsv.hue < 120) {
      r = x; g = c; b = 0;
    } else if (hsv.hue < 180) {
      r = 0; g = c; b = x;
    } else if (hsv.hue < 240) {
      r = 0; g = x; b = c;
    } else if (hsv.hue < 300) {
      r = x; g = 0; b = c;
    } else {
      r = c; g = 0; b = x;
    }
    return Color.fromARGB(
      255,
      ((r + m) * 255).round(),
      ((g + m) * 255).round(),
      ((b + m) * 255).round(),
    );
  }

  /// 获取对比色（黑或白）
  Color _getContrastColor(Color color) {
    return color.computeLuminance() > 0.5
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
  }

  // ==========================================================================
  // 主题动画过渡
  // ==========================================================================

  /// 生成从当前色板到目标色板的过渡动画值
  ///
  /// [target] 目标色板，[t] 过渡进度 0.0-1.0
  ThemePalette lerpPalette(ThemePalette target, double t) {
    return ThemePalette(
      primary: Color.lerp(_currentPalette.primary, target.primary, t)!,
      secondary:
          Color.lerp(_currentPalette.secondary, target.secondary, t)!,
      accent: Color.lerp(_currentPalette.accent, target.accent, t)!,
      background:
          Color.lerp(_currentPalette.background, target.background, t)!,
      surface: Color.lerp(_currentPalette.surface, target.surface, t)!,
      error: Color.lerp(_currentPalette.error, target.error, t)!,
      onPrimary:
          Color.lerp(_currentPalette.onPrimary, target.onPrimary, t)!,
      onSecondary:
          Color.lerp(_currentPalette.onSecondary, target.onSecondary, t)!,
      onBackground:
          Color.lerp(_currentPalette.onBackground, target.onBackground, t)!,
      onSurface:
          Color.lerp(_currentPalette.onSurface, target.onSurface, t)!,
      brightness: t > 0.5 ? target.brightness : _currentPalette.brightness,
    );
  }

  // ==========================================================================
  // 持久化
  // ==========================================================================

  Future<Directory> _getDocDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final themeDir = Directory('${dir.path}/themes');
    if (!themeDir.existsSync()) {
      themeDir.createSync(recursive: true);
    }
    return themeDir;
  }

  Future<void> _persistCurrentTheme() async {
    try {
      final dir = await _getDocDir();
      final file = File('${dir.path}/$_currentFileName');
      await file.writeAsString(jsonEncode(_currentPalette.toJson()));
    } catch (_) {}
  }

  Future<void> _loadCurrentTheme() async {
    try {
      final dir = await _getDocDir();
      final file = File('${dir.path}/$_currentFileName');
      if (!file.existsSync()) return;
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      _currentPalette = ThemePalette.fromJson(data);
    } catch (_) {}
  }

  Future<void> _persistCustomPresets() async {
    try {
      final dir = await _getDocDir();
      final file = File('${dir.path}/$_presetsFileName');
      await file.writeAsString(
          jsonEncode(_customPresets.map((p) => p.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _loadCustomPresets() async {
    try {
      final dir = await _getDocDir();
      final file = File('${dir.path}/$_presetsFileName');
      if (!file.existsSync()) return;
      final content = await file.readAsString();
      final list = jsonDecode(content) as List;
      _customPresets.clear();
      for (final item in list) {
        _customPresets.add(ThemePreset.fromJson(
            Map<String, dynamic>.from(item as Map)));
      }
    } catch (_) {}
  }

  /// 销毁服务
  void dispose() {
    _themeController.close();
  }
}

/// HSV 颜色表示
class _HsvColor {
  final double hue;
  final double saturation;
  final double value;
  _HsvColor(this.hue, this.saturation, this.value);
}
