import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';
import 'app_radius.dart';
import 'app_shadows.dart';

/// 初眠AI 全局主题 - 粉色系 + 霞鹜文楷
class AppTheme extends ChangeNotifier {
  static final AppTheme instance = AppTheme._();
  AppTheme._();

  bool _isDark = false;
  bool get isDark => _isDark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('app_theme_dark') ?? false;
    notifyListeners();
  }

  Future<void> toggleDark() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_theme_dark', _isDark);
    notifyListeners();
  }

  Future<void> setDark(bool dark) async {
    _isDark = dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_theme_dark', _isDark);
    notifyListeners();
  }

  ThemeData get theme => _isDark ? _darkTheme : _lightTheme;

  ThemeData get _lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkRipple.splashFactory,
      splashColor: AppColors.primary.withValues(alpha: 0.1),
      highlightColor: AppColors.primary.withValues(alpha: 0.05),
      hoverColor: AppColors.primary.withValues(alpha: 0.04),
      focusColor: AppColors.primary.withValues(alpha: 0.12),
      disabledColor: AppColors.textTertiary,
      dividerColor: AppColors.divider,
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      textTheme: _buildTextTheme(Brightness.light),
      primaryTextTheme: _buildTextTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h2.copyWith(fontSize: 22),
        toolbarTextStyle: AppTextStyles.body,
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
        actionsIconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allLg),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          minimumSize: const Size(64, 48),
          padding: AppSpacing.buttonPadding,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          textStyle: AppTextStyles.button,
          shadowColor: AppColors.primary,
          splashFactory: InkRipple.splashFactory,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: const Size(64, 48),
          padding: AppSpacing.buttonPadding,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          textStyle: AppTextStyles.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(64, 48),
          padding: AppSpacing.buttonPadding,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.allMd),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 40),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.allSm),
          textStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: Colors.transparent,
          hoverColor: AppColors.primary.withValues(alpha: 0.06),
          highlightColor: AppColors.primary.withValues(alpha: 0.1),
          minimumSize: const Size(40, 40),
          padding: AppSpacing.iconButtonPadding,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        helperStyle: AppTextStyles.caption,
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
        prefixIconColor: AppColors.textTertiary,
        suffixIconColor: AppColors.textTertiary,
        contentPadding: AppSpacing.inputPadding,
        border: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: const BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.textOnPrimary),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allXs),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.border;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.textOnPrimary;
          return AppColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.divider;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.borderLight,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: 0.1),
        valueIndicatorColor: AppColors.primary,
        valueIndicatorTextStyle: AppTextStyles.caption.copyWith(color: AppColors.textOnPrimary),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.bodyMedium,
        unselectedLabelStyle: AppTextStyles.body,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        dividerColor: AppColors.divider,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        selectedLabelStyle: AppTextStyles.caption,
        unselectedLabelStyle: AppTextStyles.caption,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600);
          }
          return AppTextStyles.caption.copyWith(color: AppColors.textTertiary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return const IconThemeData(color: AppColors.textTertiary);
        }),
        height: 64,
        elevation: 8,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        selectedLabelTextStyle: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
        selectedIconTheme: const IconThemeData(color: AppColors.primary),
        unselectedIconTheme: const IconThemeData(color: AppColors.textTertiary),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(AppRadius.xl)),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allXl),
        titleTextStyle: AppTextStyles.h3,
        contentTextStyle: AppTextStyles.body,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.body.copyWith(color: AppColors.textOnPrimary),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: AppRadius.allSm,
        ),
        textStyle: AppTextStyles.caption.copyWith(color: AppColors.textOnPrimary),
        padding: AppSpacing.tooltipPadding,
        showDuration: const Duration(seconds: 2),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        textColor: AppColors.textPrimary,
        collapsedTextColor: AppColors.textPrimary,
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        tilePadding: AppSpacing.expansionTilePadding,
        childrenPadding: AppSpacing.expansionTileChildrenPadding,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: AppSpacing.listTileContentPadding,
        dense: false,
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        tileColor: Colors.transparent,
        selectedTileColor: AppColors.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        horizontalTitleGap: 12,
        minVerticalPadding: 8,
        minLeadingWidth: 24,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        disabledColor: AppColors.divider,
        labelStyle: AppTextStyles.bodySmall,
        secondaryLabelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
        brightness: Brightness.light,
        padding: AppSpacing.chipPadding,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allPill),
        side: BorderSide.none,
        showCheckmark: true,
        checkmarkColor: AppColors.primary,
        elevation: 0,
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: AppColors.error,
        textColor: AppColors.textOnPrimary,
        textStyle: AppTextStyles.overline.copyWith(color: AppColors.textOnPrimary),
        padding: AppSpacing.badgePadding,
        alignment: Alignment.topRight,
        smallSize: 8,
        largeSize: 18,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.borderLight,
        circularTrackColor: AppColors.borderLight,
        refreshBackgroundColor: AppColors.surface,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primary;
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.textOnPrimary;
            return AppColors.textSecondary;
          }),
          textStyle: WidgetStateProperty.all(AppTextStyles.bodySmall),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: AppRadius.allMd)),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: AppColors.textOnPrimary,
        todayBackgroundColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.1)),
        todayForegroundColor: WidgetStateProperty.all(AppColors.primary),
        yearBackgroundColor: WidgetStateProperty.all(Colors.transparent),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.textOnPrimary;
          return AppColors.textPrimary;
        }),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allXl),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.surface,
        hourMinuteColor: AppColors.primary.withValues(alpha: 0.1),
        hourMinuteTextColor: AppColors.primary,
        dialHandColor: AppColors.primary,
        dialBackgroundColor: AppColors.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allXl),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        textStyle: AppTextStyles.body,
        enableFeedback: true,
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.surface),
          elevation: WidgetStateProperty.all(8),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: AppRadius.allMd)),
        ),
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.textPrimary),
          textStyle: WidgetStateProperty.all(AppTextStyles.body),
        ),
      ),
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: AppColors.primaryContainer,
        contentTextStyle: AppTextStyles.body,
        padding: AppSpacing.bannerPadding,
        leadingPadding: const EdgeInsets.only(right: 12),
      ),
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (context) => const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        closeButtonIconBuilder: (context) => const Icon(Icons.close_rounded, size: 20),
        drawerButtonIconBuilder: (context) => const Icon(Icons.menu_rounded, size: 24),
        endDrawerButtonIconBuilder: (context) => const Icon(Icons.menu_open_rounded, size: 24),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(AppColors.surface),
        elevation: WidgetStateProperty.all(0),
        hintStyle: WidgetStateProperty.all(AppTextStyles.body.copyWith(color: AppColors.textHint)),
        textStyle: WidgetStateProperty.all(AppTextStyles.body),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: AppRadius.allPill)),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 4)),
      ),
      searchViewTheme: SearchViewThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allXl),
      ),
      dataTableTheme: DataTableThemeData(
        dataRowColor: WidgetStateProperty.all(Colors.transparent),
        headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
        dataTextStyle: AppTextStyles.bodySmall,
        headingTextStyle: AppTextStyles.bodyMedium,
        columnSpacing: 24,
        horizontalMargin: 16,
        dividerThickness: 1,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      platform: TargetPlatform.android,
    );
  }

  ThemeData get _darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      secondary: AppColors.secondary,
      tertiary: AppColors.accentLight,
      surface: AppColors.darkSurface,
      error: AppColors.errorLight,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      splashFactory: InkRipple.splashFactory,
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        titleTextStyle: AppTextStyles.darkTitle.copyWith(fontSize: 22),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allLg),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        hintStyle: AppTextStyles.darkBody.copyWith(color: AppColors.textTertiary),
        contentPadding: AppSpacing.inputPadding,
        border: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: const BorderSide(color: AppColors.darkDivider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
        ),
      ),
      dividerColor: AppColors.darkDivider,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allXl),
      ),
    );
  }

  TextTheme _buildTextTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    return TextTheme(
      displayLarge: AppTextStyles.hero.copyWith(color: primary, fontSize: 48),
      displayMedium: AppTextStyles.hero.copyWith(color: primary, fontSize: 40),
      displaySmall: AppTextStyles.h1.copyWith(color: primary),
      headlineLarge: AppTextStyles.h1.copyWith(color: primary),
      headlineMedium: AppTextStyles.h2.copyWith(color: primary),
      headlineSmall: AppTextStyles.h3.copyWith(color: primary),
      titleLarge: AppTextStyles.title.copyWith(color: primary),
      titleMedium: AppTextStyles.subtitle.copyWith(color: primary),
      titleSmall: AppTextStyles.bodyMedium.copyWith(color: primary),
      bodyLarge: AppTextStyles.body.copyWith(color: primary),
      bodyMedium: AppTextStyles.body.copyWith(color: primary),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: secondary),
      labelLarge: AppTextStyles.button.copyWith(color: primary),
      labelMedium: AppTextStyles.caption.copyWith(color: secondary),
      labelSmall: AppTextStyles.overline.copyWith(color: secondary),
    );
  }
}
