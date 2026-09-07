import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';

/// ============================================================================
/// ImageEditService —— 图片编辑服务
///
/// 职责：
///   1. 图片压缩：质量压缩与尺寸压缩
///   2. 图片裁剪：按比例裁剪
///   3. 圆角处理：生成圆角图片
///   4. 粉色滤镜：应用粉色主题滤镜
///   5. 水印添加：文字/图片水印
///   6. 保存到相册
///   7. 质量控制与格式转换
///
/// 依赖 image 包进行底层图像处理。
/// ============================================================================
class ImageEditService {
  /// 单例实例
  static final ImageEditService _instance = ImageEditService._internal();
  factory ImageEditService() => _instance;
  ImageEditService._internal();

  // ===== 粉色滤镜参数 =====
  static const double _pinkFilterR = 1.1;
  static const double _pinkFilterG = 0.95;
  static const double _pinkFilterB = 1.05;

  // ==========================================================================
  // 图片压缩
  // ==========================================================================

  /// 压缩图片（质量 + 尺寸）
  ///
  /// [imagePath] 原图路径，[quality] 输出质量 0-100
  /// [maxWidth] 最大宽度，[maxHeight] 最大高度
  /// 返回压缩后的图片文件路径
  Future<String?> compressImage({
    required String imagePath,
    int quality = 80,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) return null;

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      var processed = image;

      // 尺寸压缩
      if (maxWidth != null || maxHeight != null) {
        final targetW = maxWidth ?? image.width;
        final targetH = maxHeight ?? image.height;
        if (image.width > targetW || image.height > targetH) {
          processed = img.copyResize(
            image,
            width: image.width > image.height ? targetW : null,
            height: image.width <= image.height ? targetH : null,
            interpolation: img.Interpolation.linear,
          );
        }
      }

      // 质量压缩（编码为 JPEG）
      final compressedBytes = img.encodeJpg(processed, quality: quality);

      // 保存到临时目录
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final outputFile = File('${tempDir.path}/$fileName');
      await outputFile.writeAsBytes(compressedBytes);

      return outputFile.path;
    } catch (_) {
      return null;
    }
  }

  /// 压缩图片到指定大小以下（字节）
  Future<String?> compressImageToSize({
    required String imagePath,
    required int maxBytes,
    int startQuality = 90,
    int minQuality = 30,
  }) async {
    var quality = startQuality;
    String? resultPath;

    while (quality >= minQuality) {
      resultPath = await compressImage(
        imagePath: imagePath,
        quality: quality,
      );
      if (resultPath == null) return null;

      final file = File(resultPath);
      if (await file.length() <= maxBytes) {
        return resultPath;
      }
      quality -= 10;
    }
    return resultPath;
  }

  // ==========================================================================
  // 图片裁剪
  // ==========================================================================

  /// 按比例裁剪图片
  ///
  /// [ratio] 宽高比，如 1.0（方形）、0.75（3:4）
  Future<String?> cropImage({
    required String imagePath,
    required double ratio,
  }) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final imgRatio = image.width / image.height;
      int cropX, cropY, cropW, cropH;

      if (imgRatio > ratio) {
        // 原图更宽，裁剪宽度
        cropH = image.height;
        cropW = (cropH * ratio).round();
        cropX = ((image.width - cropW) / 2).round();
        cropY = 0;
      } else {
        // 原图更高，裁剪高度
        cropW = image.width;
        cropH = (cropW / ratio).round();
        cropX = 0;
        cropY = ((image.height - cropH) / 2).round();
      }

      final cropped = img.copyCrop(
        image,
        x: cropX,
        y: cropY,
        width: cropW,
        height: cropH,
      );

      final tempDir = await getTemporaryDirectory();
      final fileName =
          'cropped_${DateTime.now().millisecondsSinceEpoch}.png';
      final outputFile = File('${tempDir.path}/$fileName');
      await outputFile.writeAsBytes(img.encodePng(cropped));

      return outputFile.path;
    } catch (_) {
      return null;
    }
  }

  // ==========================================================================
  // 圆角处理
  // ==========================================================================

  /// 生成圆角图片
  Future<String?> roundCorners({
    required String imagePath,
    double radius = 20,
  }) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final r = radius.clamp(0, image.width / 2).toInt();
      final rounded = _applyRoundedCorners(image, r);

      final tempDir = await getTemporaryDirectory();
      final fileName =
          'rounded_${DateTime.now().millisecondsSinceEpoch}.png';
      final outputFile = File('${tempDir.path}/$fileName');
      await outputFile.writeAsBytes(img.encodePng(rounded));

      return outputFile.path;
    } catch (_) {
      return null;
    }
  }

  /// 底层圆角处理（逐像素 alpha 遮罩）
  img.Image _applyRoundedCorners(img.Image src, int radius) {
    final dst = img.Image.from(src);
    final w = src.width;
    final h = src.height;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        bool outside = false;
        // 左上角
        if (x < radius && y < radius) {
          final dx = radius - x;
          final dy = radius - y;
          if (dx * dx + dy * dy > radius * radius) outside = true;
        }
        // 右上角
        else if (x >= w - radius && y < radius) {
          final dx = x - (w - radius - 1);
          final dy = radius - y;
          if (dx * dx + dy * dy > radius * radius) outside = true;
        }
        // 左下角
        else if (x < radius && y >= h - radius) {
          final dx = radius - x;
          final dy = y - (h - radius - 1);
          if (dx * dx + dy * dy > radius * radius) outside = true;
        }
        // 右下角
        else if (x >= w - radius && y >= h - radius) {
          final dx = x - (w - radius - 1);
          final dy = y - (h - radius - 1);
          if (dx * dx + dy * dy > radius * radius) outside = true;
        }

        if (outside) {
          dst.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }
    return dst;
  }

  // ==========================================================================
  // 粉色滤镜
  // ==========================================================================

  /// 应用粉色滤镜
  Future<String?> applyPinkFilter({
    required String imagePath,
    double intensity = 0.3,
  }) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final filtered = img.Image.from(image);
      final t = intensity.clamp(0.0, 1.0);

      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final r = pixel.r;
          final g = pixel.g;
          final b = pixel.b;

          // 粉色色调映射：增加红色，微调绿色和蓝色
          final newR = (r + (255 - r) * 0.15 * t).clamp(0, 255).toInt();
          final newG = (g * (1 - 0.05 * t)).clamp(0, 255).toInt();
          final newB = (b + (255 - b) * 0.05 * t).clamp(0, 255).toInt();

          filtered.setPixelRgba(x, y, newR, newG, newB, pixel.a.toInt());
        }
      }

      final tempDir = await getTemporaryDirectory();
      final fileName =
          'pink_filtered_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final outputFile = File('${tempDir.path}/$fileName');
      await outputFile.writeAsBytes(img.encodeJpg(filtered, quality: 90));

      return outputFile.path;
    } catch (_) {
      return null;
    }
  }

  // ==========================================================================
  // 水印添加
  // ==========================================================================

  /// 添加文字水印
  Future<String?> addTextWatermark({
    required String imagePath,
    required String text,
    int fontSize = 24,
    Color color = Colors.white,
    double opacity = 0.7,
    WatermarkPosition position = WatermarkPosition.bottomRight,
  }) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // 使用 image 包的 drawString 绘制文字
      final watermarked = img.Image.from(image);
      final a = (opacity * 255).toInt();

      // 计算文字位置
      final textWidth = text.length * fontSize ~/ 2;
      final textHeight = fontSize;
      final padding = 20;
      int posX, posY;

      switch (position) {
        case WatermarkPosition.topLeft:
          posX = padding;
          posY = padding;
          break;
        case WatermarkPosition.topRight:
          posX = image.width - textWidth - padding;
          posY = padding;
          break;
        case WatermarkPosition.bottomLeft:
          posX = padding;
          posY = image.height - textHeight - padding;
          break;
        case WatermarkPosition.bottomRight:
          posX = image.width - textWidth - padding;
          posY = image.height - textHeight - padding;
          break;
        case WatermarkPosition.center:
          posX = (image.width - textWidth) ~/ 2;
          posY = (image.height - textHeight) ~/ 2;
          break;
      }

      img.drawString(
        watermarked,
        text,
        font: img.arial24,
        x: posX,
        y: posY,
        color: img.ColorRgba8(color.red, color.green, color.blue, a),
      );

      final tempDir = await getTemporaryDirectory();
      final fileName =
          'watermarked_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final outputFile = File('${tempDir.path}/$fileName');
      await outputFile.writeAsBytes(img.encodeJpg(watermarked, quality: 90));

      return outputFile.path;
    } catch (_) {
      return null;
    }
  }

  // ==========================================================================
  // 保存到相册
  // ==========================================================================

  /// 保存图片到相册
  Future<bool> saveToGallery(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) return false;
      final result = await GallerySaver.saveImage(imagePath);
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 保存图片字节到相册
  Future<bool> saveBytesToGallery(Uint8List bytes,
      {String fileName = 'image.jpg'}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return saveToGallery(file.path);
    } catch (_) {
      return false;
    }
  }

  // ==========================================================================
  // 格式转换与信息
  // ==========================================================================

  /// 获取图片尺寸信息
  Future<ImageInfo?> getImageInfo(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;
      return ImageInfo(
        width: image.width,
        height: image.height,
        sizeBytes: bytes.length,
      );
    } catch (_) {
      return null;
    }
  }

  /// 转换图片格式
  Future<String?> convertFormat({
    required String imagePath,
    required ImageFormat format,
  }) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final tempDir = await getTemporaryDirectory();
      final ext = format == ImageFormat.png ? 'png' : 'jpg';
      final fileName =
          'converted_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final outputFile = File('${tempDir.path}/$fileName');

      final outputBytes = format == ImageFormat.png
          ? img.encodePng(image)
          : img.encodeJpg(image, quality: 90);
      await outputFile.writeAsBytes(outputBytes);

      return outputFile.path;
    } catch (_) {
      return null;
    }
  }
}

/// 水印位置枚举
enum WatermarkPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  center,
}

/// 图片格式枚举
enum ImageFormat { png, jpg }

/// 图片信息
class ImageInfo {
  final int width;
  final int height;
  final int sizeBytes;

  ImageInfo({
    required this.width,
    required this.height,
    required this.sizeBytes,
  });

  /// 宽高比
  double get aspectRatio => width / height;

  /// 文件大小文本
  String get sizeText {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
