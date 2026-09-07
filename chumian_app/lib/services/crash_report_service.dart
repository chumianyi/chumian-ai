import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// ============================================================================
/// CrashReportService —— 崩溃报告服务
///
/// 职责：
///   1. FlutterError 捕获：拦截 Flutter 框架层错误
///   2. Zone 错误捕获：拦截异步和未捕获异常
///   3. 错误日志收集：收集错误详情、堆栈、设备信息
///   4. 本地存储：崩溃日志持久化到文件，支持查看和导出
///   5. 上报接口：将崩溃报告发送到服务器
///   6. 设备信息收集：收集设备型号、系统版本、应用版本等
/// ============================================================================

/// 崩溃报告
class CrashReport {
  final String id;
  final String type; // flutter_error / uncaught_exception / platform_error
  final String message;
  final String? stackTrace;
  final Map<String, dynamic> deviceInfo;
  final Map<String, dynamic> appInfo;
  final DateTime timestamp;
  final bool isFatal;
  final String? context;

  CrashReport({
    required this.id,
    required this.type,
    required this.message,
    this.stackTrace,
    required this.deviceInfo,
    required this.appInfo,
    required this.timestamp,
    this.isFatal = false,
    this.context,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'message': message,
        'stack_trace': stackTrace,
        'device_info': deviceInfo,
        'app_info': appInfo,
        'timestamp': timestamp.toIso8601String(),
        'is_fatal': isFatal,
        'context': context,
      };

  factory CrashReport.fromJson(Map<String, dynamic> json) => CrashReport(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'unknown',
        message: json['message']?.toString() ?? '',
        stackTrace: json['stack_trace']?.toString(),
        deviceInfo:
            Map<String, dynamic>.from(json['device_info'] ?? {}),
        appInfo: Map<String, dynamic>.from(json['app_info'] ?? {}),
        timestamp:
            DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
                DateTime.now(),
        isFatal: json['is_fatal'] == true,
        context: json['context']?.toString(),
      );
}

/// 设备信息
class DeviceInfo {
  final String platform;
  final String osVersion;
  final String model;
  final String manufacturer;
  final String locale;
  final double screenWidth;
  final double screenHeight;
  final double devicePixelRatio;
  final int memoryMb;
  final int storageMb;

  DeviceInfo({
    required this.platform,
    required this.osVersion,
    required this.model,
    required this.manufacturer,
    required this.locale,
    required this.screenWidth,
    required this.screenHeight,
    required this.devicePixelRatio,
    required this.memoryMb,
    required this.storageMb,
  });

  Map<String, dynamic> toJson() => {
        'platform': platform,
        'os_version': osVersion,
        'model': model,
        'manufacturer': manufacturer,
        'locale': locale,
        'screen_width': screenWidth,
        'screen_height': screenHeight,
        'device_pixel_ratio': devicePixelRatio,
        'memory_mb': memoryMb,
        'storage_mb': storageMb,
      };
}

class CrashReportService {
  /// 单例实例
  static final CrashReportService _instance = CrashReportService._internal();
  factory CrashReportService() => _instance;
  CrashReportService._internal();

  // ===== 配置 =====
  /// 崩溃日志目录名
  static const String _crashDirName = 'crash_reports';

  /// 最大保留崩溃报告数
  static const int _maxReports = 100;

  /// 上报地址
  static const String _reportEndpoint = '/api/crash/report';

  // ===== 状态 =====
  final List<CrashReport> _reports = [];
  final StreamController<CrashReport> _reportController =
      StreamController<CrashReport>.broadcast();
  DeviceInfo? _cachedDeviceInfo;
  Map<String, dynamic>? _cachedAppInfo;
  bool _initialized = false;
  bool _enableReporting = true;
  bool _enableConsoleOutput = true;

  // ==========================================================================
  // 初始化
  // ==========================================================================

  /// 初始化崩溃报告服务
  ///
  /// 应在 runApp 之前调用，设置 FlutterError.onError
  Future<void> init({
    bool enableReporting = true,
    bool enableConsoleOutput = true,
  }) async {
    if (_initialized) return;
    _enableReporting = enableReporting;
    _enableConsoleOutput = enableConsoleOutput;

    // 捕获 Flutter 框架错误
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };

    // 捕获平台分发的错误
    PlatformDispatcher.instance.onError = (error, stack) {
      _handleUncaughtException(error, stack, context: 'platform_dispatcher');
      return true;
    };

    _cachedDeviceInfo = await _collectDeviceInfo();
    _cachedAppInfo = await _collectAppInfo();
    await _loadReports();
    _initialized = true;
  }

  // ==========================================================================
  // 错误捕获
  // ==========================================================================

  /// 处理 Flutter 框架错误
  void _handleFlutterError(FlutterErrorDetails details) {
    final report = CrashReport(
      id: _generateId(),
      type: 'flutter_error',
      message: details.exceptionAsString(),
      stackTrace: details.stack?.toString(),
      deviceInfo: _cachedDeviceInfo?.toJson() ?? {},
      appInfo: _cachedAppInfo ?? {},
      timestamp: DateTime.now(),
      isFatal: true,
      context: details.context?.toString(),
    );

    _processReport(report);

    // 输出到控制台
    if (_enableConsoleOutput) {
      debugPrint('=== CRASH (FlutterError) ===');
      debugPrint('Message: ${report.message}');
      if (report.stackTrace != null) {
        debugPrint('Stack: ${report.stackTrace}');
      }
    }
  }

  /// 处理未捕获异常（在 Zone 中调用）
  void _handleUncaughtException(
    Object error,
    StackTrace stackTrace, {
    String? context,
  }) {
    final report = CrashReport(
      id: _generateId(),
      type: 'uncaught_exception',
      message: error.toString(),
      stackTrace: stackTrace.toString(),
      deviceInfo: _cachedDeviceInfo?.toJson() ?? {},
      appInfo: _cachedAppInfo ?? {},
      timestamp: DateTime.now(),
      isFatal: true,
      context: context,
    );

    _processReport(report);

    if (_enableConsoleOutput) {
      debugPrint('=== CRASH (Uncaught) ===');
      debugPrint('Error: ${report.message}');
      debugPrint('Stack: ${report.stackTrace}');
    }
  }

  /// 手动记录非致命错误
  void logError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    bool isFatal = false,
  }) {
    final report = CrashReport(
      id: _generateId(),
      type: 'manual_log',
      message: error.toString(),
      stackTrace: stackTrace?.toString(),
      deviceInfo: _cachedDeviceInfo?.toJson() ?? {},
      appInfo: _cachedAppInfo ?? {},
      timestamp: DateTime.now(),
      isFatal: isFatal,
      context: context,
    );
    _processReport(report);
  }

  /// 处理报告：存储 + 通知 + 上报
  void _processReport(CrashReport report) {
    _reports.insert(0, report);
    if (_reports.length > _maxReports) {
      _reports.removeLast();
    }
    _persistReports();
    _reportController.add(report);

    if (_enableReporting) {
      _uploadReport(report);
    }
  }

  // ==========================================================================
  // 设备与应用信息收集
  // ==========================================================================

  /// 收集设备信息
  Future<DeviceInfo> _collectDeviceInfo() async {
    // 模拟设备信息收集（实际应使用 device_info 插件）
    return DeviceInfo(
      platform: Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'unknown'),
      osVersion: Platform.operatingSystemVersion,
      model: 'Unknown Model',
      manufacturer: 'Unknown',
      locale: Platform.localeName,
      screenWidth:
          WidgetsBinding.instance.platformDispatcher.views.first.physicalSize.width,
      screenHeight:
          WidgetsBinding.instance.platformDispatcher.views.first.physicalSize.height,
      devicePixelRatio:
          WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio,
      memoryMb: 0,
      storageMb: 0,
    );
  }

  /// 收集应用信息
  Future<Map<String, dynamic>> _collectAppInfo() async {
    return {
      'app_name': '触面AI',
      'app_version': '3.0.0',
      'build_number': '1',
      'package_name': 'com.chumian.chumian_ai',
      'build_mode': kReleaseMode ? 'release' : (kProfileMode ? 'profile' : 'debug'),
      'dart_version': Platform.version,
      'is_web': kIsWeb,
    };
  }

  // ==========================================================================
  // 崩溃报告查询
  // ==========================================================================

  /// 获取所有崩溃报告
  List<CrashReport> get reports => List.unmodifiable(_reports);

  /// 崩溃报告事件流
  Stream<CrashReport> get reportStream => _reportController.stream;

  /// 获取致命崩溃数
  int get fatalCrashCount => _reports.where((r) => r.isFatal).length;

  /// 获取今日崩溃数
  int get todayCrashCount {
    final today = DateTime.now();
    return _reports
        .where((r) =>
            r.timestamp.year == today.year &&
            r.timestamp.month == today.month &&
            r.timestamp.day == today.day)
        .length;
  }

  /// 获取单条报告
  CrashReport? getReport(String id) {
    try {
      return _reports.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  // ==========================================================================
  // 上报
  // ==========================================================================

  /// 上传崩溃报告到服务器
  Future<bool> _uploadReport(CrashReport report) async {
    try {
      // 模拟上报请求
      await Future.delayed(const Duration(milliseconds: 100));
      // 实际实现应通过 ApiService 发送 POST 请求到 _reportEndpoint
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 批量上报所有未上报的报告
  Future<int> uploadAllPending() async {
    int count = 0;
    for (final report in _reports) {
      final success = await _uploadReport(report);
      if (success) count++;
    }
    return count;
  }

  /// 设置是否启用上报
  void setReportingEnabled(bool enabled) {
    _enableReporting = enabled;
  }

  bool get isReportingEnabled => _enableReporting;

  // ==========================================================================
  // 导出与清理
  // ==========================================================================

  /// 导出所有崩溃报告为 JSON 字符串
  String exportReports() {
    return jsonEncode({
      'exported_at': DateTime.now().toIso8601String(),
      'total': _reports.length,
      'reports': _reports.map((r) => r.toJson()).toList(),
    });
  }

  /// 导出单条报告
  String exportReport(String id) {
    final report = getReport(id);
    if (report == null) return '';
    return jsonEncode(report.toJson());
  }

  /// 删除单条报告
  Future<bool> deleteReport(String id) async {
    final removed = _reports.removeWhere((r) => r.id == id);
    if (removed > 0) {
      await _persistReports();
    }
    return removed > 0;
  }

  /// 清空所有崩溃报告
  Future<void> clearAll() async {
    _reports.clear();
    await _persistReports();
  }

  // ==========================================================================
  // 持久化
  // ==========================================================================

  Future<Directory> _getCrashDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final crashDir = Directory('${dir.path}/$_crashDirName');
    if (!crashDir.existsSync()) {
      crashDir.createSync(recursive: true);
    }
    return crashDir;
  }

  Future<void> _persistReports() async {
    try {
      final dir = await _getCrashDir();
      final file = File('${dir.path}/reports.json');
      // 只保留最近 50 条以控制文件大小
      final toSave = _reports.take(50).toList();
      await file.writeAsString(
          jsonEncode(toSave.map((r) => r.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _loadReports() async {
    try {
      final dir = await _getCrashDir();
      final file = File('${dir.path}/reports.json');
      if (!file.existsSync()) return;
      final content = await file.readAsString();
      final list = jsonDecode(content) as List;
      _reports.clear();
      for (final item in list) {
        _reports.add(CrashReport.fromJson(
            Map<String, dynamic>.from(item as Map)));
      }
    } catch (_) {}
  }

  // ==========================================================================
  // 工具方法
  // ==========================================================================

  String _generateId() {
    return 'crash_${DateTime.now().microsecondsSinceEpoch}_'
        '${_reports.length}';
  }

  /// 格式化崩溃报告为可读文本
  String formatReportReadable(CrashReport report) {
    final buffer = StringBuffer();
    buffer.writeln('=== 崩溃报告 ===');
    buffer.writeln('ID: ${report.id}');
    buffer.writeln('类型: ${report.type}');
    buffer.writeln('时间: ${report.timestamp.toIso8601String()}');
    buffer.writeln('致命: ${report.isFatal ? "是" : "否"}');
    if (report.context != null) {
      buffer.writeln('上下文: ${report.context}');
    }
    buffer.writeln('');
    buffer.writeln('错误信息:');
    buffer.writeln(report.message);
    buffer.writeln('');
    if (report.stackTrace != null) {
      buffer.writeln('堆栈跟踪:');
      buffer.writeln(report.stackTrace);
      buffer.writeln('');
    }
    buffer.writeln('设备信息:');
    report.deviceInfo.forEach((k, v) => buffer.writeln('  $k: $v'));
    buffer.writeln('');
    buffer.writeln('应用信息:');
    report.appInfo.forEach((k, v) => buffer.writeln('  $k: $v'));
    return buffer.toString();
  }

  /// 销毁服务
  void dispose() {
    _reportController.close();
  }
}
