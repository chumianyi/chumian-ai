import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/local_model.dart';
import '../services/model_download_service.dart';

/// 模型商店状态管理
class ModelStoreProvider extends ChangeNotifier {
  ModelStoreProvider._();
  static final ModelStoreProvider instance = ModelStoreProvider._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://103.236.99.177:24512',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  final ModelDownloadService _downloadService = ModelDownloadService.instance;

  List<LocalModel> _models = [];
  List<LocalModel> get models => _models;
  List<LocalModel> get recommendedModels =>
      _models.where((m) => m.recommended).toList();
  List<LocalModel> get languageModels =>
      _models.where((m) => m.isLanguageModel).toList();
  List<LocalModel> get videoModels =>
      _models.where((m) => m.isVideoModel).toList();
  List<LocalModel> get downloadedModels =>
      _models.where((m) => m.isDownloaded).toList();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String _selectedCategory = 'all';
  String get selectedCategory => _selectedCategory;

  List<LocalModel> get filteredModels {
    if (_selectedCategory == 'all') return _models;
    if (_selectedCategory == 'recommended') return recommendedModels;
    return _models.where((m) => m.type == _selectedCategory).toList();
  }

  /// 从服务器获取模型列表
  Future<void> fetchModels() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dio.get('/api/models/local');
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        _models = data.map((json) => LocalModel.fromJson(json)).toList();
        // 检查已下载状态
        await _checkDownloadedStatus();
      }
    } catch (e) {
      _error = '加载模型列表失败：$e';
      // 使用本地默认模型列表
      _models = _getDefaultModels();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkDownloadedStatus() async {
    final downloadedIds = await _downloadService.getDownloadedModelIds();
    for (final model in _models) {
      if (downloadedIds.contains(model.id)) {
        model.isDownloaded = true;
        model.downloadStatus = 'completed';
        model.downloadProgress = 1.0;
        model.localPath = await _downloadService.getModelPath(model.id);
      }
    }
  }

  /// 切换分类
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// 下载模型
  Future<void> downloadModel(LocalModel model) async {
    if (model.downloadStatus == 'downloading') return;

    model.downloadStatus = 'downloading';
    model.downloadProgress = 0.0;
    notifyListeners();

    await _downloadService.downloadModel(
      model,
      onProgress: (progress, speed, bytes) {
        model.downloadProgress = progress;
        model.downloadSpeed = speed;
        model.downloadedBytes = bytes;
        notifyListeners();
      },
      onComplete: (path) {
        model.isDownloaded = true;
        model.downloadStatus = 'completed';
        model.downloadProgress = 1.0;
        model.localPath = path;
        notifyListeners();
      },
      onError: (error) {
        model.downloadStatus = 'error';
        _error = error;
        notifyListeners();
      },
    );
  }

  /// 暂停下载
  void pauseDownload(LocalModel model) {
    _downloadService.pauseDownload(model.id);
    model.downloadStatus = 'paused';
    notifyListeners();
  }

  /// 取消下载
  Future<void> cancelDownload(LocalModel model) async {
    await _downloadService.cancelDownload(model.id);
    model.downloadStatus = 'idle';
    model.downloadProgress = 0.0;
    model.downloadedBytes = 0;
    notifyListeners();
  }

  /// 删除模型
  Future<void> deleteModel(LocalModel model) async {
    await _downloadService.deleteModel(model.id);
    model.isDownloaded = false;
    model.downloadStatus = 'idle';
    model.downloadProgress = 0.0;
    model.localPath = null;
    notifyListeners();
  }

  /// 获取模型
  LocalModel? getModelById(String id) {
    try {
      return _models.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 默认模型列表（服务器不可用时使用）
  List<LocalModel> _getDefaultModels() {
    return [
      LocalModel(
        id: 'minimax-h3-full',
        name: 'MiniMax H3 满血版',
        type: 'language',
        size: 14592,
        sizeDisplay: '14.2 GB',
        description: 'MiniMax最新旗舰语言模型满血版，支持超长上下文和复杂推理。',
        downloadUrl: 'https://github.com/chumianyi/chumian-ai-models/releases/download/v1.0/minimax-h3-full.mnn',
        recommended: true,
        rank: 1,
        author: 'MiniMax',
        version: '1.0.0',
        params: '32B',
        contextLength: '128K',
      ),
      LocalModel(
        id: 'deepseek-4-pro',
        name: 'DeepSeek 4 Pro',
        type: 'language',
        size: 16384,
        sizeDisplay: '16.0 GB',
        description: 'DeepSeek第四代专业版模型，超强代码能力和数学推理。',
        downloadUrl: 'https://github.com/chumianyi/chumian-ai-models/releases/download/v1.0/deepseek-4-pro.mnn',
        recommended: true,
        rank: 2,
        author: 'DeepSeek',
        version: '4.0.0',
        params: '67B',
        contextLength: '64K',
      ),
    ];
  }
}
