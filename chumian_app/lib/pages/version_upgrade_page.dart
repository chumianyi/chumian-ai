import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class VersionUpgradePage extends StatefulWidget {
  final String downloadUrl;
  final String githubUrl;
  final String latestVersion;
  final bool forceUpdate;

  const VersionUpgradePage({
    super.key,
    required this.downloadUrl,
    required this.githubUrl,
    required this.latestVersion,
    this.forceUpdate = true,
  });

  @override
  State<VersionUpgradePage> createState() => _VersionUpgradePageState();
}

class _VersionUpgradePageState extends State<VersionUpgradePage> {
  bool _downloading = false;
  double _progress = 0;
  String _status = '';
  String? _localPath;

  Future<void> _startDownload() async {
    setState(() {
      _downloading = true;
      _progress = 0;
      _status = '正在下载...';
    });

    try {
      final dir = await getExternalStorageDirectory();
      final savePath = '${dir?.path ?? '/sdcard/Download'}/chumian_ai_${widget.latestVersion}.apk';

      final dio = Dio();
      await dio.download(
        widget.downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            setState(() => _progress = received / total);
          }
        },
      );

      setState(() {
        _localPath = savePath;
        _status = '下载完成，正在安装...';
      });

      // 自动安装
      await OpenFilex.open(savePath, type: 'application/vnd.android.package-archive');
    } catch (e) {
      // 下载失败，尝试GitHub
      setState(() => _status = '下载失败，尝试备用源...');
      try {
        final dir = await getExternalStorageDirectory();
        final savePath = '${dir?.path ?? '/sdcard/Download'}/chumian_ai_${widget.latestVersion}.apk';
        final dio = Dio();
        await dio.download(
          widget.githubUrl,
          savePath,
          onReceiveProgress: (received, total) {
            if (total > 0) setState(() => _progress = received / total);
          },
        );
        setState(() {
          _localPath = savePath;
          _status = '下载完成，正在安装...';
        });
        await OpenFilex.open(savePath, type: 'application/vnd.android.package-archive');
      } catch (e2) {
        setState(() => _status = '下载失败: $e2');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !widget.forceUpdate,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.system_update, size: 40, color: Colors.blue),
                ),
                const SizedBox(height: 24),
                const Text('版本过低', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 12),
                Text(
                  '您的版本过低，请立刻升级到 v${widget.latestVersion}\n升级后才能继续使用初眠AI',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: Colors.grey, height: 1.6),
                ),
                const SizedBox(height: 40),
                if (_downloading) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('${(_progress * 100).toStringAsFixed(0)}%  $_status', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _startDownload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      ),
                      child: const Text('立即升级', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  if (!widget.forceUpdate) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('稍后再说', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
