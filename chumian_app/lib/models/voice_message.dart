/// ============================================================================
/// VoiceMessage —— 语音消息数据模型
///
/// 承载一条语音消息的完整信息，包括 URL、时长、波形数据、
/// 是否已播放以及创建时间。支持语音消息的播放管理与波形可视化。
/// ============================================================================

/// 语音消息数据模型
class VoiceMessage {
  /// 消息唯一标识
  final String id;

  /// 语音文件 URL
  final String url;

  /// 语音时长（秒）
  final double duration;

  /// 波形数据（0.0 - 1.0 的振幅列表，用于可视化）
  final List<double> waveformData;

  /// 是否已播放
  bool isPlayed;

  /// 创建时间
  final DateTime createdAt;

  /// 发送者 ID
  final String senderId;

  /// 发送者名称
  final String senderName;

  /// 发送者头像 URL
  final String senderAvatar;

  /// 转文字内容（语音识别后）
  String transcript;

  /// 语音格式
  final String format;

  /// 文件大小（字节）
  final int fileSize;

  /// 是否正在上传
  bool isUploading;

  /// 上传进度（0.0 - 1.0）
  double uploadProgress;

  VoiceMessage({
    required this.id,
    required this.url,
    this.duration = 0.0,
    List<double>? waveformData,
    this.isPlayed = false,
    DateTime? createdAt,
    this.senderId = '',
    this.senderName = '',
    this.senderAvatar = '',
    this.transcript = '',
    this.format = 'm4a',
    this.fileSize = 0,
    this.isUploading = false,
    this.uploadProgress = 0.0,
  })  : waveformData = waveformData ?? [],
        createdAt = createdAt ?? DateTime.now();

  /// 从 JSON 反序列化
  factory VoiceMessage.fromJson(Map<String, dynamic> json) {
    return VoiceMessage(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      waveformData: (json['waveform_data'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      isPlayed: json['is_played'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      senderId: json['sender_id']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? '',
      senderAvatar: json['sender_avatar']?.toString() ?? '',
      transcript: json['transcript']?.toString() ?? '',
      format: json['format']?.toString() ?? 'm4a',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      isUploading: json['is_uploading'] == true,
      uploadProgress: (json['upload_progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'duration': duration,
      'waveform_data': waveformData,
      'is_played': isPlayed,
      'created_at': createdAt.toIso8601String(),
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'transcript': transcript,
      'format': format,
      'file_size': fileSize,
      'is_uploading': isUploading,
      'upload_progress': uploadProgress,
    };
  }

  /// 创建一条新的语音消息
  factory VoiceMessage.create({
    required String url,
    double duration = 0.0,
    List<double>? waveformData,
    String senderId = '',
    String senderName = '',
    String senderAvatar = '',
    String format = 'm4a',
    int fileSize = 0,
  }) {
    return VoiceMessage(
      id: 'vm_${DateTime.now().microsecondsSinceEpoch}',
      url: url,
      duration: duration,
      waveformData: waveformData,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      format: format,
      fileSize: fileSize,
    );
  }

  /// 格式化时长为 mm:ss
  String get formattedDuration {
    final totalSeconds = duration.toInt();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 格式化文件大小
  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// 是否有波形数据
  bool get hasWaveform => waveformData.isNotEmpty;

  /// 获取指定数量的波形采样点（用于不同宽度的显示）
  List<double> getWaveformSamples(int count) {
    if (waveformData.isEmpty) return List.filled(count, 0.3);
    if (waveformData.length <= count) {
      // 数据不足，补零
      final result = List<double>.from(waveformData);
      while (result.length < count) {
        result.add(0.2);
      }
      return result;
    }
    // 降采样：取每个区间的最大值
    final step = waveformData.length / count;
    return List.generate(count, (i) {
      final start = (i * step).toInt();
      final end = ((i + 1) * step).toInt().clamp(0, waveformData.length);
      if (start >= end) return waveformData[start];
      double max = 0;
      for (int j = start; j < end; j++) {
        if (waveformData[j] > max) max = waveformData[j];
      }
      return max;
    });
  }

  /// 是否为有效语音（有 URL 且时长 > 0）
  bool get isValid => url.isNotEmpty && duration > 0;

  /// 复制一份语音消息
  VoiceMessage copyWith({
    String? id,
    String? url,
    double? duration,
    List<double>? waveformData,
    bool? isPlayed,
    DateTime? createdAt,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? transcript,
    String? format,
    int? fileSize,
    bool? isUploading,
    double? uploadProgress,
  }) {
    return VoiceMessage(
      id: id ?? this.id,
      url: url ?? this.url,
      duration: duration ?? this.duration,
      waveformData: waveformData ?? this.waveformData,
      isPlayed: isPlayed ?? this.isPlayed,
      createdAt: createdAt ?? this.createdAt,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      transcript: transcript ?? this.transcript,
      format: format ?? this.format,
      fileSize: fileSize ?? this.fileSize,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}
