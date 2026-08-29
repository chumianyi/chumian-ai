import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:dio/dio.dart';

class VideoPreviewPage extends StatefulWidget {
  final String videoUrl;
  const VideoPreviewPage({super.key, required this.videoUrl});
  @override
  State<VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<VideoPreviewPage> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _initialized = false;
  bool _downloading = false;
  static const _galleryChannel = MethodChannel('com.chumian.chumian_ai/gallery');

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    await _videoController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowPlaybackSpeedChanging: false,
      placeholder: const Center(child: CircularProgressIndicator()),
    );
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

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
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
        child: _initialized && _chewieController != null
            ? Chewie(controller: _chewieController!)
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
