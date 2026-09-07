import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_segment.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';

/// ============================================================
/// TicTacToePage —— 井字棋
/// 双人对战 / AI对战，3x3 网格，粉色主题
/// 胜负判定，动画落子，计分板，重新开始
/// ============================================================
class TicTacToePage extends StatefulWidget {
  const TicTacToePage({super.key});

  @override
  State<TicTacToePage> createState() => _TicTacToePageState();
}

class _TicTacToePageState extends State<TicTacToePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  // 棋盘状态：0=空, 1=X, 2=O
  final List<int> _board = List.filled(9, 0);
  int _currentPlayer = 1; // 1=X, 2=O
  int _winner = 0; // 0=进行中, 1=X胜, 2=O胜, 3=平局
  List<int> _winningLine = [];

  // 模式：0=双人对战, 1=AI对战
  int _gameMode = 1;
  bool _aiThinking = false;

  // 计分
  int _xWins = 0;
  int _oWins = 0;
  int _draws = 0;

  // 落子动画
  final List<int> _animatedCells = [];

  static const List<List<int>> _winLines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // 横
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // 竖
    [0, 4, 8], [2, 4, 6], // 斜
  ];

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

  void _placeMark(int index) {
    if (_board[index] != 0 || _winner != 0 || _aiThinking) return;

    setState(() {
      _board[index] = _currentPlayer;
      _animatedCells.add(index);
    });

    // 移除动画标记
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _animatedCells.remove(index));
      }
    });

    final result = _checkWinner();
    if (result != 0) {
      _endGame(result);
      return;
    }

    _currentPlayer = _currentPlayer == 1 ? 2 : 1;

    // AI 回合
    if (_gameMode == 1 && _currentPlayer == 2 && _winner == 0) {
      _aiThinking = true;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        final move = _findBestMove();
        if (move != -1) {
          setState(() {
            _board[move] = 2;
            _animatedCells.add(move);
            _aiThinking = false;
          });
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) setState(() => _animatedCells.remove(move));
          });
          final r = _checkWinner();
          if (r != 0) {
            _endGame(r);
          } else {
            _currentPlayer = 1;
          }
        }
      });
    }
  }

  int _checkWinner() {
    for (final line in _winLines) {
      if (_board[line[0]] != 0 &&
          _board[line[0]] == _board[line[1]] &&
          _board[line[1]] == _board[line[2]]) {
        _winningLine = line;
        return _board[line[0]];
      }
    }
    if (_board.every((c) => c != 0)) return 3; // 平局
    return 0;
  }

  void _endGame(int result) {
    setState(() => _winner = result);
    if (result == 1) {
      _xWins++;
      MiuixToast.show(context, 'X 获胜！', icon: Icons.emoji_events);
    } else if (result == 2) {
      _oWins++;
      MiuixToast.show(context, 'O 获胜！', icon: Icons.emoji_events);
    } else {
      _draws++;
      MiuixToast.show(context, '平局！', icon: Icons.handshake);
    }
  }

  // Minimax AI
  int _findBestMove() {
    int bestScore = -1000;
    int bestMove = -1;
    for (int i = 0; i < 9; i++) {
      if (_board[i] == 0) {
        _board[i] = 2;
        final score = _minimax(0, false);
        _board[i] = 0;
        if (score > bestScore) {
          bestScore = score;
          bestMove = i;
        }
      }
    }
    return bestMove;
  }

  int _minimax(int depth, bool isMaximizing) {
    final result = _checkWinner();
    if (result == 2) return 10 - depth;
    if (result == 1) return depth - 10;
    if (result == 3) return 0;

    if (isMaximizing) {
      int best = -1000;
      for (int i = 0; i < 9; i++) {
        if (_board[i] == 0) {
          _board[i] = 2;
          best = max(best, _minimax(depth + 1, false));
          _board[i] = 0;
        }
      }
      return best;
    } else {
      int best = 1000;
      for (int i = 0; i < 9; i++) {
        if (_board[i] == 0) {
          _board[i] = 1;
          best = min(best, _minimax(depth + 1, true));
          _board[i] = 0;
        }
      }
      return best;
    }
  }

  void _resetGame() {
    setState(() {
      _board.fillRange(0, 9, 0);
      _currentPlayer = 1;
      _winner = 0;
      _winningLine = [];
      _aiThinking = false;
      _animatedCells.clear();
    });
  }

  void _resetScore() {
    setState(() {
      _xWins = 0;
      _oWins = 0;
      _draws = 0;
    });
    _resetGame();
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
      appBar: MiuixAppBar(title: '井字棋'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: Column(
          children: [
            _buildAnimatedItem(_buildScoreBoard(), 0),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildModeSelector(), 1),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildStatusBar(), 2),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildGameBoard(), 3),
            const SizedBox(height: MiuixSpacing.xl),
            _buildAnimatedItem(_buildActionButtons(), 4),
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
          _scoreColumn('X', _xWins, MiuixColors.primary),
          Container(width: 1, height: 40, color: MiuixColors.divider),
          _scoreColumn('平局', _draws, MiuixColors.textTertiary),
          Container(width: 1, height: 40, color: MiuixColors.divider),
          _scoreColumn('O', _oWins, MiuixColors.primaryDark),
        ],
      ),
    );
  }

  Widget _scoreColumn(String label, int score, Color color) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: MiuixFontSize.md, color: color)),
        const SizedBox(height: MiuixSpacing.xs),
        Text('$score',
            style: TextStyle(
                fontSize: MiuixFontSize.xxl,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }

  Widget _buildModeSelector() {
    return MiuixSegment(
      segments: const ['双人对战', 'AI 对战'],
      currentIndex: _gameMode,
      onChanged: (i) {
        setState(() => _gameMode = i);
        _resetGame();
      },
    );
  }

  Widget _buildStatusBar() {
    String text;
    IconData icon;
    if (_winner == 1) {
      text = 'X 获胜！';
      icon = Icons.emoji_events;
    } else if (_winner == 2) {
      text = 'O 获胜！';
      icon = Icons.emoji_events;
    } else if (_winner == 3) {
      text = '平局！';
      icon = Icons.handshake;
    } else if (_aiThinking) {
      text = 'AI 思考中...';
      icon = Icons.auto_awesome;
    } else {
      text = _gameMode == 1
          ? (_currentPlayer == 1 ? '你的回合 (X)' : 'AI 回合 (O)')
          : '${_currentPlayer == 1 ? "X" : "O"} 的回合';
      icon = Icons.play_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: MiuixSpacing.xl, vertical: MiuixSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: MiuixColors.softGradient),
        borderRadius: MiuixRadius.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: MiuixColors.primary, size: 20),
          const SizedBox(width: MiuixSpacing.sm),
          Text(text,
              style: const TextStyle(
                  color: MiuixColors.primaryDark,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildGameBoard() {
    return Container(
      padding: const EdgeInsets.all(MiuixSpacing.lg),
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
          itemCount: 9,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: MiuixSpacing.md,
            mainAxisSpacing: MiuixSpacing.md,
          ),
          itemBuilder: (context, index) => _buildCell(index),
        ),
      ),
    );
  }

  Widget _buildCell(int index) {
    final isWinning = _winningLine.contains(index);
    final isAnimated = _animatedCells.contains(index);
    final mark = _board[index];

    return GestureDetector(
      onTap: () => _placeMark(index),
      child: AnimatedContainer(
        duration: MiuixDuration.fast,
        curve: MiuixCurves.miuixSpring,
        decoration: BoxDecoration(
          color: isWinning
              ? MiuixColors.primaryLight.withOpacity(0.3)
              : MiuixColors.surfaceVariant,
          borderRadius: MiuixRadius.mdRadius,
          border: Border.all(
            color: isWinning ? MiuixColors.primary : MiuixColors.borderLight,
            width: isWinning ? 2 : 1,
          ),
        ),
        child: Center(
          child: isAnimated
              ? TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 350),
                  curve: MiuixCurves.miuixSpring,
                  builder: (context, val, _) => Transform.scale(
                    scale: val,
                    child: _buildMark(mark),
                  ),
                )
              : _buildMark(mark),
        ),
      ),
    );
  }

  Widget _buildMark(int mark) {
    if (mark == 0) return const SizedBox.shrink();
    return Icon(
      mark == 1 ? Icons.close : Icons.panorama_fish_eye,
      size: 48,
      color: mark == 1 ? MiuixColors.primary : MiuixColors.primaryDark,
      weight: 4,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: MiuixButton(
            label: '重新开始',
            icon: Icons.refresh,
            onPressed: _resetGame,
          ),
        ),
        const SizedBox(width: MiuixSpacing.md),
        Expanded(
          child: MiuixButton(
            label: '清空比分',
            icon: Icons.delete_outline,
            type: MiuixButtonType.secondary,
            onPressed: _resetScore,
          ),
        ),
      ],
    );
  }
}
