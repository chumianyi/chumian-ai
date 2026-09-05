import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});
  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  bool _checkedIn = false;
  int _points = 0;
  String? _guessResult;
  bool _guessing = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await ApiService().getCheckinStatus();
      setState(() { _checkedIn = status['checked_in'] ?? false; _points = status['points'] ?? 0; });
    } catch (_) {}
  }

  Future<void> _checkin() async {
    try {
      final result = await ApiService().checkin();
      setState(() { _checkedIn = true; _points = result['points'] ?? _points; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('签到成功，获得${result['points_earned'] ?? 10}积分！')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('签到失败：$e')));
    }
  }

  Future<void> _guess(bool isBig) async {
    setState(() => _guessing = true);
    try {
      final result = await ApiService().guess(isBig);
      setState(() => _guessResult = result['message'] ?? (result['win'] ? '猜对了！' : '猜错了'));
    } catch (e) {
      setState(() => _guessResult = '出错了');
    }
    setState(() => _guessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('活动中心', style: TextStyle(color: AppColors.primaryDeep, fontWeight: FontWeight.bold, fontFamily: 'LXGW WenKai'))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildPointsCard(user),
        const SizedBox(height: 16),
        _buildCheckinCard(),
        const SizedBox(height: 16),
        _buildGuessCard(),
      ])),
    );
  }

  Widget _buildPointsCard(user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: AppColors.primaryVibrantGradient, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))]),
      child: Row(children: [
        const Icon(Icons.stars, color: Colors.white, size: 40),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${user?.dailyPoints ?? 0}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'LXGW WenKai')),
          const Text('我的积分', style: TextStyle(fontSize: 14, color: Colors.white70, fontFamily: 'LXGW WenKai')),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Text(user?.svipType == 'none' ? '普通用户' : 'SVIP', style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'LXGW WenKai'))),
      ]),
    );
  }

  Widget _buildCheckinCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 12)]),
      child: Row(children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.calendar_today, color: AppColors.primary, size: 28)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('每日签到', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontFamily: 'LXGW WenKai')),
          const SizedBox(height: 4),
          Text(_checkedIn ? '今日已签到，明天继续哦～' : '签到领取积分，连续签到有惊喜', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'LXGW WenKai')),
        ])),
        GestureDetector(
          onTap: _checkedIn ? null : _checkin,
          child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: _checkedIn ? AppColors.textHint : AppColors.primary, borderRadius: BorderRadius.circular(20)), child: Text(_checkedIn ? '已签到' : '签到', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'LXGW WenKai'))),
        ),
      ]),
    );
  }

  Widget _buildGuessCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 12)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.casino, color: AppColors.accent, size: 24)),
          const SizedBox(width: 12),
          const Text('猜大小', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontFamily: 'LXGW WenKai')),
        ]),
        const SizedBox(height: 16),
        if (_guessResult != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_guessResult!, style: const TextStyle(fontSize: 15, color: AppColors.primary, fontWeight: FontWeight.w600, fontFamily: 'LXGW WenKai'))),
        Row(children: [
          Expanded(child: GestureDetector(onTap: _guessing ? null : () => _guess(true), child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primary.withOpacity(0.3))), child: const Center(child: Text('大', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'LXGW WenKai')))))),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(onTap: _guessing ? null : () => _guess(false), child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.accent.withOpacity(0.3))), child: const Center(child: Text('小', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accent, fontFamily: 'LXGW WenKai')))))),
        ]),
        if (_guessing) const Padding(padding: EdgeInsets.only(top: 12), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))),
      ]),
    );
  }
}
