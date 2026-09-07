/// ============================================================================
/// DateUtils —— 日期时间工具类
///
/// 提供时间格式化（相对时间）、倒计时、签到日期计算等功能。
/// 注意：此类名为 DateUtils，与 Flutter 内置的 DateUtils 区分，
/// 使用时通过完整 import 路径引用。
/// ============================================================================
class DateUtils {
  /// 将 DateTime 格式化为相对时间描述
  ///
  /// 规则：
  ///   - 1分钟内：刚刚
  ///   - 1-60分钟：x分钟前
  ///   - 1-24小时：x小时前
  ///   - 昨天：昨天 HH:mm
  ///   - 今年内：MM-dd HH:mm
  ///   - 更早：yyyy-MM-dd
  static String formatRelative(DateTime dateTime, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final diff = currentTime.difference(dateTime);

    if (diff.inSeconds < 60) {
      return '刚刚';
    }

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    }

    if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    }

    // 昨天
    final yesterday = DateTime(
        currentTime.year, currentTime.month, currentTime.day - 1);
    final targetDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    if (targetDay == yesterday) {
      return '昨天 ${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
    }

    // 今年内
    if (dateTime.year == currentTime.year) {
      return '${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)} '
          '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
    }

    // 更早
    return '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)}';
  }

  /// 格式化为简短相对时间（用于列表等紧凑场景）
  static String formatRelativeShort(DateTime dateTime, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final diff = currentTime.difference(dateTime);

    if (diff.inSeconds < 60) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分';
    if (diff.inHours < 24) return '${diff.inHours}时';
    if (diff.inDays < 7) return '${diff.inDays}天';
    if (dateTime.year == currentTime.year) {
      return '${_twoDigits(dateTime.month)}/${_twoDigits(dateTime.day)}';
    }
    return '${dateTime.year}/${_twoDigits(dateTime.month)}';
  }

  /// 格式化为完整日期时间：yyyy-MM-dd HH:mm:ss
  static String formatFull(DateTime dateTime) {
    return '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)} '
        '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}:${_twoDigits(dateTime.second)}';
  }

  /// 格式化为日期：yyyy-MM-dd
  static String formatDate(DateTime dateTime) {
    return '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)}';
  }

  /// 格式化为时间：HH:mm
  static String formatTime(DateTime dateTime) {
    return '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
  }

  /// 格式化为中文日期：yyyy年MM月dd日
  static String formatDateChinese(DateTime dateTime) {
    return '${dateTime.year}年${_twoDigits(dateTime.month)}月${_twoDigits(dateTime.day)}日';
  }

  /// 倒计时格式化：将 Duration 转为 HH:mm:ss 或 mm:ss
  static String formatCountdown(Duration duration) {
    if (duration.isNegative) return '00:00';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${_twoDigits(hours)}:${_twoDigits(minutes)}:${_twoDigits(seconds)}';
    }
    return '${_twoDigits(minutes)}:${_twoDigits(seconds)}';
  }

  /// 倒计时格式化（中文）：x小时x分x秒
  static String formatCountdownChinese(Duration duration) {
    if (duration.isNegative) return '已结束';

    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final parts = <String>[];
    if (days > 0) parts.add('$days天');
    if (hours > 0) parts.add('$hours小时');
    if (minutes > 0) parts.add('$minutes分');
    if (seconds > 0 || parts.isEmpty) parts.add('$seconds秒');

    return parts.join('');
  }

  /// 判断两个日期是否为同一天
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 判断是否为今天
  static bool isToday(DateTime dateTime) {
    return isSameDay(dateTime, DateTime.now());
  }

  /// 判断是否为昨天
  static bool isYesterday(DateTime dateTime) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(dateTime, yesterday);
  }

  // ==========================================================================
  // 签到相关
  // ==========================================================================

  /// 获取今天的日期字符串（用于签到记录的 key）：yyyy-MM-dd
  static String get todayKey => formatDate(DateTime.now());

  /// 判断今天是否已签到
  static bool isCheckedInToday(String? lastCheckinDate) {
    if (lastCheckinDate == null || lastCheckinDate.isEmpty) return false;
    return lastCheckinDate == todayKey;
  }

  /// 计算连续签到天数
  ///
  /// [checkinDates] 为已签到日期列表（yyyy-MM-dd 格式）
  static int calculateStreak(List<String> checkinDates) {
    if (checkinDates.isEmpty) return 0;

    // 转为 DateTime 并去重、排序（倒序）
    final dates = checkinDates
        .map((d) => DateTime.tryParse(d))
        .whereType<DateTime>()
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) return 0;

    int streak = 0;
    DateTime expected = DateTime.now();

    // 如果今天没签到，从昨天开始算
    if (!isSameDay(dates.first, expected)) {
      expected = expected.subtract(const Duration(days: 1));
    }

    for (final date in dates) {
      if (isSameDay(date, expected)) {
        streak++;
        expected = expected.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// 获取本月已签到天数
  static int getMonthlyCheckinCount(List<String> checkinDates) {
    final now = DateTime.now();
    return checkinDates.where((d) {
      final parsed = DateTime.tryParse(d);
      if (parsed == null) return false;
      return parsed.year == now.year && parsed.month == now.month;
    }).length;
  }

  /// 获取本周的日期范围（周一到周日）
  static DateTimeRange getWeekRange({DateTime? from}) {
    final date = from ?? DateTime.now();
    final weekday = date.weekday; // 周一=1, 周日=7
    final monday = DateTime(date.year, date.month, date.day - (weekday - 1));
    final sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return DateTimeRange(start: monday, end: sunday);
  }

  /// 数字补零（两位数）
  static String _twoDigits(int n) {
    return n.toString().padLeft(2, '0');
  }
}

/// 日期范围（用于替代 Flutter 内置 DateTimeRange 的简单实现）
class DateTimeRange {
  final DateTime start;
  final DateTime end;
  const DateTimeRange({required this.start, required this.end});
}
