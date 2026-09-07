import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_segment.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';

/// ============================================================
/// TunerPage —— 调音器
/// 吉他/尤克里里调音，弦选择，频率显示
/// 指针仪表，自定义绘制，粉色主题，模拟音高
/// ============================================================
class TunerPage extends StatefulWidget {
  const TunerPage({super.key});

  @override
  State<TunerPage> createState() => _TunerPageState();
}

class _TunerPageState extends State<TunerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _needleController;

  int _instrument = 0; // 0=吉他, 1=尤克里里
  int _selectedString = 0;
  double _currentFreq = 440.0;
  double _targetFreq = 440.0;
  bool _isListening = false;
  Timer? _simTimer;
  double _needleAngle = 0; // -1 到 1
  final Random _random = Random();

  // 吉他标准调音: E2 A2 D3 G3 B3 E4
  static const List<String> _guitarStrings = ['E2', 'A2', 'D3', 'G3', 'B3', 'E4'];
  static const List<double> _guitarFreqs = [82.41, 110.0, 146.83, 196.0, 246.94, 329.63];

  // 尤克里里标准调音: G4 C4 E4 A4
  static const List<String> _ukuleleStrings = ['G4', 'C4', 'E4', 'A4'];
  static const List<double> _ukuleleFreqs = [392.0, 261.63, 329.63, 440.0];

  List<String> get _strings => _instrument == 0 ? _guitarStrings : _ukuleleStrings;
  List<double> get _freqs => _instrument == 0 ? _guitarFreqs : _ukuleleFreqs;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _needleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _targetFreq = _freqs[0];
  }

  @override
  void dispose() {
    _entryController.dispose();
    _needleController.dispose();
    _simTimer?.cancel();
    super.dispose();
  }

  void _selectString(int index) {
    setState(() {
      _selectedString = index;
      _targetFreq = _freqs[index];
      if (_isListening) {
        _currentFreq = _targetFreq + (_random.nextDouble() - 0.5) * 20;
      }
    });
  }

  void _toggleListening() {
    setState(() => _isListening = !_isListening);
    if (_isListening) {
      MiuixToast.show(context, '开始监听...', icon: Icons.mic);
      _startSimulation();
    } else {
      _simTimer?.cancel();
      MiuixToast.show(context, '已停止监听', icon: Icons.mic_off);
    }
  }

  void _startSimulation() {
    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      // 模拟频率波动，逐渐接近目标
      final diff = _targetFreq - _currentFreq;
      final adjustment = diff * 0.3 + (_random.nextDouble() - 0.5) * 3;
      setState(() {
        _currentFreq += adjustment;
        // 计算偏差 (-1 到 1)
        final cents = (_currentFreq - _targetFreq) / _targetFreq * 100;
        _needleAngle = (cents / 50).clamp(-1.0, 1.0);
      });
    });
  }

  String get _tuningStatus {
    if (!_isListening) return '未开始';
    final diff = (_currentFreq - _targetFreq).abs();
    if (diff < 1.0) return '音准完美';
    if (diff < 3.0) return '基本准确';
    if (_currentFreq < _targetFreq) return '偏低，拧紧';
    return '偏高，拧松';
  }

  Color get _statusColor {
    if (!_isListening) return MiuixColors.textTertiary;
    final diff = (_currentFreq - _targetFreq).abs();
    if (diff < 1.0) return MiuixColors.success;
    if (diff < 3.0) return MiuixColors.warning;
    return MiuixColors.error;
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
      appBar: MiuixAppBar(title: '调音器'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: Column(
          children: [
            _buildAnimatedItem(_buildInstrumentSelector(), 0),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildStringSelector(), 1),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildFrequencyDisplay(), 2),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildMeter(), 3),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildStatusDisplay(), 4),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildListenButton(), 5),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildTuningGuide(), 6),
          ],
        ),
      ),
    );
  }

  Widget _buildInstrumentSelector() {
    return MiuixSegment(
      segments: const ['吉他', '尤克里里'],
      currentIndex: _instrument,
      onChanged: (i) {
        setState(() {
          _instrument = i;
          _selectedString = 0;
          _targetFreq = _freqs[0];
        });
      },
    );
  }

  Widget _buildStringSelector() {
    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('选择弦',
              style: TextStyle(fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: MiuixSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_strings.length, (i) {
              final selected = _selectedString == i;
              return GestureDetector(
                onTap: () => _selectString(i),
                child: AnimatedContainer(
                  duration: MiuixDuration.fast,
                  curve: MiuixCurves.miuixSpring,
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(colors: MiuixColors.primaryGradient)
                        : null,
                    color: selected ? null : MiuixColors.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? MiuixColors.primary : MiuixColors.borderLight,
                      width: 2,
                    ),
                    boxShadow: selected ? MiuixShadows.sm : null,
                  ),
                  child: Center(
                    child: Text(_strings[i],
                        style: TextStyle(
                            color: selected ? Colors.white : MiuixColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: MiuixFontSize.sm)),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyDisplay() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text('当前频率',
                  style: TextStyle(color: Colors.white70, fontSize: MiuixFontSize.sm)),
              const SizedBox(height: MiuixSpacing.xs),
              Text('${_currentFreq.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const Text('Hz',
                  style: TextStyle(color: Colors.white70, fontSize: MiuixFontSize.xs)),
            ],
          ),
          Container(width: 1, height: 50, color: Colors.white24),
          Column(
            children: [
              const Text('目标频率',
                  style: TextStyle(color: Colors.white70, fontSize: MiuixFontSize.sm)),
              const SizedBox(height: MiuixSpacing.xs),
              Text('${_targetFreq.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              Text('${_strings[_selectedString]}',
                  style: const TextStyle(color: Colors.white70, fontSize: MiuixFontSize.xs)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeter() {
    return MiuixCard(
      padding: const EdgeInsets.all(MiuixSpacing.lg),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: CustomPaint(
              size: const Size(double.infinity, 140),
              painter: _MeterPainter(needleAngle: _needleAngle),
            ),
          ),
          const SizedBox(height: MiuixSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('-50音分', style: TextStyle(color: MiuixColors.textTertiary, fontSize: 10)),
              Text('0', style: TextStyle(color: MiuixColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('+50音分', style: TextStyle(color: MiuixColors.textTertiary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: MiuixSpacing.xl, vertical: MiuixSpacing.md),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.1),
        borderRadius: MiuixRadius.pillRadius,
        border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isListening
                ? (_statusColor == MiuixColors.success
                    ? Icons.check_circle
                    : _statusColor == MiuixColors.warning
                        ? Icons.remove_circle_outline
                        : Icons.error_outline)
                : Icons.power_settings_new,
            color: _statusColor,
            size: 20,
          ),
          const SizedBox(width: MiuixSpacing.sm),
          Text(_tuningStatus,
              style: TextStyle(
                  color: _statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: MiuixFontSize.md)),
        ],
      ),
    );
  }

  Widget _buildListenButton() {
    return GestureDetector(
      onTap: _toggleListening,
      child: AnimatedContainer(
        duration: MiuixDuration.fast,
        curve: MiuixCurves.miuixSpring,
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: _isListening
              ? const LinearGradient(colors: [MiuixColors.error, MiuixColors.primaryDeep])
              : const LinearGradient(colors: MiuixColors.primaryGradient),
          shape: BoxShape.circle,
          boxShadow: _isListening
              ? [
                  BoxShadow(
                    color: MiuixColors.error.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ]
              : MiuixShadows.lg,
        ),
        child: Icon(
          _isListening ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }

  Widget _buildTuningGuide() {
    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('调音指引',
              style: TextStyle(fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: MiuixSpacing.md),
          _guideRow(Icons.arrow_upward, '指针偏右', '音高偏高，逆时针拧松弦钮', MiuixColors.error),
          const SizedBox(height: MiuixSpacing.sm),
          _guideRow(Icons.arrow_downward, '指针偏左', '音高偏低，顺时针拧紧弦钮', MiuixColors.warning),
          const SizedBox(height: MiuixSpacing.sm),
          _guideRow(Icons.check, '指针居中', '音高准确，保持当前状态', MiuixColors.success),
          const SizedBox(height: MiuixSpacing.md),
          Container(
            padding: const EdgeInsets.all(MiuixSpacing.md),
            decoration: BoxDecoration(
              color: MiuixColors.primary.withValues(alpha: 0.08),
              borderRadius: MiuixRadius.mdRadius,
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: MiuixColors.primary, size: 18),
                SizedBox(width: MiuixSpacing.sm),
                Expanded(
                  child: Text('提示：调音时请保持环境安静，依次调节每根弦，反复校准直到指针稳定在中心位置。',
                      style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.xs, height: 1.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _guideRow(IconData icon, String title, String desc, Color color) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: MiuixSpacing.sm),
        Text(title,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: MiuixFontSize.sm)),
        const SizedBox(width: MiuixSpacing.sm),
        Expanded(
          child: Text(desc,
              style: const TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.xs)),
        ),
      ],
    );
  }
}

class _MeterPainter extends CustomPainter {
  final double needleAngle; // -1 to 1

  _MeterPainter({required this.needleAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 20);
    final radius = size.width * 0.42;

    // 背景弧
    final bgPaint = Paint()
      ..color = MiuixColors.surfaceVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      bgPaint,
    );

    // 颜色分区
    final leftPaint = Paint()
      ..color = MiuixColors.warning.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi * 0.4,
      false,
      leftPaint,
    );

    final centerPaint = Paint()
      ..color = MiuixColors.success.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi + pi * 0.4,
      pi * 0.2,
      false,
      centerPaint,
    );

    final rightPaint = Paint()
      ..color = MiuixColors.error.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi + pi * 0.6,
      pi * 0.4,
      false,
      rightPaint,
    );

    // 刻度线
    final tickPaint = Paint()
      ..color = MiuixColors.textSecondary
      ..strokeWidth = 1;
    for (int i = 0; i <= 10; i++) {
      final angle = pi + (pi / 10) * i;
      final isMajor = i % 2 == 0;
      final innerR = radius - (isMajor ? 25 : 20);
      final outerR = radius - 15;
      canvas.drawLine(
        Offset(center.dx + cos(angle) * innerR, center.dy + sin(angle) * innerR),
        Offset(center.dx + cos(angle) * outerR, center.dy + sin(angle) * outerR),
        tickPaint,
      );
    }

    // 指针
    final needleAngleRad = pi + (pi / 2) + (needleAngle * pi / 2);
    final needlePaint = Paint()
      ..color = MiuixColors.primaryDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final needleEnd = Offset(
      center.dx + cos(needleAngleRad) * (radius - 30),
      center.dy + sin(needleAngleRad) * (radius - 30),
    );
    canvas.drawLine(center, needleEnd, needlePaint);

    // 指针中心圆
    canvas.drawCircle(center, 8, Paint()..color = MiuixColors.primaryDeep);
    canvas.drawCircle(center, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _MeterPainter oldDelegate) =>
      oldDelegate.needleAngle != needleAngle;
}
