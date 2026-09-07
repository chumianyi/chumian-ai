import 'package:flutter/services.dart';
import 'package:chumian_ai/utils/markdown_stripper.dart';

/// ============================================================================
/// ClipboardUtils —— 剪贴板工具类
///
/// 提供复制纯文本到剪贴板的功能，自动剥离 Markdown 格式符号，
/// 并可配合 Flutter 的 SnackBar / Toast 显示复制成功提示。
/// ============================================================================
class ClipboardUtils {
  /// 复制纯文本到剪贴板
  ///
  /// 自动调用 MarkdownStripper.strip() 剥离所有 Markdown 语法符号，
  /// 确保复制到剪贴板的是干净的纯文本。
  ///
  /// 返回 true 表示复制成功，false 表示文本为空。
  static Future<bool> copyText(String text) async {
    if (text.isEmpty) return false;
    final plainText = MarkdownStripper.strip(text);
    await Clipboard.setData(ClipboardData(text: plainText));
    return true;
  }

  /// 复制原始文本（不剥离 Markdown）到剪贴板
  ///
  /// 用于需要保留 Markdown 格式的场景，如分享到支持 Markdown 的平台。
  static Future<bool> copyRaw(String text) async {
    if (text.isEmpty) return false;
    await Clipboard.setData(ClipboardData(text: text));
    return true;
  }

  /// 从剪贴板读取文本
  static Future<String?> paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  /// 判断剪贴板是否有文本内容
  static Future<bool> hasText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text != null && data!.text!.isNotEmpty;
  }

  /// 复制消息内容（带复制成功的回调）
  ///
  /// [onSuccess] 复制成功回调，可用于显示 SnackBar 提示
  /// [onError] 复制失败回调
  static Future<void> copyMessage({
    required String content,
    Function? onSuccess,
    Function(String)? onError,
  }) async {
    try {
      final success = await copyText(content);
      if (success) {
        onSuccess?.call();
      } else {
        onError?.call('内容为空，无法复制');
      }
    } catch (e) {
      onError?.call('复制失败：$e');
    }
  }

  /// 复制并返回提示文本（用于直接显示在 UI 上）
  static Future<String> copyWithFeedback(String text) async {
    if (text.isEmpty) return '内容为空';
    try {
      await copyText(text);
      return '已复制到剪贴板';
    } catch (e) {
      return '复制失败';
    }
  }
}
