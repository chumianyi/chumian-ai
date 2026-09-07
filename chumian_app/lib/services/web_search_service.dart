import 'dart:collection';
import 'package:chumian_ai/models/search_result.dart';
import 'package:chumian_ai/services/api_service.dart';

/// ============================================================================
/// WebSearchService —— 联网搜索服务
///
/// 职责：
///   1. 调用 ApiService.webSearch 执行联网搜索
///   2. 搜索结果缓存：相同 query 在缓存有效期内直接返回，避免重复请求
///   3. 搜索触发判断：基于关键词启发式判断用户问题是否需要联网搜索
///      （含"最新/今天/新闻/价格/怎么/哪里/是什么/为什么/如何"等触发词）
///   4. 搜索结果格式化：将 SearchResult 列表转为模型可理解的文本上下文
/// ============================================================================
class WebSearchService {
  /// 搜索结果缓存（query → 结果列表 + 缓存时间）
  final LinkedHashMap<String, _CacheEntry> _cache =
      LinkedHashMap<String, _CacheEntry>();

  /// 缓存最大条目数（LRU 淘汰）
  static const int _maxCacheSize = 50;

  /// 缓存有效期（5 分钟）
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// 触发联网搜索的关键词列表
  static const List<String> _searchTriggerKeywords = [
    // 时效性
    '最新', '今天', '今日', '昨天', '近日', '当前', '现在', '近期',
    '新闻', '资讯', '动态', '热点', '热搜', '事件',
    // 价格/交易
    '价格', '多少钱', '售价', '报价', '行情', '股价', '汇率', '房价',
    '油价', '金价', '币价',
    // 疑问词
    '怎么', '怎样', '如何', '哪里', '哪个', '哪些', '什么', '为啥',
    '为什么', '咋', '吗', '呢', '吧',
    // 知识查询
    '是什么', '定义', '概念', '区别', '对比', '比较', '排名', '排行',
    '排行榜', '推荐', '攻略', '教程', '方法', '步骤',
    // 地点/机构
    '地址', '位置', '在哪', '电话', '联系方式', '官网',
    // 人物/作品
    '是谁', '简介', '生平', '作品', '演员', '导演', '作者',
  ];

  /// 不需要联网搜索的关键词（数学计算、纯创作等）
  static const List<String> _searchAvoidKeywords = [
    '写一首', '写一篇', '写个', '编一个', '编个', '创作',
    '翻译成', '翻译一下', '帮我写', '续写',
    '计算', '算一下', '等于', '解方程',
    '代码', '程序', '函数', 'bug', '报错',
  ];

  /// ========================================================================
  /// 执行联网搜索
  ///
  /// 先查缓存，命中且未过期则直接返回；否则调用后端搜索接口，
  /// 结果写入缓存后返回。
  /// ========================================================================
  Future<List<SearchResult>> search(String query) async {
    final normalizedQuery = _normalizeQuery(query);
    if (normalizedQuery.isEmpty) return [];

    // 查缓存
    final cached = _cache[normalizedQuery];
    if (cached != null && !cached.isExpired) {
      return cached.results;
    }

    // 调用后端搜索
    final results = await ApiService.webSearch(normalizedQuery);

    // 写入缓存
    _cache[normalizedQuery] = _CacheEntry(
      results: results,
      cachedAt: DateTime.now(),
    );

    // LRU 淘汰：超出最大缓存时移除最旧条目
    while (_cache.length > _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }

    return results;
  }

  /// ========================================================================
  /// 判断给定文本是否需要联网搜索（启发式）
  ///
  /// 规则：
  ///   1. 若包含"不需要搜索"关键词，返回 false
  ///   2. 若包含"触发搜索"关键词，返回 true
  ///   3. 若文本以疑问词结尾且长度适中，返回 true
  ///   4. 否则返回 false
  /// ========================================================================
  bool shouldSearch(String text) {
    final normalized = text.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    // 规则 1：避免搜索的关键词优先判断
    for (final keyword in _searchAvoidKeywords) {
      if (normalized.contains(keyword.toLowerCase())) {
        return false;
      }
    }

    // 规则 2：触发搜索的关键词
    for (final keyword in _searchTriggerKeywords) {
      if (normalized.contains(keyword.toLowerCase())) {
        return true;
      }
    }

    // 规则 3：以问号结尾的疑问句
    if (normalized.endsWith('?') || normalized.endsWith('？')) {
      // 排除纯数学/代码问题
      if (!_isMathOrCodeQuestion(normalized)) {
        return true;
      }
    }

    return false;
  }

  /// 判断是否为数学或编程问题（这类不需要联网）
  bool _isMathOrCodeQuestion(String text) {
    final mathPatterns = [
      RegExp(r'\d+\s*[+\-*/]\s*\d+'),
      RegExp(r'等于多少'),
      RegExp(r'解方程'),
      RegExp(r'求.*值'),
      RegExp(r'积分|导数|微分|矩阵'),
    ];
    final codePatterns = [
      RegExp(r'代码|函数|类|变量|报错|error|exception|bug'),
      RegExp(r'python|java|javascript|flutter|dart|cpp|c\+\+|go|rust'),
    ];
    for (final p in mathPatterns) {
      if (p.hasMatch(text)) return true;
    }
    for (final p in codePatterns) {
      if (p.hasMatch(text)) return true;
    }
    return false;
  }

  /// ========================================================================
  /// 获取搜索建议（输入框联想）
  /// ========================================================================
  Future<List<String>> suggest(String query) async {
    if (query.trim().isEmpty) return [];
    return ApiService.searchSuggest(query.trim());
  }

  /// ========================================================================
  /// 将搜索结果格式化为模型可理解的文本上下文
  ///
  /// 用于在发送给 AI 之前，将搜索结果注入到 prompt 中。
  /// ========================================================================
  String formatResultsForPrompt(List<SearchResult> results,
      {int maxResults = 5}) {
    if (results.isEmpty) return '';
    final buffer = StringBuffer();
    buffer.writeln('【联网搜索结果】');
    final count = results.length < maxResults ? results.length : maxResults;
    for (int i = 0; i < count; i++) {
      final r = results[i];
      buffer.writeln('[$i] ${r.title}');
      if (r.summary.isNotEmpty) {
        buffer.writeln('    ${r.summary}');
      }
      if (r.displaySource.isNotEmpty) {
        buffer.writeln('    来源: ${r.displaySource}');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  /// 规范化搜索 query：去除首尾空白、压缩连续空格
  String _normalizeQuery(String query) {
    return query.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// 清空搜索缓存
  void clearCache() {
    _cache.clear();
  }

  /// 获取缓存条目数
  int get cacheSize => _cache.length;
}

/// 搜索缓存条目
class _CacheEntry {
  final List<SearchResult> results;
  final DateTime cachedAt;

  _CacheEntry({
    required this.results,
    required this.cachedAt,
  });

  /// 是否已过期
  bool get isExpired =>
      DateTime.now().difference(cachedAt) > WebSearchService._cacheDuration;
}
