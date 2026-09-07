/// ============================================================================
/// MarkdownBuilder —— Markdown 文本构建器
///
/// 提供链式调用 API，用于程序化生成 Markdown 文档。
/// 支持标题、粗体、斜体、代码、链接、列表、表格、引用、图片等元素。
/// ============================================================================
class MarkdownBuilder {
  final StringBuffer _buffer = StringBuffer();

  // ==========================================================================
  // 标题
  // ==========================================================================

  /// 添加一级标题
  MarkdownBuilder h1(String text) {
    _buffer.writeln('# $text');
    _buffer.writeln();
    return this;
  }

  /// 添加二级标题
  MarkdownBuilder h2(String text) {
    _buffer.writeln('## $text');
    _buffer.writeln();
    return this;
  }

  /// 添加三级标题
  MarkdownBuilder h3(String text) {
    _buffer.writeln('### $text');
    _buffer.writeln();
    return this;
  }

  /// 添加四级标题
  MarkdownBuilder h4(String text) {
    _buffer.writeln('#### $text');
    _buffer.writeln();
    return this;
  }

  /// 添加五级标题
  MarkdownBuilder h5(String text) {
    _buffer.writeln('##### $text');
    _buffer.writeln();
    return this;
  }

  /// 添加六级标题
  MarkdownBuilder h6(String text) {
    _buffer.writeln('###### $text');
    _buffer.writeln();
    return this;
  }

  /// 通用标题（指定级别 1-6）
  MarkdownBuilder heading(String text, int level) {
    final l = level.clamp(1, 6);
    _buffer.writeln('${'#' * l} $text');
    _buffer.writeln();
    return this;
  }

  // ==========================================================================
  // 文本格式
  // ==========================================================================

  /// 添加普通段落
  MarkdownBuilder paragraph(String text) {
    _buffer.writeln(text);
    _buffer.writeln();
    return this;
  }

  /// 添加粗体文本
  MarkdownBuilder bold(String text) {
    _buffer.write('**$text**');
    return this;
  }

  /// 添加斜体文本
  MarkdownBuilder italic(String text) {
    _buffer.write('*$text*');
    return this;
  }

  /// 添加粗斜体文本
  MarkdownBuilder boldItalic(String text) {
    _buffer.write('***$text***');
    return this;
  }

  /// 添加删除线文本
  MarkdownBuilder strikethrough(String text) {
    _buffer.write('~~$text~~');
    return this;
  }

  /// 添加行内代码
  MarkdownBuilder inlineCode(String code) {
    _buffer.write('`$code`');
    return this;
  }

  /// 添加换行
  MarkdownBuilder newline() {
    _buffer.writeln();
    return this;
  }

  /// 添加水平分割线
  MarkdownBuilder hr() {
    _buffer.writeln('---');
    _buffer.writeln();
    return this;
  }

  // ==========================================================================
  // 链接与图片
  // ==========================================================================

  /// 添加链接
  MarkdownBuilder link(String text, String url, {String? title}) {
    if (title != null) {
      _buffer.write('[$text]($url "$title")');
    } else {
      _buffer.write('[$text]($url)');
    }
    return this;
  }

  /// 添加图片
  MarkdownBuilder image(String alt, String url, {String? title}) {
    if (title != null) {
      _buffer.writeln('![$alt]($url "$title")');
    } else {
      _buffer.writeln('![$alt]($url)');
    }
    _buffer.writeln();
    return this;
  }

  // ==========================================================================
  // 代码块
  // ==========================================================================

  /// 添加代码块
  MarkdownBuilder codeBlock(String code, {String language = ''}) {
    _buffer.writeln('```$language');
    _buffer.writeln(code);
    _buffer.writeln('```');
    _buffer.writeln();
    return this;
  }

  // ==========================================================================
  // 引用
  // ==========================================================================

  /// 添加引用块
  MarkdownBuilder quote(String text) {
    final lines = text.split('\n');
    for (final line in lines) {
      _buffer.writeln('> $line');
    }
    _buffer.writeln();
    return this;
  }

  /// 添加嵌套引用
  MarkdownBuilder nestedQuote(String text, {int level = 2}) {
    final prefix = '>' * level;
    final lines = text.split('\n');
    for (final line in lines) {
      _buffer.writeln('$prefix $line');
    }
    _buffer.writeln();
    return this;
  }

  // ==========================================================================
  // 列表
  // ==========================================================================

  /// 添加无序列表
  MarkdownBuilder bulletList(List<String> items) {
    for (final item in items) {
      _buffer.writeln('- $item');
    }
    _buffer.writeln();
    return this;
  }

  /// 添加有序列表
  MarkdownBuilder orderedList(List<String> items) {
    for (int i = 0; i < items.length; i++) {
      _buffer.writeln('${i + 1}. ${items[i]}');
    }
    _buffer.writeln();
    return this;
  }

  /// 添加任务列表
  MarkdownBuilder taskList(List<MapEntry<String, bool>> tasks) {
    for (final task in tasks) {
      final checked = task.value ? 'x' : ' ';
      _buffer.writeln('- [$checked] ${task.key}');
    }
    _buffer.writeln();
    return this;
  }

  /// 添加嵌套无序列表
  MarkdownBuilder nestedBulletList(Map<String, List<String>> items) {
    items.forEach((parent, children) {
      _buffer.writeln('- $parent');
      for (final child in children) {
        _buffer.writeln('  - $child');
      }
    });
    _buffer.writeln();
    return this;
  }

  // ==========================================================================
  // 表格
  // ==========================================================================

  /// 添加表格
  ///
  /// [headers] 表头列表，[rows] 数据行（每行是字符串列表）
  /// [align] 对齐方式列表（'left'/'center'/'right'）
  MarkdownBuilder table(
    List<String> headers,
    List<List<String>> rows, {
    List<String>? align,
  }) {
    // 表头
    _buffer.writeln('| ${headers.join(' | ')} |');

    // 分隔行
    final separators = <String>[];
    for (int i = 0; i < headers.length; i++) {
      final a = align != null && i < align.length ? align[i] : 'left';
      switch (a) {
        case 'center':
          separators.add(':---:');
          break;
        case 'right':
          separators.add('---:');
          break;
        default:
          separators.add('---');
      }
    }
    _buffer.writeln('| ${separators.join(' | ')} |');

    // 数据行
    for (final row in rows) {
      final cells = <String>[];
      for (int i = 0; i < headers.length; i++) {
        cells.add(i < row.length ? row[i] : '');
      }
      _buffer.writeln('| ${cells.join(' | ')} |');
    }
    _buffer.writeln();
    return this;
  }

  // ==========================================================================
  // 其他
  // ==========================================================================

  /// 添加 HTML 注释
  MarkdownBuilder comment(String text) {
    _buffer.writeln('<!-- $text -->');
    _buffer.writeln();
    return this;
  }

  /// 添加脚注定义
  MarkdownBuilder footnote(String id, String text) {
    _buffer.writeln('[^$id]: $text');
    _buffer.writeln();
    return this;
  }

  /// 添加脚注引用
  MarkdownBuilder footnoteRef(String id) {
    _buffer.write('[^$id]');
    return this;
  }

  /// 添加原始文本（不做任何处理）
  MarkdownBuilder raw(String text) {
    _buffer.write(text);
    return this;
  }

  // ==========================================================================
  // 导出
  // ==========================================================================

  /// 导出为 Markdown 字符串
  String build() {
    return _buffer.toString();
  }

  /// 导出为 Markdown 字符串（toString 别名）
  @override
  String toString() => build();

  /// 清空构建器
  void clear() {
    _buffer.clear();
  }

  /// 当前内容长度
  int get length => _buffer.length;

  /// 是否为空
  bool get isEmpty => _buffer.isEmpty;
}
