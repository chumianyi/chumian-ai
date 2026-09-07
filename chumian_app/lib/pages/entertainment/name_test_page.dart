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
/// NameTestPage —— 姓名测试
/// 输入姓名，三才五格，吉凶，性格分析
/// 事业财运，粉色主题，动画结果
/// ============================================================
class NameTestPage extends StatefulWidget {
  const NameTestPage({super.key});

  @override
  State<NameTestPage> createState() => _NameTestPageState();
}

class _NameTestPageState extends State<NameTestPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _resultController;

  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _givenNameController = TextEditingController();
  bool _showResult = false;
  bool _isCalculating = false;
  NameTestResult? _result;

  static const List<String> _personalityTexts = [
    '性格温和善良，待人真诚，富有同情心和责任感。',
    '性格开朗乐观，善于交际，具有较强的领导才能。',
    '性格沉稳内敛，做事认真负责，追求完美。',
    '性格独立坚强，勇于冒险，具有创新精神。',
    '性格细腻敏感，富有艺术天赋，情感丰富。',
    '性格坚毅果敢，目标明确，具有不屈不挠的精神。',
  ];

  static const List<String> _careerTexts = [
    '事业运旺盛，适合从事管理、金融等行业，中年后事业有成。',
    '事业平稳发展，适合从事教育、医疗等服务行业，受人尊敬。',
    '事业有波折但终能成功，适合创业或从事技术工作，大器晚成。',
    '事业运极佳，贵人相助，适合从事艺术、创意行业，名声远扬。',
  ];

  static const List<String> _wealthTexts = [
    '财运亨通，正财偏财皆旺，投资理财眼光独到。',
    '财运平稳，量入为出，中年后财富逐渐积累。',
    '财运有起伏，需谨慎理财，避免投机，踏实积累方为正道。',
    '财运极佳，常有意外之财，但需注意守财，避免铺张浪费。',
  ];

  static const List<String> _healthTexts = [
    '身体健康，精力充沛，但需注意作息规律，避免过度劳累。',
    '体质偏弱，需注意肠胃和呼吸系统，多运动增强体质。',
    '健康状况良好，心态平和是健康的关键，保持乐观心情。',
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
    _surnameController.dispose();
    _givenNameController.dispose();
    super.dispose();
  }

  void _calculate() {
    final surname = _surnameController.text.trim();
    final givenName = _givenNameController.text.trim();
    if (surname.isEmpty || givenName.isEmpty) {
      MiuixToast.show(context, '请输入完整姓名', icon: Icons.error_outline);
      return;
    }

    setState(() {
      _isCalculating = true;
      _showResult = false;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      final seed = surname.codeUnits.fold(0, (a, b) => a + b) +
          givenName.codeUnits.fold(0, (a, b) => a + b);
      final rng = Random(seed);

      // 简化版五格计算（基于笔画数模拟）
      final surnameStrokes = surname.length * 5 + rng.nextInt(10) + 3;
      final givenStrokes = givenName.length * 6 + rng.nextInt(15) + 5;
      final tianGe = surnameStrokes + 1;
      final renGe = surnameStrokes + givenName.length > 1
          ? surnameStrokes + givenName.codeUnits.first % 10 + 1
          : surnameStrokes + givenStrokes;
      final diGe = givenStrokes + 1;
      final waiGe = tianGe + diGe - renGe + 2;
      final zongGe = surnameStrokes + givenStrokes;

      _result = NameTestResult(
        name: '$surname$givenName',
        tianGe: tianGe,
        renGe: renGe,
        diGe: diGe,
        waiGe: waiGe.abs(),
        zongGe: zongGe,
        overall: rng.nextInt(30) + 70,
        personality: _personalityTexts[rng.nextInt(_personalityTexts.length)],
        career: _careerTexts[rng.nextInt(_careerTexts.length)],
        wealth: _wealthTexts[rng.nextInt(_wealthTexts.length)],
        health: _healthTexts[rng.nextInt(_healthTexts.length)],
        luckyColor: ['樱花粉', '玫瑰红', '蜜桃橙', '天空蓝', '薄荷绿'][rng.nextInt(5)],
        luckyNumber: rng.nextInt(9) + 1,
      );

      setState(() {
        _isCalculating = false;
        _showResult = true;
      });
      _resultController.forward(from: 0);
    });
  }

  String _getWuGeLuck(int value) {
    final mod = value % 5;
    return ['大吉', '吉', '半吉', '凶', '大凶'][mod];
  }

  Color _getLuckColor(String luck) {
    switch (luck) {
      case '大吉':
      case '吉':
        return MiuixColors.success;
      case '半吉':
        return MiuixColors.warning;
      default:
        return MiuixColors.error;
    }
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
      appBar: MiuixAppBar(title: '姓名测试'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: Column(
          children: [
            _buildAnimatedItem(_buildInputSection(), 0),
            const SizedBox(height: MiuixSpacing.xl),
            _buildAnimatedItem(_buildCalculateButton(), 1),
            if (_isCalculating) ...[
              const SizedBox(height: MiuixSpacing.xl),
              _buildCalculating(),
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
          const Text('请输入姓名',
              style: TextStyle(
                  fontSize: MiuixFontSize.lg,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary)),
          const SizedBox(height: MiuixSpacing.lg),
          Row(
            children: [
              Expanded(
                child: MiuixInput(
                  controller: _surnameController,
                  hintText: '姓氏',
                  prefixIcon: Icons.person,
                ),
              ),
              const SizedBox(width: MiuixSpacing.md),
              Expanded(
                flex: 2,
                child: MiuixInput(
                  controller: _givenNameController,
                  hintText: '名字',
                  prefixIcon: Icons.edit,
                ),
              ),
            ],
          ),
          const SizedBox(height: MiuixSpacing.md),
          const Text('* 本测试基于传统姓名学五格剖象法，仅供娱乐参考',
              style: TextStyle(
                  color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs)),
        ],
      ),
    );
  }

  Widget _buildCalculateButton() {
    return MiuixButton(
      label: '开始测算',
      icon: Icons.auto_awesome,
      width: double.infinity,
      onPressed: _isCalculating ? null : _calculate,
    );
  }

  Widget _buildCalculating() {
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
                child: const Icon(Icons.calculate,
                    color: MiuixColors.primary, size: 40),
              ),
            ),
            const SizedBox(height: MiuixSpacing.md),
            const Text('正在分析姓名五格...',
                style: TextStyle(color: MiuixColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return AnimatedBuilder(
      animation: _resultController,
      builder: (context, _) => Opacity(
        opacity: _resultController.value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - _resultController.value)),
          child: Column(
            children: [
              _buildOverallCard(),
              const SizedBox(height: MiuixSpacing.lg),
              _buildWuGeCard(),
              const SizedBox(height: MiuixSpacing.lg),
              _buildAnalysisCard(),
              const SizedBox(height: MiuixSpacing.lg),
              _buildLuckyCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallCard() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
      child: Column(
        children: [
          Text(_result!.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: MiuixFontSize.xxl,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4)),
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
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Column(
                children: [
                  Text('${_result!.overall}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                  const Text('综合评分',
                      style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: MiuixSpacing.md),
          Text(
            _result!.overall >= 85 ? '上上之名' : _result!.overall >= 70 ? '上吉之名' : '中吉之名',
            style: const TextStyle(
                color: Colors.white,
                fontSize: MiuixFontSize.xl,
                fontWeight: FontWeight.bold,
                letterSpacing: 6),
          ),
        ],
      ),
    );
  }

  Widget _buildWuGeCard() {
    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('三才五格',
              style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary)),
          const SizedBox(height: MiuixSpacing.md),
          _wuGeRow('天格', _result!.tianGe),
          const SizedBox(height: MiuixSpacing.sm),
          _wuGeRow('人格', _result!.renGe),
          const SizedBox(height: MiuixSpacing.sm),
          _wuGeRow('地格', _result!.diGe),
          const SizedBox(height: MiuixSpacing.sm),
          _wuGeRow('外格', _result!.waiGe),
          const SizedBox(height: MiuixSpacing.sm),
          _wuGeRow('总格', _result!.zongGe),
        ],
      ),
    );
  }

  Widget _wuGeRow(String label, int value) {
    final luck = _getWuGeLuck(value);
    final color = _getLuckColor(luck);
    return Row(
      children: [
        SizedBox(width: 50, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: MiuixColors.textSecondary))),
        Text('$value 画', style: const TextStyle(color: MiuixColors.textPrimary)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: MiuixSpacing.md, vertical: 2),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: MiuixRadius.pillRadius),
          child: Text(luck, style: TextStyle(color: color, fontSize: MiuixFontSize.xs, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildAnalysisCard() {
    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('详细分析',
              style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary)),
          const SizedBox(height: MiuixSpacing.md),
          _analysisItem(Icons.psychology, '性格分析', _result!.personality),
          const SizedBox(height: MiuixSpacing.md),
          _analysisItem(Icons.work, '事业运势', _result!.career),
          const SizedBox(height: MiuixSpacing.md),
          _analysisItem(Icons.payments, '财富运势', _result!.wealth),
          const SizedBox(height: MiuixSpacing.md),
          _analysisItem(Icons.favorite, '健康运势', _result!.health),
        ],
      ),
    );
  }

  Widget _analysisItem(IconData icon, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(MiuixSpacing.sm),
          decoration: BoxDecoration(
            color: MiuixColors.primary.withOpacity(0.1),
            borderRadius: MiuixRadius.smRadius,
          ),
          child: Icon(icon, color: MiuixColors.primary, size: 18),
        ),
        const SizedBox(width: MiuixSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: MiuixColors.textPrimary, fontSize: MiuixFontSize.sm)),
              const SizedBox(height: MiuixSpacing.xs),
              Text(content, style: const TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm, height: 1.6)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLuckyCard() {
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
        Text(value, style: const TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.bold, color: MiuixColors.primaryDark)),
        Text(label, style: const TextStyle(fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary)),
      ],
    );
  }
}

class NameTestResult {
  final String name;
  final int tianGe;
  final int renGe;
  final int diGe;
  final int waiGe;
  final int zongGe;
  final int overall;
  final String personality;
  final String career;
  final String wealth;
  final String health;
  final String luckyColor;
  final int luckyNumber;

  const NameTestResult({
    required this.name,
    required this.tianGe,
    required this.renGe,
    required this.diGe,
    required this.waiGe,
    required this.zongGe,
    required this.overall,
    required this.personality,
    required this.career,
    required this.wealth,
    required this.health,
    required this.luckyColor,
    required this.luckyNumber,
  });
}
