import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class AICreatePage extends StatefulWidget {
  const AICreatePage({super.key});

  @override
  State<AICreatePage> createState() => _AICreatePageState();
}

class _AICreatePageState extends State<AICreatePage> {
  final TextEditingController _promptCtrl = TextEditingController();
  final List<String> _generatedImages = [];
  bool _generating = false;
  String _selectedSize = '1:1';

  static const List<String> _sizes = ['1:1', '16:9', '9:16', '4:3', '3:4'];

  Future<void> _generate() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入提示词')));
      return;
    }
    setState(() => _generating = true);
    try {
      // 调用服务端图片生成API
      final result = await ApiService.generateImage(prompt, size: _selectedSize);
      if (result != null && result.isNotEmpty) {
        setState(() => _generatedImages.insert(0, result));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('生成失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _downloadImage(String url) async {
    try {
      final response = await ApiService.dio.get(url, options: Options(responseType: ResponseType.bytes));
      final bytes = response.data as List<int>;
      const platform = MethodChannel('com.chumian.chumian_ai/gallery');
      await platform.invokeMethod('saveImage', {'bytes': Uint8List.fromList(bytes), 'album': '初眠AI'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('图片已保存到相册')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI创作'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 提示词输入区
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _promptCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: '描述你想生成的图片，如：一只在星空下奔跑的白色猫咪，梦幻风格',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('尺寸:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: _sizes.map((s) => ChoiceChip(
                          label: Text(s, style: const TextStyle(fontSize: 12)),
                          selected: _selectedSize == s,
                          onSelected: (_) => setState(() => _selectedSize = s),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _generating ? null : _generate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: _generating
                        ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)), SizedBox(width: 10), Text('生成中...')])
                        : const Text('生成图片', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 生成结果网格
          Expanded(
            child: _generatedImages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('输入提示词开始创作', style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemCount: _generatedImages.length,
                    itemBuilder: (_, i) {
                      final url = _generatedImages[i];
                      return GestureDetector(
                        onTap: () => _showImagePreview(url),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(url, fit: BoxFit.cover, loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              }, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image))),
                              Positioned(
                                right: 8, bottom: 8,
                                child: GestureDetector(
                                  onTap: () => _downloadImage(url),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                                    child: const Icon(Icons.download, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showImagePreview(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(child: Image.network(url, fit: BoxFit.contain)),
            ),
            Positioned(
              top: 8, right: 8,
              child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
            ),
            Positioned(
              bottom: 8, right: 8,
              child: IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                  _downloadImage(url);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
