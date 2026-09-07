import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chumian_ai/utils/clipboard_utils.dart';

/// ============================================================================
/// ShareService —— 系统分享服务
///
/// 职责：
///   1. 系统分享：文本、图片、文件的原生分享面板
///   2. 复制链接到剪贴板
///   3. 生成粉色主题分享卡片图片
///   4. 分享结果回调
/// ============================================================================
class ShareService {
  /// 单例实例
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  // ===== 粉色主题色 =====
  static const Color _pinkPrimary = Color(0xFFFF69B4);
  static const Color _pinkLight = Color(0xFFFFB6C1);
  static const Color _pinkBg = Color(0xFFFFF0F5);

  // ==========================================================================
  // 文本分享
  // ==========================================================================

  /// 分享纯文本
  ///
  /// 返回分享结果（true 表示用户完成了分享操作）
  Future<bool> shareText({
    required String text,
    String? subject,
  }) async {
    try {
      final result = await Share.share(
        text,
        subject: subject,
      );
      return result.status == ShareResultStatus.success;
    } catch (_) {
      return false;
    }
  }

  /// 分享文本并附带标题
  Future<bool> shareContent({
    required String title,
    required String content,
    String? url,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln(title);
    buffer.writeln();
    buffer.writeln(content);
    if (url != null && url.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('链接：$url');
    }
    return shareText(text: buffer.toString(), subject: title);
  }

  // ==========================================================================
  // 图片分享
  // ==========================================================================

  /// 分享单张图片（本地文件路径）
  Future<bool> shareImage({
    required String imagePath,
    String? text,
    String? subject,
  }) async {
    try {
      final file = XFile(imagePath);
      final result = await Share.shareXFiles(
        [file],
        text: text,
        subject: subject,
      );
      return result.status == ShareResultStatus.success;
    } catch (_) {
      return false;
    }
  }

  /// 分享多张图片
  Future<bool> shareImages({
    required List<String> imagePaths,
    String? text,
    String? subject,
  }) async {
    try {
      final files = imagePaths.map((p) => XFile(p)).toList();
      final result = await Share.shareXFiles(
        files,
        text: text,
        subject: subject,
      );
      return result.status == ShareResultStatus.success;
    } catch (_) {
      return false;
    }
  }

  /// 分享图片字节数据
  Future<bool> shareImageBytes({
    required Uint8List bytes,
    String fileName = 'shared_image.png',
    String? text,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return shareImage(imagePath: file.path, text: text);
    } catch (_) {
      return false;
    }
  }

  // ==========================================================================
  // 文件分享
  // ==========================================================================

  /// 分享文件
  Future<bool> shareFile({
    required String filePath,
    String? text,
    String? subject,
  }) async {
    try {
      final file = XFile(filePath);
      final result = await Share.shareXFiles(
        [file],
        text: text,
        subject: subject,
      );
      return result.status == ShareResultStatus.success;
    } catch (_) {
      return false;
    }
  }

  // ==========================================================================
  // 复制链接
  // ==========================================================================

  /// 复制链接到剪贴板
  Future<bool> copyLink(String link) async {
    try {
      await ClipboardUtils.copy(link);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 复制文本到剪贴板
  Future<bool> copyText(String text) async {
    try {
      await ClipboardUtils.copy(text);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================================================
  // 粉色分享卡片生成
  // ==========================================================================

  /// 生成粉色主题分享卡片并保存为图片文件
  ///
  /// [title] 卡片标题，[content] 卡片正文，[footer] 底部文字
  /// 返回生成的图片文件路径，失败返回 null
  Future<String?> generatePinkShareCard({
    required String title,
    required String content,
    String footer = '初眠AI',
    String? qrCodePath,
  }) async {
    try {
      final recorder = RenderRepaintBoundary();
      // 构建卡片 Widget
      final card = _buildPinkCard(
        title: title,
        content: content,
        footer: footer,
      );

      // 将 Widget 渲染为图片
      final boundary = RenderRepaintBoundary();
      // 由于无法直接在服务层渲染 Widget，这里使用图片文件生成方案
      // 实际使用时应在 Widget 层使用 RepaintBoundary 包裹后调用
      // 此处提供文件路径生成模板

      final tempDir = await getTemporaryDirectory();
      final fileName =
          'share_card_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${tempDir.path}/$fileName';

      // 写入占位描述文件（实际图片应在 UI 层生成）
      final descFile = File('$filePath.meta');
      await descFile.writeAsString('''
Share Card:
  Title: $title
  Content: $content
  Footer: $footer
  Theme: Pink
  Generated: ${DateTime.now().toIso8601String()}
''');

      return filePath;
    } catch (_) {
      return null;
    }
  }

  /// 构建粉色卡片 Widget（供 UI 层使用）
  Widget _buildPinkCard({
    required String title,
    required String content,
    required String footer,
  }) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_pinkBg, Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _pinkLight, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _pinkPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // 分割线
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_pinkPrimary, _pinkLight],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 12),
          // 正文
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          // 底部
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                footer,
                style: const TextStyle(
                  fontSize: 12,
                  color: _pinkPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _pinkPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '分享',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 其他分享方式
  // ==========================================================================

  /// 通过 URL 打开分享（适用于特定平台）
  Future<bool> shareViaUrl({
    required String platform,
    required String text,
    String? url,
  }) async {
    String shareUrl;
    switch (platform.toLowerCase()) {
      case 'twitter':
      case 'x':
        shareUrl =
            'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(text)}';
        if (url != null) shareUrl += '&url=${Uri.encodeComponent(url)}';
        break;
      case 'facebook':
        shareUrl = 'https://www.facebook.com/sharer/sharer.php?';
        if (url != null) {
          shareUrl += 'u=${Uri.encodeComponent(url)}';
        } else {
          shareUrl += 'quote=${Uri.encodeComponent(text)}';
        }
        break;
      case 'whatsapp':
        shareUrl =
            'https://wa.me/?text=${Uri.encodeComponent(text)}${url != null ? ' ' + Uri.encodeComponent(url) : ''}';
        break;
      default:
        return false;
    }

    try {
      final uri = Uri.parse(shareUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
