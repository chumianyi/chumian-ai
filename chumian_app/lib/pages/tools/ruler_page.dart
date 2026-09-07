import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_segment.dart';
import 'package:chumian_ai/widgets/miuix/miuix_slider.dart';

/// ============================================================
/// RulerPage —— 尺子
/// 自定义绘制刻度，厘米/英寸，测量长度
/// 校准，粉色主题，水平辅助线
/// ============================================================
class RulerPage extends StatefulWidget {
  const RulerPage({super.key});

  @override
  State<RulerPage> createState() => _RulerPageState();
}

class _RulerPageState extends State<RulerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  int _unit = 0; // 0=厘米, 1=英寸
  double _calibration = 1.0; // 校准系数
  double _pointerPosition = 0; // 测量指针位置（像素）
  bool _showPointer = false;

  static const double _pixelsPerCm = 37.8; // 约 1cm = 37.8px (基于 96dpi)
  static const double _pixelsPerInch = 96.0;

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

  double get _effectivePixelsPerUnit {
    return (_unit == 0 ? _pixelsPerCm : _pixelsPerInch) * _calibration;
  }

  String _getMeasurement() {
    if (!_showPointer) return '--';
    final value = _pointerPosition / _effectivePixelsPerUnit;
    return _unit == 0
        ? '${value.toStringAsFixed(1)} cm'
        : '${value.toStringAsFixed(2)} in';
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
      appBar: MiuixAppBar(title: '尺子'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: Column(
          children: [
            _buildAnimatedItem(_buildUnitSelector(), 0),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildMeasurementDisplay(), 1),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildRuler(), 2),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildCalibration(), 3),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildActionButtons(), 4),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitSelector() {
    return MiuixSegment(
      segments: const ['厘米 (cm)', '英寸 (in)'],
      currentIndex: _unit,
      onChanged: (i) => setState(() => _unit = i),
    );
  }

  Widget _buildMeasurementDisplay() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
      child: Column(
        children: [
          const Text('测量长度',
              style: TextStyle(color: Colors.white70, fontSize: MiuixFontSize.sm)),
          const SizedBox(height: MiuixSpacing.sm),
          Text(_getMeasurement(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: MiuixSpacing.xs),
          Text(_showPointer ? '拖动指针测量' : '点击下方按钮开启测量',
              style: const TextStyle(color: Colors.white70, fontSize: MiuixFontSize.xs)),
        ],
      ),
    );
  }

  Widget _buildRuler() {
    return MiuixCard(
      padding: const EdgeInsets.all(MiuixSpacing.md),
      child: Column(
        children: [
          // 水平辅助线
          Container(
            height: 1,
            color: MiuixColors.primary.withOpacity(0.3),
          ),
          const SizedBox(height: MiuixSpacing.sm),
          // 尺子
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              if (!_showPointer) return;
              setState(() {
                _pointerPosition = details.localPosition.dx.clamp(0.0, 300.0);
              });
            },
            child: SizedBox(
              height: 100,
              width: 300,
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(300, 100),
                    painter: _RulerPainter(
                      unit: _unit,
                      pixelsPerUnit: _effectivePixelsPerUnit,
                    ),
                  ),
                  // 测量指针
                  if (_showPointer)
                    Positioned(
                      left: _pointerPosition,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: MiuixColors.primaryDeep,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: MiuixColors.primaryDeep,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: MiuixColors.primaryDeep,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: MiuixSpacing.sm),
          // 底部辅助线
          Container(
            height: 1,
            color: MiuixColors.primary.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibration() {
    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('校准',
              style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: MiuixSpacing.sm),
          Text('校准系数: ${_calibration.toStringAsFixed(2)}',
              style: const TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm)),
          const SizedBox(height: MiuixSpacing.sm),
          MiuixSlider(
            value: _calibration,
            min: 0.5,
            max: 2.0,
            divisions: 30,
            label: '${_calibration.toStringAsFixed(2)}x',
            onChanged: (v) => setState(() => _calibration = v),
          ),
          const SizedBox(height: MiuixSpacing.sm),
          const Text('将已知长度的物体放在屏幕上，调整系数使刻度匹配',
              style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: MiuixButton(
            label: _showPointer ? '关闭测量' : '开始测量',
            icon: _showPointer ? Icons.close : Icons.touch_app,
            onPressed: () {
              setState(() {
                _showPointer = !_showPointer;
                if (_showPointer) _pointerPosition = 150;
              });
            },
          ),
        ),
        const SizedBox(width: MiuixSpacing.md),
        Expanded(
          child: MiuixButton(
            label: '重置校准',
            icon: Icons.refresh,
            type: MiuixButtonType.secondary,
            onPressed: () => setState(() => _calibration = 1.0),
          ),
        ),
      ],
    );
  }
}

class _RulerPainter extends CustomPainter {
  final int unit;
  final double pixelsPerUnit;

  _RulerPainter({required this.unit, required this.pixelsPerUnit});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MiuixColors.textPrimary
      ..strokeWidth = 1;

    final majorPaint = Paint()
      ..color = MiuixColors.primary
      ..strokeWidth = 2;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final totalUnits = (size.width / pixelsPerUnit).ceil();
    final subdivisions = unit == 0 ? 10 : 8; // cm有10mm, inch有1/8

    for (int i = 0; i <= totalUnits; i++) {
      final x = i * pixelsPerUnit;
      if (x > size.width) break;

      // 主刻度
      canvas.drawLine(Offset(x, 0), Offset(x, 30), majorPaint);

      // 数字
      textPainter.text = TextSpan(
        text: '$i',
        style: const TextStyle(
          color: MiuixColors.primaryDark,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, 35));

      // 次刻度
      for (int j = 1; j < subdivisions; j++) {
        final subX = x + (pixelsPerUnit / subdivisions) * j;
        if (subX > size.width) break;
        final isHalf = j == subdivisions ~/ 2;
        final tickHeight = isHalf ? 20 : 12;
        canvas.drawLine(Offset(subX, 0), Offset(subX, tickHeight.toDouble()), paint);
      }
    }

    // 单位标签
    textPainter.text = TextSpan(
      text: unit == 0 ? 'cm' : 'inch',
      style: const TextStyle(
        color: MiuixColors.textTertiary,
        fontSize: 10,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - textPainter.width - 5, size.height - 15));

    // 底部边框
    final borderPaint = Paint()
      ..color = MiuixColors.primary
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, size.height - 1), Offset(size.width, size.height - 1), borderPaint);
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) =>
      oldDelegate.unit != unit || oldDelegate.pixelsPerUnit != pixelsPerUnit;
}
