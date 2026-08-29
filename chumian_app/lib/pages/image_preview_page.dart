import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:dio/dio.dart';
import '../theme.dart';

class ImagePreviewPage extends StatefulWidget {
  final String imageUrl;
  final String? heroTag;
  const ImagePreviewPage({super.key, required this.imageUrl, this.heroTag});

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> {
  bool _downloading = false;
  static const platform = MethodChannel('com.chumian.chumian_ai/gallery');

  Future<void> _downloadImage() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final response = await Dio().get(widget.imageUrl, options: Options(responseType: ResponseType.bytes));
      final bytes = Uint8List.fromList(response.data);
      await platform.invokeMethod('saveImage', {'bytes': bytes, 'album': '初眠AI'});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('图片已保存到相册')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
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
        title: const Text('查看图片', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: _downloading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.download),
            onPressed: _downloadImage,
            tooltip: '保存到相册',
          ),
        ],
      ),
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(widget.imageUrl),
          minScale: PhotoViewComputedScale.contained * 0.5,
          maxScale: PhotoViewComputedScale.covered * 5,
          initialScale: PhotoViewComputedScale.contained,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          loadingBuilder: (context, event) => Center(
            child: CircularProgressIndicator(
              value: event == null ? 0 : (event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1)),
              color: AppTheme.primaryColor,
            ),
          ),
          errorBuilder: (context, error, stackTrace) => const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.broken_image, color: Colors.white54, size: 48),
            SizedBox(height: 12),
            Text('图片加载失败', style: TextStyle(color: Colors.white54)),
          ]),
        ),
      ),
    );
  }
}
