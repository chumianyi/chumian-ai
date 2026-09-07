import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// ============================================================================
/// CompressionUtils —— 压缩工具
///
/// 功能：
///   1. GZIP 压缩/解压：字节级 GZIP 压缩
///   2. 字符串压缩：字符串的压缩与解压
///   3. Base64 压缩：压缩后再 Base64 编码
///   4. 压缩率计算：计算压缩前后的比率
/// ============================================================================
class CompressionUtils {
  // ==========================================================================
  // GZIP 压缩/解压
  // ==========================================================================

  /// GZIP 压缩字节数据
  static Uint8List gzipCompress(List<int> data) {
    final compressed = gzip.encode(data);
    return Uint8List.fromList(compressed);
  }

  /// GZIP 解压字节数据
  static Uint8List gzipDecompress(List<int> data) {
    final decompressed = gzip.decode(data);
    return Uint8List.fromList(decompressed);
  }

  /// GZIP 压缩文件
  static Future<File> gzipCompressFile(
    File inputFile, {
    String? outputPath,
  }) async {
    final bytes = await inputFile.readAsBytes();
    final compressed = gzipCompress(bytes);
    final output = outputPath != null
        ? File(outputPath)
        : File('${inputFile.path}.gz');
    await output.writeAsBytes(compressed);
    return output;
  }

  /// GZIP 解压文件
  static Future<File> gzipDecompressFile(
    File inputFile, {
    String? outputPath,
  }) async {
    final bytes = await inputFile.readAsBytes();
    final decompressed = gzipDecompress(bytes);
    final output = outputPath != null
        ? File(outputPath)
        : File(inputFile.path.replaceAll(RegExp(r'\.gz$'), ''));
    await output.writeAsBytes(decompressed);
    return output;
  }

  // ==========================================================================
  // 字符串压缩
  // ==========================================================================

  /// 压缩字符串
  ///
  /// 返回压缩后的字节数据
  static Uint8List compressString(String text) {
    final bytes = utf8.encode(text);
    return gzipCompress(bytes);
  }

  /// 解压字符串
  static String decompressString(List<int> data) {
    final bytes = gzipDecompress(data);
    return utf8.decode(bytes);
  }

  /// 压缩字符串并返回 Base64 编码
  static String compressStringToBase64(String text) {
    final compressed = compressString(text);
    return base64Encode(compressed);
  }

  /// 从 Base64 编码解压字符串
  static String decompressStringFromBase64(String base64String) {
    final bytes = base64Decode(base64String);
    return decompressString(bytes);
  }

  // ==========================================================================
  // Base64 压缩
  // ==========================================================================

  /// 压缩字节数据并 Base64 编码
  static String compressToBase64(List<int> data) {
    final compressed = gzipCompress(data);
    return base64Encode(compressed);
  }

  /// 从 Base64 编码解压字节数据
  static Uint8List decompressFromBase64(String base64String) {
    final bytes = base64Decode(base64String);
    return gzipDecompress(bytes);
  }

  // ==========================================================================
  // 压缩率计算
  // ==========================================================================

  /// 计算压缩率（0.0 - 1.0，越小压缩越好）
  ///
  /// [originalSize] 原始大小，[compressedSize] 压缩后大小
  static double compressionRatio(int originalSize, int compressedSize) {
    if (originalSize == 0) return 1.0;
    return compressedSize / originalSize;
  }

  /// 计算节省的空间百分比（0.0 - 1.0）
  static double savedPercentage(int originalSize, int compressedSize) {
    if (originalSize == 0) return 0.0;
    return (originalSize - compressedSize) / originalSize;
  }

  /// 计算压缩倍数
  static double compressionFactor(int originalSize, int compressedSize) {
    if (compressedSize == 0) return double.infinity;
    return originalSize / compressedSize;
  }

  /// 格式化压缩率为可读文本
  static String formatCompressionRatio(int originalSize, int compressedSize) {
    final ratio = compressionRatio(originalSize, compressedSize);
    final saved = savedPercentage(originalSize, compressedSize);
    return '压缩率: ${(ratio * 100).toStringAsFixed(1)}%, '
        '节省: ${(saved * 100).toStringAsFixed(1)}%';
  }

  // ==========================================================================
  // 批量压缩
  // ==========================================================================

  /// 批量压缩字符串列表
  static List<Uint8List> compressStrings(List<String> texts) {
    return texts.map(compressString).toList();
  }

  /// 批量解压字符串列表
  static List<String> decompressStrings(List<List<int>> dataList) {
    return dataList.map(decompressString).toList();
  }

  /// 压缩 Map 为 JSON 后再压缩
  static Uint8List compressJson(Map<String, dynamic> json) {
    final jsonString = jsonEncode(json);
    return compressString(jsonString);
  }

  /// 解压为 JSON Map
  static Map<String, dynamic> decompressJson(List<int> data) {
    final jsonString = decompressString(data);
    return Map<String, dynamic>.from(jsonDecode(jsonString) as Map);
  }

  /// 压缩 JSON Map 并 Base64 编码
  static String compressJsonToBase64(Map<String, dynamic> json) {
    final compressed = compressJson(json);
    return base64Encode(compressed);
  }

  /// 从 Base64 解压为 JSON Map
  static Map<String, dynamic> decompressJsonFromBase64(String base64String) {
    final bytes = base64Decode(base64String);
    return decompressJson(bytes);
  }

  // ==========================================================================
  // 文件大小估算
  // ==========================================================================

  /// 估算压缩后的文件大小
  ///
  /// [originalSize] 原始大小，[expectedRatio] 预期压缩率（文本约 0.3，图片约 0.9）
  static int estimateCompressedSize(int originalSize,
      {double expectedRatio = 0.5}) {
    return (originalSize * expectedRatio).round();
  }

  /// 根据内容类型估算压缩率
  static double estimateRatioByContentType(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'text/plain':
      case 'text/html':
      case 'text/css':
      case 'application/json':
      case 'application/xml':
      case 'text/csv':
        return 0.3;
      case 'application/javascript':
        return 0.35;
      case 'image/png':
        return 0.95;
      case 'image/jpeg':
      case 'image/webp':
        return 0.98;
      case 'audio/mpeg':
      case 'audio/ogg':
        return 0.95;
      case 'video/mp4':
      case 'video/webm':
        return 0.98;
      case 'application/zip':
      case 'application/gzip':
        return 1.0;
      default:
        return 0.5;
    }
  }

  // ==========================================================================
  // 工具方法
  // ==========================================================================

  /// 检查数据是否为 GZIP 压缩格式
  static bool isGzip(List<int> data) {
    if (data.length < 2) return false;
    // GZIP 魔数: 1F 8B
    return data[0] == 0x1F && data[1] == 0x8B;
  }

  /// 检查 Base64 字符串是否可能是压缩数据
  static bool isCompressedBase64(String base64String) {
    try {
      final bytes = base64Decode(base64String);
      return isGzip(bytes);
    } catch (_) {
      return false;
    }
  }

  /// 格式化字节大小
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// 压缩并返回统计信息
  static CompressionResult compressWithStats(List<int> data) {
    final compressed = gzipCompress(data);
    return CompressionResult(
      originalSize: data.length,
      compressedSize: compressed.length,
      data: compressed,
      ratio: compressionRatio(data.length, compressed.length),
      savedPercentage: savedPercentage(data.length, compressed.length),
    );
  }

  /// 压缩字符串并返回统计信息
  static CompressionResult compressStringWithStats(String text) {
    final originalBytes = utf8.encode(text);
    final compressed = compressString(text);
    return CompressionResult(
      originalSize: originalBytes.length,
      compressedSize: compressed.length,
      data: compressed,
      ratio: compressionRatio(originalBytes.length, compressed.length),
      savedPercentage:
          savedPercentage(originalBytes.length, compressed.length),
    );
  }
}

/// 压缩结果
class CompressionResult {
  final int originalSize;
  final int compressedSize;
  final Uint8List data;
  final double ratio;
  final double savedPercentage;

  CompressionResult({
    required this.originalSize,
    required this.compressedSize,
    required this.data,
    required this.ratio,
    required this.savedPercentage,
  });

  int get savedBytes => originalSize - compressedSize;

  @override
  String toString() {
    return 'CompressionResult('
        'original: ${CompressionUtils.formatBytes(originalSize)}, '
        'compressed: ${CompressionUtils.formatBytes(compressedSize)}, '
        'saved: ${(savedPercentage * 100).toStringAsFixed(1)}%'
        ')';
  }
}
