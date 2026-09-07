import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_input.dart';
import 'package:chumian_ai/widgets/miuix/miuix_progress.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';

/// ============================================================
/// FortunePage —— 运势测算
/// 输入生日/星座，今日运势，爱情/事业/财运指数
/// 幸运色/数字，粉色渐变，动画展示
/// ============================================================
class FortunePage extends StatefulWidget {
  const FortunePage({super.key});

  @override
  State<FortunePage> createState() => _FortunePageState();
}

class _FortunePageState extends State<FortunePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _resultController;

  final TextEditingController _birthdayController = TextEditingController();
  int _selectedConstellation = -1;
  bool _showResult = false;
  bool _isCalculating = false;
  FortuneResult? _result;

  static const List<String> _constellations = [
    '白羊座', '金牛座', '双子座', '巨蟹座', '狮子座', '处女座',
    '天秤座', '天蝎座', '射手座', '摩羯座', '水瓶座', '双鱼座',
  ];

  static const List<IconData> _constellationIcons = [
    Icons.auto_awesome, Icons.pets, Icons.people, Icons.cruelty_free,
    Icons.wb_sunny, Icons.eco, Icons.balance, Icons.nightlight,
    Icons.arrow_forward, Icons.terrain, Icons.water, Icons.waves,
  ];

  static const List<String> _luckyColors = [
    '樱花粉', '玫瑰红', '蜜桃橙', '薰衣草紫', '天空蓝', '薄荷绿',
    '柠檬黄', '珍珠白', '珊瑚粉', '豆沙色', '香槟金', '莓果红',
  ];

  static const List<String> _fortuneTexts = [
    '今天运势极佳，万事顺遂，适合开展新计划。',
    '今日贵人运旺盛，会有意想不到的收获。',
    '财运亨通，投资理财有望获得不错回报。',
    '感情方面甜蜜温馨，单身者有望遇到心仪对象。',
    '工作中会遇到小挑战，但凭借智慧能够顺利解决。',
    '今日适合学习充电，知识积累将带来长远收益。',
    '人际关系和谐，与朋友家人相处愉快。',
    '健康状况良好，保持规律作息更添活力。',
    '创意灵感迸发，适合从事艺术创作或头脑风暴。',
    '今日宜静不宜动，沉淀内心会有新的感悟。',
  ];

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _resultController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  void _calculateFortune() {
    if (_selectedConstellation < 0) {
      MiuixToast.show(context, '请先选择星座', icon: Icons.error_outline);
      return;
    }

    setState(() {
      _isCalculating = true;
      _showResult = false;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      final seed = _selectedConstellation * 31 + DateTime.now().day;
      final rng = Random(seed);

      _result = FortuneResult(
        overall: rng.nextInt(40) + 60,
        love: rng.nextInt(40) + 60,
        career: rng.nextInt(40) + 60,
        wealth: rng.nextInt(40) + 60,
        luckyColor: _luckyColors[rng.nextInt(_luckyColors.length)],
        luckyNumber: rng.nextInt(99) + 1,
        text: _fortuneTexts[rng.nextInt(_fortuneTexts.length)],
        constellation: _constellations[_selectedConstellation],
      );

      setState(() {
        _isCalculating = false;
        _showResult = true;
      });
      _resultController.forward(from: 0);
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
      appBar: MiuixAppBar(title: '运势测算'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: Column(
          children: [
            _buildAnimatedItem(_buildInputSection(), 0),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildConstellationGrid(), 1),
            const SizedBox(height: MiuixSpacing.xl),
            _buildAnimatedItem(_buildCalculateButton(), 2),
            if (_isCalculating) ...[
              const SizedBox(height: MiuixSpacing.xl),
              _buildCalculatingIndicator(),
            ],
            if (_showResult && _result != null) ...[
              const SizedBox(height: MiuixSpacing.xl),
              _buildResultSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('输入生日（可选）',
              style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary)),
          const SizedBox(height: MiuixSpacing.md),
          MiuixInput(
            controller: _birthdayController,
            hintText: '例如：1995-06-15',
            prefixIcon: Icons.cake,
            keyboardType: TextInputType.datetime,
          ),
        ],
      ),
    );
  }

  Widget _buildConstellationGrid() {
    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('选择星座',
              style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary)),
          const SizedBox(height: MiuixSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: MiuixSpacing.sm,
              mainAxisSpacing: MiuixSpacing.sm,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) {
              final selected = _selectedConstellation == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedConstellation = index),
                child: AnimatedContainer(
                  duration: MiuixDuration.fast,
                  curve: MiuixCurves.miuixSpring,
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(colors: MiuixColors.primaryGradient)
                        : null,
                    color: selected ? null : MiuixColors.surfaceVariant,
                    borderRadius: MiuixRadius.mdRadius,
                    border: Border.all(
                      color: selected
                          ? MiuixColors.primary
                          : MiuixColors.borderLight,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_constellationIcons[index],
                          color: selected ? Colors.white : MiuixColors.primary,
                          size: 20),
                      const SizedBox(height: MiuixSpacing.xs),
                      Text(_constellations[index],
                          style: TextStyle(
                              fontSize: MiuixFontSize.xs,
                              color: selected
                                  ? Colors.white
                                  : MiuixColors.textSecondary,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalculateButton() {
    return MiuixButton(
      label: '测算今日运势',
      icon: Icons.auto_awesome,
      width: double.infinity,
      onPressed: _isCalculating ? null : _calculateFortune,
    );
  }

  Widget _buildCalculatingIndicator() {
    return MiuixCard(
      child: Padding(
        padding: const EdgeInsets.all(MiuixSpacing.xl),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(seconds: 1),
              builder: (context, val, _) => RotationTransition(
                turns: AlwaysStoppedAnimation(val),
                child: const Icon(Icons.auto_awesome,
                    color: MiuixColors.primary, size: 40),
              ),
            ),
            const SizedBox(height: MiuixSpacing.md),
            const Text('正在为你测算运势...',
                style: TextStyle(color: MiuixColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return AnimatedBuilder(
      animation: _resultController,
      builder: (context, _) {
        return Opacity(
          opacity: _resultController.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _resultController.value)),
            child: Column(
              children: [
                _buildOverallCard(),
                const SizedBox(height: MiuixSpacing.lg),
                _buildDetailCards(),
                const SizedBox(height: MiuixSpacing.lg),
                _buildLuckyInfo(),
                const SizedBox(height: MiuixSpacing.lg),
                _buildFortuneText(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverallCard() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
      child: Column(
        children: [
          Text('${_result!.constellation} · 今日运势',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: MiuixFontSize.lg,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: MiuixSpacing.lg),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: _result!.overall / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Column(
                children: [
                  Text('${_result!.overall}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                  const Text('综合运势',
                      style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: MiuixSpacing.md),
          Text(
            _result!.overall >= 85
                ? '大吉'
                : _result!.overall >= 70
                    ? '吉'
                    : _result!.overall >= 55
                        ? '中吉'
                        : '小吉',
            style: const TextStyle(
                color: Colors.white,
                fontSize: MiuixFontSize.xxl,
                fontWeight: FontWeight.bold,
                letterSpacing: 4),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCards() {
    return Row(
      children: [
        Expanded(child: _detailCard('爱情', _result!.love, Icons.favorite)),
        const SizedBox(width: MiuixSpacing.sm),
        Expanded(child: _detailCard('事业', _result!.career, Icons.work)),
        const SizedBox(width: MiuixSpacing.sm),
        Expanded(child: _detailCard('财运', _result!.wealth, Icons.payments)),
      ],
    );
  }

  Widget _detailCard(String label, int value, IconData icon) {
    return MiuixCard(
      padding: const EdgeInsets.all(MiuixSpacing.md),
      child: Column(
        children: [
          Icon(icon, color: MiuixColors.primary, size: 20),
          const SizedBox(height: MiuixSpacing.xs),
          Text('$value',
              style: const TextStyle(
                  fontSize: MiuixFontSize.xl,
                  fontWeight: FontWeight.bold,
                  color: MiuixColors.primaryDark)),
          Text(label,
              style: const TextStyle(
                  fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary)),
          const SizedBox(height: MiuixSpacing.xs),
          MiuixProgress(value: value / 100, height: 4),
        ],
      ),
    );
  }

  Widget _buildLuckyInfo() {
    return MiuixCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _luckyItem(Icons.color_lens, '幸运色', _result!.luckyColor),
          Container(width: 1, height: 40, color: MiuixColors.divider),
          _luckyItem(Icons.tag, '幸运数字', '${_result!.luckyNumber}'),
        ],
      ),
    );
  }

  Widget _luckyItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: MiuixColors.primary, size: 22),
        const SizedBox(height: MiuixSpacing.xs),
        Text(value,
            style: const TextStyle(
                fontSize: MiuixFontSize.lg,
                fontWeight: FontWeight.bold,
                color: MiuixColors.primaryDark)),
        Text(label,
            style: const TextStyle(
                fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary)),
      ],
    );
  }

  Widget _buildFortuneText() {
    return MiuixCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote,
              color: MiuixColors.primary, size: 24),
          const SizedBox(width: MiuixSpacing.sm),
          Expanded(
            child: Text(
              _result!.text,
              style: const TextStyle(
                  fontSize: MiuixFontSize.md,
                  color: MiuixColors.textPrimary,
                  height: 1.7),
            ),
          ),
        ],
      ),
    );
  }
}

class FortuneResult {
  final int overall;
  final int love;
  final int career;
  final int wealth;
  final String luckyColor;
  final int luckyNumber;
  final String text;
  final String constellation;

  const FortuneResult({
    required this.overall,
    required this.love,
    required this.career,
    required this.wealth,
    required this.luckyColor,
    required this.luckyNumber,
    required this.text,
    required this.constellation,
  });
}
