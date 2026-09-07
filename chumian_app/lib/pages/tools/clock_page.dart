import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_segment.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// ClockPage —— 时钟页
/// 模拟时钟(自定义绘制，粉色)，数字时钟，秒表，倒计时，世界时钟
/// ============================================================
class ClockPage extends StatefulWidget {
  const ClockPage({super.key});

  @override
  State<ClockPage> createState() => _ClockPageState();
}

class _ClockPageState extends State<ClockPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Timer _timer;

  DateTime _now = DateTime.now();
  int _selectedTab = 0;

  // 秒表
  Stopwatch _stopwatch = Stopwatch();
  bool _stopwatchRunning = false;
  List<Duration> _laps = [];

  // 倒计时
  int _countdownSeconds = 300;
  int _countdownRemaining = 300;
  bool _countdownRunning = false;
  Timer? _countdownTimer;

  static const List<String> _tabs = ['时钟', '秒表', '倒计时', '世界时钟'];

  static const List<WorldClock> _worldClocks = [
    WorldClock(city: '北京', offset: 8, flag: '🇨🇳'),
    WorldClock(city: '东京', offset: 9, flag: '🇯🇵'),
    WorldClock(city: '伦敦', offset: 0, flag: '🇬🇧'),
    WorldClock(city: '纽约', offset: -5, flag: '🇺🇸'),
    WorldClock(city: '巴黎', offset: 1, flag: '🇫🇷'),
    WorldClock(city: '悉尼', offset: 10, flag: '🇦🇺'),
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _entryController.dispose();
    _stopwatch.stop();
    _countdownTimer?.cancel();
    super.dispose();
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

  void _toggleStopwatch() {
    setState(() {
      if (_stopwatchRunning) {
        _stopwatch.stop();
      } else {
        _stopwatch.start();
      }
      _stopwatchRunning = !_stopwatchRunning;
    });
  }

  void _resetStopwatch() {
    setState(() {
      _stopwatch.reset();
      _stopwatchRunning = false;
      _laps.clear();
    });
  }

  void _addLap() {
    setState(() {
      _laps.insert(0, _stopwatch.elapsed);
    });
  }

  void _toggleCountdown() {
    setState(() {
      if (_countdownRunning) {
        _countdownTimer?.cancel();
        _countdownRunning = false;
      } else {
        _countdownRunning = true;
        _countdownTimer =
            Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            if (_countdownRemaining > 0) {
              _countdownRemaining--;
            } else {
              timer.cancel();
              _countdownRunning = false;
              MiuixToast.show(context,
                  message: '倒计时结束！', type: MiuixToastType.success);
            }
          });
        });
      }
    });
  }

  void _resetCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _countdownRemaining = _countdownSeconds;
      _countdownRunning = false;
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$ms';
  }

  String _formatCountdown(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '时钟',
        backgroundColor: MiuixColors.background,
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return MiuixSegmentControl(
      items: List.generate(
        _tabs.length,
        (index) => MiuixSegmentItem(label: _tabs[index]),
      ),
      selectedIndex: _selectedTab,
      onChanged: (i) => setState(() => _selectedTab = i),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildClockTab();
      case 1:
        return _buildStopwatchTab();
      case 2:
        return _buildCountdownTab();
      case 3:
        return _buildWorldClockTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildClockTab() {
    return Column(
      children: [
        _buildAnimatedItem(_buildAnalogClock(), 0),
        const SizedBox(height: 20),
        _buildAnimatedItem(_buildDigitalClock(), 1),
      ],
    );
  }

  Widget _buildAnalogClock() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)],
      ),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SizedBox(
          width: 250,
          height: 250,
          child: CustomPaint(
            painter: _AnalogClockPainter(
              hour: _now.hour,
              minute: _now.minute,
              second: _now.second,
              millisecond: _now.millisecond,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDigitalClock() {
    final hours = _now.hour.toString().padLeft(2, '0');
    final minutes = _now.minute.toString().padLeft(2, '0');
    final seconds = _now.second.toString().padLeft(2, '0');
    final weekdays = ['日', '一', '二', '三', '四', '五', '六'];

    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hours,
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w200,
                  color: MiuixColors.primaryDeep,
                ),
              ),
              const Text(
                ':',
                style: TextStyle(
                  fontSize: 48,
                  color: MiuixColors.primary,
                ),
              ),
              Text(
                minutes,
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w200,
                  color: MiuixColors.primaryDeep,
                ),
              ),
              const Text(
                ':',
                style: TextStyle(
                  fontSize: 48,
                  color: MiuixColors.primary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  seconds,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: MiuixColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_now.year}年${_now.month}月${_now.day}日 星期${weekdays[_now.weekday % 7]}',
            style: const TextStyle(
              fontSize: MiuixFontSize.md,
              color: MiuixColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopwatchTab() {
    return Column(
      children: [
        _buildAnimatedItem(
          MiuixCard(
            style: MiuixCardStyle.gradient,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)],
            ),
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                _formatDuration(_stopwatch.elapsed),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w200,
                  color: MiuixColors.primaryDeep,
                ),
              ),
            ),
          ),
          0,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MiuixButton(
                label: _stopwatchRunning ? '暂停' : '开始',
                icon: _stopwatchRunning ? Icons.pause : Icons.play_arrow,
                type: MiuixButtonType.primary,
                onPressed: _toggleStopwatch,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MiuixButton(
                label: '计次',
                icon: Icons.flag,
                type: MiuixButtonType.secondary,
                onPressed: _stopwatchRunning ? _addLap : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MiuixButton(
                label: '重置',
                icon: Icons.refresh,
                type: MiuixButtonType.danger,
                onPressed: _resetStopwatch,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_laps.isNotEmpty)
          MiuixCard(
            style: MiuixCardStyle.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '计次记录',
                  style: TextStyle(
                    fontSize: MiuixFontSize.md,
                    fontWeight: FontWeight.w600,
                    color: MiuixColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(_laps.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          '#${_laps.length - index}',
                          style: const TextStyle(
                            color: MiuixColors.textTertiary,
                            fontSize: MiuixFontSize.sm,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDuration(_laps[index]),
                          style: const TextStyle(
                            color: MiuixColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCountdownTab() {
    return Column(
      children: [
        _buildAnimatedItem(
          MiuixCard(
            style: MiuixCardStyle.gradient,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)],
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Text(
                  _formatCountdown(_countdownRemaining),
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w200,
                    color: MiuixColors.primaryDeep,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 6,
                  child: ClipRRect(
                    borderRadius: MiuixRadius.pillRadius,
                    child: LinearProgressIndicator(
                      value: _countdownSeconds > 0
                          ? _countdownRemaining / _countdownSeconds
                          : 0,
                      backgroundColor: Colors.white.withOpacity(0.5),
                      valueColor:
                          const AlwaysStoppedAnimation(MiuixColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          0,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [60, 180, 300, 600, 900].map((seconds) {
            final isSelected = _countdownSeconds == seconds;
            return MiuixRipple(
              borderRadius: MiuixRadius.pill,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _countdownSeconds = seconds;
                    _countdownRemaining = seconds;
                    _countdownRunning = false;
                    _countdownTimer?.cancel();
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: MiuixColors.primaryGradient)
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
                    '${seconds ~/ 60}分钟',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : MiuixColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MiuixButton(
                label: _countdownRunning ? '暂停' : '开始',
                icon: _countdownRunning ? Icons.pause : Icons.play_arrow,
                type: MiuixButtonType.primary,
                onPressed: _toggleCountdown,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MiuixButton(
                label: '重置',
                icon: Icons.refresh,
                type: MiuixButtonType.secondary,
                onPressed: _resetCountdown,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWorldClockTab() {
    return Column(
      children: List.generate(_worldClocks.length, (index) {
        final clock = _worldClocks[index];
        final localTime = _now.toUtc().add(Duration(hours: clock.offset));
        return _buildAnimatedItem(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MiuixCard(
              style: MiuixCardStyle.surface,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(clock.flag, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clock.city,
                          style: const TextStyle(
                            fontSize: MiuixFontSize.lg,
                            fontWeight: FontWeight.w600,
                            color: MiuixColors.textPrimary,
                          ),
                        ),
                        Text(
                          'UTC${clock.offset >= 0 ? '+' : ''}${clock.offset}',
                          style: const TextStyle(
                            fontSize: MiuixFontSize.xs,
                            color: MiuixColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w200,
                      color: MiuixColors.primaryDeep,
                    ),
                  ),
                ],
              ),
            ),
          ),
          index,
        );
      }),
    );
  }
}

class WorldClock {
  final String city;
  final int offset;
  final String flag;
  const WorldClock(
      {required this.city, required this.offset, required this.flag});
}

/// 模拟时钟绘制器
class _AnalogClockPainter extends CustomPainter {
  final int hour;
  final int minute;
  final int second;
  final int millisecond;

  _AnalogClockPainter({
    required this.hour,
    required this.minute,
    required this.second,
    required this.millisecond,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // 表盘背景
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = Colors.white,
    );

    // 表盘边框
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = MiuixColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // 刻度
    for (int i = 0; i < 60; i++) {
      final angle = (i / 60) * 2 * math.pi - math.pi / 2;
      final isHour = i % 5 == 0;
      final innerR = radius - (isHour ? 16 : 8);
      final outerR = radius - 4;
      canvas.drawLine(
        Offset(center.dx + math.cos(angle) * innerR,
            center.dy + math.sin(angle) * innerR),
        Offset(center.dx + math.cos(angle) * outerR,
            center.dy + math.sin(angle) * outerR),
        Paint()
          ..color = isHour ? MiuixColors.primary : MiuixColors.border
          ..strokeWidth = isHour ? 3 : 1,
      );
    }

    // 数字
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 1; i <= 12; i++) {
      final angle = (i / 12) * 2 * math.pi - math.pi / 2;
      final numR = radius - 32;
      textPainter.text = TextSpan(
        text: '$i',
        style: const TextStyle(
          color: MiuixColors.primaryDeep,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx + math.cos(angle) * numR - textPainter.width / 2,
          center.dy + math.sin(angle) * numR - textPainter.height / 2,
        ),
      );
    }

    // 时针
    final hourAngle =
        ((hour % 12) + minute / 60) / 12 * 2 * math.pi - math.pi / 2;
    canvas.drawLine(
      center,
      Offset(center.dx + math.cos(hourAngle) * (radius * 0.5),
          center.dy + math.sin(hourAngle) * (radius * 0.5)),
      Paint()
        ..color = MiuixColors.primaryDeep
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    // 分针
    final minuteAngle =
        (minute + second / 60) / 60 * 2 * math.pi - math.pi / 2;
    canvas.drawLine(
      center,
      Offset(center.dx + math.cos(minuteAngle) * (radius * 0.7),
          center.dy + math.sin(minuteAngle) * (radius * 0.7)),
      Paint()
        ..color = MiuixColors.primary
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // 秒针
    final secondAngle =
        (second + millisecond / 1000) / 60 * 2 * math.pi - math.pi / 2;
    canvas.drawLine(
      Offset(center.dx - math.cos(secondAngle) * 15,
          center.dy - math.sin(secondAngle) * 15),
      Offset(center.dx + math.cos(secondAngle) * (radius * 0.8),
          center.dy + math.sin(secondAngle) * (radius * 0.8)),
      Paint()
        ..color = MiuixColors.error
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // 中心点
    canvas.drawCircle(
      center,
      6,
      Paint()..color = MiuixColors.primaryDeep,
    );
    canvas.drawCircle(
      center,
      3,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
