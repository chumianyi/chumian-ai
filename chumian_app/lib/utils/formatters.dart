/// 本地格式化与数值处理工具集合。
/// 纯计算 / 字符串处理，不涉及网络。
library;

import 'package:flutter/material.dart';
import '../theme.dart';

class Formatters {
  Formatters._();

  /// 大数字格式化：1.2亿 / 3.4万 / 1200。
  static String compactNumber(dynamic value) {
    final num = _toNum(value);
    if (num >= Units.yi) {
      return '${_trim(num / Units.yi)}亿';
    }
    if (num >= Units.wan) {
      return '${_trim(num / Units.wan)}万';
    }
    return _trim(num);
  }

  /// 亿/万格式的积分展示（保留一位小数）。
  static String formatPoints(dynamic value) {
    final num = _toNum(value);
    if (num >= Units.yi) {
      return '${(num / Units.yi).toStringAsFixed(1)}亿';
    }
    if (num >= Units.wan) {
      return '${(num / Units.wan).toStringAsFixed(1)}万';
    }
    return num.toStringAsFixed(0);
  }

  /// 时间日期展示：今天 14:30 / 昨天 09:12 / 2026-08-01。
  static String formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '刚刚';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(that).inDays;
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff == 0) return '今天 $time';
    if (diff == 1) return '昨天 $time';
    if (diff < 7) return '${diff}天前';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// 精确日期（签到等场景）。
  static String formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// 秒数转 mm:ss / hh:mm:ss。
  static String formatDuration(int seconds) {
    if (seconds < 0) seconds = 0;
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) {
      return '$h:$mm:$ss';
    }
    return '$mm:$ss';
  }

  /// 相对时间：刚刚 / n分钟前 / n小时前 / n天前。
  static String timeAgo(String? iso) {
    if (iso == null || iso.isEmpty) return '刚刚';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '刚刚';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 30) return '${diff.inDays}天前';
    return '${dt.year}-${dt.month}-${dt.day}';
  }

  /// 隐藏邮箱中间部分：a***@mail.com。
  static String maskEmail(String? email) {
    if (email == null || email.isEmpty) return '未设置';
    final at = email.indexOf('@');
    if (at <= 1) return email;
    return '${email.substring(0, 1)}***${email.substring(at)}';
  }

  /// 昵称截断。
  static String ellipsis(String text, {int max = 12}) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}…';
  }

  /// 首字符（头像占位）。
  static String initialOf(String? name) {
    if (name == null || name.isEmpty) return '?';
    return String.fromCharCode(name.runes.first);
  }

  static num _toNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  static String _trim(num value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  }
}

/// 本地颜色工具。
class ColorTools {
  ColorTools._();

  /// 基于种子字符串生成稳定颜色。
  static Color fromSeed(String seed) => AvatarPalette.of(seed);

  /// 颜色叠加透明度。
  static Color alpha(Color color, double opacity) =>
      color.withValues(alpha: opacity);

  /// 在渐变背景上取可读前景色。
  static Color readableOn(Color background) => AppTheme.onColor(background);

  /// 两个颜色插值（用于进度渐变）。
  static Color lerp(Color a, Color b, double t) => Color.lerp(a, b, t)!;
}

/// 数值区间工具（本地）。
class Ranges {
  Ranges._();

  static double clampDouble(double v, double min, double max) =>
      v.clamp(min, max).toDouble();

  static int clampInt(int v, int min, int max) => v.clamp(min, max);

  /// 百分比进度 0~1。
  static double progress(int current, int total) {
    if (total <= 0) return 0;
    return (current / total).clamp(0.0, 1.0);
  }
}

/// 列表工具。
class ListTools {
  ListTools._();

  /// 分块成二维列表。
  static List<List<T>> chunk<T>(List<T> list, int size) {
    if (size <= 0) return [list];
    final result = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      final end = (i + size > list.length) ? list.length : i + size;
      result.add(list.sublist(i, end));
    }
    return result;
  }

  /// 安全索引读取。
  static T? at<T>(List<T> list, int index) {
    if (index < 0 || index >= list.length) return null;
    return list[index];
  }
}
