import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// HotTopicsPage —— 热门话题
/// 话题卡片，热度排名，参与人数，粉色渐变
/// 点击进入话题帖子列表
/// ============================================================
class HotTopicsPage extends StatefulWidget {
  const HotTopicsPage({super.key});

  @override
  State<HotTopicsPage> createState() => _HotTopicsPageState();
}

class _HotTopicsPageState extends State<HotTopicsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  List<TopicItem> _topics = [];
  bool _isLoading = true;
  int _selectedTab = 0;

  static const List<String> _tabs = ['实时热点', '今日热议', '本周榜单'];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _loadTopics();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _loadTopics() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _topics = [
        TopicItem(
          id: '1',
          title: '初眠AI新版本发布',
          description: '初眠AI 3.0版本正式上线，全新Miuix设计语言，更流畅的交互体验',
          heat: 98562,
          posts: 1256,
          participants: 8932,
          isHot: true,
          isNew: false,
          gradient: [Color(0xFFFF6B9D), Color(0xFFFF5588)],
          icon: Icons.rocket_launch,
        ),
        TopicItem(
          id: '2',
          title: 'AI绘画创作大赛',
          description: '用初眠AI画出你心中的世界，丰厚奖品等你来拿',
          heat: 76234,
          posts: 892,
          participants: 5621,
          isHot: true,
          isNew: true,
          gradient: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
          icon: Icons.brush,
        ),
        TopicItem(
          id: '3',
          title: '我的Agent创作分享',
          description: '分享你创建的专属Agent，让更多人体验到AI的魅力',
          heat: 54321,
          posts: 678,
          participants: 3456,
          isHot: false,
          isNew: true,
          gradient: [Color(0xFF03A9F4), Color(0xFF4FC3F7)],
          icon: Icons.smart_toy,
        ),
        TopicItem(
          id: '4',
          title: 'Flutter开发技巧讨论',
          description: '交流Flutter开发中的最佳实践和性能优化技巧',
          heat: 43210,
          posts: 456,
          participants: 2345,
          isHot: false,
          isNew: false,
          gradient: [Color(0xFF4CAF50), Color(0xFF81C784)],
          icon: Icons.code,
        ),
        TopicItem(
          id: '5',
          title: '签到连续打卡挑战',
          description: '连续签到30天，赢取SVIP会员和积分奖励',
          heat: 32109,
          posts: 345,
          participants: 6789,
          isHot: false,
          isNew: false,
          gradient: [Color(0xFFFF9800), Color(0xFFFFB74D)],
          icon: Icons.calendar_today,
        ),
        TopicItem(
          id: '6',
          title: '粉色系UI设计灵感',
          description: '分享粉色系UI设计作品和灵感，打造最美界面',
          heat: 21098,
          posts: 234,
          participants: 1234,
          isHot: false,
          isNew: false,
          gradient: [Color(0xFFE91E63), Color(0xFFF06292)],
          icon: Icons.palette,
        ),
        TopicItem(
          id: '7',
          title: 'AI写作助手使用心得',
          description: '分享使用AI写作工具的经验和技巧',
          heat: 15432,
          posts: 189,
          participants: 987,
          isHot: false,
          isNew: false,
          gradient: [Color(0xFF607D8B), Color(0xFF90A4AE)],
          icon: Icons.edit,
        ),
        TopicItem(
          id: '8',
          title: '社区优秀作品展示',
          description: '展示社区用户创作的优秀内容和作品',
          heat: 12345,
          posts: 156,
          participants: 2345,
          isHot: false,
          isNew: false,
          gradient: [Color(0xFF795548), Color(0xFFA1887F)],
          icon: Icons.star,
        ),
      ];
      _isLoading = false;
    });
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.05, (index * 0.05) + 0.35,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.05, (index * 0.05) + 0.35,
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

  String _formatHeat(int heat) {
    if (heat >= 10000) return '${(heat / 10000).toStringAsFixed(1)}万';
    return heat.toString();
  }

  void _openTopic(TopicItem topic) {
    MiuixToast.show(context,
        message: '进入话题：${topic.title}', type: MiuixToastType.info);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '热门话题',
        backgroundColor: MiuixColors.background,
        actions: [
          MiuixIconButton(
            icon: Icons.refresh,
            style: MiuixIconButtonStyle.ghost,
            onPressed: _loadTopics,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(MiuixColors.primary),
                    ),
                  )
                : RefreshIndicator(
                    color: MiuixColors.primary,
                    onRefresh: _loadTopics,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _topics.length,
                      itemBuilder: (context, index) {
                        return _buildAnimatedItem(
                          _buildTopicCard(_topics[index], index),
                          index,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < 2 ? 8 : 0),
              child: MiuixRipple(
                borderRadius: MiuixRadius.pill,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = index),
                  child: AnimatedContainer(
                    duration: MiuixDuration.fast,
                    curve: MiuixCurves.miuixSpring,
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
                    child: Center(
                      child: Text(
                        _tabs[index],
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
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTopicCard(TopicItem topic, int rank) {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(0),
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => _openTopic(topic),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: MiuixRadius.lgRadius,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // 左侧渐变条
              Container(
                width: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: topic.gradient,
                  ),
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(MiuixRadius.lg)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // 排名
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: rank < 3
                                  ? LinearGradient(colors: topic.gradient)
                                  : null,
                              color: rank < 3
                                  ? null
                                  : MiuixColors.surfaceVariant,
                              borderRadius: MiuixRadius.smRadius,
                            ),
                            child: Text(
                              '${rank + 1}',
                              style: TextStyle(
                                color: rank < 3
                                    ? Colors.white
                                    : MiuixColors.textTertiary,
                                fontWeight: FontWeight.bold,
                                fontSize: MiuixFontSize.sm,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              topic.title,
                              style: const TextStyle(
                                fontSize: MiuixFontSize.md,
                                fontWeight: FontWeight.w600,
                                color: MiuixColors.textPrimary,
                              ),
                            ),
                          ),
                          if (topic.isHot)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: MiuixColors.error.withValues(alpha: 0.1),
                                borderRadius: MiuixRadius.pillRadius,
                              ),
                              child: const Text(
                                '热',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: MiuixColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (topic.isNew)
                            const SizedBox(width: 4),
                          if (topic.isNew)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: MiuixColors.success.withValues(alpha: 0.1),
                                borderRadius: MiuixRadius.pillRadius,
                              ),
                              child: const Text(
                                '新',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: MiuixColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        topic.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: MiuixFontSize.sm,
                          color: MiuixColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(topic.icon,
                              size: 14, color: MiuixColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${topic.posts} 帖子',
                            style: const TextStyle(
                              fontSize: MiuixFontSize.xs,
                              color: MiuixColors.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.people,
                              size: 14, color: MiuixColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            '${topic.participants} 参与',
                            style: const TextStyle(
                              fontSize: MiuixFontSize.xs,
                              color: MiuixColors.textTertiary,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.local_fire_department,
                              size: 14, color: MiuixColors.error),
                          const SizedBox(width: 4),
                          Text(
                            _formatHeat(topic.heat),
                            style: const TextStyle(
                              fontSize: MiuixFontSize.xs,
                              color: MiuixColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TopicItem {
  final String id;
  final String title;
  final String description;
  final int heat;
  final int posts;
  final int participants;
  final bool isHot;
  final bool isNew;
  final List<Color> gradient;
  final IconData icon;
  const TopicItem({
    required this.id,
    required this.title,
    required this.description,
    required this.heat,
    required this.posts,
    required this.participants,
    required this.isHot,
    required this.isNew,
    required this.gradient,
    required this.icon,
  });
}
