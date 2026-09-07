import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_chip.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// TimerPage —— 计时器
/// 倒计时+正计时，预设时间，圆形进度
/// 开始/暂停/重置，粉色主题，动画
/// ============================================================

enum TimerMode { countdown, stopwatch }

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage>
    with SingleTickerProviderStateMixin, TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _progressController;

  TimerMode _mode = TimerMode.countdown;
  Timer? _timer;
  int _totalSeconds = 300; // 5分钟
  int _remainingSeconds = 300;
  int _elapsedSeconds = 0;
  bool _isRunning = false;

  static const List<int> _presets = [60, 180, 300, 600, 900, 1800];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: MiuixDuration.slow);
    _entryController.forward();
    _progressController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entryController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_mode == TimerMode.countdown && _remainingSeconds <= 0) return;
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_mode == TimerMode.countdown) {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            _remainingSeconds = 0;
            _isRunning = false;
            timer.cancel();
            _onTimerComplete();
          }
        } else {
          _elapsedSeconds++;
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      if (_mode == TimerMode.countdown) {
        _remainingSeconds = _totalSeconds;
      } else {
        _elapsedSeconds = 0;
      }
    });
  }

  void _onTimerComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: MiuixRadius.lgRadius),
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: MiuixColors.primary),
            SizedBox(width: 8),
            Text('时间到！'),
          ],
        ),
        content: Text('倒计时 ${_formatTime(_totalSeconds)} 已结束', style: const TextStyle(color: MiuixColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('知道了', style: TextStyle(color: MiuixColors.primary))),
        ],
      ),
    );
  }

  void _setPreset(int seconds) {
    _timer?.cancel();
    setState(() {
      _totalSeconds = seconds;
      _remainingSeconds = seconds;
      _isRunning = false;
    });
  }

  String _formatTime(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    if (h == '00') return '$m:$s';
    return '$h:$m:$s';
  }

  double get _progress {
    if (_mode == TimerMode.countdown) {
      if (_totalSeconds == 0) return 0;
      return _remainingSeconds / _totalSeconds;
    }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '计时器',
        actions: [
          MiuixChip(
            label: _mode == TimerMode.countdown ? '倒计时' : '正计时',
            isSelected: true,
            onTap: () {
              _timer?.cancel();
              setState(() {
                _mode = _mode == TimerMode.countdown ? TimerMode.stopwatch : TimerMode.countdown;
                _isRunning = false;
                _elapsedSeconds = 0;
                _remainingSeconds = _totalSeconds;
              });
            },
          ),
          const SizedBox(width: MiuixSpacing.md),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.md),
        child: Column(
          children: [
            const SizedBox(height: MiuixSpacing.xl),
            _buildCircularTimer(),
            const SizedBox(height: MiuixSpacing.xxl),
            _buildControlButtons(),
            const SizedBox(height: MiuixSpacing.xl),
            if (_mode == TimerMode.countdown) _buildPresets(),
            const SizedBox(height: MiuixSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularTimer() {
    final displaySeconds = _mode == TimerMode.countdown ? _remainingSeconds : _elapsedSeconds;
    final size = MediaQuery.of(context).size.width * 0.65;

    return FadeTransition(
      opacity: _entryController,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: MiuixColors.primary.withValues(alpha: 0.15),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 12,
                backgroundColor: MiuixColors.surfaceVariant,
                valueColor: const AlwaysStoppedAnimation<Color>(MiuixColors.primary),
                strokeCap: StrokeCap.round,
              ),
            ),
            Container(
              width: size - 40,
              height: size - 40,
              decoration: BoxDecoration(
                color: MiuixColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: MiuixColors.borderLight, width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTime(displaySeconds),
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: MiuixColors.primary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: MiuixSpacing.sm),
                  Text(
                    _mode == TimerMode.countdown ? '倒计时中' : '正计时中',
                    style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary),
                  ),
                  if (_isRunning) ...[
                    const SizedBox(height: MiuixSpacing.sm),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        return Padding(
                          padding: EdgeInsets.only(right: i == 2 ? 0 : 4),
                          child: _PulseDot(index: i),
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryController, curve: const Interval(0.1, 0.5, curve: MiuixCurves.easeOut)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MiuixRipple(
            onTap: _resetTimer,
            borderRadius: MiuixRadius.pill,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: MiuixColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: MiuixColors.border, width: 1.5),
              ),
              child: const Icon(Icons.refresh, size: 24, color: MiuixColors.textSecondary),
            ),
          ),
          const SizedBox(width: MiuixSpacing.xl),
          MiuixRipple(
            onTap: _isRunning ? _pauseTimer : _startTimer,
            borderRadius: MiuixRadius.pill,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: MiuixColors.primaryGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: MiuixColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                _isRunning ? Icons.pause : Icons.play_arrow,
                size: 36,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: MiuixSpacing.xl),
          MiuixRipple(
            onTap: () {
              if (_mode == TimerMode.countdown) {
                _setPreset(_totalSeconds + 60);
              }
            },
            borderRadius: MiuixRadius.pill,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: MiuixColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: MiuixColors.border, width: 1.5),
              ),
              child: const Icon(Icons.add, size: 24, color: MiuixColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresets() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryController, curve: const Interval(0.2, 0.6, curve: MiuixCurves.easeOut)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: MiuixSpacing.xs, bottom: MiuixSpacing.sm),
            child: Text('预设时间', style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          ),
          Wrap(
            spacing: MiuixSpacing.sm,
            runSpacing: MiuixSpacing.sm,
            children: _presets.map((seconds) {
              final isSelected = _totalSeconds == seconds;
              return MiuixChip(
                label: _formatTime(seconds),
                isSelected: isSelected,
                onTap: () => _setPreset(seconds),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final int index;
  const _PulseDot({required this.index});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final delay = widget.index * 0.15;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = (_controller.value + delay) % 1.0;
        final scale = 0.6 + 0.4 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: MiuixColors.primary, shape: BoxShape.circle),
          ),
        );
      },
    );
  }
}
