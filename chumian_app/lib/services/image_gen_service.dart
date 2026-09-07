import 'dart:async';
import 'package:dio/dio.dart';
import 'package:chumian_ai/models/image_task.dart';
import 'package:chumian_ai/services/cache_service.dart';
import 'package:chumian_ai/services/local_storage_service.dart';

/// ============================================================================
/// ImageGenService —— AI 绘画服务
///
/// 职责：
///   1. AI 绘画任务创建与提交
///   2. 任务状态轮询
///   3. 结果缓存（内存 + 磁盘）
///   4. 风格模板管理
///   5. 尺寸预设管理
///   6. 历史记录管理
/// ============================================================================
class ImageGenService {
  /// 单例实例
  static final ImageGenService _instance = ImageGenService._internal();
  factory ImageGenService() => _instance;
  ImageGenService._internal();

  /// Dio 实例
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://103.236.99.177:24512',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));

  /// 缓存服务
  final CacheService _cache = CacheService();

  /// 本地存储服务
  final LocalStorageService _storage = LocalStorageService();

  /// 历史记录存储键
  static const String _historyKey = 'image_gen_history';

  /// 历史记录最大数量
  static const int _maxHistory = 50;

  /// 轮询间隔（毫秒）
  static const int _pollIntervalMs = 3000;

  /// 最大轮询次数
  static const int _maxPollAttempts = 60;

  /// 正在轮询的任务
  final Map<String, Timer> _pollingTasks = {};

  // ==========================================================================
  // 参数校验
  // ==========================================================================

  /// 校验绘画参数
  String? validateParams({
    required String prompt,
    ImageStyle? style,
    ImageSize? size,
  }) {
    if (prompt.trim().isEmpty) {
      return '请输入画面描述';
    }
    if (prompt.trim().length > 2000) {
      return '描述过长，请控制在 2000 字以内';
    }
    // 检查敏感词（简易检查）
    final lowerPrompt = prompt.toLowerCase();
    final sensitiveWords = ['nsfw', 'nude', 'porn', '色情', '裸体'];
    for (final word in sensitiveWords) {
      if (lowerPrompt.contains(word)) {
        return '描述包含违规内容，请修改后重试';
      }
    }
    return null;
  }

  // ==========================================================================
  // 任务创建与提交
  // ==========================================================================

  /// 创建并提交绘画任务
  ///
  /// 返回提交后的任务（状态为 queued），后续需轮询获取结果
  Future<ImageTask> generateImage({
    required String prompt,
    String negativePrompt = '',
    ImageStyle style = ImageStyle.realistic,
    ImageSize size = ImageSize.square,
    int? seed,
    void Function(double progress)? onProgress,
  }) async {
    final task = ImageTask.create(
      prompt: prompt,
      negativePrompt: negativePrompt,
      style: style,
      size: size,
      seed: seed,
    );

    // 校验参数
    final error = validateParams(prompt: prompt);
    if (error != null) {
      task.status = ImageTaskStatus.failed;
      task.errorMessage = error;
      return task;
    }

    // 检查缓存（相同 prompt + style + size 直接返回缓存结果）
    final cacheKey = 'img_${prompt}_${style.value}_${size.value}';
    final cached = _cache.getMemory<String>(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      task.status = ImageTaskStatus.completed;
      task.resultUrl = cached;
      task.progress = 100;
      task.completedAt = DateTime.now();
      return task;
    }

    task.status = ImageTaskStatus.queued;
    task.progress = 5;
    onProgress?.call(0.05);

    try {
      // 提交任务
      final resp = await _dio.post(
        '/api/image/generate',
        data: {
          'prompt': prompt,
          'negative_prompt': negativePrompt,
          'style': style.value,
          'size': size.value,
          'seed': seed,
        },
      );

      if (resp.statusCode == 200 && resp.data != null) {
        final data = resp.data is Map
            ? Map<String, dynamic>.from(resp.data as Map)
            : <String, dynamic>{};
        task.serverTaskId = data['task_id']?.toString();
        task.status = ImageTaskStatus.generating;
        task.progress = 20;
        onProgress?.call(0.2);

        // 开始轮询
        await _pollTaskStatus(task, onProgress: onProgress);
      } else {
        task.status = ImageTaskStatus.failed;
        task.errorMessage = '提交失败，服务器返回异常';
      }
    } on DioException catch (e) {
      task.status = ImageTaskStatus.failed;
      task.errorMessage = e.message ?? '网络请求失败';
    } catch (e) {
      task.status = ImageTaskStatus.failed;
      task.errorMessage = e.toString();
    }

    // 保存到历史
    if (task.status == ImageTaskStatus.completed) {
      // 缓存结果
      if (task.resultUrl != null) {
        _cache.setMemory(cacheKey, task.resultUrl!,
            ttlMs: 24 * 60 * 60 * 1000); // 缓存 24 小时
      }
      await _addToHistory(task);
    }

    return task;
  }

  // ==========================================================================
  // 状态轮询
  // ==========================================================================

  /// 轮询任务状态直到完成或失败
  Future<void> _pollTaskStatus(
    ImageTask task, {
    void Function(double progress)? onProgress,
  }) async {
    if (task.serverTaskId == null) {
      task.status = ImageTaskStatus.failed;
      task.errorMessage = '缺少服务端任务 ID';
      return;
    }

    int attempts = 0;
    while (attempts < _maxPollAttempts) {
      attempts++;
      await Future.delayed(const Duration(milliseconds: _pollIntervalMs));

      try {
        final resp = await _dio.get(
          '/api/image/status/${task.serverTaskId}',
        );

        if (resp.statusCode == 200 && resp.data != null) {
          final data = resp.data is Map
              ? Map<String, dynamic>.from(resp.data as Map)
              : <String, dynamic>{};
          final status = data['status']?.toString() ?? '';
          final progress = (data['progress'] as num?)?.toDouble() ?? 0;

          task.progress = (20 + progress * 0.75).clamp(20, 95);
          onProgress?.call(task.progress / 100);

          if (status == 'completed' || status == 'success') {
            task.resultUrl = data['result_url']?.toString();
            if (task.resultUrl != null && task.resultUrl!.isNotEmpty) {
              task.status = ImageTaskStatus.completed;
              task.progress = 100;
              task.completedAt = DateTime.now();
              onProgress?.call(1.0);
              return;
            }
          } else if (status == 'failed' || status == 'error') {
            task.status = ImageTaskStatus.failed;
            task.errorMessage = data['error']?.toString() ?? '生成失败';
            return;
          }
          // 否则继续轮询
        }
      } catch (_) {
        // 轮询异常，继续尝试
      }
    }

    // 超时
    task.status = ImageTaskStatus.failed;
    task.errorMessage = '生成超时，请稍后重试';
  }

  /// 取消正在轮询的任务
  bool cancelTask(String taskId) {
    final timer = _pollingTasks[taskId];
    if (timer != null) {
      timer.cancel();
      _pollingTasks.remove(taskId);
      return true;
    }
    return false;
  }

  // ==========================================================================
  // 历史记录
  // ==========================================================================

  /// 添加到历史记录
  Future<void> _addToHistory(ImageTask task) async {
    final history = await getHistory();
    history.insert(0, task);
    if (history.length > _maxHistory) {
      history.removeRange(_maxHistory, history.length);
    }
    await _saveHistory(history);
  }

  /// 获取历史记录
  Future<List<ImageTask>> getHistory() async {
    final list = await _storage.getJsonList(_historyKey);
    return list
        .map((e) => ImageTask.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// 保存历史记录
  Future<void> _saveHistory(List<ImageTask> history) async {
    await _storage.setJsonList(
      _historyKey,
      history.map((e) => e.toJson()).toList(),
    );
  }

  /// 删除单条历史
  Future<void> deleteHistory(String taskId) async {
    final history = await getHistory();
    history.removeWhere((t) => t.id == taskId);
    await _saveHistory(history);
  }

  /// 清空历史记录
  Future<void> clearHistory() async {
    await _storage.remove(_historyKey);
  }

  // ==========================================================================
  // 风格与尺寸预设
  // ==========================================================================

  /// 获取所有风格预设
  List<ImageStylePreset> getStylePresets() {
    return ImageStyle.values.map((style) {
      final prompts = _getStylePrompt(style);
      return ImageStylePreset(
        style: style,
        name: style.label,
        description: prompts.description,
        promptSuffix: prompts.suffix,
      );
    }).toList();
  }

  /// 获取风格对应的提示词后缀
  _StylePrompt _getStylePrompt(ImageStyle style) {
    switch (style) {
      case ImageStyle.realistic:
        return _StylePrompt(
          description: '高清写实摄影风格，细节丰富',
          suffix: ', photorealistic, high detail, 8k',
        );
      case ImageStyle.anime:
        return _StylePrompt(
          description: '日系动漫风格，色彩鲜明',
          suffix: ', anime style, cel shading, vibrant colors',
        );
      case ImageStyle.oilPainting:
        return _StylePrompt(
          description: '古典油画风格，笔触明显',
          suffix: ', oil painting, classical art, brush strokes',
        );
      case ImageStyle.watercolor:
        return _StylePrompt(
          description: '水彩画风格，柔和通透',
          suffix: ', watercolor painting, soft colors, translucent',
        );
      case ImageStyle.cyberpunk:
        return _StylePrompt(
          description: '赛博朋克风格，霓虹灯光',
          suffix: ', cyberpunk, neon lights, futuristic city',
        );
      case ImageStyle.pixel:
        return _StylePrompt(
          description: '像素艺术风格，复古游戏感',
          suffix: ', pixel art, 16-bit, retro game style',
        );
      case ImageStyle.render3d:
        return _StylePrompt(
          description: '3D 渲染风格，材质真实',
          suffix: ', 3d render, octane render, realistic materials',
        );
      case ImageStyle.illustration:
        return _StylePrompt(
          description: '插画风格，扁平设计',
          suffix: ', flat illustration, vector art, clean design',
        );
      case ImageStyle.sketch:
        return _StylePrompt(
          description: '素描风格，铅笔线条',
          suffix: ', pencil sketch, graphite drawing, monochrome',
        );
      case ImageStyle.chineseStyle:
        return _StylePrompt(
          description: '中国风国画风格，水墨意境',
          suffix: ', chinese ink painting, traditional art, elegant',
        );
      case ImageStyle.custom:
        return _StylePrompt(description: '自定义风格，无额外修饰', suffix: '');
    }
  }

  /// 获取所有尺寸预设
  List<ImageSizePreset> getSizePresets() {
    return ImageSize.values.map((size) {
      return ImageSizePreset(
        size: size,
        name: size.label,
        width: size.width,
        height: size.height,
        aspectRatio: size.aspectRatio,
      );
    }).toList();
  }
}

/// 风格预设
class ImageStylePreset {
  final ImageStyle style;
  final String name;
  final String description;
  final String promptSuffix;

  ImageStylePreset({
    required this.style,
    required this.name,
    this.description = '',
    this.promptSuffix = '',
  });
}

/// 尺寸预设
class ImageSizePreset {
  final ImageSize size;
  final String name;
  final int width;
  final int height;
  final double aspectRatio;

  ImageSizePreset({
    required this.size,
    required this.name,
    required this.width,
    required this.height,
    required this.aspectRatio,
  });
}

/// 风格提示词信息
class _StylePrompt {
  final String description;
  final String suffix;

  _StylePrompt({required this.description, required this.suffix});
}
