import 'dart:async';

/// ============================================================================
/// Debouncer —— 通用防抖器
///
/// 在指定时间间隔内多次调用时，仅执行最后一次。
/// 适用于搜索输入、按钮防重复点击、滚动停止后加载等场景。
///
/// 用法：
///   final debouncer = Debouncer(delay: Duration(milliseconds: 500));
///   debouncer.run(() => search(query));
/// ============================================================================
class Debouncer {
  /// 防抖延迟时间
  final Duration delay;

  /// 内部定时器
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  /// 执行防抖回调
  ///
  /// 如果在 [delay] 时间内再次调用，前一次回调将被取消，
  /// 仅最后一次回调会在延迟结束后执行。
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// 立即执行回调（取消等待）
  void flush(void Function() action) {
    _timer?.cancel();
    _timer = null;
    action();
  }

  /// 取消待执行的回调
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// 是否有待执行的回调
  bool get isRunning => _timer?.isActive ?? false;

  /// 释放资源
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// ============================================================================
/// TypingDebouncer —— 输入专用防抖器
///
/// 针对文本输入场景优化的防抖器，在用户停止输入一段时间后触发回调。
/// 与 Debouncer 的区别：提供输入状态回调（onTypingStart / onTypingEnd），
/// 可用于显示"正在输入..."指示器。
///
/// 用法：
///   final typingDebouncer = TypingDebouncer(
///     delay: Duration(milliseconds: 800),
///     onSearch: (query) => doSearch(query),
///   );
///   onTextChanged: (text) => typingDebouncer.onInput(text),
/// ============================================================================
class TypingDebouncer {
  /// 输入停止后触发搜索的延迟
  final Duration delay;

  /// 搜索回调（防抖结束后调用，传入当前输入文本）
  final void Function(String query)? onSearch;

  /// 开始输入回调
  final void Function()? onTypingStart;

  /// 停止输入回调（防抖结束后调用）
  final void Function()? onTypingEnd;

  /// 内部定时器
  Timer? _timer;

  /// 当前输入文本
  String _currentText = '';

  /// 是否正在输入中
  bool _isTyping = false;

  bool get isTyping => _isTyping;
  String get currentText => _currentText;

  TypingDebouncer({
    this.delay = const Duration(milliseconds: 500),
    this.onSearch,
    this.onTypingStart,
    this.onTypingEnd,
  });

  /// 输入变化时调用
  void onInput(String text) {
    _currentText = text;

    // 首次输入或之前已停止，触发开始输入回调
    if (!_isTyping) {
      _isTyping = true;
      onTypingStart?.call();
    }

    // 重置定时器
    _timer?.cancel();
    _timer = Timer(delay, () {
      _isTyping = false;
      onTypingEnd?.call();
      if (_currentText.trim().isNotEmpty) {
        onSearch?.call(_currentText.trim());
      }
    });
  }

  /// 立即触发搜索（不等待防抖）
  void triggerNow() {
    _timer?.cancel();
    _isTyping = false;
    onTypingEnd?.call();
    if (_currentText.trim().isNotEmpty) {
      onSearch?.call(_currentText.trim());
    }
  }

  /// 清除输入并取消待执行的搜索
  void clear() {
    _timer?.cancel();
    _currentText = '';
    _isTyping = false;
  }

  /// 释放资源
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// ============================================================================
/// Throttler —— 节流器
///
/// 与防抖不同，节流确保在指定时间间隔内最多执行一次回调。
/// 适用于滚动事件、resize 事件等高频触发场景。
/// ============================================================================
class Throttler {
  /// 节流间隔
  final Duration interval;

  /// 内部定时器
  Timer? _timer;

  /// 上次执行时间
  DateTime? _lastExecution;

  /// 是否有待执行的回调（leading + trailing 模式）
  bool _hasPending = false;
  void Function()? _pendingAction;

  Throttler({this.interval = const Duration(milliseconds: 200)});

  /// 执行节流回调（leading 模式：首次立即执行）
  void run(void Function() action) {
    final now = DateTime.now();
    if (_lastExecution == null ||
        now.difference(_lastExecution!) >= interval) {
      _lastExecution = now;
      action();
    } else {
      // 记录待执行回调，在间隔结束后执行（trailing）
      _hasPending = true;
      _pendingAction = action;
      _timer?.cancel();
      _timer = Timer(interval, () {
        if (_hasPending && _pendingAction != null) {
          _lastExecution = DateTime.now();
          _pendingAction!();
          _hasPending = false;
          _pendingAction = null;
        }
      });
    }
  }

  /// 取消待执行的回调
  void cancel() {
    _timer?.cancel();
    _hasPending = false;
    _pendingAction = null;
  }

  /// 释放资源
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pendingAction = null;
  }
}
