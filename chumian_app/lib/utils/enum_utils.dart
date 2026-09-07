/// ============================================================================
/// EnumUtils —— 枚举工具
///
/// 功能：
///   1. 枚举转字符串：获取枚举值的名称
///   2. 字符串转枚举：根据名称查找枚举值
///   3. 枚举列表：获取所有枚举值
///   4. 枚举描述：获取枚举值的可读描述
///   5. 下一个/上一个：循环获取相邻枚举值
/// ============================================================================
class EnumUtils {
  // ==========================================================================
  // 枚举转字符串
  // ==========================================================================

  /// 获取枚举值的名称（如 EnumType.value -> 'value'）
  static String name<T extends Enum>(T value) {
    return value.toString().split('.').last;
  }

  /// 获取枚举值的短名称（全部小写）
  static String shortName<T extends Enum>(T value) {
    return name(value).toLowerCase();
  }

  /// 获取枚举值的大写名称
  static String upperName<T extends Enum>(T value) {
    return name(value).toUpperCase();
  }

  /// 获取枚举值的首字母大写名称
  static String capitalizedName<T extends Enum>(T value) {
    final n = name(value);
    if (n.isEmpty) return n;
    return n[0].toUpperCase() + n.substring(1).toLowerCase();
  }

  /// 枚举值转带前缀的字符串
  static String withPrefix<T extends Enum>(T value, String prefix) {
    return '$prefix${name(value)}';
  }

  // ==========================================================================
  // 字符串转枚举
  // ==========================================================================

  /// 根据名称查找枚举值
  ///
  /// [values] 枚举的 values 列表，[name] 名称，[ignoreCase] 是否忽略大小写
  /// [orElse] 未找到时的默认值
  static T? fromName<T extends Enum>(
    List<T> values,
    String name, {
    bool ignoreCase = false,
    T? orElse,
  }) {
    for (final value in values) {
      final valueName = EnumUtils.name(value);
      if (ignoreCase) {
        if (valueName.toLowerCase() == name.toLowerCase()) return value;
      } else {
        if (valueName == name) return value;
      }
    }
    return orElse;
  }

  /// 根据名称查找枚举值（未找到时返回第一个）
  static T fromNameOrFirst<T extends Enum>(
    List<T> values,
    String name, {
    bool ignoreCase = false,
  }) {
    return fromName(values, name, ignoreCase: ignoreCase) ?? values.first;
  }

  /// 根据名称查找枚举值（未找到时抛出异常）
  static T fromNameOrThrow<T extends Enum>(
    List<T> values,
    String name, {
    bool ignoreCase = false,
  }) {
    final result = fromName(values, name, ignoreCase: ignoreCase);
    if (result == null) {
      throw ArgumentError('枚举值不存在: $name，可选: ${values.map(EnumUtils.name).join(", ")}');
    }
    return result;
  }

  /// 检查名称是否为有效的枚举值
  static bool isValidName<T extends Enum>(
    List<T> values,
    String name, {
    bool ignoreCase = false,
  }) {
    return fromName(values, name, ignoreCase: ignoreCase) != null;
  }

  // ==========================================================================
  // 枚举列表
  // ==========================================================================

  /// 获取所有枚举值的名称列表
  static List<String> names<T extends Enum>(List<T> values) {
    return values.map(EnumUtils.name).toList();
  }

  /// 获取所有枚举值的大写名称列表
  static List<String> upperNames<T extends Enum>(List<T> values) {
    return values.map(EnumUtils.upperName).toList();
  }

  /// 获取枚举值数量
  static int count<T extends Enum>(List<T> values) {
    return values.length;
  }

  /// 获取枚举值的索引
  static int indexOf<T extends Enum>(List<T> values, T value) {
    return values.indexOf(value);
  }

  /// 检查是否包含指定枚举值
  static bool contains<T extends Enum>(List<T> values, T value) {
    return values.contains(value);
  }

  // ==========================================================================
  // 枚举描述
  // ==========================================================================

  /// 获取枚举值的可读描述（将下划线/驼峰转换为空格分隔）
  static String description<T extends Enum>(T value) {
    final n = name(value);
    // 驼峰转空格
    final withSpaces = n.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m.group(1)} ${m.group(2)}',
    );
    // 下划线转空格
    final result = withSpaces.replaceAll('_', ' ');
    // 首字母大写
    if (result.isEmpty) return result;
    return result[0].toUpperCase() + result.substring(1).toLowerCase();
  }

  /// 获取所有枚举值的描述列表
  static List<String> descriptions<T extends Enum>(List<T> values) {
    return values.map(EnumUtils.description).toList();
  }

  /// 根据描述查找枚举值
  static T? fromDescription<T extends Enum>(
    List<T> values,
    String description, {
    bool ignoreCase = false,
  }) {
    for (final value in values) {
      final desc = EnumUtils.description(value);
      if (ignoreCase) {
        if (desc.toLowerCase() == description.toLowerCase()) return value;
      } else {
        if (desc == description) return value;
      }
    }
    return null;
  }

  // ==========================================================================
  // 下一个/上一个
  // ==========================================================================

  /// 获取下一个枚举值（循环）
  static T next<T extends Enum>(List<T> values, T current) {
    final index = values.indexOf(current);
    if (index < 0) return values.first;
    final nextIndex = (index + 1) % values.length;
    return values[nextIndex];
  }

  /// 获取上一个枚举值（循环）
  static T previous<T extends Enum>(List<T> values, T current) {
    final index = values.indexOf(current);
    if (index < 0) return values.first;
    final prevIndex = (index - 1 + values.length) % values.length;
    return values[prevIndex];
  }

  /// 获取下一个枚举值（不循环，到末尾返回 null）
  static T? nextOrNull<T extends Enum>(List<T> values, T current) {
    final index = values.indexOf(current);
    if (index < 0 || index >= values.length - 1) return null;
    return values[index + 1];
  }

  /// 获取上一个枚举值（不循环，到开头返回 null）
  static T? previousOrNull<T extends Enum>(List<T> values, T current) {
    final index = values.indexOf(current);
    if (index <= 0) return null;
    return values[index - 1];
  }

  /// 判断是否为第一个枚举值
  static bool isFirst<T extends Enum>(List<T> values, T current) {
    return values.indexOf(current) == 0;
  }

  /// 判断是否为最后一个枚举值
  static bool isLast<T extends Enum>(List<T> values, T current) {
    return values.indexOf(current) == values.length - 1;
  }

  // ==========================================================================
  // 映射与转换
  // ==========================================================================

  /// 将枚举列表映射为名称-值对
  static Map<String, T> toMap<T extends Enum>(List<T> values) {
    return {for (final v in values) EnumUtils.name(v): v};
  }

  /// 将枚举列表映射为名称-描述对
  static Map<String, String> toDescriptionMap<T extends Enum>(List<T> values) {
    return {for (final v in values) EnumUtils.name(v): EnumUtils.description(v)};
  }

  /// 枚举值列表排序（按名称）
  static List<T> sortByName<T extends Enum>(List<T> values) {
    final sorted = List<T>.from(values);
    sorted.sort((a, b) => EnumUtils.name(a).compareTo(EnumUtils.name(b)));
    return sorted;
  }

  /// 枚举值列表排序（按描述）
  static List<T> sortByDescription<T extends Enum>(List<T> values) {
    final sorted = List<T>.from(values);
    sorted.sort((a, b) =>
        EnumUtils.description(a).compareTo(EnumUtils.description(b)));
    return sorted;
  }

  /// 过滤枚举值（按名称前缀）
  static List<T> whereNameStartsWith<T extends Enum>(
    List<T> values,
    String prefix,
  ) {
    return values
        .where((v) => EnumUtils.name(v).toLowerCase().startsWith(prefix.toLowerCase()))
        .toList();
  }

  /// 过滤枚举值（按名称包含）
  static List<T> whereNameContains<T extends Enum>(
    List<T> values,
    String substring,
  ) {
    return values
        .where((v) =>
            EnumUtils.name(v).toLowerCase().contains(substring.toLowerCase()))
        .toList();
  }

  // ==========================================================================
  // 工具方法
  // ==========================================================================

  /// 随机获取一个枚举值
  static T random<T extends Enum>(List<T> values) {
    return values[DateTime.now().microsecondsSinceEpoch % values.length];
  }

  /// 枚举值比较
  static int compare<T extends Enum>(List<T> values, T a, T b) {
    return values.indexOf(a).compareTo(values.indexOf(b));
  }

  /// 获取枚举值范围（从 from 到 to）
  static List<T> range<T extends Enum>(List<T> values, T from, T to) {
    final startIndex = values.indexOf(from);
    final endIndex = values.indexOf(to);
    if (startIndex < 0 || endIndex < 0) return [];
    if (startIndex <= endIndex) {
      return values.sublist(startIndex, endIndex + 1);
    } else {
      return values.sublist(endIndex, startIndex + 1).reversed.toList();
    }
  }

  /// 将枚举值转换为 JSON 兼容的字符串
  static String toJson<T extends Enum>(T value) => name(value);

  /// 从 JSON 字符串解析枚举值
  static T? fromJson<T extends Enum>(List<T> values, dynamic json) {
    if (json is! String) return null;
    return fromName(values, json);
  }
}
