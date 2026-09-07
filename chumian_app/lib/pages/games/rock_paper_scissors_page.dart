import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';

/// ============================================================
/// RockPaperScissorsPage —— 石头剪刀布
/// 玩家选择，AI随机，动画展示，胜负判定
/// 计分，连胜统计，粉色主题
/// ============================================================
class RockPaperScissorsPage extends StatefulWidget {
  const RockPaperScissorsPage({super.key});

  @override
  State<RockPaperScissorsPage> createState() => _RockPaperScissorsPageState();
}

class _RockPaperScissorsPageState extends State<RockPaperScissorsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _shakeController;

  int _playerChoice = -1; // -1=未选, 0=石头, 1=剪刀, 2=布
  int _aiChoice = -1;
  int _result = 0; // 0=待定, 1=玩家胜, 2=AI胜, 3=平局
  bool _isShaking = false;

  int _playerWins = 0;
  int _aiWins = 0;
  int _draws = 0;
  int _winStreak = 0;
  int _maxStreak = 0;

  final Random _random = Random();

  static const List<IconData> _icons = [
    Icons.fitness_center, // 石头
    Icons.content_cut, // 剪刀
    Icons.back_hand, // 布
  ];
  static const List<String> _labels = ['石头', '剪刀', '布'];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _play(int choice) {
    if (_isShaking) return;
    setState(() {
      _playerChoice = choice;
      _aiChoice = -1;
      _result = 0;
      _isShaking = true;
    });

    _shakeController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final ai = _random.nextInt(3);
      setState(() {
        _aiChoice = ai;
        _isShaking = false;
        _determineResult(choice, ai);
      });
    });
  }

  void _determineResult(int player, int ai) {
    if (player == ai) {
      _result = 3;
      _draws++;
      _winStreak = 0;
      MiuixToast.show(context, '平局！', icon: Icons.handshake);
    } else if ((player == 0 && ai == 1) ||
        (player == 1 && ai == 2) ||
        (player == 2 && ai == 0)) {
      _result = 1;
      _playerWins++;
      _winStreak++;
      if (_winStreak > _maxStreak) _maxStreak = _winStreak;
      MiuixToast.show(context, '你赢了！$_winStreak 连胜', icon: Icons.emoji_events);
    } else {
      _result = 2;
      _aiWins++;
      _winStreak = 0;
      MiuixToast.show(context, 'AI 赢了！', icon: Icons.sentiment_dissatisfied);
    }
  }

  void _reset() {
    setState(() {
      _playerChoice = -1;
      _aiChoice = -1;
      _result = 0;
      _playerWins = 0;
      _aiWins = 0;
      _draws = 0;
      _winStreak = 0;
      _maxStreak = 0;
    });
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.06, (index * 0.06) + 0.4,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.06, (index * 0.06) + 0.4,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(title: '石头剪刀布'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: Column(
          children: [
            _buildAnimatedItem(_buildScoreBoard(), 0),
            const SizedBox(height: MiuixSpacing.xl),
            _buildAnimatedItem(_buildBattleArea(), 1),
            const SizedBox(height: MiuixSpacing.xl),
            _buildAnimatedItem(_buildResultText(), 2),
            const SizedBox(height: MiuixSpacing.xl),
            _buildAnimatedItem(_buildChoiceButtons(), 3),
            const SizedBox(height: MiuixSpacing.xl),
            _buildAnimatedItem(_buildResetButton(), 4),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return MiuixCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _scoreColumn('你', _playerWins, MiuixColors.primary),
          _scoreColumn('平局', _draws, MiuixColors.textTertiary),
          _scoreColumn('AI', _aiWins, MiuixColors.primaryDark),
          Container(width: 1, height: 40, color: MiuixColors.divider),
          Column(
            children: [
              const Icon(Icons.local_fire_department,
                  color: MiuixColors.warning, size: 18),
              Text('$_winStreak',
                  style: const TextStyle(
                      fontSize: MiuixFontSize.xl,
                      fontWeight: FontWeight.bold,
                      color: MiuixColors.warning)),
              const Text('连胜',
                  style: TextStyle(
                      fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreColumn(String label, int score, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: MiuixFontSize.md, color: color)),
        const SizedBox(height: MiuixSpacing.xs),
        Text('$score',
            style: TextStyle(
                fontSize: MiuixFontSize.xxl,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }

  Widget _buildBattleArea() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildHand('你', _playerChoice, true),
        const Text('VS',
            style: TextStyle(
                fontSize: MiuixFontSize.xxl,
                fontWeight: FontWeight.bold,
                color: MiuixColors.primary)),
        _buildHand('AI', _aiChoice, false),
      ],
    );
  }

  Widget _buildHand(String label, int choice, bool isPlayer) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: MiuixFontSize.md, color: MiuixColors.textSecondary)),
        const SizedBox(height: MiuixSpacing.md),
        AnimatedBuilder(
          animation: _shakeController,
          builder: (context, _) {
            final shake = _isShaking
                ? sin(_shakeController.value * pi * 6) * 10
                : 0.0;
            return Transform.translate(
              offset: Offset(0, shake),
              child: Transform.rotate(
                angle: isPlayer ? -0.2 : 0.2,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: choice >= 0
                        ? const LinearGradient(colors: MiuixColors.primaryGradient)
                        : const LinearGradient(
                            colors: [Color(0xFFFFE4EC), Color(0xFFFFD6E4)]),
                    borderRadius: MiuixRadius.xlRadius,
                    boxShadow: MiuixShadows.md,
                  ),
                  child: Center(
                    child: choice >= 0
                        ? Icon(_icons[choice], size: 44, color: Colors.white)
                        : const Icon(Icons.help_outline,
                            size: 40, color: MiuixColors.primary),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildResultText() {
    String text = '选择你的出招';
    Color color = MiuixColors.textSecondary;
    IconData icon = Icons.touch_app;

    if (_result == 1) {
      text = '你赢了！';
      color = MiuixColors.success;
      icon = Icons.emoji_events;
    } else if (_result == 2) {
      text = 'AI 赢了！';
      color = MiuixColors.error;
      icon = Icons.sentiment_dissatisfied;
    } else if (_result == 3) {
      text = '平局！';
      color = MiuixColors.warning;
      icon = Icons.handshake;
    }

    return AnimatedSwitcher(
      duration: MiuixDuration.fast,
      child: Container(
        key: ValueKey(_result),
        padding: const EdgeInsets.symmetric(
            horizontal: MiuixSpacing.xl, vertical: MiuixSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: MiuixRadius.pillRadius,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: MiuixSpacing.sm),
            Text(text,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: MiuixFontSize.lg)),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (i) {
        return GestureDetector(
          onTap: () => _play(i),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: _playerChoice == i ? 0.9 : 1),
            duration: MiuixDuration.fast,
            builder: (context, val, _) => Transform.scale(
              scale: val,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: MiuixColors.softGradient),
                  borderRadius: MiuixRadius.lgRadius,
                  border: Border.all(
                    color: _playerChoice == i
                        ? MiuixColors.primary
                        : MiuixColors.border,
                    width: _playerChoice == i ? 2 : 1,
                  ),
                  boxShadow: MiuixShadows.sm,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_icons[i],
                        color: MiuixColors.primary, size: 28),
                    const SizedBox(height: MiuixSpacing.xs),
                    Text(_labels[i],
                        style: const TextStyle(
                            color: MiuixColors.primaryDark,
                            fontSize: MiuixFontSize.sm,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildResetButton() {
    return MiuixButton(
      label: '重置比分',
      icon: Icons.refresh,
      type: MiuixButtonType.secondary,
      width: double.infinity,
      onPressed: _reset,
    );
  }
}
