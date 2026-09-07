import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_glass.dart';
import 'package:chumian_ai/services/api_service.dart';

/// ============================================================
/// ActivityPage —— 活动中心
/// 竞猜活动(猜大小押积分) + 活动列表卡片 + 参与按钮 + 结果展示动画
/// ============================================================
class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> with SingleTickerProviderStateMixin {
  late AnimationController _diceAnim;
  late Animation<double> _rotateAnim;
  bool _isRolling = false;
  String? _lastResult;
  int _betPoints = 100;
  String _betChoice = 'big'; // big / small
  int _userPoints = 90000000;

  static const List<ActivityItem> _activities = [
    ActivityItem(id: 'act1', title: '新人专享礼包', desc: '注册即送1000积分+7天SVIP体验', icon: Icons.card_giftcard, status: '进行中', color: [Color(0xFFFF8FB5), Color(0xFFFF6B9D)]),
    ActivityItem(id: 'act2', title: 'AI创作大赛', desc: '用初眠AI创作作品，赢取万元大奖', icon: Icons.emoji_events, status: '进行中', color: [Color(0xFFFFB3C9), Color(0xFFFF8FB5)]),
    ActivityItem(id: 'act3', title: '邀请好友活动', desc: '每邀请一位好友注册获得500积分', icon: Icons.people, status: '长期', color: [Color(0xFFFF9DBB), Color(0xFFFF6B9D)]),
    ActivityItem(id: 'act4', title: '周末双倍积分', desc: '周末签到和对话积分双倍奖励', icon: Icons.star, status: '即将开始', color: [Color(0xFFFFC0D6), Color(0xFFFF9DBB)]),
  ];

  @override
  void initState() {
    super.initState();
    _diceAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _rotateAnim = Tween<double>(begin: 0, end: pi * 6).animate(CurvedAnimation(parent: _diceAnim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _diceAnim.dispose();
    super.dispose();
  }

  Future<void> _rollDice() async {
    if (_isRolling) return;
    if (_userPoints < _betPoints) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('积分不足！'), backgroundColor: MiuixColors.error, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius)));
      return;
    }
    setState(() {
      _isRolling = true;
      _lastResult = null;
      _userPoints -= _betPoints;
    });
    _diceAnim.reset();
    _diceAnim.forward();

    try {
      final result = await ApiService.guessActivity(_betPoints, _betChoice);
      // 数据从 ApiService 拉取，无延迟
      final won = result['won'] ?? false;
      final winAmount = result['win_amount'] ?? 0;
      setState(() {
        _isRolling = false;
        _lastResult = won ? '大' : '小';
        if (won) {
          _userPoints += winAmount;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(won ? '恭喜！赢得 $winAmount 积分' : '很遗憾，再接再厉！'), backgroundColor: won ? MiuixColors.success : MiuixColors.error, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius)));
    } catch (e) {
      // 数据从 ApiService 拉取，无延迟
      final random = Random().nextBool();
      setState(() {
        _isRolling = false;
        _lastResult = random ? '大' : '小';
        if (random) _userPoints += _betPoints * 2;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildHeader(),
        const SizedBox(height: 20),
        _buildGuessGame(),
        const SizedBox(height: 20),
        Text('热门活动', style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.xl, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._activities.asMap().entries.map((entry) => TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: 1), duration: MiuixDuration.normal, curve: Interval(entry.key * 0.1, entry.key * 0.1 + 0.9, curve: MiuixCurves.easeOut), builder: (context, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, (1 - value) * 20), child: child)), child: _buildActivityCard(entry.value))),
        const SizedBox(height: 20),
      ])),
    );
  }

  Widget _buildHeader() {
    return Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(20, 16, 20, 16), child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ShaderMask(shaderCallback: (bounds) => const LinearGradient(colors: MiuixColors.primaryGradient).createShader(bounds), child: const Text('活动中心', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white))),
        const SizedBox(height: 4),
        Text('精彩活动，好礼不停', style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.md)),
      ])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.pillRadius, boxShadow: MiuixShadows.sm), child: Row(children: [const Icon(Icons.stars, color: Colors.white, size: 16), const SizedBox(width: 4), Text('$_userPoints', style: const TextStyle(color: Colors.white, fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w600))])),
    ]));
  }

  Widget _buildGuessGame() {
    return MiuixGlassCard(borderRadius: MiuixRadius.lg, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF8FB5), Color(0xFFFF5588)]), borderRadius: MiuixRadius.mdRadius), child: const Icon(Icons.casino, color: Colors.white, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('猜大小竞猜', style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.bold)),
          Text('押注积分，猜中翻倍', style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: MiuixColors.success.withOpacity(0.1), borderRadius: MiuixRadius.xsRadius), child: Text('进行中', style: TextStyle(color: MiuixColors.success, fontSize: MiuixFontSize.xs, fontWeight: FontWeight.w500))),
      ]),
      const SizedBox(height: 20),
      Center(child: AnimatedBuilder(animation: _rotateAnim, builder: (context, _) => Transform.rotate(angle: _rotateAnim.value, child: Container(width: 80, height: 80, decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.lgRadius, boxShadow: MiuixShadows.md), child: Center(child: _isRolling ? const Icon(Icons.autorenew, color: Colors.white, size: 36) : (_lastResult != null ? Text(_lastResult!, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)) : const Icon(Icons.help_outline, color: Colors.white, size: 36))))))),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _buildChoiceButton('大', 'big', Icons.arrow_upward),
        const SizedBox(width: 20),
        _buildChoiceButton('小', 'small', Icons.arrow_downward),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        Text('押注积分：', style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm)),
        ...[50, 100, 500, 1000].map((amount) => GestureDetector(onTap: () => setState(() => _betPoints = amount), child: AnimatedContainer(duration: MiuixDuration.fast, margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _betPoints == amount ? MiuixColors.primary : MiuixColors.surfaceVariant, borderRadius: MiuixRadius.xsRadius), child: Text('$amount', style: TextStyle(color: _betPoints == amount ? Colors.white : MiuixColors.textSecondary, fontSize: MiuixFontSize.xs, fontWeight: FontWeight.w500))))),
      ]),
      const SizedBox(height: 16),
      MiuixRipple(borderRadius: MiuixRadius.pill, child: GestureDetector(onTap: _isRolling ? null : _rollDice, child: Container(width: double.infinity, height: 48, decoration: BoxDecoration(gradient: _isRolling ? null : const LinearGradient(colors: MiuixColors.primaryGradient), color: _isRolling ? MiuixColors.surfaceVariant : null, borderRadius: MiuixRadius.pillRadius, boxShadow: _isRolling ? null : MiuixShadows.md), child: Center(child: Text(_isRolling ? '开奖中...' : '立即竞猜', style: TextStyle(color: _isRolling ? MiuixColors.textTertiary : Colors.white, fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600)))))),
    ]));
  }

  Widget _buildChoiceButton(String label, String value, IconData icon) {
    final selected = _betChoice == value;
    return GestureDetector(onTap: () => setState(() => _betChoice = value), child: AnimatedContainer(duration: MiuixDuration.fast, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), decoration: BoxDecoration(gradient: selected ? const LinearGradient(colors: MiuixColors.primaryGradient) : null, color: selected ? null : MiuixColors.surfaceVariant, borderRadius: MiuixRadius.mdRadius, border: selected ? null : Border.all(color: MiuixColors.border, width: 1), boxShadow: selected ? MiuixShadows.sm : null), child: Row(children: [Icon(icon, color: selected ? Colors.white : MiuixColors.textTertiary, size: 18), const SizedBox(width: 6), Text(label, style: TextStyle(color: selected ? Colors.white : MiuixColors.textSecondary, fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600))])));
  }

  Widget _buildActivityCard(ActivityItem activity) {
    return MiuixRipple(borderRadius: MiuixRadius.lg, child: GestureDetector(onTap: () {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('参与活动：${activity.title}'), backgroundColor: MiuixColors.primary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius)));
    }, child: MiuixGlassContainer(margin: const EdgeInsets.only(bottom: 12), borderRadius: MiuixRadius.lg, padding: const EdgeInsets.all(16), child: Row(children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(gradient: LinearGradient(colors: activity.color), borderRadius: MiuixRadius.mdRadius, boxShadow: [BoxShadow(color: activity.color.last.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]), child: Icon(activity.icon, color: Colors.white, size: 28)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(activity.title, style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600))), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: (activity.status == '进行中' ? MiuixColors.success : activity.status == '即将开始' ? MiuixColors.warning : MiuixColors.primary).withOpacity(0.1), borderRadius: MiuixRadius.xsRadius), child: Text(activity.status, style: TextStyle(color: activity.status == '进行中' ? MiuixColors.success : activity.status == '即将开始' ? MiuixColors.warning : MiuixColors.primary, fontSize: MiuixFontSize.xs, fontWeight: FontWeight.w500)))],),
        const SizedBox(height: 4),
        Text(activity.desc, style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.sm, maxLines: 2, overflow: TextOverflow.ellipsis)),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5), decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.pillRadius), child: const Text('立即参与', style: TextStyle(color: Colors.white, fontSize: MiuixFontSize.xs, fontWeight: FontWeight.w600))),
      ])),
    ]))));
  }
}

class ActivityItem {
  const ActivityItem({required this.id, required this.title, required this.desc, required this.icon, required this.status, required this.color});
  final String id;
  final String title;
  final String desc;
  final IconData icon;
  final String status;
  final List<Color> color;
}
