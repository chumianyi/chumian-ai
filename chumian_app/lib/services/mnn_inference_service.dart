import 'dart:async';
import 'package:flutter/services.dart';
import '../models/local_model.dart';

/// MNN端侧推理服务
/// 通过MethodChannel调用Android原生层MNN框架进行推理
class MNNInferenceService {
  MNNInferenceService._();
  static final MNNInferenceService instance = MNNInferenceService._();

  static const MethodChannel _channel = MethodChannel('com.chumianai.mnn');

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  String? _currentModelId;
  String? get currentModelId => _currentModelId;

  /// 初始化MNN引擎
  Future<bool> initialize() async {
    try {
      final result = await _channel.invokeMethod<bool>('initialize');
      _isInitialized = result ?? false;
      return _isInitialized;
    } on PlatformException catch (e) {
      // MNN原生库可能未集成，返回false但不崩溃
      _isInitialized = false;
      return false;
    }
  }

  /// 加载模型
  Future<bool> loadModel(LocalModel model) async {
    if (!_isInitialized) {
      final initOk = await initialize();
      if (!initOk) return false;
    }
    try {
      final result = await _channel.invokeMethod<bool>('loadModel', {
        'modelId': model.id,
        'modelPath': model.localPath,
        'modelType': model.type,
      });
      if (result ?? false) {
        _currentModelId = model.id;
      }
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 卸载模型
  Future<void> unloadModel() async {
    try {
      await _channel.invokeMethod('unloadModel');
      _currentModelId = null;
    } on PlatformException {
      // ignore
    }
  }

  /// 同步推理（非流式）
  Future<String> infer(String prompt, {int maxTokens = 512, double temperature = 0.7}) async {
    try {
      final result = await _channel.invokeMethod<String>('infer', {
        'prompt': prompt,
        'maxTokens': maxTokens,
        'temperature': temperature,
      });
      return result ?? '';
    } on PlatformException catch (e) {
      return '本地模型推理失败：${e.message}。请确保模型已下载且MNN引擎已初始化。';
    }
  }

  /// 流式推理（逐字输出）
  Stream<String> inferStream(String prompt, {int maxTokens = 512, double temperature = 0.7}) {
    final controller = StreamController<String>();

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onToken') {
        final token = call.arguments as String?;
        if (token != null) {
          controller.add(token);
        }
      } else if (call.method == 'onComplete') {
        controller.close();
      } else if (call.method == 'onError') {
        controller.addError(call.arguments ?? '推理错误');
        controller.close();
      }
      return null;
    });

    // 启动流式推理
    _channel.invokeMethod('inferStream', {
      'prompt': prompt,
      'maxTokens': maxTokens,
      'temperature': temperature,
    }).catchError((e) {
      controller.addError(e.toString());
      controller.close();
    });

    return controller.stream;
  }

  /// 检查MNN是否可用
  Future<bool> isMNNAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 获取推理设备信息
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final result = await _channel.invokeMethod<Map>('getDeviceInfo');
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException {
      return {
        'available': false,
        'backend': 'N/A',
        'threads': 0,
      };
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    await unloadModel();
    try {
      await _channel.invokeMethod('dispose');
    } on PlatformException {
      // ignore
    }
    _isInitialized = false;
  }
}
