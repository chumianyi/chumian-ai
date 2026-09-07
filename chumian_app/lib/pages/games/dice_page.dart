import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_slider.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';

/// ============================================================
/// DicePage —— 骰子
/// 1-6个骰子，3D翻转动画，随机结果
/// 历史记录，总和，自定义骰子面，粉色主题
/// ============================================================
class DicePage extends StatefulWidget {
  const DicePage({super.key});

  @override
  State<DicePage> createState() => _DicePageState();
}

class _DicePageState extends State<DicePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _rollController;

  int _diceCount = 2;
  int _sides = 6; // 骰子面数
  List<int> _results = [1, 1];
  List<int> _history = [];
  bool _isRolling = false;
  int _totalRolls = 0;
  final Random _random = Random();

  static const List<int> _sideOptions = [4, 6, 8, 10, 12, 20];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _rollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _rollController.dispose();
    super.dispose();
  }

  void _rollDice() {
    if (_isRolling) return;
    setState(() => _isRolling = true);
    _rollController.forward(from: 0);

    // 滚动过程中不断变化数字
    int tick = 0;
    final ticker = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      tick++;
      setState(() {
        _results = List.generate(_diceCount, (_) => _random.nextInt(_sides) + 1);
      });
      if (tick >= 8) {
        timer.cancel();
        // 最终结果
        final finalResults =
            List.generate(_diceCount, (_) => _random.nextInt(_sides) + 1);
        setState(() {
          _results = finalResults;
          _isRolling = false;
          _totalRolls++;
        });
        final sum = finalResults.reduce((a, b) => a + b);
        _history.insert(0, sum);
        if (_history.length > 20) _history.removeLast();
        MiuixToast.show(context, '总和: $sum', icon: Icons.casino);
      }
    });
  }

  void _updateDiceCount(int count) {
    setState(() {
      _diceCount = count;
      _results = List.generate(count, (_) => 1);
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
    final sum = _results.reduce((a, b) => a + b);
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(title: '骰子'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: Column(
          children: [
            _buildAnimatedItem(_buildDiceArea(), 0),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildSumCard(sum), 1),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildSettings(), 2),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildRollButton(), 3),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildHistory(), 4),
          ],
        ),
      ),
    );
  }

  Widget _buildDiceArea() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(
        colors: [Color(0xFFFFF5F8), Color(0xFFFFEEF3)],
      ),
      padding: const EdgeInsets.all(MiuixSpacing.xl),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _diceCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _diceCount <= 2 ? _diceCount : 3,
              crossAxisSpacing: MiuixSpacing.lg,
              mainAxisSpacing: MiuixSpacing.lg,
            ),
            itemBuilder: (context, index) => _buildDie(_results[index], index),
          ),
        ],
      ),
    );
  }

  Widget _buildDie(int value, int index) {
    return AnimatedBuilder(
      animation: _rollController,
      builder: (context, _) {
        final angle = _isRolling ? sin(_rollController.value * pi * 4 + index) * 0.3 : 0.0;
        final bounce = _isRolling ? (sin(_rollController.value * pi * 6 + index) * 8).abs() : 0.0;
        return Transform.translate(
          offset: Offset(0, -bounce),
          child: Transform.rotate(
            angle: angle,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFFFF0F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: MiuixRadius.lgRadius,
                border: Border.all(color: MiuixColors.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: MiuixColors.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _buildDieFace(value),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDieFace(int value) {
    if (_sides != 6) {
      // 非6面骰子显示数字
      return Center(
        child: Text(
          '$value',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: MiuixColors.primaryDark,
          ),
        ),
      );
    }

    // 6面骰子显示点数
    final dotPositions = <List<int>>[
      [], // 0 unused
      [4], // 1
      [0, 8], // 2
      [0, 4, 8], // 3
      [0, 2, 6, 8], // 4
      [0, 2, 4, 6, 8], // 5
      [0, 2, 3, 5, 6, 8], // 6
    ];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 9,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemBuilder: (context, i) {
          final hasDot = dotPositions[value].contains(i);
          return Center(
            child: hasDot
                ? Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [MiuixColors.primary, MiuixColors.primaryDeep],
                      ),
                      shape: BoxShape.circle,
                    ),
                  )
                : const SizedBox.shrink(),
          );
        },
      ),
    );
  }

  Widget _buildSumCard(int sum) {
    return MiuixCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('总和', '$sum', MiuixColors.primary),
          Container(width: 1, height: 36, color: MiuixColors.divider),
          _statItem('骰子数', '$_diceCount', MiuixColors.info),
          Container(width: 1, height: 36, color: MiuixColors.divider),
          _statItem('投掷次数', '$_totalRolls', MiuixColors.warning),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: MiuixFontSize.xxl,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary)),
      ],
    );
  }

  Widget _buildSettings() {
    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('骰子数量',
              style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary)),
          const SizedBox(height: MiuixSpacing.sm),
          MiuixSlider(
            value: _diceCount.toDouble(),
            min: 1,
            max: 6,
            divisions: 5,
            label: '$_diceCount 个',
            onChanged: (v) => _updateDiceCount(v.toInt()),
          ),
          const SizedBox(height: MiuixSpacing.lg),
          const Text('骰子面数',
              style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary)),
          const SizedBox(height: MiuixSpacing.sm),
          Wrap(
            spacing: MiuixSpacing.sm,
            children: _sideOptions.map((s) {
              final selected = _sides == s;
              return GestureDetector(
                onTap: () => setState(() => _sides = s),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: MiuixSpacing.lg, vertical: MiuixSpacing.sm),
                  decoration: BoxDecoration(
                    color: selected ? MiuixColors.primary : MiuixColors.surfaceVariant,
                    borderRadius: MiuixRadius.pillRadius,
                    border: Border.all(
                      color: selected ? MiuixColors.primary : MiuixColors.border,
                    ),
                  ),
                  child: Text('D$s',
                      style: TextStyle(
                          color: selected ? Colors.white : MiuixColors.textSecondary,
                          fontWeight: FontWeight.w500)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRollButton() {
    return MiuixButton(
      label: _isRolling ? '投掷中...' : '投掷骰子',
      icon: _isRolling ? Icons.autorenew : Icons.casino,
      width: double.infinity,
      onPressed: _isRolling ? null : _rollDice,
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return MiuixCard(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(MiuixSpacing.xl),
            child: Text('暂无历史记录，投掷骰子后显示',
                style: TextStyle(color: MiuixColors.textTertiary)),
          ),
        ),
      );
    }
    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('历史记录',
              style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary)),
          const SizedBox(height: MiuixSpacing.md),
          Wrap(
            spacing: MiuixSpacing.sm,
            runSpacing: MiuixSpacing.sm,
            children: _history.asMap().entries.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: MiuixSpacing.md, vertical: MiuixSpacing.xs),
                decoration: BoxDecoration(
                  color: e.key == 0
                      ? MiuixColors.primary.withValues(alpha: 0.15)
                      : MiuixColors.surfaceVariant,
                  borderRadius: MiuixRadius.pillRadius,
                  border: Border.all(
                    color: e.key == 0 ? MiuixColors.primary : MiuixColors.borderLight,
                  ),
                ),
                child: Text('#${_history.length - e.key}  ${e.value}',
                    style: TextStyle(
                        color: e.key == 0
                            ? MiuixColors.primaryDark
                            : MiuixColors.textSecondary,
                        fontWeight: e.key == 0 ? FontWeight.bold : FontWeight.normal)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
