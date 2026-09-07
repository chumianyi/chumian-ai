import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chumian_ai/models/game_score.dart';

/// ============================================================================
/// GameService —— 游戏分数管理服务
///
/// 基于 SharedPreferences 提供游戏分数的本地持久化能力，
/// 支持分数记录、排行榜查询、历史最佳维护、成就检测与分数上报。
/// ============================================================================
class GameService {
  // ===== 存储键 =====
  static const String _prefixScore = 'game_score_';
  static const String _keyBestScores = 'game_best_scores';
  static const String _keyAchievements = 'game_achievements';
  static const String _keyTotalPlays = 'game_total_plays';
  static const String _keyTotalScore = 'game_total_score';

  /// 单例实例
  static final GameService _instance = GameService._internal();
  factory GameService() => _instance;
  GameService._internal();

  SharedPreferences? _prefs;

  /// 初始化
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _ensurePrefs async {
    if (_prefs == null) await init();
    return _prefs!;
  }

  // ==========================================================================
  // 分数记录
  // ==========================================================================

  /// 保存一局游戏分数（自动更新最佳分数）
  Future<GameScore> submitScore({
    required GameType gameType,
    required int score,
    int level = 1,
    int duration = 0,
  }) async {
    final prefs = await _ensurePrefs;
    final bestScore = await getBestScore(gameType);
    final isNewBest = score > bestScore;

    final record = GameScore.create(
      gameType: gameType,
      score: score,
      level: level,
      duration: duration,
      bestScore: isNewBest ? score : bestScore,
    );

    // 保存单条记录
    await prefs.setString(
      '$_prefixScore${record.id}',
      jsonEncode(record.toJson()),
    );

    // 更新最佳分数
    if (isNewBest) {
      await _updateBestScore(gameType, score);
    }

    // 更新统计
    await _incrementTotalPlays();
    await _addTotalScore(score);

    // 检测成就
    await _checkAchievements(gameType, score, level);

    return record;
  }

  /// 获取单条分数记录
  Future<GameScore?> getScore(String id) async {
    final prefs = await _ensurePrefs;
    final raw = prefs.getString('$_prefixScore$id');
    if (raw == null || raw.isEmpty) return null;
    try {
      return GameScore.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return null;
    }
  }

  /// 获取某游戏类型的所有分数记录（按分数倒序）
  Future<List<GameScore>> getScoresByType(GameType gameType,
      {int limit = 50}) async {
    final prefs = await _ensurePrefs;
    final scores = <GameScore>[];
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_prefixScore)) {
        final raw = prefs.getString(key);
        if (raw != null && raw.isNotEmpty) {
          try {
            final score = GameScore.fromJson(
                Map<String, dynamic>.from(jsonDecode(raw) as Map));
            if (score.gameType == gameType) {
              scores.add(score);
            }
          } catch (_) {
            // 跳过损坏数据
          }
        }
      }
    }
    scores.sort((a, b) => b.score.compareTo(a.score));
    if (scores.length > limit) {
      return scores.sublist(0, limit);
    }
    return scores;
  }

  /// 获取所有游戏的排行榜（按分数倒序，取前 N）
  Future<List<GameScore>> getLeaderboard({int limit = 100}) async {
    final prefs = await _ensurePrefs;
    final scores = <GameScore>[];
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_prefixScore)) {
        final raw = prefs.getString(key);
        if (raw != null && raw.isNotEmpty) {
          try {
            scores.add(GameScore.fromJson(
                Map<String, dynamic>.from(jsonDecode(raw) as Map)));
          } catch (_) {}
        }
      }
    }
    scores.sort((a, b) => b.score.compareTo(a.score));
    if (scores.length > limit) {
      return scores.sublist(0, limit);
    }
    return scores;
  }

  /// 删除单条分数记录
  Future<bool> deleteScore(String id) async {
    final prefs = await _ensurePrefs;
    return prefs.remove('$_prefixScore$id');
  }

  /// 清除某游戏类型的所有记录
  Future<int> clearScoresByType(GameType gameType) async {
    final prefs = await _ensurePrefs;
    int count = 0;
    final keysToRemove = <String>[];
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_prefixScore)) {
        final raw = prefs.getString(key);
        if (raw != null) {
          try {
            final score = GameScore.fromJson(
                Map<String, dynamic>.from(jsonDecode(raw) as Map));
            if (score.gameType == gameType) {
              keysToRemove.add(key);
            }
          } catch (_) {}
        }
      }
    }
    for (final key in keysToRemove) {
      await prefs.remove(key);
      count++;
    }
    return count;
  }

  // ==========================================================================
  // 最佳分数
  // ==========================================================================

  /// 获取某游戏类型的历史最佳分数
  Future<int> getBestScore(GameType gameType) async {
    final prefs = await _ensurePrefs;
    final raw = prefs.getString(_keyBestScores);
    if (raw == null || raw.isEmpty) return 0;
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return (map[gameType.value] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// 获取所有游戏类型的最佳分数字典
  Future<Map<String, int>> getAllBestScores() async {
    final prefs = await _ensurePrefs;
    final raw = prefs.getString(_keyBestScores);
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return map.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  Future<void> _updateBestScore(GameType gameType, int score) async {
    final prefs = await _ensurePrefs;
    final all = await getAllBestScores();
    all[gameType.value] = score;
    await prefs.setString(_keyBestScores, jsonEncode(all));
  }

  // ==========================================================================
  // 成就系统
  // ==========================================================================

  /// 成就定义
  static const Map<String, Map<String, dynamic>> _achievementDefs = {
    'first_play': {'name': '初次体验', 'desc': '完成第一局游戏', 'icon': '🎮'},
    'score_1000': {'name': '千分达人', 'desc': '单局得分达到 1000', 'icon': '🏆'},
    'score_5000': {'name': '五千勇士', 'desc': '单局得分达到 5000', 'icon': '🥇'},
    'score_10000': {'name': '万分王者', 'desc': '单局得分达到 10000', 'icon': '👑'},
    'level_5': {'name': '进阶玩家', 'desc': '到达第 5 关', 'icon': '⭐'},
    'level_10': {'name': '高手玩家', 'desc': '到达第 10 关', 'icon': '🌟'},
    'play_10': {'name': '游戏爱好者', 'desc': '累计游玩 10 局', 'icon': '🎯'},
    'play_50': {'name': '游戏狂人', 'desc': '累计游玩 50 局', 'icon': '🔥'},
    'total_10000': {'name': '万分积累', 'desc': '累计得分达到 10000', 'icon': '💎'},
  };

  /// 获取已解锁成就列表
  Future<List<Map<String, dynamic>>> getUnlockedAchievements() async {
    final prefs = await _ensurePrefs;
    final raw = prefs.getString(_keyAchievements);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 获取所有成就（含未解锁状态）
  Future<List<Map<String, dynamic>>> getAllAchievements() async {
    final unlocked = await getUnlockedAchievements();
    final unlockedIds = unlocked.map((e) => e['id']).toSet();
    final result = <Map<String, dynamic>>[];
    _achievementDefs.forEach((id, def) {
      result.add({
        'id': id,
        'name': def['name'],
        'desc': def['desc'],
        'icon': def['icon'],
        'unlocked': unlockedIds.contains(id),
        'unlocked_at': unlocked
            .firstWhere((e) => e['id'] == id,
                orElse: () => {'unlocked_at': null})['unlocked_at'],
      });
    });
    return result;
  }

  Future<void> _checkAchievements(
      GameType gameType, int score, int level) async {
    final unlocked = await getUnlockedAchievements();
    final unlockedIds = unlocked.map((e) => e['id']).toSet();
    final totalPlays = await getTotalPlays();
    final totalScore = await getTotalScore();

    final newAchievements = <Map<String, dynamic>>[];

    void tryUnlock(String id) {
      if (!unlockedIds.contains(id) && _achievementDefs.containsKey(id)) {
        newAchievements.add({
          'id': id,
          'unlocked_at': DateTime.now().toIso8601String(),
        });
      }
    }

    if (totalPlays >= 1) tryUnlock('first_play');
    if (score >= 1000) tryUnlock('score_1000');
    if (score >= 5000) tryUnlock('score_5000');
    if (score >= 10000) tryUnlock('score_10000');
    if (level >= 5) tryUnlock('level_5');
    if (level >= 10) tryUnlock('level_10');
    if (totalPlays >= 10) tryUnlock('play_10');
    if (totalPlays >= 50) tryUnlock('play_50');
    if (totalScore >= 10000) tryUnlock('total_10000');

    if (newAchievements.isNotEmpty) {
      final prefs = await _ensurePrefs;
      final all = [...unlocked, ...newAchievements];
      await prefs.setString(_keyAchievements, jsonEncode(all));
    }
  }

  // ==========================================================================
  // 统计
  // ==========================================================================

  /// 获取累计游玩局数
  Future<int> getTotalPlays() async {
    final prefs = await _ensurePrefs;
    return prefs.getInt(_keyTotalPlays) ?? 0;
  }

  /// 获取累计总分
  Future<int> getTotalScore() async {
    final prefs = await _ensurePrefs;
    return prefs.getInt(_keyTotalScore) ?? 0;
  }

  Future<void> _incrementTotalPlays() async {
    final prefs = await _ensurePrefs;
    final current = prefs.getInt(_keyTotalPlays) ?? 0;
    await prefs.setInt(_keyTotalPlays, current + 1);
  }

  Future<void> _addTotalScore(int score) async {
    final prefs = await _ensurePrefs;
    final current = prefs.getInt(_keyTotalScore) ?? 0;
    await prefs.setInt(_keyTotalScore, current + score);
  }

  /// 获取某游戏类型的游玩次数
  Future<int> getPlayCountByType(GameType gameType) async {
    final scores = await getScoresByType(gameType, limit: 10000);
    return scores.length;
  }

  /// 清除所有游戏数据（谨慎使用）
  Future<bool> clearAll() async {
    final prefs = await _ensurePrefs;
    final keysToRemove = prefs
        .getKeys()
        .where((k) =>
            k.startsWith(_prefixScore) ||
            k == _keyBestScores ||
            k == _keyAchievements ||
            k == _keyTotalPlays ||
            k == _keyTotalScore)
        .toList();
    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
    return true;
  }
}
