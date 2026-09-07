import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// ============================================================================
/// MessageSearchService —— 消息搜索服务
///
/// 职责：
///   1. 本地索引：基于倒排索引的消息全文检索
///   2. 关键词搜索：支持多关键词 AND/OR 搜索
///   3. 正则搜索：支持正则表达式匹配
///   4. 筛选：按日期范围 / 模型 / 消息类型筛选
///   5. 搜索高亮：返回匹配片段及高亮位置
///   6. 搜索历史：记录用户搜索关键词，支持清除
/// ============================================================================

/// 搜索结果项
class SearchResultItem {
  final String messageId;
  final String conversationId;
  final String role;
  final String content;
  final DateTime timestamp;
  final String? model;
  final List<TextHighlight> highlights;
  final double score;

  SearchResultItem({
    required this.messageId,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.model,
    required this.highlights,
    required this.score,
  });
}

/// 文本高亮位置
class TextHighlight {
  final int start;
  final int end;
  final String matchedText;

  TextHighlight({
    required this.start,
    required this.end,
    required this.matchedText,
  });
}

/// 搜索筛选条件
class SearchFilter {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? model;
  final String? role;
  final String? messageType;

  SearchFilter({
    this.dateFrom,
    this.dateTo,
    this.model,
    this.role,
    this.messageType,
  });
}

/// 可搜索的消息模型
class SearchableMessage {
  final String id;
  final String conversationId;
  final String role;
  final String content;
  final DateTime timestamp;
  final String? model;
  final String? type;

  SearchableMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.model,
    this.type,
  });
}

class MessageSearchService {
  /// 单例实例
  static final MessageSearchService _instance =
      MessageSearchService._internal();
  factory MessageSearchService() => _instance;
  MessageSearchService._internal();

  // ===== 配置 =====
  /// 索引文件名
  static const String _indexFileName = 'message_index.json';

  /// 搜索历史文件名
  static const String _historyFileName = 'search_history.json';

  /// 最大搜索历史条数
  static const int _maxHistory = 50;

  /// 最大结果返回数
  static const int _maxResults = 200;

  // ===== 状态 =====
  /// 倒排索引：词 -> 消息ID列表
  final Map<String, Set<String>> _invertedIndex = {};

  /// 消息存储：ID -> 消息
  final Map<String, SearchableMessage> _messageStore = {};

  /// 搜索历史
  final List<String> _searchHistory = [];

  bool _initialized = false;
  bool _indexDirty = false;

  // ==========================================================================
  // 初始化
  // ==========================================================================

  /// 初始化搜索服务
  Future<void> init() async {
    if (_initialized) return;
    await _loadIndex();
    await _loadHistory();
    _initialized = true;
  }

  // ==========================================================================
  // 索引管理
  // ==========================================================================

  /// 添加消息到索引
  Future<void> indexMessage(SearchableMessage message) async {
    _messageStore[message.id] = message;
    final tokens = _tokenize(message.content);
    for (final token in tokens) {
      _invertedIndex.putIfAbsent(token, () => <String>{}).add(message.id);
    }
    _indexDirty = true;
  }

  /// 批量索引消息
  Future<void> indexMessages(List<SearchableMessage> messages) async {
    for (final msg in messages) {
      _messageStore[msg.id] = msg;
      final tokens = _tokenize(msg.content);
      for (final token in tokens) {
        _invertedIndex.putIfAbsent(token, () => <String>{}).add(msg.id);
      }
    }
    _indexDirty = true;
    await _persistIndex();
  }

  /// 从索引移除消息
  Future<void> removeMessage(String messageId) async {
    final msg = _messageStore.remove(messageId);
    if (msg != null) {
      final tokens = _tokenize(msg.content);
      for (final token in tokens) {
        _invertedIndex[token]?.remove(messageId);
        if (_invertedIndex[token]?.isEmpty ?? false) {
          _invertedIndex.remove(token);
        }
      }
      _indexDirty = true;
    }
  }

  /// 重建索引
  Future<void> rebuildIndex(List<SearchableMessage> messages) async {
    _invertedIndex.clear();
    _messageStore.clear();
    await indexMessages(messages);
  }

  /// 索引中的消息数
  int get indexedCount => _messageStore.length;

  // ==========================================================================
  // 搜索
  // ==========================================================================

  /// 关键词搜索
  ///
  /// [query] 搜索关键词（空格分隔表示 AND），[filter] 筛选条件
  /// [useRegex] 是否使用正则匹配
  Future<List<SearchResultItem>> search({
    required String query,
    SearchFilter? filter,
    bool useRegex = false,
    int limit = 50,
  }) async {
    if (query.trim().isEmpty) return [];

    // 记录搜索历史
    _addToHistory(query.trim());

    Set<String> candidateIds;

    if (useRegex) {
      candidateIds = _searchByRegex(query);
    } else {
      candidateIds = _searchByKeywords(query);
    }

    // 应用筛选
    if (filter != null) {
      candidateIds = _applyFilter(candidateIds, filter);
    }

    // 构建结果并排序
    final results = <SearchResultItem>[];
    for (final id in candidateIds) {
      final msg = _messageStore[id];
      if (msg == null) continue;

      final highlights = _findHighlights(msg.content, query, useRegex);
      final score = _calculateScore(msg, query, highlights);

      results.add(SearchResultItem(
        messageId: msg.id,
        conversationId: msg.conversationId,
        role: msg.role,
        content: msg.content,
        timestamp: msg.timestamp,
        model: msg.model,
        highlights: highlights,
        score: score,
      ));
    }

    // 按相关度排序，再按时间倒序
    results.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return b.timestamp.compareTo(a.timestamp);
    });

    return results.take(limit.clamp(1, _maxResults)).toList();
  }

  /// 关键词搜索（AND 逻辑）
  Set<String> _searchByKeywords(String query) {
    final keywords = query.toLowerCase().split(RegExp(r'\s+')).where(
          (k) => k.isNotEmpty,
        );

    if (keywords.isEmpty) return {};

    Set<String>? result;
    for (final keyword in keywords) {
      final matchedIds = <String>{};

      // 精确匹配倒排索引
      if (_invertedIndex.containsKey(keyword)) {
        matchedIds.addAll(_invertedIndex[keyword]!);
      }

      // 前缀匹配（搜索包含关键词的词）
      _invertedIndex.forEach((token, ids) {
        if (token.contains(keyword)) {
          matchedIds.addAll(ids);
        }
      });

      // 子串匹配（兜底）
      _messageStore.forEach((id, msg) {
        if (msg.content.toLowerCase().contains(keyword)) {
          matchedIds.add(id);
        }
      });

      if (result == null) {
        result = matchedIds;
      } else {
        result = result!.intersection(matchedIds);
      }
    }

    return result ?? {};
  }

  /// 正则搜索
  Set<String> _searchByRegex(String pattern) {
    final matchedIds = <String>{};
    try {
      final regex = RegExp(pattern, caseSensitive: false);
      _messageStore.forEach((id, msg) {
        if (regex.hasMatch(msg.content)) {
          matchedIds.add(id);
        }
      });
    } catch (_) {
      // 无效正则，返回空
    }
    return matchedIds;
  }

  /// 应用筛选条件
  Set<String> _applyFilter(Set<String> ids, SearchFilter filter) {
    return ids.where((id) {
      final msg = _messageStore[id];
      if (msg == null) return false;

      if (filter.dateFrom != null && msg.timestamp.isBefore(filter.dateFrom!)) {
        return false;
      }
      if (filter.dateTo != null && msg.timestamp.isAfter(filter.dateTo!)) {
        return false;
      }
      if (filter.model != null && msg.model != filter.model) {
        return false;
      }
      if (filter.role != null && msg.role != filter.role) {
        return false;
      }
      if (filter.messageType != null && msg.type != filter.messageType) {
        return false;
      }
      return true;
    }).toSet();
  }

  // ==========================================================================
  // 高亮与评分
  // ==========================================================================

  /// 查找文本中的高亮位置
  List<TextHighlight> _findHighlights(
    String content,
    String query,
    bool useRegex,
  ) {
    final highlights = <TextHighlight>[];
    final lowerContent = content.toLowerCase();

    if (useRegex) {
      try {
        final regex = RegExp(query, caseSensitive: false);
        for (final match in regex.allMatches(content)) {
          highlights.add(TextHighlight(
            start: match.start,
            end: match.end,
            matchedText: content.substring(match.start, match.end),
          ));
        }
      } catch (_) {}
    } else {
      final keywords = query.toLowerCase().split(RegExp(r'\s+')).where(
            (k) => k.isNotEmpty,
          );
      for (final keyword in keywords) {
        int start = 0;
        while (true) {
          final index = lowerContent.indexOf(keyword, start);
          if (index < 0) break;
          highlights.add(TextHighlight(
            start: index,
            end: index + keyword.length,
            matchedText: content.substring(index, index + keyword.length),
          ));
          start = index + keyword.length;
        }
      }
    }

    // 按位置排序并去重
    highlights.sort((a, b) => a.start.compareTo(b.start));
    return highlights;
  }

  /// 计算相关度评分
  double _calculateScore(
    SearchableMessage msg,
    String query,
    List<TextHighlight> highlights,
  ) {
    double score = 0.0;

    // 匹配次数权重
    score += highlights.length * 2.0;

    // 消息长度归一化（短消息匹配权重更高）
    final lengthFactor = 1000.0 / (msg.content.length + 100);
    score *= lengthFactor.clamp(0.1, 3.0);

    // 用户消息略高权重
    if (msg.role == 'user') score += 0.5;

    // 时间衰减（越新越高）
    final ageDays = DateTime.now().difference(msg.timestamp).inDays;
    score += (30 - ageDays.clamp(0, 30)) / 30.0;

    return score;
  }

  // ==========================================================================
  // 搜索历史
  // ==========================================================================

  /// 获取搜索历史
  List<String> get searchHistory => List.unmodifiable(_searchHistory);

  /// 添加到搜索历史
  void _addToHistory(String query) {
    _searchHistory.remove(query);
    _searchHistory.insert(0, query);
    if (_searchHistory.length > _maxHistory) {
      _searchHistory.removeLast();
    }
    _persistHistory();
  }

  /// 清除单条历史
  Future<void> removeHistory(String query) async {
    _searchHistory.remove(query);
    await _persistHistory();
  }

  /// 清除全部搜索历史
  Future<void> clearHistory() async {
    _searchHistory.clear();
    await _persistHistory();
  }

  // ==========================================================================
  // 分词
  // ==========================================================================

  /// 简单分词：按非字母数字分割，同时保留中文单字
  List<String> _tokenize(String text) {
    final tokens = <String>{};
    final lower = text.toLowerCase();

    // 英文单词和数字
    final wordRegex = RegExp(r'[a-z0-9]+');
    for (final match in wordRegex.allMatches(lower)) {
      tokens.add(match.group(0)!);
    }

    // 中文字符（单字索引）
    final chineseRegex = RegExp(r'[\u4e00-\u9fa5]');
    for (final match in chineseRegex.allMatches(lower)) {
      tokens.add(match.group(0)!);
    }

    // 中文双字组合（提升中文搜索精度）
    for (int i = 0; i < lower.length - 1; i++) {
      final pair = lower.substring(i, i + 2);
      if (RegExp(r'^[\u4e00-\u9fa5]{2}$').hasMatch(pair)) {
        tokens.add(pair);
      }
    }

    return tokens.toList();
  }

  // ==========================================================================
  // 持久化
  // ==========================================================================

  Future<Directory> _getDocDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final searchDir = Directory('${dir.path}/search');
    if (!searchDir.existsSync()) {
      searchDir.createSync(recursive: true);
    }
    return searchDir;
  }

  Future<void> _persistIndex() async {
    if (!_indexDirty) return;
    try {
      final dir = await _getDocDir();
      final file = File('${dir.path}/$_indexFileName');
      final data = {
        'messages': _messageStore.values
            .map((m) => {
                  'id': m.id,
                  'conversation_id': m.conversationId,
                  'role': m.role,
                  'content': m.content,
                  'timestamp': m.timestamp.toIso8601String(),
                  'model': m.model,
                  'type': m.type,
                })
            .toList(),
      };
      await file.writeAsString(jsonEncode(data));
      _indexDirty = false;
    } catch (_) {}
  }

  Future<void> _loadIndex() async {
    try {
      final dir = await _getDocDir();
      final file = File('${dir.path}/$_indexFileName');
      if (!file.existsSync()) return;
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final messages = (data['messages'] as List?) ?? [];
      for (final item in messages) {
        final msg = SearchableMessage(
          id: item['id']?.toString() ?? '',
          conversationId: item['conversation_id']?.toString() ?? '',
          role: item['role']?.toString() ?? 'user',
          content: item['content']?.toString() ?? '',
          timestamp: DateTime.tryParse(item['timestamp']?.toString() ?? '') ??
              DateTime.now(),
          model: item['model']?.toString(),
          type: item['type']?.toString(),
        );
        await indexMessage(msg);
      }
      _indexDirty = false;
    } catch (_) {}
  }

  Future<void> _persistHistory() async {
    try {
      final dir = await _getDocDir();
      final file = File('${dir.path}/$_historyFileName');
      await file.writeAsString(jsonEncode(_searchHistory));
    } catch (_) {}
  }

  Future<void> _loadHistory() async {
    try {
      final dir = await _getDocDir();
      final file = File('${dir.path}/$_historyFileName');
      if (!file.existsSync()) return;
      final content = await file.readAsString();
      final list = jsonDecode(content) as List;
      _searchHistory.clear();
      for (final item in list) {
        _searchHistory.add(item.toString());
      }
    } catch (_) {}
  }
}
