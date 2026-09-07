import 'dart:io';
import 'dart:math';

/// ============================================================================
/// VideoUtils —— 视频工具
///
/// 功能：
///   1. 时长格式化：毫秒/秒转可读格式
///   2. 缩略图生成（模拟）：生成视频缩略图占位
///   3. 分辨率格式化：1920x1080 -> 1080p
///   4. 视频格式检测：从文件头判断格式
///   5. 码率估算：根据文件大小和时长计算码率
/// ============================================================================
class VideoUtils {
  // ===== 支持的视频格式 =====
  static const List<String> _supportedFormats = [
    'mp4', 'mov', 'avi', 'mkv', 'webm', 'flv', 'wmv', 'm4v', '3gp', 'ts'
  ];

  // ===== 常见分辨率 =====
  static const List<Map<String, dynamic>> _resolutions = [
    {'name': '4320p', 'label': '8K UHD', 'width': 7680, 'height': 4320},
    {'name': '2160p', 'label': '4K UHD', 'width': 3840, 'height': 2160},
    {'name': '1440p', 'label': '2K QHD', 'width': 2560, 'height': 1440},
    {'name': '1080p', 'label': 'Full HD', 'width': 1920, 'height': 1080},
    {'name': '720p', 'label': 'HD', 'width': 1280, 'height': 720},
    {'name': '480p', 'label': 'SD', 'width': 854, 'height': 480},
    {'name': '360p', 'label': 'SD', 'width': 640, 'height': 360},
    {'name': '240p', 'label': 'Low', 'width': 426, 'height': 240},
  ];

  // ==========================================================================
  // 时长格式化
  // ==========================================================================

  /// 格式化毫秒为 hh:mm:ss 或 mm:ss
  static String formatDuration(int milliseconds) {
    final seconds = (milliseconds / 1000).round();
    return formatSeconds(seconds);
  }

  /// 格式化秒为 hh:mm:ss 或 mm:ss
  static String formatSeconds(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;

    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  /// 格式化 Duration
  static String formatDurationObj(Duration duration) {
    return formatSeconds(duration.inSeconds);
  }

  /// 格式化带帧的时间码（hh:mm:ss:ff）
  static String formatTimecode(int milliseconds, {int fps = 30}) {
    final totalFrames = (milliseconds / 1000 * fps).round();
    final h = totalFrames ~/ (fps * 3600);
    final m = (totalFrames % (fps * 3600)) ~/ (fps * 60);
    final s = (totalFrames % (fps * 60)) ~/ fps;
    final f = totalFrames % fps;

    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}:'
        '${f.toString().padLeft(2, '0')}';
  }

  /// 解析时间字符串为毫秒
  static int parseDuration(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = double.tryParse(parts[1]) ?? 0;
      return (minutes * 60 * 1000 + seconds * 1000).round();
    } else if (parts.length == 3) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final seconds = double.tryParse(parts[2]) ?? 0;
      return (hours * 3600 * 1000 + minutes * 60 * 1000 + seconds * 1000)
          .round();
    }
    return 0;
  }

  // ==========================================================================
  // 缩略图生成（模拟）
  // ==========================================================================

  /// 生成视频缩略图（模拟，返回占位数据）
  ///
  /// [videoPath] 视频文件路径，[positionMs] 截取位置（毫秒）
  /// [width] 缩略图宽度，[height] 缩略图高度
  static Future<Map<String, dynamic>> generateThumbnail({
    required String videoPath,
    int positionMs = 0,
    int width = 320,
    int height = 180,
  }) async {
    // 模拟缩略图生成
    // 实际实现应使用 video_thumbnail 或 ffmpeg
    final file = File(videoPath);
    final exists = await file.exists();

    return {
      'path': videoPath,
      'position_ms': positionMs,
      'width': width,
      'height': height,
      'thumbnail_data': null, // 模拟：实际应返回图片字节
      'success': exists,
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

  /// 生成多个时间点的缩略图（用于预览条）
  static Future<List<Map<String, dynamic>>> generateThumbnailStrip({
    required String videoPath,
    required int durationMs,
    int count = 10,
    int width = 160,
    int height = 90,
  }) async {
    final thumbnails = <Map<String, dynamic>>[];
    final interval = durationMs ~/ (count + 1);

    for (int i = 1; i <= count; i++) {
      final position = interval * i;
      final thumb = await generateThumbnail(
        videoPath: videoPath,
        positionMs: position,
        width: width,
        height: height,
      );
      thumbnails.add(thumb);
    }

    return thumbnails;
  }

  // ==========================================================================
  // 分辨率格式化
  // ==========================================================================

  /// 格式化分辨率为可读名称
  static String formatResolution(int width, int height) {
    // 查找匹配的标准分辨率
    for (final res in _resolutions) {
      if (width >= res['width'] && height >= res['height']) {
        return '${res['name']} (${res['label']})';
      }
    }
    return '${width}x$height';
  }

  /// 获取分辨率简称（如 1080p）
  static String getResolutionLabel(int width, int height) {
    for (final res in _resolutions) {
      if (width >= res['width'] && height >= res['height']) {
        return res['name'] as String;
      }
    }
    return '${height}p';
  }

  /// 判断是否为横屏视频
  static bool isLandscape(int width, int height) => width > height;

  /// 判断是否为竖屏视频
  static bool isPortrait(int width, int height) => height > width;

  /// 计算宽高比
  static double aspectRatio(int width, int height) {
    if (height == 0) return 1.0;
    return width / height;
  }

  /// 格式化宽高比
  static String formatAspectRatio(int width, int height) {
    final ratio = aspectRatio(width, height);
    if ((ratio - 16 / 9).abs() < 0.01) return '16:9';
    if ((ratio - 9 / 16).abs() < 0.01) return '9:16';
    if ((ratio - 4 / 3).abs() < 0.01) return '4:3';
    if ((ratio - 1).abs() < 0.01) return '1:1';
    if ((ratio - 21 / 9).abs() < 0.01) return '21:9';
    return ratio.toStringAsFixed(2);
  }

  // ==========================================================================
  // 视频格式检测
  // ==========================================================================

  /// 从文件头检测视频格式
  static String detectFormat(List<int> headerBytes) {
    if (headerBytes.length < 4) return 'unknown';

    // MP4/MOV/M4V: ....ftyp
    if (headerBytes.length >= 8 &&
        headerBytes[4] == 0x66 && headerBytes[5] == 0x74 &&
        headerBytes[6] == 0x79 && headerBytes[7] == 0x70) {
      // 检查 ftyp 后的品牌标识
      if (headerBytes.length >= 12) {
        final brand = String.fromCharCodes(headerBytes.sublist(8, 12));
        if (brand == 'isom' || brand == 'mp42' || brand == 'avc1') {
          return 'mp4';
        }
        if (brand == 'qt  ') return 'mov';
        if (brand == 'M4V ') return 'm4v';
      }
      return 'mp4';
    }
    // MKV/WebM: 1A 45 DF A3
    if (headerBytes[0] == 0x1A && headerBytes[1] == 0x45 &&
        headerBytes[2] == 0xDF && headerBytes[3] == 0xA3) {
      // 检查是否为 webm
      if (headerBytes.length >= 30) {
        final headerStr = String.fromCharCodes(headerBytes.sublist(0, 30));
        if (headerStr.contains('webm')) return 'webm';
      }
      return 'mkv';
    }
    // AVI: RIFF....AVI
    if (headerBytes.length >= 12 &&
        headerBytes[0] == 0x52 && headerBytes[1] == 0x49 &&
        headerBytes[2] == 0x46 && headerBytes[3] == 0x46 &&
        headerBytes[8] == 0x41 && headerBytes[9] == 0x56 &&
        headerBytes[10] == 0x49) {
      return 'avi';
    }
    // FLV: 46 4C 56
    if (headerBytes[0] == 0x46 && headerBytes[1] == 0x4C &&
        headerBytes[2] == 0x56) {
      return 'flv';
    }
    // WMV: 30 26 B2 75
    if (headerBytes[0] == 0x30 && headerBytes[1] == 0x26 &&
        headerBytes[2] == 0xB2 && headerBytes[3] == 0x75) {
      return 'wmv';
    }
    // TS: 47
    if (headerBytes[0] == 0x47) {
      return 'ts';
    }
    // 3GP: ....ftyp3gp
    if (headerBytes.length >= 12 &&
        headerBytes[4] == 0x66 && headerBytes[5] == 0x74 &&
        headerBytes[6] == 0x79 && headerBytes[7] == 0x70) {
      final brand = String.fromCharCodes(headerBytes.sublist(8, 12));
      if (brand.contains('3gp')) return '3gp';
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

  /// 判断是否为支持的视频格式
  static bool isVideoFile(String path) {
    return _supportedFormats.contains(detectFormatFromPath(path));
  }

  // ==========================================================================
  // 码率估算
  // ==========================================================================

  /// 计算视频码率（kbps）
  static double calculateBitrate({
    required int fileSizeBytes,
    required Duration duration,
  }) {
    if (duration.inSeconds == 0) return 0;
    final bits = fileSizeBytes * 8;
    return bits / duration.inSeconds / 1000;
  }

  /// 格式化码率
  static String formatBitrate(double kbps) {
    if (kbps >= 1000) {
      return '${(kbps / 1000).toStringAsFixed(1)} Mbps';
    }
    return '${kbps.toStringAsFixed(0)} kbps';
  }

  /// 根据码率和时长估算文件大小
  static int estimateFileSize({
    required Duration duration,
    double bitrateMbps = 5.0,
  }) {
    final bits = duration.inSeconds * bitrateMbps * 1000 * 1000;
    return (bits / 8).round();
  }

  /// 根据文件大小和码率估算时长
  static Duration estimateDuration({
    required int fileSizeBytes,
    double bitrateMbps = 5.0,
  }) {
    final bits = fileSizeBytes * 8;
    final seconds = bits / (bitrateMbps * 1000 * 1000);
    return Duration(seconds: seconds.round());
  }

  // ==========================================================================
  // 工具方法
  // ==========================================================================

  /// 格式化文件大小
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// 计算视频帧数
  static int calculateFrameCount({
    required Duration duration,
    int fps = 30,
  }) {
    return duration.inSeconds * fps;
  }

  /// 计算 GOP（图像组）大小
  static int calculateGopSize({
    required int fps,
    int keyframeInterval = 2,
  }) {
    return fps * keyframeInterval;
  }

  /// 判断是否为高清视频
  static bool isHd(int width, int height) => width >= 1280 || height >= 720;

  /// 判断是否为全高清视频
  static bool isFullHd(int width, int height) =>
      width >= 1920 || height >= 1080;

  /// 判断是否为 4K 视频
  static bool is4k(int width, int height) => width >= 3840 || height >= 2160;

  /// 获取所有标准分辨率列表
  static List<Map<String, dynamic>> get standardResolutions =>
      List.unmodifiable(_resolutions);
}
