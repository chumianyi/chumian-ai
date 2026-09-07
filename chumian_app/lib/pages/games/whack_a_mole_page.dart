import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_segment.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';

/// ============================================================
/// WhackAMolePage —— 打地鼠
/// 3x3/4x4 洞穴，地鼠随机出现，粉色锤子
/// 点击计分，倒计时，连击奖励，最高分
/// ============================================================
class WhackAMolePage extends StatefulWidget {
  const WhackAMolePage({super.key});

  @override
  State<WhackAMolePage> createState() => _WhackAMolePageState();
}

class _WhackAMolePageState extends State<WhackAMolePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  int _difficulty = 0; // 0=3x3, 1=4x4
  int _score = 0;
  int _highScore = 0;
  int _combo = 0;
  int _maxCombo = 0;
  int _timeLeft = 30;
  bool _isPlaying = false;
  bool _gameOver = false;

  late List<bool> _moles;
  late List<bool> _hitMoles;
  Timer? _gameTimer;
  Timer? _moleTimer;
  final Random _random = Random();

  // 锤子动画
  int _hammerCell = -1;
  bool _showHammer = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _initMoles();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _gameTimer?.cancel();
    _moleTimer?.cancel();
    super.dispose();
  }

  void _initMoles() {
    final count = _difficulty == 0 ? 9 : 16;
    _moles = List.filled(count, false);
    _hitMoles = List.filled(count, false);
  }

  void _startGame() {
    setState(() {
      _score = 0;
      _combo = 0;
      _maxCombo = 0;
      _timeLeft = 30;
      _isPlaying = true;
      _gameOver = false;
      _initMoles();
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          _endGame();
        }
      });
    });

    _scheduleMole();
  }

  void _scheduleMole() {
    if (!_isPlaying) return;
    final interval = max(400, 900 - (_score ~/ 50) * 50);
    _moleTimer = Timer(Duration(milliseconds: interval), () {
      if (!_isPlaying || !mounted) return;
      _spawnMole();
      _scheduleMole();
    });
  }

  void _spawnMole() {
    final emptyIndices = <int>[];
    for (int i = 0; i < _moles.length; i++) {
      if (!_moles[i]) emptyIndices.add(i);
    }
    if (emptyIndices.isEmpty) return;
    final idx = emptyIndices[_random.nextInt(emptyIndices.length)];
    setState(() => _moles[idx] = true);

    // 地鼠自动消失
    final duration = max(600, 1200 - (_score ~/ 100) * 100);
    Future.delayed(Duration(milliseconds: duration), () {
      if (!mounted) return;
      if (_moles[idx] && !_hitMoles[idx]) {
        setState(() {
          _moles[idx] = false;
          _combo = 0; // 漏掉地鼠断连击
        });
      }
    });
  }

  void _whackMole(int index) {
    if (!_isPlaying || !_moles[index] || _hitMoles[index]) return;

    setState(() {
      _moles[index] = false;
      _hitMoles[index] = true;
      _combo++;
      if (_combo > _maxCombo) _maxCombo = _combo;
      // 连击奖励
      final bonus = _combo >= 5 ? 20 : (_combo >= 3 ? 10 : 0);
      _score += 10 + bonus;
      if (_score > _highScore) _highScore = _score;

      // 锤子动画
      _hammerCell = index;
      _showHammer = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _hitMoles[index] = false;
        _showHammer = false;
        _hammerCell = -1;
      });
    });
  }

  void _endGame() {
    _gameTimer?.cancel();
    _moleTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _gameOver = true;
      _moles = List.filled(_moles.length, false);
    });
    MiuixToast.show(context, '游戏结束！得分 $_score', icon: Icons.emoji_events);
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
    final crossAxisCount = _difficulty == 0 ? 3 : 4;
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(title: '打地鼠'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: Column(
          children: [
            _buildAnimatedItem(_buildStatsRow(), 0),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildDifficultySelector(), 1),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildGameGrid(crossAxisCount), 2),
            const SizedBox(height: MiuixSpacing.xl),
            _buildAnimatedItem(_buildActionButton(), 3),
            if (_gameOver) _buildAnimatedItem(_buildResultCard(), 4),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _statCard(Icons.star, '$_score', '得分', MiuixColors.primary)),
        const SizedBox(width: MiuixSpacing.md),
        Expanded(child: _statCard(Icons.timer, '$_timeLeft', '倒计时',
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

  Widget _buildDifficultySelector() {
    return MiuixSegment(
      segments: const ['3x3 简单', '4x4 困难'],
      currentIndex: _difficulty,
      onChanged: (i) {
        if (_isPlaying) return;
        setState(() {
          _difficulty = i;
          _initMoles();
        });
      },
    );
  }

  Widget _buildGameGrid(int crossAxisCount) {
    return Container(
      padding: const EdgeInsets.all(MiuixSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: MiuixRadius.xlRadius,
        boxShadow: MiuixShadows.md,
        border: Border.all(color: MiuixColors.borderLight),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _moles.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: MiuixSpacing.md,
          mainAxisSpacing: MiuixSpacing.md,
        ),
        itemBuilder: (context, index) => _buildHole(index),
      ),
    );
  }

  Widget _buildHole(int index) {
    final hasMole = _moles[index];
    final isHit = _hitMoles[index];
    final showHammer = _hammerCell == index && _showHammer;

    return GestureDetector(
      onTap: () => _whackMole(index),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 洞穴
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF8B6F5E),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          // 洞穴内部阴影
          Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF5D4037),
              borderRadius: BorderRadius.circular(46),
            ),
          ),
          // 地鼠
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.elasticOut,
            bottom: hasMole ? 8 : -60,
            child: isHit
                ? Transform.rotate(
                    angle: 0.2,
                    child: const Icon(Icons.star,
                        color: MiuixColors.warning, size: 40),
                  )
                : _buildMole(),
          ),
          // 锤子
          if (showHammer)
            Positioned(
              top: 0,
              right: 0,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: -0.5, end: 0.3),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                builder: (context, val, _) => Transform.rotate(
                  angle: val,
                  child: const Icon(Icons.build_circle,
                      color: MiuixColors.primary, size: 36),
                ),
              ),
            ),
          // 连击提示
          if (isHit && _combo >= 3)
            Positioned(
              top: 0,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 400),
                builder: (context, val, _) => Opacity(
                  opacity: val,
                  child: Transform.translate(
                    offset: Offset(0, -20 * (1 - val)),
                    child: Text(
                      '+${_combo >= 5 ? 30 : 20}',
                      style: const TextStyle(
                          color: MiuixColors.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: MiuixFontSize.lg),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMole() {
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        color: Color(0xFFA1887F),
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          // 眼睛
          Positioned(
            top: 12,
            left: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          // 鼻子
          Positioned(
            top: 24,
            left: 20,
            child: Container(
              width: 10,
              height: 6,
              decoration: BoxDecoration(
                color: MiuixColors.primary.withOpacity(0.6),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return MiuixButton(
      label: _isPlaying ? '游戏中...' : (_gameOver ? '再来一局' : '开始游戏'),
      icon: _isPlaying ? Icons.pause : Icons.play_arrow,
      width: double.infinity,
      onPressed: _isPlaying ? null : _startGame,
    );
  }

  Widget _buildResultCard() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, color: Colors.white, size: 40),
          const SizedBox(height: MiuixSpacing.sm),
          const Text('游戏结束',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: MiuixFontSize.xl,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: MiuixSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _resultItem('得分', '$_score'),
              _resultItem('最高分', '$_highScore'),
              _resultItem('最大连击', '$_maxCombo'),
            ],
          ),
        ],
      ),
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
