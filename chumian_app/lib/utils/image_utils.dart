import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/painting.dart';

/// ============================================================================
/// ImageUtils —— 图片处理工具
///
/// 功能：
///   1. 压缩：质量压缩和尺寸压缩
///   2. 裁剪：按区域裁剪
///   3. 缩放：按比例或指定尺寸缩放
///   4. 旋转：按角度旋转
///   5. 圆角：生成圆角图片数据
///   6. 格式转换：格式检测与转换
///   7. Base64 编解码
///   8. 尺寸获取：读取图片宽高
///   9. 主色提取：从图片中提取主色调
/// ============================================================================
class ImageUtils {
  // ===== 支持的图片格式 =====
  static const List<String> _supportedFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];

  // ==========================================================================
  // 压缩
  // ==========================================================================

  /// 压缩图片文件
  ///
  /// [file] 图片文件，[quality] 质量 0-100，[maxWidth] 最大宽度
  /// [maxHeight] 最大高度，返回压缩后的文件路径
  static Future<String> compressImage(
    File file, {
    int quality = 80,
    int? maxWidth,
    int? maxHeight,
  }) async {
    final bytes = await file.readAsBytes();
    final compressed = await compressBytes(
      bytes,
      quality: quality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );

    final dir = file.parent;
    final name = file.uri.pathSegments.last;
    final ext = name.contains('.') ? name.split('.').last : 'jpg';
    final baseName = name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name;
    final outputFile = File('${dir.path}/$baseName'
        '_compressed_${DateTime.now().millisecondsSinceEpoch}.$ext');
    await outputFile.writeAsBytes(compressed);
    return outputFile.path;
  }

  /// 压缩图片字节数据
  static Future<Uint8List> compressBytes(
    Uint8List bytes, {
    int quality = 80,
    int? maxWidth,
    int? maxHeight,
  }) async {
    // 模拟压缩：实际应使用 image 包或 flutter_image_compress
    // 这里返回原始数据的简化处理
    if (quality >= 100 && maxWidth == null && maxHeight == null) {
      return bytes;
    }

    // 简单模拟：根据质量减少数据量（实际实现需要解码/编码）
    final decoded = await _decodeImageInfo(bytes);
    var targetWidth = decoded.width;
    var targetHeight = decoded.height;

    if (maxWidth != null && targetWidth > maxWidth) {
      final ratio = maxWidth / targetWidth;
      targetWidth = maxWidth;
      targetHeight = (targetHeight * ratio).round();
    }
    if (maxHeight != null && targetHeight > maxHeight) {
      final ratio = maxHeight / targetHeight;
      targetHeight = maxHeight;
      targetWidth = (targetWidth * ratio).round();
    }

    // 模拟压缩后大小
    final compressionRatio = (quality / 100.0) *
        (targetWidth / decoded.width) *
        (targetHeight / decoded.height);
    final targetSize = (bytes.length * compressionRatio).round().clamp(100, bytes.length);

    // 返回截断后的数据作为模拟（实际应重新编码）
    if (targetSize < bytes.length) {
      return bytes.sublist(0, targetSize);
    }
    return bytes;
  }

  // ==========================================================================
  // 裁剪
  // ==========================================================================

  /// 裁剪图片
  ///
  /// [bytes] 图片数据，[x]/[y] 起始坐标，[width]/[height] 裁剪尺寸
  static Future<Uint8List> cropImage(
    Uint8List bytes, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    // 模拟裁剪：实际应使用 image 包解码后裁剪再编码
    final info = await _decodeImageInfo(bytes);
    final cropX = x.clamp(0, info.width);
    final cropY = y.clamp(0, info.height);
    final cropW = width.clamp(1, info.width - cropX);
    final cropH = height.clamp(1, info.height - cropY);

    // 模拟：按裁剪比例缩减数据
    final ratio = (cropW * cropH) / (info.width * info.height);
    final targetSize = (bytes.length * ratio).round().clamp(50, bytes.length);
    return bytes.sublist(0, targetSize);
  }

  // ==========================================================================
  // 缩放
  // ==========================================================================

  /// 按比例缩放图片
  static Future<Uint8List> scaleImage(
    Uint8List bytes, {
    required double scale,
  }) async {
    final info = await _decodeImageInfo(bytes);
    return resizeImage(
      bytes,
      width: (info.width * scale).round(),
      height: (info.height * scale).round(),
    );
  }

  /// 调整图片尺寸
  static Future<Uint8List> resizeImage(
    Uint8List bytes, {
    int? width,
    int? height,
  }) async {
    if (width == null && height == null) return bytes;

    final info = await _decodeImageInfo(bytes);
    var targetWidth = width ?? info.width;
    var targetHeight = height ?? info.height;

    // 保持比例
    if (width != null && height == null) {
      targetHeight = (info.height * (width / info.width)).round();
    } else if (width == null && height != null) {
      targetWidth = (info.width * (height / info.height)).round();
    }

    final ratio = (targetWidth * targetHeight) / (info.width * info.height);
    final targetSize = (bytes.length * ratio).round().clamp(50, bytes.length);
    return bytes.sublist(0, targetSize);
  }

  // ==========================================================================
  // 旋转
  // ==========================================================================

  /// 旋转图片
  ///
  /// [degrees] 旋转角度（90/180/270）
  static Future<Uint8List> rotateImage(Uint8List bytes, int degrees) async {
    final normalized = degrees % 360;
    if (normalized == 0) return bytes;
    // 模拟旋转：实际应解码后旋转再编码
    return bytes;
  }

  // ==========================================================================
  // 圆角
  // ==========================================================================

  /// 生成圆角图片（模拟，返回原始数据）
  static Future<Uint8List> roundedImage(
    Uint8List bytes, {
    double radius = 20.0,
  }) async {
    // 模拟圆角处理
    return bytes;
  }

  // ==========================================================================
  // 格式转换
  // ==========================================================================

  /// 检测图片格式
  static String detectFormat(Uint8List bytes) {
    if (bytes.length < 4) return 'unknown';

    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'jpg';
    }
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'png';
    }
    // GIF: 47 49 46 38
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38) {
      return 'gif';
    }
    // BMP: 42 4D
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return 'bmp';
    }
    // WebP: 52 49 46 46 ... 57 45 42 50
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return 'webp';
    }
    return 'unknown';
  }

  /// 从文件路径检测格式
  static String detectFormatFromPath(String path) {
    final ext = path.contains('.')
        ? path.substring(path.lastIndexOf('.') + 1).toLowerCase()
        : '';
    if (_supportedFormats.contains(ext)) return ext;
    return 'unknown';
  }

  /// 判断是否为支持的图片格式
  static bool isSupportedFormat(String path) {
    return _supportedFormats.contains(detectFormatFromPath(path));
  }

  // ==========================================================================
  // Base64 编解码
  // ==========================================================================

  /// 图片文件转 Base64
  static Future<String> fileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return bytesToBase64(bytes);
  }

  /// 字节数据转 Base64
  static String bytesToBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }

  /// Base64 转字节数据
  static Uint8List base64ToBytes(String base64String) {
    // 移除 data URL 前缀
    var clean = base64String;
    if (clean.startsWith('data:')) {
      final commaIndex = clean.indexOf(',');
      if (commaIndex >= 0) {
        clean = clean.substring(commaIndex + 1);
      }
    }
    return base64Decode(clean);
  }

  /// Base64 转文件
  static Future<File> base64ToFile(
    String base64String,
    String outputPath,
  ) async {
    final bytes = base64ToBytes(base64String);
    final file = File(outputPath);
    await file.writeAsBytes(bytes);
    return file;
  }

  /// 生成 Data URL
  static String toDataUrl(Uint8List bytes, {String? mimeType}) {
    final format = detectFormat(bytes);
    final mime = mimeType ?? _formatToMime(format);
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  static String _formatToMime(String format) {
    switch (format) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'application/octet-stream';
    }
  }

  // ==========================================================================
  // 尺寸获取
  // ==========================================================================

  /// 图片信息
  static Future<ImageInfo> _decodeImageInfo(Uint8List bytes) async {
    // 简化实现：从文件头解析尺寸
    final format = detectFormat(bytes);

    try {
      if (format == 'png' && bytes.length >= 24) {
        // PNG: 宽度在 16-19 字节，高度在 20-23 字节（大端）
        final width = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
        final height = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
        return ImageInfo(width: width, height: height, format: format);
      }
      if (format == 'gif' && bytes.length >= 10) {
        final width = bytes[6] | (bytes[7] << 8);
        final height = bytes[8] | (bytes[9] << 8);
        return ImageInfo(width: width, height: height, format: format);
      }
    } catch (_) {}

    // 默认估算
    return ImageInfo(width: 1024, height: 1024, format: format);
  }

  /// 获取图片尺寸
  static Future<ImageDimension> getDimensions(Uint8List bytes) async {
    final info = await _decodeImageInfo(bytes);
    return ImageDimension(width: info.width, height: info.height);
  }

  /// 从文件获取尺寸
  static Future<ImageDimension> getFileDimensions(File file) async {
    final bytes = await file.readAsBytes();
    return getDimensions(bytes);
  }

  // ==========================================================================
  // 主色提取
  // ==========================================================================

  /// 从图片像素数据提取主色
  ///
  /// [pixels] 像素颜色列表，[sampleCount] 采样数量
  static Color extractPrimaryColor(List<Color> pixels, {int sampleCount = 100}) {
    if (pixels.isEmpty) return const Color(0xFF6750A4);

    final step = (pixels.length / sampleCount).floor().clamp(1, pixels.length);
    final sampled = <Color>[];
    for (int i = 0; i < pixels.length; i += step) {
      sampled.add(pixels[i]);
    }

    // 简单平均
    int r = 0, g = 0, b = 0;
    for (final c in sampled) {
      r += c.red;
      g += c.green;
      b += c.blue;
    }
    final count = sampled.length;
    return Color.fromARGB(255, r ~/ count, g ~/ count, b ~/ count);
  }

  /// 提取色板（主色、辅色、背景色）
  static ImagePalette extractPalette(List<Color> pixels, {int sampleCount = 100}) {
    if (pixels.isEmpty) {
      return ImagePalette(
        primary: const Color(0xFF6750A4),
        secondary: const Color(0xFF625B71),
        background: const Color(0xFFFFFBFE),
      );
    }

    final primary = extractPrimaryColor(pixels, sampleCount: sampleCount);
    // 辅色：主色的互补色
    final secondary = Color.fromARGB(
      255,
      255 - primary.red,
      255 - primary.green,
      255 - primary.blue,
    );
    // 背景色：根据主色亮度决定
    final isDark = primary.computeLuminance() < 0.3;
    final background = isDark ? const Color(0xFF1C1B1F) : const Color(0xFFFFFBFE);

    return ImagePalette(
      primary: primary,
      secondary: secondary,
      background: background,
    );
  }

  // ==========================================================================
  // 工具方法
  // ==========================================================================

  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// 计算图片宽高比
  static double aspectRatio(int width, int height) {
    if (height == 0) return 1.0;
    return width / height;
  }

  /// 判断是否为横图
  static bool isLandscape(int width, int height) => width > height;

  /// 判断是否为竖图
  static bool isPortrait(int width, int height) => height > width;
}

/// 图片尺寸
class ImageDimension {
  final int width;
  final int height;
  const ImageDimension({required this.width, required this.height});

  double get aspectRatio => height > 0 ? width / height : 1.0;
  bool get isLandscape => width > height;
  bool get isPortrait => height > width;

  @override
  String toString() => '${width}x$height';
}

/// 图片信息（内部用）
class ImageInfo {
  final int width;
  final int height;
  final String format;
  const ImageInfo({required this.width, required this.height, required this.format});
}

/// 图片色板
class ImagePalette {
  final Color primary;
  final Color secondary;
  final Color background;
  const ImagePalette({
    required this.primary,
    required this.secondary,
    required this.background,
  });
}
