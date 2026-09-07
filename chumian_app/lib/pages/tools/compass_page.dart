import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// CompassPage —— 指南针
/// 自定义绘制罗盘，粉色刻度，动画，水平仪
/// ============================================================
class CompassPage extends StatefulWidget {
  const CompassPage({super.key});

  @override
  State<CompassPage> createState() => _CompassPageState();
}

class _CompassPageState extends State<CompassPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _compassController;

  double _heading = 0; // 0-360度
  double _targetHeading = 45;
  double _levelX = 0;
  double _levelY = 0;
  bool _isCalibrated = true;

  static const List<String> _directions = ['北', '东北', '东', '东南', '南', '西南', '西', '西北'];
  static const List<double> _directionAngles = [0, 45, 90, 135, 180, 225, 270, 315];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _compassController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _entryController.forward();

    // 模拟指南针转动
    _compassController.addListener(() {
      setState(() {
        _heading = _targetHeading +
            math.sin(_compassController.value * 2 * math.pi) * 5;
        _levelX = math.sin(_compassController.value * 2 * math.pi) * 0.3;
        _levelY = math.cos(_compassController.value * 2 * math.pi * 0.7) * 0.2;
      });
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _compassController.dispose();
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

  String _getDirectionName(double angle) {
    double normalized = angle % 360;
    if (normalized < 0) normalized += 360;
    for (int i = 0; i < _directions.length; i++) {
      final diff = (normalized - _directionAngles[i]).abs();
      if (diff < 22.5 || diff > 337.5) {
        return _directions[i];
      }
    }
    return '北';
  }

  void _calibrate() {
    MiuixToast.show(context,
        message: '校准中，请画8字晃动手机', type: MiuixToastType.info);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isCalibrated = true);
      MiuixToast.show(context,
          message: '校准完成', type: MiuixToastType.success);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '指南针',
        backgroundColor: MiuixColors.background,
        actions: [
          MiuixIconButton(
            icon: Icons.settings,
            style: MiuixIconButtonStyle.ghost,
            onPressed: _calibrate,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            _buildAnimatedItem(_buildCompass(), 0),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildDirectionInfo(), 1),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildLevelMeter(), 2),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildInfoCard(), 3),
          ],
        ),
      ),
    );
  }

  Widget _buildCompass() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)],
      ),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 罗盘
              Transform.rotate(
                angle: -_heading * math.pi / 180,
                child: CustomPaint(
                  size: const Size(280, 280),
                  painter: _CompassPainter(),
                ),
              ),
              // 指针
              CustomPaint(
                size: const Size(280, 280),
                painter: _CompassNeedlePainter(),
              ),
              // 中心圆
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: MiuixColors.primaryGradient),
                  shape: BoxShape.circle,
                  boxShadow: MiuixShadows.sm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionInfo() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem('方位', _getDirectionName(_heading)),
          Container(width: 1, height: 40, color: MiuixColors.divider),
          _buildInfoItem('角度', '${_heading.toStringAsFixed(1)}°'),
          Container(width: 1, height: 40, color: MiuixColors.divider),
          _buildInfoItem('状态', _isCalibrated ? '已校准' : '未校准'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: MiuixFontSize.xl,
            fontWeight: FontWeight.bold,
            color: MiuixColors.primaryDeep,
          ),
        ),
        const SizedBox(height: 4),
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

  Widget _buildLevelMeter() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.grid_4x4, color: MiuixColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                '水平仪',
                style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 水平仪圆盘
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: MiuixColors.surfaceVariant,
                      shape: BoxShape.circle,
                      border: Border.all(color: MiuixColors.border, width: 2),
                    ),
                  ),
                  // 十字线
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 80,
                    child: Container(
                      height: 1,
                      color: MiuixColors.border,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 80,
                    child: Container(
                      width: 1,
                      color: MiuixColors.border,
                    ),
                  ),
                  // 中心圆
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: MiuixColors.primary.withValues(alpha: 0.5),
                          width: 1),
                    ),
                  ),
                  // 气泡
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 100),
                    left: 80 + _levelX * 40 - 18,
                    top: 80 + _levelY * 40 - 18,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            MiuixColors.primaryLight.withValues(alpha: 0.6),
                            MiuixColors.primary.withValues(alpha: 0.3),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: MiuixColors.primary.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'X: ${(_levelX * 45).toStringAsFixed(1)}°',
                style: const TextStyle(
                  fontSize: MiuixFontSize.sm,
                  color: MiuixColors.textSecondary,
                ),
              ),
              const SizedBox(width: 20),
              Text(
                'Y: ${(_levelY * 45).toStringAsFixed(1)}°',
                style: const TextStyle(
                  fontSize: MiuixFontSize.sm,
                  color: MiuixColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: MiuixColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                '使用说明',
                style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem('将手机平放在水平面上，查看水平仪气泡位置'),
          _buildTipItem('气泡居中表示设备处于水平状态'),
          _buildTipItem('指南针指向红色箭头方向为北方'),
          _buildTipItem('如指针不准确，点击右上角校准按钮重新校准'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: const BoxDecoration(
              color: MiuixColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: MiuixFontSize.sm,
                color: MiuixColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 罗盘绘制器
class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // 外圈
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = MiuixColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 内圈
    canvas.drawCircle(
      center,
      radius - 20,
      Paint()
        ..color = MiuixColors.surfaceVariant
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // 刻度
    for (int i = 0; i < 72; i++) {
      final angle = (i / 72) * 2 * math.pi;
      final isMajor = i % 9 == 0;
      final isMedium = i % 3 == 0;
      final innerR = radius - (isMajor ? 20 : isMedium ? 14 : 8);
      final outerR = radius - 4;
      canvas.drawLine(
        Offset(center.dx + math.cos(angle) * innerR,
            center.dy + math.sin(angle) * innerR),
        Offset(center.dx + math.cos(angle) * outerR,
            center.dy + math.sin(angle) * outerR),
        Paint()
          ..color = isMajor
              ? MiuixColors.primaryDeep
              : isMedium
                  ? MiuixColors.primary
                  : MiuixColors.border
          ..strokeWidth = isMajor ? 2.5 : isMedium ? 1.5 : 1,
      );
    }

    // 方位文字
    final directions = [
      _DirLabel('北', 0, true),
      _DirLabel('东', 90, false),
      _DirLabel('南', 180, false),
      _DirLabel('西', 270, false),
      _DirLabel('NE', 45, false),
      _DirLabel('SE', 135, false),
      _DirLabel('SW', 225, false),
      _DirLabel('NW', 315, false),
    ];

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final dir in directions) {
      final angle = (dir.angle - 90) * math.pi / 180;
      final textR = radius - 38;
      textPainter.text = TextSpan(
        text: dir.label,
        style: TextStyle(
          color: dir.isMajor ? MiuixColors.primaryDeep : MiuixColors.textSecondary,
          fontSize: dir.isMajor ? 18 : 12,
          fontWeight: dir.isMajor ? FontWeight.bold : FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx + math.cos(angle) * textR - textPainter.width / 2,
          center.dy + math.sin(angle) * textR - textPainter.height / 2,
        ),
      );
    }

    // 角度数字
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final textR = radius - 58;
      textPainter.text = TextSpan(
        text: '${i * 30}',
        style: const TextStyle(
          color: MiuixColors.textTertiary,
          fontSize: 9,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx + math.cos(angle) * textR - textPainter.width / 2,
          center.dy + math.sin(angle) * textR - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 指针绘制器
class _CompassNeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 30;

    // 北指针（红色）
    final northPath = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx - 10, center.dy)
      ..lineTo(center.dx + 10, center.dy)
      ..close();
    canvas.drawPath(
      northPath,
      Paint()
        ..color = MiuixColors.error
        ..style = PaintingStyle.fill,
    );

    // 南指针（粉色）
    final southPath = Path()
      ..moveTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - 8, center.dy)
      ..lineTo(center.dx + 8, center.dy)
      ..close();
    canvas.drawPath(
      southPath,
      Paint()
        ..color = MiuixColors.primaryLight
        ..style = PaintingStyle.fill,
    );

    // N标记
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = const TextSpan(
      text: 'N',
      style: TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - radius + 12),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DirLabel {
  final String label;
  final double angle;
  final bool isMajor;
  const _DirLabel(this.label, this.angle, this.isMajor);
}
