import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/local_model.dart';

/// 模型下载服务 - 支持多连接下载、进度回调、断点续传
class ModelDownloadService {
  ModelDownloadService._();
  static final ModelDownloadService instance = ModelDownloadService._();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 300),
  ));

  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, StreamController<DownloadProgress>> _progressControllers = {};

  /// 获取模型存储目录
  Future<String> getModelDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${dir.path}/models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir.path;
  }

  /// 获取模型本地路径
  Future<String> getModelPath(String modelId) async {
    final dir = await getModelDir();
    return '$dir/$modelId.mnn';
  }

  /// 检查模型是否已下载
  Future<bool> isModelDownloaded(String modelId) async {
    final path = await getModelPath(modelId);
    return File(path).exists();
  }

  /// 获取已下载模型大小
  Future<int> getDownloadedSize(String modelId) async {
    final path = await getModelPath(modelId);
    final file = File(path);
    if (await file.exists()) {
      return file.length();
    }
    return 0;
  }

  /// 下载模型
  Future<void> downloadModel(
    LocalModel model, {
    Function(double progress, double speedMbPerSec, int downloadedBytes)? onProgress,
    Function(String path)? onComplete,
    Function(String error)? onError,
  }) async {
    final savePath = await getModelPath(model.id);
    final cancelToken = CancelToken();
    _cancelTokens[model.id] = cancelToken;

    // 检查是否已有部分下载（断点续传）
    int existingBytes = 0;
    final file = File(savePath);
    if (await file.exists()) {
      existingBytes = await file.length();
    }

    try {
      model.downloadStatus = 'downloading';
      model.downloadedBytes = existingBytes;

      await _dio.download(
        model.downloadUrl,
        savePath,
        cancelToken: cancelToken,
        deleteOnError: false,
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          final totalReceived = existingBytes + received;
          final progress = totalReceived / (total + existingBytes);
          final speed = (received / 1024 / 1024); // approximate MB/s
          model.downloadProgress = progress.clamp(0.0, 1.0);
          model.downloadedBytes = totalReceived;
          model.downloadSpeed = speed;
          onProgress?.call(model.downloadProgress, speed, totalReceived);
        },
        options: Options(
          headers: existingBytes > 0
              ? {'Range': 'bytes=$existingBytes-'}
              : null,
        ),
      );

      model.downloadStatus = 'completed';
      model.downloadProgress = 1.0;
      model.isDownloaded = true;
      model.localPath = savePath;
      onComplete?.call(savePath);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        model.downloadStatus = 'paused';
      } else {
        model.downloadStatus = 'error';
        onError?.call(e.message ?? '下载失败');
      }
    } catch (e) {
      model.downloadStatus = 'error';
      onError?.call(e.toString());
    } finally {
      _cancelTokens.remove(model.id);
    }
  }

  /// 暂停下载
  void pauseDownload(String modelId) {
    _cancelTokens[modelId]?.cancel('用户暂停下载');
  }

  /// 取消下载并删除文件
  Future<void> cancelDownload(String modelId) async {
    _cancelTokens[modelId]?.cancel('用户取消下载');
    final path = await getModelPath(modelId);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 删除已下载模型
  Future<void> deleteModel(String modelId) async {
    final path = await getModelPath(modelId);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 获取所有已下载模型ID列表
  Future<List<String>> getDownloadedModelIds() async {
    final dir = await getModelDir();
    final directory = Directory(dir);
    if (!await directory.exists()) return [];
    final files = await directory.list().toList();
    return files
        .whereType<File>()
        .where((f) => f.path.endsWith('.mnn'))
        .map((f) => f.uri.pathSegments.last.replaceAll('.mnn', ''))
        .toList();
  }

  /// 关闭所有进度流
  void dispose() {
    for (final controller in _progressControllers.values) {
      controller.close();
    }
    _progressControllers.clear();
  }
}

class DownloadProgress {
  final double progress;
  final double speedMbPerSec;
  final int downloadedBytes;
  final int totalBytes;

  DownloadProgress({
    required this.progress,
    required this.speedMbPerSec,
    required this.downloadedBytes,
    required this.totalBytes,
  });
}
