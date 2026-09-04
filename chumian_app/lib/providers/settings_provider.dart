import 'package:flutter/foundation.dart';

class SettingsProvider extends ChangeNotifier {
  bool _ttsEnabled = false;
  bool get ttsEnabled => _ttsEnabled;

  double _ttsSpeed = 1.0;
  double get ttsSpeed => _ttsSpeed;

  bool _autoSave = true;
  bool get autoSave => _autoSave;

  bool _streamingEnabled = true;
  bool get streamingEnabled => _streamingEnabled;

  bool _markdownEnabled = true;
  bool get markdownEnabled => _markdownEnabled;

  String _fontFamily = 'LXGW WenKai';
  String get fontFamily => _fontFamily;

  void setTtsEnabled(bool v) {
    _ttsEnabled = v;
    notifyListeners();
  }

  void setTtsSpeed(double v) {
    _ttsSpeed = v;
    notifyListeners();
  }

  void setAutoSave(bool v) {
    _autoSave = v;
    notifyListeners();
  }

  void setStreamingEnabled(bool v) {
    _streamingEnabled = v;
    notifyListeners();
  }

  void setMarkdownEnabled(bool v) {
    _markdownEnabled = v;
    notifyListeners();
  }
}
