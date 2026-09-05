import 'package:flutter/material.dart';

/// 本地模型数据模型
class LocalModel {
  final String id;
  final String name;
  final String type; // language, video, image, audio
  final int size; // in MB
  final String sizeDisplay;
  final String description;
  final String downloadUrl;
  final bool recommended;
  final int rank;
  final String author;
  final String version;
  final String params;
  final String contextLength;

  // Runtime state
  bool isDownloaded;
  double downloadProgress; // 0.0 - 1.0
  String downloadStatus; // idle, downloading, paused, completed, error
  String? localPath;
  double downloadSpeed; // MB/s
  int downloadedBytes;

  LocalModel({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.sizeDisplay,
    required this.description,
    required this.downloadUrl,
    required this.recommended,
    required this.rank,
    required this.author,
    required this.version,
    required this.params,
    required this.contextLength,
    this.isDownloaded = false,
    this.downloadProgress = 0.0,
    this.downloadStatus = 'idle',
    this.localPath,
    this.downloadSpeed = 0.0,
    this.downloadedBytes = 0,
  });

  factory LocalModel.fromJson(Map<String, dynamic> json) {
    return LocalModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'language',
      size: json['size'] ?? 0,
      sizeDisplay: json['size_display'] ?? '',
      description: json['description'] ?? '',
      downloadUrl: json['download_url'] ?? '',
      recommended: json['recommended'] ?? false,
      rank: json['rank'] ?? 99,
      author: json['author'] ?? '',
      version: json['version'] ?? '',
      params: json['params'] ?? '',
      contextLength: json['context_length'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'size': size,
        'size_display': sizeDisplay,
        'description': description,
        'download_url': downloadUrl,
        'recommended': recommended,
        'rank': rank,
        'author': author,
        'version': version,
        'params': params,
        'context_length': contextLength,
        'isDownloaded': isDownloaded,
        'downloadProgress': downloadProgress,
        'downloadStatus': downloadStatus,
        'localPath': localPath,
      };

  bool get isLanguageModel => type == 'language';
  bool get isVideoModel => type == 'video';
  bool get isImageModel => type == 'image';
  bool get isAudioModel => type == 'audio';

  String get typeLabel {
    switch (type) {
      case 'language':
        return '语言模型';
      case 'video':
        return '视频模型';
      case 'image':
        return '图像模型';
      case 'audio':
        return '音频模型';
      default:
        return '未知';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case 'language':
        return Icons.chat_bubble_outline;
      case 'video':
        return Icons.videocam_outlined;
      case 'image':
        return Icons.image_outlined;
      case 'audio':
        return Icons.mic_none;
      default:
        return Icons.extension;
    }
  }
}
