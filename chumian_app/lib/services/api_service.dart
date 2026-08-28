import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static String get _baseUrl {
    const encoded = 'aHR0cDovLzEwMy4yMzYuOTkuMTc3OjI0NTEz';
    return utf8.decode(base64.decode(encoded));
  }

  static String? _token;
  static void setToken(String? token) {
    _token = token;
  }

  static Map<String, String> get _headers {
    final h = {'Content-Type': 'application/json'};
    if (_token != null) {
      h['Cookie'] = 'token=$_token';
    }
    return h;
  }

  static Future<Map<String, dynamic>> sendCode(String email) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/api/auth/send-code'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(resp.body);
  }

  static Future<Map<String, dynamic>> register(
      String email, String code, String password, String nickname) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/api/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'code': code,
        'password': password,
        'nickname': nickname,
      }),
    );
    final data = jsonDecode(resp.body);
    if (resp.statusCode != 200) {
      throw data['error'] ?? data['detail'] ?? '注册失败';
    }
    final cookie = resp.headers['set-cookie'];
    if (cookie != null) {
      final match = RegExp(r'token=([^;]+)').firstMatch(cookie);
      if (match != null) {
        _token = match.group(1);
        data['token'] = _token;
      }
    }
    return data;
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/api/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(resp.body);
    if (resp.statusCode != 200) {
      throw data['error'] ?? data['detail'] ?? '登录失败';
    }
    final cookie = resp.headers['set-cookie'];
    if (cookie != null) {
      final match = RegExp(r'token=([^;]+)').firstMatch(cookie);
      if (match != null) {
        _token = match.group(1);
        data['token'] = _token;
      }
    }
    return data;
  }

  static Future<void> logout() async {
    try {
      await http.post(Uri.parse('$_baseUrl/api/auth/logout'), headers: _headers);
    } catch (_) {}
    _token = null;
  }

  static Future<void> completeOobe() async {
    await http.post(Uri.parse('$_baseUrl/api/auth/complete-oobe'),
        headers: _headers);
  }

  static Future<Map<String, dynamic>> getUserInfo() async {
    final resp = await http.get(Uri.parse('$_baseUrl/api/user/info'),
        headers: _headers);
    if (resp.statusCode != 200) {
      throw '未登录';
    }
    return jsonDecode(resp.body);
  }

  static Future<bool> verifyApp(String packageName, String apkMd5) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/verify-app'),
        headers: _headers,
        body: jsonEncode(
            {'package_name': packageName, 'apk_md5': apkMd5}),
      );
      final data = jsonDecode(resp.body);
      return data['valid'] == true;
    } catch (e) {
      return true;
    }
  }

  static Stream<Map<String, dynamic>> chatStream({
    String? conversationId,
    required String message,
    String model = 'glm-4-flash',
    String? imageUrl,
    String? agentId,
  }) async* {
    final client = http.Client();
    final request = http.Request(
      'POST',
      Uri.parse('$_baseUrl/api/chat/stream'),
    );
    request.headers.addAll(_headers);
    request.body = jsonEncode({
      'conversation_id': conversationId,
      'message': message,
      'model': model,
      if (imageUrl != null) 'image_url': imageUrl,
      if (agentId != null) 'agent_id': agentId,
    });
    final streamedResponse = await client.send(request);
    final transformer = StreamTransformer<List<int>, String>.fromHandlers(
      handleData: (data, sink) {
        sink.add(utf8.decode(data));
      },
    );
    await for (final chunk in streamedResponse.stream
        .transform(transformer)
        .transform(const LineSplitter())) {
      if (chunk.startsWith('data: ')) {
        final dataStr = chunk.substring(6);
        if (dataStr.isNotEmpty) {
          try {
            yield jsonDecode(dataStr);
          } catch (_) {}
        }
      }
    }
    client.close();
  }

  static Future<List<dynamic>> getConversations() async {
    final resp = await http.get(Uri.parse('$_baseUrl/api/conversations'),
        headers: _headers);
    if (resp.statusCode != 200) {
      return [];
    }
    final data = jsonDecode(resp.body);
    if (data is List) return data;
    return [];
  }

  static Future<List<dynamic>> getMessages(String conversationId) async {
    if (conversationId.isEmpty) return [];
    final resp = await http.get(
      Uri.parse('$_baseUrl/api/conversations/$conversationId/messages'),
      headers: _headers,
    );
    if (resp.statusCode != 200) {
      return [];
    }
    final data = jsonDecode(resp.body);
    if (data is List) return data;
    return [];
  }

  static Future<void> deleteConversation(String conversationId) async {
    if (conversationId.isEmpty) return;
    await http.delete(
      Uri.parse('$_baseUrl/api/conversations/$conversationId'),
      headers: _headers,
    );
  }

  static Future<Map<String, dynamic>> generateImage(String prompt,
      {String size = '1024x1024'}) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/api/generate/image'),
      headers: _headers,
      body: jsonEncode({'prompt': prompt, 'size': size}),
    );
    final data = jsonDecode(resp.body);
    if (resp.statusCode != 200) {
      throw data['detail'] ?? data['error'] ?? '图片生成失败';
    }
    return data;
  }

  static Future<Map<String, dynamic>> generateVideo(String prompt) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/api/generate/video'),
      headers: _headers,
      body: jsonEncode({'prompt': prompt}),
    );
    final data = jsonDecode(resp.body);
    if (resp.statusCode != 200) {
      throw data['detail'] ?? data['error'] ?? '视频生成失败';
    }
    return data;
  }

  static Future<Map<String, dynamic>> getVideoStatus(String taskId) async {
    final resp = await http.get(
      Uri.parse('$_baseUrl/api/generate/video/$taskId'),
      headers: _headers,
    );
    if (resp.statusCode != 200) {
      return {'status': 'failed'};
    }
    return jsonDecode(resp.body);
  }

  static Future<List<dynamic>> getPosts() async {
    final resp =
        await http.get(Uri.parse('$_baseUrl/api/posts'), headers: _headers);
    if (resp.statusCode != 200) return [];
    final data = jsonDecode(resp.body);
    if (data is List) return data;
    return [];
  }

  static Future<Map<String, dynamic>> createPost(
      String title, String content) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/api/posts'),
      headers: _headers,
      body: jsonEncode({'title': title, 'content': content}),
    );
    final data = jsonDecode(resp.body);
    if (resp.statusCode != 200) {
      throw data['detail'] ?? data['error'] ?? '发布失败';
    }
    return data;
  }

  static Future<bool> toggleLike(String postId) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/api/posts/$postId/like'),
      headers: _headers,
    );
    if (resp.statusCode != 200) return false;
    return jsonDecode(resp.body)['liked'] == true;
  }

  static Future<List<dynamic>> getComments(String postId) async {
    final resp = await http.get(
      Uri.parse('$_baseUrl/api/posts/$postId/comments'),
      headers: _headers,
    );
    if (resp.statusCode != 200) return [];
    final data = jsonDecode(resp.body);
    if (data is List) return data;
    return [];
  }

  static Future<void> addComment(String postId, String content) async {
    await http.post(
      Uri.parse('$_baseUrl/api/posts/$postId/comments'),
      headers: _headers,
      body: jsonEncode({'content': content}),
    );
  }

  static Future<List<dynamic>> getAgents() async {
    final resp =
        await http.get(Uri.parse('$_baseUrl/api/agents'), headers: _headers);
    if (resp.statusCode != 200) return [];
    final data = jsonDecode(resp.body);
    if (data is List) return data;
    return [];
  }

  static Future<Map<String, dynamic>> createAgent(
      String name, String description, String systemPrompt) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/api/agents'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'description': description,
        'system_prompt': systemPrompt,
      }),
    );
    return jsonDecode(resp.body);
  }

  static Future<List<dynamic>> getTemplates() async {
    final resp = await http.get(Uri.parse('$_baseUrl/api/templates'),
        headers: _headers);
    if (resp.statusCode != 200) return [];
    final data = jsonDecode(resp.body);
    if (data is List) return data;
    return [];
  }

  static Future<Map<String, dynamic>> getModels() async {
    final resp =
        await http.get(Uri.parse('$_baseUrl/api/models'), headers: _headers);
    if (resp.statusCode != 200) return {};
    return jsonDecode(resp.body);
  }

  static String getMediaUrl(String path) {
    if (path.startsWith('http')) return path;
    return '$_baseUrl$path';
  }
}
