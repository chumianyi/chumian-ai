import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// ============================================================================
/// NetworkUtils —— 网络工具类
///
/// 提供网络状态检测、连接类型判断、ping 测试、API 延迟测量、
/// 重试机制、超时处理等网络相关工具功能。
/// ============================================================================
class NetworkUtils {
  /// Dio 实例（用于延迟测试）
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// 连接性检查实例
  static final Connectivity _connectivity = Connectivity();

  // ==========================================================================
  // 网络状态检测
  // ==========================================================================

  /// 检查是否有网络连接
  static Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (_) {
      return false;
    }
  }

  /// 获取当前连接类型
  static Future<ConnectivityType> getConnectionType() async {
    try {
      final result = await _connectivity.checkConnectivity();
      switch (result) {
        case ConnectivityResult.wifi:
          return ConnectivityType.wifi;
        case ConnectivityResult.mobile:
          return ConnectivityType.mobile;
        case ConnectivityResult.ethernet:
          return ConnectivityType.ethernet;
        case ConnectivityResult.none:
          return ConnectivityType.none;
        default:
          return ConnectivityType.unknown;
      }
    } catch (_) {
      return ConnectivityType.unknown;
    }
  }

  /// 是否为 WiFi 连接
  static Future<bool> isWifi() async {
    return (await getConnectionType()) == ConnectivityType.wifi;
  }

  /// 是否为移动数据连接
  static Future<bool> isMobile() async {
    return (await getConnectionType()) == ConnectivityType.mobile;
  }

  /// 监听网络状态变化
  static Stream<ConnectivityType> onConnectivityChanged() {
    return _connectivity.onConnectivityChanged.map((result) {
      switch (result) {
        case ConnectivityResult.wifi:
          return ConnectivityType.wifi;
        case ConnectivityResult.mobile:
          return ConnectivityType.mobile;
        case ConnectivityResult.ethernet:
          return ConnectivityType.ethernet;
        case ConnectivityResult.none:
          return ConnectivityType.none;
        default:
          return ConnectivityType.unknown;
      }
    });
  }

  // ==========================================================================
  // Ping 测试
  // ==========================================================================

  /// Ping 测试（通过 Socket 连接测试）
  ///
  /// [host] 目标主机，[port] 端口，[timeout] 超时时间
  /// 返回延迟毫秒数，失败返回 null
  static Future<int?> ping({
    String host = '8.8.8.8',
    int port = 53,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: timeout,
      );
      stopwatch.stop();
      socket.destroy();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      stopwatch.stop();
      return null;
    }
  }

  /// 多次 Ping 取平均值
  ///
  /// [count] 测试次数，[interval] 间隔时间
  static Future<PingResult> pingMultiple({
    String host = '8.8.8.8',
    int count = 4,
    Duration interval = const Duration(milliseconds: 500),
  }) async {
    final results = <int>[];
    int success = 0;

    for (int i = 0; i < count; i++) {
      final delay = await ping(host: host);
      if (delay != null) {
        results.add(delay);
        success++;
      }
      if (i < count - 1) {
        await Future.delayed(interval);
      }
    }

    if (results.isEmpty) {
      return PingResult(
        successCount: 0,
        totalCount: count,
        minDelay: null,
        maxDelay: null,
        avgDelay: null,
        lossRate: 1.0,
      );
    }

    final min = results.reduce((a, b) => a < b ? a : b);
    final max = results.reduce((a, b) => a > b ? a : b);
    final avg = results.reduce((a, b) => a + b) ~/ results.length;

    return PingResult(
      successCount: success,
      totalCount: count,
      minDelay: min,
      maxDelay: max,
      avgDelay: avg,
      lossRate: (count - success) / count,
    );
  }

  // ==========================================================================
  // API 延迟测量
  // ==========================================================================

  /// 测量 API 延迟（HTTP GET 请求）
  ///
  /// [url] 测试地址，返回延迟毫秒数，失败返回 null
  static Future<int?> measureApiLatency(String url) async {
    final stopwatch = Stopwatch()..start();
    try {
      await _dio.get(url);
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      stopwatch.stop();
      return null;
    }
  }

  /// 测量多个 API 端点的延迟，返回最快的
  static Future<ApiLatencyResult?> findFastestEndpoint(
    List<String> urls, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final results = <ApiLatencyResult>[];

    await Future.wait(urls.map((url) async {
      final delay = await measureApiLatency(url);
      if (delay != null) {
        results.add(ApiLatencyResult(url: url, latencyMs: delay));
      }
    }));

    if (results.isEmpty) return null;
    results.sort((a, b) => a.latencyMs.compareTo(b.latencyMs));
    return results.first;
  }

  // ==========================================================================
  // 重试机制
  // ==========================================================================

  /// 带重试的异步操作
  ///
  /// [operation] 要执行的操作，[maxRetries] 最大重试次数
  /// [retryDelay] 重试间隔，[retryIf] 自定义重试条件
  static Future<T> withRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
    bool Function(Object error)? retryIf,
  }) async {
    Object? lastError;
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        lastError = e;
        if (attempt >= maxRetries) rethrow;
        if (retryIf != null && !retryIf(e)) rethrow;
        await Future.delayed(retryDelay * (attempt + 1));
      }
    }
    throw lastError ?? Exception('Unknown error');
  }

  /// 带重试的 HTTP GET 请求
  static Future<Response<T>> getWithRetry<T>(
    String url, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return withRetry<Response<T>>(
      operation: () => _dio.get<T>(
        url,
        queryParameters: queryParameters,
        options: options,
      ),
      maxRetries: maxRetries,
      retryDelay: retryDelay,
      retryIf: (error) =>
          error is DioException &&
          (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError),
    );
  }

  // ==========================================================================
  // 超时处理
  // ==========================================================================

  /// 为异步操作添加超时
  static Future<T> withTimeout<T>({
    required Future<T> Function() operation,
    required Duration timeout,
    T? Function()? onTimeout,
  }) async {
    try {
      return await operation().timeout(timeout);
    } on TimeoutException {
      if (onTimeout != null) {
        return onTimeout() as T;
      }
      rethrow;
    }
  }

  /// 判断 Dio 异常是否为网络错误
  static bool isNetworkError(Object error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.unknown;
    }
    return error is SocketException || error is TimeoutException;
  }

  /// 获取网络错误的用户友好描述
  static String getNetworkErrorMessage(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return '连接超时，请检查网络后重试';
        case DioExceptionType.receiveTimeout:
          return '接收数据超时，请检查网络后重试';
        case DioExceptionType.sendTimeout:
          return '发送数据超时，请检查网络后重试';
        case DioExceptionType.connectionError:
          return '网络连接失败，请检查网络设置';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          return '服务器错误（$statusCode），请稍后重试';
        case DioExceptionType.cancel:
          return '请求已取消';
        default:
          return '网络异常，请稍后重试';
      }
    }
    if (error is SocketException) {
      return '网络连接失败，请检查网络设置';
    }
    if (error is TimeoutException) {
      return '请求超时，请检查网络后重试';
    }
    return '未知错误，请稍后重试';
  }
}

/// 连接类型枚举
enum ConnectivityType {
  wifi,
  mobile,
  ethernet,
  none,
  unknown,
}

/// Ping 测试结果
class PingResult {
  final int successCount;
  final int totalCount;
  final int? minDelay;
  final int? maxDelay;
  final int? avgDelay;
  final double lossRate;

  PingResult({
    required this.successCount,
    required this.totalCount,
    required this.minDelay,
    required this.maxDelay,
    required this.avgDelay,
    required this.lossRate,
  });

  /// 丢包率百分比文本
  String get lossRateText => '${(lossRate * 100).toStringAsFixed(0)}%';

  /// 平均延迟文本
  String get avgDelayText => avgDelay != null ? '${avgDelay}ms' : '--';
}

/// API 延迟结果
class ApiLatencyResult {
  final String url;
  final int latencyMs;

  ApiLatencyResult({required this.url, required this.latencyMs});
}
