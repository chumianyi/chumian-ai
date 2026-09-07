import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';

/// ============================================================
/// Game2048Page —— 2048 游戏
/// 4x4 网格，滑动合并，粉色渐变数字块
/// 动画合并，分数，最高分，撤销，游戏结束
/// ============================================================
class Game2048Page extends StatefulWidget {
  const Game2048Page({super.key});

  @override
  State<Game2048Page> createState() => _Game2048PageState();
}

class _Game2048PageState extends State<Game2048Page>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  static const int _gridSize = 4;
  late List<List<int>> _board;
  int _score = 0;
  int _highScore = 0;
  List<List<int>>? _previousBoard;
  int _previousScore = 0;
  bool _gameOver = false;
  bool _won = false;
  final Random _random = Random();

  static const Map<int, Color> _tileColors = {
    2: Color(0xFFFFE4EC),
    4: Color(0xFFFFD6E4),
    8: Color(0xFFFFC0D6),
    16: Color(0xFFFFA8C8),
    32: Color(0xFFFF8FB5),
    64: Color(0xFFFF6B9D),
    128: Color(0xFFFF5588),
    256: Color(0xFFE8558A),
    512: Color(0xFFD4417A),
    1024: Color(0xFFC2185B),
    2048: Color(0xFFAD1457),
  };

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _initGame();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _initGame() {
    _board = List.generate(_gridSize, (_) => List.filled(_gridSize, 0));
    _score = 0;
    _gameOver = false;
    _won = false;
    _previousBoard = null;
    _addRandomTile();
    _addRandomTile();
  }

  void _addRandomTile() {
    final empty = <Point<int>>[];
    for (int r = 0; r < _gridSize; r++) {
      for (int c = 0; c < _gridSize; c++) {
        if (_board[r][c] == 0) empty.add(Point(r, c));
      }
    }
    if (empty.isEmpty) return;
    final pos = empty[_random.nextInt(empty.length)];
    _board[pos.x][pos.y] = _random.nextDouble() < 0.9 ? 2 : 4;
  }

  bool _canMove() {
    for (int r = 0; r < _gridSize; r++) {
      for (int c = 0; c < _gridSize; c++) {
        if (_board[r][c] == 0) return true;
        if (c < _gridSize - 1 && _board[r][c] == _board[r][c + 1]) return true;
        if (r < _gridSize - 1 && _board[r][c] == _board[r + 1][c]) return true;
      }
    }
    return false;
  }

  void _move(Direction2048 dir) {
    if (_gameOver) return;
    _previousBoard = _board.map((row) => List<int>.from(row)).toList();
    _previousScore = _score;

    bool moved = false;
    switch (dir) {
      case Direction2048.left:
        moved = _moveLeft();
        break;
      case Direction2048.right:
        moved = _moveRight();
        break;
      case Direction2048.up:
        moved = _moveUp();
        break;
      case Direction2048.down:
        moved = _moveDown();
        break;
    }

    if (moved) {
      _addRandomTile();
      if (!_canMove()) {
        _gameOver = true;
        MiuixToast.show(context, '游戏结束！得分 $_score', icon: Icons.game_over);
      }
      if (!_won && _board.any((row) => row.contains(2048))) {
        _won = true;
        MiuixToast.show(context, '恭喜达成 2048！', icon: Icons.emoji_events);
      }
    }
    setState(() {});
  }

  bool _moveLeft() {
    bool moved = false;
    for (int r = 0; r < _gridSize; r++) {
      final row = _board[r].where((v) => v != 0).toList();
      final merged = <int>[];
      for (int i = 0; i < row.length; i++) {
        if (i < row.length - 1 && row[i] == row[i + 1]) {
          merged.add(row[i] * 2);
          _score += row[i] * 2;
          if (_score > _highScore) _highScore = _score;
          i++;
          moved = true;
        } else {
          merged.add(row[i]);
        }
      }
      while (merged.length < _gridSize) merged.add(0);
      if (!moved && !_listEquals(_board[r], merged)) moved = true;
      _board[r] = merged;
    }
    return moved;
  }

  bool _moveRight() {
    bool moved = false;
    for (int r = 0; r < _gridSize; r++) {
      final row = _board[r].where((v) => v != 0).toList().reversed.toList();
      final merged = <int>[];
      for (int i = 0; i < row.length; i++) {
        if (i < row.length - 1 && row[i] == row[i + 1]) {
          merged.add(row[i] * 2);
          _score += row[i] * 2;
          if (_score > _highScore) _highScore = _score;
          i++;
          moved = true;
        } else {
          merged.add(row[i]);
        }
      }
      merged = merged.reversed.toList();
      while (merged.length < _gridSize) merged.insert(0, 0);
      if (!moved && !_listEquals(_board[r], merged)) moved = true;
      _board[r] = merged;
    }
    return moved;
  }

  bool _moveUp() {
    bool moved = false;
    for (int c = 0; c < _gridSize; c++) {
      final col = <int>[];
      for (int r = 0; r < _gridSize; r++) {
        if (_board[r][c] != 0) col.add(_board[r][c]);
      }
      final merged = <int>[];
      for (int i = 0; i < col.length; i++) {
        if (i < col.length - 1 && col[i] == col[i + 1]) {
          merged.add(col[i] * 2);
          _score += col[i] * 2;
          if (_score > _highScore) _highScore = _score;
          i++;
          moved = true;
        } else {
          merged.add(col[i]);
        }
      }
      while (merged.length < _gridSize) merged.add(0);
      for (int r = 0; r < _gridSize; r++) {
        if (_board[r][c] != merged[r]) moved = true;
        _board[r][c] = merged[r];
      }
    }
    return moved;
  }

  bool _moveDown() {
    bool moved = false;
    for (int c = 0; c < _gridSize; c++) {
      final col = <int>[];
      for (int r = _gridSize - 1; r >= 0; r--) {
        if (_board[r][c] != 0) col.add(_board[r][c]);
      }
      final merged = <int>[];
      for (int i = 0; i < col.length; i++) {
        if (i < col.length - 1 && col[i] == col[i + 1]) {
          merged.add(col[i] * 2);
          _score += col[i] * 2;
          if (_score > _highScore) _highScore = _score;
          i++;
          moved = true;
        } else {
          merged.add(col[i]);
        }
      }
      while (merged.length < _gridSize) merged.add(0);
      merged = merged.reversed.toList();
      for (int r = 0; r < _gridSize; r++) {
        if (_board[r][c] != merged[r]) moved = true;
        _board[r][c] = merged[r];
      }
    }
    return moved;
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _undo() {
    if (_previousBoard == null) return;
    setState(() {
      _board = _previousBoard!.map((row) => List<int>.from(row)).toList();
      _score = _previousScore;
      _previousBoard = null;
      _gameOver = false;
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
      appBar: MiuixAppBar(title: '2048'),
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! < -100) _move(Direction2048.up);
          if (details.primaryVelocity! > 100) _move(Direction2048.down);
        },
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < -100) _move(Direction2048.left);
          if (details.primaryVelocity! > 100) _move(Direction2048.right);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MiuixSpacing.lg),
          child: Column(
            children: [
              _buildAnimatedItem(_buildScoreRow(), 0),
              const SizedBox(height: MiuixSpacing.lg),
              _buildAnimatedItem(_buildGameBoard(), 1),
              const SizedBox(height: MiuixSpacing.xl),
              _buildAnimatedItem(_buildDirectionPad(), 2),
              const SizedBox(height: MiuixSpacing.lg),
              _buildAnimatedItem(_buildActionButtons(), 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRow() {
    return Row(
      children: [
        Expanded(
          child: MiuixCard(
            padding: const EdgeInsets.all(MiuixSpacing.md),
            child: Column(
              children: [
                const Text('分数',
                    style: TextStyle(
                        fontSize: MiuixFontSize.sm,
                        color: MiuixColors.textTertiary)),
                Text('$_score',
                    style: const TextStyle(
                        fontSize: MiuixFontSize.xxl,
                        fontWeight: FontWeight.bold,
                        color: MiuixColors.primaryDark)),
              ],
            ),
          ),
        ),
        const SizedBox(width: MiuixSpacing.md),
        Expanded(
          child: MiuixCard(
            padding: const EdgeInsets.all(MiuixSpacing.md),
            child: Column(
              children: [
                const Text('最高分',
                    style: TextStyle(
                        fontSize: MiuixFontSize.sm,
                        color: MiuixColors.textTertiary)),
                Text('$_highScore',
                    style: const TextStyle(
                        fontSize: MiuixFontSize.xxl,
                        fontWeight: FontWeight.bold,
                        color: MiuixColors.warning)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameBoard() {
    return Container(
      padding: const EdgeInsets.all(MiuixSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFBBADA0),
        borderRadius: MiuixRadius.lgRadius,
        boxShadow: MiuixShadows.md,
      ),
      child: Column(
        children: List.generate(_gridSize, (r) {
          return Padding(
            padding: EdgeInsets.only(top: r == 0 ? 0 : MiuixSpacing.sm),
            child: Row(
              children: List.generate(_gridSize, (c) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: c == 0 ? 0 : MiuixSpacing.sm),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _buildTile(_board[r][c]),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTile(int value) {
    final color = _tileColors[value] ?? const Color(0xFF8B0040);
    final textColor = value <= 4 ? MiuixColors.textPrimary : Colors.white;
    final fontSize = value >= 1024
        ? MiuixFontSize.lg
        : (value >= 128 ? MiuixFontSize.xl : MiuixFontSize.xxl);

    return AnimatedContainer(
      duration: MiuixDuration.fast,
      curve: MiuixCurves.miuixSpring,
      decoration: BoxDecoration(
        color: value == 0 ? const Color(0xFFCDC1B4) : color,
        borderRadius: MiuixRadius.smRadius,
        boxShadow: value != 0
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: value != 0
            ? TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1),
                duration: const Duration(milliseconds: 200),
                curve: MiuixCurves.miuixSpring,
                builder: (context, val, _) => Transform.scale(
                  scale: val,
                  child: Text(
                    '$value',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildDirectionPad() {
    return Column(
      children: [
        MiuixIconButton(icon: Icons.arrow_upward, onPressed: () => _move(Direction2048.up)),
        const SizedBox(height: MiuixSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MiuixIconButton(icon: Icons.arrow_back, onPressed: () => _move(Direction2048.left)),
            const SizedBox(width: MiuixSpacing.xl * 2),
            MiuixIconButton(icon: Icons.arrow_forward, onPressed: () => _move(Direction2048.right)),
          ],
        ),
        const SizedBox(height: MiuixSpacing.sm),
        MiuixIconButton(icon: Icons.arrow_downward, onPressed: () => _move(Direction2048.down)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: MiuixButton(
            label: '撤销',
            icon: Icons.undo,
            type: MiuixButtonType.secondary,
            onPressed: _previousBoard == null ? null : _undo,
          ),
        ),
        const SizedBox(width: MiuixSpacing.md),
        Expanded(
          child: MiuixButton(
            label: '新游戏',
            icon: Icons.refresh,
            onPressed: () => setState(() => _initGame()),
          ),
        ),
      ],
    );
  }
}

enum Direction2048 { left, right, up, down }
