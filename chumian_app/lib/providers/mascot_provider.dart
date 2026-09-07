import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chumian_ai/models/mascot_mood.dart';

/// ============================================================================
/// MascotProvider —— 吉祥物状态管理 Provider
///
/// 职责：
///   1. 管理吉祥物心情状态
///   2. 好感度系统
///   3. 互动记录
///   4. 表情解锁
///   5. 本地存储持久化
/// ============================================================================
class MascotProvider extends ChangeNotifier {
  /// 存储键
  static const String _storageKey = 'mascot_mood';

  /// 吉祥物心情状态
  MascotMood _mood = MascotMood.initial();

  /// 是否加载完成
  bool _isLoaded = false;

  /// 互动记录（最近 50 条）
  final List<MascotInteraction> _interactions = [];

  /// 今日互动次数
  int get todayInteractions => _mood.todayInteractionCount;

  /// 连续互动天数
  int get streakDays => _mood.streakDays;

  // ===== Getters =====
  MascotMood get mood => _mood;
  bool get isLoaded => _isLoaded;
  MoodType get currentMood => _mood.moodType;
  int get affection => _mood.affection;
  int get affectionLevel => _mood.affectionLevel;
  String get affectionLevelName => _mood.affectionLevelName;
  double get affectionPercent => _mood.affectionPercent;
  double get moodIntensity => _mood.moodIntensity;
  List<String> get unlockedExpressions =>
      List.unmodifiable(_mood.unlockedExpressions);
  List<MascotInteraction> get interactions =>
      List.unmodifiable(_interactions);

  // ==========================================================================
  // 初始化
  // ==========================================================================

  /// 初始化：从本地存储加载状态
  Future<void> init() async {
    await _loadMood();
    await _loadInteractions();
    _checkDailyReset();
    _isLoaded = true;
    notifyListeners();
  }

  /// 加载心情状态
  Future<void> _loadMood() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        _mood = MascotMood.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map));
      }
    } catch (_) {
      _mood = MascotMood.initial();
    }
  }

  /// 加载互动记录
  Future<void> _loadInteractions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('${_storageKey}_interactions');
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        _interactions.clear();
        _interactions.addAll(list
            .map((e) =>
                MascotInteraction.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList());
      }
    } catch (_) {}
  }

  /// 保存心情状态
  Future<void> _saveMood() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_mood.toJson()));
    } catch (_) {}
  }

  /// 保存互动记录
  Future<void> _saveInteractions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${_storageKey}_interactions',
        jsonEncode(_interactions.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  /// 检查每日重置
  void _checkDailyReset() {
    final now = DateTime.now();
    final last = _mood.lastInteraction;
    final isSameDay = now.year == last.year &&
        now.month == last.month &&
        now.day == last.day;

    if (!isSameDay) {
      // 新的一天，重置今日互动次数
      _mood.todayInteractionCount = 0;

      // 检查连续互动天数
      final yesterday = now.subtract(const Duration(days: 1));
      final isYesterday = last.year == yesterday.year &&
          last.month == yesterday.month &&
          last.day == yesterday.day;
      if (!isYesterday) {
        _mood.streakDays = 0;
      }
    }
  }

  // ==========================================================================
  // 互动操作
  // ==========================================================================

  /// 互动（通用）
  Future<void> interact({
    MoodType? newMood,
    int affectionDelta = 1,
    String? action,
  }) async {
    _mood.interact(
      newMood: newMood,
      affectionDelta: affectionDelta,
    );

    // 记录互动
    _interactions.insert(
      0,
      MascotInteraction(
        action: action ?? 'interact',
        moodAfter: _mood.moodType,
        affectionChange: affectionDelta,
        timestamp: DateTime.now(),
      ),
    );
    // 限制记录数量
    if (_interactions.length > 50) {
      _interactions.removeRange(50, _interactions.length);
    }

    // 更新连续天数
    _updateStreak();

    await _saveMood();
    await _saveInteractions();
    notifyListeners();
  }

  /// 抚摸互动
  Future<void> pet() async {
    await interact(
      newMood: MoodType.happy,
      affectionDelta: 2,
      action: 'pet',
    );
  }

  /// 喂食互动
  Future<void> feed() async {
    await interact(
      newMood: MoodType.excited,
      affectionDelta: 3,
      action: 'feed',
    );
  }

  /// 聊天互动
  Future<void> chat() async {
    await interact(
      newMood: MoodType.happy,
      affectionDelta: 1,
      action: 'chat',
    );
  }

  /// 玩耍互动
  Future<void> play() async {
    await interact(
      newMood: MoodType.excited,
      affectionDelta: 4,
      action: 'play',
    );
  }

  /// 睡觉互动
  Future<void> sleep() async {
    await interact(
      newMood: MoodType.sleepy,
      affectionDelta: 1,
      action: 'sleep',
    );
  }

  // ==========================================================================
  // 心情管理
  // ==========================================================================

  /// 设置心情
  Future<void> setMood(MoodType mood, {double intensity = 1.0}) async {
    _mood.moodType = mood;
    _mood.moodIntensity = intensity.clamp(0.0, 1.0);
    _mood.lastInteraction = DateTime.now();
    await _saveMood();
    notifyListeners();
  }

  /// 自然衰减心情（随时间调用）
  Future<void> decayMood() async {
    _mood.decayMood();
    await _saveMood();
    notifyListeners();
  }

  // ==========================================================================
  // 好感度管理
  // ==========================================================================

  /// 增加好感度
  Future<void> addAffection(int delta) async {
    _mood.addAffection(delta);
    await _saveMood();
    notifyListeners();
  }

  /// 设置好感度
  Future<void> setAffection(int value) async {
    _mood.affection = value.clamp(0, 100);
    _mood.addAffection(0); // 触发解锁检查
    await _saveMood();
    notifyListeners();
  }

  // ==========================================================================
  // 表情管理
  // ==========================================================================

  /// 判断表情是否已解锁
  bool isExpressionUnlocked(String expression) {
    return _mood.isExpressionUnlocked(expression);
  }

  /// 手动解锁表情
  Future<void> unlockExpression(String expression) async {
    if (!_mood.unlockedExpressions.contains(expression)) {
      _mood.unlockedExpressions.add(expression);
      await _saveMood();
      notifyListeners();
    }
  }

  /// 获取所有可解锁表情及解锁条件
  Map<String, int> get expressionUnlockConditions => {
        'default': 0,
        'happy': 0,
        'shy': 20,
        'excited': 40,
        'love': 60,
        'surprised': 80,
        'angry': 95,
        'sleepy': 10,
        'calm': 5,
        'sad': 30,
      };

  /// 获取下一个待解锁表情
  String? get nextUnlockExpression {
    final conditions = expressionUnlockConditions;
    for (final entry in conditions.entries) {
      if (!_mood.unlockedExpressions.contains(entry.key) &&
          _mood.affection < entry.value) {
        return entry.key;
      }
    }
    return null;
  }

  /// 下一个表情解锁所需好感度
  int? get nextUnlockAffection {
    final next = nextUnlockExpression;
    if (next == null) return null;
    return expressionUnlockConditions[next];
  }

  // ==========================================================================
  // 连续天数
  // ==========================================================================

  /// 更新连续互动天数
  void _updateStreak() {
    final now = DateTime.now();
    final last = _mood.lastInteraction;
    final isSameDay = now.year == last.year &&
        now.month == last.month &&
        now.day == last.day;

    if (!isSameDay) {
      final yesterday = now.subtract(const Duration(days: 1));
      final isYesterday = last.year == yesterday.year &&
          last.month == yesterday.month &&
          last.day == yesterday.day;
      if (isYesterday) {
        _mood.streakDays++;
      } else {
        _mood.streakDays = 1;
      }
    }
  }

  // ==========================================================================
  // 统计
  // ==========================================================================

  /// 获取今日互动次数
  int getTodayInteractionCount() {
    final now = DateTime.now();
    return _interactions
        .where((i) =>
            i.timestamp.year == now.year &&
            i.timestamp.month == now.month &&
            i.timestamp.day == now.day)
        .length;
  }

  /// 获取总互动次数
  int get totalInteractions => _interactions.length;

  /// 获取最近 N 天的互动统计
  Map<String, int> getRecentStats(int days) {
    final stats = <String, int>{};
    final now = DateTime.now();
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      stats[key] = _interactions
          .where((interaction) =>
              interaction.timestamp.year == date.year &&
              interaction.timestamp.month == date.month &&
              interaction.timestamp.day == date.day)
          .length;
    }
    return stats;
  }

  // ==========================================================================
  // 重置
  // ==========================================================================

  /// 重置吉祥物状态
  Future<void> reset() async {
    _mood = MascotMood.initial();
    _interactions.clear();
    await _saveMood();
    await _saveInteractions();
    notifyListeners();
  }
}

/// 吉祥物互动记录
class MascotInteraction {
  /// 互动动作类型
  final String action;

  /// 互动后的心情
  final MoodType moodAfter;

  /// 好感度变化
  final int affectionChange;

  /// 互动时间
  final DateTime timestamp;

  MascotInteraction({
    required this.action,
    required this.moodAfter,
    this.affectionChange = 0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory MascotInteraction.fromJson(Map<String, dynamic> json) {
    return MascotInteraction(
      action: json['action']?.toString() ?? 'interact',
      moodAfter: MoodTypeExtension.fromString(json['mood_after']?.toString()),
      affectionChange: (json['affection_change'] as num?)?.toInt() ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'mood_after': moodAfter.value,
      'affection_change': affectionChange,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// 动作显示名称
  String get actionLabel {
    switch (action) {
      case 'pet':
        return '抚摸';
      case 'feed':
        return '喂食';
      case 'chat':
        return '聊天';
      case 'play':
        return '玩耍';
      case 'sleep':
        return '睡觉';
      default:
        return '互动';
    }
  }
}
