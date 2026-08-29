import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';

class VideoPreviewPage extends StatefulWidget {
  final String videoUrl;
  const VideoPreviewPage({super.key, required this.videoUrl});
  @override
  State<VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<VideoPreviewPage> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _downloading = false;
  bool _showControls = true;
  static const _galleryChannel = MethodChannel('com.chumian.chumian_ai/gallery');

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    await _controller.initialize();
    await _controller.play();
    if (mounted) setState(() => _initialized = true);
  }

  Future<void> _downloadVideo() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final response = await Dio().get(widget.videoUrl, options: Options(responseType: ResponseType.bytes));
      final bytes = Uint8List.fromList(response.data);
      await _galleryChannel.invokeMethod('saveVideo', {'bytes': bytes, 'album': '初眠AI'});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('视频已保存到相册')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        title: const Text('视频播放', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: _downloading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.download),
            onPressed: _downloadVideo,
            tooltip: '保存视频',
          ),
        ],
      ),
      body: Center(
        child: _initialized
            ? GestureDetector(
                onTap: () => setState(() => _showControls = !_showControls),
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      VideoPlayer(_controller),
                      if (_showControls) Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(children: [
                          IconButton(
                            icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                            onPressed: () => _controller.value.isPlaying ? _controller.pause() : _controller.play(),
                          ),
                          Expanded(
                            child: Slider(
                              value: _controller.value.position.inSeconds.toDouble(),
                              max: _controller.value.duration.inSeconds.toDouble(),
                              onChanged: (v) => _controller.seekTo(Duration(seconds: v.toInt())),
                              activeColor: Colors.white,
                              inactiveColor: Colors.white30,
                            ),
                          ),
                          Text('${_formatDuration(_controller.value.position)}/${_formatDuration(_controller.value.duration)}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          IconButton(icon: const Icon(Icons.fullscreen, color: Colors.white), onPressed: () {
                            SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
                          }),
                        ]),
                      ),
                    ],
                  ),
                ),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
