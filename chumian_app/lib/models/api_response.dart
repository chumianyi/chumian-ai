import 'pagination.dart';
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? code;
  final Map<String, dynamic>? errors;
  final Pagination? pagination;
  final DateTime timestamp;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.code,
    this.errors,
    this.pagination,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ApiResponse.success(T data, [String? message]) {
    return ApiResponse<T>(success: true, data: data, message: message);
  }

  factory ApiResponse.error(String message, [int? code]) {
    return ApiResponse<T>(success: false, message: message, code: code);
  }

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse<T>(
      success: json['success'] ?? json['code'] == 200,
      data: json['data'] as T?,
      message: json['message'] ?? json['msg'],
      code: json['code'] ?? json['status'],
      errors: json['errors'] as Map<String, dynamic>?,
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'data': data,
        'message': message,
        'code': code,
        'errors': errors,
        'pagination': pagination?.toJson(),
        'timestamp': timestamp.toIso8601String(),
      };
}
