import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:chumian_ai/services/cache_service.dart';

/// ============================================================================
/// UpgradeService —— 应用更新服务
///
/// 职责：
///   1. 版本检查：对比当前版本与服务器最新版本
///   2. 更新日志：获取版本变更说明
///   3. 下载进度：APK 下载进度回调
///   4. 强制更新：最低版本控制
///   5. 粉色更新弹窗 UI
/// ============================================================================
class UpgradeService {
  /// 单例实例
  static final UpgradeService _instance = UpgradeService._internal();
  factory UpgradeService() => _instance;
  UpgradeService._internal();

  /// Dio 实例
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));

  /// 缓存服务
  final CacheService _cache = CacheService();

  /// 版本检查 API 地址
  static const String _checkUrl =
      'http://103.236.99.177:24512/api/app/version';

  /// 缓存键
  static const String _cacheKey = 'upgrade_info';

  /// 当前版本信息
  PackageInfo? _packageInfo;

  /// 是否正在下载
  bool _isDownloading = false;

  /// 下载进度回调
  void Function(int received, int total)? onDownloadProgress;

  /// 下载完成回调
  void Function(String filePath)? onDownloadComplete;

  // ==========================================================================
  // 初始化
  // ==========================================================================

  /// 初始化：获取当前版本信息
  Future<void> init() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
    } catch (_) {
      _packageInfo = null;
    }
  }

  /// 当前版本号
  String get currentVersion => _packageInfo?.version ?? '0.0.0';

  /// 当前构建号
  String get currentBuildNumber => _packageInfo?.buildNumber ?? '0';

  // ==========================================================================
  // 版本检查
  // ==========================================================================

  /// 检查更新
  ///
  /// 返回 UpgradeInfo，null 表示检查失败
  Future<UpgradeInfo?> checkUpdate({bool useCache = true}) async {
    if (_packageInfo == null) await init();

    // 尝试从缓存读取
    if (useCache) {
      final cached = _cache.getMemory<UpgradeInfo>(_cacheKey);
      if (cached != null) return cached;
    }

    try {
      final resp = await _dio.get(_checkUrl, queryParameters: {
        'version': currentVersion,
        'build': currentBuildNumber,
        'platform': Platform.isAndroid ? 'android' : 'ios',
      });

      if (resp.statusCode == 200 && resp.data != null) {
        final data = resp.data is Map
            ? Map<String, dynamic>.from(resp.data as Map)
            : <String, dynamic>{};
        final info = UpgradeInfo.fromJson(data);
        _cache.setMemory(_cacheKey, info, ttlMs: 30 * 60 * 1000); // 缓存30分钟
        return info;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 判断是否有新版本
  Future<bool> hasUpdate() async {
    final info = await checkUpdate();
    if (info == null) return false;
    return _compareVersions(info.latestVersion, currentVersion) > 0;
  }

  /// 判断是否需要强制更新
  Future<bool> needsForceUpdate() async {
    final info = await checkUpdate();
    if (info == null) return false;
    if (!info.forceUpdate) return false;
    return _compareVersions(info.minVersion, currentVersion) > 0;
  }

  /// 版本号比较：v1 > v2 返回 1，相等返回 0，v1 < v2 返回 -1
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;

    for (int i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  // ==========================================================================
  // APK 下载
  // ==========================================================================

  /// 下载 APK（Android）
  ///
  /// [downloadUrl] 下载地址，[fileName] 保存文件名
  /// 返回下载后的文件路径，失败返回 null
  Future<String?> downloadApk({
    required String downloadUrl,
    String? fileName,
  }) async {
    if (_isDownloading) return null;
    _isDownloading = true;

    try {
      final tempDir = await getTemporaryDirectory();
      final saveFileName = fileName ??
          'chumian_ai_update_${DateTime.now().millisecondsSinceEpoch}.apk';
      final savePath = '${tempDir.path}/$saveFileName';

      await _dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          onDownloadProgress?.call(received, total);
        },
        deleteOnError: true,
      );

      _isDownloading = false;
      onDownloadComplete?.call(savePath);
      return savePath;
    } catch (_) {
      _isDownloading = false;
      return null;
    }
  }

  /// 安装 APK（Android）
  Future<bool> installApk(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath, type: 'application/vnd.android.package-archive');
      return result.type == ResultType.done;
    } catch (_) {
      return false;
    }
  }

  /// 是否正在下载
  bool get isDownloading => _isDownloading;

  // ==========================================================================
  // 粉色更新弹窗
  // ==========================================================================

  /// 展示粉色主题的更新弹窗
  ///
  /// [context] 构建上下文，[info] 更新信息
  /// [onUpdate] 点击更新回调，[onLater] 稍后提醒回调
  void showUpdateDialog({
    required BuildContext context,
    required UpgradeInfo info,
    VoidCallback? onUpdate,
    VoidCallback? onLater,
  }) {
    final isForce = info.forceUpdate &&
        _compareVersions(info.minVersion, currentVersion) > 0;

    showDialog(
      context: context,
      barrierDismissible: !isForce,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFFF0F5),
                  Colors.white,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 图标
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF69B4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.system_update,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 标题
                  Text(
                    '发现新版本 ${info.latestVersion}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 当前版本
                  Text(
                    '当前版本 $currentVersion',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 更新日志
                  if (info.changelog.isNotEmpty)
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 150),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFB6C1),
                          width: 1,
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          info.changelog,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  // 按钮
                  Row(
                    children: [
                      if (!isForce)
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              onLater?.call();
                            },
                            child: const Text(
                              '稍后提醒',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      if (!isForce) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF69B4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            onUpdate?.call();
                          },
                          child: Text(
                            isForce ? '立即更新' : '立即更新',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isForce)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        '此版本为强制更新，请更新后继续使用',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 更新信息模型
class UpgradeInfo {
  /// 最新版本号
  final String latestVersion;

  /// 最低支持版本（低于此版本需强制更新）
  final String minVersion;

  /// 是否强制更新
  final bool forceUpdate;

  /// 下载地址
  final String downloadUrl;

  /// 更新日志
  final String changelog;

  /// 文件大小（字节）
  final int fileSize;

  /// 发布时间
  final DateTime? releaseDate;

  UpgradeInfo({
    required this.latestVersion,
    this.minVersion = '0.0.0',
    this.forceUpdate = false,
    this.downloadUrl = '',
    this.changelog = '',
    this.fileSize = 0,
    this.releaseDate,
  });

  factory UpgradeInfo.fromJson(Map<String, dynamic> json) {
    return UpgradeInfo(
      latestVersion: json['latest_version']?.toString() ?? '0.0.0',
      minVersion: json['min_version']?.toString() ?? '0.0.0',
      forceUpdate: json['force_update'] == true,
      downloadUrl: json['download_url']?.toString() ?? '',
      changelog: json['changelog']?.toString() ?? '',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      releaseDate: json['release_date'] != null
          ? DateTime.tryParse(json['release_date'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latest_version': latestVersion,
      'min_version': minVersion,
      'force_update': forceUpdate,
      'download_url': downloadUrl,
      'changelog': changelog,
      'file_size': fileSize,
      'release_date': releaseDate?.toIso8601String(),
    };
  }

  /// 文件大小可读文本
  String get fileSizeText {
    if (fileSize <= 0) return '未知';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(0)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
