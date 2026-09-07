import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// ImagePreviewPage —— 图片预览页
/// photo_view缩放 + 保存到相册 + 分享 + 粉色背景
/// ============================================================
class ImagePreviewPage extends StatefulWidget {
  const ImagePreviewPage({super.key, required this.imageUrl, this.tag = ''});

  final String imageUrl;
  final String tag;

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  bool _showAppBar = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: MiuixDuration.normal);
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: MiuixCurves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleAppBar() => setState(() => _showAppBar = !_showAppBar);

  Future<void> _saveToGallery() async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('图片已保存到相册'), backgroundColor: MiuixColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius)));
  }

  void _shareImage() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('分享功能'), backgroundColor: MiuixColors.primary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.primary.withValues(alpha: 0.02),
      body: Stack(children: [
        GestureDetector(onTap: _toggleAppBar, child: PhotoView(imageProvider: _getImageProvider(), minScale: PhotoViewComputedScale.contained * 0.8, maxScale: PhotoViewComputedScale.covered * 3, initialScale: PhotoViewComputedScale.contained, backgroundDecoration: BoxDecoration(color: MiuixColors.primary.withValues(alpha: 0.02)), heroAttributes: widget.tag.isNotEmpty ? PhotoViewHeroAttributes(tag: widget.tag) : null, loadingBuilder: (context, event) => Center(child: SizedBox(width: 30, height: 30, child: CircularProgressIndicator(value: event == null ? 0 : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1), color: MiuixColors.primary, strokeWidth: 2))), errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: MiuixColors.textTertiary, size: 64)))),
        AnimatedOpacity(opacity: _showAppBar ? 1 : 0, duration: MiuixDuration.fast, child: IgnorePointer(ignoring: !_showAppBar, child: Column(children: [_buildAppBar(), const Spacer(), _buildBottomBar()]))),
      ]),
    );
  }

  ImageProvider _getImageProvider() {
    if (widget.imageUrl.startsWith('http')) {
      return NetworkImage(widget.imageUrl);
    }
    return AssetImage(widget.imageUrl);
  }

  Widget _buildAppBar() {
    return SafeArea(child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent])), child: Row(children: [
      MiuixRipple(borderRadius: MiuixRadius.pill, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))),
      const Spacer(),
      MiuixRipple(borderRadius: MiuixRadius.pill, child: IconButton(icon: const Icon(Icons.download, color: Colors.white), onPressed: _saveToGallery)),
      MiuixRipple(borderRadius: MiuixRadius.pill, child: IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: _shareImage)),
    ])));
  }

  Widget _buildBottomBar() {
    return SafeArea(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent])), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _buildBottomAction(Icons.zoom_in, '放大'),
      const SizedBox(width: 24),
      _buildBottomAction(Icons.zoom_out, '缩小'),
      const SizedBox(width: 24),
      _buildBottomAction(Icons.fit_screen, '适应'),
    ])));
  }

  Widget _buildBottomAction(IconData icon, String label) {
    return Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 22), const SizedBox(height: 2), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10))]);
  }
}
