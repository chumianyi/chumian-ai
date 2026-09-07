import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chumian_ai/models/user_model.dart';
import 'package:chumian_ai/services/api_service.dart';

/// ============================================================================
/// UserProvider —— 用户状态管理 Provider（ChangeNotifier）
///
/// 职责：
///   1. 管理当前登录用户的完整状态（token / userId / nickname / email /
///      avatar / dailyPoints / oobeCompleted / isBanned / vipStatus）
///   2. 提供 init / login / register / completeOobe / logout /
///      updatePoints / refreshUserInfo 等操作
///   3. 用户信息持久化到 SharedPreferences（token + 基本信息）
///   4. 加载状态管理（isLoading），用于启动页判断
/// ============================================================================
class UserProvider extends ChangeNotifier {
  // ===== 持久化键 =====
  static const String _keyToken = 'token';
  static const String _keyUserId = 'user_id';
  static const String _keyNickname = 'nickname';
  static const String _keyEmail = 'email';
  static const String _keyAvatar = 'avatar';
  static const String _keyDailyPoints = 'daily_points';
  static const String _keyOobeCompleted = 'oobe_completed';

  // ===== 状态字段 =====
  String? _token;
  String? _userId;
  String? _nickname;
  String? _email;
  String? _avatar;
  int _dailyPoints = 0;
  bool _oobeCompleted = false;
  bool _isBanned = false;
  VipStatus _vipStatus = VipStatus.none;
  bool _isLoggedIn = false;
  bool _isLoading = true;
  String? _lastError;

  // ===== Getters =====
  String? get token => _token;
  String? get userId => _userId;
  String? get nickname => _nickname;
  String? get email => _email;
  String? get avatar => _avatar;
  int get dailyPoints => _dailyPoints;
  bool get oobeCompleted => _oobeCompleted;
  bool get isBanned => _isBanned;
  VipStatus get vipStatus => _vipStatus;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get isVip => _vipStatus.isVip;

  /// 获取当前用户的 User 模型对象
  User? get currentUser {
    if (_userId == null) return null;
    return User(
      id: _userId!,
      email: _email,
      nickname: _nickname ?? '',
      avatar: _avatar,
      dailyPoints: _dailyPoints,
      oobeCompleted: _oobeCompleted,
      isBanned: _isBanned,
      vipStatus: _vipStatus,
    );
  }

  // ==========================================================================
  // 初始化：从本地恢复登录态，然后拉取最新用户信息
  // ==========================================================================
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_keyToken);
      _userId = prefs.getString(_keyUserId);
      _nickname = prefs.getString(_keyNickname);
      _email = prefs.getString(_keyEmail);
      _avatar = prefs.getString(_keyAvatar);
      _dailyPoints = prefs.getInt(_keyDailyPoints) ?? 0;
      _oobeCompleted = prefs.getBool(_keyOobeCompleted) ?? false;

      if (_token != null && _token!.isNotEmpty) {
        // 注入 Token 到 ApiService
        await ApiService.setToken(_token);
        try {
          // 拉取最新用户信息
          final info = await ApiService.getUserInfo();
          _applyUserInfo(info);
          _isLoggedIn = true;
        } catch (e) {
          // Token 失效，清除本地登录态
          _clearLocalState();
          _isLoggedIn = false;
        }
      } else {
        _isLoggedIn = false;
      }
    } catch (_) {
      _isLoggedIn = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  // ==========================================================================
  // 登录
  // ==========================================================================
  Future<bool> login(String username, String password) async {
    _lastError = null;
    try {
      final result = await ApiService.login(username, password);
      _token = result['token']?.toString();
      _applyUserInfo(result);
      _isLoggedIn = true;
      await _persist();
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = _extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // ==========================================================================
  // 注册
  // ==========================================================================
  Future<bool> register({
    required String username,
    required String password,
    required String nickname,
  }) async {
    _lastError = null;
    try {
      final result = await ApiService.register(
        username: username,
        password: password,
        nickname: nickname,
      );
      _token = result['token']?.toString();
      _applyUserInfo(result);
      _oobeCompleted = false; // 新注册用户需完成 OOBE
      _isLoggedIn = true;
      await _persist();
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = _extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // ==========================================================================
  // 完成新手引导
  // ==========================================================================
  Future<void> completeOobe() async {
    try {
      await ApiService.completeOobe();
      _oobeCompleted = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyOobeCompleted, true);
      notifyListeners();
    } catch (_) {}
  }

  // ==========================================================================
  // 登出
  // ==========================================================================
  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (_) {}
    _clearLocalState();
    _isLoggedIn = false;
    notifyListeners();
  }

  // ==========================================================================
  // 更新积分（签到、消费等场景调用）
  // ==========================================================================
  void updatePoints(int points) {
    _dailyPoints = points;
    _persistInt(_keyDailyPoints, points);
    notifyListeners();
  }

  /// 积分增加
  void addPoints(int delta) {
    _dailyPoints += delta;
    _persistInt(_keyDailyPoints, _dailyPoints);
    notifyListeners();
  }

  /// 积分扣减（返回是否余额充足）
  bool deductPoints(int amount) {
    if (_dailyPoints < amount) return false;
    _dailyPoints -= amount;
    _persistInt(_keyDailyPoints, _dailyPoints);
    notifyListeners();
    return true;
  }

  // ==========================================================================
  // 刷新用户信息（从服务端拉取最新数据）
  // ==========================================================================
  Future<void> refreshUserInfo() async {
    if (!_isLoggedIn) return;
    try {
      final info = await ApiService.getUserInfo();
      _applyUserInfo(info);
      await _persist();
      notifyListeners();
    } catch (_) {}
  }

  // ==========================================================================
  // 更新用户资料
  // ==========================================================================
  Future<bool> updateProfile({
    String? nickname,
    String? avatar,
  }) async {
    try {
      await ApiService.updateProfile(
        nickname: nickname,
        avatar: avatar,
      );
      if (nickname != null) _nickname = nickname;
      if (avatar != null) _avatar = avatar;
      await _persist();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================================================
  // 内部工具方法
  // ==========================================================================

  /// 从服务端返回的 Map 中提取用户信息并应用到状态
  void _applyUserInfo(Map<String, dynamic> info) {
    _userId = info['user_id']?.toString() ??
        info['id']?.toString() ??
        _userId;
    _nickname = info['nickname']?.toString() ?? _nickname;
    _email = info['email']?.toString() ?? info['username']?.toString() ?? _email;
    _avatar = info['avatar']?.toString() ?? _avatar;
    _dailyPoints = (info['daily_points'] as num?)?.toInt() ??
        (info['points'] as num?)?.toInt() ??
        _dailyPoints;
    _oobeCompleted = info['oobe_completed'] == true || _oobeCompleted;
    _isBanned = info['is_banned'] == true;
    _vipStatus = VipStatusExtension.fromString(info['vip_status']?.toString());
  }

  /// 清除本地登录态（SharedPreferences + 内存）
  Future<void> _clearLocalState() async {
    _token = null;
    _userId = null;
    _nickname = null;
    _email = null;
    _avatar = null;
    _dailyPoints = 0;
    _oobeCompleted = false;
    _isBanned = false;
    _vipStatus = VipStatus.none;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyNickname);
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyAvatar);
      await prefs.remove(_keyDailyPoints);
      await prefs.remove(_keyOobeCompleted);
    } catch (_) {}
  }

  /// 持久化当前用户状态到 SharedPreferences
  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) await prefs.setString(_keyToken, _token!);
      if (_userId != null) await prefs.setString(_keyUserId, _userId!);
      if (_nickname != null) await prefs.setString(_keyNickname, _nickname!);
      if (_email != null) await prefs.setString(_keyEmail, _email!);
      if (_avatar != null) await prefs.setString(_keyAvatar, _avatar!);
      await prefs.setInt(_keyDailyPoints, _dailyPoints);
      await prefs.setBool(_keyOobeCompleted, _oobeCompleted);
    } catch (_) {}
  }

  /// 持久化单个 int 值
  Future<void> _persistInt(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
    } catch (_) {}
  }

  /// 从异常中提取可读的错误消息
  String _extractErrorMessage(dynamic e) {
    if (e is Map) {
      return e['message']?.toString() ?? '操作失败';
    }
    final msg = e.toString();
    if (msg.contains('401')) return '登录已过期，请重新登录';
    if (msg.contains('403')) return '没有权限执行此操作';
    if (msg.contains('404')) return '资源不存在';
    if (msg.contains('500')) return '服务器内部错误';
    if (msg.contains('SocketException') || msg.contains('Failed host')) {
      return '网络连接失败，请检查网络';
    }
    return msg;
  }

  /// 清除最后一次错误
  void clearError() {
    _lastError = null;
  }
}
