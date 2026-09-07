import 'dart:io';
import 'dart:math';

/// ============================================================================
/// AudioUtils —— 音频工具
///
/// 功能：
///   1. 时长格式化：毫秒/秒转可读格式
///   2. 振幅计算：从音频数据计算振幅/音量
///   3. 波形数据生成：生成可视化波形数据
///   4. 音频格式检测：从文件头判断格式
///   5. 文件大小估算：根据时长和码率估算文件大小
/// ============================================================================
class AudioUtils {
  // ===== 支持的音频格式 =====
  static const List<String> _supportedFormats = [
    'mp3', 'wav', 'ogg', 'm4a', 'aac', 'flac', 'wma', 'opus', 'webm'
  ];

  // ===== 常见格式的默认码率（kbps）=====
  static const Map<String, int> _defaultBitrates = {
    'mp3': 128,
    'wav': 1411,
    'ogg': 96,
    'm4a': 128,
    'aac': 128,
    'flac': 800,
    'wma': 128,
    'opus': 96,
    'webm': 128,
  };

  // ==========================================================================
  // 时长格式化
  // ==========================================================================

  /// 格式化毫秒为 mm:ss
  static String formatDuration(int milliseconds) {
    final seconds = (milliseconds / 1000).round();
    return formatSeconds(seconds);
  }

  /// 格式化秒为 mm:ss 或 hh:mm:ss
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

  /// 格式化带毫秒的时长（mm:ss.SSS）
  static String formatDurationWithMs(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final ms = milliseconds % 1000;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}.'
        '${ms.toString().padLeft(3, '0')}';
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
  // 振幅计算
  // ==========================================================================

  /// 从 16 位 PCM 数据计算 RMS 振幅
  ///
  /// [samples] 16 位有符号整数采样数据
  static double calculateRms(List<int> samples) {
    if (samples.isEmpty) return 0.0;

    double sumSquares = 0;
    for (final sample in samples) {
      sumSquares += sample * sample;
    }
    final rms = sqrt(sumSquares / samples.length);
    return rms;
  }

  /// 计算峰值振幅
  static double calculatePeak(List<int> samples) {
    if (samples.isEmpty) return 0.0;
    int maxAbs = 0;
    for (final sample in samples) {
      final abs = sample.abs();
      if (abs > maxAbs) maxAbs = abs;
    }
    return maxAbs.toDouble();
  }

  /// 振幅转分贝（dBFS）
  static double amplitudeToDb(double amplitude, {double maxAmplitude = 32768}) {
    if (amplitude <= 0) return -96.0;
    return 20 * log(amplitude / maxAmplitude) / ln10;
  }

  /// 分贝转振幅
  static double dbToAmplitude(double db, {double maxAmplitude = 32768}) {
    return maxAmplitude * pow(10, db / 20);
  }

  /// 归一化振幅到 0.0-1.0
  static double normalizeAmplitude(double amplitude, {double max = 32768}) {
    return (amplitude / max).clamp(0.0, 1.0);
  }

  // ==========================================================================
  // 波形数据生成
  // ==========================================================================

  /// 生成模拟波形数据（用于占位显示）
  ///
  /// [count] 数据点数量，[seed] 随机种子（保证可复现）
  static List<double> generateWaveform({
    int count = 100,
    int seed = 42,
    double minAmplitude = 0.1,
    double maxAmplitude = 1.0,
  }) {
    final random = Random(seed);
    final waveform = <double>[];

    for (int i = 0; i < count; i++) {
      // 使用多个正弦波叠加模拟真实波形
      final t = i / count;
      final value = 0.3 * sin(2 * pi * 2 * t) +
          0.2 * sin(2 * pi * 5 * t + 1) +
          0.15 * sin(2 * pi * 8 * t + 2) +
          0.1 * random.nextDouble();

      final normalized = (value.abs() * 2).clamp(minAmplitude, maxAmplitude);
      waveform.add(normalized.toDouble());
    }

    return waveform;
  }

  /// 从 PCM 数据生成波形采样
  ///
  /// [samples] PCM 采样数据，[bars] 波形柱数量
  static List<double> waveformFromPcm(List<int> samples, {int bars = 100}) {
    if (samples.isEmpty || bars <= 0) return [];

    final waveform = <double>[];
    final samplesPerBar = (samples.length / bars).floor().clamp(1, samples.length);

    for (int i = 0; i < bars; i++) {
      final start = i * samplesPerBar;
      final end = (start + samplesPerBar).clamp(0, samples.length);
      final segment = samples.sublist(start, end);

      if (segment.isEmpty) {
        waveform.add(0.0);
        continue;
      }

      final rms = calculateRms(segment);
      waveform.add(normalizeAmplitude(rms));
    }

    return waveform;
  }

  /// 平滑波形数据
  static List<double> smoothWaveform(List<double> data, {int windowSize = 3}) {
    if (data.isEmpty || windowSize <= 1) return data;

    final result = <double>[];
    final halfWindow = windowSize ~/ 2;

    for (int i = 0; i < data.length; i++) {
      double sum = 0;
      int count = 0;
      for (int j = -halfWindow; j <= halfWindow; j++) {
        final index = i + j;
        if (index >= 0 && index < data.length) {
          sum += data[index];
          count++;
        }
      }
      result.add(sum / count);
    }

    return result;
  }

  // ==========================================================================
  // 音频格式检测
  // ==========================================================================

  /// 从文件头检测音频格式
  static String detectFormat(List<int> headerBytes) {
    if (headerBytes.length < 4) return 'unknown';

    // MP3: ID3 标签 或 FF FB
    if (headerBytes[0] == 0x49 && headerBytes[1] == 0x44 && headerBytes[2] == 0x33) {
      return 'mp3';
    }
    if (headerBytes[0] == 0xFF && (headerBytes[1] & 0xE0) == 0xE0) {
      return 'mp3';
    }
    // WAV: RIFF....WAVE
    if (headerBytes.length >= 12 &&
        headerBytes[0] == 0x52 && headerBytes[1] == 0x49 &&
        headerBytes[2] == 0x46 && headerBytes[3] == 0x46 &&
        headerBytes[8] == 0x57 && headerBytes[9] == 0x41 &&
        headerBytes[10] == 0x56 && headerBytes[11] == 0x45) {
      return 'wav';
    }
    // OGG: OggS
    if (headerBytes[0] == 0x4F && headerBytes[1] == 0x67 &&
        headerBytes[2] == 0x67 && headerBytes[3] == 0x53) {
      return 'ogg';
    }
    // FLAC: fLaC
    if (headerBytes[0] == 0x66 && headerBytes[1] == 0x4C &&
        headerBytes[2] == 0x61 && headerBytes[3] == 0x43) {
      return 'flac';
    }
    // AAC/M4A: ....ftyp
    if (headerBytes.length >= 8 &&
        headerBytes[4] == 0x66 && headerBytes[5] == 0x74 &&
        headerBytes[6] == 0x79 && headerBytes[7] == 0x70) {
      return 'm4a';
    }
    // WebM/Opus: ....webm 或 1A 45 DF A3
    if (headerBytes[0] == 0x1A && headerBytes[1] == 0x45 &&
        headerBytes[2] == 0xDF && headerBytes[3] == 0xA3) {
      return 'webm';
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

  /// 判断是否为支持的音频格式
  static bool isAudioFile(String path) {
    return _supportedFormats.contains(detectFormatFromPath(path));
  }

  // ==========================================================================
  // 文件大小估算
  // ==========================================================================

  /// 根据时长和码率估算文件大小（字节）
  static int estimateFileSize({
    required Duration duration,
    int bitrateKbps = 128,
  }) {
    final bits = duration.inSeconds * bitrateKbps * 1000;
    return (bits / 8).round();
  }

  /// 根据文件大小和码率估算时长
  static Duration estimateDuration({
    required int fileSizeBytes,
    int bitrateKbps = 128,
  }) {
    final bits = fileSizeBytes * 8;
    final seconds = bits / (bitrateKbps * 1000);
    return Duration(seconds: seconds.round());
  }

  /// 根据格式获取默认码率
  static int getDefaultBitrate(String format) {
    return _defaultBitrates[format.toLowerCase()] ?? 128;
  }

  /// 计算实际码率
  static double calculateBitrate({
    required int fileSizeBytes,
    required Duration duration,
  }) {
    if (duration.inSeconds == 0) return 0;
    final bits = fileSizeBytes * 8;
    return bits / duration.inSeconds / 1000; // kbps
  }

  // ==========================================================================
  // 工具方法
  // ==========================================================================

  /// 采样率转换计算
  static int calculateResampledCount({
    required int originalCount,
    required int originalSampleRate,
    required int targetSampleRate,
  }) {
    return (originalCount * targetSampleRate / originalSampleRate).round();
  }

  /// 声道数计算
  static int calculateBytesPerSample({
    required int bitDepth,
    required int channels,
  }) {
    return (bitDepth ~/ 8) * channels;
  }

  /// 格式化码率
  static String formatBitrate(double kbps) {
    if (kbps >= 1000) {
      return '${(kbps / 1000).toStringAsFixed(1)} Mbps';
    }
    return '${kbps.toStringAsFixed(0)} kbps';
  }

  /// 音量百分比转 dB
  static double percentToDb(double percent) {
    if (percent <= 0) return -96.0;
    return 20 * log(percent.clamp(0.0, 1.0)) / ln10;
  }

  /// dB 转音量百分比
  static double dbToPercent(double db) {
    if (db <= -96) return 0.0;
    return pow(10, db / 20).toDouble().clamp(0.0, 1.0);
  }
}
