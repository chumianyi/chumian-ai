import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_progress.dart';

/// ============================================================
/// TaskCenterPage —— 任务中心
/// 每日任务/成就任务列表，任务进度条，领取奖励按钮
/// 粉色卡片，积分奖励
/// ============================================================
class TaskCenterPage extends StatefulWidget {
  const TaskCenterPage({super.key});

  @override
  State<TaskCenterPage> createState() => _TaskCenterPageState();
}

class _TaskCenterPageState extends State<TaskCenterPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  int _selectedTab = 0;
  int _totalPoints = 1280;
  bool _isClaiming = false;

  static const List<String> _tabs = ['每日任务', '成就任务'];

  final List<TaskItem> _dailyTasks = [
    TaskItem(id: '1', title: '每日签到', desc: '完成每日签到', icon: Icons.calendar_today, current: 1, target: 1, points: 10, completed: true, claimed: true),
    TaskItem(id: '2', title: 'AI对话', desc: '与AI对话3次', icon: Icons.chat, current: 2, target: 3, points: 15, completed: false, claimed: false),
    TaskItem(id: '3', title: '浏览社区', desc: '浏览10篇帖子', icon: Icons.explore, current: 10, target: 10, points: 20, completed: true, claimed: false),
    TaskItem(id: '4', title: '发布帖子', desc: '发布1篇帖子', icon: Icons.edit, current: 0, target: 1, points: 30, completed: false, claimed: false),
    TaskItem(id: '5', title: 'AI绘画', desc: '使用AI绘画1次', icon: Icons.brush, current: 0, target: 1, points: 25, completed: false, claimed: false),
    TaskItem(id: '6', title: '分享内容', desc: '分享内容给好友', icon: Icons.share, current: 0, target: 1, points: 15, completed: false, claimed: false),
  ];

  final List<TaskItem> _achievementTasks = [
    TaskItem(id: 'a1', title: '初来乍到', desc: '完成注册', icon: Icons.emoji_events, current: 1, target: 1, points: 100, completed: true, claimed: true),
    TaskItem(id: 'a2', title: '对话达人', desc: '累计对话100次', icon: Icons.chat_bubble, current: 45, target: 100, points: 200, completed: false, claimed: false),
    TaskItem(id: 'a3', title: '创作新星', desc: '发布10篇帖子', icon: Icons.create, current: 3, target: 10, points: 300, completed: false, claimed: false),
    TaskItem(id: 'a4', title: '签到达人', desc: '连续签到30天', icon: Icons.local_fire_department, current: 7, target: 30, points: 500, completed: false, claimed: false),
    TaskItem(id: 'a5', title: '社交蝴蝶', desc: '关注50位用户', icon: Icons.people, current: 23, target: 50, points: 150, completed: false, claimed: false),
    TaskItem(id: 'a6', title: '绘画大师', desc: '生成100张AI图片', icon: Icons.image, current: 12, target: 100, points: 400, completed: false, claimed: false),
    TaskItem(id: 'a7', title: 'SVIP会员', desc: '开通SVIP会员', icon: Icons.workspace_premium, current: 0, target: 1, points: 1000, completed: false, claimed: false),
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  List<TaskItem> get _currentTasks =>
      _selectedTab == 0 ? _dailyTasks : _achievementTasks;

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.05, (index * 0.05) + 0.35,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0.04, 0),
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

  Future<void> _claimReward(TaskItem task) async {
    setState(() => _isClaiming = true);
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      task.claimed = true;
      _totalPoints += task.points;
      _isClaiming = false;
    });
    MiuixToast.show(context,
        message: '领取成功 +${task.points} 积分', type: MiuixToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '任务中心',
        backgroundColor: MiuixColors.background,
      ),
      body: Column(
        children: [
          _buildPointsHeader(),
          _buildTabBar(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _currentTasks.length,
              itemBuilder: (context, index) {
                return _buildAnimatedItem(
                  _buildTaskCard(_currentTasks[index]),
                  index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8FB5), Color(0xFFFF6B9D), Color(0xFFFF5588)],
        ),
        borderRadius: MiuixRadius.xlRadius,
        boxShadow: MiuixShadows.md,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: MiuixRadius.lgRadius,
            ),
            child: const Icon(Icons.stars, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '我的积分',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: MiuixFontSize.sm,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_totalPoints',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '今日可领 +${_getClaimablePoints()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: MiuixFontSize.sm,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              MiuixButton(
                label: '去兑换',
                type: MiuixButtonType.secondary,
                size: MiuixButtonSize.small,
                onPressed: () {
                  MiuixToast.show(context,
                      message: '打开积分商城', type: MiuixToastType.info);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getClaimablePoints() {
    return _currentTasks
        .where((t) => t.completed && !t.claimed)
        .fold(0, (sum, t) => sum + t.points);
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < 1 ? 10 : 0),
              child: MiuixRipple(
                borderRadius: MiuixRadius.md,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = index),
                  child: AnimatedContainer(
                    duration: MiuixDuration.fast,
                    curve: MiuixCurves.miuixSpring,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(colors: MiuixColors.primaryGradient)
                          : null,
                      color: isSelected ? null : MiuixColors.surface,
                      borderRadius: MiuixRadius.mdRadius,
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
                          fontSize: MiuixFontSize.md,
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

  Widget _buildTaskCard(TaskItem task) {
    final progress = (task.current / task.target).clamp(0.0, 1.0);
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: task.completed
                  ? const LinearGradient(colors: MiuixColors.primaryGradient)
                  : LinearGradient(
                      colors: [
                        MiuixColors.primaryLight.withValues(alpha: 0.3),
                        MiuixColors.primary.withValues(alpha: 0.2),
                      ],
                    ),
              borderRadius: MiuixRadius.lgRadius,
            ),
            child: Icon(
              task.icon,
              color: task.completed ? Colors.white : MiuixColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: MiuixFontSize.md,
                          fontWeight: FontWeight.w600,
                          color: MiuixColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: MiuixColors.primaryLight.withValues(alpha: 0.15),
                        borderRadius: MiuixRadius.pillRadius,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars,
                              size: 12, color: MiuixColors.primary),
                          const SizedBox(width: 2),
                          Text(
                            '+${task.points}',
                            style: const TextStyle(
                              fontSize: MiuixFontSize.xs,
                              color: MiuixColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  task.desc,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.xs,
                    color: MiuixColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: MiuixRadius.pillRadius,
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: MiuixColors.surfaceVariant,
                          valueColor: const AlwaysStoppedAnimation(
                              MiuixColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${task.current}/${task.target}',
                      style: const TextStyle(
                        fontSize: MiuixFontSize.xs,
                        color: MiuixColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          task.claimed
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: MiuixColors.success.withValues(alpha: 0.1),
                    borderRadius: MiuixRadius.pillRadius,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check,
                          size: 14, color: MiuixColors.success),
                      SizedBox(width: 4),
                      Text(
                        '已领取',
                        style: TextStyle(
                          fontSize: MiuixFontSize.xs,
                          color: MiuixColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : task.completed
                  ? MiuixButton(
                      label: '领取',
                      type: MiuixButtonType.primary,
                      size: MiuixButtonSize.small,
                      onPressed: () => _claimReward(task),
                    )
                  : MiuixButton(
                      label: '去完成',
                      type: MiuixButtonType.secondary,
                      size: MiuixButtonSize.small,
                      onPressed: () {
                        MiuixToast.show(context,
                            message: '前往完成任务', type: MiuixToastType.info);
                      },
                    ),
        ],
      ),
    );
  }
}

class TaskItem {
  final String id;
  final String title;
  final String desc;
  final IconData icon;
  final int current;
  final int target;
  final int points;
  bool completed;
  bool claimed;
  TaskItem({
    required this.id,
    required this.title,
    required this.desc,
    required this.icon,
    required this.current,
    required this.target,
    required this.points,
    required this.completed,
    required this.claimed,
  });
}
