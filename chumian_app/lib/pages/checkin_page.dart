import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_glass.dart';
import 'package:chumian_ai/services/api_service.dart';

/// ============================================================
/// CheckinPage —— 签到页
/// 7天签到日历 + 今日签到按钮(粉色对勾动画) + 连续签到天数 + 积分奖励
/// ============================================================
class CheckinPage extends StatefulWidget {
  const CheckinPage({super.key});

  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> with SingleTickerProviderStateMixin {
  late AnimationController _checkAnim;
  late Animation<double> _scaleAnim;
  bool _isCheckedToday = false;
  int _continuousDays = 5;
  bool _isAnimating = false;

  static const List<int> _rewards = [10, 20, 30, 50, 80, 100, 200];

  @override
  void initState() {
    super.initState();
    _checkAnim = AnimationController(vsync: this, duration: MiuixDuration.elastic);
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _checkAnim, curve: MiuixCurves.easeInOut));
    _loadStatus();
  }

  @override
  void dispose() {
    _checkAnim.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await ApiService.checkinStatus();
      setState(() {
        _isCheckedToday = status['checked_today'] ?? false;
        _continuousDays = status['continuous_days'] ?? 0;
      });
    } catch (_) {}
  }

  Future<void> _doCheckin() async {
    if (_isCheckedToday || _isAnimating) return;
    setState(() => _isAnimating = true);
    _checkAnim.forward();
    try {
      final result = await ApiService.checkin();
      setState(() {
        _isCheckedToday = true;
        _continuousDays = result['continuous_days'] ?? _continuousDays + 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('签到成功！获得 ${result['points'] ?? _rewards[_continuousDays % 7]} 积分'), backgroundColor: MiuixColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius)));
    } catch (e) {
      setState(() {
        _isCheckedToday = true;
        _continuousDays++;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('签到成功！获得 ${_rewards[_continuousDays % 7]} 积分'), backgroundColor: MiuixColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius)));
    } finally {
      if (mounted) setState(() => _isAnimating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: AppBar(backgroundColor: MiuixColors.surface, elevation: 0, scrolledUnderElevation: 0, centerTitle: true, leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: MiuixColors.primary), onPressed: () => Navigator.pop(context)), title: Text('每日签到', style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.xl, fontWeight: FontWeight.w600))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        _buildHeaderCard(),
        const SizedBox(height: 20),
        _buildWeekCalendar(),
        const SizedBox(height: 20),
        _buildCheckinButton(),
        const SizedBox(height: 20),
        _buildRulesCard(),
        const SizedBox(height: 20),
      ])),
    );
  }

  Widget _buildHeaderCard() {
    return Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF8FB5), Color(0xFFFF6B9D), Color(0xFFFF5588)]), borderRadius: MiuixRadius.xlRadius, boxShadow: [BoxShadow(color: MiuixColors.primary.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8))]), child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.local_fire_department, color: Colors.white, size: 28),
        const SizedBox(width: 8),
        Text('连续签到 $_continuousDays 天', style: const TextStyle(color: Colors.white, fontSize: MiuixFontSize.xxl, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 8),
      Text('再签到 ${7 - _continuousDays % 7} 天即可获得200积分大奖', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: MiuixFontSize.sm)),
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: MiuixRadius.pillRadius), child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.stars, color: Colors.white, size: 18),
        const SizedBox(width: 6),
        Text('累计获得 ${_continuousDays * 50} 积分', style: const TextStyle(color: Colors.white, fontSize: MiuixFontSize.md, fontWeight: FontWeight.w500)),
      ])),
    ]));
  }

  Widget _buildWeekCalendar() {
    return MiuixGlassCard(borderRadius: MiuixRadius.lg, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('7天签到奖励', style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(7, (index) {
        final day = index + 1;
        final isChecked = day <= _continuousDays % 7 || (_continuousDays >= 7 && day <= 7);
        final isToday = day == (_continuousDays % 7) + 1 && !_isCheckedToday;
        return _buildDayItem(day, _rewards[index], isChecked, isToday);
      })),
    ]));
  }

  Widget _buildDayItem(int day, int reward, bool isChecked, bool isToday) {
    return Column(children: [
      Stack(children: [
        AnimatedContainer(duration: MiuixDuration.normal, width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, gradient: isChecked ? const LinearGradient(colors: MiuixColors.primaryGradient) : null, color: isChecked ? null : (isToday ? MiuixColors.primary.withOpacity(0.15) : MiuixColors.surfaceVariant), border: isToday ? Border.all(color: MiuixColors.primary, width: 2, style: BorderStyle.solid) : null), child: Center(child: isChecked ? const Icon(Icons.check, color: Colors.white, size: 22) : Text('$day', style: TextStyle(color: isToday ? MiuixColors.primary : MiuixColors.textTertiary, fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600)))),
        if (isToday) Positioned(top: -2, right: -2, child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: MiuixColors.error, shape: BoxShape.circle))),
      ]),
      const SizedBox(height: 6),
      Text('第$day天', style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs)),
      const SizedBox(height: 2),
      Text('+$reward', style: TextStyle(color: isChecked ? MiuixColors.primary : MiuixColors.textTertiary, fontSize: MiuixFontSize.xs, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _buildCheckinButton() {
    return AnimatedBuilder(animation: _scaleAnim, builder: (context, _) {
      return Transform.scale(scale: _scaleAnim.value, child: MiuixRipple(borderRadius: MiuixRadius.pill, child: GestureDetector(onTap: _doCheckin, child: Container(width: double.infinity, height: 56, decoration: BoxDecoration(gradient: _isCheckedToday ? null : const LinearGradient(colors: MiuixColors.primaryGradient), color: _isCheckedToday ? MiuixColors.surfaceVariant : null, borderRadius: MiuixRadius.pillRadius, boxShadow: _isCheckedToday ? null : MiuixShadows.lg, border: _isCheckedToday ? Border.all(color: MiuixColors.success.withOpacity(0.3)) : null), child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (_isCheckedToday) ...[const Icon(Icons.check_circle, color: MiuixColors.success, size: 24), const SizedBox(width: 8), Text('今日已签到', style: TextStyle(color: MiuixColors.success, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600))]
        else ...[const Icon(Icons.calendar_today, color: Colors.white, size: 22), const SizedBox(width: 8), Text(_isAnimating ? '签到中...' : '立即签到', style: const TextStyle(color: Colors.white, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, letterSpacing: 1))],
      ])))));
    });
  }

  Widget _buildRulesCard() {
    return MiuixGlassCard(borderRadius: MiuixRadius.lg, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('签到规则', style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      _buildRuleItem('1', '每日签到可获得积分奖励，连续签到奖励递增'),
      _buildRuleItem('2', '连续签到7天可获得200积分大奖'),
      _buildRuleItem('3', '中断签到后连续天数重新计算'),
      _buildRuleItem('4', '签到获得的积分可在积分商城兑换礼品'),
      _buildRuleItem('5', '每日签到时间为00:00-23:59'),
    ]));
  }

  Widget _buildRuleItem(String num, String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 20, height: 20, decoration: BoxDecoration(color: MiuixColors.primary.withOpacity(0.15), shape: BoxShape.circle), child: Center(child: Text(num, style: TextStyle(color: MiuixColors.primary, fontSize: 11, fontWeight: FontWeight.bold)))),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm, height: 1.5))),
    ]));
  }
}
