/// 版本检查与更新服务。
library;

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class VersionInfo {
  final String latestVersion;
  final int versionCode;
  final String downloadUrl;
  final String githubUrl;
  final String updateMessage;
  final bool forceUpdate;
  VersionInfo({
    required this.latestVersion,
    required this.versionCode,
    required this.downloadUrl,
    required this.githubUrl,
    required this.updateMessage,
    required this.forceUpdate,
  });
  factory VersionInfo.fromJson(Map<String, dynamic> json) => VersionInfo(
    latestVersion: json['latest_version'] ?? '',
    versionCode: json['version_code'] ?? 0,
    downloadUrl: json['download_url'] ?? '',
    githubUrl: json['github_url'] ?? '',
    updateMessage: json['update_message'] ?? '',
    forceUpdate: json['force_update'] ?? false,
  );
}

class VersionService {
  VersionService._();
  static final VersionService instance = VersionService._();
  static const String _baseUrl = 'http://103.236.99.177:24512';
  static const int _currentVersionCode = 5;

  Future<VersionInfo?> checkUpdate() async {
    try {
      final resp = await Dio().get('$_baseUrl/api/version',
        options: Options(connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10)),
      );
      if (resp.statusCode == 200) {
        final info = VersionInfo.fromJson(resp.data);
        if (info.versionCode > _currentVersionCode) return info;
      }
    } catch (_) {}
    return null;
  }

  Future<void> showUpdateDialog(BuildContext context, VersionInfo info) async {
    showDialog(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: const Color(0xFFFF6B9D).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.system_update, color: Color(0xFFFF6B9D), size: 20),
            ),
            const SizedBox(width: 10),
            Text('发现新版本 v${info.latestVersion}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(info.updateMessage, style: const TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          if (!info.forceUpdate)
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('暂不更新')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _downloadAndInstall(context, info);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B9D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('立即更新'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndInstall(BuildContext context, VersionInfo info) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          double progress = 0;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('正在下载更新...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFFF6B9D)),
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 10),
                Text('${(progress * 100).toInt()}%', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          );
        },
      ),
    );

    try {
      final dir = await getExternalStorageDirectory();
      final savePath = '${dir?.path}/chumian_ai_update.apk';
      await Dio().download(
        info.downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            // Update progress - need to find the dialog context
          }
        },
      );
      if (context.mounted) Navigator.pop(context);
      await OpenFilex.open(savePath, type: 'application/vnd.android.package-archive');
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('下载失败，请从GitHub下载')),
        );
      }
    }
  }
}
