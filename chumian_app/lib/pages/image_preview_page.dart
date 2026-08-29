import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:dio/dio.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
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

  Future<void> _downloadImage() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted && !status.isPermanentlyDenied) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('需要存储权限')));
          setState(() => _downloading = false);
          return;
        }
      }
      final response = await Dio().get(widget.imageUrl, options: Options(responseType: ResponseType.bytes));
      final bytes = Uint8List.fromList(response.data);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final result = await ImageGallerySaver.saveImage(bytes, name: 'chumian_ai_$timestamp', quality: 100);
      if (mounted) {
        if (result['isSuccess'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('图片已保存到相册')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: ${result['errorMessage'] ?? '未知错误'}')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('下载失败: $e')));
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
