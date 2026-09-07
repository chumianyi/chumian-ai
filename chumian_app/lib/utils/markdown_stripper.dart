/// ============================================================================
/// MarkdownStripper —— Markdown 纯文本剥离工具（核心工具类）
///
/// 将 Markdown 格式文本转换为纯文本，剥离所有 Markdown 语法符号，
/// 保留文字内容。用于消息复制、分享、无障碍朗读等场景。
///
/// 支持的 Markdown 元素：
///   - 标题 # ## ### #### ##### ######
///   - 粗体 **text** / __text__
///   - 斜体 *text* / _text_
///   - 行内代码 `code`
///   - 代码块 ```...```（含语言标识）
///   - 链接 [text](url) → text
///   - 图片 ![alt](url) → alt
///   - 引用 > text → text
///   - 无序列表 - / * / + → text
///   - 有序列表 1. 2. → text
///   - 表格 | 分隔符 → 空格分隔单元格
///   - 水平线 --- / *** / ___ → 空行
///   - HTML 标签剥离
///   - 多余空行压缩
/// ============================================================================
class MarkdownStripper {
  /// 将 Markdown 文本转换为纯文本
  static String strip(String markdown) {
    if (markdown.isEmpty) return '';

    String text = markdown;

    // 步骤 1：处理代码块（```...```），先提取内容再移除围栏
    text = _stripCodeBlocks(text);

    // 步骤 2：移除 HTML 标签
    text = _stripHtmlTags(text);

    // 步骤 3：处理图片 ![alt](url) → alt
    text = text.replaceAllMapped(
      RegExp(r'!\[([^\]]*)\]\([^)]*\)'),
      (m) => m.group(1) ?? '',
    );

    // 步骤 4：处理链接 [text](url) → text
    text = text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]*\)'),
      (m) => m.group(1) ?? '',
    );

    // 步骤 5：处理行内代码 `code` → code
    text = text.replaceAllMapped(
      RegExp(r'`([^`]+)`'),
      (m) => m.group(1) ?? '',
    );

    // 步骤 6：处理粗体 **text** / __text__
    text = text.replaceAllMapped(
      RegExp(r'\*\*([^*]+)\*\*'),
      (m) => m.group(1) ?? '',
    );
    text = text.replaceAllMapped(
      RegExp(r'__([^_]+)__'),
      (m) => m.group(1) ?? '',
    );

    // 步骤 7：处理斜体 *text* / _text_
    // 注意：需要避免匹配到已经处理过的粗体残留
    text = text.replaceAllMapped(
      RegExp(r'(?<!\*)\*(?!\*)([^*]+)(?<!\*)\*(?!\*)'),
      (m) => m.group(1) ?? '',
    );
    text = text.replaceAllMapped(
      RegExp(r'(?<!_)_(?!_)([^_]+)(?<!_)_(?!_)'),
      (m) => m.group(1) ?? '',
    );

    // 步骤 8：按行处理块级元素
    final lines = text.split('\n');
    final result = <String>[];

    for (final line in lines) {
      String processed = line;

      // 标题：# ## ### → 纯文字
      processed = processed.replaceFirst(
        RegExp(r'^\s{0,3}#{1,6}\s+'),
        '',
      );

      // 引用：> text → text
      processed = processed.replaceFirst(
        RegExp(r'^\s{0,3}>\s?'),
        '',
      );

      // 无序列表：- / * / + → text
      processed = processed.replaceFirst(
        RegExp(r'^\s*[-*+]\s+'),
        '',
      );

      // 有序列表：1. 2. → text
      processed = processed.replaceFirst(
        RegExp(r'^\s*\d+\.\s+'),
        '',
      );

      // 水平线：--- / *** / ___ → 空行
      if (RegExp(r'^\s*([-*_])\1{2,}\s*$').hasMatch(processed)) {
        processed = '';
      }

      // 表格行：| 分隔符 → 用空格分隔单元格
      if (processed.contains('|')) {
        // 跳过分隔行（|---|---|）
        if (!RegExp(r'^\s*\|?[\s:-]+\|[\s:||-]*$').hasMatch(processed)) {
          processed = processed
              .replaceAll(RegExp(r'^\s*\|'), '')
              .replaceAll(RegExp(r'\|\s*$'), '')
              .replaceAll('|', ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
        } else {
          processed = '';
        }
      }

      result.add(processed);
    }

    text = result.join('\n');

    // 步骤 9：压缩多余空行（3个以上连续换行 → 2个）
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // 步骤 10：去除首尾空白
    text = text.trim();

    return text;
  }

  /// 剥离代码块围栏，保留代码内容
  static String _stripCodeBlocks(String text) {
    return text.replaceAllMapped(
      RegExp(r'```[\w]*\n([\s\S]*?)```', multiLine: false),
      (m) => m.group(1) ?? '',
    );
  }

  /// 剥离 HTML 标签
  static String _stripHtmlTags(String text) {
    // 移除自闭合标签 <br/> <img .../> 等
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<hr\s*/?>', caseSensitive: false), '\n');
    // 移除所有其他 HTML 标签（保留标签内文本）
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');
    // 处理 HTML 实体
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    return text;
  }

  /// 快速判断文本是否包含 Markdown 语法
  static bool containsMarkdown(String text) {
    if (text.isEmpty) return false;
    return RegExp(
      r'(#{1,6}\s|\*\*|__|`|\[.*\]\(.*\)|!\[|^\s*[-*+]\s|^\s*\d+\.\s|```|^\s*>|^\s*\|)',
      multiLine: true,
    ).hasMatch(text);
  }

  /// 统计纯文本字数（剥离 Markdown 后）
  static int countPlainWords(String markdown) {
    final plain = strip(markdown);
    if (plain.isEmpty) return 0;
    // 中文字符按字计数，英文按单词计数
    final chineseChars = RegExp(r'[\u4e00-\u9fa5]').allMatches(plain).length;
    final englishWords =
        RegExp(r'[a-zA-Z]+').allMatches(plain).length;
    return chineseChars + englishWords;
  }
}
