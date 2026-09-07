import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_progress.dart';

/// ============================================================
/// MascotInteractionPage —— 吉祥物互动
/// mascot 形象，点击触发不同动画(眨眼/跳跃/说话)
/// 好感度系统，粉色主题
/// ============================================================
class MascotInteractionPage extends StatefulWidget {
  const MascotInteractionPage({super.key});

  @override
  State<MascotInteractionPage> createState() => _MascotInteractionPageState();
}

class _MascotInteractionPageState extends State<MascotInteractionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _mascotController;

  int _affection = 68;
  int _level = 3;
  String _currentMood = 'happy';
  String _speechBubble = '';
  int _interactionCount = 0;

  static const List<String> _moods = ['happy', 'blink', 'jump', 'talk', 'shy', 'love'];
  static const List<String> _speeches = [
    '你好呀！今天也要开心哦~',
    '初眠最喜欢你了！',
    '工作辛苦了，休息一下吧~',
    '今天天气真好呢！',
    '有什么我可以帮忙的吗？',
    '记得多喝水哦！',
    '初眠会一直陪着你的~',
    '你笑起来真好看！',
  ];

  static const List<InteractionAction> _actions = [
    InteractionAction(icon: Icons.pets, label: '摸摸头', affection: 5),
    InteractionAction(icon: Icons.favorite, label: '送爱心', affection: 8),
    InteractionAction(icon: Icons.fastfood, label: '喂零食', affection: 10),
    InteractionAction(icon: Icons.music_note, label: '唱歌', affection: 6),
    InteractionAction(icon: Icons.sports_esports, label: '玩耍', affection: 7),
    InteractionAction(icon: Icons.bedtime, label: '哄睡', affection: 4),
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _mascotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _entryController.forward();
    _speechBubble = _speeches[0];
  }

  @override
  void dispose() {
    _entryController.dispose();
    _mascotController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.07, (index * 0.07) + 0.4,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.07, (index * 0.07) + 0.4,
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

  void _interact(InteractionAction action) {
    setState(() {
      _interactionCount++;
      _affection = (_affection + action.affection).clamp(0, 100);
      _currentMood = _moods[_interactionCount % _moods.length];
      _speechBubble = _speeches[_interactionCount % _speeches.length];
      if (_affection >= 100 && _level < 5) {
        _level++;
        _affection = 0;
        MiuixToast.show(context,
            message: '好感度升级！当前等级 Lv.$_level',
            type: MiuixToastType.success);
      }
    });
    _mascotController.forward(from: 0);
  }

  void _tapMascot() {
    setState(() {
      _interactionCount++;
      _currentMood = _moods[_interactionCount % _moods.length];
      _speechBubble = _speeches[_interactionCount % _speeches.length];
      _affection = (_affection + 2).clamp(0, 100);
    });
  }

  String _getLevelName() {
    switch (_level) {
      case 1:
        return '初识';
      case 2:
        return '熟悉';
      case 3:
        return '朋友';
      case 4:
        return '亲密';
      case 5:
        return '挚友';
      default:
        return '灵魂伴侣';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '初眠互动',
        backgroundColor: MiuixColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            _buildAnimatedItem(_buildAffectionCard(), 0),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildMascotArea(), 1),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildActionsGrid(), 2),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildStatsCard(), 3),
          ],
        ),
      ),
    );
  }

  Widget _buildAffectionCard() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF8FB5), Color(0xFFFF6B9D), Color(0xFFFF5588)],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: MiuixRadius.lgRadius,
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '好感度',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: MiuixFontSize.sm,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: MiuixRadius.pillRadius,
                          ),
                          child: Text(
                            'Lv.$_level ${_getLevelName()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: MiuixFontSize.xs,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: MiuixRadius.pillRadius,
                      child: LinearProgressIndicator(
                        value: _affection / 100,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor:
                            const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$_affection%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: MiuixFontSize.xl,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMascotArea() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 对话气泡
          if (_speechBubble.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: MiuixRadius.lgRadius,
                boxShadow: MiuixShadows.xs,
              ),
              child: Text(
                _speechBubble,
                style: const TextStyle(
                  fontSize: MiuixFontSize.md,
                  color: MiuixColors.textPrimary,
                ),
              ),
            ),
          const SizedBox(height: 8),
          // 小三角
          CustomPaint(
            size: const Size(20, 10),
            painter: _BubbleTrianglePainter(),
          ),
          const SizedBox(height: 16),
          // 吉祥物
          MiuixRipple(
            borderRadius: MiuixRadius.xl,
            child: GestureDetector(
              onTap: _tapMascot,
              child: AnimatedBuilder(
                animation: _mascotController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0,
                      _currentMood == 'jump'
                          ? -math.sin(_mascotController.value * 2 * math.pi) * 20
                          : math.sin(_mascotController.value * 2 * math.pi) * 3,
                    ),
                    child: Transform.scale(
                      scale: _currentMood == 'love'
                          ? 1 + math.sin(_mascotController.value * 4 * math.pi) * 0.05
                          : 1,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFB6C1), Color(0xFFFF69B4)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: MiuixShadows.lg,
                        ),
                        child: CustomPaint(
                          painter: _MascotPainter(
                            mood: _currentMood,
                            progress: _mascotController.value,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '初眠 · ${_getMoodText()}',
            style: const TextStyle(
              fontSize: MiuixFontSize.md,
              fontWeight: FontWeight.w600,
              color: MiuixColors.primaryDeep,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '点击初眠和它互动吧~',
            style: TextStyle(
              fontSize: MiuixFontSize.sm,
              color: MiuixColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _getMoodText() {
    switch (_currentMood) {
      case 'happy':
        return '开心';
      case 'blink':
        return '眨眼';
      case 'jump':
        return '跳跃';
      case 'talk':
        return '说话';
      case 'shy':
        return '害羞';
      case 'love':
        return '喜爱';
      default:
        return '开心';
    }
  }

  Widget _buildActionsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: _actions.length,
      itemBuilder: (context, index) {
        final action = _actions[index];
        return MiuixRipple(
          borderRadius: MiuixRadius.lg,
          child: GestureDetector(
            onTap: () => _interact(action),
            child: Container(
              decoration: BoxDecoration(
                color: MiuixColors.surface,
                borderRadius: MiuixRadius.lgRadius,
                boxShadow: MiuixShadows.xs,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: MiuixColors.primaryGradient),
                      borderRadius: MiuixRadius.mdRadius,
                    ),
                    child: Icon(action.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action.label,
                    style: const TextStyle(
                      fontSize: MiuixFontSize.sm,
                      fontWeight: FontWeight.w600,
                      color: MiuixColors.textPrimary,
                    ),
                  ),
                  Text(
                    '+${action.affection}',
                    style: const TextStyle(
                      fontSize: MiuixFontSize.xs,
                      color: MiuixColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsCard() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: MiuixColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                '互动统计',
                style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                    Icons.touch_app, '互动次数', '$_interactionCount'),
              ),
              Expanded(
                child: _buildStatItem(Icons.favorite, '好感等级', 'Lv.$_level'),
              ),
              Expanded(
                child: _buildStatItem(
                    Icons.emoji_events, '当前称号', _getLevelName()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: MiuixColors.primary, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: MiuixFontSize.lg,
            fontWeight: FontWeight.bold,
            color: MiuixColors.primaryDeep,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: MiuixFontSize.xs,
            color: MiuixColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class InteractionAction {
  final IconData icon;
  final String label;
  final int affection;
  const InteractionAction({
    required this.icon,
    required this.label,
    required this.affection,
  });
}

/// 对话气泡三角绘制器
class _BubbleTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(size.width / 2 - 8, 0)
      ..lineTo(size.width / 2 + 8, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 吉祥物表情绘制器
class _MascotPainter extends CustomPainter {
  final String mood;
  final double progress;

  _MascotPainter({required this.mood, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final faceRadius = size.width / 2 - 20;

    // 眼睛
    final eyeY = center.dy - 10;
    final eyeOffset = 25.0;
    final blink = mood == 'blink' && (progress * 4 % 1) < 0.2;

    if (blink) {
      // 闭眼（线条）
      canvas.drawLine(
        Offset(center.dx - eyeOffset - 8, eyeY),
        Offset(center.dx - eyeOffset + 8, eyeY),
        Paint()
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(center.dx + eyeOffset - 8, eyeY),
        Offset(center.dx + eyeOffset + 8, eyeY),
        Paint()
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    } else {
      // 睁眼（圆形）
      canvas.drawCircle(
        Offset(center.dx - eyeOffset, eyeY),
        mood == 'love' ? 10 : 8,
        Paint()..color = const Color(0xFF5D4037),
      );
      canvas.drawCircle(
        Offset(center.dx + eyeOffset, eyeY),
        mood == 'love' ? 10 : 8,
        Paint()..color = const Color(0xFF5D4037),
      );
      // 眼睛高光
      canvas.drawCircle(
        Offset(center.dx - eyeOffset + 2, eyeY - 2),
        3,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(center.dx + eyeOffset + 2, eyeY - 2),
        3,
        Paint()..color = Colors.white,
      );
    }

    // 爱心眼
    if (mood == 'love') {
      _drawHeart(canvas, Offset(center.dx - eyeOffset, eyeY), 12);
      _drawHeart(canvas, Offset(center.dx + eyeOffset, eyeY), 12);
    }

    // 腮红
    if (mood == 'shy' || mood == 'happy') {
      canvas.drawCircle(
        Offset(center.dx - 35, eyeY + 15),
        8,
        Paint()..color = const Color(0xFFFF8FB5).withValues(alpha: 0.5),
      );
      canvas.drawCircle(
        Offset(center.dx + 35, eyeY + 15),
        8,
        Paint()..color = const Color(0xFFFF8FB5).withValues(alpha: 0.5),
      );
    }

    // 嘴巴
    final mouthY = center.dy + 15;
    if (mood == 'happy' || mood == 'jump') {
      // 微笑
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(center.dx, mouthY - 5), width: 30, height: 20),
        0,
        math.pi,
        false,
        Paint()
          ..color = const Color(0xFF5D4037)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    } else if (mood == 'talk') {
      // 说话（O型）
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(center.dx, mouthY), width: 14, height: 18),
        Paint()..color = const Color(0xFF5D4037),
      );
    } else if (mood == 'shy') {
      // 小嘴巴
      canvas.drawCircle(
        Offset(center.dx, mouthY),
        5,
        Paint()..color = const Color(0xFF5D4037),
      );
    } else {
      // 普通微笑
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(center.dx, mouthY - 3), width: 20, height: 12),
        0.2,
        math.pi - 0.4,
        false,
        Paint()
          ..color = const Color(0xFF5D4037)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size) {
    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.3);
    path.cubicTo(center.dx - size, center.dy - size * 0.5,
        center.dx - size * 0.5, center.dy - size, center.dx, center.dy - size * 0.3);
    path.cubicTo(center.dx + size * 0.5, center.dy - size, center.dx + size,
        center.dy - size * 0.5, center.dx, center.dy + size * 0.3);
    canvas.drawPath(path, Paint()..color = MiuixColors.error);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
