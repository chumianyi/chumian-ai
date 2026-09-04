import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String? _username;
  String? get username => _username;

  String? _avatar;
  String? get avatar => _avatar;

  int _points = 0;
  int get points => _points;

  void login(String name) {
    _isLoggedIn = true;
    _username = name;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _username = null;
    _avatar = null;
    _points = 0;
    notifyListeners();
  }

  void addPoints(int amount) {
    _points += amount;
    notifyListeners();
  }
}
