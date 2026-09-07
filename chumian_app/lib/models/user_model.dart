/// VIP 状态枚举
enum VipStatus { none, svip, lifetime }

/// VIP 状态扩展
extension VipStatusExtension on VipStatus {
  String get value {
    switch (this) {
      case VipStatus.none:
        return 'none';
      case VipStatus.svip:
        return 'svip';
      case VipStatus.lifetime:
        return 'lifetime';
    }
  }

  static VipStatus fromString(String? status) {
    switch (status) {
      case 'svip':
        return VipStatus.svip;
      case 'lifetime':
        return VipStatus.lifetime;
      default:
        return VipStatus.none;
    }
  }

  /// 是否为付费会员
  bool get isVip => this != VipStatus.none;
}

/// 用户数据模型
///
/// 承载当前登录用户的完整档案信息，包括身份凭证字段、
/// 积分余额、会员状态以及账号封禁标记。
class User {
  /// 用户唯一标识
  final String id;

  /// 邮箱（登录凭证之一）
  final String? email;

  /// 用户名（登录凭证之一）
  final String? username;

  /// 昵称（展示用）
  final String nickname;

  /// 头像 URL
  final String? avatar;

  /// 每日可用积分余额
  final int dailyPoints;

  /// 是否已完成新手引导（OOBE）
  final bool oobeCompleted;

  /// 账号是否被封禁
  final bool isBanned;

  /// 账号创建时间
  final DateTime? createdAt;

  /// VIP 会员状态
  final VipStatus vipStatus;

  User({
    required this.id,
    this.email,
    this.username,
    this.nickname = '',
    this.avatar,
    this.dailyPoints = 0,
    this.oobeCompleted = false,
    this.isBanned = false,
    this.createdAt,
    this.vipStatus = VipStatus.none,
  });

  /// 从 JSON 反序列化
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? json['user_id']?.toString() ?? '',
      email: json['email']?.toString(),
      username: json['username']?.toString(),
      nickname: json['nickname']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      dailyPoints: (json['daily_points'] as num?)?.toInt() ??
          (json['points'] as num?)?.toInt() ??
          0,
      oobeCompleted: json['oobe_completed'] == true,
      isBanned: json['is_banned'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      vipStatus: VipStatusExtension.fromString(json['vip_status']?.toString()),
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'nickname': nickname,
      'avatar': avatar,
      'daily_points': dailyPoints,
      'oobe_completed': oobeCompleted,
      'is_banned': isBanned,
      'created_at': createdAt?.toIso8601String(),
      'vip_status': vipStatus.value,
    };
  }

  /// 展示用名称：优先昵称，其次用户名，最后邮箱
  String get displayName {
    if (nickname.isNotEmpty) return nickname;
    if (username != null && username!.isNotEmpty) return username!;
    if (email != null && email!.isNotEmpty) return email!;
    return '用户';
  }

  /// 是否为 SVIP 及以上
  bool get isSvip =>
      vipStatus == VipStatus.svip || vipStatus == VipStatus.lifetime;

  /// 复制并修改部分字段
  User copyWith({
    String? id,
    String? email,
    String? username,
    String? nickname,
    String? avatar,
    int? dailyPoints,
    bool? oobeCompleted,
    bool? isBanned,
    DateTime? createdAt,
    VipStatus? vipStatus,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      dailyPoints: dailyPoints ?? this.dailyPoints,
      oobeCompleted: oobeCompleted ?? this.oobeCompleted,
      isBanned: isBanned ?? this.isBanned,
      createdAt: createdAt ?? this.createdAt,
      vipStatus: vipStatus ?? this.vipStatus,
    );
  }
}
