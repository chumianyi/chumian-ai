import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/context_ext.dart';
import '../widgets/app_card.dart';
import '../widgets/feedback.dart';
import '../widgets/buttons.dart';
import '../utils/constants.dart';

class CheckinPage extends StatefulWidget {
  const CheckinPage({super.key});
  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
  bool _loading = true;
  bool _loadFailed = false;
  bool _checkedToday = false;
  int _streak = 0;
  List<dynamic> _history = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _history.isEmpty;
      _loadFailed = false;
    });
    try {
      final data = await ApiService.checkinStatus();
      if (!mounted) return;
      setState(() {
        _checkedToday = data['checked_today'] == true;
        _streak = data['current_streak'] ?? 0;
        _history = data['history'] ?? [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _checkin() async {
    setState(() => _submitting = true);
    try {
      final result = await ApiService.checkin();
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF5A623), Color(0xFFF7C948)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              const Text('签到成功'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+${result['premium_points']}',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFF5A623),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '获得高级积分',
                style: TextStyle(fontSize: 13, color: ctx.textSecondary),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_fire_department_rounded, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    '连续签到 ${result['streak']} 天',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Center(
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('太棒了'),
              ),
            ),
          ],
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('签到失败: ${ErrorMessages.of(e)}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('每日签到')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const ListSkeleton(items: 3);
    if (_loadFailed) {
      return ErrorRetry(message: '签到数据加载失败', onRetry: _load);
    }
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final checkedDates = _history
        .map((h) => h['checkin_date']?.toString().substring(8, 10))
        .toSet();

    return AppRefreshable(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      '连续签到 $_streak 天',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '每天签到可获得 3~10 高级积分，连续7天额外奖励20高级积分',
                  style: TextStyle(fontSize: 13, color: context.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: _checkedToday ? '今日已签到' : '立即签到',
                  icon: _checkedToday
                      ? Icons.check_circle_rounded
                      : Icons.event_available_rounded,
                  loading: _submitting,
                  height: 52,
                  onPressed: (!_checkedToday && !_submitting) ? _checkin : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 20, color: context.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${now.year}年${now.month}月',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '已签到 ${checkedDates.length} 天',
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: daysInMonth,
                  itemBuilder: (ctx, i) {
                    final day = i + 1;
                    final isChecked = checkedDates.contains(day.toString().padLeft(2, '0'));
                    final isToday = day == now.day;
                    return Container(
                      decoration: BoxDecoration(
                        color: isChecked
                            ? const Color(0xFFF5A623).withValues(alpha: 0.18)
                            : isToday
                                ? context.primary.withValues(alpha: 0.12)
                                : context.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: isToday
                            ? Border.all(color: context.primary, width: 1.2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 13,
                          color: isChecked
                              ? const Color(0xFFF5A623)
                              : isToday
                                  ? context.primary
                                  : context.textSecondary,
                          fontWeight: isChecked || isToday
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
