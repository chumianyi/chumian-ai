import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixGradientText —— Miuix 风格渐变文字
/// 粉色渐变文字，闪烁动画，逐字入场，描边效果
/// ============================================================

/// 动画模式
enum MiuixGradientTextMode {
  /// 静态渐变
  static,

  /// 闪烁动画
  shimmer,

  /// 逐字入场
  charEntry,
}

/// Miuix 风格渐变文字
///
/// 用法：
/// ```dart
/// MiuixGradientText(
///   '初眠AI',
///   mode: MiuixGradientTextMode.shimmer,
///   fontSize: 32,
/// )
/// ```
class MiuixGradientText extends StatefulWidget {
  const MiuixGradientText(
    this.text, {
    super.key,
    this.mode = MiuixGradientTextMode.static,
    this.fontSize = 24,
    this.fontWeight = FontWeight.w700,
    this.gradient,
    this.strokeWidth = 0,
    this.strokeColor,
    this.textAlign = TextAlign.start,
    this.charDelay = 80,
  });

  /// 文字内容
  final String text;

  /// 动画模式
  final MiuixGradientTextMode mode;

  /// 字体大小
  final double fontSize;

  /// 字重
  final FontWeight fontWeight;

  /// 自定义渐变
  final Gradient? gradient;

  /// 描边宽度（0为无描边）
  final double strokeWidth;

  /// 描边颜色
  final Color? strokeColor;

  /// 对齐方式
  final TextAlign textAlign;

  /// 逐字入场延迟（毫秒）
  final int charDelay;

  @override
  State<MiuixGradientText> createState() => _MiuixGradientTextState();
}

class _MiuixGradientTextState extends State<MiuixGradientText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.mode == MiuixGradientTextMode.charEntry
          ? Duration(
              milliseconds: 600 + widget.text.length * widget.charDelay,
            )
          : const Duration(seconds: 2),
    );
    if (widget.mode != MiuixGradientTextMode.static) {
      if (widget.mode == MiuixGradientTextMode.shimmer) {
        _controller.repeat();
      } else {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _controller.forward());
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Gradient get _defaultGradient => const LinearGradient(
        colors: MiuixColors.primaryGradient,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  @override
  Widget build(BuildContext context) {
    switch (widget.mode) {
      case MiuixGradientTextMode.static:
        return _buildStaticText();
      case MiuixGradientTextMode.shimmer:
        return _buildShimmerText();
      case MiuixGradientTextMode.charEntry:
        return _buildCharEntryText();
    }
  }

  Widget _buildStaticText() {
    return ShaderMask(
      shaderCallback: (bounds) =>
          (widget.gradient ?? _defaultGradient).createShader(bounds),
      child: _buildText(Colors.white),
    );
  }

  Widget _buildShimmerText() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dx = _controller.value * 2 - 0.5;
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                MiuixColors.primaryLight,
                MiuixColors.primary,
                Colors.white,
                MiuixColors.primary,
                MiuixColors.primaryDeep,
              ],
              stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
              begin: Alignment(dx - 0.5, 0),
              end: Alignment(dx + 0.5, 0),
            ).createShader(bounds);
          },
          child: _buildText(Colors.white),
        );
      },
    );
  }

  Widget _buildCharEntryText() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return RichText(
          textAlign: widget.textAlign,
          text: TextSpan(
            children: widget.text.characters.asMap().entries.map((entry) {
              final index = entry.key;
              final char = entry.value;
              final charStart =
                  (index * widget.charDelay) /
                      (600 + widget.text.length * widget.charDelay);
              final charEnd =
                  (index * widget.charDelay + 400) /
                      (600 + widget.text.length * widget.charDelay);
              final charProgress =
                  ((_controller.value - charStart) /
                          (charEnd - charStart))
                      .clamp(0.0, 1.0);
              final curveValue =
                  Curves.easeOutBack.transform(charProgress);

              return WidgetSpan(
                child: Transform.translate(
                  offset: Offset(0, (1 - curveValue) * 20),
                  child: Opacity(
                    opacity: curveValue,
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          (widget.gradient ?? _defaultGradient)
                              .createShader(bounds),
                      child: Text(
                        char,
                        style: TextStyle(
                          fontSize: widget.fontSize,
                          fontWeight: widget.fontWeight,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildText(Color color) {
    if (widget.strokeWidth > 0) {
      return Stack(
        children: [
          Text(
            widget.text,
            textAlign: widget.textAlign,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: widget.fontWeight,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = widget.strokeWidth
                ..color = widget.strokeColor ?? MiuixColors.primaryDeep,
            ),
          ),
          Text(
            widget.text,
            textAlign: widget.textAlign,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: widget.fontWeight,
              color: color,
            ),
          ),
        ],
      );
    }
    return Text(
      widget.text,
      textAlign: widget.textAlign,
      style: TextStyle(
        fontSize: widget.fontSize,
        fontWeight: widget.fontWeight,
        color: color,
      ),
    );
  }
}

/// ============================================================
/// MiuixTypewriterText —— 打字机效果文字
/// 逐字显示，带光标闪烁
/// ============================================================
class MiuixTypewriterText extends StatefulWidget {
  const MiuixTypewriterText(
    this.text, {
    super.key,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w500,
    this.color = MiuixColors.textPrimary,
    this.typingSpeed = const Duration(milliseconds: 80),
    this.showCursor = true,
    this.onComplete,
    this.loop = false,
  });

  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final Duration typingSpeed;
  final bool showCursor;
  final VoidCallback? onComplete;
  final bool loop;

  @override
  State<MiuixTypewriterText> createState() => _MiuixTypewriterTextState();
}

class _MiuixTypewriterTextState extends State<MiuixTypewriterText>
    with SingleTickerProviderStateMixin {
  int _charCount = 0;
  Timer? _timer;
  late final AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _startTyping();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cursorController.dispose();
    super.dispose();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.typingSpeed, (timer) {
      if (!mounted) return;
      setState(() {
        _charCount++;
        if (_charCount >= widget.text.length) {
          timer.cancel();
          widget.onComplete?.call();
          if (widget.loop) {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() => _charCount = 0);
                _startTyping();
              }
            });
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: MiuixColors.primaryGradient,
      ).createShader(bounds),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: widget.text.substring(0, _charCount),
              style: TextStyle(
                fontSize: widget.fontSize,
                fontWeight: widget.fontWeight,
                color: Colors.white,
              ),
            ),
            if (widget.showCursor && _charCount < widget.text.length)
              WidgetSpan(
                child: AnimatedBuilder(
                  animation: _cursorController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _cursorController.value > 0.5 ? 1.0 : 0.0,
                      child: Text(
                        '|',
                        style: TextStyle(
                          fontSize: widget.fontSize,
                          fontWeight: widget.fontWeight,
                          color: MiuixColors.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// MiuixMarqueeText —— 跑马灯文字
/// 文字过长时自动滚动
/// ============================================================
class MiuixMarqueeText extends StatefulWidget {
  const MiuixMarqueeText(
    this.text, {
    super.key,
    this.fontSize = 14,
    this.color = MiuixColors.textPrimary,
    this.scrollSpeed = 50,
    this.pauseDuration = const Duration(seconds: 2),
  });

  final String text;
  final double fontSize;
  final Color color;
  final double scrollSpeed;
  final Duration pauseDuration;

  @override
  State<MiuixMarqueeText> createState() => _MiuixMarqueeTextState();
}

class _MiuixMarqueeTextState extends State<MiuixMarqueeText>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScroll());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startScroll() async {
    while (mounted) {
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(
            milliseconds:
                (_scrollController.position.maxScrollExtent / widget.scrollSpeed * 1000)
                    .toInt(),
          ),
          curve: Curves.linear,
        );
        await Future.delayed(widget.pauseDuration);
        if (!mounted) break;
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
        await Future.delayed(widget.pauseDuration);
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Text(
        widget.text,
        style: TextStyle(
          fontSize: widget.fontSize,
          color: widget.color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
