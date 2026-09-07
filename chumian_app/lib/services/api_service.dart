import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chumian_ai/models/search_result.dart';

/// ============================================================================
/// ApiService —— 初眠AI 全局网络服务层（静态类）
///
/// 职责：
///   1. 管理 Dio 实例、baseUrl、Token 注入与持久化
///   2. 封装全部后端 REST API（认证 / 用户 / 聊天 / 模型 / 生成 /
///      社区 / Agent / 积分商城 / 活动 / 通知 / 联网搜索 / 法律）
///   3. 提供 SSE 流式聊天接口 chatStream，正确处理 data: 行与缓冲区拼接
///   4. 所有方法均有 try-catch，错误时抛出异常或返回空集合
/// ============================================================================
class ApiService {
  // ===== 基础配置 =====
  static const String baseUrl = 'http://103.236.99.177:24512';

  /// 全局 Dio 实例，统一超时与请求头
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 120),
    sendTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));

  /// 内存中的 Token 缓存
  static String? _token;

  /// SharedPreferences 中 Token 的存储键
  static const String _tokenKey = 'token';

  // ==========================================================================
  // Token 管理
  // ==========================================================================

  /// 初始化：从 SharedPreferences 恢复 Token 并注入 Dio 请求头
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    if (_token != null && _token!.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
    }
  }

  /// 设置 Token：同时更新内存、持久化存储和 Dio 请求头
  /// 传入 null 表示清除 Token（登出）
  static Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null && token.isNotEmpty) {
      await prefs.setString(_tokenKey, token);
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      await prefs.remove(_tokenKey);
      _dio.options.headers.remove('Authorization');
    }
  }

  /// 获取当前 Token（只读）
  static String? get token => _token;

  /// 判断是否已登录
  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  // ==========================================================================
  // 认证相关
  // ==========================================================================

  /// 应用完整性校验（包名 + APK MD5）
  /// 校验失败返回 false；网络异常时默认放行（返回 true）
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

  /// 用户注册
  /// 返回包含 token / user_id / nickname 等字段的 Map
  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String nickname,
  }) async {
    try {
      final resp = await _dio.post('/api/auth/register', data: {
        'username': username,
        'password': password,
        'nickname': nickname,
      });
      final data = Map<String, dynamic>.from(resp.data);
      if (data['token'] != null) {
        await setToken(data['token'].toString());
      }
      return data;
    } catch (e) {
      rethrow;
    }
  }

  /// 用户登录
  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    try {
      final resp = await _dio.post('/api/auth/login', data: {
        'username': username,
        'password': password,
      });
      final data = Map<String, dynamic>.from(resp.data);
      if (data['token'] != null) {
        await setToken(data['token'].toString());
      }
      return data;
    } catch (e) {
      rethrow;
    }
  }

  /// 登出：调用后端登出接口（失败不阻塞），然后清除本地 Token
  static Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
    } catch (_) {}
    await setToken(null);
  }

  /// 完成新手引导（OOBE）
  static Future<void> completeOobe() async {
    try {
      await _dio.post('/api/auth/complete-oobe');
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================================================
  // 用户相关
  // ==========================================================================

  /// 获取当前登录用户信息
  static Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final resp = await _dio.get('/api/user/info');
      return Map<String, dynamic>.from(resp.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 获取积分变动日志
  static Future<List<dynamic>> getPointsLog() async {
    try {
      final resp = await _dio.get('/api/user/points-log');
      return List<dynamic>.from(resp.data);
    } catch (_) {
      return [];
    }
  }

  /// 更新用户资料（仅传入需要修改的字段）
  static Future<void> updateProfile({
    String? nickname,
    String? avatar,
    String? qq,
    String? birthday,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (nickname != null) data['nickname'] = nickname;
      if (avatar != null) data['avatar'] = avatar;
      if (qq != null) data['qq'] = qq;
      if (birthday != null) data['birthday'] = birthday;
      await _dio.put('/api/profile', data: data);
    } catch (e) {
      rethrow;
    }
  }

  /// 获取指定用户的公开资料
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final resp = await _dio.get('/api/users/$userId');
      return Map<String, dynamic>.from(resp.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 关注 / 取消关注用户
  static Future<Map<String, dynamic>> followUser(String userId) async {
    try {
      final resp = await _dio.post('/api/users/$userId/follow');
      return Map<String, dynamic>.from(resp.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 获取粉丝列表
  static Future<List<dynamic>> getFollowers(String userId) async {
    try {
      final resp = await _dio.get('/api/users/$userId/followers');
      return List<dynamic>.from(resp.data);
    } catch (_) {
      return [];
    }
  }

  /// 获取关注列表
  static Future<List<dynamic>> getFollowing(String userId) async {
    try {
      final resp = await _dio.get('/api/users/$userId/following');
      return List<dynamic>.from(resp.data);
    } catch (_) {
      return [];
    }
  }

  /// 获取黑名单用户列表
  static Future<List<dynamic>> getBlockedUsers() async {
    try {
      final resp = await _dio.get('/api/user/blocked');
      return List<dynamic>.from(resp.data);
    } catch (_) {
      return [];
    }
  }

  /// 获取收藏列表
  static Future<List<dynamic>> getFavorites() async {
    try {
      final resp = await _dio.get('/api/user/favorites');
      return List<dynamic>.from(resp.data);
    } catch (_) {
      return [];
    }
  }

  /// 获取草稿列表
  static Future<List<dynamic>> getDrafts() async {
    try {
      final resp = await _dio.get('/api/user/drafts');
      return List<dynamic>.from(resp.data);
    } catch (_) {
      return [];
    }
  }

  /// 获取浏览历史
  static Future<List<dynamic>> getHistory() async {
    try {
      final resp = await _dio.get('/api/user/history');
      return List<dynamic>.from(resp.data);
    } catch (_) {
      return [];
    }
  }

  // ==========================================================================
  // 聊天相关（核心：SSE 流式）
  // ==========================================================================

  /// SSE 流式聊天接口
  ///
  /// 通过 Dio 的 ResponseType.stream 获取 SSE 字节流，
  /// 使用缓冲区拼接处理跨 chunk 的 data: 行，逐行解析 JSON 事件。
  ///
  /// 支持的事件类型（服务端推送的 JSON 中 type 字段）：
  ///   - think        : AI 思考过程片段
  ///   - content      : 正文内容片段（打字机效果）
  ///   - image        : AI 生成的图片 URL
  ///   - video_task   : 视频生成任务已创建，返回 task_id
  ///   - search_results: 联网搜索结果列表
  ///   - done         : 流式生成结束，可能携带 conversation_id / tokens
  ///   - error        : 服务端错误
  ///
  /// [conversationId]    会话 ID，首次发送为 null 由服务端创建
  /// [message]           用户输入文本
  /// [model]             使用的模型标识
  /// [imageUrl]          附带图片 URL（图文对话）
  /// [agentId]           使用的 Agent ID
  /// [webSearchEnabled]  是否启用联网搜索（用户手动开关）
  static Stream<Map<String, dynamic>> chatStream({
    String? conversationId,
    required String message,
    String model = 'glm-4-flash',
    String? imageUrl,
    String? agentId,
    bool webSearchEnabled = false,
  }) {
    final controller = StreamController<Map<String, dynamic>>();

    // 构造请求体：仅在非空时传入可选字段
    final data = <String, dynamic>{
      'conversation_id': conversationId,
      'message': message,
      'model': model,
      'web_search': webSearchEnabled,
    };
    if (imageUrl != null && imageUrl.isNotEmpty) {
      data['image_url'] = imageUrl;
    }
    if (agentId != null && agentId.isNotEmpty) {
      data['agent_id'] = agentId;
    }

    // 发起流式 POST 请求
    _dio
        .post(
      '/api/chat/stream',
      data: jsonEncode(data),
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      ),
    )
        .then((response) {
      // 获取底层字节流
      final stream = response.data.stream as Stream<List<int>>;
      String buffer = '';

      stream.listen(
        (bytes) {
          // 将新到达的字节追加到缓冲区
          buffer += utf8.decode(bytes, allowMalformed: true);

          // 按换行分割；最后一段可能不完整，保留在缓冲区中
          final lines = buffer.split('\n');
          buffer = lines.removeLast();

          for (final line in lines) {
            final trimmed = line.trim();
            // SSE 事件以 "data: " 开头
            if (trimmed.startsWith('data: ')) {
              final jsonStr = trimmed.substring(6).trim();
              if (jsonStr.isEmpty) continue;
              // SSE 结束标记
              if (jsonStr == '[DONE]') {
                controller.add({'type': 'done'});
                continue;
              }
              try {
                final parsed = jsonDecode(jsonStr);
                if (parsed is Map<String, dynamic>) {
                  controller.add(parsed);
                }
              } catch (_) {
                // 单行 JSON 解析失败时忽略，继续处理后续行
              }
            }
          }
        },
        onDone: () {
          // 流结束时，如果缓冲区中还有残留数据，尝试最后解析一次
          if (buffer.trim().isNotEmpty) {
            final trimmed = buffer.trim();
            if (trimmed.startsWith('data: ')) {
              final jsonStr = trimmed.substring(6).trim();
              if (jsonStr.isNotEmpty && jsonStr != '[DONE]') {
                try {
                  final parsed = jsonDecode(jsonStr);
                  if (parsed is Map<String, dynamic>) {
                    controller.add(parsed);
                  }
                } catch (_) {}
              }
            }
          }
          controller.close();
        },
        onError: (e) {
          controller.add({'type': 'error', 'message': e.toString()});
          controller.close();
        },
        cancelOnError: true,
      );
    }).catchError((e) {
      // 请求本身失败（网络错误、超时等）
      controller.add({'type': 'error', 'message': e.toString()});
      controller.close();
    });

    return controller.stream;
  }

  /// 获取会话列表
  static Future<List<dynamic>> getConversations() async {
    try {
      final resp = await _dio.get('/api/conversations');
      return List<dynamic>.from(resp.data);
    } catch (_) {
      return [];
    }
  }

  /// 获取指定会话的历史消息
  static Future<List<dynamic>> getConversationMessages(
      String convId) async {
    try {
      final resp = await _dio.get('/api/conversations/$convId/messages');
      return List<dynamic>.from(resp.data);
    } catch (_) {
      return [];
    }
  }

  /// 删除会话
  static Future<void> deleteConversation(String convId) async {
    try {
      await _dio.delete('/api/conversations/$convId');
    } catch (_) {}
  }

  /// 重命名会话
  static Future<void> renameConversation(
      String convId, String title) async {
    try {
      await _dio.patch('/api/conversations/$convId', data: {
        'title': title,
      });
    } catch (_) {}
  }

  // ==========================================================================
  // 模型相关
  // ==========================================================================

  /// 获取可用模型列表
  static Future<Map<String, dynamic>> getModels() async {
    try {
      final resp = await _dio.get('/api/models');
      return Map<String, dynamic>.from(resp.data);
    } catch (_) {
      return {};
    }
  }

  // ==========================================================================
  // 生成相关（图片 / 视频）
  // ==========================================================================

  /// 查询视频生成任务状态
  static Future<Map<String, dynamic>> getVideoStatus(String taskId) async {
    try {
      final resp = await _dio.get('/api/generate/video/$taskId');
      return Map<String, dynamic>.from(resp.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 生成图片
  static Future<Map<String, dynamic>> generateImage(String prompt) async {
    try {
      final resp = await _dio.post('/api/generate/image', data: {
        'prompt': prompt,
      });
      return Map<String, dynamic>.from(resp.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 生成视频（返回 task_id，需配合 getVideoStatus 轮询）
  static Future<Map<String, dynamic>> generateVideo(String prompt) async {
    try {
      final resp = await _dio.post('/api/generate/video', data: {
        'prompt': prompt,
      });
      return Map<String, dynamic>.from(resp.data);
    } catch (e) {
      rethrow;
    }
  }

  // ==========================================================================
  // 社区相关
  // ==========================================================================

  /// 获取帖子列表
  static Future<List<dynamic>> getPosts() async {
    try {
      final resp = await _dio.get('/api/posts');
      return List<dynamic>.from(resp.data);
    } catch (_) {
      return [];
    }
  }

  /// 获取单条帖子详情
  static Future<Map<String, dynamic>> getPost(String postId) async {
    try {
      final resp = await _dio.get('/api/posts/$postId');
      return Map<String, dynamic>.from(resp.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 创建纯文本帖子
  static Future<Map<String, dynamic>> createPost(
      String title, String content) async {
    try {
      final resp = await _dio.post('/api/posts', data: {
        'title': title,
        'content': content,
        'type': 'text',
      });
      return Map<String, dynamic>.from(resp.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 创建带多媒体的帖子（图片 / 视频）
  static Future<Map<String, dynamic>> createMediaPost({
    required String title,
    required String content,
    required String type,
    String mediaUrl = '',
    String agentId = '',
  }) async {
    try {
      final resp = await _dio.post('/api/posts', data: {
        'title': title,
        'content': content,
        'type': type,
        'media_url': mediaUrl,
        'agent_id': agentId,
      });
      return Map<String, dynamic>.from(resp.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 点赞 / 取消点赞帖子
  static Future<Map<String, dynamic>> likePost(String postId) async {
    try {
      final resp = await _dio.post('/api/posts/$postId/like');
      return Map<String, dynamic>.from(resp.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 获取帖子评论列表
  static Future<List<dynamic>> getComments(String postId) async {
    try {
      final resp = await _dio.get('/api/posts/$postId/comments');
      return List<dynamic>.from(resp.data);
    } catch (_) {
      return [];
    }
  }

  /// 发表评论
  static Future<Map<String, dynamic>> createComment(
      String postId, String content) async {
    try {
      final resp = await _dio.post('/api/posts/$postId/comments', data: {
        'content': content,
      });
      return Map<String, dynamic>.from(resp.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 获取指定话题下的帖子列表
  static Future<List<dynamic>> getPostsByTopic(String topicId) async {
    try {
      final resp = await _dio.get('/api/topics/$topicId/posts');
      return List<dynamic>.from(resp.data);
    } catch (_) {
      return [];
    }
  }

  /// 探索页内容（按类型筛选：all / image / video / agent）
  static Future<List<dynamic>> getExplore({String type = 'all', int page = 1}) async {
    try {
      final resp = await _dio.get('/api/explore',
          queryParameters: {'type': type, 'page': page});
      return List<dynamic>.from(resp.data);
    } catch (_) {
      return [];
    }
  }

  // ==========================================================================
  // Agent 相关
  // ==========================================================================

  /// 获取 Agent 列表
  static Future<List<dynamic>> getAgents() async {
    try {
      final resp = await _dio.get('/api/agents');
      return List<dynamic>.from(resp.data);
    } catch (_) {
      return [];
    }
  }

  /// 获取单个 Agent 详情
  static Future<Map<String, dynamic>> getAgent(String agentId) async {
    try {
      final resp = await _dio.get('/api/agents/$agentId');
      return Map<String, dynamic>.from(resp.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 创建 Agent
  static Future<Map<String, dynamic>> createAgent({
    required String name,
    required String description,
    required String systemPrompt,
    String openingMessage = '',
    String avatar = '',
  }) async {
    try {
      final resp = await _dio.post('/api/agents', data: {
        'name': name,
        'description': description,
        'system_prompt': systemPrompt,
        'opening_message': openingMessage,
        'avatar': avatar,
      });
      return Map<String, dynamic>.from(resp.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 克隆 Agent
  static Future<Map<String, dynamic>> cloneAgent(String agentId) async {
    try {
      final resp = await _dio.post('/api/agents/$agentId/clone');
      return Map<String, dynamic>.from(resp.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 点赞 Agent
  static Future<Map<String, dynamic>> likeAgent(String agentId) async {
    try {
      final resp = await _dio.post('/api/agents/$agentId/like');
      return Map<String, dynamic>.from(resp.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 发布 Agent（公开）
  static Future<Map<String, dynamic>> publishAgent(String agentId) async {
    try {
      final resp = await _dio.post('/api/agents/$agentId/publish');
      return Map<String, dynamic>.from(resp.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 获取 Agent 排行榜
  static Future<List<dynamic>> getAgentLeaderboard(
      {int limit = 50}) async {
    try {
      final resp = await _dio.get('/api/agents/leaderboard',
          queryParameters: {'limit': limit});
      return List<dynamic>.from(resp.data);
    } catch (_) {
      return [];
    }
  }

  // ==========================================================================
  // 积分 / 商城相关
  // ==========================================================================

  /// 每日签到
  static Future<Map<String, dynamic>> checkin() async {
    try {
      final resp = await _dio.post('/api/checkin');
      return Map<String, dynamic>.from(resp.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 查询签到状态
  static Future<Map<String, dynamic>> checkinStatus() async {
    try {
      final resp = await _dio.get('/api/checkin/status');
      return Map<String, dynamic>.from(resp.data);
    } catch (_) {
      return {};
    }
  }

  /// 积分兑换（兑换商品或服务）
  static Future<Map<String, dynamic>> exchangePoints(int amount) async {
    try {
      final resp = await _dio.post('/api/shop/exchange', data: {
        'amount': amount,
      });
      return Map<String, dynamic>.from(resp.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 购买 SVIP 会员
  static Future<Map<String, dynamic>> buySvip(String plan) async {
    try {
      final resp = await _dio.post('/api/shop/svip', data: {
        'plan': plan,
      });
      return Map<String, dynamic>.from(resp.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 获取商城商品列表
  static Future<List<dynamic>> getShopItems() async {
    try {
      final resp = await _dio.get('/api/shop/items');
      return List<dynamic>.from(resp.data);
    } catch (_) {
      return [];
    }
  }

  // ==========================================================================
  // 活动相关
  // ==========================================================================

  /// 参与竞猜活动
  static Future<Map<String, dynamic>> guessActivity(
      int points, String choice) async {
    try {
      final resp = await _dio.post('/api/activity/guess', data: {
        'points': points,
        'choice': choice,
      });
      return Map<String, dynamic>.from(resp.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 查询竞猜活动状态
  static Future<Map<String, dynamic>> guessStatus() async {
    try {
      final resp = await _dio.get('/api/activity/guess/status');
      return Map<String, dynamic>.from(resp.data);
    } catch (_) {
      return {};
    }
  }

  // ==========================================================================
  // 通知相关
  // ==========================================================================

  /// 获取通知列表
  static Future<List<dynamic>> getNotifications() async {
    try {
      final resp = await _dio.get('/api/notifications');
      return List<dynamic>.from(resp.data);
    } catch (_) {
      return [];
    }
  }

  /// 标记通知为已读
  static Future<void> readNotification(String nid) async {
    try {
      await _dio.post('/api/notifications/$nid/read');
    } catch (_) {}
  }

  // ==========================================================================
  // 联网搜索相关
  // ==========================================================================

  /// 联网搜索：调用后端搜索接口，返回 SearchResult 列表
  static Future<List<SearchResult>> webSearch(String query) async {
    try {
      final resp = await _dio.get('/api/search/web', queryParameters: {
        'q': query,
      });
      final data = resp.data;
      if (data is List) {
        return SearchResult.fromList(data);
      } else if (data is Map) {
        final results = data['results'] ?? data['items'] ?? [];
        if (results is List) {
          return SearchResult.fromList(results);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// 搜索建议（输入框联想）
  static Future<List<String>> searchSuggest(String query) async {
    try {
      final resp = await _dio.get('/api/search/suggest', queryParameters: {
        'q': query,
      });
      final data = resp.data;
      if (data is List) {
        return data.map((e) => e.toString()).toList();
      } else if (data is Map) {
        final suggestions = data['suggestions'] ?? data['items'] ?? [];
        if (suggestions is List) {
          return suggestions.map((e) => e.toString()).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ==========================================================================
  // 法律相关
  // ==========================================================================

  /// 获取隐私政策文本
  static Future<String> getPrivacyPolicy() async {
    try {
      final resp = await _dio.get('/api/legal/privacy');
      if (resp.data is Map) {
        return resp.data['content']?.toString() ?? '';
      }
      return resp.data?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  /// 获取用户协议文本
  static Future<String> getUserAgreement() async {
    try {
      final resp = await _dio.get('/api/legal/agreement');
      if (resp.data is Map) {
        return resp.data['content']?.toString() ?? '';
      }
      return resp.data?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  // ==========================================================================
  // AI 工具通用接口（基于 chatStream + system prompt）
  // ==========================================================================

  /// 通用 AI 工具调用：将 systemPrompt 与 userInput 拼接后通过 SSE 流式获取，
  /// 收集全部 content 片段后返回完整文本。用于翻译、写作、代码、摘要等所有
  /// AI 工具页面。失败时抛出异常，由调用方展示错误态 + 重试。
  ///
  /// [systemPrompt]  角色/任务设定（如"你是一个专业翻译"）
  /// [userInput]     用户输入内容
  /// [model]         模型标识，默认 glm-4-flash
  static Future<String> aiToolComplete({
    required String systemPrompt,
    required String userInput,
    String model = 'glm-4-flash',
  }) async {
    final combined = systemPrompt.isEmpty
        ? userInput
        : '$systemPrompt\n\n用户输入：\n$userInput';

    final buffer = StringBuffer();
    final stream = chatStream(message: combined, model: model);

    await for (final event in stream) {
      final type = event['type'] as String?;
      if (type == 'content' || type == 'delta' || type == 'text') {
        final delta = event['content']?.toString() ??
            event['delta']?.toString() ??
            event['text']?.toString() ??
            '';
        if (delta.isNotEmpty) buffer.write(delta);
      } else if (type == 'error') {
        throw Exception(event['message']?.toString() ?? 'AI 生成失败');
      }
    }

    final result = buffer.toString().trim();
    if (result.isEmpty) {
      throw Exception('AI 返回内容为空，请稍后重试');
    }
    return result;
  }

  // ==========================================================================
  // 工具方法
  // ==========================================================================

  /// 将相对路径转换为完整媒体 URL
  /// 如果路径已经是 http(s) 开头则直接返回
  static String getMediaUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('/')) {
      return '$baseUrl$path';
    }
    return '$baseUrl/$path';
  }
}
