import 'package:flutter/material.dart';

/// 初眠AI 粉色主题色板 - 全局统一粉色系
class AppColors {
  AppColors._();

  // ---- 主色 ----
  static const Color primary = Color(0xFFFF6B9D);
  static const Color primaryLight = Color(0xFFFF85AB);
  static const Color primaryDark = Color(0xFFE8558A);
  static const Color primaryDeep = Color(0xFFD4487A);

  // ---- 次色 ----
  static const Color secondary = Color(0xFFFFB3C6);
  static const Color secondaryLight = Color(0xFFFFC9D6);
  static const Color secondaryDark = Color(0xFFFF9DB8);

  // ---- 强调色 ----
  static const Color accent = Color(0xFFFF4081);
  static const Color accentLight = Color(0xFFFF6B9D);
  static const Color accentDark = Color(0xFFC2185B);

  // ---- 背景 ----
  static const Color background = Color(0xFFFFF0F5);
  static const Color backgroundLight = Color(0xFFFFF5F8);
  static const Color backgroundDark = Color(0xFFFFE4EE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfacePink = Color(0xFFFFF8FA);
  static const Color surfaceVariant = Color(0xFFFFEEF3);

  // ---- 文字 ----
  static const Color textPrimary = Color(0xFF2D1B2E);
  static const Color textSecondary = Color(0xFF6B4D5E);
  static const Color textTertiary = Color(0xFF9C7A8E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textHint = Color(0xFFB89AAA);

  // ---- 边框 / 分割线 ----
  static const Color divider = Color(0xFFFFD6E4);
  static const Color border = Color(0xFFFFC4D8);
  static const Color borderLight = Color(0xFFFFE0EA);

  // ---- 状态色 ----
  static const Color success = Color(0xFF4CAF7D);
  static const Color successLight = Color(0xFF81C7A3);
  static const Color warning = Color(0xFFFFA726);
  static const Color warningLight = Color(0xFFFFCC80);
  static const Color error = Color(0xFFE53965);
  static const Color errorLight = Color(0xFFEF6A8C);
  static const Color info = Color(0xFF5C8AE6);
  static const Color infoLight = Color(0xFF8FB0F0);

  // ---- 渐变 ----
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF85AB), Color(0xFFFF6B9D)],
  );
  static const LinearGradient primaryVibrantGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B9D), Color(0xFFFF4081)],
  );
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF5F8), Color(0xFFFFF0F5)],
  );
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFFF8FA)],
  );
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF66BB94), Color(0xFF4CAF7D)],
  );
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB74D), Color(0xFFFFA726)],
  );
  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF6A8C), Color(0xFFE53965)],
  );
  static const RadialGradient glowGradient = RadialGradient(
    colors: [Color(0x66FF6B9D), Color(0x00FF6B9D)],
  );

  // ---- 深色模式粉色系 ----
  static const Color darkBackground = Color(0xFF1A0F17);
  static const Color darkSurface = Color(0xFF241620);
  static const Color darkSurfaceVariant = Color(0xFF2E1D28);
  static const Color darkTextPrimary = Color(0xFFFFF0F5);
  static const Color darkTextSecondary = Color(0xFFC9A8B8);
  static const Color darkDivider = Color(0xFF3D2835);

  // ---- 阴影色 ----
  static const Color shadowPink = Color(0x33FF6B9D);
  static const Color shadowSoft = Color(0x1A000000);
  static const Color shadowMedium = Color(0x24000000);
  static const Color shadowStrong = Color(0x33000000);
}
