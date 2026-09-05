import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/chat_message.dart';
import '../models/mail_agent_post.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String baseUrl = 'http://103.236.99.177:24512';
  late Dio _dio;
  String? _token;

  Future<void> init() async {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
    }
  }

  void setToken(String? token) {
    _token = token;
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  // ==================== Auth ====================

  Future<UserModel> login(String username, String password) async {
    final resp = await _dio.post('/api/auth/login', data: {
      'username': username,
      'password': password,
    });
    final data = resp.data;
    final user = UserModel.fromJson(data);
    setToken(user.token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', user.token);
    await prefs.setString('user_id', user.id);
    return user;
  }

  Future<UserModel> register(String username, String password, String nickname, String code) async {
    final resp = await _dio.post('/api/auth/register', data: {
      'username': username,
      'password': password,
      'nickname': nickname,
      'code': code,
    });
    final data = resp.data;
    final user = UserModel.fromJson(data);
    setToken(user.token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', user.token);
    await prefs.setString('user_id', user.id);
    return user;
  }

  Future<void> sendCode(String email) async {
    await _dio.post('/api/auth/send-code', data: {'email': email});
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
    } catch (_) {}
    setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
  }

  Future<UserModel> getUserInfo() async {
    final resp = await _dio.get('/api/user/info');
    return UserModel.fromJson(resp.data);
  }

  // ==================== Chat ====================

  Stream<String> chatStream(String message, String model, {String? conversationId}) async* {
    final resp = await _dio.post(
      '/api/chat/stream',
      data: {
        'message': message,
        'model': model,
        if (conversationId != null) 'conversation_id': conversationId,
      },
      options: Options(responseType: ResponseType.stream),
    );
    await for (final chunk in resp.data.stream) {
      final text = utf8.decode(chunk);
      final lines = text.split('\n');
      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') continue;
          try {
            final json = jsonDecode(data);
            final delta = json['delta'] ?? json['content'] ?? '';
            if (delta.isNotEmpty) yield delta;
          } catch (_) {}
        }
      }
    }
  }

  Future<List<Conversation>> getConversations() async {
    final resp = await _dio.get('/api/conversations');
    final List list = resp.data is List ? resp.data : (resp.data['data'] ?? []);
    return list.map((e) => Conversation.fromJson(e)).toList();
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final resp = await _dio.get('/api/conversations/$conversationId/messages');
    final List list = resp.data is List ? resp.data : (resp.data['data'] ?? []);
    return list.map((e) => ChatMessage.fromJson(e)).toList();
  }

  Future<void> deleteConversation(String conversationId) async {
    await _dio.delete('/api/conversations/$conversationId');
  }

  // ==================== Models ====================

  Future<List<ModelInfo>> getModels() async {
    final resp = await _dio.get('/api/models');
    final List list = resp.data is List ? resp.data : (resp.data['models'] ?? resp.data['data'] ?? []);
    return list.map((e) => ModelInfo.fromJson(e)).toList();
  }

  // ==================== Agents ====================

  Future<List<Agent>> getAgents() async {
    final resp = await _dio.get('/api/agents');
    final List list = resp.data is List ? resp.data : (resp.data['data'] ?? []);
    return list.map((e) => Agent.fromJson(e)).toList();
  }

  // ==================== Explore / Posts ====================

  Future<List<Post>> getPosts() async {
    final resp = await _dio.get('/api/posts');
    final List list = resp.data is List ? resp.data : (resp.data['data'] ?? []);
    return list.map((e) => Post.fromJson(e)).toList();
  }

  Future<void> likePost(String postId) async {
    await _dio.post('/api/posts/$postId/like');
  }

  // ==================== Points / Checkin ====================

  Future<Map<String, dynamic>> checkin() async {
    final resp = await _dio.post('/api/checkin');
    return resp.data;
  }

  Future<Map<String, dynamic>> getCheckinStatus() async {
    final resp = await _dio.get('/api/checkin/status');
    return resp.data;
  }

  Future<Map<String, dynamic>> guess(bool isBig) async {
    final resp = await _dio.post('/api/activity/guess', data: {'guess': isBig ? 'big' : 'small'});
    return resp.data;
  }

  // ==================== Mails ====================

  Future<List<MailItem>> getMails() async {
    final resp = await _dio.get('/api/mails');
    final List list = resp.data['data'] ?? [];
    return list.map((e) => MailItem.fromJson(e)).toList();
  }

  Future<MailItem> getMailDetail(String mailId) async {
    final resp = await _dio.get('/api/mails/$mailId');
    return MailItem.fromJson(resp.data['data']);
  }

  Future<void> markMailRead(String mailId) async {
    await _dio.post('/api/mails/$mailId/read');
  }

  Future<void> markAllMailsRead() async {
    await _dio.post('/api/mails/read-all');
  }

  // ==================== Image/Video Generation ====================

  Future<String> generateImage(String prompt) async {
    final resp = await _dio.post('/api/generate/image', data: {'prompt': prompt});
    return resp.data['image_url'] ?? resp.data['url'] ?? '';
  }

  // ==================== Search ====================

  Future<List<dynamic>> search(String query) async {
    final resp = await _dio.get('/api/search', queryParameters: {'q': query});
    return resp.data['results'] ?? resp.data is List ? resp.data : [];
  }

  // ==================== Version ====================

  Future<Map<String, dynamic>> checkVersion() async {
    final resp = await _dio.get('/api/version/check');
    return resp.data;
  }
}
