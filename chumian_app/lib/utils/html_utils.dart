/// ============================================================================
/// HtmlUtils —— HTML 处理工具
///
/// 功能：
///   1. HTML 转纯文本：剥离所有标签，保留文本内容
///   2. HTML 转 Markdown：将常见 HTML 标签转换为 Markdown 语法
///   3. 标签剥离：移除指定标签或所有标签
///   4. 实体解码：解码 HTML 实体（&amp; &lt; &nbsp; 等）
///   5. 安全过滤：移除危险标签和属性（XSS 防护）
/// ============================================================================
class HtmlUtils {
  // ===== HTML 实体映射表 =====
  static const Map<String, String> _namedEntities = {
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&apos;': "'",
    '&nbsp;': ' ',
    '&copy;': '©',
    '&reg;': '®',
    '&trade;': '™',
    '&hellip;': '…',
    '&mdash;': '—',
    '&ndash;': '–',
    '&bull;': '•',
    '&middot;': '·',
    '&lsquo;': "'",
    '&rsquo;': "'",
    '&ldquo;': '"',
    '&rdquo;': '"',
    '&laquo;': '«',
    '&raquo;': '»',
    '&brvbar;': '¦',
    '&sect;': '§',
    '&para;': '¶',
    '&deg;': '°',
    '&plusmn;': '±',
    '&times;': '×',
    '&divide;': '÷',
    '&micro;': 'µ',
    '&euro;': '€',
    '&pound;': '£',
    '&yen;': '¥',
    '&cent;': '¢',
    '&agrave;': 'à',
    '&aacute;': 'á',
    '&acirc;': 'â',
    '&atilde;': 'ã',
    '&auml;': 'ä',
    '&aring;': 'å',
    '&egrave;': 'è',
    '&eacute;': 'é',
    '&ecirc;': 'ê',
    '&euml;': 'ë',
    '&igrave;': 'ì',
    '&iacute;': 'í',
    '&icirc;': 'î',
    '&iuml;': 'ï',
    '&ograve;': 'ò',
    '&oacute;': 'ó',
    '&ocirc;': 'ô',
    '&otilde;': 'õ',
    '&ouml;': 'ö',
    '&ugrave;': 'ù',
    '&uacute;': 'ú',
    '&ucirc;': 'û',
    '&uuml;': 'ü',
  };

  // ===== 危险标签列表（XSS 防护）=====
  static const Set<String> _dangerousTags = {
    'script',
    'style',
    'iframe',
    'object',
    'embed',
    'form',
    'input',
    'button',
    'textarea',
    'select',
    'option',
    'link',
    'meta',
    'base',
  };

  // ===== 危险属性列表 =====
  static const Set<String> _dangerousAttributes = {
    'onclick',
    'onload',
    'onerror',
    'onmouseover',
    'onmouseout',
    'onfocus',
    'onblur',
    'onchange',
    'onsubmit',
    'onreset',
    'onselect',
    'onkeydown',
    'onkeypress',
    'onkeyup',
    'onmousedown',
    'onmousemove',
    'onmouseup',
    'ondblclick',
    'oncontextmenu',
    'onwheel',
    'ondrag',
    'ondrop',
    'oncopy',
    'oncut',
    'onpaste',
    'onabort',
    'oncanplay',
    'onended',
    'onpause',
    'onplay',
    'onplaying',
    'onprogress',
    'onratechange',
    'onseeked',
    'onseeking',
    'onstalled',
    'onsuspend',
    'ontimeupdate',
    'onvolumechange',
    'onwaiting',
  };

  // ==========================================================================
  // HTML 转纯文本
  // ==========================================================================

  /// 将 HTML 转换为纯文本
  ///
  /// [preserveLineBreaks] 是否保留换行（p/br/div 转换为换行）
  /// [preserveLinks] 是否保留链接文本和 URL
  static String toPlainText(
    String html, {
    bool preserveLineBreaks = true,
    bool preserveLinks = false,
  }) {
    if (html.isEmpty) return '';

    var result = html;

    // 先解码实体
    result = decodeEntities(result);

    // 移除 script 和 style 标签及其内容
    result = result.replaceAll(
      RegExp(r'<(script|style)[^>]*>.*?</\1>', caseSensitive: false, dotAll: true),
      '',
    );

    // 保留链接
    if (preserveLinks) {
      result = result.replaceAllMapped(
        RegExp(r'<a\s+[^>]*href=["\']([^"\']*)["\'][^>]*>(.*?)</a>',
            caseSensitive: false, dotAll: true),
        (match) => '${match.group(2)} (${match.group(1)})',
      );
    }

    // 块级标签转换为换行
    if (preserveLineBreaks) {
      result = result.replaceAll(
        RegExp(r'<\s*/\s*(p|div|br|li|h[1-6]|tr)\s*/?>',
            caseSensitive: false),
        '\n',
      );
      result = result.replaceAll(
        RegExp(r'<\s*br\s*/?>', caseSensitive: false),
        '\n',
      );
    }

    // 移除所有剩余标签
    result = result.replaceAll(RegExp(r'<[^>]*>'), '');

    // 清理多余空白
    result = result.replaceAll(RegExp(r'[ \t]+'), ' ');
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    result = result.trim();

    return result;
  }

  // ==========================================================================
  // HTML 转 Markdown
  // ==========================================================================

  /// 将 HTML 转换为 Markdown
  static String toMarkdown(String html) {
    if (html.isEmpty) return '';

    var result = html;

    // 解码实体
    result = decodeEntities(result);

    // 移除 script/style
    result = result.replaceAll(
      RegExp(r'<(script|style)[^>]*>.*?</\1>', caseSensitive: false, dotAll: true),
      '',
    );

    // 标题
    for (int i = 6; i >= 1; i--) {
      result = result.replaceAllMapped(
        RegExp('<h$i[^>]*>(.*?)</h$i>', caseSensitive: false, dotAll: true),
        (match) => '${'#' * i} ${_inlineToMarkdown(match.group(1)!)}\n\n',
      );
    }

    // 粗体
    result = result.replaceAllMapped(
      RegExp(r'<(strong|b)[^>]*>(.*?)</\1>', caseSensitive: false, dotAll: true),
      (match) => '**${_inlineToMarkdown(match.group(2)!)}**',
    );

    // 斜体
    result = result.replaceAllMapped(
      RegExp(r'<(em|i)[^>]*>(.*?)</\1>', caseSensitive: false, dotAll: true),
      (match) => '*${_inlineToMarkdown(match.group(2)!)}*',
    );

    // 删除线
    result = result.replaceAllMapped(
      RegExp(r'<(del|s|strike)[^>]*>(.*?)</\1>',
          caseSensitive: false, dotAll: true),
      (match) => '~~${_inlineToMarkdown(match.group(2)!)}~~',
    );

    // 行内代码
    result = result.replaceAllMapped(
      RegExp(r'<code[^>]*>(.*?)</code>', caseSensitive: false, dotAll: true),
      (match) => '`${match.group(1)!}`',
    );

    // 代码块
    result = result.replaceAllMapped(
      RegExp(r'<pre[^>]*>(.*?)</pre>', caseSensitive: false, dotAll: true),
      (match) => '```\n${match.group(1)!.trim()}\n```\n\n',
    );

    // 链接
    result = result.replaceAllMapped(
      RegExp(r'<a\s+[^>]*href=["\']([^"\']*)["\'][^>]*>(.*?)</a>',
          caseSensitive: false, dotAll: true),
      (match) => '[${_inlineToMarkdown(match.group(2)!)}](${match.group(1)!})',
    );

    // 图片
    result = result.replaceAllMapped(
      RegExp(r'<img\s+[^>]*src=["\']([^"\']*)["\'][^>]*alt=["\']([^"\']*)["\'][^>]*/?>',
          caseSensitive: false),
      (match) => '![${match.group(2)!}](${match.group(1)!})',
    );
    // 无 alt 的图片
    result = result.replaceAllMapped(
      RegExp(r'<img\s+[^>]*src=["\']([^"\']*)["\'][^>]*/?>',
          caseSensitive: false),
      (match) => '![图片](${match.group(1)!})',
    );

    // 引用
    result = result.replaceAllMapped(
      RegExp(r'<blockquote[^>]*>(.*?)</blockquote>',
          caseSensitive: false, dotAll: true),
      (match) {
        final text = toPlainText(match.group(1)!);
        return text.split('\n').map((l) => '> $l').join('\n') + '\n\n';
      },
    );

    // 无序列表
    result = result.replaceAllMapped(
      RegExp(r'<ul[^>]*>(.*?)</ul>', caseSensitive: false, dotAll: true),
      (match) {
        final items = RegExp(r'<li[^>]*>(.*?)</li>',
                caseSensitive: false, dotAll: true)
            .allMatches(match.group(1)!)
            .map((m) => '- ${_inlineToMarkdown(m.group(1)!)}')
            .join('\n');
        return '$items\n\n';
      },
    );

    // 有序列表
    result = result.replaceAllMapped(
      RegExp(r'<ol[^>]*>(.*?)</ol>', caseSensitive: false, dotAll: true),
      (match) {
        var index = 0;
        final items = RegExp(r'<li[^>]*>(.*?)</li>',
                caseSensitive: false, dotAll: true)
            .allMatches(match.group(1)!)
            .map((m) => '${++index}. ${_inlineToMarkdown(m.group(1)!)}')
            .join('\n');
        return '$items\n\n';
      },
    );

    // 段落
    result = result.replaceAllMapped(
      RegExp(r'<p[^>]*>(.*?)</p>', caseSensitive: false, dotAll: true),
      (match) => '${_inlineToMarkdown(match.group(1)!)}\n\n',
    );

    // 换行
    result = result.replaceAll(RegExp(r'<\s*br\s*/?>', caseSensitive: false), '\n');

    // 水平线
    result = result.replaceAll(
      RegExp(r'<\s*hr\s*/?>', caseSensitive: false),
      '\n---\n\n',
    );

    // 移除剩余标签
    result = result.replaceAll(RegExp(r'<[^>]*>'), '');

    // 清理
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    result = result.trim();

    return result;
  }

  /// 内联元素转 Markdown（用于嵌套在其他元素中时）
  static String _inlineToMarkdown(String html) {
    var result = html;
    result = result.replaceAllMapped(
      RegExp(r'<(strong|b)[^>]*>(.*?)</\1>', caseSensitive: false, dotAll: true),
      (m) => '**${m.group(2)!}**',
    );
    result = result.replaceAllMapped(
      RegExp(r'<(em|i)[^>]*>(.*?)</\1>', caseSensitive: false, dotAll: true),
      (m) => '*${m.group(2)!}*',
    );
    result = result.replaceAllMapped(
      RegExp(r'<code[^>]*>(.*?)</code>', caseSensitive: false, dotAll: true),
      (m) => '`${m.group(1)!}`',
    );
    result = result.replaceAll(RegExp(r'<[^>]*>'), '');
    return result.trim();
  }

  // ==========================================================================
  // 标签剥离
  // ==========================================================================

  /// 移除所有 HTML 标签
  static String stripTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// 移除指定标签（保留内容）
  static String stripTag(String html, String tagName) {
    return html.replaceAll(
      RegExp('<$tagName[^>]*>|</$tagName>', caseSensitive: false),
      '',
    );
  }

  /// 移除指定标签及其内容
  static String removeTagWithContent(String html, String tagName) {
    return html.replaceAll(
      RegExp('<$tagName[^>]*>.*?</$tagName>',
          caseSensitive: false, dotAll: true),
      '',
    );
  }

  // ==========================================================================
  // 实体解码
  // ==========================================================================

  /// 解码 HTML 实体
  static String decodeEntities(String html) {
    if (html.isEmpty) return html;

    var result = html;

    // 命名实体
    _namedEntities.forEach((entity, char) {
      result = result.replaceAll(entity, char);
    });

    // 数字实体（十进制）
    result = result.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (match) {
        final code = int.tryParse(match.group(1)!);
        if (code != null && code >= 0 && code <= 0x10FFFF) {
          return String.fromCharCode(code);
        }
        return match.group(0)!;
      },
    );

    // 数字实体（十六进制）
    result = result.replaceAllMapped(
      RegExp(r'&#x([0-9a-fA-F]+);'),
      (match) {
        final code = int.tryParse(match.group(1)!, radix: 16);
        if (code != null && code >= 0 && code <= 0x10FFFF) {
          return String.fromCharCode(code);
        }
        return match.group(0)!;
      },
    );

    return result;
  }

  /// 编码 HTML 实体（将特殊字符转换为实体）
  static String encodeEntities(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  // ==========================================================================
  // 安全过滤
  // ==========================================================================

  /// 安全过滤 HTML，移除危险标签和属性
  static String sanitize(String html) {
    if (html.isEmpty) return '';

    var result = html;

    // 移除危险标签及其内容
    for (final tag in _dangerousTags) {
      result = result.replaceAll(
        RegExp('<$tag[^>]*>.*?</$tag>',
            caseSensitive: false, dotAll: true),
        '',
      );
      // 自闭合危险标签
      result = result.replaceAll(
        RegExp('<$tag[^>]*/?>', caseSensitive: false),
        '',
      );
    }

    // 移除危险属性（on* 事件处理器等）
    result = result.replaceAllMapped(
      RegExp(r'<[^>]+>', caseSensitive: false),
      (match) {
        var tag = match.group(0)!;
        for (final attr in _dangerousAttributes) {
          tag = tag.replaceAll(
            RegExp('$attr\\s*=\\s*"[^"]*"', caseSensitive: false),
            '',
          );
          tag = tag.replaceAll(
            RegExp("$attr\\s*=\\s*'[^']*'", caseSensitive: false),
            '',
          );
        }
        // 移除 javascript: 协议
        tag = tag.replaceAll(
          RegExp(r'''(href|src)\s*=\s*["']javascript:''',
              caseSensitive: false),
          '${1}="#"',
        );
        return tag;
      },
    );

    return result;
  }

  /// 检查 HTML 是否包含危险内容
  static bool containsDangerousContent(String html) {
    final lower = html.toLowerCase();
    for (final tag in _dangerousTags) {
      if (lower.contains('<$tag')) return true;
    }
    for (final attr in _dangerousAttributes) {
      if (lower.contains('$attr=')) return true;
    }
    if (lower.contains('javascript:')) return true;
    return false;
  }

  // ==========================================================================
  // 工具方法
  // ==========================================================================

  /// 提取所有链接
  static List<Map<String, String>> extractLinks(String html) {
    final links = <Map<String, String>>[];
    final regex = RegExp(
      r'<a\s+[^>]*href=["\']([^"\']*)["\'][^>]*>(.*?)</a>',
      caseSensitive: false,
      dotAll: true,
    );
    for (final match in regex.allMatches(html)) {
      links.add({
        'url': match.group(1) ?? '',
        'text': stripTags(match.group(2) ?? '').trim(),
      });
    }
    return links;
  }

  /// 提取所有图片 URL
  static List<String> extractImages(String html) {
    final images = <String>[];
    final regex = RegExp(
      r'<img\s+[^>]*src=["\']([^"\']*)["\']',
      caseSensitive: false,
    );
    for (final match in regex.allMatches(html)) {
      final url = match.group(1);
      if (url != null && url.isNotEmpty) {
        images.add(url);
      }
    }
    return images;
  }

  /// 估算 HTML 文本长度（剥离标签后）
  static int estimateTextLength(String html) {
    return toPlainText(html).length;
  }
}
