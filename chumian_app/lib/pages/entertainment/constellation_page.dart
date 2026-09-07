import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_progress.dart';
import 'package:chumian_ai/widgets/miuix/miuix_segment.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';

/// ============================================================
/// ConstellationPage —— 星座运势
/// 12星座选择，今日/本周/本月运势，星座性格
/// 配对指数，粉色主题，卡片展示
/// ============================================================
class ConstellationPage extends StatefulWidget {
  const ConstellationPage({super.key});

  @override
  State<ConstellationPage> createState() => _ConstellationPageState();
}

class _ConstellationPageState extends State<ConstellationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  int _selectedSign = 0;
  int _timeRange = 0; // 0=今日, 1=本周, 2=本月
  int _matchSign = -1;
  bool _showMatch = false;

  static const List<ConstellationData> _signs = [
    ConstellationData(name: '白羊座', icon: Icons.auto_awesome, date: '3.21-4.19', element: '火', trait: '热情勇敢，行动力强'),
    ConstellationData(name: '金牛座', icon: Icons.pets, date: '4.20-5.20', element: '土', trait: '稳重踏实，享受生活'),
    ConstellationData(name: '双子座', icon: Icons.people, date: '5.21-6.21', element: '风', trait: '机智多变，善于交际'),
    ConstellationData(name: '巨蟹座', icon: Icons.cruelty_free, date: '6.22-7.22', element: '水', trait: '温柔体贴，重视家庭'),
    ConstellationData(name: '狮子座', icon: Icons.wb_sunny, date: '7.23-8.22', element: '火', trait: '自信大方，领导力强'),
    ConstellationData(name: '处女座', icon: Icons.eco, date: '8.23-9.22', element: '土', trait: '细致完美，追求卓越'),
    ConstellationData(name: '天秤座', icon: Icons.balance, date: '9.23-10.23', element: '风', trait: '优雅平衡，追求和谐'),
    ConstellationData(name: '天蝎座', icon: Icons.nightlight, date: '10.24-11.22', element: '水', trait: '神秘深邃，意志坚定'),
    ConstellationData(name: '射手座', icon: Icons.arrow_forward, date: '11.23-12.21', element: '火', trait: '乐观自由，热爱冒险'),
    ConstellationData(name: '摩羯座', icon: Icons.terrain, date: '12.22-1.19', element: '土', trait: '踏实努力，目标明确'),
    ConstellationData(name: '水瓶座', icon: Icons.water, date: '1.20-2.18', element: '风', trait: '独立创新，思想前卫'),
    ConstellationData(name: '双鱼座', icon: Icons.waves, date: '2.19-3.20', element: '水', trait: '浪漫感性，富有想象'),
  ];

  static const List<String> _timeRanges = ['今日', '本周', '本月'];

  static const List<String> _fortuneTexts = [
    '今日运势上扬，适合主动出击把握机会。',
    '感情方面会有新的进展，保持真诚态度。',
    '工作中需要更多耐心，细节决定成败。',
    '财运不错，但需谨慎对待大额支出。',
    '人际关系活跃，社交场合会有惊喜。',
    '健康方面注意休息，避免过度疲劳。',
    '学习运旺盛，适合充电提升自我。',
    '今日宜出行，远方会带来好消息。',
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
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  int _getFortuneValue(int seed) {
    final rng = Random(seed + _timeRange * 7 + DateTime.now().day);
    return rng.nextInt(35) + 65;
  }

  int _getMatchScore(int a, int b) {
    if (a == b) return 75;
    final rng = Random(a * 31 + b * 17);
    return rng.nextInt(35) + 55;
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.05, (index * 0.05) + 0.4,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.05, (index * 0.05) + 0.4,
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
    final sign = _signs[_selectedSign];
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(title: '星座运势'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: Column(
          children: [
            _buildAnimatedItem(_buildSignSelector(), 0),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildSignHeader(sign), 1),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildTimeSelector(), 2),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildFortuneDetail(sign), 3),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildPersonalityCard(sign), 4),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildMatchSection(), 5),
          ],
        ),
      ),
    );
  }

  Widget _buildSignSelector() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 12,
        itemBuilder: (context, index) {
          final s = _signs[index];
          final selected = _selectedSign == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedSign = index),
            child: AnimatedContainer(
              duration: MiuixDuration.fast,
              curve: MiuixCurves.miuixSpring,
              width: 72,
              margin: const EdgeInsets.symmetric(horizontal: MiuixSpacing.xs),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(colors: MiuixColors.primaryGradient)
                    : null,
                color: selected ? null : MiuixColors.surface,
                borderRadius: MiuixRadius.lgRadius,
                border: Border.all(
                  color: selected
                      ? MiuixColors.primary
                      : MiuixColors.borderLight,
                ),
                boxShadow: selected ? MiuixShadows.sm : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(s.icon,
                      color: selected ? Colors.white : MiuixColors.primary,
                      size: 24),
                  const SizedBox(height: MiuixSpacing.xs),
                  Text(s.name,
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
    );
  }

  Widget _buildSignHeader(ConstellationData sign) {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(
        colors: [Color(0xFFFFF5F8), Color(0xFFFFEEF3)],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
              shape: BoxShape.circle,
            ),
            child: Icon(sign.icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: MiuixSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sign.name,
                    style: const TextStyle(
                        fontSize: MiuixFontSize.xxl,
                        fontWeight: FontWeight.bold,
                        color: MiuixColors.textPrimary)),
                const SizedBox(height: MiuixSpacing.xs),
                Text('${sign.date} · ${sign.element}象星座',
                    style: const TextStyle(
                        color: MiuixColors.textSecondary,
                        fontSize: MiuixFontSize.sm)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector() {
    return MiuixSegment(
      segments: _timeRanges,
      currentIndex: _timeRange,
      onChanged: (i) => setState(() => _timeRange = i),
    );
  }

  Widget _buildFortuneDetail(ConstellationData sign) {
    final seed = _selectedSign * 13;
    final overall = _getFortuneValue(seed);
    final love = _getFortuneValue(seed + 1);
    final career = _getFortuneValue(seed + 2);
    final wealth = _getFortuneValue(seed + 3);
    final health = _getFortuneValue(seed + 4);
    final text = _fortuneTexts[Random(seed + _timeRange).nextInt(_fortuneTexts.length)];

    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('综合运势',
                  style: TextStyle(
                      fontSize: MiuixFontSize.md,
                      fontWeight: FontWeight.w600,
                      color: MiuixColors.textPrimary)),
              Text('$overall 分',
                  style: const TextStyle(
                      fontSize: MiuixFontSize.xl,
                      fontWeight: FontWeight.bold,
                      color: MiuixColors.primary)),
            ],
          ),
          const SizedBox(height: MiuixSpacing.sm),
          MiuixProgress(value: overall / 100, height: 8),
          const SizedBox(height: MiuixSpacing.lg),
          _fortuneRow('爱情运势', love),
          const SizedBox(height: MiuixSpacing.sm),
          _fortuneRow('事业运势', career),
          const SizedBox(height: MiuixSpacing.sm),
          _fortuneRow('财富运势', wealth),
          const SizedBox(height: MiuixSpacing.sm),
          _fortuneRow('健康运势', health),
          const SizedBox(height: MiuixSpacing.lg),
          Container(
            padding: const EdgeInsets.all(MiuixSpacing.md),
            decoration: BoxDecoration(
              color: MiuixColors.primary.withValues(alpha: 0.08),
              borderRadius: MiuixRadius.mdRadius,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome,
                    color: MiuixColors.primary, size: 18),
                const SizedBox(width: MiuixSpacing.sm),
                Expanded(
                  child: Text(text,
                      style: const TextStyle(
                          color: MiuixColors.textPrimary,
                          fontSize: MiuixFontSize.sm,
                          height: 1.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fortuneRow(String label, int value) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textSecondary))),
        Expanded(
          child: MiuixProgress(
            value: value / 100,
            height: 6,
            color: value >= 80
                ? MiuixColors.success
                : value >= 60
                    ? MiuixColors.primary
                    : MiuixColors.warning,
          ),
        ),
        const SizedBox(width: MiuixSpacing.sm),
        SizedBox(width: 30, child: Text('$value', textAlign: TextAlign.right, style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textSecondary))),
      ],
    );
  }

  Widget _buildPersonalityCard(ConstellationData sign) {
    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('星座性格',
              style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary)),
          const SizedBox(height: MiuixSpacing.md),
          Text(sign.trait,
              style: const TextStyle(
                  color: MiuixColors.textSecondary,
                  fontSize: MiuixFontSize.md,
                  height: 1.6)),
          const SizedBox(height: MiuixSpacing.lg),
          Wrap(
            spacing: MiuixSpacing.sm,
            runSpacing: MiuixSpacing.sm,
            children: [
              _traitChip('守护星', _getRulingPlanet(_selectedSign)),
              _traitChip('象性', '${sign.element}象'),
              _traitChip('最佳配对', _signs[_getBestMatch(_selectedSign)].name),
            ],
          ),
        ],
      ),
    );
  }

  String _getRulingPlanet(int index) {
    const planets = ['火星', '金星', '水星', '月亮', '太阳', '水星', '金星', '冥王星', '木星', '土星', '天王星', '海王星'];
    return planets[index];
  }

  int _getBestMatch(int index) {
    const matches = [4, 7, 9, 10, 0, 5, 11, 1, 8, 2, 3, 6];
    return matches[index];
  }

  Widget _traitChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: MiuixSpacing.md, vertical: MiuixSpacing.xs),
      decoration: BoxDecoration(
        color: MiuixColors.primary.withValues(alpha: 0.1),
        borderRadius: MiuixRadius.pillRadius,
      ),
      child: Text('$label: $value',
          style: const TextStyle(
              color: MiuixColors.primary,
              fontSize: MiuixFontSize.xs,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildMatchSection() {
    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('配对测试',
              style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary)),
          const SizedBox(height: MiuixSpacing.md),
          const Text('选择配对星座：',
              style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm)),
          const SizedBox(height: MiuixSpacing.sm),
          Wrap(
            spacing: MiuixSpacing.xs,
            runSpacing: MiuixSpacing.xs,
            children: List.generate(12, (i) {
              if (i == _selectedSign) return const SizedBox.shrink();
              final selected = _matchSign == i;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _matchSign = i;
                    _showMatch = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: MiuixSpacing.md, vertical: MiuixSpacing.xs),
                  decoration: BoxDecoration(
                    color: selected
                        ? MiuixColors.primary
                        : MiuixColors.surfaceVariant,
                    borderRadius: MiuixRadius.pillRadius,
                    border: Border.all(
                      color: selected
                          ? MiuixColors.primary
                          : MiuixColors.borderLight,
                    ),
                  ),
                  child: Text(_signs[i].name,
                      style: TextStyle(
                          color: selected ? Colors.white : MiuixColors.textSecondary,
                          fontSize: MiuixFontSize.xs)),
                ),
              );
            }),
          ),
          if (_showMatch && _matchSign >= 0) ...[
            const SizedBox(height: MiuixSpacing.lg),
            _buildMatchResult(),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchResult() {
    final score = _getMatchScore(_selectedSign, _matchSign);
    final signA = _signs[_selectedSign];
    final signB = _signs[_matchSign];

    return Container(
      padding: const EdgeInsets.all(MiuixSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: score >= 80
              ? [MiuixColors.primaryLight.withValues(alpha: 0.2), MiuixColors.primary.withValues(alpha: 0.1)]
              : [MiuixColors.surfaceVariant, MiuixColors.surfaceHover],
        ),
        borderRadius: MiuixRadius.mdRadius,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(signA.icon, color: MiuixColors.primary, size: 28),
              const SizedBox(width: MiuixSpacing.sm),
              Text(signA.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: MiuixColors.primaryDark)),
              const SizedBox(width: MiuixSpacing.md),
              const Icon(Icons.favorite, color: MiuixColors.primary, size: 20),
              const SizedBox(width: MiuixSpacing.md),
              Text(signB.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: MiuixColors.primaryDark)),
              const SizedBox(width: MiuixSpacing.sm),
              Icon(signB.icon, color: MiuixColors.primary, size: 28),
            ],
          ),
          const SizedBox(height: MiuixSpacing.md),
          Text('$score%',
              style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: MiuixColors.primary)),
          const SizedBox(height: MiuixSpacing.xs),
          Text(
            score >= 85
                ? '天作之合'
                : score >= 70
                    ? '非常般配'
                    : score >= 55
                        ? '需要磨合'
                        : '互补挑战',
            style: const TextStyle(
                color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm),
          ),
          const SizedBox(height: MiuixSpacing.md),
          MiuixProgress(value: score / 100, height: 8),
        ],
      ),
    );
  }
}

class ConstellationData {
  final String name;
  final IconData icon;
  final String date;
  final String element;
  final String trait;

  const ConstellationData({
    required this.name,
    required this.icon,
    required this.date,
    required this.element,
    required this.trait,
  });
}
