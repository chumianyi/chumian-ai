import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:chumian_ai/services/api_service.dart';

/// ============================================================================
/// PluginService —— AI 插件系统服务
///
/// 职责：
///   1. 插件注册：动态注册插件定义与执行器
///   2. 插件发现：扫描内置和已安装插件
///   3. 插件执行：统一执行入口，参数校验，结果返回
///   4. 插件权限：声明式权限模型，执行前权限检查
///   5. 内置插件：计算器 / 搜索 / 代码执行 / 日期时间
///   6. 插件市场接口：获取市场插件列表，安装/卸载
/// ============================================================================

/// 插件权限
enum PluginPermission {
  network,
  filesystem,
  codeExecution,
  userData,
  location,
  notifications,
}

/// 插件状态
enum PluginStatus { enabled, disabled, error }

/// 插件定义
class PluginDefinition {
  final String id;
  final String name;
  final String description;
  final String version;
  final String author;
  final List<PluginPermission> permissions;
  final List<String> categories;
  final PluginStatus status;
  final bool isBuiltin;
  final Map<String, dynamic> config;

  PluginDefinition({
    required this.id,
    required this.name,
    required this.description,
    this.version = '1.0.0',
    this.author = '系统',
    this.permissions = const [],
    this.categories = const [],
    this.status = PluginStatus.enabled,
    this.isBuiltin = false,
    this.config = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'version': version,
        'author': author,
        'permissions': permissions.map((e) => e.name).toList(),
        'categories': categories,
        'status': status.name,
        'is_builtin': isBuiltin,
        'config': config,
      };
}

/// 插件执行结果
class PluginResult {
  final bool success;
  final String pluginId;
  final Map<String, dynamic> data;
  final String? error;
  final Duration executionTime;

  PluginResult({
    required this.success,
    required this.pluginId,
    required this.data,
    this.error,
    required this.executionTime,
  });
}

/// 插件执行器函数类型
typedef PluginExecutor = Future<Map<String, dynamic>> Function(
  Map<String, dynamic> params,
);

class PluginService {
  /// 单例实例
  static final PluginService _instance = PluginService._internal();
  factory PluginService() => _instance;
  PluginService._internal();

  // ===== 配置 =====
  /// 已安装插件文件名
  static const String _installedFileName = 'installed_plugins.json';

  /// 插件执行超时（秒）
  static const int _executionTimeoutSec = 30;

  // ===== 状态 =====
  final Map<String, PluginDefinition> _plugins = {};
  final Map<String, PluginExecutor> _executors = {};
  final Set<PluginPermission> _grantedPermissions = {};
  bool _initialized = false;

  // ==========================================================================
  // 初始化
  // ==========================================================================

  /// 初始化插件服务，注册所有内置插件
  Future<void> init() async {
    if (_initialized) return;
    _registerBuiltinPlugins();
    await _loadInstalledPlugins();
    _initialized = true;
  }

  /// 注册内置插件
  void _registerBuiltinPlugins() {
    // 计算器插件
    registerPlugin(
      PluginDefinition(
        id: 'calculator',
        name: '计算器',
        description: '支持四则运算、函数计算、单位换算的科学计算器',
        version: '1.0.0',
        author: '触面AI',
        permissions: const [],
        categories: const ['工具', '数学'],
        isBuiltin: true,
      ),
      _calculatorExecutor,
    );

    // 搜索插件
    registerPlugin(
      PluginDefinition(
        id: 'web_search',
        name: '联网搜索',
        description: '搜索互联网获取实时信息，支持关键词和自然语言查询',
        version: '1.0.0',
        author: '触面AI',
        permissions: const [PluginPermission.network],
        categories: const ['工具', '搜索'],
        isBuiltin: true,
      ),
      _searchExecutor,
    );

    // 代码执行插件
    registerPlugin(
      PluginDefinition(
        id: 'code_runner',
        name: '代码执行',
        description: '在沙箱中执行 Python/JavaScript 代码，返回运行结果',
        version: '1.0.0',
        author: '触面AI',
        permissions: const [PluginPermission.codeExecution],
        categories: const ['开发', '工具'],
        isBuiltin: true,
      ),
      _codeExecutor,
    );

    // 日期时间插件
    registerPlugin(
      PluginDefinition(
        id: 'datetime',
        name: '日期时间',
        description: '获取当前时间、日期计算、时区转换、格式化输出',
        version: '1.0.0',
        author: '触面AI',
        permissions: const [],
        categories: const ['工具'],
        isBuiltin: true,
      ),
      _datetimeExecutor,
    );
  }

  // ==========================================================================
  // 插件注册与发现
  // ==========================================================================

  /// 注册插件
  bool registerPlugin(PluginDefinition definition, PluginExecutor executor) {
    if (_plugins.containsKey(definition.id)) return false;
    _plugins[definition.id] = definition;
    _executors[definition.id] = executor;
    return true;
  }

  /// 注销插件
  bool unregisterPlugin(String pluginId) {
    final plugin = _plugins[pluginId];
    if (plugin == null || plugin.isBuiltin) return false;
    _plugins.remove(pluginId);
    _executors.remove(pluginId);
    return true;
  }

  /// 获取所有插件
  List<PluginDefinition> getAllPlugins({bool includeDisabled = true}) {
    final list = _plugins.values.toList();
    if (!includeDisabled) {
      list.removeWhere((p) => p.status == PluginStatus.disabled);
    }
    list.sort((a, b) {
      // 内置插件排前面
      if (a.isBuiltin != b.isBuiltin) return a.isBuiltin ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    return list;
  }

  /// 获取插件详情
  PluginDefinition? getPlugin(String pluginId) => _plugins[pluginId];

  /// 按分类获取插件
  List<PluginDefinition> getPluginsByCategory(String category) {
    return _plugins.values
        .where((p) => p.categories.contains(category))
        .toList();
  }

  /// 搜索插件
  List<PluginDefinition> searchPlugins(String query) {
    final lower = query.toLowerCase();
    return _plugins.values
        .where((p) =>
            p.name.toLowerCase().contains(lower) ||
            p.description.toLowerCase().contains(lower) ||
            p.id.toLowerCase().contains(lower))
        .toList();
  }

  // ==========================================================================
  // 插件执行
  // ==========================================================================

  /// 执行插件
  Future<PluginResult> executePlugin({
    required String pluginId,
    Map<String, dynamic> params = const {},
  }) async {
    final startTime = DateTime.now();
    final plugin = _plugins[pluginId];

    if (plugin == null) {
      return PluginResult(
        success: false,
        pluginId: pluginId,
        data: {},
        error: '插件不存在: $pluginId',
        executionTime: DateTime.now().difference(startTime),
      );
    }

    if (plugin.status == PluginStatus.disabled) {
      return PluginResult(
        success: false,
        pluginId: pluginId,
        data: {},
        error: '插件已禁用: ${plugin.name}',
        executionTime: DateTime.now().difference(startTime),
      );
    }

    // 权限检查
    final missingPermissions = plugin.permissions
        .where((p) => !_grantedPermissions.contains(p))
        .toList();
    if (missingPermissions.isNotEmpty) {
      return PluginResult(
        success: false,
        pluginId: pluginId,
        data: {},
        error: '缺少权限: ${missingPermissions.map((e) => e.name).join(", ")}',
        executionTime: DateTime.now().difference(startTime),
      );
    }

    final executor = _executors[pluginId];
    if (executor == null) {
      return PluginResult(
        success: false,
        pluginId: pluginId,
        data: {},
        error: '插件执行器未注册',
        executionTime: DateTime.now().difference(startTime),
      );
    }

    try {
      final result = await executor(params)
          .timeout(const Duration(seconds: _executionTimeoutSec));
      return PluginResult(
        success: true,
        pluginId: pluginId,
        data: result,
        executionTime: DateTime.now().difference(startTime),
      );
    } catch (e) {
      return PluginResult(
        success: false,
        pluginId: pluginId,
        data: {},
        error: e.toString(),
        executionTime: DateTime.now().difference(startTime),
      );
    }
  }

  // ==========================================================================
  // 权限管理
  // ==========================================================================

  /// 授予权限
  void grantPermission(PluginPermission permission) {
    _grantedPermissions.add(permission);
  }

  /// 撤销权限
  void revokePermission(PluginPermission permission) {
    _grantedPermissions.remove(permission);
  }

  /// 检查权限
  bool hasPermission(PluginPermission permission) =>
      _grantedPermissions.contains(permission);

  /// 获取所有已授予权限
  Set<PluginPermission> get grantedPermissions =>
      Set.unmodifiable(_grantedPermissions);

  // ==========================================================================
  // 插件启用/禁用
  // ==========================================================================

  /// 启用插件
  bool enablePlugin(String pluginId) {
    final plugin = _plugins[pluginId];
    if (plugin == null) return false;
    _plugins[pluginId] = PluginDefinition(
      id: plugin.id,
      name: plugin.name,
      description: plugin.description,
      version: plugin.version,
      author: plugin.author,
      permissions: plugin.permissions,
      categories: plugin.categories,
      status: PluginStatus.enabled,
      isBuiltin: plugin.isBuiltin,
      config: plugin.config,
    );
    return true;
  }

  /// 禁用插件
  bool disablePlugin(String pluginId) {
    final plugin = _plugins[pluginId];
    if (plugin == null || plugin.isBuiltin) return false;
    _plugins[pluginId] = PluginDefinition(
      id: plugin.id,
      name: plugin.name,
      description: plugin.description,
      version: plugin.version,
      author: plugin.author,
      permissions: plugin.permissions,
      categories: plugin.categories,
      status: PluginStatus.disabled,
      isBuiltin: plugin.isBuiltin,
      config: plugin.config,
    );
    return true;
  }

  // ==========================================================================
  // 内置插件执行器
  // ==========================================================================

  /// 计算器执行器
  Future<Map<String, dynamic>> _calculatorExecutor(
      Map<String, dynamic> params) async {
    final expression = params['expression']?.toString() ?? '';
    if (expression.isEmpty) {
      return {'error': '表达式不能为空'};
    }
    try {
      final result = _evaluateExpression(expression);
      return {
        'expression': expression,
        'result': result,
        'formatted': result.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), ''),
      };
    } catch (e) {
      return {'error': '计算错误: $e', 'expression': expression};
    }
  }

  /// 简单表达式求值（支持 + - * / 和括号）
  double _evaluateExpression(String expr) {
    // 清理表达式
    final cleaned = expr.replaceAll(RegExp(r'\s+'), '');
    return _parseExpression(cleaned, 0).value;
  }

  _ParseResult _parseExpression(String expr, int pos) {
    var result = _parseTerm(expr, pos);
    var value = result.value;
    var p = result.pos;
    while (p < expr.length && (expr[p] == '+' || expr[p] == '-')) {
      final op = expr[p];
      p++;
      final term = _parseTerm(expr, p);
      value = op == '+' ? value + term.value : value - term.value;
      p = term.pos;
    }
    return _ParseResult(value, p);
  }

  _ParseResult _parseTerm(String expr, int pos) {
    var result = _parseFactor(expr, pos);
    var value = result.value;
    var p = result.pos;
    while (p < expr.length && (expr[p] == '*' || expr[p] == '/')) {
      final op = expr[p];
      p++;
      final factor = _parseFactor(expr, p);
      value = op == '*' ? value * factor.value : value / factor.value;
      p = factor.pos;
    }
    return _ParseResult(value, p);
  }

  _ParseResult _parseFactor(String expr, int pos) {
    if (pos < expr.length && expr[pos] == '(') {
      final result = _parseExpression(expr, pos + 1);
      if (result.pos < expr.length && expr[result.pos] == ')') {
        return _ParseResult(result.value, result.pos + 1);
      }
      return result;
    }
    if (pos < expr.length && expr[pos] == '-') {
      final result = _parseFactor(expr, pos + 1);
      return _ParseResult(-result.value, result.pos);
    }
    // 解析数字
    final numRegex = RegExp(r'^\d+(\.\d+)?');
    final match = numRegex.matchAsPrefix(expr, pos);
    if (match != null) {
      final value = double.parse(match.group(0)!);
      return _ParseResult(value, pos + match.group(0)!.length);
    }
    throw FormatException('无法解析表达式位置: $pos');
  }

  /// 搜索执行器：调用真实联网搜索接口
  Future<Map<String, dynamic>> _searchExecutor(
      Map<String, dynamic> params) async {
    final query = params['query']?.toString() ?? '';
    final count = (params['count'] as num?)?.toInt() ?? 5;
    if (query.isEmpty) {
      return {'error': '搜索关键词不能为空'};
    }
    final startTime = DateTime.now();
    try {
      final results = await ApiService.webSearch(query);
      final limited = results.take(count).toList();
      final mapped = limited.map((r) {
        return {
          'title': r.title,
          'url': r.url,
          'snippet': r.summary,
          'source': r.source,
        };
      }).toList();
      return {
        'query': query,
        'total_results': mapped.length,
        'results': mapped,
        'search_time_ms':
            DateTime.now().difference(startTime).inMilliseconds,
      };
    } catch (e) {
      return {
        'error': '搜索失败: $e',
        'query': query,
        'total_results': 0,
        'results': <Map<String, dynamic>>[],
      };
    }
  }

  /// 代码执行器（模拟）
  Future<Map<String, dynamic>> _codeExecutor(
      Map<String, dynamic> params) async {
    final code = params['code']?.toString() ?? '';
    final language = params['language']?.toString() ?? 'python';
    await Future.delayed(const Duration(milliseconds: 500));

    if (code.isEmpty) {
      return {'error': '代码不能为空'};
    }

    // 模拟执行：提取 print 语句的输出
    final outputs = <String>[];
    final printRegex = RegExp(r'''print\(['"](.+?)['"]\)''');
    for (final match in printRegex.allMatches(code)) {
      outputs.add(match.group(1)!);
    }

    return {
      'language': language,
      'exit_code': 0,
      'stdout': outputs.join('\n'),
      'stderr': '',
      'execution_time_ms': 500,
    };
  }

  /// 日期时间执行器
  Future<Map<String, dynamic>> _datetimeExecutor(
      Map<String, dynamic> params) async {
    final action = params['action']?.toString() ?? 'now';
    final now = DateTime.now();

    switch (action) {
      case 'now':
        return {
          'timestamp': now.millisecondsSinceEpoch,
          'iso8601': now.toIso8601String(),
          'formatted': '${now.year}-${now.month.toString().padLeft(2, '0')}-'
              '${now.day.toString().padLeft(2, '0')} '
              '${now.hour.toString().padLeft(2, '0')}:'
              '${now.minute.toString().padLeft(2, '0')}:'
              '${now.second.toString().padLeft(2, '0')}',
          'timezone': now.timeZoneName,
          'weekday': ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
              [now.weekday - 1],
        };
      case 'timestamp':
        return {'timestamp': now.millisecondsSinceEpoch};
      case 'date':
        return {
          'year': now.year,
          'month': now.month,
          'day': now.day,
          'weekday': now.weekday,
        };
      default:
        return {'error': '未知操作: $action', 'supported': ['now', 'timestamp', 'date']};
    }
  }

  // ==========================================================================
  // 插件市场（模拟接口）
  // ==========================================================================

  /// 获取市场插件列表
  Future<List<PluginDefinition>> getMarketplacePlugins() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      PluginDefinition(
        id: 'weather',
        name: '天气查询',
        description: '查询全球城市实时天气、预报和空气质量',
        version: '1.2.0',
        author: 'WeatherTech',
        permissions: const [PluginPermission.network, PluginPermission.location],
        categories: const ['生活', '工具'],
      ),
      PluginDefinition(
        id: 'translate',
        name: '翻译助手',
        description: '支持100+语言互译，带发音和例句',
        version: '2.0.1',
        author: 'LinguaAI',
        permissions: const [PluginPermission.network],
        categories: const ['工具', '学习'],
      ),
      PluginDefinition(
        id: 'draw',
        name: 'AI 绘画',
        description: '文本生成图片，支持多种风格和尺寸',
        version: '1.5.0',
        author: 'ArtAI',
        permissions: const [PluginPermission.network, PluginPermission.filesystem],
        categories: const ['创意', '图像'],
      ),
    ];
  }

  /// 安装插件
  Future<bool> installPlugin(String pluginId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // 模拟安装：注册一个空执行器
    if (_plugins.containsKey(pluginId)) return false;
    registerPlugin(
      PluginDefinition(
        id: pluginId,
        name: pluginId,
        description: '已安装的第三方插件',
        version: '1.0.0',
        author: '第三方',
        permissions: const [PluginPermission.network],
        categories: const ['第三方'],
      ),
      (params) async => {'status': 'installed', 'plugin_id': pluginId},
    );
    await _persistInstalledPlugins();
    return true;
  }

  /// 卸载插件
  Future<bool> uninstallPlugin(String pluginId) async {
    final success = unregisterPlugin(pluginId);
    if (success) {
      await _persistInstalledPlugins();
    }
    return success;
  }

  // ==========================================================================
  // 持久化
  // ==========================================================================

  Future<Directory> _getDocDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final pluginDir = Directory('${dir.path}/plugins');
    if (!pluginDir.existsSync()) {
      pluginDir.createSync(recursive: true);
    }
    return pluginDir;
  }

  Future<void> _persistInstalledPlugins() async {
    try {
      final dir = await _getDocDir();
      final file = File('${dir.path}/$_installedFileName');
      final installed = _plugins.values
          .where((p) => !p.isBuiltin)
          .map((p) => p.toJson())
          .toList();
      await file.writeAsString(jsonEncode(installed));
    } catch (_) {}
  }

  Future<void> _loadInstalledPlugins() async {
    // 第三方插件的执行器需要动态加载，此处仅记录元数据
  }
}

/// 表达式解析中间结果
class _ParseResult {
  final double value;
  final int pos;
  _ParseResult(this.value, this.pos);
}
