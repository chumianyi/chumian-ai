/// TTS 语音朗读服务（基于 flutter_tts）。
library;

import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { stopped, playing, paused }

class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _initFailed = false;
  String? _initError;
  TtsState _state = TtsState.stopped;

  TtsState get state => _state;
  bool get isSpeaking => _state == TtsState.playing;
  bool get isPaused => _state == TtsState.paused;
  bool get isAvailable => !_initFailed;
  String? get initError => _initError;

  /// 状态变化回调，供 UI 监听
  void Function(TtsState)? onStateChanged;

  Future<void> init() async {
    if (_initialized) return;
    if (_initFailed) return;

    try {
      // 等待朗读完成，这样 speak() 才会真正阻塞到朗读结束
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('zh-CN');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // Android 上设置引擎
      try {
        await _tts.setEngine('com.google.android.tts');
      } catch (_) {
        // 忽略，使用默认引擎
      }

      _tts.setCompletionHandler(() {
        _state = TtsState.stopped;
        onStateChanged?.call(_state);
      });

      _tts.setErrorHandler((msg) {
        _state = TtsState.stopped;
        onStateChanged?.call(_state);
      });

      _initialized = true;
    } catch (e) {
      _initFailed = true;
      _initError = e.toString();
    }
  }

  /// 朗读文本，返回是否成功
  Future<bool> speak(String text) async {
    await init();
    if (_initFailed) return false;

    try {
      await _tts.stop();
      _state = TtsState.playing;
      onStateChanged?.call(_state);

      final result = await _tts.speak(text);
      // flutter_tts speak 返回 1 表示成功，0 表示失败
      if (result == 0 || result == null) {
        _state = TtsState.stopped;
        onStateChanged?.call(_state);
        return false;
      }
      return true;
    } catch (e) {
      _state = TtsState.stopped;
      onStateChanged?.call(_state);
      return false;
    }
  }

  Future<void> pause() async {
    if (_state != TtsState.playing) return;
    try {
      await _tts.pause();
      _state = TtsState.paused;
      onStateChanged?.call(_state);
    } catch (_) {}
  }

  Future<void> resume() async {
    if (_state != TtsState.paused) return;
    try {
      await _tts.resume();
      _state = TtsState.playing;
      onStateChanged?.call(_state);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _state = TtsState.stopped;
    onStateChanged?.call(_state);
  }

  void dispose() {
    try {
      _tts.stop();
    } catch (_) {}
  }
}
