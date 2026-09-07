import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// ============================================================================
/// DeepLinkService —— 深链接服务
///
/// 职责：
///   1. URL 解析：解析自定义 scheme 和 https 深链接
///   2. 路由跳转：将深链接映射到应用内路由
///   3. 参数提取：从 URL query 和 path 中提取参数
///   4. 分享接收：处理系统分享到应用的内容
///   5. 外部链接处理：判断链接是否应在应用内打开或外部浏览器
/// ============================================================================

/// 深链接类型
enum DeepLinkType {
  appScheme, // 自定义 scheme: chumian://
  universalLink, // 通用链接: https://chumian.app/...
  shareIntent, // 系统分享
  unknown,
}

/// 解析后的深链接
class ParsedDeepLink {
  final DeepLinkType type;
  final String rawUrl;
  final String scheme;
  final String host;
  final String path;
  final Map<String, String> queryParams;
  final String? fragment;
  final String route;
  final Map<String, dynamic> arguments;
  final DateTime receivedAt;

  ParsedDeepLink({
    required this.type,
    required this.rawUrl,
    required this.scheme,
    required this.host,
    required this.path,
    required this.queryParams,
    this.fragment,
    required this.route,
    required this.arguments,
    required this.receivedAt,
  });
}

/// 分享内容
class SharedContent {
  final String text;
  final String? title;
  final List<String> imagePaths;
  final List<String> filePaths;
  final String? sourceApp;
  final DateTime receivedAt;

  SharedContent({
    required this.text,
    this.title,
    this.imagePaths = const [],
    this.filePaths = const [],
    this.sourceApp,
    required this.receivedAt,
  });
}

class DeepLinkService {
  /// 单例实例
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  // ===== 配置 =====
  /// 应用自定义 scheme
  static const String appScheme = 'chumian';

  /// 通用链接域名
  static const List<String> universalLinkHosts = [
    'chumian.app',
    'www.chumian.app',
    'app.chumian.ai',
  ];

  /// 路由映射文件名
  static const String _routeMapFileName = 'deeplink_routes.json';

  // ===== 状态 =====
  final StreamController<ParsedDeepLink> _linkController =
      StreamController<ParsedDeepLink>.broadcast();
  final StreamController<SharedContent> _shareController =
      StreamController<SharedContent>.broadcast();
  final Map<String, String> _routeMap = {};
  ParsedDeepLink? _pendingLink;
  SharedContent? _pendingShare;
  bool _initialized = false;

  // ==========================================================================
  // 初始化
  // ==========================================================================

  /// 初始化深链接服务
  Future<void> init() async {
    if (_initialized) return;
    _setupDefaultRouteMap();
    await _loadRouteMap();
    _initialized = true;
  }

  /// 设置默认路由映射
  void _setupDefaultRouteMap() {
    _routeMap.addAll({
      '/': '/',
      '/chat': '/chat',
      '/chat/new': '/chat/new',
      '/chat/{id}': '/chat',
      '/image': '/image',
      '/image/generate': '/image/generate',
      '/writing': '/writing',
      '/search': '/search',
      '/profile': '/profile',
      '/profile/{id}': '/profile',
      '/settings': '/settings',
      '/community': '/community',
      '/community/post/{id}': '/community/post',
      '/shop': '/shop',
      '/agents': '/agents',
      '/agents/{id}': '/agents/detail',
      '/invite': '/invite',
      '/share': '/share',
    });
  }

  // ==========================================================================
  // URL 解析
  // ==========================================================================

  /// 解析 URL
  ParsedDeepLink? parseUrl(String url) {
    if (url.isEmpty) return null;

    try {
      final uri = Uri.parse(url);
      final type = _detectType(uri);

      if (type == DeepLinkType.unknown) return null;

      final route = _mapToRoute(uri);
      final arguments = _extractArguments(uri);

      return ParsedDeepLink(
        type: type,
        rawUrl: url,
        scheme: uri.scheme,
        host: uri.host,
        path: uri.path,
        queryParams: uri.queryParameters,
        fragment: uri.fragment,
        route: route,
        arguments: arguments,
        receivedAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  /// 检测链接类型
  DeepLinkType _detectType(Uri uri) {
    if (uri.scheme == appScheme) {
      return DeepLinkType.appScheme;
    }
    if (uri.scheme == 'https' &&
        universalLinkHosts.contains(uri.host)) {
      return DeepLinkType.universalLink;
    }
    return DeepLinkType.unknown;
  }

  /// 映射到应用内路由
  String _mapToRoute(Uri uri) {
    final path = uri.path.isEmpty ? '/' : uri.path;

    // 精确匹配
    if (_routeMap.containsKey(path)) {
      return _routeMap[path]!;
    }

    // 模式匹配（如 /chat/{id}）
    for (final pattern in _routeMap.keys) {
      if (_matchPattern(pattern, path)) {
        return _routeMap[pattern]!;
      }
    }

    // 默认：去掉第一段作为路由
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return '/';
    return '/${segments.first}';
  }

  /// 模式匹配（支持 {param} 占位符）
  bool _matchPattern(String pattern, String path) {
    if (!pattern.contains('{')) return false;

    final patternSegments = pattern.split('/').where((s) => s.isNotEmpty);
    final pathSegments = path.split('/').where((s) => s.isNotEmpty).toList();

    if (patternSegments.length != pathSegments.length) return false;

    final patternList = patternSegments.toList();
    for (int i = 0; i < patternList.length; i++) {
      if (patternList[i].startsWith('{') && patternList[i].endsWith('}')) {
        continue; // 占位符匹配任意值
      }
      if (patternList[i] != pathSegments[i]) return false;
    }
    return true;
  }

  /// 提取参数（从 path 占位符 + query）
  Map<String, dynamic> _extractArguments(Uri uri) {
    final args = <String, dynamic>{};

    // 从路径占位符提取
    for (final pattern in _routeMap.keys) {
      if (_matchPattern(pattern, uri.path)) {
        final patternSegments =
            pattern.split('/').where((s) => s.isNotEmpty).toList();
        final pathSegments =
            uri.path.split('/').where((s) => s.isNotEmpty).toList();
        for (int i = 0; i < patternSegments.length; i++) {
          if (patternSegments[i].startsWith('{') &&
              patternSegments[i].endsWith('}')) {
            final paramName =
                patternSegments[i].substring(1, patternSegments[i].length - 1);
            args[paramName] = pathSegments[i];
          }
        }
        break;
      }
    }

    // 从 query 提取
    uri.queryParameters.forEach((key, value) {
      args[key] = value;
    });

    return args;
  }

  // ==========================================================================
  // 链接接收与处理
  // ==========================================================================

  /// 深链接事件流
  Stream<ParsedDeepLink> get linkStream => _linkController.stream;

  /// 分享内容事件流
  Stream<SharedContent> get shareStream => _shareController.stream;

  /// 处理传入的 URL（由原生层调用）
  void handleIncomingUrl(String url) {
    final parsed = parseUrl(url);
    if (parsed != null) {
      _pendingLink = parsed;
      _linkController.add(parsed);
    }
  }

  /// 处理分享内容（由原生层调用）
  void handleSharedContent({
    required String text,
    String? title,
    List<String> imagePaths = const [],
    List<String> filePaths = const [],
    String? sourceApp,
  }) {
    final content = SharedContent(
      text: text,
      title: title,
      imagePaths: imagePaths,
      filePaths: filePaths,
      sourceApp: sourceApp,
      receivedAt: DateTime.now(),
    );
    _pendingShare = content;
    _shareController.add(content);
  }

  /// 获取并清除待处理的深链接
  ParsedDeepLink? consumePendingLink() {
    final link = _pendingLink;
    _pendingLink = null;
    return link;
  }

  /// 获取并清除待处理的分享内容
  SharedContent? consumePendingShare() {
    final share = _pendingShare;
    _pendingShare = null;
    return share;
  }

  /// 是否有待处理的深链接
  bool get hasPendingLink => _pendingLink != null;

  /// 是否有待处理的分享
  bool get hasPendingShare => _pendingShare != null;

  // ==========================================================================
  // 外部链接处理
  // ==========================================================================

  /// 判断 URL 是否应该在应用内打开
  bool shouldOpenInApp(String url) {
    final parsed = parseUrl(url);
    return parsed != null;
  }

  /// 判断 URL 是否为外部链接（需要浏览器打开）
  bool isExternalLink(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.scheme == appScheme) return false;
      if (uri.scheme == 'https' &&
          universalLinkHosts.contains(uri.host)) {
        return false;
      }
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (_) {
      return false;
    }
  }

  /// 获取外部链接的安全浏览 URL（添加 https 等）
  String? normalizeExternalUrl(String url) {
    if (url.isEmpty) return null;
    try {
      var uri = Uri.parse(url);
      if (uri.scheme.isEmpty) {
        uri = Uri.parse('https://$url');
      }
      return uri.toString();
    } catch (_) {
      return null;
    }
  }

  // ==========================================================================
  // 路由映射管理
  // ==========================================================================

  /// 添加路由映射
  void addRouteMapping(String pathPattern, String route) {
    _routeMap[pathPattern] = route;
    _persistRouteMap();
  }

  /// 移除路由映射
  bool removeRouteMapping(String pathPattern) {
    final removed = _routeMap.remove(pathPattern) != null;
    if (removed) _persistRouteMap();
    return removed;
  }

  /// 获取所有路由映射
  Map<String, String> get routeMappings => Map.unmodifiable(_routeMap);

  // ==========================================================================
  // 链接生成
  // ==========================================================================

  /// 生成应用内深链接
  String generateAppLink({
    required String path,
    Map<String, String>? params,
  }) {
    final query = params != null && params.isNotEmpty
        ? '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';
    return '$appScheme://$path$query';
  }

  /// 生成通用链接
  String generateUniversalLink({
    required String path,
    Map<String, String>? params,
  }) {
    final query = params != null && params.isNotEmpty
        ? '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';
    return 'https://${universalLinkHosts.first}$path$query';
  }

  // ==========================================================================
  // 持久化
  // ==========================================================================

  Future<Directory> _getDocDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final deeplinkDir = Directory('${dir.path}/deeplink');
    if (!deeplinkDir.existsSync()) {
      deeplinkDir.createSync(recursive: true);
    }
    return deeplinkDir;
  }

  Future<void> _persistRouteMap() async {
    try {
      final dir = await _getDocDir();
      final file = File('${dir.path}/$_routeMapFileName');
      await file.writeAsString(jsonEncode(_routeMap));
    } catch (_) {}
  }

  Future<void> _loadRouteMap() async {
    // 自定义路由映射的加载，默认映射已在初始化时设置
  }

  /// 销毁服务
  void dispose() {
    _linkController.close();
    _shareController.close();
  }
}
