import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

/// ============================================================================
/// SettingsProvider —— 应用设置管理 Provider（ChangeNotifier）
///
/// 职责：
///   1. 管理用户偏好设置：音效、震动、消息通知、深色模式、语言等
///   2. 所有设置项持久化到 SharedPreferences
///   3. 缓存管理：计算缓存大小、清除缓存
///   4. 提供设置项的 getter / setter，变更时通知监听器
/// ============================================================================

/// 应用语言枚举
enum AppLanguage { system, zhCN, enUS }

/// 语言扩展
extension AppLanguageExtension on AppLanguage {
  String get label {
    switch (this) {
      case AppLanguage.system:
        return '跟随系统';
      case AppLanguage.zhCN:
        return '简体中文';
      case AppLanguage.enUS:
        return 'English';
    }
  }

  String get code {
    switch (this) {
      case AppLanguage.system:
        return 'system';
      case AppLanguage.zhCN:
        return 'zh_CN';
      case AppLanguage.enUS:
        return 'en_US';
    }
  }

  static AppLanguage fromCode(String? code) {
    switch (code) {
      case 'zh_CN':
        return AppLanguage.zhCN;
      case 'en_US':
        return AppLanguage.enUS;
      default:
        return AppLanguage.system;
    }
  }
}

class SettingsProvider extends ChangeNotifier {
  // ===== 持久化键 =====
  static const String _keySoundEnabled = 'settings_sound';
  static const String _keyVibrationEnabled = 'settings_vibration';
  static const String _keyNotificationEnabled = 'settings_notification';
  static const String _keyDarkMode = 'settings_dark_mode';
  static const String _keyLanguage = 'settings_language';
  static const String _keyAutoPlayVideo = 'settings_auto_play_video';
  static const String _keyShowThinkContent = 'settings_show_think';
  static const String _keyMessagePreview = 'settings_message_preview';
  static const String _keyFontScale = 'settings_font_scale';

  // ===== 设置状态 =====
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _notificationEnabled = true;
  bool _darkMode = false;
  AppLanguage _language = AppLanguage.system;
  bool _autoPlayVideo = false;
  bool _showThinkContent = true;
  bool _messagePreview = true;
  double _fontScale = 1.0;

  // ===== 缓存状态 =====
  double _cacheSizeMB = 0;
  bool _cacheCalculating = false;

  // ===== Getters =====
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get notificationEnabled => _notificationEnabled;
  bool get darkMode => _darkMode;
  AppLanguage get language => _language;
  bool get autoPlayVideo => _autoPlayVideo;
  bool get showThinkContent => _showThinkContent;
  bool get messagePreview => _messagePreview;
  double get fontScale => _fontScale;
  double get cacheSizeMB => _cacheSizeMB;
  bool get cacheCalculating => _cacheCalculating;

  // ==========================================================================
  // 初始化：从 SharedPreferences 加载所有设置
  // ==========================================================================
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool(_keySoundEnabled) ?? true;
      _vibrationEnabled = prefs.getBool(_keyVibrationEnabled) ?? true;
      _notificationEnabled = prefs.getBool(_keyNotificationEnabled) ?? true;
      _darkMode = prefs.getBool(_keyDarkMode) ?? false;
      _language = AppLanguageExtension.fromCode(
          prefs.getString(_keyLanguage));
      _autoPlayVideo = prefs.getBool(_keyAutoPlayVideo) ?? false;
      _showThinkContent = prefs.getBool(_keyShowThinkContent) ?? true;
      _messagePreview = prefs.getBool(_keyMessagePreview) ?? true;
      _fontScale = prefs.getDouble(_keyFontScale) ?? 1.0;
      notifyListeners();
    } catch (_) {}
  }

  // ==========================================================================
  // 设置项 Setter（每个都持久化 + 通知）
  // ==========================================================================

  Future<void> setSoundEnabled(bool value) async {
    if (_soundEnabled == value) return;
    _soundEnabled = value;
    await _saveBool(_keySoundEnabled, value);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool value) async {
    if (_vibrationEnabled == value) return;
    _vibrationEnabled = value;
    await _saveBool(_keyVibrationEnabled, value);
    notifyListeners();
  }

  Future<void> setNotificationEnabled(bool value) async {
    if (_notificationEnabled == value) return;
    _notificationEnabled = value;
    await _saveBool(_keyNotificationEnabled, value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (_darkMode == value) return;
    _darkMode = value;
    await _saveBool(_keyDarkMode, value);
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage lang) async {
    if (_language == lang) return;
    _language = lang;
    await _saveString(_keyLanguage, lang.code);
    notifyListeners();
  }

  Future<void> setAutoPlayVideo(bool value) async {
    if (_autoPlayVideo == value) return;
    _autoPlayVideo = value;
    await _saveBool(_keyAutoPlayVideo, value);
    notifyListeners();
  }

  Future<void> setShowThinkContent(bool value) async {
    if (_showThinkContent == value) return;
    _showThinkContent = value;
    await _saveBool(_keyShowThinkContent, value);
    notifyListeners();
  }

  Future<void> setMessagePreview(bool value) async {
    if (_messagePreview == value) return;
    _messagePreview = value;
    await _saveBool(_keyMessagePreview, value);
    notifyListeners();
  }

  Future<void> setFontScale(double scale) async {
    if ((_fontScale - scale).abs() < 0.01) return;
    _fontScale = scale.clamp(0.8, 1.5);
    await _saveDouble(_keyFontScale, _fontScale);
    notifyListeners();
  }

  // ==========================================================================
  // 缓存管理
  // ==========================================================================

  /// 计算应用缓存大小（MB）
  Future<void> calculateCacheSize() async {
    if (_cacheCalculating) return;
    _cacheCalculating = true;
    notifyListeners();

    try {
      double totalBytes = 0;

      // 临时目录
      try {
        final tempDir = await getTemporaryDirectory();
        totalBytes += await _dirSize(tempDir);
      } catch (_) {}

      // 应用支持目录（图片缓存等）
      try {
        final supportDir = await getApplicationSupportDirectory();
        totalBytes += await _dirSize(supportDir);
      } catch (_) {}

      // 文档目录
      try {
        final docDir = await getApplicationDocumentsDirectory();
        totalBytes += await _dirSize(docDir);
      } catch (_) {}

      _cacheSizeMB = totalBytes / (1024 * 1024);
    } catch (_) {
      _cacheSizeMB = 0;
    }

    _cacheCalculating = false;
    notifyListeners();
  }

  /// 递归计算目录大小（字节）
  Future<int> _dirSize(Directory dir) async {
    int total = 0;
    try {
      if (!await dir.exists()) return 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          try {
            total += await entity.length();
          } catch (_) {}
        }
      }
    } catch (_) {}
    return total;
  }

  /// 清除应用缓存
  Future<bool> clearCache() async {
    try {
      // 清除临时目录
      try {
        final tempDir = await getTemporaryDirectory();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
          await tempDir.create(recursive: true);
        }
      } catch (_) {}

      // 清除图片缓存目录（cached_network_image）
      try {
        final cacheDir = await getTemporaryDirectory();
        final imgCacheDir = Directory('${cacheDir.path}/libCachedImageData');
        if (await imgCacheDir.exists()) {
          await imgCacheDir.delete(recursive: true);
        }
      } catch (_) {}

      _cacheSizeMB = 0;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================================================
  // 重置所有设置为默认值
  // ==========================================================================
  Future<void> resetToDefaults() async {
    _soundEnabled = true;
    _vibrationEnabled = true;
    _notificationEnabled = true;
    _darkMode = false;
    _language = AppLanguage.system;
    _autoPlayVideo = false;
    _showThinkContent = true;
    _messagePreview = true;
    _fontScale = 1.0;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySoundEnabled);
      await prefs.remove(_keyVibrationEnabled);
      await prefs.remove(_keyNotificationEnabled);
      await prefs.remove(_keyDarkMode);
      await prefs.remove(_keyLanguage);
      await prefs.remove(_keyAutoPlayVideo);
      await prefs.remove(_keyShowThinkContent);
      await prefs.remove(_keyMessagePreview);
      await prefs.remove(_keyFontScale);
    } catch (_) {}

    notifyListeners();
  }

  // ==========================================================================
  // 内部持久化工具
  // ==========================================================================

  Future<void> _saveBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
  }

  Future<void> _saveString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }

  Future<void> _saveDouble(String key, double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(key, value);
    } catch (_) {}
  }
}
