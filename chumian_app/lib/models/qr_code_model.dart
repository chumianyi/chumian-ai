/// ============================================================================
/// QrCodeData —— 二维码数据模型
///
/// 承载二维码生成与历史记录的完整信息，包括二维码内容、
/// 类型、创建时间以及自定义颜色。支持文本、URL、WiFi、
/// 联系方式等多种二维码类型。
/// ============================================================================

/// 二维码内容类型枚举
enum QrCodeType {
  /// 纯文本
  text,

  /// URL 链接
  url,

  /// WiFi 配置
  wifi,

  /// 联系方式（vCard）
  contact,

  /// 电话号码
  phone,

  /// 短信
  sms,

  /// 邮箱
  email,

  /// 地理位置
  location,

  /// 事件
  event,
}

/// QrCodeType 枚举的字符串扩展
extension QrCodeTypeExtension on QrCodeType {
  String get value {
    switch (this) {
      case QrCodeType.text:
        return 'text';
      case QrCodeType.url:
        return 'url';
      case QrCodeType.wifi:
        return 'wifi';
      case QrCodeType.contact:
        return 'contact';
      case QrCodeType.phone:
        return 'phone';
      case QrCodeType.sms:
        return 'sms';
      case QrCodeType.email:
        return 'email';
      case QrCodeType.location:
        return 'location';
      case QrCodeType.event:
        return 'event';
    }
  }

  /// 中文显示名称
  String get label {
    switch (this) {
      case QrCodeType.text:
        return '文本';
      case QrCodeType.url:
        return '链接';
      case QrCodeType.wifi:
        return 'WiFi';
      case QrCodeType.contact:
        return '联系方式';
      case QrCodeType.phone:
        return '电话';
      case QrCodeType.sms:
        return '短信';
      case QrCodeType.email:
        return '邮箱';
      case QrCodeType.location:
        return '位置';
      case QrCodeType.event:
        return '事件';
    }
  }

  static QrCodeType fromString(String? type) {
    switch (type) {
      case 'text':
        return QrCodeType.text;
      case 'url':
        return QrCodeType.url;
      case 'wifi':
        return QrCodeType.wifi;
      case 'contact':
        return QrCodeType.contact;
      case 'phone':
        return QrCodeType.phone;
      case 'sms':
        return QrCodeType.sms;
      case 'email':
        return QrCodeType.email;
      case 'location':
        return QrCodeType.location;
      case 'event':
        return QrCodeType.event;
      default:
        return QrCodeType.text;
    }
  }
}

/// 二维码数据模型
class QrCodeData {
  /// 唯一标识
  final String id;

  /// 二维码内容（原始文本）
  final String content;

  /// 二维码类型
  final QrCodeType type;

  /// 创建时间
  final DateTime createdAt;

  /// 二维码前景色（十六进制，默认黑色）
  final String color;

  /// 二维码背景色（十六进制，默认白色）
  final String backgroundColor;

  /// 备注名称（用户自定义）
  final String? name;

  QrCodeData({
    required this.id,
    required this.content,
    this.type = QrCodeType.text,
    DateTime? createdAt,
    this.color = '#000000',
    this.backgroundColor = '#FFFFFF',
    this.name,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 从 JSON 反序列化
  factory QrCodeData.fromJson(Map<String, dynamic> json) {
    return QrCodeData(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      type: QrCodeTypeExtension.fromString(json['type']?.toString()),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      color: json['color']?.toString() ?? '#000000',
      backgroundColor: json['background_color']?.toString() ?? '#FFFFFF',
      name: json['name']?.toString(),
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.value,
      'created_at': createdAt.toIso8601String(),
      'color': color,
      'background_color': backgroundColor,
      'name': name,
    };
  }

  /// 创建一个文本二维码
  factory QrCodeData.text(String content, {String? name}) {
    return QrCodeData(
      id: 'qr_${DateTime.now().microsecondsSinceEpoch}',
      content: content,
      type: QrCodeType.text,
      name: name,
    );
  }

  /// 创建一个 URL 二维码
  factory QrCodeData.url(String url, {String? name}) {
    return QrCodeData(
      id: 'qr_${DateTime.now().microsecondsSinceEpoch}',
      content: url,
      type: QrCodeType.url,
      name: name,
    );
  }

  /// 创建一个 WiFi 二维码
  ///
  /// [ssid] WiFi 名称，[password] 密码，[isHidden] 是否隐藏网络
  factory QrCodeData.wifi({
    required String ssid,
    String password = '',
    bool isHidden = false,
    String? name,
  }) {
    final escapedSsid = _escapeWifiString(ssid);
    final escapedPassword = _escapeWifiString(password);
    final auth = password.isEmpty ? 'nopass' : 'WPA';
    final content =
        'WIFI:T:$auth;S:$escapedSsid;P:$escapedPassword;'
        '${isHidden ? 'H:true;' : ''};';
    return QrCodeData(
      id: 'qr_${DateTime.now().microsecondsSinceEpoch}',
      content: content,
      type: QrCodeType.wifi,
      name: name ?? ssid,
    );
  }

  /// 转义 WiFi 字符串中的特殊字符
  static String _escapeWifiString(String input) {
    return input
        .replaceAll(r'\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll('"', r'\"');
  }

  /// 内容预览（截断显示）
  String get preview {
    if (content.length <= 40) return content;
    return '${content.substring(0, 40)}...';
  }

  /// 复制一份
  QrCodeData copyWith({
    String? id,
    String? content,
    QrCodeType? type,
    DateTime? createdAt,
    String? color,
    String? backgroundColor,
    String? name,
  }) {
    return QrCodeData(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      name: name ?? this.name,
    );
  }
}
