/// ============================================================================
/// TextUtils —— 文本处理工具类
///
/// 提供字数统计、文本截断、表情处理、URL 提取、邮箱验证、
/// 密码强度评估等通用文本处理功能。
/// ============================================================================
class TextUtils {
  /// 统计文本字数
  ///
  /// 中文字符按字计数，英文/数字按单词计数，标点符号不计入。
  static int countWords(String text) {
    if (text.isEmpty) return 0;
    final chineseChars =
        RegExp(r'[\u4e00-\u9fa5]').allMatches(text).length;
    final englishWords = RegExp(r'[a-zA-Z0-9]+').allMatches(text).length;
    return chineseChars + englishWords;
  }

  /// 统计字符数（含所有字符，不含换行符）
  static int countChars(String text, {bool includeNewlines = false}) {
    if (text.isEmpty) return 0;
    if (includeNewlines) return text.length;
    return text.replaceAll('\n', '').length;
  }

  /// 截断文本到指定长度，超出部分添加省略号
  static String truncate(String text, int maxLength,
      {String ellipsis = '...'}) {
    if (text.length <= maxLength) return text;
    if (maxLength <= ellipsis.length) return ellipsis;
    return '${text.substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// 按单词截断（避免截断半个英文单词）
  static String truncateByWords(String text, int maxWords,
      {String ellipsis = '...'}) {
    if (text.isEmpty) return '';
    final words = text.split(RegExp(r'\s+'));
    if (words.length <= maxWords) return text;
    return '${words.take(maxWords).join(' ')}$ellipsis';
  }

  /// 去除文本中的表情符号（Emoji）
  static String removeEmojis(String text) {
    if (text.isEmpty) return '';
    // 匹配常见 Emoji 范围
    final emojiRegex = RegExp(
      r'[\u{1F300}-\u{1F9FF}]'
      r'|[\u{2600}-\u{26FF}]'
      r'|[\u{2700}-\u{27BF}]'
      r'|[\u{1F000}-\u{1F02F}]'
      r'|[\u{1F0A0}-\u{1F0FF}]'
      r'|[\u{1F100}-\u{1F64F}]'
      r'|[\u{1F680}-\u{1F6FF}]'
      r'|[\u{1F900}-\u{1F9FF}]'
      r'|[\u{200D}]'
      r'|[\u{FE0F}]',
      unicode: true,
    );
    return text.replaceAll(emojiRegex, '');
  }

  /// 判断文本是否包含表情符号
  static bool containsEmoji(String text) {
    if (text.isEmpty) return false;
    return RegExp(
      r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
      unicode: true,
    ).hasMatch(text);
  }

  /// 从文本中提取所有 URL
  static List<String> extractUrls(String text) {
    if (text.isEmpty) return [];
    final urlRegex = RegExp(
      r'https?://[^\s<>"\')\]]+',
      caseSensitive: false,
    );
    return urlRegex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  /// 判断文本是否包含 URL
  static bool containsUrl(String text) {
    if (text.isEmpty) return false;
    return RegExp(
      r'https?://[^\s<>"\')\]]+',
      caseSensitive: false,
    ).hasMatch(text);
  }

  /// 验证邮箱格式
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  /// 验证用户名格式（3-20位，字母/数字/下划线）
  static bool isValidUsername(String username) {
    if (username.isEmpty) return false;
    final trimmed = username.trim();
    if (trimmed.length < 3 || trimmed.length > 20) return false;
    return RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed);
  }

  /// 验证手机号格式（中国大陆）
  static bool isValidPhone(String phone) {
    if (phone.isEmpty) return false;
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(phone.trim());
  }

  /// 密码强度等级
  enum PasswordStrength { weak, medium, strong, veryStrong }

  /// 评估密码强度
  ///
  /// 规则：
  ///   - 弱：长度 < 6 或仅包含一种字符类型
  ///   - 中：长度 >= 6 且包含两种字符类型
  ///   - 强：长度 >= 8 且包含三种字符类型
  ///   - 极强：长度 >= 10 且包含四种字符类型（大小写+数字+特殊符号）
  static PasswordStrength checkPasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.weak;

    int typeCount = 0;
    if (RegExp(r'[a-z]').hasMatch(password)) typeCount++;
    if (RegExp(r'[A-Z]').hasMatch(password)) typeCount++;
    if (RegExp(r'[0-9]').hasMatch(password)) typeCount++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\/~`]')
        .hasMatch(password)) typeCount++;

    final len = password.length;

    if (len >= 10 && typeCount >= 4) return PasswordStrength.veryStrong;
    if (len >= 8 && typeCount >= 3) return PasswordStrength.strong;
    if (len >= 6 && typeCount >= 2) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }

  /// 获取密码强度的描述文本
  static String passwordStrengthLabel(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return '弱';
      case PasswordStrength.medium:
        return '中';
      case PasswordStrength.strong:
        return '强';
      case PasswordStrength.veryStrong:
        return '极强';
    }
  }

  /// 去除文本首尾空白并压缩内部连续空格
  static String normalizeWhitespace(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// 将文本首字母大写
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// 判断文本是否为纯数字
  static bool isNumeric(String text) {
    if (text.isEmpty) return false;
    return double.tryParse(text) != null;
  }

  /// 安全地从文本中提取数字（返回第一个匹配的整数）
  static int? extractFirstInt(String text) {
    if (text.isEmpty) return null;
    final match = RegExp(r'-?\d+').firstMatch(text);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }
}
