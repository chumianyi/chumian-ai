/// 内置 TTS 语音朗读服务（基于 flutter_tts，支持离线语音包）。
library;

import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _isSpeaking = false;
  bool _isPaused = false;

  bool get isSpeaking => _isSpeaking;
  bool get isPaused => _isPaused;

  Future<void> init() async {
    if (_initialized) return;
    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      _isPaused = false;
    });
    _initialized = true;
  }

  Future<void> speak(String text) async {
    await init();
    await _tts.stop();
    _isSpeaking = true;
    _isPaused = false;
    await _tts.speak(text);
  }

  Future<void> pause() async {
    if (!_isSpeaking) return;
    await _tts.pause();
    _isPaused = true;
  }

  Future<void> resume() async {
    if (!_isPaused) return;
    _isPaused = false;
  }

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
    _isPaused = false;
  }

  void dispose() {
    _tts.stop();
  }
}
