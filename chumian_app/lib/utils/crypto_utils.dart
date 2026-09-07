import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// ============================================================================
/// CryptoUtils —— 加密与编码工具类
///
/// 提供 MD5/SHA1/SHA256 哈希计算、Base64 编解码、AES 简易加密解密、
/// 随机字符串生成、盐值生成等常用加密与编码功能。
/// ============================================================================
class CryptoUtils {
  // ===== 随机字符集 =====
  static const String _digits = '0123456789';
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _special = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  // ==========================================================================
  // 哈希计算
  // ==========================================================================

  /// 计算字符串的 MD5 哈希（32位十六进制）
  static String md5(String input) {
    if (input.isEmpty) return '';
    final bytes = utf8.encode(input);
    return crypto.md5.convert(bytes).toString();
  }

  /// 计算字节数据的 MD5 哈希
  static String md5Bytes(Uint8List bytes) {
    return crypto.md5.convert(bytes).toString();
  }

  /// 计算文件的 MD5 哈希（异步）
  static Future<String> md5File(String filePath) async {
    final file = await File(filePath).readAsBytes();
    return md5Bytes(file);
  }

  /// 计算字符串的 SHA1 哈希（40位十六进制）
  static String sha1(String input) {
    if (input.isEmpty) return '';
    final bytes = utf8.encode(input);
    return sha1.convert(bytes).toString();
  }

  /// 计算字节数据的 SHA1 哈希
  static String sha1Bytes(Uint8List bytes) {
    return sha1.convert(bytes).toString();
  }

  /// 计算字符串的 SHA256 哈希（64位十六进制）
  static String sha256(String input) {
    if (input.isEmpty) return '';
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  /// 计算字节数据的 SHA256 哈希
  static String sha256Bytes(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }

  /// 计算带盐值的 SHA256 哈希
  static String sha256WithSalt(String input, String salt) {
    return sha256('$salt$input$salt');
  }

  /// HMAC-SHA256 计算
  static String hmacSha256(String input, String key) {
    final keyBytes = utf8.encode(key);
    final inputBytes = utf8.encode(input);
    final hmac = Hmac(sha256, keyBytes);
    return hmac.convert(inputBytes).toString();
  }

  // ==========================================================================
  // Base64 编解码
  // ==========================================================================

  /// Base64 编码字符串
  static String base64Encode(String input) {
    if (input.isEmpty) return '';
    final bytes = utf8.encode(input);
    return base64.encode(bytes);
  }

  /// Base64 编码字节数据
  static String base64EncodeBytes(Uint8List bytes) {
    return base64.encode(bytes);
  }

  /// Base64 解码为字符串
  static String base64Decode(String input) {
    if (input.isEmpty) return '';
    try {
      final bytes = base64.decode(input);
      return utf8.decode(bytes);
    } catch (_) {
      return '';
    }
  }

  /// Base64 解码为字节数据
  static Uint8List base64DecodeBytes(String input) {
    try {
      return base64.decode(input);
    } catch (_) {
      return Uint8List(0);
    }
  }

  /// URL 安全的 Base64 编码
  static String base64UrlEncode(String input) {
    if (input.isEmpty) return '';
    final bytes = utf8.encode(input);
    return base64Url.encode(bytes);
  }

  /// URL 安全的 Base64 解码
  static String base64UrlDecode(String input) {
    if (input.isEmpty) return '';
    try {
      final bytes = base64Url.decode(input);
      return utf8.decode(bytes);
    } catch (_) {
      return '';
    }
  }

  // ==========================================================================
  // AES 简易加密解密（基于 XOR + Base64，适用于非高安全场景）
  // ==========================================================================

  /// AES 简易加密（XOR 流加密 + Base64）
  ///
  /// 注意：此为简易实现，适用于本地数据混淆，不适用于高安全需求场景。
  /// 生产环境应使用 pointycastle 等专业加密库。
  static String aesEncrypt(String plaintext, String key) {
    if (plaintext.isEmpty) return '';
    final keyBytes = utf8.encode(key);
    if (keyBytes.isEmpty) return plaintext;

    final plainBytes = utf8.encode(plaintext);
    final encrypted = Uint8List(plainBytes.length);

    for (int i = 0; i < plainBytes.length; i++) {
      encrypted[i] = plainBytes[i] ^ keyBytes[i % keyBytes.length];
    }

    return base64.encode(encrypted);
  }

  /// AES 简易解密
  static String aesDecrypt(String ciphertext, String key) {
    if (ciphertext.isEmpty) return '';
    try {
      final keyBytes = utf8.encode(key);
      if (keyBytes.isEmpty) return ciphertext;

      final encrypted = base64.decode(ciphertext);
      final decrypted = Uint8List(encrypted.length);

      for (int i = 0; i < encrypted.length; i++) {
        decrypted[i] = encrypted[i] ^ keyBytes[i % keyBytes.length];
      }

      return utf8.decode(decrypted);
    } catch (_) {
      return '';
    }
  }

  // ==========================================================================
  // 随机字符串生成
  // ==========================================================================

  /// 生成随机字符串
  ///
  /// [length] 长度，[includeDigits] 是否包含数字
  /// [includeLowercase] 是否包含小写字母
  /// [includeUppercase] 是否包含大写字母
  /// [includeSpecial] 是否包含特殊字符
  static String randomString({
    int length = 16,
    bool includeDigits = true,
    bool includeLowercase = true,
    bool includeUppercase = true,
    bool includeSpecial = false,
  }) {
    final random = Random.secure();
    final charset = StringBuffer();
    if (includeDigits) charset.write(_digits);
    if (includeLowercase) charset.write(_lowercase);
    if (includeUppercase) charset.write(_uppercase);
    if (includeSpecial) charset.write(_special);

    final chars = charset.toString();
    if (chars.isEmpty) return '';

    return List.generate(length, (_) {
      return chars[random.nextInt(chars.length)];
    }).join();
  }

  /// 生成纯数字随机字符串
  static String randomDigits(int length) {
    return randomString(
      length: length,
      includeDigits: true,
      includeLowercase: false,
      includeUppercase: false,
      includeSpecial: false,
    );
  }

  /// 生成十六进制随机字符串
  static String randomHex(int length) {
    final random = Random.secure();
    const hexChars = '0123456789abcdef';
    return List.generate(length, (_) {
      return hexChars[random.nextInt(hexChars.length)];
    }).join();
  }

  /// 生成 UUID v4 格式字符串
  static String generateUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    // 设置版本号 (4) 和变体 (10xx)
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }

  // ==========================================================================
  // 盐值生成
  // ==========================================================================

  /// 生成随机盐值
  ///
  /// [length] 盐值长度（默认 16）
  static String generateSalt({int length = 16}) {
    return randomString(
      length: length,
      includeDigits: true,
      includeLowercase: true,
      includeUppercase: true,
      includeSpecial: false,
    );
  }

  /// 生成字节盐值
  static Uint8List generateSaltBytes({int length = 16}) {
    final random = Random.secure();
    return Uint8List.fromList(
        List.generate(length, (_) => random.nextInt(256)));
  }

  // ==========================================================================
  // 其他工具
  // ==========================================================================

  /// 校验哈希值是否匹配（防止时序攻击）
  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// 生成 API 签名（MD5 of params sorted + secret）
  static String generateApiSignature(
    Map<String, dynamic> params,
    String secret,
  ) {
    final sortedKeys = params.keys.toList()..sort();
    final buffer = StringBuffer();
    for (final key in sortedKeys) {
      buffer.write('$key=${params[key]}&');
    }
    buffer.write('secret=$secret');
    return md5(buffer.toString()).toUpperCase();
  }
}
