import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ModelStorePage extends StatefulWidget {
  const ModelStorePage({super.key});
  @override
  State<ModelStorePage> createState() => _ModelStorePageState();
}

class _ModelStorePageState extends State<ModelStorePage> {
  final List<Map<String, dynamic>> _models = [
    {'id': 'minimax-h3-full', 'name': 'MiniMax H3 满血版', 'type': '语言', 'size': '14.2 GB', 'desc': '最强开源语言模型，推理能力卓越', 'recommended': true, 'icon': Icons.psychology},
    {'id': 'deepseek-4-pro', 'name': 'DeepSeek 4 Pro', 'type': '语言', 'size': '18.5 GB', 'desc': '深度推理，代码能力顶尖', 'recommended': true, 'icon': Icons.auto_awesome},
    {'id': 'qwen-3-72b', 'name': 'Qwen3 72B', 'type': '语言', 'size': '42.0 GB', 'desc': '通义千问旗舰模型', 'recommended': false, 'icon': Icons.lightbulb},
    {'id': 'llama-4-70b', 'name': 'Llama 4 70B', 'type': '语言', 'size': '38.0 GB', 'desc': 'Meta最新开源大模型', 'recommended': false, 'icon': Icons.pets},
    {'id': 'glm-5-9b', 'name': 'GLM-5 9B', 'type': '语言', 'size': '5.4 GB', 'desc': '轻量高效，移动端友好', 'recommended': false, 'icon': Icons.bolt},
    {'id': 'phi-4-14b', 'name': 'Phi-4 14B', 'type': '语言', 'size': '8.2 GB', 'desc': '微软小模型，性能强悍', 'recommended': false, 'icon': Icons.memory},
    {'id': 'wan-2-14b-video', 'name': 'Wan 2.1 视频', 'type': '视频', 'size': '28.0 GB', 'desc': '阿里视频生成模型', 'recommended': false, 'icon': Icons.movie},
    {'id': 'hunyuan-video-13b', 'name': 'HunyuanVideo', 'type': '视频', 'size': '25.0 GB', 'desc': '腾讯视频生成大模型', 'recommended': false, 'icon': Icons.videocam},
    {'id': 'sd-3-5-large', 'name': 'SD 3.5 Large', 'type': '图像', 'size': '12.0 GB', 'desc': 'Stable Diffusion最新版', 'recommended': false, 'icon': Icons.image},
    {'id': 'flux-1-dev', 'name': 'FLUX.1 Dev', 'type': '图像', 'size': '22.0 GB', 'desc': 'Black Forest Labs图像模型', 'recommended': false, 'icon': Icons.brush},
  ];

  final Set<String> _downloaded = {};
  final Map<String, double> _progress = {};
  String _tab = '全部';

  @override
  Widget build(BuildContext context) {
    final filtered = _tab == '全部' ? _models : _models.where((m) => m['type'] == _tab).toList();
    final recommended = _models.where((m) => m['recommended'] == true).toList();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('模型商店', style: TextStyle(color: AppColors.primaryDeep, fontWeight: FontWeight.bold, fontFamily: 'LXGW WenKai'))),
      body: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['全部', '语言', '视频', '图像'].map((t) => _tabChip(t)).toList()))),
        const SizedBox(height: 12),
        if (_tab == '全部') ...[
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Align(alignment: Alignment.centerLeft, child: Text('🔥 推荐榜', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDeep, fontFamily: 'LXGW WenKai')))),
          const SizedBox(height: 8),
          SizedBox(height: 140, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: recommended.length, itemBuilder: (_, i) => _buildRecommendCard(recommended[i]))),
          const SizedBox(height: 12),
        ],
        Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: filtered.length, itemBuilder: (_, i) => _buildModelCard(filtered[i]))),
      ]),
    );
  }

  Widget _tabChip(String label) {
    final selected = _tab == label;
    return GestureDetector(
      onTap: () => setState(() => _tab = label),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: selected ? AppColors.primary : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 6)]), child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontWeight: selected ? FontWeight.w600 : FontWeight.normal, fontFamily: 'LXGW WenKai'))),
    );
  }

  Widget _buildRecommendCard(Map model) {
    return Container(width: 200, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(gradient: AppColors.primaryVibrantGradient, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(model['icon'], color: Colors.white, size: 24), const SizedBox(width: 8), Expanded(child: Text(model['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'LXGW WenKai')))]),
      const SizedBox(height: 8),
      Text(model['desc'], maxLines: 2, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'LXGW WenKai')),
      const Spacer(),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(model['size'], style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'LXGW WenKai')), _downloadButton(model)]),
    ]));
  }

  Widget _buildModelCard(Map model) {
    final id = model['id'];
    final isDownloaded = _downloaded.contains(id);
    final progress = _progress[id] ?? 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.06), blurRadius: 8)]),
      child: Column(children: [
        Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(model['icon'], color: AppColors.primary, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(model['name'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontFamily: 'LXGW WenKai')),
            const SizedBox(height: 2),
            Text('${model['type']} · ${model['size']}', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, fontFamily: 'LXGW WenKai')),
          ])),
          _downloadButton(model),
        ]),
        if (progress > 0 && progress < 1) ...[
          const SizedBox(height: 10),
          LinearProgressIndicator(value: progress, color: AppColors.primary, backgroundColor: AppColors.background, minHeight: 4, borderRadius: BorderRadius.circular(2)),
          const SizedBox(height: 4),
          Align(alignment: Alignment.centerRight, child: Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontFamily: 'LXGW WenKai'))),
        ],
      ]),
    );
  }

  Widget _downloadButton(Map model) {
    final id = model['id'];
    final isDownloaded = _downloaded.contains(id);
    final isDownloading = (_progress[id] ?? 0) > 0 && (_progress[id] ?? 0) < 1;
    return GestureDetector(
      onTap: isDownloading ? null : () => _startDownload(id),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(color: isDownloaded ? AppColors.success : AppColors.primary, borderRadius: BorderRadius.circular(16)), child: Text(isDownloaded ? '已下载' : (isDownloading ? '下载中' : '下载'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'LXGW WenKai'))),
    );
  }

  void _startDownload(String id) {
    setState(() => _progress[id] = 0.01);
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return false;
      setState(() => _progress[id] = (_progress[id]! + 0.05).clamp(0.0, 1.0));
      if (_progress[id]! >= 1.0) {
        setState(() { _downloaded.add(id); _progress.remove(id); });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('模型下载完成！')));
        return false;
      }
      return true;
    });
  }
}
