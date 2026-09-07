import 'package:flutter/material.dart';

/// 初眠AI Miuix 风格核心色板 —— 整体粉色系
/// 对标小米 HyperOS Miuix 设计语言：连续曲率、细腻高光、柔和阴影
class MiuixColors {
  // ===== 主粉色系 =====
  static const Color primary = Color(0xFFFF6B9D);
  static const Color primaryLight = Color(0xFFFF8FB5);
  static const Color primaryDark = Color(0xFFE8558A);
  static const Color primaryDeep = Color(0xFFD4417A);

  // ===== 浅粉背景系 =====
  static const Color background = Color(0xFFFFF5F8);
  static const Color surface = Color(0xFFFFFAFC);
  static const Color surfaceVariant = Color(0xFFFFF0F5);
  static const Color surfaceHover = Color(0xFFFFE8F0);

  // ===== 粉色渐变 =====
  static const List<Color> primaryGradient = [
    Color(0xFFFF8FB5),
    Color(0xFFFF6B9D),
    Color(0xFFFF5588),
  ];
  static const List<Color> softGradient = [
    Color(0xFFFFD6E4),
    Color(0xFFFFC0D6),
  ];
  static const List<Color> backgroundGradient = [
    Color(0xFFFFF5F8),
    Color(0xFFFFEEF3),
  ];

  // ===== 文字层级 =====
  static const Color textPrimary = Color(0xFF2D2D3A);
  static const Color textSecondary = Color(0xFF6E6E80);
  static const Color textTertiary = Color(0xFF9E9EB0);
  static const Color textOnPrimary = Colors.white;
  static const Color textLink = Color(0xFFFF4081);

  // ===== 边框 / 分割线 =====
  static const Color border = Color(0xFFFFD6E4);
  static const Color borderLight = Color(0xFFFFE4EC);
  static const Color divider = Color(0xFFFFE8F0);

  // ===== 功能色 =====
  static const Color success = Color(0xFF52C41A);
  static const Color warning = Color(0xFFFAAD14);
  static const Color error = Color(0xFFFF4D4F);
  static const Color info = Color(0xFF1890FF);

  // ===== 阴影 =====
  static const Color shadowColor = Color(0x1AFF6B9D);
  static const Color shadowSoft = Color(0x0DFF6B9D);

  // ===== 暗色模式粉色系 =====
  static const Color darkBackground = Color(0xFF1A1220);
  static const Color darkSurface = Color(0xFF241A2E);
  static const Color darkSurfaceVariant = Color(0xFF2E2238);
  static const Color darkTextPrimary = Color(0xFFF0E8F0);
  static const Color darkTextSecondary = Color(0xFFB0A0B8);
  static const Color darkBorder = Color(0xFF3D2E48);

  // ===== Miuix 专属：高光 / 玻璃 =====
  static const Color glassOverlay = Color(0x33FFFFFF);
  static const Color glassBorder = Color(0x40FFFFFF);
  static const Color highlight = Color(0x40FFFFFF);
}

/// Miuix 圆角曲率体系 —— 连续曲率(squircle 风格)
class MiuixRadius {
  static const double xs = 6.0;
  static const double sm = 10.0;
  static const double md = 14.0;
  static const double lg = 20.0;
  static const double xl = 28.0;
  static const double xxl = 36.0;
  static const double pill = 999.0;

  static BorderRadius get xsRadius => BorderRadius.circular(xs);
  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get xlRadius => BorderRadius.circular(xl);
  static BorderRadius get pillRadius => BorderRadius.circular(pill);
}

/// Miuix 阴影体系
class MiuixShadows {
  static List<BoxShadow> get xs => [
        BoxShadow(
          color: MiuixColors.shadowSoft,
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];
  static List<BoxShadow> get sm => [
        BoxShadow(
          color: MiuixColors.shadowSoft,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
  static List<BoxShadow> get md => [
        BoxShadow(
          color: MiuixColors.shadowColor,
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
  static List<BoxShadow> get lg => [
        BoxShadow(
          color: MiuixColors.shadowColor,
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
  static List<BoxShadow> get xl => [
        BoxShadow(
          color: const Color(0x33FF6B9D),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];
}

/// Miuix 动画时长体系
class MiuixDuration {
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration elastic = Duration(milliseconds: 500);
  static const Duration page = Duration(milliseconds: 350);
}

/// Miuix 动画曲线体系 —— 弹簧式按压回弹
class MiuixCurves {
  static const Curve spring = Curves.elasticOut;
  static const Curve bounce = Curves.bounceOut;
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeIn = Curves.easeInCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve decelerate = Curves.decelerate;
  static const Curve accelerate = Curves.fastOutSlowIn;

  /// 自定义弹簧曲线 —— Miuix 标志性按压回弹
  static Curve get miuixSpring => const _MiuixSpringCurve();
}

class _MiuixSpringCurve extends Curve {
  const _MiuixSpringCurve();
  @override
  double transform(double t) {
    if (t == 0 || t == 1) return t;
    // 过冲回弹：先到 1.15 再弹回 1.0
    const overshoot = 1.15;
    final s = 1.0 - overshoot;
    return 1.0 + s * (1 - (1 - t) * (1 - t));
  }
}

/// Miuix 间距体系
class MiuixSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
}

/// Miuix 字体大小体系（跟随系统字体，不引入第三方字体）
class MiuixFontSize {
  static const double xs = 10.0;
  static const double sm = 12.0;
  static const double md = 14.0;
  static const double lg = 16.0;
  static const double xl = 18.0;
  static const double xxl = 22.0;
  static const double xxxl = 28.0;
  static const double display = 36.0;
}
