import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_input.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';

/// ============================================================
/// CoinFlipPage —— 抛硬币
/// 3D翻转动画，正面/反面，历史统计
/// 自定义正反面文字，粉色主题，音效模拟
/// ============================================================
class CoinFlipPage extends StatefulWidget {
  const CoinFlipPage({super.key});

  @override
  State<CoinFlipPage> createState() => _CoinFlipPageState();
}

class _CoinFlipPageState extends State<CoinFlipPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _flipController;

  final TextEditingController _headsController = TextEditingController(text: '正面');
  final TextEditingController _tailsController = TextEditingController(text: '反面');

  bool _isFlipping = false;
  int _result = 0; // 0=未抛, 1=正面, 2=反面
  int _headsCount = 0;
  int _tailsCount = 0;
  int _totalFlips = 0;
  final List<int> _history = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _flipController.dispose();
    _headsController.dispose();
    _tailsController.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFlipping) return;
    setState(() {
      _isFlipping = true;
      _result = 0;
    });

    _flipController.reset();
    final animation = Tween<double>(begin: 0, end: 5 * pi + _random.nextDouble() * pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    animation.addListener(() => setState(() {}));
    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final result = _random.nextBool() ? 1 : 2;
        setState(() {
          _result = result;
          _isFlipping = false;
          _totalFlips++;
          if (result == 1) {
            _headsCount++;
          } else {
            _tailsCount++;
          }
          _history.insert(0, result);
          if (_history.length > 20) _history.removeLast();
        });
        final label = result == 1 ? _headsController.text : _tailsController.text;
        MiuixToast.show(context, '结果：$label！', icon: Icons.casino);
      }
    });

    _flipController.forward();
  }

  void _resetStats() {
    setState(() {
      _headsCount = 0;
      _tailsCount = 0;
      _totalFlips = 0;
      _history.clear();
      _result = 0;
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
      appBar: MiuixAppBar(title: '抛硬币'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: Column(
          children: [
            _buildAnimatedItem(_buildStatsRow(), 0),
            const SizedBox(height: MiuixSpacing.xl),
            _buildAnimatedItem(_buildCoinArea(), 1),
            const SizedBox(height: MiuixSpacing.xl),
            _buildAnimatedItem(_buildResultDisplay(), 2),
            const SizedBox(height: MiuixSpacing.xl),
            _buildAnimatedItem(_buildFlipButton(), 3),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildCustomLabels(), 4),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildHistory(), 5),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildResetButton(), 6),
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
                const Icon(Icons.looks_one, color: MiuixColors.primary, size: 18),
                const SizedBox(height: MiuixSpacing.xs),
                Text('$_headsCount',
                    style: const TextStyle(
                        fontSize: MiuixFontSize.xl,
                        fontWeight: FontWeight.bold,
                        color: MiuixColors.primaryDark)),
                Text(_headsController.text,
                    style: const TextStyle(
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
                const Icon(Icons.casino, color: MiuixColors.info, size: 18),
                const SizedBox(height: MiuixSpacing.xs),
                Text('$_totalFlips',
                    style: const TextStyle(
                        fontSize: MiuixFontSize.xl,
                        fontWeight: FontWeight.bold,
                        color: MiuixColors.info)),
                const Text('总次数',
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
                const Icon(Icons.looks_two, color: MiuixColors.primaryDark, size: 18),
                const SizedBox(height: MiuixSpacing.xs),
                Text('$_tailsCount',
                    style: const TextStyle(
                        fontSize: MiuixFontSize.xl,
                        fontWeight: FontWeight.bold,
                        color: MiuixColors.primaryDark)),
                Text(_tailsController.text,
                    style: const TextStyle(
                        fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoinArea() {
    final angle = _flipController.value;
    final isHeadsSide = (angle % (2 * pi)) < pi / 2 || (angle % (2 * pi)) > 3 * pi / 2;
    final scaleY = cos(angle).abs();

    return Center(
      child: SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 阴影
            Container(
              width: 140,
              height: 20,
              decoration: BoxDecoration(
                color: MiuixColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            // 硬币
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isHeadsSide
                        ? [MiuixColors.primaryLight, MiuixColors.primaryDeep]
                        : [MiuixColors.primaryDeep, MiuixColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: MiuixColors.primary.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 4),
                ),
                child: Center(
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(1.0, scaleY.clamp(0.1, 1.0)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isHeadsSide ? Icons.face : Icons.flip,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: MiuixSpacing.xs),
                        Text(
                          isHeadsSide ? _headsController.text : _tailsController.text,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: MiuixFontSize.lg,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
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
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
      child: _result != 0 && !_isFlipping
          ? Container(
              key: ValueKey('result_$_result'),
              padding: const EdgeInsets.symmetric(horizontal: MiuixSpacing.xl, vertical: MiuixSpacing.md),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
                borderRadius: MiuixRadius.pillRadius,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.celebration, color: Colors.white, size: 20),
                  const SizedBox(width: MiuixSpacing.sm),
                  Text(
                    '结果：${_result == 1 ? _headsController.text : _tailsController.text}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: MiuixFontSize.lg,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }

  Widget _buildFlipButton() {
    return MiuixButton(
      label: _isFlipping ? '翻转中...' : '抛硬币',
      icon: _isFlipping ? Icons.autorenew : Icons.casino,
      width: double.infinity,
      onPressed: _isFlipping ? null : _flip,
    );
  }

  Widget _buildCustomLabels() {
    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('自定义正反面文字',
              style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: MiuixSpacing.md),
          Row(
            children: [
              Expanded(
                child: MiuixInput(
                  controller: _headsController,
                  hintText: '正面文字',
                  prefixIcon: Icons.looks_one,
                ),
              ),
              const SizedBox(width: MiuixSpacing.md),
              Expanded(
                child: MiuixInput(
                  controller: _tailsController,
                  hintText: '反面文字',
                  prefixIcon: Icons.looks_two,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return const SizedBox.shrink();
    }
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
              final isHeads = e.value == 1;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: MiuixSpacing.md, vertical: MiuixSpacing.xs),
                decoration: BoxDecoration(
                  color: isHeads
                      ? MiuixColors.primary.withOpacity(0.15)
                      : MiuixColors.primaryDeep.withOpacity(0.15),
                  borderRadius: MiuixRadius.pillRadius,
                  border: Border.all(
                    color: isHeads ? MiuixColors.primary : MiuixColors.primaryDeep,
                  ),
                ),
                child: Text(
                  isHeads ? _headsController.text : _tailsController.text,
                  style: TextStyle(
                      color: isHeads ? MiuixColors.primaryDark : MiuixColors.primaryDeep,
                      fontWeight: e.key == 0 ? FontWeight.bold : FontWeight.normal,
                      fontSize: MiuixFontSize.sm),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return MiuixButton(
      label: '重置统计',
      icon: Icons.refresh,
      type: MiuixButtonType.secondary,
      width: double.infinity,
      onPressed: _totalFlips == 0 ? null : _resetStats,
    );
  }
}
