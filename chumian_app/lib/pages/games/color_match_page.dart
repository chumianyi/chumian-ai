import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';

/// ============================================================
/// ColorMatchPage —— 颜色匹配（施特鲁普效应）
/// 显示颜色名(文字颜色与含义不同)，快速选择
/// 倒计时，连击，分数，粉色主题
/// ============================================================
class ColorMatchPage extends StatefulWidget {
  const ColorMatchPage({super.key});

  @override
  State<ColorMatchPage> createState() => _ColorMatchPageState();
}

class _ColorMatchPageState extends State<ColorMatchPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  bool _gameStarted = false;
  bool _gameOver = false;
  int _score = 0;
  int _highScore = 0;
  int _combo = 0;
  int _maxCombo = 0;
  int _timeLeft = 30;
  int _correctCount = 0;
  int _totalCount = 0;

  late String _displayWord;
  late Color _wordColor;
  late Color _correctColor;
  late List<Color> _options;

  Timer? _timer;
  final Random _random = Random();

  static const List<Map<String, dynamic>> _colorData = [
    {'name': '红色', 'color': Color(0xFFFF4D4F)},
    {'name': '蓝色', 'color': Color(0xFF1890FF)},
    {'name': '绿色', 'color': Color(0xFF52C41A)},
    {'name': '黄色', 'color': Color(0xFFFAAD14)},
    {'name': '紫色', 'color': Color(0xFF722ED1)},
    {'name': '橙色', 'color': Color(0xFFFF7A45)},
    {'name': '粉色', 'color': Color(0xFFFF6B9D)},
    {'name': '青色', 'color': Color(0xFF13C2C2)},
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _generateQuestion();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _generateQuestion() {
    final wordIdx = _random.nextInt(_colorData.length);
    int colorIdx;
    do {
      colorIdx = _random.nextInt(_colorData.length);
    } while (colorIdx == wordIdx && _colorData.length > 1);

    _displayWord = _colorData[wordIdx]['name'];
    _wordColor = _colorData[colorIdx]['color'];
    _correctColor = _colorData[colorIdx]['color'];

    // 生成4个选项，包含正确答案
    final optionSet = <Color>{_correctColor};
    while (optionSet.length < 4) {
      optionSet.add(_colorData[_random.nextInt(_colorData.length)]['color']);
    }
    _options = optionSet.toList()..shuffle(_random);
  }

  void _startGame() {
    setState(() {
      _score = 0;
      _combo = 0;
      _maxCombo = 0;
      _timeLeft = 30;
      _correctCount = 0;
      _totalCount = 0;
      _gameStarted = true;
      _gameOver = false;
      _generateQuestion();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          _endGame();
        }
      });
    });
  }

  void _endGame() {
    _timer?.cancel();
    setState(() {
      _gameOver = true;
      _gameStarted = false;
    });
    if (_score > _highScore) _highScore = _score;
    MiuixToast.show(context, '游戏结束！得分 $_score', icon: Icons.emoji_events);
  }

  void _selectColor(Color color) {
    if (!_gameStarted) return;
    _totalCount++;
    if (color == _correctColor) {
      _correctCount++;
      _combo++;
      if (_combo > _maxCombo) _maxCombo = _combo;
      final bonus = _combo >= 5 ? 15 : (_combo >= 3 ? 8 : 0);
      _score += 10 + bonus;
    } else {
      _combo = 0;
      _score = max(0, _score - 5);
    }
    _generateQuestion();
    setState(() {});
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
      appBar: MiuixAppBar(title: '颜色匹配'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: _gameOver ? _buildResultPage() : _buildGameContent(),
      ),
    );
  }

  Widget _buildGameContent() {
    return Column(
      children: [
        _buildAnimatedItem(_buildStatsRow(), 0),
        const SizedBox(height: MiuixSpacing.xl),
        _buildAnimatedItem(_buildQuestionCard(), 1),
        const SizedBox(height: MiuixSpacing.xl),
        _buildAnimatedItem(
          const Text('点击文字的实际颜色（不是文字含义）',
              style: TextStyle(
                  color: MiuixColors.textTertiary, fontSize: MiuixFontSize.sm)),
          2,
        ),
        const SizedBox(height: MiuixSpacing.lg),
        _buildAnimatedItem(_buildOptionsGrid(), 3),
        if (!_gameStarted) ...[
          const SizedBox(height: MiuixSpacing.xl),
          _buildAnimatedItem(_buildStartButton(), 4),
        ],
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _statCard(Icons.star, '$_score', '得分', MiuixColors.primary)),
        const SizedBox(width: MiuixSpacing.md),
        Expanded(child: _statCard(Icons.timer, '$_timeLeft', '时间',
            _timeLeft <= 5 ? MiuixColors.error : MiuixColors.info)),
        const SizedBox(width: MiuixSpacing.md),
        Expanded(child: _statCard(Icons.local_fire_department, '$_combo', '连击',
            _combo >= 3 ? MiuixColors.warning : MiuixColors.textTertiary)),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    return MiuixCard(
      padding: const EdgeInsets.all(MiuixSpacing.sm),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: MiuixSpacing.xs),
          Text(value,
              style: TextStyle(
                  fontSize: MiuixFontSize.xl,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(
        colors: [Color(0xFFFFF5F8), Color(0xFFFFEEF3)],
      ),
      padding: const EdgeInsets.symmetric(vertical: MiuixSpacing.xxxl, horizontal: MiuixSpacing.xl),
      child: Center(
        child: AnimatedSwitcher(
          duration: MiuixDuration.fast,
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
          child: Text(
            _displayWord,
            key: ValueKey('$_displayWord$_wordColor'),
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: _wordColor,
              letterSpacing: 4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _options.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: MiuixSpacing.md,
        mainAxisSpacing: MiuixSpacing.md,
        childAspectRatio: 2.5,
      ),
      itemBuilder: (context, index) {
        final color = _options[index];
        return GestureDetector(
          onTap: () => _selectColor(color),
          child: AnimatedContainer(
            duration: MiuixDuration.fast,
            curve: MiuixCurves.miuixSpring,
            decoration: BoxDecoration(
              color: color,
              borderRadius: MiuixRadius.lgRadius,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getColorName(color),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: MiuixFontSize.lg,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getColorName(Color color) {
    for (final data in _colorData) {
      if (data['color'] == color) return data['name'];
    }
    return '未知';
  }

  Widget _buildStartButton() {
    return MiuixButton(
      label: '开始游戏',
      icon: Icons.play_arrow,
      width: double.infinity,
      onPressed: _startGame,
    );
  }

  Widget _buildResultPage() {
    final accuracy = _totalCount > 0
        ? (_correctCount / _totalCount * 100).toInt()
        : 0;
    return Column(
      children: [
        _buildAnimatedItem(
          MiuixCard(
            style: MiuixCardStyle.gradient,
            gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
            child: Column(
              children: [
                const Icon(Icons.emoji_events, color: Colors.white, size: 48),
                const SizedBox(height: MiuixSpacing.md),
                const Text('游戏结束',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: MiuixFontSize.xxl,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: MiuixSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _resultItem('得分', '$_score'),
                    _resultItem('正确率', '$accuracy%'),
                    _resultItem('最大连击', '$_maxCombo'),
                  ],
                ),
                const SizedBox(height: MiuixSpacing.lg),
                Text('最高分: $_highScore',
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          0,
        ),
        const SizedBox(height: MiuixSpacing.xl),
        _buildAnimatedItem(
          MiuixButton(
            label: '再来一局',
            icon: Icons.refresh,
            width: double.infinity,
            onPressed: _startGame,
          ),
          1,
        ),
      ],
    );
  }

  Widget _resultItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: MiuixFontSize.xxl,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: MiuixFontSize.xs)),
      ],
    );
  }
}
