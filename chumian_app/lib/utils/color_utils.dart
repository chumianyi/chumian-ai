import 'dart:math';
import 'package:flutter/material.dart';

/// ============================================================================
/// ColorUtils —— 颜色工具类
///
/// 提供颜色十六进制转换、亮度调整、对比度计算、粉色调色板生成、
/// 渐变插值、颜色混合等常用颜色处理功能。
/// ============================================================================
class ColorUtils {
  // ==========================================================================
  // 十六进制转换
  // ==========================================================================

  /// 将十六进制颜色字符串转换为 Color
  ///
  /// 支持 "#RRGGBB"、"RRGGBB"、"#AARRGGBB"、"AARRGGBB" 格式
  static Color fromHex(String hexString) {
    final cleaned = hexString.replaceAll('#', '').trim();
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    } else if (cleaned.length == 8) {
      return Color(int.parse(cleaned, radix: 16));
    } else if (cleaned.length == 3) {
      // 简写格式 #RGB -> #RRGGBB
      final r = cleaned[0];
      final g = cleaned[1];
      final b = cleaned[2];
      return Color(int.parse('FF$r$r$g$g$b$b', radix: 16));
    }
    return Colors.black;
  }

  /// 将 Color 转换为十六进制字符串
  ///
  /// [includeAlpha] 是否包含 alpha 通道
  static String toHex(Color color, {bool includeAlpha = false}) {
    final r = color.red.toRadixString(16).padLeft(2, '0');
    final g = color.green.toRadixString(16).padLeft(2, '0');
    final b = color.blue.toRadixString(16).padLeft(2, '0');
    if (includeAlpha) {
      final a = color.alpha.toRadixString(16).padLeft(2, '0');
      return '#$a$r$g$b'.toUpperCase();
    }
    return '#$r$g$b'.toUpperCase();
  }

  /// 判断字符串是否为有效的十六进制颜色
  static bool isHexColor(String input) {
    final cleaned = input.replaceAll('#', '').trim();
    return RegExp(r'^[0-9a-fA-F]{3}$|^[0-9a-fA-F]{6}$|^[0-9a-fA-F]{8}$')
        .hasMatch(cleaned);
  }

  // ==========================================================================
  // 亮度调整
  // ==========================================================================

  /// 调亮颜色
  ///
  /// [amount] 调亮程度 0.0-1.0
  static Color lighten(Color color, [double amount = 0.1]) {
    final t = amount.clamp(0.0, 1.0);
    return Color.fromARGB(
      color.alpha,
      (color.red + (255 - color.red) * t).round(),
      (color.green + (255 - color.green) * t).round(),
      (color.blue + (255 - color.blue) * t).round(),
    );
  }

  /// 调暗颜色
  ///
  /// [amount] 调暗程度 0.0-1.0
  static Color darken(Color color, [double amount = 0.1]) {
    final t = amount.clamp(0.0, 1.0);
    return Color.fromARGB(
      color.alpha,
      (color.red * (1 - t)).round(),
      (color.green * (1 - t)).round(),
      (color.blue * (1 - t)).round(),
    );
  }

  /// 调整颜色亮度（正值调亮，负值调暗）
  static Color adjustBrightness(Color color, double amount) {
    if (amount >= 0) {
      return lighten(color, amount);
    } else {
      return darken(color, -amount);
    }
  }

  // ==========================================================================
  // 对比度计算
  // ==========================================================================

  /// 计算颜色的相对亮度（0.0-1.0）
  static double luminance(Color color) {
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;

    double channelLuminance(double c) {
      return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * channelLuminance(r) +
        0.7152 * channelLuminance(g) +
        0.0722 * channelLuminance(b);
  }

  /// 计算两种颜色的对比度比率（WCAG 标准）
  static double contrastRatio(Color a, Color b) {
    final l1 = luminance(a);
    final l2 = luminance(b);
    final lighter = max(l1, l2);
    final darker = min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// 根据背景色获取合适的文字颜色（黑或白）
  static Color adaptiveTextColor(Color background) {
    return luminance(background) > 0.5 ? Colors.black : Colors.white;
  }

  /// 判断颜色是否为亮色
  static bool isLight(Color color) {
    return luminance(color) > 0.5;
  }

  /// 判断颜色是否为暗色
  static bool isDark(Color color) {
    return !isLight(color);
  }

  // ==========================================================================
  // 粉色调色板
  // ==========================================================================

  /// 初眠AI 主题粉色
  static const Color primaryPink = Color(0xFFFF69B4);

  /// 生成粉色系调色板
  ///
  /// [count] 颜色数量，[baseColor] 基础粉色
  static List<Color> generatePinkPalette({
    int count = 10,
    Color baseColor = primaryPink,
  }) {
    final palette = <Color>[];
    for (int i = 0; i < count; i++) {
      final t = i / (count - 1);
      if (t < 0.5) {
        // 从白色过渡到基础色
        palette.add(
          Color.lerp(Colors.white, baseColor, t * 2)!,
        );
      } else {
        // 从基础色过渡到深粉色
        palette.add(
          Color.lerp(baseColor, darken(baseColor, 0.5), (t - 0.5) * 2)!,
        );
      }
    }
    return palette;
  }

  /// 生成粉色渐变颜色列表
  static List<Color> generatePinkGradient({
    int steps = 5,
    Color start = const Color(0xFFFFB6C1),
    Color end = const Color(0xFFFF1493),
  }) {
    return generateGradient(start: start, end: end, steps: steps);
  }

  // ==========================================================================
  // 渐变插值
  // ==========================================================================

  /// 生成从 start 到 end 的渐变颜色列表
  static List<Color> generateGradient({
    required Color start,
    required Color end,
    int steps = 5,
  }) {
    final colors = <Color>[];
    for (int i = 0; i < steps; i++) {
      final t = steps == 1 ? 0.0 : i / (steps - 1);
      colors.add(Color.lerp(start, end, t)!);
    }
    return colors;
  }

  /// 在两个颜色之间插值
  ///
  /// [t] 插值比例 0.0-1.0
  static Color lerp(Color a, Color b, double t) {
    return Color.lerp(a, b, t.clamp(0.0, 1.0))!;
  }

  /// 多色渐变中获取指定位置的颜色
  static Color lerpGradient(List<Color> colors, double t) {
    if (colors.isEmpty) return Colors.black;
    if (colors.length == 1) return colors.first;

    final clamped = t.clamp(0.0, 1.0);
    final segment = clamped * (colors.length - 1);
    final index = segment.floor().clamp(0, colors.length - 2);
    final localT = segment - index;
    return Color.lerp(colors[index], colors[index + 1], localT)!;
  }

  // ==========================================================================
  // 颜色混合
  // ==========================================================================

  /// 混合两种颜色（按比例）
  ///
  /// [ratio] 第一种颜色的比例 0.0-1.0
  static Color mix(Color a, Color b, [double ratio = 0.5]) {
    final t = ratio.clamp(0.0, 1.0);
    return Color.fromARGB(
      (a.alpha * (1 - t) + b.alpha * t).round(),
      (a.red * (1 - t) + b.red * t).round(),
      (a.green * (1 - t) + b.green * t).round(),
      (a.blue * (1 - t) + b.blue * t).round(),
    );
  }

  /// 将颜色与白色混合
  static Color tint(Color color, [double amount = 0.5]) {
    return mix(color, Colors.white, 1 - amount);
  }

  /// 将颜色与黑色混合
  static Color shade(Color color, [double amount = 0.5]) {
    return mix(color, Colors.black, 1 - amount);
  }

  /// 将颜色与灰色混合
  static Color tone(Color color, [double amount = 0.5]) {
    return mix(color, Colors.grey, 1 - amount);
  }

  // ==========================================================================
  // 颜色转换
  // ==========================================================================

  /// 将 Color 转换为 HSL
  static HSLColor toHSL(Color color) {
    return HSLColor.fromColor(color);
  }

  /// 从 HSL 创建 Color
  static Color fromHSL({
    double hue = 0,
    double saturation = 0.5,
    double lightness = 0.5,
  }) {
    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }

  /// 调整色相
  static Color withHue(Color color, double hue) {
    final hsl = toHSL(color);
    return hsl.withHue(hue).toColor();
  }

  /// 调整饱和度
  static Color withSaturation(Color color, double saturation) {
    final hsl = toHSL(color);
    return hsl.withSaturation(saturation.clamp(0.0, 1.0)).toColor();
  }

  /// 调整明度
  static Color withLightness(Color color, double lightness) {
    final hsl = toHSL(color);
    return hsl.withLightness(lightness.clamp(0.0, 1.0)).toColor();
  }

  /// 获取互补色
  static Color complementary(Color color) {
    final hsl = toHSL(color);
    return hsl.withHue((hsl.hue + 180) % 360).toColor();
  }

  /// 设置透明度
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity.clamp(0.0, 1.0));
  }

  // ==========================================================================
  // 随机颜色
  // ==========================================================================

  /// 生成随机颜色
  static Color random({Random? random, double saturation = 0.6, double lightness = 0.6}) {
    final rng = random ?? Random();
    return fromHSL(
      hue: rng.nextDouble() * 360,
      saturation: saturation,
      lightness: lightness,
    );
  }

  /// 生成随机粉色
  static Color randomPink({Random? random}) {
    final rng = random ?? Random();
    return fromHSL(
      hue: 320 + rng.nextDouble() * 40, // 320-360 粉色范围
      saturation: 0.6 + rng.nextDouble() * 0.3,
      lightness: 0.5 + rng.nextDouble() * 0.3,
    );
  }
}
