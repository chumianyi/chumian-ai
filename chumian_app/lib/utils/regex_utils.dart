/// ============================================================================
/// RegexUtils —— 正则表达式工具类
///
/// 提供常用正则表达式的验证与提取方法，覆盖邮箱、手机号、
/// URL、IP 地址、身份证号、密码强度、中文字符、英文字符、
/// 数字等常见场景。
/// ============================================================================
class RegexUtils {
  // ===== 正则表达式常量 =====

  /// 邮箱正则
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// 中国大陆手机号正则
  static final RegExp phoneRegex = RegExp(r'^1[3-9]\d{9}$');

  /// URL 正则（http/https）
  static final RegExp urlRegex = RegExp(
    r'https?://[^\s<>"\')\]]+',
    caseSensitive: false,
  );

  /// IPv4 地址正则
  static final RegExp ipv4Regex = RegExp(
    r'^((25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(25[0-5]|2[0-4]\d|[01]?\d\d?)$',
  );

  /// IPv6 地址正则（简化版）
  static final RegExp ipv6Regex = RegExp(
    r'^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$',
  );

  /// 中国大陆身份证号正则（18位）
  static final RegExp idCardRegex = RegExp(
    r'^[1-9]\d{5}(18|19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{3}[\dXx]$',
  );

  /// 中文字符正则
  static final RegExp chineseRegex = RegExp(r'[\u4e00-\u9fa5]');

  /// 纯中文正则
  static final RegExp chineseOnlyRegex = RegExp(r'^[\u4e00-\u9fa5]+$');

  /// 英文字母正则
  static final RegExp englishRegex = RegExp(r'[a-zA-Z]');

  /// 纯英文正则
  static final RegExp englishOnlyRegex = RegExp(r'^[a-zA-Z]+$');

  /// 数字正则
  static final RegExp numberRegex = RegExp(r'\d');

  /// 纯数字正则
  static final RegExp numberOnlyRegex = RegExp(r'^\d+$');

  /// 整数正则（含负数）
  static final RegExp integerRegex = RegExp(r'^-?\d+$');

  /// 浮点数正则
  static final RegExp floatRegex = RegExp(r'^-?\d+\.\d+$');

  /// 数字或浮点数正则
  static final RegExp numericRegex = RegExp(r'^-?\d+(\.\d+)?$');

  /// 用户名正则（3-20位，字母/数字/下划线）
  static final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  /// 弱密码正则（至少6位）
  static final RegExp weakPasswordRegex = RegExp(r'^.{6,}$');

  /// 中强度密码正则（至少8位，包含字母和数字）
  static final RegExp mediumPasswordRegex = RegExp(
    r'^(?=.*[a-zA-Z])(?=.*\d).{8,}$',
  );

  /// 强密码正则（至少8位，包含大小写字母、数字和特殊字符）
  static final RegExp strongPasswordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\/~`]).{8,}$',
  );

  /// 特殊字符正则
  static final RegExp specialCharRegex =
      RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\/~`]');

  /// 十六进制颜色正则
  static final RegExp hexColorRegex = RegExp(r'^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$');

  /// 日期正则（YYYY-MM-DD）
  static final RegExp dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// 时间正则（HH:mm:ss）
  static final RegExp timeRegex = RegExp(r'^\d{2}:\d{2}:\d{2}$');

  /// QQ 号正则
  static final RegExp qqRegex = RegExp(r'^[1-9]\d{4,11}$');

  /// 邮政编码正则
  static final RegExp postalCodeRegex = RegExp(r'^\d{6}$');

  /// 车牌号正则（中国大陆）
  static final RegExp plateNumberRegex = RegExp(
    r'^[京津沪渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤青藏川宁琼使领][A-HJ-NP-Z][A-HJ-NP-Z0-9]{4,5}[A-HJ-NP-Z0-9挂学警港澳]$',
  );

  // ==========================================================================
  // 验证方法
  // ==========================================================================

  /// 验证邮箱格式
  static bool isEmail(String input) {
    if (input.isEmpty) return false;
    return emailRegex.hasMatch(input.trim());
  }

  /// 验证手机号格式（中国大陆）
  static bool isPhone(String input) {
    if (input.isEmpty) return false;
    return phoneRegex.hasMatch(input.trim());
  }

  /// 验证 URL 格式
  static bool isUrl(String input) {
    if (input.isEmpty) return false;
    return urlRegex.hasMatch(input.trim());
  }

  /// 验证 IPv4 地址
  static bool isIpv4(String input) {
    if (input.isEmpty) return false;
    return ipv4Regex.hasMatch(input.trim());
  }

  /// 验证 IPv6 地址
  static bool isIpv6(String input) {
    if (input.isEmpty) return false;
    return ipv6Regex.hasMatch(input.trim());
  }

  /// 验证 IP 地址（v4 或 v6）
  static bool isIp(String input) {
    return isIpv4(input) || isIpv6(input);
  }

  /// 验证身份证号（18位，含校验位验证）
  static bool isIdCard(String input) {
    if (input.isEmpty) return false;
    final id = input.trim();
    if (!idCardRegex.hasMatch(id)) return false;

    // 校验位验证
    const weights = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2];
    const checkCodes = ['1', '0', 'X', '9', '8', '7', '6', '5', '4', '3', '2'];
    int sum = 0;
    for (int i = 0; i < 17; i++) {
      sum += int.parse(id[i]) * weights[i];
    }
    final expected = checkCodes[sum % 11];
    return id[17].toUpperCase() == expected;
  }

  /// 验证是否包含中文
  static bool containsChinese(String input) {
    if (input.isEmpty) return false;
    return chineseRegex.hasMatch(input);
  }

  /// 验证是否纯中文
  static bool isChineseOnly(String input) {
    if (input.isEmpty) return false;
    return chineseOnlyRegex.hasMatch(input);
  }

  /// 验证是否包含英文
  static bool containsEnglish(String input) {
    if (input.isEmpty) return false;
    return englishRegex.hasMatch(input);
  }

  /// 验证是否纯英文
  static bool isEnglishOnly(String input) {
    if (input.isEmpty) return false;
    return englishOnlyRegex.hasMatch(input);
  }

  /// 验证是否包含数字
  static bool containsNumber(String input) {
    if (input.isEmpty) return false;
    return numberRegex.hasMatch(input);
  }

  /// 验证是否纯数字
  static bool isNumberOnly(String input) {
    if (input.isEmpty) return false;
    return numberOnlyRegex.hasMatch(input);
  }

  /// 验证是否为整数
  static bool isInteger(String input) {
    if (input.isEmpty) return false;
    return integerRegex.hasMatch(input.trim());
  }

  /// 验证是否为浮点数
  static bool isFloat(String input) {
    if (input.isEmpty) return false;
    return floatRegex.hasMatch(input.trim());
  }

  /// 验证是否为数字（整数或浮点数）
  static bool isNumeric(String input) {
    if (input.isEmpty) return false;
    return numericRegex.hasMatch(input.trim());
  }

  /// 验证用户名格式
  static bool isUsername(String input) {
    if (input.isEmpty) return false;
    return usernameRegex.hasMatch(input.trim());
  }

  /// 验证密码强度等级
  ///
  /// 返回 0=极弱, 1=弱, 2=中, 3=强, 4=极强
  static int passwordStrength(String password) {
    if (password.isEmpty) return 0;
    if (!weakPasswordRegex.hasMatch(password)) return 1;
    if (!mediumPasswordRegex.hasMatch(password)) return 2;
    if (!strongPasswordRegex.hasMatch(password)) return 3;
    return 4;
  }

  /// 验证是否包含特殊字符
  static bool containsSpecialChar(String input) {
    if (input.isEmpty) return false;
    return specialCharRegex.hasMatch(input);
  }

  /// 验证十六进制颜色
  static bool isHexColor(String input) {
    if (input.isEmpty) return false;
    return hexColorRegex.hasMatch(input.trim());
  }

  /// 验证日期格式（YYYY-MM-DD）
  static bool isDate(String input) {
    if (input.isEmpty) return false;
    if (!dateRegex.hasMatch(input.trim())) return false;
    // 尝试解析为实际日期
    return DateTime.tryParse(input.trim()) != null;
  }

  /// 验证 QQ 号
  static bool isQQ(String input) {
    if (input.isEmpty) return false;
    return qqRegex.hasMatch(input.trim());
  }

  /// 验证邮政编码
  static bool isPostalCode(String input) {
    if (input.isEmpty) return false;
    return postalCodeRegex.hasMatch(input.trim());
  }

  // ==========================================================================
  // 提取方法
  // ==========================================================================

  /// 从文本中提取所有邮箱
  static List<String> extractEmails(String text) {
    if (text.isEmpty) return [];
    return emailRegex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  /// 从文本中提取所有手机号
  static List<String> extractPhones(String text) {
    if (text.isEmpty) return [];
    return phoneRegex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  /// 从文本中提取所有 URL
  static List<String> extractUrls(String text) {
    if (text.isEmpty) return [];
    return urlRegex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  /// 从文本中提取所有数字
  static List<String> extractNumbers(String text) {
    if (text.isEmpty) return [];
    return RegExp(r'\d+').allMatches(text).map((m) => m.group(0)!).toList();
  }

  /// 从文本中提取所有中文字符
  static List<String> extractChinese(String text) {
    if (text.isEmpty) return [];
    return chineseRegex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  /// 从文本中提取第一个匹配的整数
  static int? extractFirstInt(String text) {
    if (text.isEmpty) return null;
    final match = RegExp(r'-?\d+').firstMatch(text);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }

  /// 从文本中提取第一个匹配的浮点数
  static double? extractFirstDouble(String text) {
    if (text.isEmpty) return null;
    final match = RegExp(r'-?\d+(\.\d+)?').firstMatch(text);
    return match != null ? double.tryParse(match.group(0)!) : null;
  }

  /// 统计文本中中文字符数
  static int countChinese(String text) {
    if (text.isEmpty) return 0;
    return chineseRegex.allMatches(text).length;
  }

  /// 统计文本中英文字符数
  static int countEnglish(String text) {
    if (text.isEmpty) return 0;
    return englishRegex.allMatches(text).length;
  }

  /// 统计文本中数字字符数
  static int countDigits(String text) {
    if (text.isEmpty) return 0;
    return numberRegex.allMatches(text).length;
  }
}
