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
/// NumberPuzzlePage —— 数字华容道
/// 3x3/4x4 数字滑块，移动动画，打乱，计时
/// 步数，自动检测完成，粉色主题
/// ============================================================
class NumberPuzzlePage extends StatefulWidget {
  const NumberPuzzlePage({super.key});

  @override
  State<NumberPuzzlePage> createState() => _NumberPuzzlePageState();
}

class _NumberPuzzlePageState extends State<NumberPuzzlePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  int _difficulty = 0; // 0=3x3, 1=4x4
  late int _gridSize;
  late List<int> _tiles;
  int _emptyIndex = 0;
  int _moves = 0;
  int _elapsedSeconds = 0;
  bool _isPlaying = false;
  bool _isSolved = false;
  Timer? _timer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _gridSize = _difficulty == 0 ? 3 : 4;
    _initPuzzle();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _initPuzzle() {
    _gridSize = _difficulty == 0 ? 3 : 4;
    final total = _gridSize * _gridSize;
    _tiles = List.generate(total, (i) => i == total - 1 ? 0 : i + 1);
    _emptyIndex = total - 1;
    _moves = 0;
    _elapsedSeconds = 0;
    _isPlaying = false;
    _isSolved = false;
    _timer?.cancel();
  }

  void _shufflePuzzle() {
    // 通过随机合法移动打乱，保证可解
    final total = _gridSize * _gridSize;
    _tiles = List.generate(total, (i) => i == total - 1 ? 0 : i + 1);
    _emptyIndex = total - 1;

    final shuffleCount = _gridSize == 3 ? 50 : 100;
    for (int i = 0; i < shuffleCount; i++) {
      final neighbors = _getMovableIndices();
      final moveIdx = neighbors[_random.nextInt(neighbors.length)];
      _tiles[_emptyIndex] = _tiles[moveIdx];
      _tiles[moveIdx] = 0;
      _emptyIndex = moveIdx;
    }

    _moves = 0;
    _elapsedSeconds = 0;
    _isPlaying = true;
    _isSolved = false;
    _startTimer();
    setState(() {});
  }

  List<int> _getMovableIndices() {
    final row = _emptyIndex ~/ _gridSize;
    final col = _emptyIndex % _gridSize;
    final result = <int>[];
    if (row > 0) result.add(_emptyIndex - _gridSize);
    if (row < _gridSize - 1) result.add(_emptyIndex + _gridSize);
    if (col > 0) result.add(_emptyIndex - 1);
    if (col < _gridSize - 1) result.add(_emptyIndex + 1);
    return result;
  }

  void _moveTile(int index) {
    if (!_isPlaying || _isSolved) return;
    if (!_canMove(index)) return;

    setState(() {
      _tiles[_emptyIndex] = _tiles[index];
      _tiles[index] = 0;
      _emptyIndex = index;
      _moves++;
    });

    _checkSolved();
  }

  bool _canMove(int index) {
    final row = index ~/ _gridSize;
    final col = index % _gridSize;
    final emptyRow = _emptyIndex ~/ _gridSize;
    final emptyCol = _emptyIndex % _gridSize;
    return (row == emptyRow && (col - emptyCol).abs() == 1) ||
        (col == emptyCol && (row - emptyRow).abs() == 1);
  }

  void _checkSolved() {
    for (int i = 0; i < _tiles.length - 1; i++) {
      if (_tiles[i] != i + 1) return;
    }
    if (_tiles.last != 0) return;
    _isSolved = true;
    _isPlaying = false;
    _timer?.cancel();
    MiuixToast.show(context, '恭喜完成！用时 ${_formatTime(_elapsedSeconds)}，$_moves 步',
        icon: Icons.emoji_events);
    setState(() {});
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isPlaying) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  String _formatTime(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
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
      appBar: MiuixAppBar(title: '数字华容道'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: Column(
          children: [
            _buildAnimatedItem(_buildStatsRow(), 0),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildDifficultySelector(), 1),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildPuzzleGrid(), 2),
            const SizedBox(height: MiuixSpacing.xl),
            _buildAnimatedItem(_buildActionButtons(), 3),
            if (_isSolved) _buildAnimatedItem(_buildSolvedCard(), 4),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: MiuixCard(
            padding: const EdgeInsets.all(MiuixSpacing.sm),
            child: Column(
              children: [
                const Icon(Icons.timer, color: MiuixColors.primary, size: 18),
                const SizedBox(height: MiuixSpacing.xs),
                Text(_formatTime(_elapsedSeconds),
                    style: const TextStyle(
                        fontSize: MiuixFontSize.xl,
                        fontWeight: FontWeight.bold,
                        color: MiuixColors.primaryDark)),
                const Text('用时',
                    style: TextStyle(
                        fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary)),
              ],
            ),
          ),
        ),
        const SizedBox(width: MiuixSpacing.md),
        Expanded(
          child: MiuixCard(
            padding: const EdgeInsets.all(MiuixSpacing.sm),
            child: Column(
              children: [
                const Icon(Icons.touch_app, color: MiuixColors.info, size: 18),
                const SizedBox(height: MiuixSpacing.xs),
                Text('$_moves',
                    style: const TextStyle(
                        fontSize: MiuixFontSize.xl,
                        fontWeight: FontWeight.bold,
                        color: MiuixColors.info)),
                const Text('步数',
                    style: TextStyle(
                        fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary)),
              ],
            ),
          ),
        ),
        const SizedBox(width: MiuixSpacing.md),
        Expanded(
          child: MiuixCard(
            padding: const EdgeInsets.all(MiuixSpacing.sm),
            child: Column(
              children: [
                Icon(_isSolved ? Icons.check_circle : Icons.grid_view,
                    color: _isSolved ? MiuixColors.success : MiuixColors.textTertiary,
                    size: 18),
                const SizedBox(height: MiuixSpacing.xs),
                Text('${_gridSize}x$_gridSize',
                    style: const TextStyle(
                        fontSize: MiuixFontSize.xl,
                        fontWeight: FontWeight.bold,
                        color: MiuixColors.textPrimary)),
                const Text('难度',
                    style: TextStyle(
                        fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary)),
              ],
            ),
          ),
        ),
      ],
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
          _initPuzzle();
        });
      },
    );
  }

  Widget _buildPuzzleGrid() {
    return Container(
      padding: const EdgeInsets.all(MiuixSpacing.md),
      decoration: BoxDecoration(
        color: MiuixColors.surface,
        borderRadius: MiuixRadius.xlRadius,
        boxShadow: MiuixShadows.md,
        border: Border.all(color: MiuixColors.borderLight),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _tiles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _gridSize,
            crossAxisSpacing: MiuixSpacing.sm,
            mainAxisSpacing: MiuixSpacing.sm,
          ),
          itemBuilder: (context, index) => _buildTile(index),
        ),
      ),
    );
  }

  Widget _buildTile(int index) {
    final value = _tiles[index];
    if (value == 0) {
      return Container(
        decoration: BoxDecoration(
          color: MiuixColors.surfaceVariant,
          borderRadius: MiuixRadius.smRadius,
        ),
      );
    }

    final isCorrect = value == index + 1;
    final canMove = _canMove(index);

    return GestureDetector(
      onTap: () => _moveTile(index),
      child: AnimatedContainer(
        duration: MiuixDuration.fast,
        curve: MiuixCurves.miuixSpring,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isCorrect
                ? [MiuixColors.primaryLight, MiuixColors.primaryDeep]
                : [const Color(0xFFFFE4EC), const Color(0xFFFFD6E4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: MiuixRadius.smRadius,
          boxShadow: canMove
              ? [
                  BoxShadow(
                    color: MiuixColors.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : MiuixShadows.xs,
          border: Border.all(
            color: canMove ? MiuixColors.primary : Colors.transparent,
            width: canMove ? 2 : 0,
          ),
        ),
        child: Center(
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: _gridSize == 3 ? MiuixFontSize.xxxl : MiuixFontSize.xxl,
              fontWeight: FontWeight.bold,
              color: isCorrect ? Colors.white : MiuixColors.primaryDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: MiuixButton(
            label: _isPlaying ? '重新打乱' : '开始游戏',
            icon: Icons.shuffle,
            onPressed: _shufflePuzzle,
          ),
        ),
        const SizedBox(width: MiuixSpacing.md),
        Expanded(
          child: MiuixButton(
            label: '重置',
            icon: Icons.refresh,
            type: MiuixButtonType.secondary,
            onPressed: () {
              _timer?.cancel();
              setState(() => _initPuzzle());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSolvedCard() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, color: Colors.white, size: 40),
          const SizedBox(height: MiuixSpacing.sm),
          const Text('恭喜完成！',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: MiuixFontSize.xl,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: MiuixSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _solvedItem('用时', _formatTime(_elapsedSeconds)),
              _solvedItem('步数', '$_moves'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _solvedItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: MiuixFontSize.xxl,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: MiuixFontSize.xs)),
      ],
    );
  }
}
