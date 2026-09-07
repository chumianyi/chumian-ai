import 'dart:async';
import 'dart:convert';
import 'package:chumian_ai/models/analytics_event.dart';
import 'package:chumian_ai/services/local_storage_service.dart';

/// ============================================================================
/// AnalyticsService —— 事件埋点与用户行为分析服务
///
/// 职责：
///   1. 事件埋点：记录页面访问、按钮点击、自定义事件
///   2. 会话管理：生成会话 ID，追踪会话时长
///   3. 事件队列：批量缓存事件，达到阈值或定时批量上报
///   4. 本地缓存：上报失败时持久化到本地，网络恢复后重试
///   5. 用户行为分析：页面停留时长、功能使用频率统计
/// ============================================================================
class AnalyticsService {
  /// 单例实例
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  // ===== 配置 =====
  /// 批量上报阈值（事件数）
  static const int _batchSize = 20;

  /// 定时上报间隔（秒）
  static const int _flushInterval = 30;

  /// 本地缓存最大事件数
  static const int _maxCachedEvents = 500;

  /// 本地存储键
  static const String _keyCachedEvents = 'analytics_cached_events';
  static const String _keySessionId = 'analytics_session_id';
  static const String _keySessionStart = 'analytics_session_start';
  static const String _keyPageEnterTime = 'analytics_page_enter_';

  // ===== 状态 =====
  /// 当前会话 ID
  String _sessionId = '';

  /// 会话开始时间
  DateTime _sessionStart = DateTime.now();

  /// 内存事件队列
  final List<AnalyticsEvent> _eventQueue = [];

  /// 定时上报定时器
  Timer? _flushTimer;

  /// 用户 ID
  String? _userId;

  /// 本地存储服务
  final LocalStorageService _storage = LocalStorageService();

  /// 是否已初始化
  bool _initialized = false;

  /// 上报回调（由外部注入，实际发送到服务器）
  Future<bool> Function(List<AnalyticsEvent>)? onReport;

  // ==========================================================================
  // 初始化与会话管理
  // ==========================================================================

  /// 初始化服务：恢复会话、加载缓存、启动定时上报
  Future<void> init({String? userId}) async {
    if (_initialized) return;
    _userId = userId;
    await _storage.init();

    // 恢复或创建会话
    final savedSessionId = await _storage.getString(_keySessionId);
    if (savedSessionId != null && savedSessionId.isNotEmpty) {
      _sessionId = savedSessionId;
    } else {
      _sessionId = _generateSessionId();
      await _storage.setString(_keySessionId, _sessionId);
    }
    _sessionStart = DateTime.now();
    await _storage.setString(
      _keySessionStart,
      _sessionStart.toIso8601String(),
    );

    // 加载本地缓存的失败事件
    await _loadCachedEvents();

    // 启动定时上报
    _startFlushTimer();
    _initialized = true;
  }

  /// 生成会话 ID
  String _generateSessionId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random =
        List.generate(8, (_) => now % 256).map((b) => b.toRadixString(16)).join();
    return 'sess_${now}_$random';
  }

  /// 获取当前会话 ID
  String get sessionId => _sessionId;

  /// 获取会话时长（秒）
  int get sessionDuration =>
      DateTime.now().difference(_sessionStart).inSeconds;

  /// 设置用户 ID（登录后调用）
  void setUserId(String? userId) {
    _userId = userId;
  }

  /// 结束当前会话并开始新会话
  Future<void> resetSession() async {
    // 记录会话结束事件
    trackEvent('session_end', params: {
      'duration_seconds': sessionDuration,
      'event_count': _eventQueue.length,
    });
    await flush();

    _sessionId = _generateSessionId();
    _sessionStart = DateTime.now();
    await _storage.setString(_keySessionId, _sessionId);
    await _storage.setString(
      _keySessionStart,
      _sessionStart.toIso8601String(),
    );
    trackEvent('session_start');
  }

  // ==========================================================================
  // 事件埋点
  // ==========================================================================

  /// 记录自定义事件
  void trackEvent(
    String eventName, {
    Map<String, dynamic>? params,
    String? sourcePage,
    int? durationMs,
  }) {
    final event = AnalyticsEvent(
      name: eventName,
      params: params,
      sessionId: _sessionId,
      userId: _userId,
      sourcePage: sourcePage,
      durationMs: durationMs,
    );
    _enqueueEvent(event);
  }

  /// 记录页面进入（开始计时）
  void trackPageEnter(String pageName) {
    final enterKey = '$_keyPageEnterTime$pageName';
    // 存储进入时间（用毫秒数字符串）
    _storage.setString(
      enterKey,
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
    trackEvent('page_enter', params: {'page_name': pageName});
  }

  /// 记录页面离开（计算停留时长）
  Future<void> trackPageLeave(String pageName) async {
    final enterKey = '$_keyPageEnterTime$pageName';
    final enterTimeStr = await _storage.getString(enterKey);
    int durationMs = 0;
    if (enterTimeStr != null) {
      final enterTime = int.tryParse(enterTimeStr) ?? 0;
      durationMs = DateTime.now().millisecondsSinceEpoch - enterTime;
      await _storage.remove(enterKey);
    }
    trackEvent(
      'page_leave',
      params: {'page_name': pageName, 'duration_ms': durationMs},
      durationMs: durationMs,
    );
  }

  /// 记录按钮点击
  void trackButtonClick(String buttonId, {String? sourcePage}) {
    trackEvent('button_click',
        params: {'button_id': buttonId}, sourcePage: sourcePage);
  }

  /// 记录功能使用
  void trackFeatureUsage(String featureName, {Map<String, dynamic>? extra}) {
    final params = <String, dynamic>{'feature_name': featureName};
    if (extra != null) params.addAll(extra);
    trackEvent('feature_usage', params: params);
  }

  // ==========================================================================
  // 事件队列与批量上报
  // ==========================================================================

  /// 事件入队
  void _enqueueEvent(AnalyticsEvent event) {
    _eventQueue.add(event);
    // 达到批量阈值立即上报
    if (_eventQueue.length >= _batchSize) {
      flush();
    }
  }

  /// 启动定时上报定时器
  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(
      const Duration(seconds: _flushInterval),
      (_) => flush(),
    );
  }

  /// 立即上报队列中的所有事件
  Future<void> flush() async {
    if (_eventQueue.isEmpty) return;
    final events = List<AnalyticsEvent>.from(_eventQueue);
    _eventQueue.clear();

    bool success = false;
    if (onReport != null) {
      try {
        success = await onReport!(events);
      } catch (_) {
        success = false;
      }
    }

    if (!success) {
      // 上报失败，缓存到本地
      await _cacheEvents(events);
    }
  }

  // ==========================================================================
  // 本地缓存
  // ==========================================================================

  /// 缓存事件到本地
  Future<void> _cacheEvents(List<AnalyticsEvent> events) async {
    final cached = await _loadCachedEventList();
    cached.addAll(events);
    // 限制最大缓存数量
    if (cached.length > _maxCachedEvents) {
      cached.removeRange(0, cached.length - _maxCachedEvents);
    }
    await _storage.setJsonList(
      _keyCachedEvents,
      cached.map((e) => e.toJson()).toList(),
    );
  }

  /// 加载本地缓存事件列表
  Future<List<AnalyticsEvent>> _loadCachedEventList() async {
    final list = await _storage.getJsonList(_keyCachedEvents);
    return list
        .map((e) => AnalyticsEvent.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// 加载本地缓存并尝试上报
  Future<void> _loadCachedEvents() async {
    final cached = await _loadCachedEventList();
    if (cached.isNotEmpty) {
      _eventQueue.addAll(cached);
      await _storage.remove(_keyCachedEvents);
    }
  }

  /// 重试上报本地缓存的事件
  Future<void> retryCachedEvents() async {
    await _loadCachedEvents();
    await flush();
  }

  // ==========================================================================
  // 行为统计
  // ==========================================================================

  /// 获取页面访问统计（从当前会话事件中统计）
  Map<String, int> getPageViewStats() {
    final stats = <String, int>{};
    for (final event in _eventQueue) {
      if (event.name == 'page_enter') {
        final page = event.params['page_name']?.toString() ?? 'unknown';
        stats[page] = (stats[page] ?? 0) + 1;
      }
    }
    return stats;
  }

  /// 获取功能使用统计
  Map<String, int> getFeatureUsageStats() {
    final stats = <String, int>{};
    for (final event in _eventQueue) {
      if (event.name == 'feature_usage') {
        final feature = event.params['feature_name']?.toString() ?? 'unknown';
        stats[feature] = (stats[feature] ?? 0) + 1;
      }
    }
    return stats;
  }

  /// 获取当前队列事件数
  int get queuedEventCount => _eventQueue.length;

  /// 销毁服务（取消定时器）
  void dispose() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _initialized = false;
  }
}
