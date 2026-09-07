/// ============================================================================
/// StopwatchUtils —— 计时器工具
///
/// 功能：
///   1. 格式化输出：毫秒/微秒转可读格式
///   2. 分段计时：记录多个时间点，计算各段耗时
///   3. 平均计算：计算多次计时的平均值
///   4. 最快/最慢：找出多次计时中的最快和最慢
///   5. 导出数据：导出计时数据为 JSON/CSV
/// ============================================================================

/// 计时记录
class TimingRecord {
  final String label;
  final Duration duration;
  final DateTime timestamp;

  TimingRecord({
    required this.label,
    required this.duration,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'duration_ms': duration.inMilliseconds,
        'duration_us': duration.inMicroseconds,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// 分段计时结果
class LapResult {
  final int lapNumber;
  final String? label;
  final Duration lapTime;
  final Duration totalTime;
  final DateTime timestamp;

  LapResult({
    required this.lapNumber,
    this.label,
    required this.lapTime,
    required this.totalTime,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'lap_number': lapNumber,
        'label': label,
        'lap_time_ms': lapTime.inMilliseconds,
        'total_time_ms': totalTime.inMilliseconds,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// 高级秒表（支持分段计时）
class AdvancedStopwatch {
  final Stopwatch _stopwatch = Stopwatch();
  final List<LapResult> _laps = [];
  Duration _lastLapTime = Duration.zero;
  bool _isRunning = false;

  /// 开始计时
  void start() {
    if (!_isRunning) {
      _stopwatch.start();
      _isRunning = true;
    }
  }

  /// 停止计时
  void stop() {
    if (_isRunning) {
      _stopwatch.stop();
      _isRunning = false;
    }
  }

  /// 重置计时
  void reset() {
    _stopwatch.reset();
    _laps.clear();
    _lastLapTime = Duration.zero;
    _isRunning = false;
  }

  /// 记录分段
  LapResult lap({String? label}) {
    final current = _stopwatch.elapsed;
    final lapTime = current - _lastLapTime;
    final result = LapResult(
      lapNumber: _laps.length + 1,
      label: label,
      lapTime: lapTime,
      totalTime: current,
      timestamp: DateTime.now(),
    );
    _laps.add(result);
    _lastLapTime = current;
    return result;
  }

  /// 当前已用时间
  Duration get elapsed => _stopwatch.elapsed;

  /// 是否正在运行
  bool get isRunning => _isRunning;

  /// 分段记录
  List<LapResult> get laps => List.unmodifiable(_laps);

  /// 分段数
  int get lapCount => _laps.length;

  /// 最快分段
  LapResult? get fastestLap {
    if (_laps.isEmpty) return null;
    return _laps.reduce((a, b) =>
        a.lapTime.compareTo(b.lapTime) < 0 ? a : b);
  }

  /// 最慢分段
  LapResult? get slowestLap {
    if (_laps.isEmpty) return null;
    return _laps.reduce((a, b) =>
        a.lapTime.compareTo(b.lapTime) > 0 ? a : b);
  }

  /// 平均分段时间
  Duration get averageLapTime {
    if (_laps.isEmpty) return Duration.zero;
    final total = _laps.fold<int>(
        0, (sum, lap) => sum + lap.lapTime.inMicroseconds);
    return Duration(microseconds: total ~/ _laps.length);
  }
}

class StopwatchUtils {
  // ==========================================================================
  // 格式化输出
  // ==========================================================================

  /// 格式化 Duration 为 mm:ss.SSS
  static String format(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = duration.inMilliseconds.remainder(1000).toString().padLeft(3, '0');
    return '$minutes:$seconds.$millis';
  }

  /// 格式化 Duration 为 hh:mm:ss
  static String formatHms(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// 格式化 Duration 为可读文本（如 "1分30秒"）
  static String formatReadable(Duration duration) {
    if (duration.inMicroseconds < 1000) {
      return '${duration.inMicroseconds}微秒';
    }
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds}毫秒';
    }
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}.${(duration.inMilliseconds % 1000).toString().padLeft(3, "0").substring(0, 1)}秒';
    }
    if (duration.inMinutes < 60) {
      final mins = duration.inMinutes;
      final secs = duration.inSeconds.remainder(60);
      return '$mins分${secs}秒';
    }
    if (duration.inHours < 24) {
      final hours = duration.inHours;
      final mins = duration.inMinutes.remainder(60);
      return '$hours小时$mins分';
    }
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    return '$days天$hours小时';
  }

  /// 格式化毫秒为 mm:ss.SSS
  static String formatMs(int milliseconds) {
    return format(Duration(milliseconds: milliseconds));
  }

  /// 格式化微秒
  static String formatUs(int microseconds) {
    return format(Duration(microseconds: microseconds));
  }

  // ==========================================================================
  // 分段计时
  // ==========================================================================

  /// 创建高级秒表
  static AdvancedStopwatch createStopwatch() {
    return AdvancedStopwatch();
  }

  /// 测量函数执行时间
  static Duration measure(void Function() action) {
    final sw = Stopwatch()..start();
    action();
    sw.stop();
    return sw.elapsed;
  }

  /// 测量异步函数执行时间
  static Future<Duration> measureAsync(Future<void> Function() action) async {
    final sw = Stopwatch()..start();
    await action();
    sw.stop();
    return sw.elapsed;
  }

  /// 测量函数执行时间并返回结果
  static (T, Duration) measureWithResult<T>(T Function() action) {
    final sw = Stopwatch()..start();
    final result = action();
    sw.stop();
    return (result, sw.elapsed);
  }

  /// 测量异步函数执行时间并返回结果
  static Future<(T, Duration)> measureAsyncWithResult<T>(
      Future<T> Function() action) async {
    final sw = Stopwatch()..start();
    final result = await action();
    sw.stop();
    return (result, sw.elapsed);
  }

  // ==========================================================================
  // 平均计算
  // ==========================================================================

  /// 计算 Duration 列表的平均值
  static Duration average(List<Duration> durations) {
    if (durations.isEmpty) return Duration.zero;
    final totalMicros = durations.fold<int>(
        0, (sum, d) => sum + d.inMicroseconds);
    return Duration(microseconds: totalMicros ~/ durations.length);
  }

  /// 计算 Duration 列表的总和
  static Duration sum(List<Duration> durations) {
    final totalMicros = durations.fold<int>(
        0, (sum, d) => sum + d.inMicroseconds);
    return Duration(microseconds: totalMicros);
  }

  /// 计算 Duration 列表的中位数
  static Duration median(List<Duration> durations) {
    if (durations.isEmpty) return Duration.zero;
    final sorted = List<int>.from(durations.map((d) => d.inMicroseconds))
      ..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return Duration(microseconds: sorted[middle]);
    }
    return Duration(
        microseconds: (sorted[middle - 1] + sorted[middle]) ~/ 2);
  }

  /// 计算标准差
  static double standardDeviation(List<Duration> durations) {
    if (durations.length < 2) return 0.0;
    final avg = average(durations).inMicroseconds;
    final squaredDiffs = durations.map((d) {
      final diff = d.inMicroseconds - avg;
      return diff * diff;
    }).toList();
    final variance = squaredDiffs.reduce((a, b) => a + b) /
        (durations.length - 1);
    return sqrt(variance);
  }

  // ==========================================================================
  // 最快/最慢
  // ==========================================================================

  /// 获取最快（最小）Duration
  static Duration min(List<Duration> durations) {
    if (durations.isEmpty) return Duration.zero;
    return durations.reduce((a, b) => a.compareTo(b) < 0 ? a : b);
  }

  /// 获取最慢（最大）Duration
  static Duration max(List<Duration> durations) {
    if (durations.isEmpty) return Duration.zero;
    return durations.reduce((a, b) => a.compareTo(b) > 0 ? a : b);
  }

  /// 获取最快记录的索引
  static int minIndex(List<Duration> durations) {
    if (durations.isEmpty) return -1;
    int minIdx = 0;
    for (int i = 1; i < durations.length; i++) {
      if (durations[i].compareTo(durations[minIdx]) < 0) {
        minIdx = i;
      }
    }
    return minIdx;
  }

  /// 获取最慢记录的索引
  static int maxIndex(List<Duration> durations) {
    if (durations.isEmpty) return -1;
    int maxIdx = 0;
    for (int i = 1; i < durations.length; i++) {
      if (durations[i].compareTo(durations[maxIdx]) > 0) {
        maxIdx = i;
      }
    }
    return maxIdx;
  }

  // ==========================================================================
  // 导出数据
  // ==========================================================================

  /// 导出计时记录为 JSON
  static String exportJson(List<TimingRecord> records) {
    final data = {
      'exported_at': DateTime.now().toIso8601String(),
      'count': records.length,
      'records': records.map((r) => r.toJson()).toList(),
      'statistics': {
        'total_ms': sum(records.map((r) => r.duration).toList()).inMilliseconds,
        'average_ms':
            average(records.map((r) => r.duration).toList()).inMilliseconds,
        'min_ms': min(records.map((r) => r.duration).toList()).inMilliseconds,
        'max_ms': max(records.map((r) => r.duration).toList()).inMilliseconds,
      },
    };
    return _jsonEncode(data);
  }

  /// 导出计时记录为 CSV
  static String exportCsv(List<TimingRecord> records) {
    final buffer = StringBuffer();
    buffer.writeln('label,duration_ms,duration_us,timestamp');
    for (final record in records) {
      buffer.writeln(
          '${record.label},${record.duration.inMilliseconds},'
          '${record.duration.inMicroseconds},${record.timestamp.toIso8601String()}');
    }
    return buffer.toString();
  }

  /// 导出分段计时为 JSON
  static String exportLapsJson(List<LapResult> laps) {
    final data = {
      'exported_at': DateTime.now().toIso8601String(),
      'lap_count': laps.length,
      'laps': laps.map((l) => l.toJson()).toList(),
    };
    return _jsonEncode(data);
  }

  // ==========================================================================
  // 工具方法
  // ==========================================================================

  /// 简单 JSON 编码（避免 dart:convert 依赖问题）
  static String _jsonEncode(dynamic data) {
    if (data is Map) {
      final entries = data.entries
          .map((e) => '"${e.key}":${_jsonEncode(e.value)}')
          .join(',');
      return '{$entries}';
    }
    if (data is List) {
      return '[${data.map(_jsonEncode).join(',')}]';
    }
    if (data is String) {
      return '"${data.replaceAll('"', '\\"').replaceAll('\n', '\\n')}"';
    }
    if (data is num || data is bool) return data.toString();
    if (data == null) return 'null';
    return '"$data"';
  }

  /// 多次运行取平均（用于性能测试）
  static Future<Duration> benchmarkAsync(
    Future<void> Function() action, {
    int iterations = 10,
    int warmup = 2,
  }) async {
    // 预热
    for (int i = 0; i < warmup; i++) {
      await action();
    }

    final durations = <Duration>[];
    for (int i = 0; i < iterations; i++) {
      final sw = Stopwatch()..start();
      await action();
      sw.stop();
      durations.add(sw.elapsed);
    }

    return average(durations);
  }

  /// 多次运行取平均（同步版本）
  static Duration benchmark(
    void Function() action, {
    int iterations = 10,
    int warmup = 2,
  }) {
    for (int i = 0; i < warmup; i++) {
      action();
    }

    final durations = <Duration>[];
    for (int i = 0; i < iterations; i++) {
      final sw = Stopwatch()..start();
      action();
      sw.stop();
      durations.add(sw.elapsed);
    }

    return average(durations);
  }

  /// 计算速度（每秒操作数）
  static double operationsPerSecond(Duration duration, int operations) {
    if (duration.inMicroseconds == 0) return 0;
    return operations * 1000000 / duration.inMicroseconds;
  }

  /// 格式化速度
  static String formatSpeed(double opsPerSecond) {
    if (opsPerSecond >= 1000000) {
      return '${(opsPerSecond / 1000000).toStringAsFixed(2)}M ops/s';
    }
    if (opsPerSecond >= 1000) {
      return '${(opsPerSecond / 1000).toStringAsFixed(2)}K ops/s';
    }
    return '${opsPerSecond.toStringAsFixed(1)} ops/s';
  }
}
