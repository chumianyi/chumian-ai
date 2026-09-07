import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// ============================================================================
/// FileUtils —— 文件工具类
///
/// 提供文件大小格式化、文件类型判断、目录大小计算、
/// 文件复制/移动/删除、临时文件管理、路径工具等常用文件操作。
/// ============================================================================
class FileUtils {
  // ==========================================================================
  // 文件大小格式化
  // ==========================================================================

  /// 格式化文件大小为可读字符串
  ///
  /// [bytes] 文件大小（字节），[decimals] 小数位数
  static String formatFileSize(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    int unitIndex = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(decimals)} ${units[unitIndex]}';
  }

  /// 格式化文件大小为简短字符串（如 "1.5M"）
  static String formatFileSizeShort(int bytes) {
    if (bytes <= 0) return '0';
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)}K';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}M';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}G';
  }

  /// 解析文件大小字符串为字节数
  ///
  /// 支持 "1.5 MB"、"500KB"、"2G" 等格式
  static int parseFileSize(String sizeStr) {
    if (sizeStr.isEmpty) return 0;
    final cleaned = sizeStr.trim().toUpperCase().replaceAll(' ', '');
    final match = RegExp(r'^([\d.]+)\s*([KMGT]?B?)$').firstMatch(cleaned);
    if (match == null) return 0;

    final value = double.tryParse(match.group(1)!) ?? 0;
    final unit = match.group(2) ?? '';

    switch (unit) {
      case 'KB':
      case 'K':
        return (value * 1024).round();
      case 'MB':
      case 'M':
        return (value * 1024 * 1024).round();
      case 'GB':
      case 'G':
        return (value * 1024 * 1024 * 1024).round();
      case 'TB':
      case 'T':
        return (value * 1024 * 1024 * 1024 * 1024).round();
      default:
        return value.round();
    }
  }

  // ==========================================================================
  // 文件类型判断
  // ==========================================================================

  /// 根据扩展名判断是否为图片
  static bool isImage(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.svg']
        .contains(ext);
  }

  /// 根据扩展名判断是否为视频
  static bool isVideo(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.flv', '.wmv']
        .contains(ext);
  }

  /// 根据扩展名判断是否为音频
  static bool isAudio(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return ['.mp3', '.wav', '.aac', '.flac', '.ogg', '.m4a', '.wma']
        .contains(ext);
  }

  /// 根据扩展名判断是否为文档
  static bool isDocument(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt']
        .contains(ext);
  }

  /// 根据扩展名判断是否为压缩包
  static bool isArchive(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return ['.zip', '.rar', '.7z', '.tar', '.gz', '.bz2'].contains(ext);
  }

  /// 获取文件的 MIME 类型（简易判断）
  static String getMimeType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    const mimeMap = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.webp': 'image/webp',
      '.bmp': 'image/bmp',
      '.svg': 'image/svg+xml',
      '.mp4': 'video/mp4',
      '.mov': 'video/quicktime',
      '.avi': 'video/x-msvideo',
      '.mkv': 'video/x-matroska',
      '.webm': 'video/webm',
      '.mp3': 'audio/mpeg',
      '.wav': 'audio/wav',
      '.aac': 'audio/aac',
      '.flac': 'audio/flac',
      '.ogg': 'audio/ogg',
      '.m4a': 'audio/mp4',
      '.pdf': 'application/pdf',
      '.doc': 'application/msword',
      '.docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      '.xls': 'application/vnd.ms-excel',
      '.xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      '.ppt': 'application/vnd.ms-powerpoint',
      '.pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      '.txt': 'text/plain',
      '.html': 'text/html',
      '.htm': 'text/html',
      '.css': 'text/css',
      '.js': 'application/javascript',
      '.json': 'application/json',
      '.xml': 'application/xml',
      '.zip': 'application/zip',
      '.rar': 'application/x-rar-compressed',
      '.7z': 'application/x-7z-compressed',
      '.apk': 'application/vnd.android.package-archive',
    };
    return mimeMap[ext] ?? 'application/octet-stream';
  }

  // ==========================================================================
  // 目录大小计算
  // ==========================================================================

  /// 计算目录大小（字节）
  static Future<int> getDirectorySize(String dirPath) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return 0;

    int total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {}
      }
    }
    return total;
  }

  /// 计算目录大小（同步，可能较慢）
  static int getDirectorySizeSync(String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return 0;

    int total = 0;
    try {
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is File) {
          try {
            total += entity.lengthSync();
          } catch (_) {}
        }
      }
    } catch (_) {}
    return total;
  }

  /// 获取目录中的文件数量
  static Future<int> getFileCount(String dirPath) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return 0;

    int count = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) count++;
    }
    return count;
  }

  // ==========================================================================
  // 文件操作
  // ==========================================================================

  /// 复制文件
  static Future<bool> copyFile(String sourcePath, String targetPath) async {
    try {
      final source = File(sourcePath);
      if (!source.existsSync()) return false;

      // 确保目标目录存在
      final targetDir = Directory(path.dirname(targetPath));
      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      await source.copy(targetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 移动文件
  static Future<bool> moveFile(String sourcePath, String targetPath) async {
    try {
      final source = File(sourcePath);
      if (!source.existsSync()) return false;

      final targetDir = Directory(path.dirname(targetPath));
      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      await source.rename(targetPath);
      return true;
    } catch (_) {
      // 跨分区移动可能失败，尝试复制+删除
      final copied = await copyFile(sourcePath, targetPath);
      if (copied) {
        await deleteFile(sourcePath);
        return true;
      }
      return false;
    }
  }

  /// 删除文件
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 删除目录（递归）
  static Future<bool> deleteDirectory(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 清空目录内容（保留目录本身）
  static Future<int> clearDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return 0;

    int count = 0;
    await for (final entity in dir.list()) {
      try {
        await entity.delete(recursive: true);
        count++;
      } catch (_) {}
    }
    return count;
  }

  // ==========================================================================
  // 临时文件管理
  // ==========================================================================

  /// 创建临时文件
  static Future<File> createTempFile({
    String prefix = 'temp_',
    String suffix = '.tmp',
  }) async {
    final tempDir = await getTemporaryDirectory();
    final fileName =
        '$prefix${DateTime.now().millisecondsSinceEpoch}$suffix';
    final file = File('${tempDir.path}/$fileName');
    await file.create();
    return file;
  }

  /// 清理过期的临时文件
  ///
  /// [maxAgeHours] 最大保留时间（小时）
  static Future<int> cleanupTempFiles({int maxAgeHours = 24}) async {
    final tempDir = await getTemporaryDirectory();
    if (!tempDir.existsSync()) return 0;

    final now = DateTime.now();
    int count = 0;

    await for (final entity in tempDir.list()) {
      if (entity is File) {
        try {
          final stat = await entity.stat();
          final age = now.difference(stat.modified).inHours;
          if (age > maxAgeHours) {
            await entity.delete();
            count++;
          }
        } catch (_) {}
      }
    }
    return count;
  }

  // ==========================================================================
  // 路径工具
  // ==========================================================================

  /// 获取文件名（含扩展名）
  static String getFileName(String filePath) {
    return path.basename(filePath);
  }

  /// 获取文件名（不含扩展名）
  static String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  /// 获取文件扩展名（含点号）
  static String getFileExtension(String filePath) {
    return path.extension(filePath);
  }

  /// 获取目录路径
  static String getDirectoryPath(String filePath) {
    return path.dirname(filePath);
  }

  /// 拼接路径
  static String joinPath(String part1, String part2, [String? part3]) {
    if (part3 != null) return path.join(part1, part2, part3);
    return path.join(part1, part2);
  }

  /// 判断文件是否存在
  static bool fileExists(String filePath) {
    return File(filePath).existsSync();
  }

  /// 判断目录是否存在
  static bool directoryExists(String dirPath) {
    return Directory(dirPath).existsSync();
  }

  /// 确保目录存在（不存在则创建）
  static Future<Directory> ensureDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 获取应用文档目录路径
  static Future<String> getAppDocumentsPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  /// 获取应用缓存目录路径
  static Future<String> getAppCachePath() async {
    final dir = await getTemporaryDirectory();
    return dir.path;
  }

  /// 获取应用支持目录路径
  static Future<String> getAppSupportPath() async {
    final dir = await getApplicationSupportDirectory();
    return dir.path;
  }
}
