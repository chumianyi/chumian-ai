import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// LevelPage —— 水平仪
/// 自定义绘制水平仪，气泡动画，角度显示
/// 粉色主题，传感器模拟
/// ============================================================

class LevelPage extends StatefulWidget {
  const LevelPage({super.key});

  @override
  State<LevelPage> createState() => _LevelPageState();
}

class _LevelPageState extends State<LevelPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _bubbleController;

  double _angleX = 0.0; // 左右倾斜角度
  double _angleY = 0.0; // 前后倾斜角度
  bool _isSimulating = true;
  Timer? _simTimer;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: MiuixDuration.slow);
    _entryController.forward();
    _bubbleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 16))..repeat();
    _startSimulation();
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    _entryController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  void _startSimulation() {
    _simTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      setState(() {
        _angleX += (_random.nextDouble() - 0.5) * 1.5;
        _angleY += (_random.nextDouble() - 0.5) * 1.5;
        _angleX = _angleX.clamp(-15.0, 15.0);
        _angleY = _angleY.clamp(-15.0, 15.0);
        // 缓慢回中
        _angleX *= 0.95;
        _angleY *= 0.95;
      });
    });
  }

  void _toggleSimulation() {
    setState(() {
      _isSimulating = !_isSimulating;
      if (_isSimulating) {
        _startSimulation();
      } else {
        _simTimer?.cancel();
      }
    });
  }

  void _calibrate() {
    setState(() {
      _angleX = 0;
      _angleY = 0;
    });
  }

  bool get _isLevel => _angleX.abs() < 0.5 && _angleY.abs() < 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '水平仪',
        actions: [
          MiuixButton(
            label: _isSimulating ? '模拟中' : '已暂停',
            type: _isSimulating ? MiuixButtonType.primary : MiuixButtonType.secondary,
            size: MiuixButtonSize.small,
            icon: _isSimulating ? Icons.pause : Icons.play_arrow,
            onPressed: _toggleSimulation,
          ),
          const SizedBox(width: MiuixSpacing.md),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.md),
        child: Column(
          children: [
            const SizedBox(height: MiuixSpacing.lg),
            _buildStatusIndicator(),
            const SizedBox(height: MiuixSpacing.xl),
            _buildCircularLevel(),
            const SizedBox(height: MiuixSpacing.xl),
            _buildHorizontalLevel(),
            const SizedBox(height: MiuixSpacing.xl),
            _buildVerticalLevel(),
            const SizedBox(height: MiuixSpacing.xl),
            _buildAngleDisplay(),
            const SizedBox(height: MiuixSpacing.xl),
            _buildCalibrateButton(),
            const SizedBox(height: MiuixSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return FadeTransition(
      opacity: _entryController,
      child: AnimatedContainer(
        duration: MiuixDuration.normal,
        padding: const EdgeInsets.symmetric(horizontal: MiuixSpacing.xl, vertical: MiuixSpacing.md),
        decoration: BoxDecoration(
          color: (_isLevel ? MiuixColors.success : MiuixColors.primary).withOpacity(0.1),
          borderRadius: MiuixRadius.pillRadius,
          border: Border.all(
            color: _isLevel ? MiuixColors.success : MiuixColors.primary,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isLevel ? Icons.check_circle : Icons.adjust,
              size: 20,
              color: _isLevel ? MiuixColors.success : MiuixColors.primary,
            ),
            const SizedBox(width: MiuixSpacing.sm),
            Text(
              _isLevel ? '已水平' : '调整中...',
              style: TextStyle(
                fontSize: MiuixFontSize.lg,
                fontWeight: FontWeight.w700,
                color: _isLevel ? MiuixColors.success : MiuixColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularLevel() {
    final size = MediaQuery.of(context).size.width * 0.7;
    final maxOffset = size * 0.35;
    final offsetX = (_angleX / 15.0) * maxOffset;
    final offsetY = (_angleY / 15.0) * maxOffset;

    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryController, curve: const Interval(0.1, 0.5, curve: MiuixCurves.easeOut)),
      child: MiuixCard(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: Column(
          children: [
            const Text('圆水平仪', style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
            const SizedBox(height: MiuixSpacing.md),
            AnimatedBuilder(
              animation: _bubbleController,
              builder: (context, child) {
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        MiuixColors.surfaceVariant,
                        MiuixColors.surface,
                      ],
                    ),
                    border: Border.all(color: MiuixColors.border, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: MiuixColors.primary.withOpacity(0.1),
                        blurRadius: 20,
                        inset: true,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 同心圆刻度
                      ...List.generate(3, (i) {
                        final ringSize = size * (0.3 + i * 0.2);
                        return Container(
                          width: ringSize,
                          height: ringSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: i == 0
                                  ? MiuixColors.primary.withOpacity(0.5)
                                  : MiuixColors.border,
                              width: i == 0 ? 2 : 1,
                            ),
                          ),
                        );
                      }),
                      // 十字线
                      Container(width: size, height: 1, color: MiuixColors.border),
                      Container(width: 1, height: size, color: MiuixColors.border),
                      // 气泡
                      Transform.translate(
                        offset: Offset(offsetX, offsetY),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: size * 0.18,
                          height: size * 0.18,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                _isLevel ? MiuixColors.success : MiuixColors.primary,
                                (_isLevel ? MiuixColors.success : MiuixColors.primary).withOpacity(0.6),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isLevel ? MiuixColors.success : MiuixColors.primary).withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: size * 0.06,
                              height: size * 0.06,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalLevel() {
    final barWidth = MediaQuery.of(context).size.width * 0.8;
    final maxOffset = barWidth * 0.4;
    final bubbleOffset = (_angleX / 15.0) * maxOffset;

    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryController, curve: const Interval(0.2, 0.6, curve: MiuixCurves.easeOut)),
      child: MiuixCard(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('横向水平', style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
            const SizedBox(height: MiuixSpacing.md),
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: MiuixColors.surfaceVariant,
                borderRadius: MiuixRadius.pillRadius,
                border: Border.all(color: MiuixColors.border, width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 中心刻度
                  Container(width: 2, height: 30, color: MiuixColors.primary.withOpacity(0.5)),
                  // 左右刻度
                  Positioned(left: barWidth * 0.2, child: Container(width: 1, height: 20, color: MiuixColors.border)),
                  Positioned(right: barWidth * 0.2, child: Container(width: 1, height: 20, color: MiuixColors.border)),
                  // 气泡
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 100),
                    left: (barWidth / 2 - 20) + bubbleOffset,
                    child: Container(
                      width: 40,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _angleX.abs() < 0.5 ? MiuixColors.success : MiuixColors.primary,
                            (_angleX.abs() < 0.5 ? MiuixColors.success : MiuixColors.primary).withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: (_angleX.abs() < 0.5 ? MiuixColors.success : MiuixColors.primary).withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 12,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MiuixSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('-15°', style: const TextStyle(fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary)),
                Text('0°', style: TextStyle(fontSize: MiuixFontSize.xs, color: _angleX.abs() < 0.5 ? MiuixColors.success : MiuixColors.primary, fontWeight: FontWeight.w600)),
                Text('+15°', style: const TextStyle(fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalLevel() {
    final barHeight = 160.0;
    final maxOffset = barHeight * 0.35;
    final bubbleOffset = (_angleY / 15.0) * maxOffset;

    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryController, curve: const Interval(0.3, 0.7, curve: MiuixCurves.easeOut)),
      child: MiuixCard(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('纵向水平', style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
                const SizedBox(height: MiuixSpacing.sm),
                Text(_angleY >= 0 ? '前倾 ${_angleY.toStringAsFixed(1)}°' : '后仰 ${_angleY.abs().toStringAsFixed(1)}°',
                    style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
              ],
            ),
            const Spacer(),
            Container(
              width: 50,
              height: barHeight,
              decoration: BoxDecoration(
                color: MiuixColors.surfaceVariant,
                borderRadius: MiuixRadius.pillRadius,
                border: Border.all(color: MiuixColors.border, width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(width: 30, height: 1, color: MiuixColors.primary.withOpacity(0.5)),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 100),
                    top: (barHeight / 2 - 18) + bubbleOffset,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _angleY.abs() < 0.5 ? MiuixColors.success : MiuixColors.primary,
                            (_angleY.abs() < 0.5 ? MiuixColors.success : MiuixColors.primary).withOpacity(0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_angleY.abs() < 0.5 ? MiuixColors.success : MiuixColors.primary).withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 10,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAngleDisplay() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryController, curve: const Interval(0.4, 0.8, curve: MiuixCurves.easeOut)),
      child: Row(
        children: [
          Expanded(
            child: _buildAngleCard('X轴 (左右)', _angleX, Icons.swipe_left_alt),
          ),
          const SizedBox(width: MiuixSpacing.md),
          Expanded(
            child: _buildAngleCard('Y轴 (前后)', _angleY, Icons.swipe_up_alt),
          ),
        ],
      ),
    );
  }

  Widget _buildAngleCard(String label, double angle, IconData icon) {
    final isLevel = angle.abs() < 0.5;
    return MiuixCard(
      padding: const EdgeInsets.all(MiuixSpacing.md),
      child: Column(
        children: [
          Icon(icon, size: 20, color: isLevel ? MiuixColors.success : MiuixColors.primary),
          const SizedBox(height: MiuixSpacing.sm),
          Text(
            '${angle.toStringAsFixed(1)}°',
            style: TextStyle(
              fontSize: MiuixFontSize.xl,
              fontWeight: FontWeight.w700,
              color: isLevel ? MiuixColors.success : MiuixColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildCalibrateButton() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryController, curve: const Interval(0.5, 0.9, curve: MiuixCurves.easeOut)),
      child: MiuixButton(
        label: '校准归零',
        type: MiuixButtonType.primary,
        icon: Icons.center_focus_strong,
        onPressed: _calibrate,
        width: double.infinity,
        height: 50,
      ),
    );
  }
}
