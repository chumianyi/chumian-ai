import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// VideoPreviewPage —— 视频预览页
/// video_player播放控制 + 全屏 + 粉色UI
/// ============================================================
class VideoPreviewPage extends StatefulWidget {
  const VideoPreviewPage({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<VideoPreviewPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() => _isInitialized = true);
        _controller.play();
      }).catchError((_) {
        setState(() => _isInitialized = false);
      });
    _controller.addListener(_onVideoUpdate);
  }

  void _onVideoUpdate() {
    if (_controller.value.isCompleted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isInitialized
            ? _buildVideoPlayer()
            : const Center(child: CircularProgressIndicator(color: MiuixColors.primary)),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(alignment: Alignment.center, children: [
        AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller)),
        AnimatedOpacity(opacity: _showControls ? 1 : 0, duration: MiuixDuration.fast, child: IgnorePointer(ignoring: !_showControls, child: Stack(children: [
          _buildTopBar(),
          _buildCenterPlay(),
          _buildBottomBar(),
        ]))),
      ]),
    );
  }

  Widget _buildTopBar() {
    return Positioned(top: 0, left: 0, right: 0, child: SafeArea(child: Container(padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent])), child: Row(children: [
      MiuixRipple(borderRadius: MiuixRadius.pill, child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context))),
      const Spacer(),
      MiuixRipple(borderRadius: MiuixRadius.pill, child: IconButton(icon: Icon(_isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white), onPressed: _toggleFullscreen)),
    ]))));
  }

  Widget _buildCenterPlay() {
    return Center(child: MiuixRipple(borderRadius: MiuixRadius.pill, child: GestureDetector(onTap: _togglePlay, child: AnimatedContainer(duration: MiuixDuration.fast, width: 64, height: 64, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle, border: Border.all(color: MiuixColors.primary.withValues(alpha: 0.5), width: 2)), child: Center(child: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 36))))));
  }

  Widget _buildBottomBar() {
    return Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent])), child: Column(children: [
      Row(children: [
        Text(_formatDuration(_controller.value.position), style: const TextStyle(color: Colors.white, fontSize: 12)),
        Expanded(child: SliderTheme(data: SliderThemeData(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), activeTrackColor: MiuixColors.primary, inactiveTrackColor: Colors.white24, thumbColor: MiuixColors.primary, overlayColor: MiuixColors.primary.withValues(alpha: 0.2)), child: Slider(value: _controller.value.position.inSeconds.toDouble(), max: _controller.value.duration.inSeconds.toDouble().clamp(1, double.infinity), onChanged: (v) => _controller.seekTo(Duration(seconds: v.toInt()))))),
        Text(_formatDuration(_controller.value.duration), style: const TextStyle(color: Colors.white, fontSize: 12)),
      ]),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _buildControlButton(Icons.replay_10, '后退10秒', () => _controller.seekTo(_controller.value.position - const Duration(seconds: 10))),
        const SizedBox(width: 24),
        _buildControlButton(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow, _controller.value.isPlaying ? '暂停' : '播放', _togglePlay, isMain: true),
        const SizedBox(width: 24),
        _buildControlButton(Icons.forward_10, '前进10秒', () => _controller.seekTo(_controller.value.position + const Duration(seconds: 10))),
      ]),
    ])));
  }

  Widget _buildControlButton(IconData icon, String label, VoidCallback onTap, {bool isMain = false}) {
    return MiuixRipple(borderRadius: MiuixRadius.pill, child: GestureDetector(onTap: onTap, child: Container(width: isMain ? 48 : 40, height: isMain ? 48 : 40, decoration: BoxDecoration(color: isMain ? MiuixColors.primary : Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle), child: Center(child: Icon(icon, color: Colors.white, size: isMain ? 28 : 22)))));
  }
}
