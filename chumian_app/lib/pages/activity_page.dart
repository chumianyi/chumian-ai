import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pink50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('活动中心', style: AppTextStyles.headingMedium.copyWith(color: AppColors.pink600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SignInCard(),
          const SizedBox(height: 16),
          _SectionTitle(title: '热门活动'),
          const SizedBox(height: 12),
          _ActivityCard(
            title: '猜大小赢积分',
            desc: '每日参与猜大小游戏，赢取海量积分奖励',
            icon: Icons.casino,
            color: AppColors.pink400,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _ActivityCard(
            title: '连续签到',
            desc: '连续签到7天，额外获得双倍积分奖励',
            icon: Icons.calendar_today,
            color: AppColors.pink500,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _ActivityCard(
            title: '邀请好友',
            desc: '邀请好友注册，双方各得500积分',
            icon: Icons.group_add,
            color: AppColors.pink300,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.headingSmall.copyWith(color: AppColors.pink600));
  }
}

class _SignInCard extends StatefulWidget {
  @override
  State<_SignInCard> createState() => _SignInCardState();
}

class _SignInCardState extends State<_SignInCard> {
  bool _signedIn = false;
  int _streak = 3;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.pink400, AppColors.pink500]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.pink300.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('每日签到', style: AppTextStyles.headingSmall.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('已连续签到 $_streak 天', style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withOpacity(0.85))),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => _signedIn = !_signedIn),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _signedIn ? Colors.white.withOpacity(0.3) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _signedIn ? '已签到' : '立即签到',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _signedIn ? Colors.white : AppColors.pink500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final done = i < _streak;
              return Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: done ? Colors.white : Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: done
                        ? const Icon(Icons.check, color: AppColors.pink500, size: 18)
                        : Center(child: Text('${i + 1}', style: AppTextStyles.caption.copyWith(color: Colors.white))),
                  ),
                  const SizedBox(height: 4),
                  Text(['一', '二', '三', '四', '五', '六', '日'][i], style: AppTextStyles.caption.copyWith(color: Colors.white.withOpacity(0.7))),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatefulWidget {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.pink100.withOpacity(0.5), blurRadius: 8)],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: widget.color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                child: Icon(widget.icon, color: widget.color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(widget.desc, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary), maxLines: 2),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.pink300),
            ],
          ),
        ),
      ),
    );
  }
}
