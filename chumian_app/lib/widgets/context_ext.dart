/// BuildContext 主题取色扩展。
/// 统一从 Material Theme 读取语义色，使组件随主题 / 深色模式正确响应。
library;

import 'package:flutter/material.dart';

extension ThemeContextX on BuildContext {
  ColorScheme get scheme => Theme.of(this).colorScheme;

  /// 主色
  Color get primary => scheme.primary;

  /// 次色
  Color get secondary => scheme.secondary;

  /// 第三色
  Color get tertiary => scheme.tertiary;

  /// 页面背景
  Color get background => Theme.of(this).scaffoldBackgroundColor;

  /// 卡片表面
  Color get surface => scheme.surface;

  /// 表面（升高层）
  Color get surfaceElevated => _surfaceLifted(0.04);

  /// 表面（压暗层）
  Color get surfaceSubtle => _surfaceLifted(0.06);

  /// 主色容器
  Color get primaryContainer => scheme.primaryContainer;

  /// 主色容器前景
  Color get onPrimaryContainer => scheme.onPrimaryContainer;

  /// 正文色
  Color get textPrimary => Theme.of(this).textTheme.bodyLarge?.color ?? scheme.onSurface;

  /// 次要文本色
  Color get textSecondary => Theme.of(this).textTheme.bodyMedium?.color ?? scheme.onSurfaceVariant;

  /// 弱化文本色
  Color get textTertiary => Theme.of(this).textTheme.labelSmall?.color ?? scheme.outline;

  /// 主色上的文本色
  Color get onPrimary => scheme.onPrimary;

  /// 分隔线
  Color get divider => Theme.of(this).dividerColor;

  /// 成功色
  Color get success => const Color(0xFF22B573);

  /// 警告色
  Color get warning => const Color(0xFFF5A623);

  /// 危险色
  Color get danger => scheme.error;

  /// 信息色
  Color get info => const Color(0xFF3D7BF0);

  /// 主色渐变
  LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, secondary],
      );

  /// 主色明快渐变
  LinearGradient get vibrantGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, tertiary],
      );

  Color _surfaceLifted(double delta) {
    final base = surface;
    final isLight = Theme.of(this).brightness == Brightness.light;
    if (isLight) {
      return Color.lerp(base, Colors.white, delta * 8)? .withValues(alpha: 1) ?? base;
    }
    return Color.lerp(base, Colors.black, delta)? .withValues(alpha: 1) ?? base;
  }
}

/// 圆角快捷常量（供组件复用）。
class R {
  R._();

  static const Radius xs = Radius.circular(8);
  static const Radius sm = Radius.circular(12);
  static const Radius md = Radius.circular(16);
  static const Radius lg = Radius.circular(20);
  static const Radius xl = Radius.circular(24);
  static const Radius pill = Radius.circular(999);

  static const BorderRadius allXs = BorderRadius.all(xs);
  static const BorderRadius allSm = BorderRadius.all(sm);
  static const BorderRadius allMd = BorderRadius.all(md);
  static const BorderRadius allLg = BorderRadius.all(lg);
  static const BorderRadius allXl = BorderRadius.all(xl);
  static const BorderRadius allPill = BorderRadius.all(pill);
}
