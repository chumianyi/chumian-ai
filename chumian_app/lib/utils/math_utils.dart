import 'dart:math';

/// ============================================================================
/// MathUtils —— 数值工具类
///
/// 提供千分位格式化、百分比计算、范围映射、缓动函数、随机数、
/// 角度弧度转换、距离计算等常用数学工具功能。
/// ============================================================================
class MathUtils {
  // ==========================================================================
  // 数值格式化
  // ==========================================================================

  /// 千分位格式化数字
  ///
  /// [number] 数字，[decimals] 小数位数
  static String formatThousands(num number, {int decimals = 0}) {
    final isNegative = number < 0;
    final absNumber = number.abs();

    String formatted;
    if (decimals > 0) {
      formatted = absNumber.toStringAsFixed(decimals);
    } else {
      formatted = absNumber.round().toString();
    }

    // 分离整数和小数部分
    final parts = formatted.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    // 整数部分添加千分位
    final buffer = StringBuffer();
    final digits = integerPart.split('');
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }

    return '${isNegative ? '-' : ''}$buffer$decimalPart';
  }

  /// 格式化大数字为简短形式（如 1.5万、2.3M）
  static String formatCompact(num number, {int decimals = 1}) {
    final abs = number.abs();
    if (abs < 1000) return number.toStringAsFixed(0);
    if (abs < 10000) {
      return '${(number / 1000).toStringAsFixed(decimals)}K';
    }
    if (abs < 100000000) {
      return '${(number / 10000).toStringAsFixed(decimals)}万';
    }
    return '${(number / 100000000).toStringAsFixed(decimals)}亿';
  }

  /// 格式化百分比
  static String formatPercent(num value, {int decimals = 1, bool multiply = true}) {
    final pct = multiply ? value * 100 : value;
    return '${pct.toStringAsFixed(decimals)}%';
  }

  /// 格式化文件大小
  static String formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int unitIndex = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(decimals)} ${units[unitIndex]}';
  }

  // ==========================================================================
  // 百分比计算
  // ==========================================================================

  /// 计算百分比（part / total * 100）
  static double percent(num part, num total) {
    if (total == 0) return 0;
    return (part / total) * 100;
  }

  /// 计算比例（part / total，0.0-1.0）
  static double ratio(num part, num total) {
    if (total == 0) return 0;
    return (part / total).clamp(0.0, 1.0).toDouble();
  }

  /// 计算增长率
  static double growthRate(num current, num previous) {
    if (previous == 0) return 0;
    return ((current - previous) / previous) * 100;
  }

  // ==========================================================================
  // 范围映射
  // ==========================================================================

  /// 将值从一个范围映射到另一个范围
  ///
  /// [value] 输入值，[inMin]/[inMax] 输入范围
  /// [outMin]/[outMax] 输出范围
  static double map(
    num value,
    num inMin,
    num inMax,
    num outMin,
    num outMax,
  ) {
    if (inMax == inMin) return outMin.toDouble();
    return ((value - inMin) / (inMax - inMin)) * (outMax - outMin) + outMin;
  }

  /// 将值限制在范围内
  static T clamp<T extends num>(T value, T min, T max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  /// 将值限制在 0-1 范围内
  static double clamp01(num value) {
    return value.clamp(0.0, 1.0).toDouble();
  }

  /// 归一化值到 0-1 范围
  static double normalize(num value, num min, num max) {
    if (max == min) return 0;
    return ((value - min) / (max - min)).clamp(0.0, 1.0).toDouble();
  }

  // ==========================================================================
  // 缓动函数
  // ==========================================================================

  /// 线性缓动
  static double linear(double t) => t.clamp(0.0, 1.0);

  /// 二次方缓入
  static double easeInQuad(double t) {
    t = t.clamp(0.0, 1.0);
    return t * t;
  }

  /// 二次方缓出
  static double easeOutQuad(double t) {
    t = t.clamp(0.0, 1.0);
    return t * (2 - t);
  }

  /// 二次方缓入缓出
  static double easeInOutQuad(double t) {
    t = t.clamp(0.0, 1.0);
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }

  /// 三次方缓入
  static double easeInCubic(double t) {
    t = t.clamp(0.0, 1.0);
    return t * t * t;
  }

  /// 三次方缓出
  static double easeOutCubic(double t) {
    t = t.clamp(0.0, 1.0);
    final f = t - 1;
    return f * f * f + 1;
  }

  /// 三次方缓入缓出
  static double easeInOutCubic(double t) {
    t = t.clamp(0.0, 1.0);
    return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2;
  }

  /// 弹性缓出（回弹效果）
  static double easeOutElastic(double t) {
    t = t.clamp(0.0, 1.0);
    const c4 = (2 * pi) / 3;
    if (t == 0) return 0;
    if (t == 1) return 1;
    return pow(2, -10 * t) * sin((t * 10 - 0.75) * c4) + 1;
  }

  /// 回弹缓出
  static double easeOutBounce(double t) {
    t = t.clamp(0.0, 1.0);
    const n1 = 7.5625;
    const d1 = 2.75;
    if (t < 1 / d1) {
      return n1 * t * t;
    } else if (t < 2 / d1) {
      t -= 1.5 / d1;
      return n1 * t * t + 0.75;
    } else if (t < 2.5 / d1) {
      t -= 2.25 / d1;
      return n1 * t * t + 0.9375;
    } else {
      t -= 2.625 / d1;
      return n1 * t * t + 0.984375;
    }
  }

  // ==========================================================================
  // 随机数
  // ==========================================================================

  /// 生成指定范围内的随机整数
  static int randomInt(int min, int max, {Random? random}) {
    final rng = random ?? Random();
    return min + rng.nextInt(max - min + 1);
  }

  /// 生成指定范围内的随机浮点数
  static double randomDouble(double min, double max, {Random? random}) {
    final rng = random ?? Random();
    return min + rng.nextDouble() * (max - min);
  }

  /// 随机布尔值
  static bool randomBool({Random? random}) {
    final rng = random ?? Random();
    return rng.nextBool();
  }

  /// 从列表中随机选择一个元素
  static T randomChoice<T>(List<T> list, {Random? random}) {
    if (list.isEmpty) {
      throw StateError('Cannot choose from an empty list');
    }
    final rng = random ?? Random();
    return list[rng.nextInt(list.length)];
  }

  /// 从列表中随机选择多个不重复元素
  static List<T> randomChoices<T>(List<T> list, int count, {Random? random}) {
    if (count >= list.length) return List.from(list);
    final rng = random ?? Random();
    final indices = List.generate(list.length, (i) => i)..shuffle(rng);
    return indices.take(count).map((i) => list[i]).toList();
  }

  /// 打乱列表（返回新列表）
  static List<T> shuffle<T>(List<T> list, {Random? random}) {
    final rng = random ?? Random();
    final result = List<T>.from(list);
    result.shuffle(rng);
    return result;
  }

  // ==========================================================================
  // 角度弧度转换
  // ==========================================================================

  /// 角度转弧度
  static double degreesToRadians(num degrees) {
    return degrees * pi / 180;
  }

  /// 弧度转角度
  static double radiansToDegrees(num radians) {
    return radians * 180 / pi;
  }

  /// 将角度标准化到 0-360 范围
  static double normalizeAngle(num degrees) {
    var result = degrees % 360;
    if (result < 0) result += 360;
    return result.toDouble();
  }

  /// 计算两个角度之间的最短夹角
  static double angleDifference(num angle1, num angle2) {
    var diff = (angle2 - angle1) % 360;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return diff.toDouble();
  }

  // ==========================================================================
  // 距离计算
  // ==========================================================================

  /// 计算两点之间的欧几里得距离
  static double distance(
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return sqrt(dx * dx + dy * dy);
  }

  /// 计算两点之间的曼哈顿距离
  static double manhattanDistance(
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    return (x2 - x1).abs() + (y2 - y1).abs();
  }

  /// 计算两点之间的切比雪夫距离
  static double chebyshevDistance(
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    return max((x2 - x1).abs(), (y2 - y1).abs());
  }

  /// 计算两个经纬度之间的距离（公里）
  static double geoDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371.0; // 地球半径（公里）
    final dLat = degreesToRadians(lat2 - lat1);
    final dLon = degreesToRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(degreesToRadians(lat1)) *
            cos(degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  // ==========================================================================
  // 其他数学工具
  // ==========================================================================

  /// 计算平均值
  static double average(List<num> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// 计算中位数
  static double median(List<num> values) {
    if (values.isEmpty) return 0;
    final sorted = List<num>.from(values)..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return sorted[middle].toDouble();
    }
    return (sorted[middle - 1] + sorted[middle]) / 2;
  }

  /// 计算标准差
  static double standardDeviation(List<num> values) {
    if (values.length < 2) return 0;
    final mean = average(values);
    final squaredDiffs = values.map((v) => pow(v - mean, 2)).toList();
    final variance = squaredDiffs.reduce((a, b) => a + b) / (values.length - 1);
    return sqrt(variance);
  }

  /// 线性插值
  static double lerp(num a, num b, double t) {
    return a + (b - a) * t.clamp(0.0, 1.0);
  }

  /// 判断值是否在范围内
  static bool inRange(num value, num min, num max) {
    return value >= min && value <= max;
  }

  /// 接近判断（在容差范围内视为相等）
  static bool approximately(num a, num b, {num tolerance = 0.0001}) {
    return (a - b).abs() <= tolerance;
  }
}
