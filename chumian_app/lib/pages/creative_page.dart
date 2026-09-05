import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';

class CreativePage extends StatefulWidget {
  const CreativePage({super.key});
  @override
  State<CreativePage> createState() => _CreativePageState();
}

class _CreativePageState extends State<CreativePage> {
  final _promptCtrl = TextEditingController();
  String? _generatedImage;
  bool _generating = false;

  Future<void> _generate() async {
    if (_promptCtrl.text.trim().isEmpty) return;
    setState(() => _generating = true);
    try {
      final url = await ApiService().generateImage(_promptCtrl.text.trim());
      setState(() => _generatedImage = url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('生成失败：$e')));
    }
    setState(() => _generating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('AI创作', style: TextStyle(color: AppColors.primaryDeep, fontWeight: FontWeight.bold, fontFamily: 'LXGW WenKai'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _buildCategoryCard('图片生成', Icons.image_outlined, '用文字描述你想要的画面', () => _showImageGen()),
          const SizedBox(height: 12),
          _buildCategoryCard('视频生成', Icons.movie_outlined, 'AI生成动态视频内容', () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('视频生成功能开发中')))),
          const SizedBox(height: 12),
          _buildCategoryCard('智能体', Icons.smart_toy_outlined, '创建和管理专属AI智能体', () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('智能体管理开发中')))),
          const SizedBox(height: 24),
          if (_generatedImage != null) ...[
            const Text('生成结果', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDeep, fontFamily: 'LXGW WenKai')),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(_generatedImage!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 200, color: AppColors.surfaceVariant, child: const Center(child: Icon(Icons.broken_image, color: AppColors.textHint))))),
          ],
        ]),
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, String desc, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Row(children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: Colors.white, size: 26)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontFamily: 'LXGW WenKai')),
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'LXGW WenKai')),
          ])),
          const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ]),
      ),
    );
  }

  void _showImageGen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('图片生成', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDeep, fontFamily: 'LXGW WenKai')),
            const SizedBox(height: 16),
            TextField(
              controller: _promptCtrl,
              maxLines: 3,
              decoration: InputDecoration(hintText: '描述你想要的图片...', filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 16),
            if (_generating) const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else GestureDetector(
              onTap: () { _generate(); Navigator.pop(ctx); },
              child: Container(height: 50, decoration: BoxDecoration(gradient: AppColors.primaryVibrantGradient, borderRadius: BorderRadius.circular(25)), child: const Center(child: Text('开始生成', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'LXGW WenKai')))),
            ),
          ]),
        ),
      ),
    );
  }
}
