import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_glass.dart';
import 'package:chumian_ai/providers/user_provider.dart';
import 'package:chumian_ai/pages/checkin_page.dart';
import 'package:chumian_ai/pages/shop_page.dart';

/// ============================================================
/// PointsPage —— 积分中心
/// 积分余额大数字 + 积分明细 + 获取途径 + 签到入口 + 兑换入口
/// ============================================================
class PointsPage extends StatefulWidget {
  const PointsPage({super.key});

  @override
  State<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends State<PointsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _numberAnim;
  final List<PointLog> _logs = [];
  bool _isLoading = true;

  static const List<EarnWay> _earnWays = [
    EarnWay(icon: Icons.check_circle_outline, title: '每日签到', desc: '每天签到获得积分', points: '+10~100'),
    EarnWay(icon: Icons.chat_bubble_outline, title: 'AI对话', desc: '使用AI对话获得积分', points: '+5/次'),
    EarnWay(icon: Icons.create_outlined, title: '发布帖子', desc: '在社区发布内容', points: '+20/篇'),
    EarnWay(icon: Icons.people_outline, title: '邀请好友', desc: '邀请好友注册', points: '+500/人'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: MiuixDuration.elastic);
    _numberAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: MiuixCurves.miuixSpring));
    _controller.forward();
    _loadLogs();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() {
      _logs.addAll([
        PointLog(title: '每日签到', points: 50, time: DateTime.now().subtract(const Duration(hours: 2)), type: 'earn'),
        PointLog(title: 'AI对话奖励', points: 5, time: DateTime.now().subtract(const Duration(hours: 5)), type: 'earn'),
        PointLog(title: '兑换SVIP月卡', points: -5000, time: DateTime.now().subtract(const Duration(days: 1)), type: 'spend'),
        PointLog(title: '发布帖子', points: 20, time: DateTime.now().subtract(const Duration(days: 1)), type: 'earn'),
        PointLog(title: '邀请好友', points: 500, time: DateTime.now().subtract(const Duration(days: 2)), type: 'earn'),
        PointLog(title: '兑换积分包', points: -1000, time: DateTime.now().subtract(const Duration(days: 3)), type: 'spend'),
        PointLog(title: '连续签到奖励', points: 100, time: DateTime.now().subtract(const Duration(days: 3)), type: 'earn'),
      ]);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: MiuixColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPointsHeader(userProvider.dailyPoints),
            const SizedBox(height: 16),
            _buildActionRow(),
            const SizedBox(height: 16),
            _buildEarnWays(),
            const SizedBox(height: 16),
            _buildPointsLog(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsHeader(int points) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8FB5), Color(0xFFFF6B9D), Color(0xFFFF5588)],
        ),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(MiuixRadius.xxl), bottomRight: Radius.circular(MiuixRadius.xxl)),
      ),
      child: Column(
        children: [
          const Text('我的积分', style: TextStyle(color: Colors.white, fontSize: MiuixFontSize.md)),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _numberAnim,
            builder: (context, _) {
              return Text(
                (points * _numberAnim.value).toInt().toString(),
                style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 2),
              );
            },
          ),
          const SizedBox(height: 4),
          Text('积分可兑换SVIP会员和精美礼品', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: MiuixFontSize.sm)),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildActionCard(Icons.check_circle, '每日签到', '签到领积分', () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckinPage()));
          })),
          const SizedBox(width: 12),
          Expanded(child: _buildActionCard(Icons.card_giftcard, '积分兑换', '好礼换不停', () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShopPage()));
          })),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return MiuixRipple(
      borderRadius: MiuixRadius.lg,
      child: GestureDetector(
        onTap: onTap,
        child: MiuixGlassContainer(
          borderRadius: MiuixRadius.lg,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.mdRadius), child: Icon(icon, color: Colors.white, size: 24)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEarnWays() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MiuixGlassCard(
        borderRadius: MiuixRadius.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('获取积分', style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._earnWays.map((way) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: MiuixColors.primary.withValues(alpha: 0.1), borderRadius: MiuixRadius.smRadius), child: Icon(way.icon, color: MiuixColors.primary, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(way.title, style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.md, fontWeight: FontWeight.w500)),
                    Text(way.desc, style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs)),
                  ])),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: MiuixColors.success.withValues(alpha: 0.1), borderRadius: MiuixRadius.xsRadius), child: Text(way.points, style: TextStyle(color: MiuixColors.success, fontSize: MiuixFontSize.xs, fontWeight: FontWeight.w600))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsLog() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MiuixGlassCard(
        borderRadius: MiuixRadius.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('积分明细', style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: MiuixColors.primary)))
            else if (_logs.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('暂无积分记录', style: TextStyle(color: MiuixColors.textTertiary))))
            else
              ..._logs.asMap().entries.map((entry) {
                final log = entry.value;
                final isLast = entry.key == _logs.length - 1;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                  child: Row(
                    children: [
                      Container(width: 36, height: 36, decoration: BoxDecoration(color: (log.type == 'earn' ? MiuixColors.success : MiuixColors.error).withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(log.type == 'earn' ? Icons.add : Icons.remove, color: log.type == 'earn' ? MiuixColors.success : MiuixColors.error, size: 18)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(log.title, style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.md)),
                        Text(_formatTime(log.time), style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs)),
                      ])),
                      Text('${log.points > 0 ? '+' : ''}${log.points}', style: TextStyle(color: log.points > 0 ? MiuixColors.success : MiuixColors.error, fontSize: MiuixFontSize.md, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }
}

class PointLog {
  PointLog({required this.title, required this.points, required this.time, required this.type});
  final String title;
  final int points;
  final DateTime time;
  final String type;
}

class EarnWay {
  const EarnWay({required this.icon, required this.title, required this.desc, required this.points});
  final IconData icon;
  final String title;
  final String desc;
  final String points;
}
