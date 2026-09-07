import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================================
/// ThemeProvider —— 主题管理 Provider（ChangeNotifier）
///
/// 职责：
///   1. 管理粉色 Miuix 风格主题，支持亮色 / 暗色模式切换
///   2. 提供完整的 ThemeData 配置（colorScheme / appBar / card / button /
///      input / bottomNav / switch / slider / dialog / bottomSheet /
///      snackBar / tabBar 等）
///   3. 不设置任何 fontFamily，使用系统默认字体
///   4. 主题偏好持久化到 SharedPreferences
///   5. 支持主题色板切换（粉 / 紫 / 蓝 / 绿）
/// ============================================================================

/// 主题色板类型
enum ThemePalette { pink, purple, blue, green }

/// 色板扩展：提供各主题的主色/次色
extension ThemePaletteExtension on ThemePalette {
  String get label {
    switch (this) {
      case ThemePalette.pink:
        return '初眠粉';
      case ThemePalette.purple:
        return '梦幻紫';
      case ThemePalette.blue:
        return '天空蓝';
      case ThemePalette.green:
        return '清新绿';
    }
  }

  /// 主色
  Color get primary {
    switch (this) {
      case ThemePalette.pink:
        return MiuixColors.primary;
      case ThemePalette.purple:
        return const Color(0xFF9C6ADE);
      case ThemePalette.blue:
        return const Color(0xFF5B8DEF);
      case ThemePalette.green:
        return const Color(0xFF6BCB77);
    }
  }

  /// 主色浅色
  Color get primaryLight {
    switch (this) {
      case ThemePalette.pink:
        return MiuixColors.primaryLight;
      case ThemePalette.purple:
        return const Color(0xFFB89AE8);
      case ThemePalette.blue:
        return const Color(0xFF8BB0F5);
      case ThemePalette.green:
        return const Color(0xFF95DCA0);
    }
  }

  /// 主色深色
  Color get primaryDark {
    switch (this) {
      case ThemePalette.pink:
        return MiuixColors.primaryDark;
      case ThemePalette.purple:
        return const Color(0xFF7B4FB8);
      case ThemePalette.blue:
        return const Color(0xFF3D6BD0);
      case ThemePalette.green:
        return const Color(0xFF4CAF50);
    }
  }
}

class ThemeProvider extends ChangeNotifier {
  // ===== 持久化键 =====
  static const String _keyIsDark = 'theme_is_dark';
  static const String _keyPalette = 'theme_palette_index';

  // ===== 状态 =====
  bool _isDark = false;
  ThemePalette _palette = ThemePalette.pink;

  bool get isDark => _isDark;
  ThemePalette get palette => _palette;

  // ===== 便捷颜色获取 =====
  Color get primaryColor => _palette.primary;
  Color get primaryLight => _palette.primaryLight;
  Color get primaryDark => _palette.primaryDark;

  Color get backgroundColor =>
      _isDark ? MiuixColors.darkBackground : MiuixColors.background;
  Color get surfaceColor =>
      _isDark ? MiuixColors.darkSurface : MiuixColors.surface;
  Color get surfaceVariant =>
      _isDark ? MiuixColors.darkSurfaceVariant : MiuixColors.surfaceVariant;
  Color get textPrimary =>
      _isDark ? MiuixColors.darkTextPrimary : MiuixColors.textPrimary;
  Color get textSecondary =>
      _isDark ? MiuixColors.darkTextSecondary : MiuixColors.textSecondary;
  Color get textTertiary => MiuixColors.textTertiary;
  Color get borderColor =>
      _isDark ? MiuixColors.darkBorder : MiuixColors.border;
  Color get dividerColor =>
      _isDark ? MiuixColors.darkBorder : MiuixColors.divider;
  Color get errorColor => MiuixColors.error;
  Color get successColor => MiuixColors.success;
  Color get warningColor => MiuixColors.warning;

  // ==========================================================================
  // 持久化
  // ==========================================================================

  /// 从 SharedPreferences 加载主题偏好
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDark = prefs.getBool(_keyIsDark) ?? false;
      final paletteIndex = prefs.getInt(_keyPalette) ?? 0;
      if (paletteIndex >= 0 && paletteIndex < ThemePalette.values.length) {
        _palette = ThemePalette.values[paletteIndex];
      }
      notifyListeners();
    } catch (_) {}
  }

  /// 保存当前主题偏好
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsDark, _isDark);
      await prefs.setInt(_keyPalette, _palette.index);
    } catch (_) {}
  }

  // ==========================================================================
  // 主题切换
  // ==========================================================================

  /// 切换亮色/暗色模式
  Future<void> toggleDark() async {
    _isDark = !_isDark;
    await _save();
    notifyListeners();
  }

  /// 设置亮色/暗色模式
  Future<void> setDark(bool dark) async {
    if (_isDark == dark) return;
    _isDark = dark;
    await _save();
    notifyListeners();
  }

  /// 切换主题色板
  Future<void> setPalette(ThemePalette palette) async {
    if (_palette == palette) return;
    _palette = palette;
    await _save();
    notifyListeners();
  }

  // ==========================================================================
  // ThemeData 构建
  // ==========================================================================

  ThemeData get theme {
    final seed = _palette.primary;
    final brightness = _isDark ? Brightness.dark : Brightness.light;

    // M3 规范：从种子色派生完整 colorScheme
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _isDark
          ? MiuixColors.darkBackground
          : MiuixColors.background,
      // 页面过渡动画保留
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
