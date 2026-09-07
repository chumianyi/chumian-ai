/// 商城商品类型枚举
enum ShopItemType { points, svip, theme, avatar, badge, other }

/// 商品类型扩展
extension ShopItemTypeExtension on ShopItemType {
  String get value {
    switch (this) {
      case ShopItemType.points:
        return 'points';
      case ShopItemType.svip:
        return 'svip';
      case ShopItemType.theme:
        return 'theme';
      case ShopItemType.avatar:
        return 'avatar';
      case ShopItemType.badge:
        return 'badge';
      case ShopItemType.other:
        return 'other';
    }
  }

  static ShopItemType fromString(String? type) {
    switch (type) {
      case 'points':
        return ShopItemType.points;
      case 'svip':
        return ShopItemType.svip;
      case 'theme':
        return ShopItemType.theme;
      case 'avatar':
        return ShopItemType.avatar;
      case 'badge':
        return ShopItemType.badge;
      default:
        return ShopItemType.other;
    }
  }
}

/// 积分商城商品数据模型
///
/// 代表商城中可兑换或购买的商品，包括积分包、SVIP 会员、
/// 主题皮肤、头像框等虚拟物品。
class ShopItem {
  /// 商品唯一标识
  final String id;

  /// 商品名称
  final String name;

  /// 商品描述
  final String description;

  /// 商品价格（单位：积分或人民币分，视 type 而定）
  final int price;

  /// 商品类型
  final ShopItemType type;

  /// 商品图标（emoji 或图标资源名）
  final String icon;

  /// 折扣比例（0.0 - 1.0，0 表示无折扣）
  final double discount;

  ShopItem({
    required this.id,
    this.name = '',
    this.description = '',
    this.price = 0,
    this.type = ShopItemType.other,
    this.icon = '🎁',
    this.discount = 0.0,
  });

  /// 从 JSON 反序列化
  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      type: ShopItemTypeExtension.fromString(json['type']?.toString()),
      icon: json['icon']?.toString() ?? '🎁',
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'type': type.value,
      'icon': icon,
      'discount': discount,
    };
  }

  /// 从列表批量解析
  static List<ShopItem> fromList(List<dynamic> list) {
    return list
        .map((e) =>
            ShopItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// 是否有折扣
  bool get hasDiscount => discount > 0 && discount < 1.0;

  /// 折后实际价格
  int get finalPrice {
    if (!hasDiscount) return price;
    return (price * (1.0 - discount)).round();
  }

  /// 折扣展示文本，如 '7折'
  String get discountLabel {
    if (!hasDiscount) return '';
    final percent = ((1.0 - discount) * 10).toStringAsFixed(1);
    return '${percent.replaceAll('.0', '')}折';
  }

  /// 是否为会员类商品
  bool get isVipItem => type == ShopItemType.svip;

  /// 是否为积分类商品
  bool get isPointsItem => type == ShopItemType.points;

  /// 复制并修改部分字段
  ShopItem copyWith({
    String? id,
    String? name,
    String? description,
    int? price,
    ShopItemType? type,
    String? icon,
    double? discount,
  }) {
    return ShopItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      discount: discount ?? this.discount,
    );
  }
}
