import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeType { defaultTheme, green, pink, purple }

class ThemeProvider extends ChangeNotifier {
  AppThemeType _themeType = AppThemeType.defaultTheme;
  bool _isDark = false;
  AppThemeType get themeType => _themeType;
  bool get isDark => _isDark;

  static const Map<AppThemeType, Map<String, Color>> _themes = {
    AppThemeType.defaultTheme: {
      'primary': Color(0xFFE8B4D8),
      'secondary': Color(0xFFB8D8E8),
      'background': Color(0xFFFDF8FC),
      'surface': Color(0xFFFFFBFE),
      'accent': Color(0xFFD4A5C8),
    },
    AppThemeType.green: {
      'primary': Color(0xFF6BCB77),
      'secondary': Color(0xFFA8E6CF),
      'background': Color(0xFFF5FBF6),
      'surface': Color(0xFFFBFEFC),
      'accent': Color(0xFF4CAF50),
    },
    AppThemeType.pink: {
      'primary': Color(0xFFFF6B9D),
      'secondary': Color(0xFFFFB3C6),
      'background': Color(0xFFFFF5F8),
      'surface': Color(0xFFFFFAFC),
      'accent': Color(0xFFFF4081),
    },
    AppThemeType.purple: {
      'primary': Color(0xFF9C6ADE),
      'secondary': Color(0xFFD4B8F0),
      'background': Color(0xFFF9F5FD),
      'surface': Color(0xFFFDFBFF),
      'accent': Color(0xFF7C4DFF),
    },
  };

  Map<String, Color> get _colors => _themes[_themeType]!;
  Color get primaryColor => _colors['primary']!;
  Color get secondaryColor => _colors['secondary']!;
  Color get backgroundColor => _isDark ? const Color(0xFF1A1A24) : _colors['background']!;
  Color get surfaceColor => _isDark ? const Color(0xFF242430) : _colors['surface']!;
  Color get textPrimary => _isDark ? const Color(0xFFE8E8F0) : const Color(0xFF2D2D3A);
  Color get textSecondary => _isDark ? const Color(0xFF9E9EB0) : const Color(0xFF6E6E80);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeType = AppThemeType.values[prefs.getInt('theme_type') ?? 0];
    _isDark = prefs.getBool('is_dark') ?? false;
    notifyListeners();
  }

  Future<void> setTheme(AppThemeType type) async {
    _themeType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_type', type.index);
    notifyListeners();
  }

  Future<void> toggleDark() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark', _isDark);
    notifyListeners();
  }

  ThemeData get theme {
    final c = _colors;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: c['primary']!,
      brightness: _isDark ? Brightness.dark : Brightness.light,
      primary: c['primary']!,
      secondary: c['secondary']!,
      surface: surfaceColor,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c['primary']!,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: c['primary']!)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c['primary']!.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c['primary']!, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: c['primary']!,
        unselectedItemColor: textSecondary,
      ),
    );
  }
}

// Backward compatibility static colors (default theme)
class AppTheme {
  static const Color primaryColor = Color(0xFFE8B4D8);
  static const Color secondaryColor = Color(0xFFB8D8E8);
  static const Color backgroundColor = Color(0xFFFDF8FC);
  static const Color surfaceColor = Color(0xFFFFFBFE);
  static const Color textPrimary = Color(0xFF2D2D3A);
  static const Color textSecondary = Color(0xFF6E6E80);
  static const Color accentColor = Color(0xFFD4A5C8);
  static const Color darkBackground = Color(0xFF1A1A24);
  static const Color darkSurface = Color(0xFF242430);
  static const Color darkTextPrimary = Color(0xFFE8E8F0);
  static const Color darkTextSecondary = Color(0xFF9E9EB0);
}
