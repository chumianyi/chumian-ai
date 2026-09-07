import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';

/// ============================================================
/// SnakePage —— 贪吃蛇
/// 方向控制(滑动/按钮)，粉色蛇身，食物，分数
/// 速度递增，游戏结束/重新开始，网格背景
/// ============================================================
class SnakePage extends StatefulWidget {
  const SnakePage({super.key});

  @override
  State<SnakePage> createState() => _SnakePageState();
}

class _SnakePageState extends State<SnakePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  static const int _gridSize = 20;
  static const int _initialSpeed = 300; // ms per move

  List<Point<int>> _snake = [];
  Point<int>? _food;
  Direction _direction = Direction.right;
  Direction _nextDirection = Direction.right;
  Timer? _gameTimer;
  bool _isPlaying = false;
  bool _isGameOver = false;
  int _score = 0;
  int _highScore = 0;
  int _speed = _initialSpeed;
  final Random _random = Random();

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
    _gameTimer?.cancel();
    super.dispose();
  }

  void _initGame() {
    _snake = [
      const Point(10, 10),
      const Point(9, 10),
      const Point(8, 10),
    ];
    _direction = Direction.right;
    _nextDirection = Direction.right;
    _score = 0;
    _speed = _initialSpeed;
    _isGameOver = false;
    _spawnFood();
  }

  void _spawnFood() {
    Point<int> p;
    do {
      p = Point(_random.nextInt(_gridSize), _random.nextInt(_gridSize));
    } while (_snake.contains(p));
    _food = p;
  }

  void _startGame() {
    if (_isGameOver) _initGame();
    setState(() => _isPlaying = true);
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(Duration(milliseconds: _speed), (_) => _tick());
  }

  void _pauseGame() {
    setState(() => _isPlaying = false);
    _gameTimer?.cancel();
  }

  void _tick() {
    if (!mounted) return;
    _direction = _nextDirection;
    final head = _snake.first;
    Point<int> newHead;
    switch (_direction) {
      case Direction.up:
        newHead = Point(head.x, head.y - 1);
        break;
      case Direction.down:
        newHead = Point(head.x, head.y + 1);
        break;
      case Direction.left:
        newHead = Point(head.x - 1, head.y);
        break;
      case Direction.right:
        newHead = Point(head.x + 1, head.y);
        break;
    }

    // 撞墙
    if (newHead.x < 0 ||
        newHead.x >= _gridSize ||
        newHead.y < 0 ||
        newHead.y >= _gridSize) {
      _gameOver();
      return;
    }
    // 撞自己
    if (_snake.contains(newHead)) {
      _gameOver();
      return;
    }

    setState(() {
      _snake.insert(0, newHead);
      if (newHead == _food) {
        _score += 10;
        if (_score > _highScore) _highScore = _score;
        _spawnFood();
        // 提速
        if (_speed > 100) {
          _speed -= 10;
          _gameTimer?.cancel();
          _gameTimer = Timer.periodic(
              Duration(milliseconds: _speed), (_) => _tick());
        }
      } else {
        _snake.removeLast();
      }
    });
  }

  void _gameOver() {
    _gameTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _isGameOver = true;
    });
    MiuixToast.show(context, '游戏结束！得分 $_score', icon: Icons.game_over);
  }

  void _changeDirection(Direction d) {
    if (!_isPlaying) return;
    // 禁止反向
    if ((d == Direction.up && _direction == Direction.down) ||
        (d == Direction.down && _direction == Direction.up) ||
        (d == Direction.left && _direction == Direction.right) ||
        (d == Direction.right && _direction == Direction.left)) {
      return;
    }
    _nextDirection = d;
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
      appBar: MiuixAppBar(title: '贪吃蛇'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: Column(
          children: [
            _buildAnimatedItem(_buildScoreRow(), 0),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildGameArea(), 1),
            const SizedBox(height: MiuixSpacing.xl),
            _buildAnimatedItem(_buildControls(), 2),
          ],
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
                const Icon(Icons.star, color: MiuixColors.primary, size: 20),
                const SizedBox(height: MiuixSpacing.xs),
                Text('$_score',
                    style: const TextStyle(
                        fontSize: MiuixFontSize.xxl,
                        fontWeight: FontWeight.bold,
                        color: MiuixColors.primaryDark)),
                const Text('当前得分',
                    style: TextStyle(
                        fontSize: MiuixFontSize.xs,
                        color: MiuixColors.textTertiary)),
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
                const Icon(Icons.emoji_events,
                    color: MiuixColors.warning, size: 20),
                const SizedBox(height: MiuixSpacing.xs),
                Text('$_highScore',
                    style: const TextStyle(
                        fontSize: MiuixFontSize.xxl,
                        fontWeight: FontWeight.bold,
                        color: MiuixColors.warning)),
                const Text('最高分',
                    style: TextStyle(
                        fontSize: MiuixFontSize.xs,
                        color: MiuixColors.textTertiary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameArea() {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy < -5) _changeDirection(Direction.up);
        if (details.delta.dy > 5) _changeDirection(Direction.down);
      },
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx < -5) _changeDirection(Direction.left);
        if (details.delta.dx > 5) _changeDirection(Direction.right);
      },
      child: Container(
        decoration: BoxDecoration(
          color: MiuixColors.surface,
          borderRadius: MiuixRadius.lgRadius,
          boxShadow: MiuixShadows.md,
          border: Border.all(color: MiuixColors.borderLight),
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: _SnakePainter(
              snake: _snake,
              food: _food,
              gridSize: _gridSize,
              isGameOver: _isGameOver,
            ),
            child: _isGameOver
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sentiment_dissatisfied,
                            size: 48, color: MiuixColors.primary),
                        const SizedBox(height: MiuixSpacing.md),
                        const Text('游戏结束',
                            style: TextStyle(
                                fontSize: MiuixFontSize.xl,
                                fontWeight: FontWeight.bold,
                                color: MiuixColors.primaryDark)),
                        Text('得分 $_score',
                            style: const TextStyle(
                                color: MiuixColors.textSecondary)),
                      ],
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MiuixIconButton(
              icon: Icons.arrow_upward,
              onPressed: () => _changeDirection(Direction.up),
            ),
          ],
        ),
        const SizedBox(height: MiuixSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MiuixIconButton(
              icon: Icons.arrow_back,
              onPressed: () => _changeDirection(Direction.left),
            ),
            const SizedBox(width: MiuixSpacing.xl * 2),
            MiuixIconButton(
              icon: Icons.arrow_forward,
              onPressed: () => _changeDirection(Direction.right),
            ),
          ],
        ),
        const SizedBox(height: MiuixSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MiuixIconButton(
              icon: Icons.arrow_downward,
              onPressed: () => _changeDirection(Direction.down),
            ),
          ],
        ),
        const SizedBox(height: MiuixSpacing.xl),
        Row(
          children: [
            Expanded(
              child: MiuixButton(
                label: _isPlaying ? '暂停' : (_isGameOver ? '重新开始' : '开始'),
                icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                onPressed: _isPlaying ? _pauseGame : _startGame,
              ),
            ),
            const SizedBox(width: MiuixSpacing.md),
            Expanded(
              child: MiuixButton(
                label: '重置',
                icon: Icons.refresh,
                type: MiuixButtonType.secondary,
                onPressed: () {
                  _pauseGame();
                  setState(() => _initGame());
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum Direction { up, down, left, right }

class _SnakePainter extends CustomPainter {
  final List<Point<int>> snake;
  final Point<int>? food;
  final int gridSize;
  final bool isGameOver;

  _SnakePainter({
    required this.snake,
    required this.food,
    required this.gridSize,
    required this.isGameOver,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / gridSize;
    final cellH = size.height / gridSize;

    // 网格背景
    final gridPaint = Paint()
      ..color = MiuixColors.divider.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= gridSize; i++) {
      canvas.drawLine(
          Offset(i * cellW, 0), Offset(i * cellW, size.height), gridPaint);
      canvas.drawLine(
          Offset(0, i * cellH), Offset(size.width, i * cellH), gridPaint);
    }

    // 食物
    if (food != null) {
      final foodRect = Rect.fromLTWH(
        food!.x * cellW + cellW * 0.15,
        food!.y * cellH + cellH * 0.15,
        cellW * 0.7,
        cellH * 0.7,
      );
      final foodPaint = Paint()
        ..shader = const LinearGradient(
          colors: [MiuixColors.primaryLight, MiuixColors.primaryDeep],
        ).createShader(foodRect);
      canvas.drawOval(foodRect, foodPaint);
      // 高光
      canvas.drawOval(
        Rect.fromLTWH(foodRect.left + cellW * 0.1, foodRect.top + cellH * 0.05,
            cellW * 0.25, cellH * 0.2),
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );
    }

    // 蛇身
    for (int i = snake.length - 1; i >= 0; i--) {
      final seg = snake[i];
      final isHead = i == 0;
      final rect = Rect.fromLTWH(
        seg.x * cellW + 1,
        seg.y * cellH + 1,
        cellW - 2,
        cellH - 2,
      );
      final t = i / snake.length;
      final color = Color.lerp(
          MiuixColors.primaryDeep, MiuixColors.primaryLight, t)!;
      final segPaint = Paint()
        ..color = isHead ? MiuixColors.primaryDeep : color
        ..style = PaintingStyle.fill;
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      canvas.drawRRect(rrect, segPaint);

      // 蛇头眼睛
      if (isHead) {
        final eyePaint = Paint()..color = Colors.white;
        final eyeSize = cellW * 0.15;
        canvas.drawCircle(
            Offset(rect.left + cellW * 0.3, rect.top + cellH * 0.35),
            eyeSize,
            eyePaint);
        canvas.drawCircle(
            Offset(rect.right - cellW * 0.3, rect.top + cellH * 0.35),
            eyeSize,
            eyePaint);
        final pupilPaint = Paint()..color = MiuixColors.textPrimary;
        canvas.drawCircle(
            Offset(rect.left + cellW * 0.3, rect.top + cellH * 0.35),
            eyeSize * 0.5,
            pupilPaint);
        canvas.drawCircle(
            Offset(rect.right - cellW * 0.3, rect.top + cellH * 0.35),
            eyeSize * 0.5,
            pupilPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SnakePainter oldDelegate) =>
      oldDelegate.snake != snake ||
      oldDelegate.food != food ||
      oldDelegate.isGameOver != isGameOver;
}
