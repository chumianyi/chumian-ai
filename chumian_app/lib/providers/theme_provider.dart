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
    final primary = _palette.primary;
    final primaryLight = _palette.primaryLight;
    final primaryDark = _palette.primaryDark;

    final colorScheme = ColorScheme(
      brightness: _isDark ? Brightness.dark : Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryLight.withOpacity(_isDark ? 0.3 : 0.2),
      onPrimaryContainer: _isDark ? Colors.white : primaryDark,
      secondary: primaryLight,
      onSecondary: Colors.white,
      secondaryContainer: primaryLight.withOpacity(0.15),
      onSecondaryContainer: textPrimary,
      error: MiuixColors.error,
      onError: Colors.white,
      surface: surfaceColor,
      onSurface: textPrimary,
      surfaceVariant: surfaceVariant,
      onSurfaceVariant: textSecondary,
      outline: borderColor,
      outlineVariant: dividerColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,

      // ===== AppBar 主题（Miuix 风格：透明背景、无阴影、居中标题）=====
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: MiuixFontSize.xl,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textPrimary),
        actionsIconTheme: IconThemeData(color: textPrimary),
      ),

      // ===== Card 主题（圆角、柔和阴影、表面色）=====
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 0,
        shadowColor: MiuixColors.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: MiuixRadius.lgRadius,
          side: BorderSide(
            color: borderColor.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ===== 悬浮按钮（ElevatedButton）主题 =====
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: MiuixRadius.mdRadius,
          ),
          textStyle: const TextStyle(
            fontSize: MiuixFontSize.md,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(0, 48),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),

      // ===== 文本按钮（TextButton）主题 =====
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: MiuixRadius.smRadius,
          ),
          textStyle: const TextStyle(
            fontSize: MiuixFontSize.md,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ===== 输入框主题（扁平单框风格）=====
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: MiuixRadius.mdRadius,
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: MiuixRadius.mdRadius,
          borderSide: BorderSide(color: borderColor.withOpacity(0.6), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: MiuixRadius.mdRadius,
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: MiuixRadius.mdRadius,
          borderSide: BorderSide(color: MiuixColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: MiuixRadius.mdRadius,
          borderSide: BorderSide(color: MiuixColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: MiuixRadius.mdRadius,
          borderSide: BorderSide(color: dividerColor, width: 1),
        ),
        hintStyle: TextStyle(color: textTertiary, fontSize: MiuixFontSize.md),
        labelStyle: TextStyle(color: textSecondary, fontSize: MiuixFontSize.md),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),

      // ===== 底部导航栏主题 =====
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primary,
        unselectedItemColor: textTertiary,
        selectedLabelStyle: const TextStyle(
          fontSize: MiuixFontSize.xs,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: MiuixFontSize.xs,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),

      // ===== Switch 开关主题 =====
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return borderColor;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),

      // ===== Slider 滑块主题 =====
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: borderColor,
        thumbColor: primary,
        overlayColor: primary.withOpacity(0.15),
        valueIndicatorColor: primary,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: MiuixFontSize.sm,
        ),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),

      // ===== Dialog 对话框主题 =====
      dialogTheme: DialogTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: MiuixRadius.xlRadius,
        ),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: MiuixFontSize.xl,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: textSecondary,
          fontSize: MiuixFontSize.md,
        ),
      ),

      // ===== BottomSheet 底部弹出层主题 =====
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(MiuixRadius.xl)),
        ),
        clipBehavior: Clip.antiAlias,
        modalBackgroundColor: surfaceColor,
        modalElevation: 0,
        dragHandleColor: dividerColor,
        dragHandleSize: const Size(40, 4),
      ),

      // ===== SnackBar 主题 =====
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _isDark
            ? MiuixColors.darkSurfaceVariant
            : MiuixColors.textPrimary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: MiuixFontSize.md,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: MiuixRadius.mdRadius,
        ),
        actionTextColor: primaryLight,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // ===== TabBar 主题 =====
      tabBarTheme: TabBarTheme(
        labelColor: primary,
        unselectedLabelColor: textTertiary,
        labelStyle: const TextStyle(
          fontSize: MiuixFontSize.md,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: MiuixFontSize.md,
          fontWeight: FontWeight.w400,
        ),
        indicatorSize: TabBarIndicatorSize.label,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: primary, width: 2.5),
          ),
        ),
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(primary.withOpacity(0.08)),
      ),

      // ===== 分割线主题 =====
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 0.5,
        space: 1,
      ),

      // ===== 列表项主题 =====
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: MiuixFontSize.md,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(
          color: textSecondary,
          fontSize: MiuixFontSize.sm,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: MiuixRadius.mdRadius,
        ),
      ),

      // ===== 图标主题 =====
      iconTheme: IconThemeData(
        color: textSecondary,
        size: 24,
      ),

      // ===== 进度指示器主题 =====
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: borderColor,
        circularTrackColor: borderColor,
      ),

      // ===== 文本选择主题 =====
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primary.withOpacity(0.2),
        selectionHandleColor: primary,
      ),

      // ===== 页面过渡动画 =====
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
