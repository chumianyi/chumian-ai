import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================================
/// VideoThumbnail —— 视频缩略图组件
///
/// 播放按钮覆盖 + 时长标签，粉色主题，点击播放回调。
/// 用于视频列表、消息中的视频预览等场景。
/// ============================================================================
class VideoThumbnail extends StatefulWidget {
  /// 视频缩略图 URL
  final String thumbnailUrl;

  /// 视频 URL（点击播放时使用）
  final String? videoUrl;

  /// 视频时长（秒）
  final int duration;

  /// 宽度
  final double? width;

  /// 高度
  final double? height;

  /// 圆角
  final double borderRadius;

  /// 播放按钮大小
  final double playButtonSize;

  /// 点击播放回调
  final VoidCallback? onPlay;

  /// 是否显示时长标签
  final bool showDuration;

  /// 是否显示播放按钮
  final bool showPlayButton;

  /// 自定义占位组件
  final Widget? placeholder;

  const VideoThumbnail({
    super.key,
    required this.thumbnailUrl,
    this.videoUrl,
    this.duration = 0,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.playButtonSize = 48.0,
    this.onPlay,
    this.showDuration = true,
    this.showPlayButton = true,
    this.placeholder,
  });

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// 格式化时长
  String get _formattedDuration {
    final minutes = widget.duration ~/ 60;
    final seconds = widget.duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPlay,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: MiuixColors.primary.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 缩略图
                _buildThumbnail(),
                // 暗色遮罩
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
                // 播放按钮
                if (widget.showPlayButton) _buildPlayButton(),
                // 时长标签
                if (widget.showDuration && widget.duration > 0)
                  _buildDurationLabel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (widget.thumbnailUrl.isEmpty) {
      return widget.placeholder ??
          Container(
            color: MiuixColors.surfaceVariant,
            child: Icon(
              Icons.video_library,
              color: MiuixColors.textTertiary,
              size: 48,
            ),
          );
    }
    return CachedNetworkImage(
      imageUrl: widget.thumbnailUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: MiuixColors.surfaceVariant,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(MiuixColors.primary),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: MiuixColors.surfaceVariant,
        child: Icon(
          Icons.broken_image,
          color: MiuixColors.textTertiary,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = 1.0 + _pulseController.value * 0.08;
          return Stack(
            alignment: Alignment.center,
            children: [
              // 脉冲光圈
              Container(
                width: widget.playButtonSize * 1.5,
                height: widget.playButtonSize * 1.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MiuixColors.primary
                      .withOpacity(0.15 * _pulseController.value),
                ),
              ),
              // 播放按钮
              Transform.scale(
                scale: _isHovering ? scale : 1.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: widget.playButtonSize,
                  height: widget.playButtonSize,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: MiuixColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: MiuixColors.primary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: widget.playButtonSize * 0.5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDurationLabel() {
    return Positioned(
      bottom: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(MiuixRadius.xs),
          border: Border.all(
            color: MiuixColors.primary.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time,
              color: MiuixColors.primaryLight,
              size: 12,
            ),
            const SizedBox(width: 3),
            Text(
              _formattedDuration,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
