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
/// MemoryCardPage —— 记忆翻牌
/// 4x4/6x6 网格，粉色卡片，翻转动画，配对消除
/// 步数统计，计时，难度选择
/// ============================================================
class MemoryCardPage extends StatefulWidget {
  const MemoryCardPage({super.key});

  @override
  State<MemoryCardPage> createState() => _MemoryCardPageState();
}

class _MemoryCardPageState extends State<MemoryCardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  int _difficulty = 0; // 0=4x4简单, 1=6x6困难
  late List<MemoryCard> _cards;
  List<int> _flippedIndices = [];
  bool _isChecking = false;
  int _moves = 0;
  int _matchedPairs = 0;
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _gameStarted = false;
  bool _gameWon = false;

  static const List<IconData> _cardIcons = [
    Icons.favorite,
    Icons.star,
    Icons.heart_broken,
    Icons.local_florist,
    Icons.cake,
    Icons.spa,
    Icons.auto_awesome,
    Icons.music_note,
    Icons.pets,
    Icons.eco,
    Icons.bedtime,
    Icons.wb_sunny,
    Icons.icecream,
    Icons.coffee,
    Icons.anchor,
    Icons.palette,
    Icons.umbrella,
    Icons.volunteer_activism,
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _initCards();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _initCards() {
    final pairCount = _difficulty == 0 ? 8 : 18;
    final selectedIcons = _cardIcons.take(pairCount).toList();
    final List<MemoryCard> cardList = [];
    for (int i = 0; i < pairCount; i++) {
      cardList.add(MemoryCard(icon: selectedIcons[i], pairId: i));
      cardList.add(MemoryCard(icon: selectedIcons[i], pairId: i));
    }
    cardList.shuffle(Random());
    _cards = cardList;
    _flippedIndices = [];
    _moves = 0;
    _matchedPairs = 0;
    _elapsedSeconds = 0;
    _gameStarted = false;
    _gameWon = false;
    _timer?.cancel();
  }

  void _startTimer() {
    if (_gameStarted) return;
    _gameStarted = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  void _flipCard(int index) {
    if (_isChecking || _gameWon) return;
    if (_cards[index].isFlipped || _cards[index].isMatched) return;
    if (_flippedIndices.length >= 2) return;

    _startTimer();
    setState(() {
      _cards[index].isFlipped = true;
      _flippedIndices.add(index);
    });

    if (_flippedIndices.length == 2) {
      _moves++;
      _isChecking = true;
      final first = _cards[_flippedIndices[0]];
      final second = _cards[_flippedIndices[1]];

      if (first.pairId == second.pairId) {
        // 配对成功
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {
            _cards[_flippedIndices[0]].isMatched = true;
            _cards[_flippedIndices[1]].isMatched = true;
            _matchedPairs++;
            _flippedIndices.clear();
            _isChecking = false;
          });
          final totalPairs = _difficulty == 0 ? 8 : 18;
          if (_matchedPairs == totalPairs) {
            _gameWon = true;
            _timer?.cancel();
            MiuixToast.show(context, '恭喜通关！用时 ${_formatTime(_elapsedSeconds)}',
                icon: Icons.emoji_events);
          }
        });
      } else {
        // 配对失败，翻回
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          setState(() {
            _cards[_flippedIndices[0]].isFlipped = false;
            _cards[_flippedIndices[1]].isFlipped = false;
            _flippedIndices.clear();
            _isChecking = false;
          });
        });
      }
    }
  }

  String _formatTime(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  void _resetGame() {
    setState(() => _initCards());
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
    final crossAxisCount = _difficulty == 0 ? 4 : 6;
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(title: '记忆翻牌'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: Column(
          children: [
            _buildAnimatedItem(_buildStatsRow(), 0),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildDifficultySelector(), 1),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildCardGrid(crossAxisCount), 2),
            const SizedBox(height: MiuixSpacing.xl),
            _buildAnimatedItem(_buildActionButton(), 3),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(Icons.timer, _formatTime(_elapsedSeconds), '用时'),
        ),
        const SizedBox(width: MiuixSpacing.md),
        Expanded(
          child: _statCard(Icons.touch_app, '$_moves', '步数'),
        ),
        const SizedBox(width: MiuixSpacing.md),
        Expanded(
          child: _statCard(Icons.check_circle, '$_matchedPairs', '配对'),
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return MiuixCard(
      padding: const EdgeInsets.all(MiuixSpacing.sm),
      child: Column(
        children: [
          Icon(icon, color: MiuixColors.primary, size: 18),
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
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return MiuixSegment(
      segments: const ['4x4 简单', '6x6 困难'],
      currentIndex: _difficulty,
      onChanged: (i) {
        setState(() {
          _difficulty = i;
          _initCards();
        });
      },
    );
  }

  Widget _buildCardGrid(int crossAxisCount) {
    return Container(
      padding: const EdgeInsets.all(MiuixSpacing.md),
      decoration: BoxDecoration(
        color: MiuixColors.surface,
        borderRadius: MiuixRadius.lgRadius,
        boxShadow: MiuixShadows.sm,
        border: Border.all(color: MiuixColors.borderLight),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _cards.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: MiuixSpacing.sm,
          mainAxisSpacing: MiuixSpacing.sm,
        ),
        itemBuilder: (context, index) => _buildCard(index),
      ),
    );
  }

  Widget _buildCard(int index) {
    final card = _cards[index];
    return GestureDetector(
      onTap: () => _flipCard(index),
      child: AnimatedBuilder(
        animation: _entryController,
        builder: (context, _) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: card.isFlipped || card.isMatched ? 1 : 0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            builder: (context, value, _) {
              final isFront = value > 0.5;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(pi * value),
                child: isFront
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(pi),
                        child: _buildCardFront(card),
                      )
                    : _buildCardBack(card),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCardFront(MemoryCard card) {
    return Container(
      decoration: BoxDecoration(
        gradient: card.isMatched
            ? const LinearGradient(colors: [
                MiuixColors.primaryLight,
                MiuixColors.primaryDeep
              ])
            : const LinearGradient(colors: [
                Color(0xFFFFE4EC),
                Color(0xFFFFD6E4),
              ]),
        borderRadius: MiuixRadius.smRadius,
        border: Border.all(
          color: card.isMatched ? MiuixColors.primary : MiuixColors.border,
          width: card.isMatched ? 2 : 1,
        ),
      ),
      child: Center(
        child: Icon(
          card.icon,
          color: card.isMatched ? Colors.white : MiuixColors.primary,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildCardBack(MemoryCard card) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: MiuixColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: MiuixRadius.smRadius,
        boxShadow: MiuixShadows.xs,
      ),
      child: const Center(
        child: Icon(Icons.help_outline, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildActionButton() {
    return MiuixButton(
      label: '重新开始',
      icon: Icons.refresh,
      width: double.infinity,
      onPressed: _resetGame,
    );
  }
}

class MemoryCard {
  final IconData icon;
  final int pairId;
  bool isFlipped;
  bool isMatched;

  MemoryCard({
    required this.icon,
    required this.pairId,
    this.isFlipped = false,
    this.isMatched = false,
  });
}
