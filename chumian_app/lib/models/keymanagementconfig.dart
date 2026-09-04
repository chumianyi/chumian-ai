import 'dart:convert';

/// KeyManagementConfig 数据模型
class KeyManagementConfig {
  String id;
  DateTime createdAt;
  DateTime updatedAt;
  Map<String, dynamic> data;
  Map<String, dynamic> metadata;

  KeyManagementConfig({
    this.id = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? data,
    Map<String, dynamic>? metadata,
  }) : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        data = data ?? {},
        metadata = metadata ?? {};

  factory KeyManagementConfig.fromJson(Map<String, dynamic> json) => KeyManagementConfig(
    id: json['id'] ?? '',
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : {},
    metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : {},
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'data': data,
    'metadata': metadata,
  };

  KeyManagementConfig copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? data,
    Map<String, dynamic>? metadata,
  }) => KeyManagementConfig(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    data: data ?? this.data,
    metadata: metadata ?? this.metadata,
  );

  KeyManagementConfig clone() => KeyManagementConfig.fromJson(toJson());
  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is KeyManagementConfig && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'KeyManagementConfig(id: $id)';
}
