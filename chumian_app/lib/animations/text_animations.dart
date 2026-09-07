import 'dart:async';
import 'package:flutter/material.dart';

/// ============================================================================
/// TextAnimations —— 文字动画集合
///
/// 提供 Typewriter / FadeText / WaveText / ScaleText / GlitchText 等
/// 文字动画，支持逐字动画、文字波浪、打字机效果。
/// ============================================================================

/// 打字机效果文字
class Typewriter extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool repeat;
  final TextAlign? textAlign;

  const Typewriter({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 1500),
    this.delay = Duration.zero,
    this.curve = Curves.linear,
    this.repeat = false,
    this.textAlign,
  });

  @override
  State<Typewriter> createState() => _TypewriterState();
}

class _TypewriterState extends State<Typewriter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _timer;
  int _visibleChars = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    Future.delayed(widget.delay, _startTyping);
  }

  void _startTyping() {
    if (!mounted) return;
    final charDuration = widget.duration.inMilliseconds ~/ widget.text.length;
    _timer = Timer.periodic(Duration(milliseconds: charDuration), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _visibleChars++;
      });
      if (_visibleChars >= widget.text.length) {
        timer.cancel();
        if (widget.repeat) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() => _visibleChars = 0);
              _startTyping();
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleText = widget.text.substring(
      0,
      _visibleChars.clamp(0, widget.text.length),
    );
    return Text(
      visibleText,
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}

/// 逐字淡入文字
class FadeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final Duration charDelay;
  final Curve curve;
  final TextAlign? textAlign;

  const FadeText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 400),
    this.charDelay = const Duration(milliseconds: 50),
    this.curve = Curves.easeOut,
    this.textAlign,
  });

  @override
  State<FadeText> createState() => _FadeTextState();
}

class _FadeTextState extends State<FadeText> {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.text.length; i++) {
      final controller = AnimationController(
        vsync: this as TickerProvider,
        duration: widget.duration,
      );
      _controllers.add(controller);
      _animations.add(
        Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: controller, curve: widget.curve),
        ),
      );
      Future.delayed(widget.charDelay * i, () {
        if (mounted) controller.forward();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: widget.textAlign ?? TextAlign.start,
      text: TextSpan(
        style: widget.style ?? DefaultTextStyle.of(context).style,
        children: List.generate(widget.text.length, (i) {
          return WidgetSpan(
            child: FadeTransition(
              opacity: _animations[i],
              child: Text(widget.text[i], style: widget.style),
            ),
          );
        }),
      ),
    );
  }
}

/// 波浪文字（每个字上下波动）
class WaveText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final double amplitude;
  final double frequency;
  final TextAlign? textAlign;

  const WaveText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(seconds: 2),
    this.amplitude = 5,
    this.frequency = 2,
    this.textAlign,
  });

  @override
  State<WaveText> createState() => _WaveTextState();
}

class _WaveTextState extends State<WaveText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return RichText(
          textAlign: widget.textAlign ?? TextAlign.start,
          text: TextSpan(
            style: widget.style ?? DefaultTextStyle.of(context).style,
            children: List.generate(widget.text.length, (i) {
              final phase = _controller.value * 2 * 3.14159 * widget.frequency;
              final offset =
                  (phase + i * 0.5).sin() * widget.amplitude;
              return WidgetSpan(
                child: Transform.translate(
                  offset: Offset(0, offset),
                  child: Text(widget.text[i], style: widget.style),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// 缩放文字（每个字依次缩放）
class ScaleText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final Duration charDelay;
  final double beginScale;
  final Curve curve;
  final TextAlign? textAlign;

  const ScaleText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 500),
    this.charDelay = const Duration(milliseconds: 60),
    this.beginScale = 0.0,
    this.curve = Curves.elasticOut,
    this.textAlign,
  });

  @override
  State<ScaleText> createState() => _ScaleTextState();
}

class _ScaleTextState extends State<ScaleText> {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.text.length; i++) {
      final controller = AnimationController(
        vsync: this as TickerProvider,
        duration: widget.duration,
      );
      _controllers.add(controller);
      _animations.add(
        Tween<double>(begin: widget.beginScale, end: 1).animate(
          CurvedAnimation(parent: controller, curve: widget.curve),
        ),
      );
      Future.delayed(widget.charDelay * i, () {
        if (mounted) controller.forward();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: widget.textAlign ?? TextAlign.start,
      text: TextSpan(
        style: widget.style ?? DefaultTextStyle.of(context).style,
        children: List.generate(widget.text.length, (i) {
          return WidgetSpan(
            child: ScaleTransition(
              scale: _animations[i],
              child: Text(widget.text[i], style: widget.style),
            ),
          );
        }),
      ),
    );
  }
}

/// 故障文字（Glitch 效果，RGB 分离抖动）
class GlitchText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final double offset;
  final TextAlign? textAlign;

  const GlitchText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 200),
    this.offset = 3,
    this.textAlign,
  });

  @override
  State<GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<GlitchText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _offsetX = 0;
  double _offsetY = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addListener(() {
        setState(() {
          _offsetX = (DateTime.now().microsecond % 2 == 0)
              ? widget.offset
              : -widget.offset;
          _offsetY = (DateTime.now().microsecond % 3 == 0)
              ? widget.offset / 2
              : -widget.offset / 2;
        });
      });
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style ??
        const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
    return Stack(
      children: [
        // 红色通道
        Transform.translate(
          offset: Offset(_offsetX, 0),
          child: Text(
            widget.text,
            style: baseStyle.copyWith(color: Colors.red.withOpacity(0.8)),
            textAlign: widget.textAlign,
          ),
        ),
        // 绿色通道
        Transform.translate(
          offset: Offset(-_offsetX, _offsetY),
          child: Text(
            widget.text,
            style: baseStyle.copyWith(color: Colors.green.withOpacity(0.8)),
            textAlign: widget.textAlign,
          ),
        ),
        // 蓝色通道（原始）
        Transform.translate(
          offset: Offset(0, -_offsetY),
          child: Text(
            widget.text,
            style: baseStyle.copyWith(color: Colors.blue.withOpacity(0.8)),
            textAlign: widget.textAlign,
          ),
        ),
        // 原始文字
        Text(
          widget.text,
          style: baseStyle,
          textAlign: widget.textAlign,
        ),
      ],
    );
  }
}

/// 闪烁文字
class BlinkText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final TextAlign? textAlign;

  const BlinkText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 500),
    this.textAlign,
  });

  @override
  State<BlinkText> createState() => _BlinkTextState();
}

class _BlinkTextState extends State<BlinkText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1, end: 0.2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Text(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
      ),
    );
  }
}
