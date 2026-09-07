import 'package:flutter/material.dart';
import 'package:chumian_ai/services/api_service.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// SigninCalendarPage —— 签到日历
/// 月历视图，已签到日期标记，连续签到天数
/// 补签功能，粉色主题，签到动画
/// ============================================================
class SigninCalendarPage extends StatefulWidget {
  const SigninCalendarPage({super.key});

  @override
  State<SigninCalendarPage> createState() => _SigninCalendarPageState();
}

class _SigninCalendarPageState extends State<SigninCalendarPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _signinController;

  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Set<int> _signedDays = {};
  int _continuousDays = 7;
  int _totalDays = 45;
  bool _isSigning = false;
  bool _todaySigned = false;

  static const List<int> _rewardDays = [3, 7, 14, 30, 60, 100];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _signinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _entryController.forward();
    _loadSigninData();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _signinController.dispose();
    super.dispose();
  }

  Future<void> _loadSigninData() async {
    final now = DateTime.now();
    // 从后端拉取本月签到状态，无数据时显示空态
    try {
      final status = await ApiService.checkinStatus();
      final checked = status['checked_dates'] as List<dynamic>?;
      _signedDays = checked?.map((e) => e as int).toSet() ?? {};
      _points = (status['points'] as int?) ?? _points;
      _streak = (status['streak'] as int?) ?? _streak;
    } catch (_) {
      _signedDays = {};
    }
    _todaySigned = _signedDays.contains(now.day);
    if (mounted) setState(() {});
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
      begin: const Offset(0, 0.05),
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

  Future<void> _signin() async {
    if (_todaySigned) return;
    setState(() => _isSigning = true);
    _signinController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() {
      _signedDays.add(DateTime.now().day);
      _todaySigned = true;
      _continuousDays++;
      _totalDays++;
      _isSigning = false;
    });
    MiuixToast.show(context,
        message: '签到成功！获得 +10 积分', type: MiuixToastType.success);
  }

  void _补签(int day) {
    MiuixDialog_show(context, day);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '签到日历',
        backgroundColor: MiuixColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            _buildAnimatedItem(_buildStatsCard(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildCalendarCard(), 1),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildRewardSection(), 2),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildSigninButton(), 3),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF8FB5), Color(0xFFFF6B9D), Color(0xFFFF5588)],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildStatItem('连续签到', '$_continuousDays', '天', Icons.local_fire_department),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          _buildStatItem('累计签到', '$_totalDays', '天', Icons.calendar_today),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          _buildStatItem('本月签到', '${_signedDays.length}', '天', Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: MiuixFontSize.xs,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: MiuixFontSize.xs,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sunday

    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 月份导航
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MiuixIconButton(
                icon: Icons.chevron_left,
                style: MiuixIconButtonStyle.ghost,
                size: 36,
                onPressed: _previousMonth,
              ),
              Text(
                '$year年${month}月',
                style: const TextStyle(
                  fontSize: MiuixFontSize.lg,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
              MiuixIconButton(
                icon: Icons.chevron_right,
                style: MiuixIconButtonStyle.ghost,
                size: 36,
                onPressed: _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 星期标题
          Row(
            children: List.generate(7, (index) {
              final days = ['日', '一', '二', '三', '四', '五', '六'];
              return Expanded(
                child: Center(
                  child: Text(
                    days[index],
                    style: TextStyle(
                      fontSize: MiuixFontSize.sm,
                      fontWeight: FontWeight.w600,
                      color: index == 0 || index == 6
                          ? MiuixColors.primary
                          : MiuixColors.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          // 日期网格
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startWeekday) {
                return const SizedBox.shrink();
              }
              final day = index - startWeekday + 1;
              final isSigned = _signedDays.contains(day);
              final isToday = day == DateTime.now().day &&
                  month == DateTime.now().month &&
                  year == DateTime.now().year;
              final isFuture = day > DateTime.now().day &&
                  month == DateTime.now().month &&
                  year == DateTime.now().year;

              return MiuixRipple(
                borderRadius: MiuixRadius.sm,
                child: GestureDetector(
                  onTap: () {
                    if (!isSigned && !isFuture && !isToday) {
                      _补签(day);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isSigned
                          ? const LinearGradient(
                              colors: MiuixColors.primaryGradient)
                          : null,
                      color: isSigned
                          ? null
                          : isToday
                              ? MiuixColors.primaryLight.withOpacity(0.2)
                              : Colors.transparent,
                      borderRadius: MiuixRadius.smRadius,
                      border: isToday && !isSigned
                          ? Border.all(color: MiuixColors.primary, width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: isSigned
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 18)
                          : Text(
                              '$day',
                              style: TextStyle(
                                fontSize: MiuixFontSize.sm,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isFuture
                                    ? MiuixColors.textTertiary
                                    : isToday
                                        ? MiuixColors.primary
                                        : MiuixColors.textPrimary,
                              ),
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRewardSection() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.card_giftcard, color: MiuixColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                '签到奖励',
                style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _rewardDays.length,
              itemBuilder: (context, index) {
                final day = _rewardDays[index];
                final achieved = _continuousDays >= day;
                return Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: achieved
                        ? const LinearGradient(
                            colors: MiuixColors.primaryGradient)
                        : null,
                    color: achieved
                        ? null
                        : MiuixColors.surfaceVariant,
                    borderRadius: MiuixRadius.mdRadius,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        achieved ? Icons.star : Icons.star_border,
                        color: achieved ? Colors.white : MiuixColors.textTertiary,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day}天',
                        style: TextStyle(
                          fontSize: MiuixFontSize.sm,
                          fontWeight: FontWeight.w600,
                          color: achieved
                              ? Colors.white
                              : MiuixColors.textSecondary,
                        ),
                      ),
                      Text(
                        achieved ? '已领取' : '+${day * 10}积分',
                        style: TextStyle(
                          fontSize: 10,
                          color: achieved
                              ? Colors.white.withOpacity(0.8)
                              : MiuixColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSigninButton() {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_isSigning)
          AnimatedBuilder(
            animation: _signinController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(200, 60),
                painter: _SigninPainter(_signinController.value),
              );
            },
          ),
        SizedBox(
          width: double.infinity,
          child: MiuixButton(
            label: _todaySigned
                ? '今日已签到'
                : _isSigning
                    ? '签到中...'
                    : '立即签到',
            icon: _todaySigned ? Icons.check_circle : Icons.calendar_today,
            type: MiuixButtonType.gradient,
            gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
            size: MiuixButtonSize.large,
            loading: _isSigning,
            disabled: _todaySigned,
            onPressed: (_todaySigned || _isSigning) ? null : _signin,
          ),
        ),
      ],
    );
  }
}

void MiuixDialog_show(BuildContext context, int day) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: MiuixColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: MiuixRadius.xlRadius,
      ),
      title: const Text(
        '补签',
        style: TextStyle(
          color: MiuixColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text('使用 50 积分补签 $day 号？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消',
              style: TextStyle(color: MiuixColors.textSecondary)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            MiuixToast.show(context,
                message: '补签成功', type: MiuixToastType.success);
          },
          child: const Text('补签',
              style: TextStyle(color: MiuixColors.primary)),
        ),
      ],
    ),
  );
}

/// 签到动画绘制器
class _SigninPainter extends CustomPainter {
  final double progress;
  _SigninPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * 3.14159 + progress * 2 * 3.14159;
      final radius = 60 + progress * 40;
      final dx = center.dx + cos(angle) * radius;
      final dy = center.dy + sin(angle) * radius;
      canvas.drawCircle(
        Offset(dx, dy),
        3 * (1 - progress),
        Paint()..color = MiuixColors.primary.withOpacity(1 - progress),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
