import 'dart:async';
import 'package:chumian_ai/models/chat_message.dart';
import 'package:chumian_ai/models/search_result.dart';
import 'package:chumian_ai/services/api_service.dart';
import 'package:chumian_ai/services/web_search_service.dart';

/// ============================================================================
/// ChatService —— 聊天业务逻辑封装层
///
/// 职责：
///   1. 消息队列管理：用户消息入队、AI 占位消息创建、流式更新
///   2. 打字机效果：通过 Stream 逐字/逐块推送 AI 回复内容
///   3. SSE 事件解析：处理 think / content / image / video_task /
///      search_results / done / error 等事件类型
///   4. 视频生成轮询：收到 video_task 后定时查询状态，完成后填充 videoUrl
///   5. 搜索结果注入：发送前若启用联网搜索，先搜索再将结果格式化注入 prompt
///
/// 该类不直接管理 UI 状态，而是通过回调/Stream 将事件传递给 Provider。
/// ============================================================================
class ChatService {
  /// 联网搜索服务实例
  final WebSearchService _webSearchService = WebSearchService();

  /// 生成唯一消息 ID（时间戳 + 随机数）
  String generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_'
        '${DateTime.now().microsecond}';
  }

  /// 生成唯一会话 ID
  String generateConversationId() {
    return 'conv_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// ========================================================================
  /// 发送消息并返回 AI 回复的事件流
  ///
  /// 流程：
  ///   1. 若 webSearchEnabled 为 true，先执行联网搜索
  ///   2. 将搜索结果格式化为上下文注入到用户消息中
  ///   3. 调用 ApiService.chatStream 建立 SSE 连接
  ///   4. 逐事件解析并通过 Stream 输出给调用方
  ///
  /// 返回的 Stream 中每个事件为 Map<String, dynamic>，包含：
  ///   - type: 事件类型（thinking / content / image / video / search / done / error）
  ///   - 以及对应事件的数据字段
  /// ========================================================================
  Stream<Map<String, dynamic>> sendMessage({
    String? conversationId,
    required String text,
    String model = 'glm-4-flash',
    String? imageUrl,
    String? agentId,
    bool webSearchEnabled = false,
  }) async* {
    String enhancedText = text;
    List<SearchResult> searchResults = [];

    // 步骤 1：联网搜索（若启用）
    if (webSearchEnabled && text.trim().isNotEmpty) {
      yield {'type': 'searching', 'query': text};
      try {
        searchResults = await _webSearchService.search(text);
        if (searchResults.isNotEmpty) {
          // 将搜索结果格式化为上下文注入 prompt
          enhancedText = _injectSearchContext(text, searchResults);
          yield {
            'type': 'search_results',
            'results': searchResults.map((e) => e.toJson()).toList(),
          };
        }
      } catch (_) {
        // 搜索失败不阻塞对话，使用原始文本
      }
    }

    // 步骤 2：建立 SSE 流式连接
    final sseStream = ApiService.chatStream(
      conversationId: conversationId,
      message: enhancedText,
      model: model,
      imageUrl: imageUrl,
      agentId: agentId,
      webSearchEnabled: webSearchEnabled,
    );

    // 步骤 3：逐事件解析并转发
    await for (final event in sseStream) {
      final type = event['type']?.toString() ?? '';

      switch (type) {
        case 'think':
          // AI 思考过程片段
          yield {
            'type': 'thinking',
            'content': event['content']?.toString() ??
                event['delta']?.toString() ??
                '',
          };
          break;

        case 'content':
        case 'text':
        case 'delta':
          // 正文内容片段（打字机效果）
          yield {
            'type': 'content',
            'content': event['content']?.toString() ??
                event['delta']?.toString() ??
                event['text']?.toString() ??
                '',
          };
          break;

        case 'image':
          // AI 生成图片
          yield {
            'type': 'image',
            'url': event['url']?.toString() ??
                event['image_url']?.toString() ??
                '',
          };
          break;

        case 'video_task':
        case 'video':
          // 视频生成任务已创建，通知调用方启动轮询
          // （视频状态轮询由调用方/Provider 负责，避免阻塞 SSE 流）
          final taskId = event['task_id']?.toString() ??
              event['video_task_id']?.toString() ??
              '';
          if (taskId.isNotEmpty) {
            yield {'type': 'video_loading', 'task_id': taskId};
          }
          break;

        case 'search_results':
          // 服务端返回的搜索结果
          final results = (event['results'] as List<dynamic>?)
                  ?.map((e) => SearchResult.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList() ??
              [];
          yield {
            'type': 'search_results',
            'results': results.map((e) => e.toJson()).toList(),
          };
          break;

        case 'done':
          // 流式生成结束
          yield {
            'type': 'done',
            'conversation_id': event['conversation_id']?.toString(),
            'tokens_used': (event['tokens_used'] as num?)?.toInt() ??
                (event['tokens'] as num?)?.toInt(),
            'model': event['model']?.toString(),
          };
          break;

        case 'error':
          // 服务端错误
          yield {
            'type': 'error',
            'message': event['message']?.toString() ?? '未知错误',
          };
          break;

        default:
          // 未知事件类型，原样转发
          yield event;
      }
    }
  }

  /// ========================================================================
  /// 将联网搜索结果格式化为上下文注入到用户消息中
  ///
  /// 格式示例：
  ///   用户问题：xxx
  ///
  ///   【联网搜索结果】
  ///   [1] 标题1 - 摘要1
  ///   [2] 标题2 - 摘要2
  ///
  ///   请结合以上搜索结果回答用户问题。
  /// ========================================================================
  String _injectSearchContext(
      String originalQuery, List<SearchResult> results) {
    final buffer = StringBuffer();
    buffer.writeln(originalQuery);
    buffer.writeln();
    buffer.writeln('【联网搜索结果】');
    for (int i = 0; i < results.length && i < 5; i++) {
      final r = results[i];
      buffer.writeln('[$i] ${r.title}');
      if (r.summary.isNotEmpty) {
        buffer.writeln('    ${r.summary}');
      }
      if (r.url.isNotEmpty) {
        buffer.writeln('    来源: ${r.displaySource}');
      }
      buffer.writeln();
    }
    buffer.writeln('请结合以上搜索结果回答用户问题，引用时标注来源编号。');
    return buffer.toString();
  }

  /// 从服务端历史消息列表解析为 ChatMessage 列表
  List<ChatMessage> parseHistoryMessages(List<dynamic> rawList) {
    return rawList.map((e) {
      final json = Map<String, dynamic>.from(e as Map);
      return ChatMessage.fromJson(json);
    }).toList();
  }

  /// 截断文本到指定长度（用于会话标题等场景）
  String truncateText(String text, {int maxLength = 30}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// 从消息内容自动生成会话标题（取首条用户消息的前 N 字）
  String generateTitleFromMessage(String content) {
    final clean = content.replaceAll('\n', ' ').trim();
    return truncateText(clean, maxLength: 20);
  }
}
