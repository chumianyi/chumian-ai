import 'dart:convert';

/// ============================================================================
/// JsonUtils —— JSON 安全解析工具类
///
/// 提供安全的 JSON 解析（带默认值和类型转换）、深拷贝、差异比较、
/// 路径查找（dot notation）、格式化输出等功能。
/// ============================================================================
class JsonUtils {
  // ==========================================================================
  // 安全解析
  // ==========================================================================

  /// 安全解析 JSON 字符串
  ///
  /// 解析失败返回空 Map
  static Map<String, dynamic> safeParse(String jsonString) {
    if (jsonString.isEmpty) return {};
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  /// 安全解析 JSON 字符串为列表
  static List<dynamic> safeParseList(String jsonString) {
    if (jsonString.isEmpty) return [];
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) return decoded;
      return [];
    } catch (_) {
      return [];
    }
  }

  /// 尝试解析 JSON，成功返回 true
  static bool tryParse(String jsonString) {
    if (jsonString.isEmpty) return false;
    try {
      jsonDecode(jsonString);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================================================
  // 安全取值（带默认值和类型转换）
  // ==========================================================================

  /// 从 Map 中安全获取字符串
  static String getString(
    Map<String, dynamic> json,
    String key, {
    String defaultValue = '',
  }) {
    final value = json[key];
    if (value == null) return defaultValue;
    return value.toString();
  }

  /// 从 Map 中安全获取整数
  static int getInt(
    Map<String, dynamic> json,
    String key, {
    int defaultValue = 0,
  }) {
    final value = json[key];
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// 从 Map 中安全获取双精度浮点数
  static double getDouble(
    Map<String, dynamic> json,
    String key, {
    double defaultValue = 0.0,
  }) {
    final value = json[key];
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// 从 Map 中安全获取布尔值
  static bool getBool(
    Map<String, dynamic> json,
    String key, {
    bool defaultValue = false,
  }) {
    final value = json[key];
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is num) return value != 0;
    return defaultValue;
  }

  /// 从 Map 中安全获取列表
  static List<dynamic> getList(
    Map<String, dynamic> json,
    String key, {
    List<dynamic>? defaultValue,
  }) {
    final value = json[key];
    if (value == null) return defaultValue ?? [];
    if (value is List) return value;
    return defaultValue ?? [];
  }

  /// 从 Map 中安全获取嵌套 Map
  static Map<String, dynamic> getMap(
    Map<String, dynamic> json,
    String key, {
    Map<String, dynamic>? defaultValue,
  }) {
    final value = json[key];
    if (value == null) return defaultValue ?? {};
    if (value is Map) return Map<String, dynamic>.from(value);
    return defaultValue ?? {};
  }

  /// 从 Map 中安全获取 DateTime
  static DateTime? getDateTime(
    Map<String, dynamic> json,
    String key, {
    DateTime? defaultValue,
  }) {
    final value = json[key];
    if (value == null) return defaultValue;
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? defaultValue;
    }
    if (value is int) {
      // 假设为毫秒时间戳
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return defaultValue;
  }

  // ==========================================================================
  // 路径查找（dot notation）
  // ==========================================================================

  /// 通过点分隔路径查找嵌套值
  ///
  /// 例如：findByPath(json, 'user.profile.name')
  static dynamic findByPath(Map<String, dynamic> json, String path) {
    if (path.isEmpty) return null;
    final keys = path.split('.');
    dynamic current = json;

    for (final key in keys) {
      if (current is Map<String, dynamic>) {
        current = current[key];
      } else if (current is List) {
        final index = int.tryParse(key);
        if (index != null && index >= 0 && index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else {
        return null;
      }
      if (current == null) return null;
    }
    return current;
  }

  /// 通过路径查找字符串值
  static String findString(
    Map<String, dynamic> json,
    String path, {
    String defaultValue = '',
  }) {
    final value = findByPath(json, path);
    if (value == null) return defaultValue;
    return value.toString();
  }

  /// 通过路径查找整数值
  static int findInt(
    Map<String, dynamic> json,
    String path, {
    int defaultValue = 0,
  }) {
    final value = findByPath(json, path);
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// 通过路径设置嵌套值
  static void setByPath(
    Map<String, dynamic> json,
    String path,
    dynamic value,
  ) {
    if (path.isEmpty) return;
    final keys = path.split('.');
    dynamic current = json;

    for (int i = 0; i < keys.length - 1; i++) {
      final key = keys[i];
      if (current is Map<String, dynamic>) {
        if (current[key] is! Map<String, dynamic>) {
          current[key] = <String, dynamic>{};
        }
        current = current[key];
      } else {
        return;
      }
    }

    if (current is Map<String, dynamic>) {
      current[keys.last] = value;
    }
  }

  // ==========================================================================
  // 深拷贝
  // ==========================================================================

  /// 深拷贝 Map
  static Map<String, dynamic> deepCopyMap(Map<String, dynamic> source) {
    final result = <String, dynamic>{};
    source.forEach((key, value) {
      result[key] = _deepCopyValue(value);
    });
    return result;
  }

  /// 深拷贝 List
  static List<dynamic> deepCopyList(List<dynamic> source) {
    return source.map((e) => _deepCopyValue(e)).toList();
  }

  /// 深拷贝单个值
  static dynamic _deepCopyValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      return deepCopyMap(value);
    }
    if (value is List) {
      return deepCopyList(value);
    }
    // 基本类型（String, int, double, bool, null）是不可变的，直接返回
    return value;
  }

  // ==========================================================================
  // 差异比较
  // ==========================================================================

  /// 比较两个 Map 的差异
  ///
  /// 返回包含差异的 Map：新增的键、删除的键、值变化的键
  static JsonDiff diff(Map<String, dynamic> a, Map<String, dynamic> b) {
    final added = <String>[];
    final removed = <String>[];
    final changed = <String>[];

    final allKeys = <String>{...a.keys, ...b.keys};

    for (final key in allKeys) {
      final inA = a.containsKey(key);
      final inB = b.containsKey(key);

      if (inA && !inB) {
        removed.add(key);
      } else if (!inA && inB) {
        added.add(key);
      } else if (inA && inB) {
        if (!_valuesEqual(a[key], b[key])) {
          changed.add(key);
        }
      }
    }

    return JsonDiff(
      added: added,
      removed: removed,
      changed: changed,
    );
  }

  /// 比较两个值是否相等（处理嵌套结构）
  static bool _valuesEqual(dynamic a, dynamic b) {
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key)) return false;
        if (!_valuesEqual(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!_valuesEqual(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }

  // ==========================================================================
  // 格式化输出
  // ==========================================================================

  /// 格式化 JSON 为带缩进的字符串
  static String format(dynamic json, {int indent = 2}) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (_) {
      return json.toString();
    }
  }

  /// 压缩 JSON 为单行字符串
  static String compress(dynamic json) {
    try {
      return jsonEncode(json);
    } catch (_) {
      return json.toString();
    }
  }

  /// 美化 JSON 字符串
  static String prettify(String jsonString) {
    final parsed = safeParse(jsonString);
    if (parsed.isEmpty) {
      final list = safeParseList(jsonString);
      if (list.isNotEmpty) return format(list);
      return jsonString;
    }
    return format(parsed);
  }

  // ==========================================================================
  // 其他工具
  // ==========================================================================

  /// 合并两个 Map（后者覆盖前者）
  static Map<String, dynamic> merge(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final result = deepCopyMap(a);
    b.forEach((key, value) {
      if (result[key] is Map<String, dynamic> &&
          value is Map<String, dynamic>) {
        result[key] = merge(result[key] as Map<String, dynamic>, value);
      } else {
        result[key] = _deepCopyValue(value);
      }
    });
    return result;
  }

  /// 从 Map 中移除 null 值
  static Map<String, dynamic> removeNulls(Map<String, dynamic> json) {
    final result = <String, dynamic>{};
    json.forEach((key, value) {
      if (value != null) {
        if (value is Map<String, dynamic>) {
          result[key] = removeNulls(value);
        } else {
          result[key] = value;
        }
      }
    });
    return result;
  }

  /// 将 Map 转换为查询参数字符串
  static String toQueryString(Map<String, dynamic> params) {
    final parts = <String>[];
    params.forEach((key, value) {
      if (value != null) {
        parts.add(
            '${Uri.encodeComponent(key)}=${Uri.encodeComponent(value.toString())}');
      }
    });
    return parts.join('&');
  }
}

/// JSON 差异结果
class JsonDiff {
  final List<String> added;
  final List<String> removed;
  final List<String> changed;

  JsonDiff({
    required this.added,
    required this.removed,
    required this.changed,
  });

  /// 是否有差异
  bool get hasDifference =>
      added.isNotEmpty || removed.isNotEmpty || changed.isNotEmpty;

  /// 差异总数
  int get totalCount => added.length + removed.length + changed.length;
}
