import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================
/// 设计规范常量：间距 / 圆角 / 时长 / 阴影 / 字号
/// ============================================================

class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double xxxxl = 40;
  static const double huge = 56;

  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: lg, vertical: md);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardInner = EdgeInsets.all(md);
  static const EdgeInsets listSection = EdgeInsets.only(top: xxl, bottom: md);
}

class AppRadius {
  AppRadius._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 28;
  static const double pill = 999;

  static const BorderRadius allXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius allSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius allMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius allLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius allXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius allXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius allPill = BorderRadius.all(Radius.circular(pill));
}

class AppDurations {
  AppDurations._();

  static const Duration fastest = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 600);
  static const Duration page = Duration(milliseconds: 300);
}

class AppEasings {
  AppEasings._();

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;
  static const Curve decelerate = Curves.decelerate;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
}

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> none = [];
  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> medium = [
    BoxShadow(color: Color(0x18000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> strong = [
    BoxShadow(color: Color(0x22000000), blurRadius: 28, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> float = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x12000000), blurRadius: 6, offset: Offset(0, 2)),
  ];
}

class AppTextStyles {
  AppTextStyles._();

  static const double hero = 34;
  static const double h1 = 28;
  static const double h2 = 24;
  static const double h3 = 20;
  static const double title = 17;
  static const double body = 15;
  static const double caption = 13;
  static const double overline = 11;

  static const FontWeight w4 = FontWeight.w400;
  static const FontWeight w5 = FontWeight.w500;
  static const FontWeight w6 = FontWeight.w600;
  static const FontWeight w7 = FontWeight.w700;
  static const FontWeight w8 = FontWeight.w800;
}

/// ============================================================
/// 枚举：主题色板
/// ============================================================

enum AppThemeType { defaultTheme, green, pink, purple, orange, red, cyan, yellow, darkBlue }

class ThemeColorSet {
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color background;
  final Color surface;
  final Color accent;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondaryContainer;
  final Color gradientStart;
  final Color gradientEnd;

  const ThemeColorSet({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.background,
    required this.surface,
    required this.accent,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondaryContainer,
    required this.gradientStart,
    required this.gradientEnd,
  });

  static const Map<AppThemeType, ThemeColorSet> all = {
    AppThemeType.defaultTheme: ThemeColorSet(
      primary: Color(0xFFE8B4D8),
      secondary: Color(0xFFB8D8E8),
      tertiary: Color(0xFFD4B8F0),
      background: Color(0xFFFDF8FC),
      surface: Color(0xFFFFFBFE),
      accent: Color(0xFFD4A5C8),
      primaryContainer: Color(0xFFF8E4F0),
      onPrimaryContainer: Color(0xFF5A2340),
      secondaryContainer: Color(0xFFE1F0F7),
      gradientStart: Color(0xFFF4C4DE),
      gradientEnd: Color(0xFFB8D8E8),
    ),
    AppThemeType.green: ThemeColorSet(
      primary: Color(0xFF6BCB77),
      secondary: Color(0xFFA8E6CF),
      tertiary: Color(0xFFB6E0A8),
      background: Color(0xFFF5FBF6),
      surface: Color(0xFFFBFEFC),
      accent: Color(0xFF4CAF50),
      primaryContainer: Color(0xFFDFF3E2),
      onPrimaryContainer: Color(0xFF1F4A28),
      secondaryContainer: Color(0xFFDDF2EA),
      gradientStart: Color(0xFF8ADB94),
      gradientEnd: Color(0xFFA8E6CF),
    ),
    AppThemeType.pink: ThemeColorSet(
      primary: Color(0xFFFF6B9D),
      secondary: Color(0xFFFFB3C6),
      tertiary: Color(0xFFF48FB1),
      background: Color(0xFFFFF5F8),
      surface: Color(0xFFFFFAFC),
      accent: Color(0xFFFF4081),
      primaryContainer: Color(0xFFFFDCE6),
      onPrimaryContainer: Color(0xFF6E1232),
      secondaryContainer: Color(0xFFFFE8EE),
      gradientStart: Color(0xFFFF8FB1),
      gradientEnd: Color(0xFFFFB3C6),
    ),
    AppThemeType.purple: ThemeColorSet(
      primary: Color(0xFF9C6ADE),
      secondary: Color(0xFFD4B8F0),
      tertiary: Color(0xFFB39DDB),
      background: Color(0xFFF9F5FD),
      surface: Color(0xFFFDFBFF),
      accent: Color(0xFF7C4DFF),
      primaryContainer: Color(0xFFEBDCF8),
      onPrimaryContainer: Color(0xFF3A1A5E),
      secondaryContainer: Color(0xFFEDE3F8),
      gradientStart: Color(0xFFB48AF0),
      gradientEnd: Color(0xFFD4B8F0),
    ),
    AppThemeType.orange: ThemeColorSet(
      primary: Color(0xFFFF9F43),
      secondary: Color(0xFFFFD180),
      tertiary: Color(0xFFFFB74D),
      background: Color(0xFFFFF8F0),
      surface: Color(0xFFFFFCF7),
      accent: Color(0xFFFF6D00),
      primaryContainer: Color(0xFFFFE8CC),
      onPrimaryContainer: Color(0xFF663300),
      secondaryContainer: Color(0xFFFFF0D6),
      gradientStart: Color(0xFFFFB74D),
      gradientEnd: Color(0xFFFFD180),
    ),
    AppThemeType.red: ThemeColorSet(
      primary: Color(0xFFEF5350),
      secondary: Color(0xFFEF9A9A),
      tertiary: Color(0xFFE57373),
      background: Color(0xFFFFF5F5),
      surface: Color(0xFFFFFAFA),
      accent: Color(0xFFD32F2F),
      primaryContainer: Color(0xFFFFCDD2),
      onPrimaryContainer: Color(0xFFB71C1C),
      secondaryContainer: Color(0xFFFFEBEE),
      gradientStart: Color(0xFFEF5350),
      gradientEnd: Color(0xFFEF9A9A),
    ),
    AppThemeType.cyan: ThemeColorSet(
      primary: Color(0xFF26C6DA),
      secondary: Color(0xFF80DEEA),
      tertiary: Color(0xFF4DD0E1),
      background: Color(0xFFF0FCFE),
      surface: Color(0xFFF8FEFF),
      accent: Color(0xFF00ACC1),
      primaryContainer: Color(0xFFB2EBF2),
      onPrimaryContainer: Color(0xFF006064),
      secondaryContainer: Color(0xFFE0F7FA),
      gradientStart: Color(0xFF4DD0E1),
      gradientEnd: Color(0xFF80DEEA),
    ),
    AppThemeType.yellow: ThemeColorSet(
      primary: Color(0xFFFFCA28),
      secondary: Color(0xFFFFE082),
      tertiary: Color(0xFFFFD54F),
      background: Color(0xFFFFFDF0),
      surface: Color(0xFFFFFEF7),
      accent: Color(0xFFFFA000),
      primaryContainer: Color(0xFFFFECB3),
      onPrimaryContainer: Color(0xFFE65100),
      secondaryContainer: Color(0xFFFFF8E1),
      gradientStart: Color(0xFFFFD54F),
      gradientEnd: Color(0xFFFFE082),
    ),
    AppThemeType.darkBlue: ThemeColorSet(
      primary: Color(0xFF3F51B5),
      secondary: Color(0xFF7986CB),
      tertiary: Color(0xFF5C6BC0),
      background: Color(0xFFF3F4FB),
      surface: Color(0xFFF8F9FD),
      accent: Color(0xFF303F9F),
      primaryContainer: Color(0xFFC5CAE9),
      onPrimaryContainer: Color(0xFF1A237E),
      secondaryContainer: Color(0xFFDDE0F5),
      gradientStart: Color(0xFF5C6BC0),
      gradientEnd: Color(0xFF7986CB),
    ),
  };
}

/// ============================================================
/// ThemeProvider：可响应切换的主题源
/// ============================================================

class ThemeProvider extends ChangeNotifier {
  AppThemeType _themeType = AppThemeType.pink;
  bool _isDark = true;

  AppThemeType get themeType => _themeType;
  bool get isDark => _isDark;

  ThemeColorSet get _set => ThemeColorSet.all[_themeType]!;

  // ---- 语义色（随主题 / 深色模式变化） ----
  Color get primaryColor => _set.primary;
  Color get secondaryColor => _set.secondary;
  Color get tertiaryColor => _set.tertiary;
  Color get accentColor => _set.accent;
  Color get primaryContainer => _set.primaryContainer;
  Color get onPrimaryContainer => _set.onPrimaryContainer;
  Color get secondaryContainer => _set.secondaryContainer;
  Color get gradientStart => _set.gradientStart;
  Color get gradientEnd => _set.gradientEnd;

  Color get backgroundColor =>
      _isDark ? const Color(0xFF0D0D0D) : _set.background;
  Color get surfaceColor => _isDark ? const Color(0xFF1A1A22) : _set.surface;
  Color get surfaceElevated =>
      _isDark ? const Color(0xFF24242E) : const Color(0xFFFFFFFF);
  Color get surfaceSubtle =>
      _isDark ? const Color(0xFF15151C) : const Color(0xFFF7F2F8);

  Color get textPrimary => _isDark ? const Color(0xFFECECF4) : const Color(0xFF2A2A38);
  Color get textSecondary => _isDark ? const Color(0xFFA2A2B4) : const Color(0xFF6C6C80);
  Color get textTertiary => _isDark ? const Color(0xFF70707E) : const Color(0xFFA0A0B0);
  Color get textOnPrimary => _isDark ? const Color(0xFF0D0D0D) : const Color(0xFFFFFFFF);

  Color get dividerColor => _isDark ? const Color(0xFF2A2A35) : const Color(0xFFEDE6EF);
  Color get shadowColor => _isDark ? Colors.black : const Color(0xFF2A2A38);

  // ---- 状态色（随深色微调） ----
  Color get successColor => _isDark ? const Color(0xFF4DD98A) : const Color(0xFF22B573);
  Color get warningColor => _isDark ? const Color(0xFFFFC24D) : const Color(0xFFF5A623);
  Color get dangerColor => _isDark ? const Color(0xFFFF6B7A) : const Color(0xFFE8445C);
  Color get infoColor => _isDark ? const Color(0xFF6FA8FF) : const Color(0xFF3D7BF0);

  // ---- 渐变 ----
  LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [gradientStart, gradientEnd],
      );

  LinearGradient get primaryVibrantGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryColor, accentColor],
      );

  LinearGradient get successGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF34C77B), Color(0xFF4DD98A)],
      );

  LinearGradient get warningGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFB020), Color(0xFFFFC24D)],
      );

  // ---- 偏好持久化 ----
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeType = AppThemeType.values[prefs.getInt('theme_type') ?? 2];
    _isDark = prefs.getBool('is_dark') ?? true;
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
// ---- 完整 Material3 ThemeData ----
  ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: _isDark ? Brightness.dark : Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
      surface: surfaceColor,
      error: dangerColor,
    );

    final base = ThemeData(
      useMaterial3: false,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      splashFactory: InkRipple.splashFactory,
    );

    return base.copyWith(
      textTheme: _buildTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: _isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: _isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      cardTheme: CardTheme(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allLg),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textOnPrimary,
          elevation: 0,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textOnPrimary,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor.withOpacity(0.4)),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        hintStyle: TextStyle(color: textTertiary, fontSize: 15),
        labelStyle: TextStyle(color: textSecondary, fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: AppRadius.allXxl,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.allXxl,
          borderSide: BorderSide(color: primaryColor.withOpacity(0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.allXxl,
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.allXxl,
          borderSide: const BorderSide(color: Color(0xFFE8445C)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.allXxl,
          borderSide: const BorderSide(color: Color(0xFFE8445C), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: DividerThemeData(color: dividerColor, thickness: 0.5),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surfaceSubtle,
        selectedColor: primaryContainer,
        labelStyle: TextStyle(color: textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allPill),
        side: BorderSide.none,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        backgroundColor: _isDark ? const Color(0xFF30303E) : const Color(0xFF2A2A38),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allXl),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allMd),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondary,
        indicatorColor: primaryColor,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: primaryContainer,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allLg),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: _isDark ? const Color(0xFF3A3A48) : const Color(0xFF2A2A38),
          borderRadius: AppRadius.allSm,
        ),
      ),
    );
  }

  TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: AppTextStyles.hero, fontWeight: AppTextStyles.w8, color: textPrimary,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: AppTextStyles.h1, fontWeight: AppTextStyles.w7, color: textPrimary,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: AppTextStyles.h2, fontWeight: AppTextStyles.w7, color: textPrimary,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: AppTextStyles.h3, fontWeight: AppTextStyles.w6, color: textPrimary,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: AppTextStyles.title, fontWeight: AppTextStyles.w6, color: textPrimary,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: AppTextStyles.body, fontWeight: AppTextStyles.w6, color: textPrimary,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: AppTextStyles.body, fontWeight: AppTextStyles.w4, color: textPrimary,
        height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: AppTextStyles.body, fontWeight: AppTextStyles.w4, color: textSecondary,
        height: 1.45,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: AppTextStyles.caption, fontWeight: AppTextStyles.w4, color: textSecondary,
        height: 1.4,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: AppTextStyles.body, fontWeight: AppTextStyles.w5, color: textPrimary,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: AppTextStyles.caption, fontWeight: AppTextStyles.w5, color: textSecondary,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: AppTextStyles.overline, fontWeight: AppTextStyles.w5, color: textTertiary,
        letterSpacing: 0.4,
      ),
    );
  }
}

/// ============================================================
/// AppTheme：向后兼容的静态色（默认主题 + 语义色 + 规范）
/// ============================================================

class AppTheme {
  AppTheme._();

  // 主色（默认主题）
  static const Color primaryColor = Color(0xFFE8B4D8);
  static const Color secondaryColor = Color(0xFFB8D8E8);
  static const Color tertiaryColor = Color(0xFFD4B8F0);
  static const Color backgroundColor = Color(0xFFFDF8FC);
  static const Color surfaceColor = Color(0xFFFFFBFE);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF7F2F8);
  static const Color textPrimary = Color(0xFF2D2D3A);
  static const Color textSecondary = Color(0xFF6E6E80);
  static const Color textTertiary = Color(0xFFA0A0B0);
  static const Color accentColor = Color(0xFFD4A5C8);
  static const Color primaryContainer = Color(0xFFF8E4F0);
  static const Color onPrimaryContainer = Color(0xFF5A2340);
  static const Color secondaryContainer = Color(0xFFE1F0F7);

  static const Color successColor = Color(0xFF22B573);
  static const Color warningColor = Color(0xFFF5A623);
  static const Color dangerColor = Color(0xFFE8445C);
  static const Color infoColor = Color(0xFF3D7BF0);

  static const Color gradientStart = Color(0xFFF4C4DE);
  static const Color gradientEnd = Color(0xFFB8D8E8);
  static const Color darkBackground = Color(0xFF14141E);
  static const Color darkSurface = Color(0xFF1E1E2A);
  static const Color darkSurfaceElevated = Color(0xFF262633);
  static const Color darkTextPrimary = Color(0xFFECECF4);
  static const Color darkTextSecondary = Color(0xFFA2A2B4);
  static const Color darkTextTertiary = Color(0xFF70707E);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  static const LinearGradient vibrantGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, accentColor],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34C77B), Color(0xFF4DD98A)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB020), Color(0xFFFFC24D)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF0455C), Color(0xFFFF6B7A)],
  );

  static const List<Color> chartPalette = [
    primaryColor,
    secondaryColor,
    tertiaryColor,
    accentColor,
    Color(0xFF8FD3F4),
    Color(0xFFB9E6C9),
    Color(0xFFF5D98E),
    Color(0xFFC9A8F0),
  ];

  static Color alpha(Color color, double opacity) =>
      color.withValues(alpha: opacity);

  static Color onColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? const Color(0xFF2A2A38) : Colors.white;
  }
}
