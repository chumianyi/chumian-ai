import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';

/// ============================================================
/// ProtractorPage —— 量角器
/// 自定义绘制半圆刻度，角度测量，两点连线
/// 粉色主题，动画指针
/// ============================================================
class ProtractorPage extends StatefulWidget {
  const ProtractorPage({super.key});

  @override
  State<ProtractorPage> createState() => _ProtractorPageState();
}

class _ProtractorPageState extends State<ProtractorPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  double _angle = 45.0; // 当前角度（度）
  double _secondAngle = 135.0; // 第二条线角度
  bool _measureMode = false; // false=单指针, true=双指针测夹角
  bool _isDraggingFirst = false;
  bool _isDraggingSecond = false;

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

  double get _includedAngle {
    final diff = (_angle - _secondAngle).abs();
    return diff > 180 ? 360 - diff : diff;
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    final center = Offset(size.width / 2, size.height - 20);
    final dx = details.localPosition.dx - center.dx;
    final dy = center.dy - details.localPosition.dy;
    var angle = atan2(dy, dx) * 180 / pi;
    angle = angle.clamp(0.0, 180.0);

    if (_isDraggingFirst) {
      setState(() => _angle = angle);
    } else if (_isDraggingSecond) {
      setState(() => _secondAngle = angle);
    }
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
      appBar: MiuixAppBar(title: '量角器'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: Column(
          children: [
            _buildAnimatedItem(_buildAngleDisplay(), 0),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildProtractor(), 1),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildModeToggle(), 2),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildSliders(), 3),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildResetButton(), 4),
          ],
        ),
      ),
    );
  }

  Widget _buildAngleDisplay() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
      child: Column(
        children: [
          Text(_measureMode ? '夹角测量' : '角度测量',
              style: const TextStyle(color: Colors.white70, fontSize: MiuixFontSize.sm)),
          const SizedBox(height: MiuixSpacing.sm),
          Text(
            _measureMode
                ? '${_includedAngle.toStringAsFixed(1)}°'
                : '${_angle.toStringAsFixed(1)}°',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold),
          ),
          if (_measureMode) ...[
            const SizedBox(height: MiuixSpacing.xs),
            Text('线1: ${_angle.toStringAsFixed(1)}°  线2: ${_secondAngle.toStringAsFixed(1)}°',
                style: const TextStyle(color: Colors.white70, fontSize: MiuixFontSize.xs)),
          ],
        ],
      ),
    );
  }

  Widget _buildProtractor() {
    return MiuixCard(
      padding: const EdgeInsets.all(MiuixSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxWidth * 0.6);
          return GestureDetector(
            onPanStart: (details) {
              final center = Offset(size.width / 2, size.height - 20);
              final dx = details.localPosition.dx - center.dx;
              final dy = center.dy - details.localPosition.dy;
              final touchAngle = atan2(dy, dx) * 180 / pi;
              final diff1 = (touchAngle - _angle).abs();
              final diff2 = (touchAngle - _secondAngle).abs();
              if (_measureMode && diff2 < diff1) {
                _isDraggingSecond = true;
              } else {
                _isDraggingFirst = true;
              }
            },
            onPanUpdate: (details) => _onPanUpdate(details, size),
            onPanEnd: (_) {
              _isDraggingFirst = false;
              _isDraggingSecond = false;
            },
            child: CustomPaint(
              size: size,
              painter: _ProtractorPainter(
                angle: _angle,
                secondAngle: _measureMode ? _secondAngle : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeToggle() {
    return Row(
      children: [
        Expanded(
          child: MiuixButton(
            label: '单指针',
            icon: Icons.arrow_upward,
            type: !_measureMode ? MiuixButtonType.primary : MiuixButtonType.secondary,
            onPressed: () => setState(() => _measureMode = false),
          ),
        ),
        const SizedBox(width: MiuixSpacing.md),
        Expanded(
          child: MiuixButton(
            label: '测夹角',
            icon: Icons.transform,
            type: _measureMode ? MiuixButtonType.primary : MiuixButtonType.secondary,
            onPressed: () => setState(() => _measureMode = true),
          ),
        ),
      ],
    );
  }

  Widget _buildSliders() {
    return MiuixCard(
      child: Column(
        children: [
          _sliderRow('指针 1', _angle, (v) => setState(() => _angle = v)),
          if (_measureMode) ...[
            const SizedBox(height: MiuixSpacing.md),
            _sliderRow('指针 2', _secondAngle, (v) => setState(() => _secondAngle = v)),
          ],
        ],
      ),
    );
  }

  Widget _sliderRow(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: MiuixColors.textPrimary)),
            Text('${value.toStringAsFixed(1)}°',
                style: const TextStyle(color: MiuixColors.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 180,
          activeColor: MiuixColors.primary,
          inactiveColor: MiuixColors.border,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    return MiuixButton(
      label: '重置',
      icon: Icons.refresh,
      type: MiuixButtonType.secondary,
      width: double.infinity,
      onPressed: () => setState(() {
        _angle = 45;
        _secondAngle = 135;
      }),
    );
  }
}

class _ProtractorPainter extends CustomPainter {
  final double angle;
  final double? secondAngle;

  _ProtractorPainter({required this.angle, this.secondAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 20);
    final radius = size.width * 0.42;

    // 半圆背景
    final bgPaint = Paint()
      ..color = MiuixColors.surfaceVariant
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      true,
      bgPaint,
    );

    // 半圆边框
    final borderPaint = Paint()
      ..color = MiuixColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      borderPaint,
    );

    // 底线
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      borderPaint,
    );

    // 刻度
    final tickPaint = Paint()
      ..color = MiuixColors.textSecondary
      ..strokeWidth = 1;
    final majorTickPaint = Paint()
      ..color = MiuixColors.primary
      ..strokeWidth = 2;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int deg = 0; deg <= 180; deg += 5) {
      final rad = (180 - deg) * pi / 180;
      final isMajor = deg % 10 == 0;
      final tickLength = isMajor ? 15.0 : 8.0;
      final paint = isMajor ? majorTickPaint : tickPaint;

      final x1 = center.dx + cos(rad) * radius;
      final y1 = center.dy + sin(rad) * radius;
      final x2 = center.dx + cos(rad) * (radius - tickLength);
      final y2 = center.dy + sin(rad) * (radius - tickLength);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);

      // 数字
      if (isMajor) {
        textPainter.text = TextSpan(
          text: '$deg',
          style: const TextStyle(
            color: MiuixColors.primaryDark,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        final tx = center.dx + cos(rad) * (radius - 28) - textPainter.width / 2;
        final ty = center.dy + sin(rad) * (radius - 28) - textPainter.height / 2;
        textPainter.paint(canvas, Offset(tx, ty));
      }
    }

    // 夹角扇形（双指针模式）
    if (secondAngle != null) {
      final startRad = (180 - max(angle, secondAngle!)) * pi / 180;
      final sweepRad = (secondAngle! - angle).abs() * pi / 180;
      final sectorPaint = Paint()
        ..color = MiuixColors.primary.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.5),
        startRad,
        sweepRad,
        true,
        sectorPaint,
      );
    }

    // 指针1
    _drawPointer(canvas, center, radius, angle, MiuixColors.primaryDeep);

    // 指针2
    if (secondAngle != null) {
      _drawPointer(canvas, center, radius, secondAngle!, MiuixColors.warning);
    }

    // 中心点
    final centerPaint = Paint()
      ..color = MiuixColors.primaryDeep
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, centerPaint);
    canvas.drawCircle(center, 3, Paint()..color = Colors.white);
  }

  void _drawPointer(Canvas canvas, Offset center, double radius, double angle, Color color) {
    final rad = (180 - angle) * pi / 180;
    final pointerPaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final endX = center.dx + cos(rad) * (radius - 20);
    final endY = center.dy + sin(rad) * (radius - 20);

    canvas.drawLine(center, Offset(endX, endY), pointerPaint);

    // 指针端点圆
    canvas.drawCircle(Offset(endX, endY), 6, Paint()..color = color);
    canvas.drawCircle(Offset(endX, endY), 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _ProtractorPainter oldDelegate) =>
      oldDelegate.angle != angle || oldDelegate.secondAngle != secondAngle;
}
