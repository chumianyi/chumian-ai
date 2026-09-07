import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// ============================================================================
/// Logger —— 分级日志工具
///
/// 提供 debug/info/warning/error 四级日志，带时间戳和标签，
/// 支持文件输出、崩溃记录、开发/生产模式切换。
/// ============================================================================

/// 日志级别枚举
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// LogLevel 扩展
extension LogLevelExtension on LogLevel {
  /// 级别数值（用于过滤）
  int get value {
    switch (this) {
      case LogLevel.debug:
        return 0;
      case LogLevel.info:
        return 1;
      case LogLevel.warning:
        return 2;
      case LogLevel.error:
        return 3;
    }
  }

  /// 显示名称
  String get label {
    switch (this) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }

  /// ANSI 颜色代码（终端输出）
  String get ansiColor {
    switch (this) {
      case LogLevel.debug:
        return '\x1B[37m'; // 白色
      case LogLevel.info:
        return '\x1B[36m'; // 青色
      case LogLevel.warning:
        return '\x1B[33m'; // 黄色
      case LogLevel.error:
        return '\x1B[31m'; // 红色
    }
  }
}

class Logger {
  /// 单例实例
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;
  Logger._internal();

  // ===== 配置 =====
  /// 最低输出级别（低于此级别的日志不输出）
  LogLevel _minLevel = LogLevel.debug;

  /// 是否为开发模式（输出更详细）
  bool _isDebug = true;

  /// 是否写入文件
  bool _enableFileOutput = false;

  /// 是否启用 ANSI 颜色
  bool _enableColors = true;

  /// 日志文件最大大小（字节，默认 5MB）
  static const int _maxFileSize = 5 * 1024 * 1024;

  /// 日志文件保留数量
  static const int _maxFileCount = 3;

  // ===== 状态 =====
  /// 日志文件
  File? _logFile;

  /// 崩溃记录文件
  File? _crashFile;

  /// 日志写入队列
  final List<String> _writeQueue = [];

  /// 是否正在写入
  bool _isWriting = false;

  /// 时间格式化
  static final DateFormat _dateFormat =
      DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

  // ==========================================================================
  // 初始化与配置
  // ==========================================================================

  /// 初始化日志器
  Future<void> init({
    bool isDebug = true,
    LogLevel minLevel = LogLevel.debug,
    bool enableFileOutput = false,
    bool enableColors = true,
  }) async {
    _isDebug = isDebug;
    _minLevel = minLevel;
    _enableFileOutput = enableFileOutput;
    _enableColors = enableColors;

    if (enableFileOutput) {
      await _initLogFile();
    }
  }

  /// 初始化日志文件
  Future<void> _initLogFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${dir.path}/logs');
      if (!logDir.existsSync()) {
        logDir.createSync(recursive: true);
      }
      _logFile = File('${logDir.path}/app.log');
      _crashFile = File('${logDir.path}/crash.log');

      // 检查文件大小，超过限制则轮转
      await _rotateLogFile();
    } catch (_) {
      _logFile = null;
      _crashFile = null;
    }
  }

  /// 日志文件轮转
  Future<void> _rotateLogFile() async {
    if (_logFile == null || !_logFile!.existsSync()) return;
    try {
      final length = await _logFile!.length();
      if (length >= _maxFileSize) {
        // 重命名旧文件
        for (int i = _maxFileCount - 1; i >= 1; i--) {
          final oldFile = File('${_logFile!.path}.$i');
          if (oldFile.existsSync()) {
            if (i == _maxFileCount - 1) {
              oldFile.deleteSync();
            } else {
              oldFile.renameSync('${_logFile!.path}.${i + 1}');
            }
          }
        }
        _logFile!.renameSync('${_logFile!.path}.1');
        _logFile = File(_logFile!.path.replaceAll('.1', ''));
      }
    } catch (_) {}
  }

  /// 设置最低日志级别
  void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// 设置开发模式
  void setDebugMode(bool debug) {
    _isDebug = debug;
  }

  // ==========================================================================
  // 日志输出方法
  // ==========================================================================

  /// 输出 DEBUG 级别日志
  static void d(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _instance._log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// 输出 INFO 级别日志
  static void i(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _instance._log(LogLevel.info, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// 输出 WARNING 级别日志
  static void w(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _instance._log(LogLevel.warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// 输出 ERROR 级别日志
  static void e(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _instance._log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// 内部日志方法
  void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // 级别过滤
    if (level.value < _minLevel.value) return;
    // 生产模式下不输出 debug
    if (!_isDebug && level == LogLevel.debug) return;

    final timestamp = _dateFormat.format(DateTime.now());
    final tagStr = tag != null ? '[$tag] ' : '';
    final errorStr = error != null ? '\n  Error: $error' : '';
    final stackStr = stackTrace != null ? '\n  Stack:\n$stackTrace' : '';

    final plainMessage =
        '$timestamp [${level.label}] $tagStr$message$errorStr$stackStr';

    // 控制台输出
    if (_enableColors) {
      // ignore: avoid_print
      print('${level.ansiColor}$plainMessage\x1B[0m');
    } else {
      // ignore: avoid_print
      print(plainMessage);
    }

    // 文件输出
    if (_enableFileOutput && _logFile != null) {
      _writeToFile(plainMessage);
    }

    // 错误级别记录到崩溃文件
    if (level == LogLevel.error && _crashFile != null) {
      _writeCrashLog(plainMessage);
    }
  }

  // ==========================================================================
  // 文件写入
  // ==========================================================================

  /// 异步写入日志文件
  void _writeToFile(String message) {
    _writeQueue.add(message);
    _flushWriteQueue();
  }

  /// 刷新写入队列
  Future<void> _flushWriteQueue() async {
    if (_isWriting || _writeQueue.isEmpty) return;
    _isWriting = true;

    try {
      await _rotateLogFile();
      final content = '${_writeQueue.join('\n')}\n';
      _writeQueue.clear();
      await _logFile!.writeAsString(
        content,
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      // 写入失败时静默处理
    } finally {
      _isWriting = false;
      if (_writeQueue.isNotEmpty) {
        _flushWriteQueue();
      }
    }
  }

  /// 写入崩溃日志
  Future<void> _writeCrashLog(String message) async {
    try {
      if (_crashFile != null) {
        await _crashFile!.writeAsString(
          '$message\n',
          mode: FileMode.append,
          flush: true,
        );
      }
    } catch (_) {}
  }

  // ==========================================================================
  // 崩溃记录
  // ==========================================================================

  /// 记录崩溃信息
  static void logCrash(Object error, StackTrace stackTrace, {String? context}) {
    _instance._log(
      LogLevel.error,
      'CRASH${context != null ? ' in $context' : ''}',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 记录 Flutter 框架错误
  static void logFlutterError(FlutterErrorDetails details) {
    _instance._log(
      LogLevel.error,
      'Flutter Error: ${details.exception}',
      error: details.exception,
      stackTrace: details.stack,
    );
  }

  // ==========================================================================
  // 日志查询与清理
  // ==========================================================================

  /// 获取日志文件路径
  String? get logFilePath => _logFile?.path;

  /// 获取崩溃日志文件路径
  String? get crashFilePath => _crashFile?.path;

  /// 读取日志文件内容
  Future<String> readLogs() async {
    if (_logFile == null || !_logFile!.existsSync()) return '';
    try {
      return await _logFile!.readAsString();
    } catch (_) {
      return '';
    }
  }

  /// 读取崩溃日志内容
  Future<String> readCrashLogs() async {
    if (_crashFile == null || !_crashFile!.existsSync()) return '';
    try {
      return await _crashFile!.readAsString();
    } catch (_) {
      return '';
    }
  }

  /// 清除日志文件
  Future<bool> clearLogs() async {
    try {
      if (_logFile != null && _logFile!.existsSync()) {
        await _logFile!.delete();
        _logFile = File(_logFile!.path);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 方法执行时间追踪
  static Future<T> trackExecution<T>(
    String tag,
    Future<T> Function() action,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await action();
      stopwatch.stop();
      d('$tag completed in ${stopwatch.elapsedMilliseconds}ms', tag: 'Perf');
      return result;
    } catch (e, stack) {
      stopwatch.stop();
      e('$tag failed after ${stopwatch.elapsedMilliseconds}ms',
          tag: 'Perf', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
