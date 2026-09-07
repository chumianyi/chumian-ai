/// ============================================================================
/// Task —— 任务/成就数据模型
///
/// 承载每日任务与成就系统的完整信息，包括任务标题、描述、
/// 奖励积分、进度、目标值以及完成状态。支持每日任务与
/// 长期成就两种类型。
/// ============================================================================

/// 任务类型枚举
enum TaskType {
  /// 每日任务
  daily,

  /// 成就任务
  achievement,
}

/// TaskType 枚举的字符串扩展
extension TaskTypeExtension on TaskType {
  String get value {
    switch (this) {
      case TaskType.daily:
        return 'daily';
      case TaskType.achievement:
        return 'achievement';
    }
  }

  String get label {
    switch (this) {
      case TaskType.daily:
        return '每日任务';
      case TaskType.achievement:
        return '成就';
    }
  }

  static TaskType fromString(String? type) {
    switch (type) {
      case 'daily':
        return TaskType.daily;
      case 'achievement':
        return TaskType.achievement;
      default:
        return TaskType.daily;
    }
  }
}

/// 任务数据模型
class Task {
  /// 任务唯一标识
  final String id;

  /// 任务标题
  final String title;

  /// 任务描述
  final String description;

  /// 完成奖励（积分）
  final int reward;

  /// 当前进度
  int progress;

  /// 目标值
  final int target;

  /// 是否已完成
  bool isCompleted;

  /// 是否已领取奖励
  bool isClaimed;

  /// 任务类型
  final TaskType type;

  /// 任务图标标识（用于 UI 展示）
  final String iconKey;

  /// 任务创建时间
  final DateTime createdAt;

  /// 任务完成时间
  DateTime? completedAt;

  /// 每日任务的日期标识（格式：yyyy-MM-dd）
  final String? dateKey;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.reward = 0,
    this.progress = 0,
    this.target = 1,
    this.isCompleted = false,
    this.isClaimed = false,
    this.type = TaskType.daily,
    this.iconKey = 'task_default',
    DateTime? createdAt,
    this.completedAt,
    this.dateKey,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 从 JSON 反序列化
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      reward: (json['reward'] as num?)?.toInt() ?? 0,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      target: (json['target'] as num?)?.toInt() ?? 1,
      isCompleted: json['is_completed'] == true,
      isClaimed: json['is_claimed'] == true,
      type: TaskTypeExtension.fromString(json['type']?.toString()),
      iconKey: json['icon_key']?.toString() ?? 'task_default',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      dateKey: json['date_key']?.toString(),
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'reward': reward,
      'progress': progress,
      'target': target,
      'is_completed': isCompleted,
      'is_claimed': isClaimed,
      'type': type.value,
      'icon_key': iconKey,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'date_key': dateKey,
    };
  }

  /// 创建一个每日任务
  factory Task.daily({
    required String id,
    required String title,
    String description = '',
    int reward = 10,
    int target = 1,
    String iconKey = 'task_default',
  }) {
    final now = DateTime.now();
    final dateKey = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return Task(
      id: id,
      title: title,
      description: description,
      reward: reward,
      target: target,
      type: TaskType.daily,
      iconKey: iconKey,
      dateKey: dateKey,
    );
  }

  /// 创建一个成就任务
  factory Task.achievement({
    required String id,
    required String title,
    String description = '',
    int reward = 50,
    int target = 1,
    String iconKey = 'achievement_default',
  }) {
    return Task(
      id: id,
      title: title,
      description: description,
      reward: reward,
      target: target,
      type: TaskType.achievement,
      iconKey: iconKey,
    );
  }

  /// 进度百分比（0.0 - 1.0）
  double get progressPercent {
    if (target <= 0) return 0.0;
    final p = progress / target;
    return p.clamp(0.0, 1.0);
  }

  /// 进度显示文本，如 "3/10"
  String get progressText => '$progress/$target';

  /// 是否可以领取奖励（已完成且未领取）
  bool get canClaim => isCompleted && !isClaimed;

  /// 是否为进行中（未完成且有进度）
  bool get inProgress => !isCompleted && progress > 0;

  /// 增加进度，自动标记完成
  void addProgress(int delta) {
    if (isCompleted) return;
    progress += delta;
    if (progress >= target) {
      progress = target;
      isCompleted = true;
      completedAt = DateTime.now();
    }
  }

  /// 复制一份任务
  Task copyWith({
    String? id,
    String? title,
    String? description,
    int? reward,
    int? progress,
    int? target,
    bool? isCompleted,
    bool? isClaimed,
    TaskType? type,
    String? iconKey,
    DateTime? createdAt,
    DateTime? completedAt,
    String? dateKey,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      reward: reward ?? this.reward,
      progress: progress ?? this.progress,
      target: target ?? this.target,
      isCompleted: isCompleted ?? this.isCompleted,
      isClaimed: isClaimed ?? this.isClaimed,
      type: type ?? this.type,
      iconKey: iconKey ?? this.iconKey,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      dateKey: dateKey ?? this.dateKey,
    );
  }
}
