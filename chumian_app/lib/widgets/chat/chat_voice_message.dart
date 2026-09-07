import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// ChatVoiceMessage —— 语音消息组件
/// 语音气泡，波形图，播放按钮，时长显示，播放进度
/// 粉色主题，按压缩放，水晕反馈
/// ============================================================

class ChatVoiceMessage extends StatefulWidget {
  const ChatVoiceMessage({
    super.key,
    required this.duration,
    this.audioUrl,
    this.isUser = false,
    this.onPlay,
    this.onPause,
    this.onSeek,
  });

  /// 语音时长（秒）
  final int duration;

  /// 音频 URL
  final String? audioUrl;

  /// 是否为用户消息
  final bool isUser;

  /// 播放回调
  final VoidCallback? onPlay;

  /// 暂停回调
  final VoidCallback? onPause;

  /// 拖动进度回调
  final ValueChanged<double>? onSeek;

  @override
  State<ChatVoiceMessage> createState() => _ChatVoiceMessageState();
}

class _ChatVoiceMessageState extends State<ChatVoiceMessage>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  double _progress = 0.0;
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  Timer? _progressTimer;
  final List<double> _waveform = _generateWaveform();

  static List<double> _generateWaveform() {
    final random = math.Random(42);
    return List.generate(30, (_) => 0.3 + random.nextDouble() * 0.7);
  }

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: MiuixDuration.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: MiuixCurves.easeInOut),
    );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _pressController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        widget.onPlay?.call();
        _startProgress();
      } else {
        widget.onPause?.call();
        _progressTimer?.cancel();
      }
    });
  }

  void _startProgress() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _progress += 0.1 / widget.duration;
        if (_progress >= 1.0) {
          _progress = 0.0;
          _isPlaying = false;
          timer.cancel();
        }
      });
    });
  }

  String _formatDuration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(1, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bubbleWidth = 80.0 + (widget.duration * 2.5).clamp(0.0, 160.0);

    return GestureDetector(
      onTapDown: (_) {
        setState(() {});
        _pressController.forward();
      },
      onTapUp: (_) {
        _pressController.reverse();
        _togglePlay();
      },
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: MiuixRipple(
          onTap: _togglePlay,
          borderRadius: MiuixRadius.lg,
          child: Container(
            width: bubbleWidth,
            padding: const EdgeInsets.symmetric(
              horizontal: MiuixSpacing.md,
              vertical: MiuixSpacing.md,
            ),
            decoration: BoxDecoration(
              gradient: widget.isUser
                  ? const LinearGradient(colors: MiuixColors.primaryGradient)
                  : null,
              color: widget.isUser ? null : MiuixColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(MiuixRadius.lg),
                topRight: const Radius.circular(MiuixRadius.lg),
                bottomLeft: Radius.circular(
                  widget.isUser ? MiuixRadius.lg : MiuixRadius.sm,
                ),
                bottomRight: Radius.circular(
                  widget.isUser ? MiuixRadius.sm : MiuixRadius.lg,
                ),
              ),
              border: widget.isUser
                  ? null
                  : Border.all(color: MiuixColors.borderLight, width: 1),
              boxShadow: widget.isUser
                  ? [
                      BoxShadow(
                        color: MiuixColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : MiuixShadows.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPlayButton(),
                const SizedBox(width: MiuixSpacing.sm),
                Expanded(child: _buildWaveform()),
                const SizedBox(width: MiuixSpacing.sm),
                Text(
                  _formatDuration(widget.duration),
                  style: TextStyle(
                    fontSize: MiuixFontSize.sm,
                    fontWeight: FontWeight.w500,
                    color: widget.isUser ? Colors.white : MiuixColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    return AnimatedContainer(
      duration: MiuixDuration.fast,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: widget.isUser
            ? Colors.white.withOpacity(0.25)
            : MiuixColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _isPlaying ? Icons.pause : Icons.play_arrow,
        size: 18,
        color: widget.isUser ? Colors.white : MiuixColors.primary,
      ),
    );
  }

  Widget _buildWaveform() {
    return SizedBox(
      height: 28,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_waveform.length, (i) {
          final isPlayed = (i / _waveform.length) <= _progress;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 2.5,
            height: 4 + _waveform[i] * 20,
            margin: const EdgeInsets.symmetric(horizontal: 0.5),
            decoration: BoxDecoration(
              color: isPlayed
                  ? (widget.isUser ? Colors.white : MiuixColors.primary)
                  : (widget.isUser
                      ? Colors.white.withOpacity(0.4)
                      : MiuixColors.border),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
