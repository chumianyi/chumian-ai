import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================================
/// AudioPlayerBar —— 音频播放条组件
///
/// 播放/暂停/上一首/下一首控制，进度条拖拽，粉色主题，波形动画。
/// 用于音乐播放器、语音消息播放、播客等场景。
/// ============================================================================
class AudioPlayerBar extends StatefulWidget {
  /// 音频标题
  final String title;

  /// 音频副标题（歌手/来源）
  final String? subtitle;

  /// 封面图 URL
  final String? coverUrl;

  /// 总时长（秒）
  final Duration totalDuration;

  /// 当前进度（秒）
  final Duration currentPosition;

  /// 是否正在播放
  final bool isPlaying;

  /// 播放回调
  final VoidCallback? onPlay;

  /// 暂停回调
  final VoidCallback? onPause;

  /// 上一首回调
  final VoidCallback? onPrevious;

  /// 下一首回调
  final VoidCallback? onNext;

  /// 进度变化回调（拖拽结束）
  final ValueChanged<Duration>? onSeek;

  /// 是否显示上一首/下一首
  final bool showSkipControls;

  /// 高度
  final double height;

  /// 内边距
  final EdgeInsetsGeometry padding;

  const AudioPlayerBar({
    super.key,
    required this.title,
    this.subtitle,
    this.coverUrl,
    required this.totalDuration,
    this.currentPosition = Duration.zero,
    this.isPlaying = false,
    this.onPlay,
    this.onPause,
    this.onPrevious,
    this.onNext,
    this.onSeek,
    this.showSkipControls = true,
    this.height = 72.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  State<AudioPlayerBar> createState() => _AudioPlayerBarState();
}

class _AudioPlayerBarState extends State<AudioPlayerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;
  double _dragValue = -1.0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isPlaying) {
      _waveController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AudioPlayerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) {
      if (widget.isPlaying) {
        _waveController.repeat();
      } else {
        _waveController.stop();
      }
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  /// 格式化时长
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalDuration.inMilliseconds > 0
        ? widget.currentPosition.inMilliseconds /
            widget.totalDuration.inMilliseconds
        : 0.0;
    final displayValue = _dragValue >= 0 ? _dragValue : progress;

    return Container(
      height: widget.height,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: MiuixColors.surface,
        borderRadius: BorderRadius.circular(MiuixRadius.lg),
        border: Border.all(color: MiuixColors.borderLight),
        boxShadow: MiuixShadows.sm,
      ),
      child: Row(
        children: [
          // 封面 + 波形
          _buildCover(),
          const SizedBox(width: 12),
          // 标题 + 进度
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: MiuixFontSize.md,
                    fontWeight: FontWeight.w600,
                    color: MiuixColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle!,
                    style: TextStyle(
                      fontSize: MiuixFontSize.sm,
                      color: MiuixColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                // 进度条
                _buildProgressBar(displayValue),
                const SizedBox(height: 2),
                // 时间
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_dragValue >= 0
                          ? Duration(
                              milliseconds: (_dragValue *
                                      widget.totalDuration.inMilliseconds)
                                  .toInt())
                          : widget.currentPosition),
                      style: TextStyle(
                        fontSize: 10,
                        color: MiuixColors.textTertiary,
                      ),
                    ),
                    Text(
                      _formatDuration(widget.totalDuration),
                      style: TextStyle(
                        fontSize: 10,
                        color: MiuixColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 控制按钮
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildCover() {
    return Stack(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MiuixRadius.sm),
            gradient: widget.coverUrl == null
                ? const LinearGradient(
                    colors: MiuixColors.primaryGradient,
                  )
                : null,
            image: widget.coverUrl != null
                ? DecorationImage(
                    image: NetworkImage(widget.coverUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: widget.coverUrl == null
              ? const Icon(Icons.music_note, color: Colors.white, size: 22)
              : null,
        ),
        // 波形动画覆盖
        if (widget.isPlaying)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildWaveform(),
          ),
      ],
    );
  }

  Widget _buildWaveform() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final waveHeight =
                4 + sin(_waveController.value * pi * 2 + i * 0.8) * 4 + 4;
            return Container(
              width: 3,
              height: waveHeight,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildProgressBar(double value) {
    return GestureDetector(
      onHorizontalDragStart: (details) {
        setState(() => _dragValue = value);
      },
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final localPosition = details.globalPosition - box.localToGlobal(Offset.zero);
        final barWidth = box.size.width - 100; // 估算进度条宽度
        final newValue =
            (localPosition.dx / barWidth).clamp(0.0, 1.0).toDouble();
        setState(() => _dragValue = newValue);
      },
      onHorizontalDragEnd: (details) {
        if (_dragValue >= 0 && widget.onSeek != null) {
          final position = Duration(
              milliseconds:
                  (_dragValue * widget.totalDuration.inMilliseconds).toInt());
          widget.onSeek!.call(position);
        }
        setState(() => _dragValue = -1.0);
      },
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: MiuixColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // 已播放部分
                FractionallySizedBox(
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: MiuixColors.primaryGradient,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // 拖拽圆点
                Positioned(
                  left: (value.clamp(0.0, 1.0) * constraints.maxWidth) - 6,
                  top: -4,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: MiuixColors.primary, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: MiuixColors.primary.withOpacity(0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showSkipControls) ...[
          _buildIconButton(
            icon: Icons.skip_previous,
            onTap: widget.onPrevious,
            size: 28,
          ),
          const SizedBox(width: 4),
        ],
        // 播放/暂停主按钮
        GestureDetector(
          onTap: widget.isPlaying ? widget.onPause : widget.onPlay,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: MiuixColors.primaryGradient,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: MiuixColors.primary.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              widget.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
        if (widget.showSkipControls) ...[
          const SizedBox(width: 4),
          _buildIconButton(
            icon: Icons.skip_next,
            onTap: widget.onNext,
            size: 28,
          ),
        ],
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onTap,
    double size = 24,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        color: onTap != null ? MiuixColors.primary : MiuixColors.textTertiary,
        size: size,
      ),
    );
  }
}
