import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'chat_page.dart';

class CreativePage extends StatefulWidget {
  const CreativePage({super.key});

  @override
  State<CreativePage> createState() => _CreativePageState();
}

class _CreativePageState extends State<CreativePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _templates = [];
  List<dynamic> _agents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([ApiService.getTemplates(), ApiService.getAgents()]);
      if (mounted) {
        setState(() {
          _templates = results[0];
          _agents = results[1];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _useTemplate(dynamic t) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(initialPrompt: t['prompt'], initialModel: 'glm-4-flash')));
  }

  void _useAgent(dynamic a) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(initialPrompt: a['opening_message'] ?? '你好', initialModel: 'glm-4-flash')));
  }

  void _showCreateAgentDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final promptCtrl = TextEditingController();
    final openingCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('创建智能体'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '名称')),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: '描述')),
            const SizedBox(height: 12),
            TextField(controller: promptCtrl, maxLines: 3, decoration: const InputDecoration(labelText: '系统提示词')),
            const SizedBox(height: 12),
            TextField(controller: openingCtrl, decoration: const InputDecoration(labelText: '开场白')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(onPressed: () async {
            if (nameCtrl.text.isEmpty || promptCtrl.text.isEmpty) {
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('请填写名称和系统提示词')));
              return;
            }
            try {
              await ApiService.createAgent(name: nameCtrl.text, description: descCtrl.text, systemPrompt: promptCtrl.text, openingMessage: openingCtrl.text);
              Navigator.pop(ctx);
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('智能体创建成功')));
            } catch (e) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('创建失败: $e')));
            }
          }, child: const Text('创建')),
        ],
      ),
    );
  }

  Future<void> _publishAgent(dynamic a) async {
    try {
      await ApiService.publishAgent(a['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已发布到探索')));
        _loadData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发布失败（可能含违规内容）: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('创意'),
        bottom: TabBar(controller: _tabController, labelColor: AppTheme.primaryColor, unselectedLabelColor: AppTheme.textSecondary, indicatorColor: AppTheme.primaryColor, tabs: const [Tab(text: '模板'), Tab(text: '智能体')]),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildTemplatesTab(), _buildAgentsTab()],
      ),
    );
  }

  Widget _buildTemplatesTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadData,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.2, crossAxisSpacing: 12, mainAxisSpacing: 12),
        itemCount: _templates.length,
        itemBuilder: (context, index) {
          final t = _templates[index];
          return GestureDetector(
            onTap: () => _useTemplate(t),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t['icon'] ?? '✨', style: const TextStyle(fontSize: 28)),
                const Spacer(),
                Text(t['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(t['category'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAgentsTab() {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadData,
          child: _agents.isEmpty
              ? ListView(children: [SizedBox(height: MediaQuery.of(context).size.height * 0.3), const Center(child: Text('暂无智能体，点击右下角创建', style: TextStyle(color: AppTheme.textSecondary)))])
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _agents.length,
                  itemBuilder: (context, index) {
                    final a = _agents[index];
                    return GestureDetector(
                      onTap: () => _useAgent(a),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                        child: Row(children: [
                          Container(width: 48, height: 48, decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.15), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.smart_toy_outlined, color: AppTheme.primaryColor)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(a['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(a['description'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Row(children: [
                              Icon(Icons.favorite, size: 12, color: (a['likes'] ?? 0) > 0 ? Colors.red : AppTheme.textSecondary),
                              const SizedBox(width: 3),
                              Text('${a['likes'] ?? 0}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                              const SizedBox(width: 10),
                              Icon(Icons.download, size: 12, color: AppTheme.textSecondary),
                              const SizedBox(width: 3),
                              Text('${a['download_count'] ?? 0}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                              if (a['is_published'] == 1) ...[const SizedBox(width: 10), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: const Text('已发布', style: TextStyle(fontSize: 10, color: Colors.green)))],
                            ]),
                          ])),
                          Column(children: [
                            if (a['is_published'] != 1) GestureDetector(onTap: () => _publishAgent(a), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: const Text('发布', style: TextStyle(fontSize: 11, color: AppTheme.primaryColor)))),
                            const SizedBox(height: 6),
                            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                          ]),
                        ]),
                      ),
                    );
                  },
                ),
        ),
        Positioned(right: 16, bottom: 16, child: FloatingActionButton(onPressed: _showCreateAgentDialog, backgroundColor: AppTheme.primaryColor, child: const Icon(Icons.add, color: Colors.white))),
      ],
    );
  }
}
