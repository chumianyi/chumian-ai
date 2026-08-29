import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://103.236.99.177:24512';
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 120),
    headers: {'Content-Type': 'application/json'},
  ));

  static String? _token;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
    }
  }

  static Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      prefs.setString('token', token);
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      prefs.remove('token');
      _dio.options.headers.remove('Authorization');
    }
  }

  static String? get token => _token;

  static Future<bool> verifyApp(String packageName, String apkMd5) async {
    try {
      final resp = await _dio.post('/api/verify-app', data: {
        'package_name': packageName,
        'apk_md5': apkMd5,
      });
      return resp.data['valid'] == true;
    } catch (_) {
      return true;
    }
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String nickname,
  }) async {
    final resp = await _dio.post('/api/auth/register', data: {
      'username': username,
      'password': password,
      'nickname': nickname,
    });
    final data = Map<String, dynamic>.from(resp.data);
    if (data['token'] != null) {
      await setToken(data['token']);
    }
    return data;
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final resp = await _dio.post('/api/auth/login', data: {
      'username': username,
      'password': password,
    });
    final data = Map<String, dynamic>.from(resp.data);
    if (data['token'] != null) {
      await setToken(data['token']);
    }
    return data;
  }

  static Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
    } catch (_) {}
    await setToken(null);
  }

  static Future<void> completeOobe() async {
    await _dio.post('/api/auth/complete-oobe');
  }

  static Future<Map<String, dynamic>> getUserInfo() async {
    final resp = await _dio.get('/api/user/info');
    return Map<String, dynamic>.from(resp.data);
  }

  static Future<List<dynamic>> getPointsLog() async {
    final resp = await _dio.get('/api/user/points-log');
    return List<dynamic>.from(resp.data);
  }

  static Future<Map<String, dynamic>> getModels() async {
    final resp = await _dio.get('/api/models');
    return Map<String, dynamic>.from(resp.data);
  }

  static Future<List<dynamic>> getTemplates() async {
    final resp = await _dio.get('/api/templates');
    return List<dynamic>.from(resp.data);
  }

  static Stream<Map<String, dynamic>> chatStream({
    String? conversationId,
    required String message,
    String model = 'glm-4-flash',
    String? imageUrl,
    String? agentId,
  }) {
    final controller = StreamController<Map<String, dynamic>>();
    final data = {
      'conversation_id': conversationId,
      'message': message,
      'model': model,
      if (imageUrl != null) 'image_url': imageUrl,
      if (agentId != null) 'agent_id': agentId,
    };

    _dio.post(
      '/api/chat/stream',
      data: jsonEncode(data),
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      ),
    ).then((response) {
      final stream = response.data.stream as Stream<List<int>>;
      String buffer = '';
      stream.listen(
        (bytes) {
          buffer += utf8.decode(bytes);
          final lines = buffer.split('\n');
          buffer = lines.removeLast();
          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final jsonStr = line.substring(6);
              if (jsonStr.isNotEmpty) {
                try {
                  final parsed = jsonDecode(jsonStr);
                  if (parsed is Map<String, dynamic>) {
                    controller.add(parsed);
                  }
                } catch (_) {}
              }
            }
          }
        },
        onDone: () => controller.close(),
        onError: (e) {
          controller.add({'type': 'error', 'message': e.toString()});
          controller.close();
        },
      );
    }).catchError((e) {
      controller.add({'type': 'error', 'message': e.toString()});
      controller.close();
    });

    return controller.stream;
  }

  static Future<Map<String, dynamic>> getVideoStatus(String taskId) async {
    final resp = await _dio.get('/api/generate/video/$taskId');
    return Map<String, dynamic>.from(resp.data);
  }

  static Future<List<dynamic>> getConversations() async {
    final resp = await _dio.get('/api/conversations');
    return List<dynamic>.from(resp.data);
  }

  static Future<List<dynamic>> getConversationMessages(String convId) async {
    final resp = await _dio.get('/api/conversations/$convId/messages');
    return List<dynamic>.from(resp.data);
  }

  static Future<void> deleteConversation(String convId) async {
    await _dio.delete('/api/conversations/$convId');
  }

  static Future<List<dynamic>> getPosts() async {
    final resp = await _dio.get('/api/posts');
    return List<dynamic>.from(resp.data);
  }

  static Future<Map<String, dynamic>> getPost(String postId) async {
    final resp = await _dio.get('/api/posts/$postId');
    return Map<String, dynamic>.from(resp.data);
  }

  static Future<Map<String, dynamic>> createPost(String title, String content) async {
    final resp = await _dio.post('/api/posts', data: {'title': title, 'content': content, 'type': 'image'});
    return Map<String, dynamic>.from(resp.data);
  }

  static Future<Map<String, dynamic>> createMediaPost({required String title, required String content, required String type, String mediaUrl = '', String agentId = ''}) async {
    final resp = await _dio.post('/api/posts', data: {'title': title, 'content': content, 'type': type, 'media_url': mediaUrl, 'agent_id': agentId});
    return Map<String, dynamic>.from(resp.data);
  }

  static Future<List<dynamic>> getExplore({String type = 'all'}) async {
    final resp = await _dio.get('/api/explore', queryParameters: {'type': type});
    return List<dynamic>.from(resp.data);
  }

  static Future<Map<String, dynamic>> cloneAgent(String agentId) async {
    final resp = await _dio.post('/api/agents/$agentId/clone');
    return Map<String, dynamic>.from(resp.data);
  }

  static Future<Map<String, dynamic>> likeAgent(String agentId) async {
    final resp = await _dio.post('/api/agents/$agentId/like');
    return Map<String, dynamic>.from(resp.data);
  }

  static Future<Map<String, dynamic>> publishAgent(String agentId) async {
    final resp = await _dio.post('/api/agents/$agentId/publish');
    return Map<String, dynamic>.from(resp.data);
  }

  static Future<List<dynamic>> getAgentLeaderboard({int limit = 50}) async {
    final resp = await _dio.get('/api/agents/leaderboard', queryParameters: {'limit': limit});
    return List<dynamic>.from(resp.data);
  }

  static Future<Map<String, dynamic>> likePost(String postId) async {
    final resp = await _dio.post('/api/posts/$postId/like');
    return Map<String, dynamic>.from(resp.data);
  }

  static Future<List<dynamic>> getComments(String postId) async {
    final resp = await _dio.get('/api/posts/$postId/comments');
    return List<dynamic>.from(resp.data);
  }

  static Future<Map<String, dynamic>> createComment(String postId, String content) async {
    final resp = await _dio.post('/api/posts/$postId/comments', data: {'content': content});
    return Map<String, dynamic>.from(resp.data);
  }

  static Future<List<dynamic>> getAgents() async {
    final resp = await _dio.get('/api/agents');
    return List<dynamic>.from(resp.data);
  }

  static Future<Map<String, dynamic>> getAgent(String agentId) async {
    final resp = await _dio.get('/api/agents/$agentId');
    return Map<String, dynamic>.from(resp.data);
  }

  static Future<Map<String, dynamic>> createAgent({
    required String name,
    required String description,
    required String systemPrompt,
    String openingMessage = '',
    String avatar = '',
  }) async {
    final resp = await _dio.post('/api/agents', data: {
      'name': name,
      'description': description,
      'system_prompt': systemPrompt,
      'opening_message': openingMessage,
      'avatar': avatar,
    });
    return Map<String, dynamic>.from(resp.data);
  }

  static String getMediaUrl(String path) {
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }

  // ===== v2.0 New APIs =====
  static Future<Map<String, dynamic>> checkin() async {
    final resp = await _dio.post('/api/checkin');
    return Map<String, dynamic>.from(resp.data);
  }

  static Future<Map<String, dynamic>> checkinStatus() async {
    final resp = await _dio.get('/api/checkin/status');
    return Map<String, dynamic>.from(resp.data);
  }

  static Future<Map<String, dynamic>> exchangePoints(int amount) async {
    final resp = await _dio.post('/api/shop/exchange', data: {'amount': amount});
    return Map<String, dynamic>.from(resp.data);
  }

  static Future<Map<String, dynamic>> buySvip(String plan) async {
    final resp = await _dio.post('/api/shop/svip', data: {'plan': plan});
    return Map<String, dynamic>.from(resp.data);
  }

  static Future<Map<String, dynamic>> guessActivity(int points, String choice) async {
    final resp = await _dio.post('/api/activity/guess', data: {'points': points, 'choice': choice});
    return Map<String, dynamic>.from(resp.data);
  }

  static Future<Map<String, dynamic>> guessStatus() async {
    final resp = await _dio.get('/api/activity/guess/status');
    return Map<String, dynamic>.from(resp.data);
  }

  static Future<void> updateProfile({String? nickname, String? avatar, String? qq, String? birthday}) async {
    final data = <String, dynamic>{};
    if (nickname != null) data['nickname'] = nickname;
    if (avatar != null) data['avatar'] = avatar;
    if (qq != null) data['qq'] = qq;
    if (birthday != null) data['birthday'] = birthday;
    await _dio.put('/api/profile', data: data);
  }

  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final resp = await _dio.get('/api/users/$userId');
    return Map<String, dynamic>.from(resp.data);
  }

  static Future<Map<String, dynamic>> followUser(String userId) async {
    final resp = await _dio.post('/api/users/$userId/follow');
    return Map<String, dynamic>.from(resp.data);
  }

  static Future<List<dynamic>> getFollowers(String userId) async {
    final resp = await _dio.get('/api/users/$userId/followers');
    return List<dynamic>.from(resp.data);
  }

  static Future<List<dynamic>> getFollowing(String userId) async {
    final resp = await _dio.get('/api/users/$userId/following');
    return List<dynamic>.from(resp.data);
  }

  static Future<List<dynamic>> getNotifications() async {
    final resp = await _dio.get('/api/notifications');
    return List<dynamic>.from(resp.data);
  }

  static Future<void> readNotification(String nid) async {
    await _dio.post('/api/notifications/$nid/read');
  }
