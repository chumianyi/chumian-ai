import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// ============================================================================
/// UuidUtils —— UUID 生成工具
///
/// 功能：
///   1. UUID v1：基于时间戳的 UUID
///   2. UUID v4：基于随机数的 UUID
///   3. UUID v5：基于命名空间和名称的 SHA-1 哈希 UUID
///   4. 短 ID：生成短唯一标识符
///   5. Nano ID：生成 URL 友好的短 ID
///   6. 唯一文件名：生成不冲突的文件名
///   7. 会话 ID：生成会话标识符
/// ============================================================================
class UuidUtils {
  // ===== UUID 命名空间 =====
  /// DNS 命名空间
  static const String namespaceDns = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';

  /// URL 命名空间
  static const String namespaceUrl = '6ba7b811-9dad-11d1-80b4-00c04fd430c8';

  /// OID 命名空间
  static const String namespaceOid = '6ba7b812-9dad-11d1-80b4-00c04fd430c8';

  /// X500 命名空间
  static const String namespaceX500 = '6ba7b814-9dad-11d1-80b4-00c04fd430c8';

  // ===== Nano ID 默认字符集 =====
  static const String _defaultAlphabet =
      'ModuleSymbhasOwnPr-0123456789ABCDEFGHNRVfgctiUvz_KqYTJkLxpZXIjQW';

  static final Random _random = Random.secure();

  // ==========================================================================
  // UUID v4（随机）
  // ==========================================================================

  /// 生成 UUID v4（随机 UUID）
  static String v4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    // 设置版本号为 4（0100）
    bytes[6] = (bytes[6] & 0x0F) | 0x40;

    // 设置变体位为 10
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    return _formatUuid(bytes);
  }

  /// 生成不带连字符的 UUID v4
  static String v4NoHyphen() {
    return v4().replaceAll('-', '');
  }

  // ==========================================================================
  // UUID v1（时间戳）
  // ==========================================================================

  /// 生成 UUID v1（基于时间戳）
  ///
  /// [nodeId] 节点 ID（6 字节），不传则随机生成
  static String v1({List<int>? nodeId}) {
    // 时间戳：从 1582-10-15 00:00:00 UTC 开始的 100 纳秒间隔数
    final now = DateTime.now().toUtc();
    final gregorianEpoch = DateTime.utc(1582, 10, 15);
    final elapsed = now.difference(gregorianEpoch);
    final timestamp = elapsed.inMicroseconds * 10 + 0x01b21dd213814000;

    final bytes = List<int>.filled(16, 0);

    // time_low（前 32 位）
    bytes[0] = (timestamp >> 24) & 0xFF;
    bytes[1] = (timestamp >> 16) & 0xFF;
    bytes[2] = (timestamp >> 8) & 0xFF;
    bytes[3] = timestamp & 0xFF;

    // time_mid（接下来 16 位）
    bytes[4] = (timestamp >> 40) & 0xFF;
    bytes[5] = (timestamp >> 32) & 0xFF;

    // time_hi_and_version（接下来 16 位，版本号为 1）
    bytes[6] = ((timestamp >> 56) & 0x0F) | 0x10;
    bytes[7] = (timestamp >> 48) & 0xFF;

    // clock_seq（16 位，变体为 10）
    final clockSeq = _random.nextInt(0x4000);
    bytes[8] = ((clockSeq >> 8) & 0x3F) | 0x80;
    bytes[9] = clockSeq & 0xFF;

    // node（48 位）
    final node = nodeId ?? List<int>.generate(6, (_) => _random.nextInt(256));
    for (int i = 0; i < 6; i++) {
      bytes[10 + i] = node[i];
    }

    return _formatUuid(bytes);
  }

  // ==========================================================================
  // UUID v5（SHA-1 哈希）
  // ==========================================================================

  /// 生成 UUID v5（基于命名空间和名称的 SHA-1 哈希）
  ///
  /// [namespace] 命名空间 UUID，[name] 名称字符串
  static String v5(String namespace, String name) {
    final namespaceBytes = _parseUuid(namespace);
    final nameBytes = utf8.encode(name);
    final combined = [...namespaceBytes, ...nameBytes];

    final hash = sha1.convert(combined).bytes;
    final bytes = hash.sublist(0, 16);

    // 设置版本号为 5
    bytes[6] = (bytes[6] & 0x0F) | 0x50;

    // 设置变体位为 10
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    return _formatUuid(bytes);
  }

  /// 使用 DNS 命名空间生成 UUID v5
  static String v5Dns(String name) => v5(namespaceDns, name);

  /// 使用 URL 命名空间生成 UUID v5
  static String v5Url(String url) => v5(namespaceUrl, url);

  // ==========================================================================
  // 短 ID
  // ==========================================================================

  /// 生成短 ID（基于时间戳 + 随机数）
  ///
  /// [length] 长度（默认 12）
  static String shortId({int length = 12}) {
    final chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final randomPart = List.generate(
      length - timestamp.length.clamp(0, length),
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
    return (timestamp + randomPart).substring(0, length.clamp(4, 32));
  }

  /// 生成数字短 ID（仅数字）
  static String numericShortId({int length = 8}) {
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(_random.nextInt(10));
    }
    return buffer.toString();
  }

  // ==========================================================================
  // Nano ID
  // ==========================================================================

  /// 生成 Nano ID（URL 友好的短 ID）
  ///
  /// [size] 长度（默认 21），[alphabet] 自定义字符集
  static String nanoId({int size = 21, String? alphabet}) {
    final chars = alphabet ?? _defaultAlphabet;
    final mask = (2 << (log(chars.length - 1) ~/ ln2)) - 1;
    final step = (1.6 * mask * size / chars.length).ceil();

    final result = StringBuffer();
    while (result.length < size) {
      final randomBytes = List<int>.generate(step, (_) => _random.nextInt(256));
      for (int i = 0; i < step && result.length < size; i++) {
        final index = randomBytes[i] & mask;
        if (index < chars.length) {
          result.write(chars[index]);
        }
      }
    }
    return result.toString();
  }

  /// 生成仅小写字母的 Nano ID
  static String nanoIdLower({int size = 21}) {
    return nanoId(size: size, alphabet: 'abcdefghijklmnopqrstuvwxyz');
  }

  /// 生成仅数字的 Nano ID
  static String nanoIdNumeric({int size = 21}) {
    return nanoId(size: size, alphabet: '0123456789');
  }

  // ==========================================================================
  // 唯一文件名
  // ==========================================================================

  /// 生成唯一文件名
  ///
  /// [extension] 文件扩展名（不含点），[prefix] 文件名前缀
  static String uniqueFileName({
    String extension = 'tmp',
    String prefix = '',
  }) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = _random.nextInt(0xFFFF).toRadixString(16).padLeft(4, '0');
    final prefixStr = prefix.isNotEmpty ? '${prefix}_' : '';
    return '$prefixStr${timestamp}_$random.$extension';
  }

  /// 生成基于内容哈希的文件名
  static String contentHashFileName(List<int> content, {String extension = 'bin'}) {
    final hash = sha256.convert(content).toString();
    return '${hash.substring(0, 16)}.$extension';
  }

  // ==========================================================================
  // 会话 ID
  // ==========================================================================

  /// 生成会话 ID
  static String sessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final random = List.generate(8, (_) => _random.nextInt(36).toRadixString(36)).join();
    return 'sess_$timestamp$random';
  }

  /// 生成短会话 ID
  static String shortSessionId() {
    return 's_${nanoId(size: 16)}';
  }

  // ==========================================================================
  // 验证与解析
  // ==========================================================================

  /// 验证是否为有效的 UUID
  static bool isValidUuid(String uuid) {
    final regex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return regex.hasMatch(uuid);
  }

  /// 获取 UUID 版本号
  static int? getVersion(String uuid) {
    if (!isValidUuid(uuid)) return null;
    final versionChar = uuid[14];
    return int.tryParse(versionChar, radix: 16);
  }

  /// 解析 UUID 为字节数组
  static List<int> _parseUuid(String uuid) {
    final clean = uuid.replaceAll('-', '');
    final bytes = <int>[];
    for (int i = 0; i < clean.length; i += 2) {
      bytes.add(int.parse(clean.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }

  /// 格式化字节数组为 UUID 字符串
  static String _formatUuid(List<int> bytes) {
    String hex(int value) => value.toRadixString(16).padLeft(2, '0');

    return '${hex(bytes[0])}${hex(bytes[1])}${hex(bytes[2])}${hex(bytes[3])}-'
        '${hex(bytes[4])}${hex(bytes[5])}-'
        '${hex(bytes[6])}${hex(bytes[7])}-'
        '${hex(bytes[8])}${hex(bytes[9])}-'
        '${hex(bytes[10])}${hex(bytes[11])}${hex(bytes[12])}'
        '${hex(bytes[13])}${hex(bytes[14])}${hex(bytes[15])}';
  }

  // ==========================================================================
  // 工具方法
  // ==========================================================================

  /// 生成指定数量的唯一 ID
  static List<String> generateBatch(int count, {String Function() generator = v4}) {
    final ids = <String>{};
    while (ids.length < count) {
      ids.add(generator());
    }
    return ids.toList();
  }

  /// 比较两个 UUID 是否相等（忽略大小写和格式）
  static bool equals(String uuid1, String uuid2) {
    return uuid1.toLowerCase().replaceAll('-', '') ==
        uuid2.toLowerCase().replaceAll('-', '');
  }

  /// 将 UUID 转为大写
  static String toUpperCase(String uuid) => uuid.toUpperCase();

  /// 将 UUID 转为小写
  static String toLowerCase(String uuid) => uuid.toLowerCase();

  /// 移除 UUID 中的连字符
  static String removeHyphens(String uuid) => uuid.replaceAll('-', '');

  /// 添加连字符（将 32 位十六进制字符串转为 UUID 格式）
  static String addHyphens(String hex) {
    if (hex.length != 32) return hex;
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
