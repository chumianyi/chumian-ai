/// 联网搜索结果数据模型
///
/// 代表单条搜索引擎返回结果，包含标题、摘要、链接、
/// 来源站点和 favicon 图标，用于 AI 回复中的引用展示。
class SearchResult {
  /// 结果标题
  final String title;

  /// 结果摘要/片段
  final String summary;

  /// 结果链接 URL
  final String url;

  /// 来源站点名称（如 '百度百科'、'知乎'）
  final String source;

  /// 网站 favicon 图标 URL
  final String? favicon;

  SearchResult({
    this.title = '',
    this.summary = '',
    this.url = '',
    this.source = '',
    this.favicon,
  });

  /// 从 JSON 反序列化
  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ??
          json['snippet']?.toString() ??
          '',
      url: json['url']?.toString() ?? json['link']?.toString() ?? '',
      source: json['source']?.toString() ??
          json['site']?.toString() ??
          '',
      favicon: json['favicon']?.toString() ??
          json['icon']?.toString(),
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'summary': summary,
      'url': url,
      'source': source,
      'favicon': favicon,
    };
  }

  /// 从列表批量解析
  static List<SearchResult> fromList(List<dynamic> list) {
    return list
        .map((e) =>
            SearchResult.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// 是否有有效链接
  bool get hasValidUrl => url.isNotEmpty && url.startsWith('http');

  /// 展示用来源：优先 source，否则从 URL 提取域名
  String get displaySource {
    if (source.isNotEmpty) return source;
    if (url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        return uri.host.replaceFirst('www.', '');
      } catch (_) {
        return '';
      }
    }
    return '';
  }

  /// 复制并修改部分字段
  SearchResult copyWith({
    String? title,
    String? summary,
    String? url,
    String? source,
    String? favicon,
  }) {
    return SearchResult(
      title: title ?? this.title,
      summary: summary ?? this.summary,
      url: url ?? this.url,
      source: source ?? this.source,
      favicon: favicon ?? this.favicon,
    );
  }
}

/// 搜索结果列表的便捷封装
class SearchResultList {
  final List<SearchResult> results;
  final String? query;
  final DateTime? searchedAt;

  SearchResultList({
    List<SearchResult>? results,
    this.query,
    this.searchedAt,
  }) : results = results ?? [];

  factory SearchResultList.fromJson(Map<String, dynamic> json) {
    return SearchResultList(
      results: SearchResult.fromList(json['results'] as List<dynamic>? ?? []),
      query: json['query']?.toString(),
      searchedAt: json['searched_at'] != null
          ? DateTime.tryParse(json['searched_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'results': results.map((e) => e.toJson()).toList(),
      'query': query,
      'searched_at': searchedAt?.toIso8601String(),
    };
  }

  bool get isEmpty => results.isEmpty;
  bool get isNotEmpty => results.isNotEmpty;
  int get length => results.length;
}
