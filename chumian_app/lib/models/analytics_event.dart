/// ============================================================================
/// AnalyticsEvent —— 埋点事件数据模型
///
/// 承载单次用户行为埋点事件的完整信息，包括事件名称、
/// 附加参数、时间戳以及会话 ID。用于事件队列批量上报
/// 与本地缓存。
/// ============================================================================

/// 埋点事件数据模型
class AnalyticsEvent {
  /// 事件名称（如 page_view / button_click / item_purchase）
  final String name;

  /// 事件附加参数
  final Map<String, dynamic> params;

  /// 事件发生时间戳
  final DateTime timestamp;

  /// 会话 ID（同一次启动内的事件共享）
  final String sessionId;

  /// 用户 ID（未登录时为匿名 ID）
  final String? userId;

  /// 事件来源页面
  final String? sourcePage;

  /// 事件持续时长（毫秒，用于页面停留等）
  final int? durationMs;

  AnalyticsEvent({
    required this.name,
    Map<String, dynamic>? params,
    DateTime? timestamp,
    required this.sessionId,
    this.userId,
    this.sourcePage,
    this.durationMs,
  })  : params = params ?? {},
        timestamp = timestamp ?? DateTime.now();

  /// 从 JSON 反序列化
  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      name: json['name']?.toString() ?? '',
      params: json['params'] != null
          ? Map<String, dynamic>.from(json['params'] as Map)
          : {},
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      sessionId: json['session_id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      sourcePage: json['source_page']?.toString(),
      durationMs: (json['duration_ms'] as num?)?.toInt(),
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'params': params,
      'timestamp': timestamp.toIso8601String(),
      'session_id': sessionId,
      'user_id': userId,
      'source_page': sourcePage,
      'duration_ms': durationMs,
    };
  }

  /// 创建一个页面浏览事件
  factory AnalyticsEvent.pageView({
    required String pageName,
    required String sessionId,
    String? userId,
    int? durationMs,
    Map<String, dynamic>? extra,
  }) {
    final params = <String, dynamic>{'page_name': pageName};
    if (extra != null) params.addAll(extra);
    return AnalyticsEvent(
      name: 'page_view',
      params: params,
      sessionId: sessionId,
      userId: userId,
      sourcePage: pageName,
      durationMs: durationMs,
    );
  }

  /// 创建一个按钮点击事件
  factory AnalyticsEvent.buttonClick({
    required String buttonId,
    required String sessionId,
    String? userId,
    String? sourcePage,
    Map<String, dynamic>? extra,
  }) {
    final params = <String, dynamic>{'button_id': buttonId};
    if (extra != null) params.addAll(extra);
    return AnalyticsEvent(
      name: 'button_click',
      params: params,
      sessionId: sessionId,
      userId: userId,
      sourcePage: sourcePage,
    );
  }

  /// 创建一个自定义事件
  factory AnalyticsEvent.custom({
    required String eventName,
    required String sessionId,
    String? userId,
    String? sourcePage,
    Map<String, dynamic>? params,
  }) {
    return AnalyticsEvent(
      name: eventName,
      params: params,
      sessionId: sessionId,
      userId: userId,
      sourcePage: sourcePage,
    );
  }

  /// 事件唯一键（用于去重）
  String get uniqueKey =>
      '${name}_${timestamp.millisecondsSinceEpoch}_${sessionId}';

  /// 复制一份
  AnalyticsEvent copyWith({
    String? name,
    Map<String, dynamic>? params,
    DateTime? timestamp,
    String? sessionId,
    String? userId,
    String? sourcePage,
    int? durationMs,
  }) {
    return AnalyticsEvent(
      name: name ?? this.name,
      params: params ?? this.params,
      timestamp: timestamp ?? this.timestamp,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      sourcePage: sourcePage ?? this.sourcePage,
      durationMs: durationMs ?? this.durationMs,
    );
  }
}
