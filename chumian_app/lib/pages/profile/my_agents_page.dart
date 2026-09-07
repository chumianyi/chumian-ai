import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_dialog.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_empty_state.dart';
import 'package:chumian_ai/widgets/miuix/miuix_avatar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_badge.dart';

/// ============================================================
/// MyAgentsPage —— 我的 Agent
/// Agent 卡片列表，编辑/发布/删除，创建入口，粉色渐变
/// ============================================================
class MyAgentsPage extends StatefulWidget {
  const MyAgentsPage({super.key});

  @override
  State<MyAgentsPage> createState() => _MyAgentsPageState();
}

class _MyAgentsPageState extends State<MyAgentsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  List<AgentItem> _agents = [];
  bool _isLoading = true;
  int _selectedFilter = 0;

  static const List<String> _filters = ['全部', '已发布', '未发布'];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _loadAgents();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _loadAgents() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _agents = [
        AgentItem(
          id: '1',
          name: '小眠助手',
          description: '温柔贴心的生活助手，擅长日常对话和情感陪伴',
          avatar: '🌸',
          category: '生活助手',
          chats: 1280,
          likes: 256,
          isPublished: true,
          gradient: [Color(0xFFFFB6C1), Color(0xFFFF69B4)],
        ),
        AgentItem(
          id: '2',
          name: '代码大师',
          description: '精通多种编程语言的技术专家，解答编程难题',
          avatar: '💻',
          category: '编程助手',
          chats: 856,
          likes: 189,
          isPublished: true,
          gradient: [Color(0xFF87CEEB), Color(0xFF4682B4)],
        ),
        AgentItem(
          id: '3',
          name: '文学少女',
          description: '热爱文学创作的文艺少女，陪你写诗作文',
          avatar: '📚',
          category: '创作助手',
          chats: 432,
          likes: 98,
          isPublished: false,
          gradient: [Color(0xFFDDA0DD), Color(0xFF9370DB)],
        ),
        AgentItem(
          id: '4',
          name: '健身教练',
          description: '专业健身指导，定制个性化训练计划',
          avatar: '💪',
          category: '健康助手',
          chats: 210,
          likes: 45,
          isPublished: false,
          gradient: [Color(0xFF98FB98), Color(0xFF3CB371)],
        ),
      ];
      _isLoading = false;
    });
  }

  List<AgentItem> get _filteredAgents {
    if (_selectedFilter == 0) return _agents;
    if (_selectedFilter == 1) {
      return _agents.where((a) => a.isPublished).toList();
    }
    return _agents.where((a) => !a.isPublished).toList();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.07, (index * 0.07) + 0.4,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.07, (index * 0.07) + 0.4,
            curve: Curves.easeOutCubic),
      ),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) => Opacity(
        opacity: anim.value,
        child: Transform.translate(offset: slide.value, child: child),
      ),
    );
  }

  void _togglePublish(AgentItem agent) {
    setState(() {
      final index = _agents.indexWhere((a) => a.id == agent.id);
      if (index != -1) {
        _agents[index] = AgentItem(
          id: agent.id,
          name: agent.name,
          description: agent.description,
          avatar: agent.avatar,
          category: agent.category,
          chats: agent.chats,
          likes: agent.likes,
          isPublished: !agent.isPublished,
          gradient: agent.gradient,
        );
      }
    });
    MiuixToast.show(
      context,
      message: agent.isPublished ? '已下架' : '已发布',
      type: MiuixToastType.success,
    );
  }

  void _deleteAgent(AgentItem agent) {
    MiuixDialog.show(
      context,
      title: '删除 Agent',
      content: '确定要删除「${agent.name}」吗？此操作不可恢复。',
      type: MiuixDialogType.warning,
      confirmText: '删除',
      onConfirm: () {
        setState(() => _agents.removeWhere((a) => a.id == agent.id));
        MiuixToast.show(context,
            message: 'Agent 已删除', type: MiuixToastType.success);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '我的 Agent',
        backgroundColor: MiuixColors.background,
        actions: [
          MiuixIconButton(
            icon: Icons.add,
            style: MiuixIconButtonStyle.filled,
            onPressed: () {
              MiuixToast.show(context,
                  message: '打开 Agent 创建页', type: MiuixToastType.info);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          _buildStatsBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation(MiuixColors.primary),
                    ),
                  )
                : _filteredAgents.isEmpty
                    ? const MiuixEmptyState(
                        title: '暂无 Agent',
                        description: '创建你的第一个专属 Agent 吧',
                        icon: Icons.smart_toy,
                        actionLabel: '创建 Agent',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredAgents.length,
                        itemBuilder: (context, index) {
                          return _buildAnimatedItem(
                            _buildAgentCard(_filteredAgents[index]),
                            index,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = _selectedFilter == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: MiuixRipple(
              borderRadius: MiuixRadius.pill,
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = index),
                child: AnimatedContainer(
                  duration: MiuixDuration.fast,
                  curve: MiuixCurves.miuixSpring,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(colors: MiuixColors.primaryGradient)
                        : null,
                    color: isSelected ? null : MiuixColors.surface,
                    borderRadius: MiuixRadius.pillRadius,
                    border: Border.all(
                      color: isSelected
                          ? MiuixColors.primary
                          : MiuixColors.borderLight,
                    ),
                  ),
                  child: Text(
                    _filters[index],
                    style: TextStyle(
                      fontSize: MiuixFontSize.sm,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : MiuixColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatsBar() {
    final published = _agents.where((a) => a.isPublished).length;
    final totalChats = _agents.fold<int>(0, (sum, a) => sum + a.chats);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Agent 总数', '${_agents.length}', Icons.smart_toy),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard('已发布', '$published', Icons.publish),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard('总对话', '$totalChats', Icons.chat),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)],
        ),
        borderRadius: MiuixRadius.mdRadius,
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: MiuixColors.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: MiuixFontSize.xl,
              fontWeight: FontWeight.bold,
              color: MiuixColors.primaryDeep,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: MiuixFontSize.xs,
              color: MiuixColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentCard(AgentItem agent) {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: agent.gradient),
                  borderRadius: MiuixRadius.lgRadius,
                  boxShadow: MiuixShadows.sm,
                ),
                child: Center(
                  child: Text(agent.avatar, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          agent.name,
                          style: const TextStyle(
                            fontSize: MiuixFontSize.lg,
                            fontWeight: FontWeight.w600,
                            color: MiuixColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (agent.isPublished)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: MiuixColors.success.withValues(alpha: 0.15),
                              borderRadius: MiuixRadius.pillRadius,
                            ),
                            child: const Text(
                              '已发布',
                              style: TextStyle(
                                fontSize: 10,
                                color: MiuixColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      agent.category,
                      style: const TextStyle(
                        fontSize: MiuixFontSize.xs,
                        color: MiuixColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              MiuixBadge(
                count: agent.likes,
                child: const Icon(Icons.favorite,
                    color: MiuixColors.primary, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            agent.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: MiuixFontSize.md,
              color: MiuixColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMiniStat(Icons.chat, '${agent.chats}'),
              const SizedBox(width: 16),
              _buildMiniStat(Icons.favorite, '${agent.likes}'),
              const Spacer(),
              MiuixIconButton(
                icon: Icons.edit,
                style: MiuixIconButtonStyle.outlined,
                size: 36,
                iconSize: 16,
                onPressed: () {
                  MiuixToast.show(context,
                      message: '编辑 ${agent.name}', type: MiuixToastType.info);
                },
              ),
              const SizedBox(width: 8),
              MiuixButton(
                label: agent.isPublished ? '下架' : '发布',
                type: agent.isPublished
                    ? MiuixButtonType.secondary
                    : MiuixButtonType.primary,
                size: MiuixButtonSize.small,
                onPressed: () => _togglePublish(agent),
              ),
              const SizedBox(width: 8),
              MiuixIconButton(
                icon: Icons.delete_outline,
                style: MiuixIconButtonStyle.ghost,
                size: 36,
                iconSize: 16,
                color: MiuixColors.error,
                onPressed: () => _deleteAgent(agent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: MiuixColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: MiuixFontSize.sm,
            color: MiuixColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class AgentItem {
  final String id;
  final String name;
  final String description;
  final String avatar;
  final String category;
  final int chats;
  final int likes;
  final bool isPublished;
  final List<Color> gradient;
  const AgentItem({
    required this.id,
    required this.name,
    required this.description,
    required this.avatar,
    required this.category,
    required this.chats,
    required this.likes,
    required this.isPublished,
    required this.gradient,
  });
}
