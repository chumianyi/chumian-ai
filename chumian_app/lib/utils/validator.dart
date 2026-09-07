import 'package:chumian_ai/utils/regex_utils.dart';

/// ============================================================================
/// Validator —— 表单验证器集合
///
/// 提供用户名、密码、邮箱、手机号、昵称、URL、身份证等
/// 常用表单字段的验证方法，返回错误消息（null 表示验证通过）。
/// 支持实时验证和联合验证。
/// ============================================================================
class Validator {
  // ==========================================================================
  // 通用验证
  // ==========================================================================

  /// 必填验证
  static String? required(String? value, {String fieldName = '该字段'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName不能为空';
    }
    return null;
  }

  /// 最小长度验证
  static String? minLength(String? value, int min, {String fieldName = '该字段'}) {
    if (value == null || value.isEmpty) return null; // 空值由 required 处理
    if (value.length < min) {
      return '$fieldName至少需要 $min 个字符';
    }
    return null;
  }

  /// 最大长度验证
  static String? maxLength(String? value, int max, {String fieldName = '该字段'}) {
    if (value == null || value.isEmpty) return null;
    if (value.length > max) {
      return '$fieldName不能超过 $max 个字符';
    }
    return null;
  }

  /// 长度范围验证
  static String? lengthRange(
    String? value,
    int min,
    int max, {
    String fieldName = '该字段',
  }) {
    if (value == null || value.isEmpty) return null;
    if (value.length < min || value.length > max) {
      return '$fieldName长度需在 $min-$max 个字符之间';
    }
    return null;
  }

  // ==========================================================================
  // 用户名验证
  // ==========================================================================

  /// 验证用户名
  ///
  /// 规则：3-20位，字母/数字/下划线，不能以数字开头
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '用户名不能为空';
    }
    final trimmed = value.trim();
    if (trimmed.length < 3 || trimmed.length > 20) {
      return '用户名长度需在 3-20 个字符之间';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
      return '用户名只能包含字母、数字和下划线';
    }
    if (RegExp(r'^[0-9]').hasMatch(trimmed)) {
      return '用户名不能以数字开头';
    }
    return null;
  }

  // ==========================================================================
  // 密码验证
  // ==========================================================================

  /// 验证密码
  ///
  /// 规则：至少6位，包含字母和数字
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return '密码不能为空';
    }
    if (value.length < 6) {
      return '密码至少需要 6 个字符';
    }
    if (value.length > 64) {
      return '密码不能超过 64 个字符';
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
      return '密码必须包含字母';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return '密码必须包含数字';
    }
    return null;
  }

  /// 验证强密码
  ///
  /// 规则：至少8位，包含大小写字母、数字和特殊字符
  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return '密码不能为空';
    }
    if (value.length < 8) {
      return '密码至少需要 8 个字符';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return '密码必须包含小写字母';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return '密码必须包含大写字母';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return '密码必须包含数字';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\/~`]').hasMatch(value)) {
      return '密码必须包含特殊字符';
    }
    return null;
  }

  /// 验证确认密码
  static String? confirmPassword(String? value, String? original) {
    if (value == null || value.isEmpty) {
      return '请确认密码';
    }
    if (value != original) {
      return '两次输入的密码不一致';
    }
    return null;
  }

  // ==========================================================================
  // 邮箱验证
  // ==========================================================================

  /// 验证邮箱
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '邮箱不能为空';
    }
    if (!RegexUtils.isEmail(value)) {
      return '请输入有效的邮箱地址';
    }
    if (value.length > 100) {
      return '邮箱地址过长';
    }
    return null;
  }

  // ==========================================================================
  // 手机号验证
  // ==========================================================================

  /// 验证手机号（中国大陆）
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '手机号不能为空';
    }
    final cleaned = value.trim().replaceAll(RegExp(r'\s|-'), '');
    if (!RegexUtils.isPhone(cleaned)) {
      return '请输入有效的手机号码';
    }
    return null;
  }

  /// 验证手机号验证码
  static String? smsCode(String? value, {int length = 6}) {
    if (value == null || value.trim().isEmpty) {
      return '验证码不能为空';
    }
    final cleaned = value.trim();
    if (cleaned.length != length) {
      return '验证码为 $length 位数字';
    }
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return '验证码只能包含数字';
    }
    return null;
  }

  // ==========================================================================
  // 昵称验证
  // ==========================================================================

  /// 验证昵称
  ///
  /// 规则：2-20位，支持中文、字母、数字、下划线
  static String? nickname(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '昵称不能为空';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2 || trimmed.length > 20) {
      return '昵称长度需在 2-20 个字符之间';
    }
    if (!RegExp(r'^[\u4e00-\u9fa5a-zA-Z0-9_]+$').hasMatch(trimmed)) {
      return '昵称只能包含中文、字母、数字和下划线';
    }
    return null;
  }

  // ==========================================================================
  // URL 验证
  // ==========================================================================

  /// 验证 URL
  static String? url(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? '链接不能为空' : null;
    }
    if (!RegexUtils.isUrl(value)) {
      return '请输入有效的 URL 链接';
    }
    return null;
  }

  // ==========================================================================
  // 身份证验证
  // ==========================================================================

  /// 验证身份证号
  static String? idCard(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '身份证号不能为空';
    }
    final cleaned = value.trim().toUpperCase();
    if (!RegexUtils.isIdCard(cleaned)) {
      return '请输入有效的身份证号';
    }
    return null;
  }

  // ==========================================================================
  // 实时验证
  // ==========================================================================

  /// 实时验证（输入过程中调用，不显示空值错误）
  static String? liveValidate(
    String? value,
    String? Function(String?) validator,
  ) {
    if (value == null || value.isEmpty) return null;
    return validator(value);
  }

  // ==========================================================================
  // 联合验证
  // ==========================================================================

  /// 联合多个验证器，返回第一个错误
  static String? combine(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }

  /// 验证注册表单（用户名 + 密码 + 确认密码 + 邮箱）
  static Map<String, String?> validateRegister({
    String? username,
    String? password,
    String? confirmPassword,
    String? email,
  }) {
    return {
      'username': Validator.username(username),
      'password': Validator.password(password),
      'confirmPassword': Validator.confirmPassword(confirmPassword, password),
      'email': Validator.email(email),
    };
  }

  /// 验证登录表单
  static Map<String, String?> validateLogin({
    String? account,
    String? password,
  }) {
    return {
      'account': required(account, fieldName: '账号'),
      'password': required(password, fieldName: '密码'),
    };
  }

  /// 验证个人资料表单
  static Map<String, String?> validateProfile({
    String? nickname,
    String? phone,
    String? email,
  }) {
    return {
      'nickname': Validator.nickname(nickname),
      'phone': phone == null || phone.isEmpty ? null : Validator.phone(phone),
      'email': email == null || email.isEmpty ? null : Validator.email(email),
    };
  }

  // ==========================================================================
  // 其他验证
  // ==========================================================================

  /// 验证年龄（18-120）
  static String? age(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '年龄不能为空';
    }
    final age = int.tryParse(value.trim());
    if (age == null) {
      return '请输入有效的年龄';
    }
    if (age < 1 || age > 120) {
      return '年龄需在 1-120 之间';
    }
    return null;
  }

  /// 验证金额
  static String? amount(String? value, {double? min, double? max}) {
    if (value == null || value.trim().isEmpty) {
      return '金额不能为空';
    }
    final amount = double.tryParse(value.trim());
    if (amount == null) {
      return '请输入有效的金额';
    }
    if (amount <= 0) {
      return '金额必须大于 0';
    }
    if (min != null && amount < min) {
      return '金额不能少于 $min';
    }
    if (max != null && amount > max) {
      return '金额不能超过 $max';
    }
    return null;
  }

  /// 验证验证码（图形验证码）
  static String? captcha(String? value, {int length = 4}) {
    if (value == null || value.trim().isEmpty) {
      return '验证码不能为空';
    }
    if (value.trim().length != length) {
      return '验证码为 $length 位';
    }
    return null;
  }
}
