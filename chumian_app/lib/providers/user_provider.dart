import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  String? _token;
  String? _userId;
  String? _nickname;
  String? _email;
  int _dailyPoints = 90000000;
  bool _oobeCompleted = false;
  bool _isLoggedIn = false;
  bool _isLoading = true;

  String? get token => _token;
  String? get userId => _userId;
  String? get nickname => _nickname;
  String? get email => _email;
  int get dailyPoints => _dailyPoints;
  bool get oobeCompleted => _oobeCompleted;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _nickname = prefs.getString('nickname');
    _userId = prefs.getString('user_id');
    _oobeCompleted = prefs.getBool('oobe_completed') ?? false;

    if (_token != null) {
      ApiService.setToken(_token);
      try {
        final info = await ApiService.getUserInfo();
        _nickname = info['nickname'];
        _email = info['email'];
        _dailyPoints = info['daily_points'] ?? 90000000;
        _oobeCompleted = info['oobe_completed'] ?? false;
        _isLoggedIn = true;
      } catch (e) {
        _token = null;
        _isLoggedIn = false;
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final result = await ApiService.login(email, password);
    _token = result['token'];
    _userId = result['user_id'];
    _nickname = result['nickname'];
    _oobeCompleted = result['oobe_completed'] ?? false;
    _isLoggedIn = true;

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('token', _token!);
    prefs.setString('nickname', _nickname!);
    prefs.setString('user_id', _userId!);
    prefs.setBool('oobe_completed', _oobeCompleted);

    notifyListeners();
  }

  Future<void> register(
      String email, String code, String password, String nickname) async {
    final result = await ApiService.register(email, code, password, nickname);
    _token = result['token'];
    _userId = result['user_id'];
    _nickname = result['nickname'];
    _oobeCompleted = false;
    _isLoggedIn = true;

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('token', _token!);
    prefs.setString('nickname', _nickname!);
    prefs.setString('user_id', _userId!);
    prefs.setBool('oobe_completed', false);

    notifyListeners();
  }

  Future<void> completeOobe() async {
    await ApiService.completeOobe();
    _oobeCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('oobe_completed', true);
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (_) {}
    _token = null;
    _userId = null;
    _nickname = null;
    _email = null;
    _isLoggedIn = false;
    _oobeCompleted = false;

    final prefs = await SharedPreferences.getInstance();
    prefs.clear();

    notifyListeners();
  }

  void updatePoints(int points) {
    _dailyPoints = points;
    notifyListeners();
  }
}
