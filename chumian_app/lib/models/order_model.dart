/// ============================================================================
/// Order —— 订单数据模型
///
/// 承载积分商城兑换与商品购买订单的完整信息，包括商品 ID、
/// 商品名称、金额/积分、订单状态以及订单类型。
/// ============================================================================

/// 订单类型枚举
enum OrderType {
  /// 积分兑换
  exchange,

  /// 购买
  purchase,
}

/// OrderType 枚举的字符串扩展
extension OrderTypeExtension on OrderType {
  String get value {
    switch (this) {
      case OrderType.exchange:
        return 'exchange';
      case OrderType.purchase:
        return 'purchase';
    }
  }

  String get label {
    switch (this) {
      case OrderType.exchange:
        return '积分兑换';
      case OrderType.purchase:
        return '购买';
    }
  }

  static OrderType fromString(String? type) {
    switch (type) {
      case 'exchange':
        return OrderType.exchange;
      case 'purchase':
        return OrderType.purchase;
      default:
        return OrderType.exchange;
    }
  }
}

/// 订单状态枚举
enum OrderStatus {
  /// 待处理
  pending,

  /// 处理中
  processing,

  /// 已完成
  completed,

  /// 已取消
  cancelled,

  /// 已退款
  refunded,

  /// 失败
  failed,
}

/// OrderStatus 枚举的字符串扩展
extension OrderStatusExtension on OrderStatus {
  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.processing:
        return 'processing';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
      case OrderStatus.refunded:
        return 'refunded';
      case OrderStatus.failed:
        return 'failed';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return '待处理';
      case OrderStatus.processing:
        return '处理中';
      case OrderStatus.completed:
        return '已完成';
      case OrderStatus.cancelled:
        return '已取消';
      case OrderStatus.refunded:
        return '已退款';
      case OrderStatus.failed:
        return '失败';
    }
  }

  static OrderStatus fromString(String? status) {
    switch (status) {
      case 'pending':
        return OrderStatus.pending;
      case 'processing':
        return OrderStatus.processing;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'refunded':
        return OrderStatus.refunded;
      case 'failed':
        return OrderStatus.failed;
      default:
        return OrderStatus.pending;
    }
  }
}

/// 订单数据模型
class Order {
  /// 订单唯一标识
  final String id;

  /// 商品 ID
  final String itemId;

  /// 商品名称
  final String itemName;

  /// 商品图片 URL（可选）
  final String? itemImage;

  /// 金额（兑换时为积分，购买时为元/分）
  final int amount;

  /// 订单状态
  OrderStatus status;

  /// 订单创建时间
  final DateTime createdAt;

  /// 订单类型
  final OrderType type;

  /// 购买数量
  final int quantity;

  /// 订单完成时间
  DateTime? completedAt;

  /// 收货/兑换信息（如邮箱、地址等）
  final Map<String, dynamic> deliveryInfo;

  /// 备注
  final String? remark;

  /// 错误信息（失败时填充）
  String? errorMessage;

  Order({
    required this.id,
    required this.itemId,
    required this.itemName,
    this.itemImage,
    required this.amount,
    this.status = OrderStatus.pending,
    DateTime? createdAt,
    this.type = OrderType.exchange,
    this.quantity = 1,
    this.completedAt,
    Map<String, dynamic>? deliveryInfo,
    this.remark,
    this.errorMessage,
  })  : deliveryInfo = deliveryInfo ?? {},
        createdAt = createdAt ?? DateTime.now();

  /// 从 JSON 反序列化
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id']?.toString() ?? '',
      itemId: json['item_id']?.toString() ?? '',
      itemName: json['item_name']?.toString() ?? '',
      itemImage: json['item_image']?.toString(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      status: OrderStatusExtension.fromString(json['status']?.toString()),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      type: OrderTypeExtension.fromString(json['type']?.toString()),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      deliveryInfo: json['delivery_info'] != null
          ? Map<String, dynamic>.from(json['delivery_info'] as Map)
          : {},
      remark: json['remark']?.toString(),
      errorMessage: json['error_message']?.toString(),
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'item_name': itemName,
      'item_image': itemImage,
      'amount': amount,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'type': type.value,
      'quantity': quantity,
      'completed_at': completedAt?.toIso8601String(),
      'delivery_info': deliveryInfo,
      'remark': remark,
      'error_message': errorMessage,
    };
  }

  /// 创建一个兑换订单
  factory Order.exchange({
    required String itemId,
    required String itemName,
    String? itemImage,
    required int points,
    int quantity = 1,
    Map<String, dynamic>? deliveryInfo,
  }) {
    return Order(
      id: 'ord_${DateTime.now().millisecondsSinceEpoch}_'
          '${itemId.hashCode.toRadixString(16)}',
      itemId: itemId,
      itemName: itemName,
      itemImage: itemImage,
      amount: points,
      type: OrderType.exchange,
      quantity: quantity,
      deliveryInfo: deliveryInfo,
    );
  }

  /// 创建一个购买订单
  factory Order.purchase({
    required String itemId,
    required String itemName,
    String? itemImage,
    required int price,
    int quantity = 1,
    Map<String, dynamic>? deliveryInfo,
  }) {
    return Order(
      id: 'ord_${DateTime.now().millisecondsSinceEpoch}_'
          '${itemId.hashCode.toRadixString(16)}',
      itemId: itemId,
      itemName: itemName,
      itemImage: itemImage,
      amount: price,
      type: OrderType.purchase,
      quantity: quantity,
      deliveryInfo: deliveryInfo,
    );
  }

  /// 总金额（单价 × 数量）
  int get totalAmount => amount * quantity;

  /// 金额显示文本
  String get amountText {
    if (type == OrderType.exchange) {
      return '$totalAmount 积分';
    }
    return '¥${(totalAmount / 100).toStringAsFixed(2)}';
  }

  /// 是否处于终态
  bool get isFinished =>
      status == OrderStatus.completed ||
      status == OrderStatus.cancelled ||
      status == OrderStatus.refunded ||
      status == OrderStatus.failed;

  /// 是否可以取消
  bool get canCancel =>
      status == OrderStatus.pending || status == OrderStatus.processing;

  /// 复制一份订单
  Order copyWith({
    String? id,
    String? itemId,
    String? itemName,
    String? itemImage,
    int? amount,
    OrderStatus? status,
    DateTime? createdAt,
    OrderType? type,
    int? quantity,
    DateTime? completedAt,
    Map<String, dynamic>? deliveryInfo,
    String? remark,
    String? errorMessage,
  }) {
    return Order(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      itemImage: itemImage ?? this.itemImage,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      completedAt: completedAt ?? this.completedAt,
      deliveryInfo: deliveryInfo ?? this.deliveryInfo,
      remark: remark ?? this.remark,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
