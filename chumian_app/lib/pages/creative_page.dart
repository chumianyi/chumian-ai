import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/context_ext.dart';
import '../widgets/app_card.dart';
import '../widgets/avatar.dart';
import '../widgets/feedback.dart';
import '../widgets/gradient_header.dart';
import '../widgets/buttons.dart';
import '../widgets/tiles.dart';
import '../utils/formatters.dart';
import 'chat_page.dart';
import '../utils/constants.dart';

class CreativePage extends StatefulWidget {
  const CreativePage({super.key});

  @override
  State<CreativePage> createState() => _CreativePageState();
}

class _CreativePageState extends State<CreativePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _templates = [];
  List<dynamic> _agents = [];
  bool _loading = true;
  bool _loadFailed = false;

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
    setState(() {
      _loading = _templates.isEmpty && _agents.isEmpty;
      _loadFailed = false;
    });
    try {
      final results = await Future.wait([
        ApiService.getTemplates(),
        ApiService.getAgents(),
      ]);
      if (!mounted) return;
      setState(() {
        _templates = results[0];
        _agents = results[1];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _useTemplate(dynamic t) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          initialPrompt: t['prompt'],
          initialModel: 'glm-4-flash',
        ),
      ),
    );
  }

  void _useAgent(dynamic a) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          initialPrompt: a['opening_message'] ?? '你好',
          initialModel: 'glm-4-flash',
        ),
      ),
    );
  }

  void _showCreateAgentDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final promptCtrl = TextEditingController();
    final openingCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 8,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  IconCircle(
                    icon: Icons.smart_toy_outlined,
                    size: 40,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '创建智能体',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      Text(
                        '定义角色与开场白，一键投入使用',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: '名称'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? '请填写名称' : null,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: '描述'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: promptCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: '系统提示词'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? '请填写系统提示词' : null,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: openingCtrl,
                      decoration: const InputDecoration(labelText: '开场白'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: '创建',
                  icon: Icons.add_rounded,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    try {
                      await ApiService.createAgent(
                        name: nameCtrl.text,
                        description: descCtrl.text,
                        systemPrompt: promptCtrl.text,
                        openingMessage: openingCtrl.text,
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _loadData();
                      _showSnack('智能体创建成功');
                    } catch (e) {
                      if (!ctx.mounted) return;
                      _showSnack('创建失败: ${ErrorMessages.of(e)}');
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _publishAgent(dynamic a) async {
    try {
      await ApiService.publishAgent(a['id']);
      if (!mounted) return;
      _showSnack('已发布到探索');
      _loadData();
    } catch (e) {
      if (!mounted) return;
      _showSnack('发布失败（可能含违规内容）: ${ErrorMessages.of(e)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创意'),
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(height: 44, text: '模板'),
            Tab(height: 44, text: '智能体'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildTemplatesTab(), _buildAgentsTab()],
      ),
    );
  }

  Widget _buildTemplatesTab() {
    if (_loading) return const GridSkeleton(items: 6, columns: 2);
    if (_loadFailed) {
      return ErrorRetry(message: '模板加载失败', onRetry: _loadData);
    }
    return AppRefreshable(
      onRefresh: _loadData,
      child: _templates.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.12),
                const EmptyState(
                  icon: Icons.auto_awesome_outlined,
                  title: '暂无模板',
                  subtitle: '下拉刷新看看有没有新模板',
                ),
              ],
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.95,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _templates.length,
              itemBuilder: (context, index) =>
                  _buildTemplateCard(_templates[index]),
            ),
    );
  }

  Widget _buildTemplateCard(dynamic t) {
    final colors = _templateColor(indexOf: _templates.indexOf(t));
    final category = t['category'] ?? '通用';
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _useTemplate(t),
      radius: R.allLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: colors,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _templateIcon(category),
                  size: 22,
                  color: context.onPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.colors.last.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colors.colors.last,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            t['name'] ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            t['prompt'] ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _templateColor({required int indexOf}) {
    const palette = [
      LinearGradient(colors: [Color(0xFF4D8DFF), Color(0xFF7CB4FF)]),
      LinearGradient(colors: [Color(0xFF9C6ADE), Color(0xFFC9A8F0)]),
      LinearGradient(colors: [Color(0xFF34C77B), Color(0xFF7ADBA7)]),
      LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFFFA3C4)]),
      LinearGradient(colors: [Color(0xFFF5A623), Color(0xFFFFCE7A)]),
      LinearGradient(colors: [Color(0xFF00BFC7), Color(0xFF5EDDE2)]),
    ];
    return palette[indexOf % palette.length];
  }

  IconData _templateIcon(String category) {
    if (category.contains('翻译')) return Icons.translate_rounded;
    if (category.contains('写作') || category.contains('文案')) {
      return Icons.edit_note_rounded;
    }
    if (category.contains('代码') || category.contains('编程')) {
      return Icons.code_rounded;
    }
    if (category.contains('学习')) return Icons.school_rounded;
    if (category.contains('情感') || category.contains('聊天')) {
      return Icons.favorite_rounded;
    }
    if (category.contains('商务') || category.contains('职场')) {
      return Icons.work_rounded;
    }
    return Icons.auto_awesome_rounded;
  }

  Widget _buildAgentsTab() {
    if (_loading) return const ListSkeleton(items: 5);
    if (_loadFailed) {
      return ErrorRetry(message: '智能体加载失败', onRetry: _loadData);
    }
    return Stack(
      children: [
        AppRefreshable(
          onRefresh: _loadData,
          child: _agents.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.12,
                    ),
                    const EmptyState(
                      icon: Icons.smart_toy_outlined,
                      title: '暂无智能体',
                      subtitle: '点击右下角按钮创建你的第一个智能体',
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                  itemCount: _agents.length,
                  itemBuilder: (context, index) =>
                      _buildAgentCard(_agents[index]),
                ),
        ),
        Positioned(
          right: 20,
          bottom: 24,
          child: FloatingActionButton.extended(
            onPressed: _showCreateAgentDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('创建'),
          ),
        ),
      ],
    );
  }

  Widget _buildAgentCard(dynamic a) {
    final name = a['name'] ?? '未命名智能体';
    final published = a['is_published'] == 1;
    final likes = a['likes'] ?? 0;
    final downloads = a['download_count'] ?? 0;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      onTap: () => _useAgent(a),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: context.vibrantGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.smart_toy_outlined,
                size: 24,
                color: context.onPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (published)
                        PillTag(
                          text: '已发布',
                          icon: Icons.check_circle_rounded,
                          color: context.success,
                          fontSize: 10,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    a['description'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _miniStat(
                        context,
                        Icons.favorite_rounded,
                        Formatters.compactNumber(likes),
                        context.danger,
                      ),
                      const SizedBox(width: 14),
                      _miniStat(
                        context,
                        Icons.download_rounded,
                        Formatters.compactNumber(downloads),
                        context.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!published)
                  GestureDetector(
                    onTap: () => _publishAgent(a),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: context.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '发布',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.primary,
                        ),
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.verified_rounded,
                    size: 18,
                    color: context.success,
                  ),
                const SizedBox(height: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: context.textTertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11.5, color: color),
        ),
      ],
    );
  }
}
