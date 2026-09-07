import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// ============================================================================
/// NotificationService —— 本地通知服务
///
/// 职责：
///   1. 通知权限请求与状态检查
///   2. Android 通知渠道管理（粉色主题渠道）
///   3. 即时通知与定时通知调度
///   4. 通知点击跳转路由
///   5. 通知取消与清理
///
/// 依赖 flutter_local_notifications 和 timezone 包。
/// ============================================================================
class NotificationService {
  /// 单例实例
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// 通知插件实例
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// 是否已初始化
  bool _initialized = false;

  /// 通知点击回调
  void Function(String? payload)? onNotificationTap;

  // ===== 通知渠道配置（Android）=====
  static const String _channelId = 'chumian_ai_default';
  static const String _channelName = '初眠AI 通知';
  static const String _channelDescription = '初眠AI 的默认通知渠道';

  /// 粉色主题通知渠道 ID
  static const String _pinkChannelId = 'chumian_ai_pink';
  static const String _pinkChannelName = '初眠AI 粉色提醒';
  static const String _pinkChannelDescription = '粉色主题的提醒与活动通知';

  /// 通知 ID 计数器
  int _notificationIdCounter = 0;

  // ==========================================================================
  // 初始化
  // ==========================================================================

  /// 初始化通知服务
  Future<void> init() async {
    if (_initialized) return;

    // 初始化时区
    tz.initializeTimeZones();

    // Android 初始化设置
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 初始化设置
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap?.call(response.payload);
      },
    );

    // 创建通知渠道
    await _createNotificationChannels();

    _initialized = true;
  }

  /// 创建 Android 通知渠道
  Future<void> _createNotificationChannels() async {
    // 默认渠道
    const defaultChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      enableVibration: true,
    );

    // 粉色主题渠道
    const pinkChannel = AndroidNotificationChannel(
      _pinkChannelId,
      _pinkChannelName,
      description: _pinkChannelDescription,
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      enableLights: true,
      ledColor: Color(0xFFFF69B4),
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(defaultChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(pinkChannel);
  }

  // ==========================================================================
  // 权限管理
  // ==========================================================================

  /// 请求通知权限
  Future<bool> requestPermission() async {
    if (!_initialized) await init();

    bool granted = false;

    // Android 13+ 权限请求
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      granted = await androidImpl.requestNotificationsPermission() ?? false;
    }

    // iOS 权限请求
    final iosImpl = _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      granted = await iosImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return granted;
  }

  /// 检查通知权限状态
  Future<bool> isPermissionGranted() async {
    if (!_initialized) await init();
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final status = await androidImpl.getNotificationChannel(_channelId);
      return status?.importance != Importance.none;
    }
    return true;
  }

  // ==========================================================================
  // 即时通知
  // ==========================================================================

  /// 发送即时通知
  ///
  /// [title] 通知标题，[body] 通知内容，[payload] 点击跳转数据
  /// [usePinkChannel] 是否使用粉色主题渠道
  Future<int> showNotification({
    required String title,
    required String body,
    String? payload,
    bool usePinkChannel = true,
  }) async {
    if (!_initialized) await init();

    final id = _nextId();
    final channelId = usePinkChannel ? _pinkChannelId : _channelId;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      usePinkChannel ? _pinkChannelName : _channelName,
      channelDescription:
          usePinkChannel ? _pinkChannelDescription : _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFFF69B4),
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _notifications.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );

    return id;
  }

  // ==========================================================================
  // 定时通知
  // ==========================================================================

  /// 发送定时通知
  ///
  /// [scheduledTime] 触发时间，[title] 标题，[body] 内容
  Future<int> scheduleNotification({
    required DateTime scheduledTime,
    required String title,
    required String body,
    String? payload,
    bool usePinkChannel = true,
  }) async {
    if (!_initialized) await init();

    final id = _nextId();
    final channelId = usePinkChannel ? _pinkChannelId : _channelId;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      usePinkChannel ? _pinkChannelName : _channelName,
      channelDescription:
          usePinkChannel ? _pinkChannelDescription : _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFFF69B4),
    );

    const iosDetails = DarwinNotificationDetails();

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    return id;
  }

  /// 发送每日重复通知（指定时分）
  Future<int> scheduleDailyNotification({
    required int hour,
    required int minute,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();

    final id = _nextId();
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      _pinkChannelId,
      _pinkChannelName,
      channelDescription: _pinkChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFFF69B4),
    );

    const iosDetails = DarwinNotificationDetails();

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduled, tz.local),
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );

    return id;
  }

  // ==========================================================================
  // 通知管理
  // ==========================================================================

  /// 取消指定通知
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// 获取所有待处理的定时通知
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return _notifications.pendingNotificationRequests();
  }

  /// 生成下一个通知 ID
  int _nextId() {
    _notificationIdCounter++;
    return DateTime.now().millisecondsSinceEpoch % 100000 +
        _notificationIdCounter;
  }
}
