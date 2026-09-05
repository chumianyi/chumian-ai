import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isStreaming = false;
  String _currentModel = 'glm-4-flash';
  String? _conversationId;
  String? _streamingContent;
  String? _thinkingContent;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isStreaming => _isStreaming;
  String get currentModel => _currentModel;
  String? get conversationId => _conversationId;
  String? get streamingContent => _streamingContent;

  void setModel(String model) {
    _currentModel = model;
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _conversationId = null;
    notifyListeners();
  }

  Future<void> sendMessage(String content) async {
    if (_isStreaming || content.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: content,
      model: _currentModel,
    );
    _messages.add(userMsg);
    _isStreaming = true;
    _streamingContent = '';
    _thinkingContent = '';
    notifyListeners();

    final aiMsgId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    final aiMsg = ChatMessage(
      id: aiMsgId,
      role: 'assistant',
      content: '',
      model: _currentModel,
      isStreaming: true,
    );
    _messages.add(aiMsg);

    try {
      final stream = ApiService().chatStream(content, _currentModel, conversationId: _conversationId);
      await for (final delta in stream) {
        final idx = _messages.indexWhere((m) => m.id == aiMsgId);
        if (idx >= 0) {
          _messages[idx] = ChatMessage(
            id: aiMsgId,
            role: 'assistant',
            content: (_messages[idx].content) + delta,
            model: _currentModel,
            isStreaming: true,
          );
          _streamingContent = _messages[idx].content;
          notifyListeners();
        }
      }
      final idx = _messages.indexWhere((m) => m.id == aiMsgId);
      if (idx >= 0) {
        _messages[idx] = ChatMessage(
          id: aiMsgId,
          role: 'assistant',
          content: _messages[idx].content,
          model: _currentModel,
          isStreaming: false,
        );
      }
    } catch (e) {
      final idx = _messages.indexWhere((m) => m.id == aiMsgId);
      if (idx >= 0) {
        _messages[idx] = ChatMessage(
          id: aiMsgId,
          role: 'assistant',
          content: '出错了：${e.toString().replaceAll('Exception: ', '')}',
          model: _currentModel,
          isStreaming: false,
        );
      }
    }
    _isStreaming = false;
    _streamingContent = null;
    notifyListeners();
  }
}
