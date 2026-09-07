/// ============================================================================
/// GameScore —— 游戏分数数据模型
///
/// 承载单局游戏的完整分数信息，包括游戏类型、得分、关卡、
/// 耗时、创建时间以及历史最佳分数。支持本地持久化与排行榜排序。
/// ============================================================================

/// 游戏类型枚举
enum GameType {
  /// 记忆翻牌
  memory,

  /// 2048
  game2048,

  /// 贪吃蛇
  snake,

  /// 井字棋
  ticTacToe,

  /// 消消乐
  matchThree,

  /// 数独
  sudoku,

  /// 其他
  other,
}

/// GameType 枚举的字符串扩展
extension GameTypeExtension on GameType {
  /// 转为存储用字符串
  String get value {
    switch (this) {
      case GameType.memory:
        return 'memory';
      case GameType.game2048:
        return 'game2048';
      case GameType.snake:
        return 'snake';
      case GameType.ticTacToe:
        return 'tic_tac_toe';
      case GameType.matchThree:
        return 'match_three';
      case GameType.sudoku:
        return 'sudoku';
      case GameType.other:
        return 'other';
    }
  }

  /// 游戏显示名称
  String get label {
    switch (this) {
      case GameType.memory:
        return '记忆翻牌';
      case GameType.game2048:
        return '2048';
      case GameType.snake:
        return '贪吃蛇';
      case GameType.ticTacToe:
        return '井字棋';
      case GameType.matchThree:
        return '消消乐';
      case GameType.sudoku:
        return '数独';
      case GameType.other:
        return '其他游戏';
    }
  }

  static GameType fromString(String? type) {
    switch (type) {
      case 'memory':
        return GameType.memory;
      case 'game2048':
        return GameType.game2048;
      case 'snake':
        return GameType.snake;
      case 'tic_tac_toe':
        return GameType.ticTacToe;
      case 'match_three':
        return GameType.matchThree;
      case 'sudoku':
        return GameType.sudoku;
      default:
        return GameType.other;
    }
  }
}

/// 游戏分数数据模型
class GameScore {
  /// 分数记录唯一标识
  final String id;

  /// 游戏类型
  final GameType gameType;

  /// 本局得分
  final int score;

  /// 到达关卡
  final int level;

  /// 游戏耗时（秒）
  final int duration;

  /// 创建时间
  final DateTime createdAt;

  /// 该游戏类型的历史最佳分数（冗余字段，便于排序展示）
  final int bestScore;

  GameScore({
    required this.id,
    required this.gameType,
    required this.score,
    this.level = 1,
    this.duration = 0,
    DateTime? createdAt,
    this.bestScore = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 从 JSON 反序列化
  factory GameScore.fromJson(Map<String, dynamic> json) {
    return GameScore(
      id: json['id']?.toString() ?? '',
      gameType: GameTypeExtension.fromString(json['game_type']?.toString()),
      score: (json['score'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      bestScore: (json['best_score'] as num?)?.toInt() ?? 0,
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'game_type': gameType.value,
      'score': score,
      'level': level,
      'duration': duration,
      'created_at': createdAt.toIso8601String(),
      'best_score': bestScore,
    };
  }

  /// 创建一条新的游戏分数记录
  factory GameScore.create({
    required GameType gameType,
    required int score,
    int level = 1,
    int duration = 0,
    int bestScore = 0,
  }) {
    return GameScore(
      id: 'gs_${DateTime.now().microsecondsSinceEpoch}',
      gameType: gameType,
      score: score,
      level: level,
      duration: duration,
      bestScore: bestScore,
    );
  }

  /// 格式化耗时为 mm:ss
  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 是否打破最佳记录
  bool get isNewRecord => score > 0 && score >= bestScore && bestScore > 0;

  /// 分数评级（S/A/B/C/D）
  String get rank {
    if (score >= 10000) return 'S';
    if (score >= 5000) return 'A';
    if (score >= 2000) return 'B';
    if (score >= 500) return 'C';
    return 'D';
  }

  /// 复制一份游戏分数
  GameScore copyWith({
    String? id,
    GameType? gameType,
    int? score,
    int? level,
    int? duration,
    DateTime? createdAt,
    int? bestScore,
  }) {
    return GameScore(
      id: id ?? this.id,
      gameType: gameType ?? this.gameType,
      score: score ?? this.score,
      level: level ?? this.level,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      bestScore: bestScore ?? this.bestScore,
    );
  }
}
