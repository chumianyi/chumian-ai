import 'dart:convert';

/// DataReportingConfig 数据模型
class DataReportingConfig {
  String id;
  DateTime createdAt;
  DateTime updatedAt;
  Map<String, dynamic> data;
  Map<String, dynamic> metadata;

  DataReportingConfig({
    this.id = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? data,
    Map<String, dynamic>? metadata,
  }) : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        data = data ?? {},
        metadata = metadata ?? {};

  factory DataReportingConfig.fromJson(Map<String, dynamic> json) => DataReportingConfig(
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

  DataReportingConfig copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? data,
    Map<String, dynamic>? metadata,
  }) => DataReportingConfig(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    data: data ?? this.data,
    metadata: metadata ?? this.metadata,
  );

  DataReportingConfig clone() => DataReportingConfig.fromJson(toJson());
  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DataReportingConfig && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'DataReportingConfig(id: $id)';
}
