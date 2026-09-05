class UserModel {
  final String id;
  final String email;
  final String nickname;
  final String token;
  final String? avatar;
  final String? githubId;
  final int dailyPoints;
  final int premiumPoints;
  final String svipType;
  final String? svipExpire;
  final String agentStatus;
  final bool githubBound;
  final bool oobeCompleted;
  final String? qq;
  final String? birthday;

  UserModel({
    required this.id,
    required this.email,
    required this.nickname,
    required this.token,
    this.avatar,
    this.githubId,
    this.dailyPoints = 90000000,
    this.premiumPoints = 0,
    this.svipType = 'none',
    this.svipExpire,
    this.agentStatus = 'none',
    this.githubBound = false,
    this.oobeCompleted = false,
    this.qq,
    this.birthday,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      nickname: json['nickname'] ?? '',
      token: json['token'] ?? '',
      avatar: json['avatar'],
      githubId: json['github_id'],
      dailyPoints: json['daily_points'] ?? 90000000,
      premiumPoints: json['premium_points'] ?? 0,
      svipType: json['svip_type'] ?? 'none',
      svipExpire: json['svip_expire'],
      agentStatus: json['agent_status'] ?? 'none',
      githubBound: json['github_bound'] ?? false,
      oobeCompleted: json['oobe_completed'] ?? false,
      qq: json['qq'],
      birthday: json['birthday'],
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': id,
    'email': email,
    'nickname': nickname,
    'token': token,
    'avatar': avatar,
    'daily_points': dailyPoints,
    'premium_points': premiumPoints,
    'svip_type': svipType,
    'agent_status': agentStatus,
    'github_bound': githubBound,
  };
}
