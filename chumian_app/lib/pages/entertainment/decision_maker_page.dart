import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_chip.dart';
import 'package:chumian_ai/widgets/miuix/miuix_input.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';

/// ============================================================
/// DecisionMakerPage —— 帮你决定
/// 输入选项(2-8个)，转盘动画，随机选择
/// 历史记录，预设选项(吃什么/去哪玩)，粉色转盘
/// ============================================================
class DecisionMakerPage extends StatefulWidget {
  const DecisionMakerPage({super.key});

  @override
  State<DecisionMakerPage> createState() => _DecisionMakerPageState();
}

class _DecisionMakerPageState extends State<DecisionMakerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _wheelController;

  final List<TextEditingController> _optionControllers = [];
  int _optionCount = 4;
  String? _result;
  bool _isSpinning = false;
  final List<String> _history = [];
  final Random _random = Random();

  static const List<List<String>> _presets = [
    ['火锅', '烧烤', '日料', '川菜', '粤菜', '西餐', '韩餐', '泰餐'],
    ['公园', '电影院', '商场', '博物馆', '游乐园', '海边', '爬山', '图书馆'],
    ['睡觉', '打游戏', '看剧', '看书', '运动', '做饭', '逛街', '听音乐'],
  ];
  static const List<String> _presetNames = ['吃什么', '去哪玩', '干什么'];

  static const List<Color> _wheelColors = [
    Color(0xFFFF6B9D),
    Color(0xFFFF8FB5),
    Color(0xFFFFA8C8),
    Color(0xFFFFC0D6),
    Color(0xFFFF5588),
    Color(0xFFE8558A),
    Color(0xFFFFD6E4),
    Color(0xFFFFB6C9),
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _initControllers();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _wheelController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _initControllers() {
    _optionControllers.clear();
    for (int i = 0; i < _optionCount; i++) {
      _optionControllers.add(TextEditingController());
    }
  }

  void _updateOptionCount(int count) {
    setState(() {
      _optionCount = count;
      _initControllers();
      _result = null;
    });
  }

  void _applyPreset(int index) {
    final preset = _presets[index];
    setState(() {
      _optionCount = preset.length;
      _initControllers();
      for (int i = 0; i < preset.length; i++) {
        _optionControllers[i].text = preset[i];
      }
      _result = null;
    });
    MiuixToast.show(context, '已加载「${_presetNames[index]}」选项', icon: Icons.check_circle);
  }

  void _spin() {
    final options = _optionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    if (options.length < 2) {
      MiuixToast.show(context, '请至少输入2个选项', icon: Icons.error_outline);
      return;
    }

    setState(() {
      _isSpinning = true;
      _result = null;
    });

    final winnerIndex = _random.nextInt(options.length);
    final targetAngle = 2 * pi * 3 + (2 * pi * (1 - winnerIndex / options.length) - pi / options.length);

    _wheelController.reset();
    final animation = Tween<double>(begin: 0, end: targetAngle).animate(
      CurvedAnimation(parent: _wheelController, curve: Curves.decelerate),
    );

    animation.addListener(() => setState(() {}));
    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _result = options[winnerIndex];
          _isSpinning = false;
          _history.insert(0, _result!);
          if (_history.length > 10) _history.removeLast();
        });
        MiuixToast.show(context, '决定了：$_result！', icon: Icons.celebration);
      }
    });

    _wheelController.forward();
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
      appBar: MiuixAppBar(title: '帮你决定'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: Column(
          children: [
            _buildAnimatedItem(_buildPresetChips(), 0),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildOptionCount(), 1),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildOptionsInput(), 2),
            const SizedBox(height: MiuixSpacing.xl),
            _buildAnimatedItem(_buildWheel(), 3),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildResultDisplay(), 4),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildSpinButton(), 5),
            if (_history.isNotEmpty) ...[
              const SizedBox(height: MiuixSpacing.lg),
              _buildAnimatedItem(_buildHistory(), 6),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChips() {
    return Wrap(
      spacing: MiuixSpacing.sm,
      runSpacing: MiuixSpacing.sm,
      children: List.generate(_presetNames.length, (i) {
        return MiuixChip(
          label: _presetNames[i],
          icon: Icons.category,
          onTap: () => _applyPreset(i),
        );
      }),
    );
  }

  Widget _buildOptionCount() {
    return MiuixCard(
      child: Row(
        children: [
          const Text('选项数量', style: TextStyle(fontWeight: FontWeight.w500, color: MiuixColors.textPrimary)),
          const Spacer(),
          ...List.generate(7, (i) {
            final count = i + 2;
            final selected = _optionCount == count;
            return GestureDetector(
              onTap: () => _updateOptionCount(count),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: selected ? MiuixColors.primary : MiuixColors.surfaceVariant,
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? MiuixColors.primary : MiuixColors.borderLight),
                ),
                child: Center(
                  child: Text('$count',
                      style: TextStyle(
                          color: selected ? Colors.white : MiuixColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: MiuixFontSize.sm)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOptionsInput() {
    return MiuixCard(
      child: Column(
        children: List.generate(_optionCount, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i == _optionCount - 1 ? 0 : MiuixSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _wheelColors[i % _wheelColors.length],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: MiuixSpacing.sm),
                Expanded(
                  child: MiuixInput(
                    controller: _optionControllers[i],
                    hintText: '选项 ${i + 1}',
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWheel() {
    final options = _optionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    final angle = _wheelController.value;

    return Center(
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 指针
            Positioned(
              top: 0,
              child: CustomPaint(
                size: const Size(30, 40),
                painter: _PointerPainter(),
              ),
            ),
            // 转盘
            Transform.rotate(
              angle: angle,
              child: CustomPaint(
                size: const Size(260, 260),
                painter: _WheelPainter(
                  options: options.isEmpty ? ['选项1', '选项2'] : options,
                  colors: _wheelColors,
                ),
              ),
            ),
            // 中心圆
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
                shape: BoxShape.circle,
                boxShadow: MiuixShadows.md,
              ),
              child: const Center(
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultDisplay() {
    return AnimatedSwitcher(
      duration: MiuixDuration.normal,
      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
      child: _result != null
          ? MiuixCard(
              key: ValueKey(_result),
              style: MiuixCardStyle.gradient,
              gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
              child: Column(
                children: [
                  const Text('就决定是你了！',
                      style: TextStyle(color: Colors.white70, fontSize: MiuixFontSize.sm)),
                  const SizedBox(height: MiuixSpacing.sm),
                  Text(_result!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: MiuixFontSize.xxxl,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4)),
                ],
              ),
            )
          : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }

  Widget _buildSpinButton() {
    return MiuixButton(
      label: _isSpinning ? '转动中...' : '开始转动',
      icon: _isSpinning ? Icons.autorenew : Icons.play_circle_filled,
      width: double.infinity,
      onPressed: _isSpinning ? null : _spin,
    );
  }

  Widget _buildHistory() {
    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('历史记录',
              style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: MiuixSpacing.md),
          Wrap(
            spacing: MiuixSpacing.sm,
            runSpacing: MiuixSpacing.sm,
            children: _history.asMap().entries.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: MiuixSpacing.md, vertical: MiuixSpacing.xs),
                decoration: BoxDecoration(
                  color: e.key == 0 ? MiuixColors.primary.withValues(alpha: 0.15) : MiuixColors.surfaceVariant,
                  borderRadius: MiuixRadius.pillRadius,
                  border: Border.all(color: e.key == 0 ? MiuixColors.primary : MiuixColors.borderLight),
                ),
                child: Text(e.value,
                    style: TextStyle(
                        color: e.key == 0 ? MiuixColors.primaryDark : MiuixColors.textSecondary,
                        fontWeight: e.key == 0 ? FontWeight.bold : FontWeight.normal,
                        fontSize: MiuixFontSize.sm)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<String> options;
  final List<Color> colors;

  _WheelPainter({required this.options, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweep = 2 * pi / options.length;

    for (int i = 0; i < options.length; i++) {
      final startAngle = -pi / 2 + i * sweep;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        paint,
      );

      // 文字
      final textAngle = startAngle + sweep / 2;
      final textRadius = radius * 0.65;
      final textX = center.dx + cos(textAngle) * textRadius;
      final textY = center.dy + sin(textAngle) * textRadius;

      canvas.save();
      canvas.translate(textX, textY);
      canvas.rotate(textAngle + pi / 2);
      final textPainter = TextPainter(
        text: TextSpan(
          text: options[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      );
      textPainter.layout(maxWidth: radius * 0.7);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }

    // 边框
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      oldDelegate.options != options;
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MiuixColors.primaryDeep
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);

    // 高光
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, 8), 4, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
