/// ============================================================================
/// MascotMood —— 吉祥物心情数据模型
///
/// 承载桌面吉祥物的心情状态、好感度、互动记录以及已解锁表情。
/// 心情会随时间和互动变化，影响吉祥物的展示动画与对话内容。
/// ============================================================================

/// 吉祥物心情类型枚举
enum MoodType {
  /// 开心
  happy,

  /// 平静
  calm,

  /// 困倦
  sleepy,

  /// 兴奋
  excited,

  /// 害羞
  shy,

  /// 生气
  angry,

  /// 悲伤
  sad,

  /// 惊讶
  surprised,

  /// 爱意
  love,
}

/// MoodType 枚举的字符串扩展
extension MoodTypeExtension on MoodType {
  String get value {
    switch (this) {
      case MoodType.happy:
        return 'happy';
      case MoodType.calm:
        return 'calm';
      case MoodType.sleepy:
        return 'sleepy';
      case MoodType.excited:
        return 'excited';
      case MoodType.shy:
        return 'shy';
      case MoodType.angry:
        return 'angry';
      case MoodType.sad:
        return 'sad';
      case MoodType.surprised:
        return 'surprised';
      case MoodType.love:
        return 'love';
    }
  }

  /// 中文显示名称
  String get label {
    switch (this) {
      case MoodType.happy:
        return '开心';
      case MoodType.calm:
        return '平静';
      case MoodType.sleepy:
        return '困倦';
      case MoodType.excited:
        return '兴奋';
      case MoodType.shy:
        return '害羞';
      case MoodType.angry:
        return '生气';
      case MoodType.sad:
        return '悲伤';
      case MoodType.surprised:
        return '惊讶';
      case MoodType.love:
        return '喜爱';
    }
  }

  static MoodType fromString(String? mood) {
    switch (mood) {
      case 'happy':
        return MoodType.happy;
      case 'calm':
        return MoodType.calm;
      case 'sleepy':
        return MoodType.sleepy;
      case 'excited':
        return MoodType.excited;
      case 'shy':
        return MoodType.shy;
      case 'angry':
        return MoodType.angry;
      case 'sad':
        return MoodType.sad;
      case 'surprised':
        return MoodType.surprised;
      case 'love':
        return MoodType.love;
      default:
        return MoodType.calm;
    }
  }
}

/// 吉祥物心情数据模型
class MascotMood {
  /// 当前心情类型
  MoodType moodType;

  /// 好感度（0-100）
  int affection;

  /// 最后互动时间
  DateTime lastInteraction;

  /// 已解锁的表情标识列表
  List<String> unlockedExpressions;

  /// 当前心情的强度（0.0-1.0，影响动画幅度）
  double moodIntensity;

  /// 连续互动天数
  int streakDays;

  /// 今日互动次数
  int todayInteractionCount;

  /// 心情变化的原因描述
  String? moodReason;

  MascotMood({
    this.moodType = MoodType.calm,
    this.affection = 0,
    DateTime? lastInteraction,
    List<String>? unlockedExpressions,
    this.moodIntensity = 0.5,
    this.streakDays = 0,
    this.todayInteractionCount = 0,
    this.moodReason,
  })  : lastInteraction = lastInteraction ?? DateTime.now(),
        unlockedExpressions = unlockedExpressions ?? ['default'];

  /// 从 JSON 反序列化
  factory MascotMood.fromJson(Map<String, dynamic> json) {
    return MascotMood(
      moodType: MoodTypeExtension.fromString(json['mood_type']?.toString()),
      affection: (json['affection'] as num?)?.toInt() ?? 0,
      lastInteraction: json['last_interaction'] != null
          ? DateTime.tryParse(json['last_interaction'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      unlockedExpressions: (json['unlocked_expressions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['default'],
      moodIntensity: (json['mood_intensity'] as num?)?.toDouble() ?? 0.5,
      streakDays: (json['streak_days'] as num?)?.toInt() ?? 0,
      todayInteractionCount:
          (json['today_interaction_count'] as num?)?.toInt() ?? 0,
      moodReason: json['mood_reason']?.toString(),
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'mood_type': moodType.value,
      'affection': affection,
      'last_interaction': lastInteraction.toIso8601String(),
      'unlocked_expressions': unlockedExpressions,
      'mood_intensity': moodIntensity,
      'streak_days': streakDays,
      'today_interaction_count': todayInteractionCount,
      'mood_reason': moodReason,
    };
  }

  /// 默认初始心情
  factory MascotMood.initial() {
    return MascotMood(
      moodType: MoodType.calm,
      affection: 10,
      moodIntensity: 0.5,
      unlockedExpressions: ['default', 'happy'],
    );
  }

  /// 好感度等级
  int get affectionLevel {
    if (affection >= 90) return 5;
    if (affection >= 70) return 4;
    if (affection >= 50) return 3;
    if (affection >= 30) return 2;
    if (affection >= 10) return 1;
    return 0;
  }

  /// 好感度等级名称
  String get affectionLevelName {
    switch (affectionLevel) {
      case 5:
        return '挚友';
      case 4:
        return '亲密';
      case 3:
        return '熟悉';
      case 2:
        return '认识';
      case 1:
        return '初识';
      default:
        return '陌生';
    }
  }

  /// 好感度进度百分比（0.0-1.0）
  double get affectionPercent => (affection / 100).clamp(0.0, 1.0);

  /// 增加好感度（自动限制在 0-100）
  void addAffection(int delta) {
    affection = (affection + delta).clamp(0, 100);
    _checkUnlockExpressions();
  }

  /// 检查并解锁新表情
  void _checkUnlockExpressions() {
    final unlockMap = {
      20: 'shy',
      40: 'excited',
      60: 'love',
      80: 'surprised',
      95: 'angry',
    };
    unlockMap.forEach((threshold, expression) {
      if (affection >= threshold && !unlockedExpressions.contains(expression)) {
        unlockedExpressions.add(expression);
      }
    });
  }

  /// 判断表情是否已解锁
  bool isExpressionUnlocked(String expression) {
    return unlockedExpressions.contains(expression);
  }

  /// 记录一次互动
  void interact({MoodType? newMood, int affectionDelta = 1}) {
    lastInteraction = DateTime.now();
    todayInteractionCount++;
    if (newMood != null) {
      moodType = newMood;
      moodIntensity = 1.0;
    }
    addAffection(affectionDelta);
  }

  /// 根据时间自然衰减心情强度
  void decayMood() {
    final hoursSinceInteraction =
        DateTime.now().difference(lastInteraction).inHours;
    if (hoursSinceInteraction > 2) {
      moodIntensity = (moodIntensity - 0.1).clamp(0.0, 1.0);
      if (moodIntensity <= 0.2) {
        moodType = MoodType.calm;
      }
    }
    // 深夜自动切换为困倦
    final hour = DateTime.now().hour;
    if (hour >= 23 || hour <= 5) {
      moodType = MoodType.sleepy;
    }
  }

  /// 复制一份
  MascotMood copyWith({
    MoodType? moodType,
    int? affection,
    DateTime? lastInteraction,
    List<String>? unlockedExpressions,
    double? moodIntensity,
    int? streakDays,
    int? todayInteractionCount,
    String? moodReason,
  }) {
    return MascotMood(
      moodType: moodType ?? this.moodType,
      affection: affection ?? this.affection,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      unlockedExpressions: unlockedExpressions ?? this.unlockedExpressions,
      moodIntensity: moodIntensity ?? this.moodIntensity,
      streakDays: streakDays ?? this.streakDays,
      todayInteractionCount:
          todayInteractionCount ?? this.todayInteractionCount,
      moodReason: moodReason ?? this.moodReason,
    );
  }
}
