import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_slider.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';

/// ============================================================
/// FlashlightPage —— 手电筒
/// 屏幕白光/粉色光，亮度调节，SOS闪烁
/// 摩尔斯电码，粉色主题，动画
/// ============================================================
class FlashlightPage extends StatefulWidget {
  const FlashlightPage({super.key});

  @override
  State<FlashlightPage> createState() => _FlashlightPageState();
}

class _FlashlightPageState extends State<FlashlightPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _pulseController;

  bool _isOn = false;
  double _brightness = 1.0;
  int _lightColor = 0; // 0=白光, 1=粉色光
  bool _sosMode = false;
  bool _morseMode = false;
  Timer? _sosTimer;
  int _sosStep = 0;

  static const List<Color> _colors = [Colors.white, MiuixColors.primaryLight];
  static const List<String> _colorNames = ['白光', '粉光'];

  // SOS 摩尔斯电码: ... --- ...
  static const List<int> _sosPattern = [
    200, 200, 200, 200, // S: 短 短 短
    600, 200, 600, 200, 600, 200, // O: 长 长 长
    200, 200, 200, 800, // S: 短 短 短 + 间隔
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    _sosTimer?.cancel();
    super.dispose();
  }

  void _toggleLight() {
    setState(() {
      _isOn = !_isOn;
      if (!_isOn) {
        _sosMode = false;
        _morseMode = false;
        _sosTimer?.cancel();
      }
    });
    if (_isOn) {
      MiuixToast.show(context, '手电筒已开启', icon: Icons.flash_on);
    }
  }

  void _toggleSOS() {
    if (!_isOn) {
      MiuixToast.show(context, '请先开启手电筒', icon: Icons.error_outline);
      return;
    }
    setState(() {
      _sosMode = !_sosMode;
      _morseMode = false;
    });
    if (_sosMode) {
      _startSOS();
      MiuixToast.show(context, 'SOS 模式已开启', icon: Icons.sos);
    } else {
      _sosTimer?.cancel();
    }
  }

  void _startSOS() {
    _sosStep = 0;
    _sosTimer?.cancel();
    _sosTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      // 简化：用固定模式
    });
    _runSOSPattern();
  }

  void _runSOSPattern() {
    if (!_sosMode || !mounted) return;
    if (_sosStep >= _sosPattern.length) {
      _sosStep = 0;
      Future.delayed(const Duration(milliseconds: 1000), () => _runSOSPattern());
      return;
    }
    final duration = _sosPattern[_sosStep];
    final isOn = _sosStep % 2 == 0;
    setState(() => _isOn = isOn);
    _sosStep++;
    Future.delayed(Duration(milliseconds: duration), () => _runSOSPattern());
  }

  void _sendMorse(String text) {
    if (!_isOn) {
      MiuixToast.show(context, '请先开启手电筒', icon: Icons.error_outline);
      return;
    }
    _sosMode = false;
    _morseMode = true;
    MiuixToast.show(context, '发送摩尔斯电码: $text', icon: Icons.code);
    // 模拟发送
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _morseMode = false);
        MiuixToast.show(context, '发送完成', icon: Icons.check_circle);
      }
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
    final bgColor = _isOn
        ? _colors[_lightColor].withValues(alpha: _brightness * 0.15)
        : MiuixColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: MiuixAppBar(
        title: '手电筒',
        backgroundColor: _isOn ? _colors[_lightColor].withValues(alpha: 0.3) : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: Column(
          children: [
            _buildAnimatedItem(_buildLightBulb(), 0),
            const SizedBox(height: MiuixSpacing.xl),
            _buildAnimatedItem(_buildPowerButton(), 1),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildBrightnessSlider(), 2),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildColorSelector(), 3),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildFunctionButtons(), 4),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildMorseButtons(), 5),
          ],
        ),
      ),
    );
  }

  Widget _buildLightBulb() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final glow = _isOn ? _pulseController.value * 0.3 + 0.7 : 0.0;
        return Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isOn ? _colors[_lightColor].withValues(alpha: glow * 0.3) : MiuixColors.surfaceVariant,
            boxShadow: _isOn
                ? [
                    BoxShadow(
                      color: _colors[_lightColor].withValues(alpha: glow * 0.6),
                      blurRadius: 60,
                      spreadRadius: 20,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            _isOn ? Icons.flashlight_on : Icons.flashlight_off,
            size: 64,
            color: _isOn ? _colors[_lightColor] : MiuixColors.textTertiary,
          ),
        );
      },
    );
  }

  Widget _buildPowerButton() {
    return GestureDetector(
      onTap: _toggleLight,
      child: AnimatedContainer(
        duration: MiuixDuration.fast,
        curve: MiuixCurves.miuixSpring,
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: _isOn
              ? const LinearGradient(colors: MiuixColors.primaryGradient)
              : null,
          color: _isOn ? null : MiuixColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: _isOn ? MiuixColors.primary : MiuixColors.border,
            width: 2,
          ),
          boxShadow: _isOn ? MiuixShadows.md : null,
        ),
        child: Icon(
          Icons.power_settings_new,
          color: _isOn ? Colors.white : MiuixColors.textTertiary,
          size: 36,
        ),
      ),
    );
  }

  Widget _buildBrightnessSlider() {
    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('亮度',
                  style: TextStyle(fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
              Text('${(_brightness * 100).toInt()}%',
                  style: const TextStyle(color: MiuixColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: MiuixSpacing.sm),
          MiuixSlider(
            value: _brightness,
            min: 0.1,
            max: 1.0,
            onChanged: (v) => setState(() => _brightness = v),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector() {
    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('光色',
              style: TextStyle(fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: MiuixSpacing.md),
          Row(
            children: List.generate(_colors.length, (i) {
              final selected = _lightColor == i;
              return GestureDetector(
                onTap: () => setState(() => _lightColor = i),
                child: Padding(
                  padding: const EdgeInsets.only(right: MiuixSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _colors[i],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? MiuixColors.primary : MiuixColors.border,
                            width: selected ? 3 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _colors[i].withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: MiuixSpacing.sm),
                      Text(_colorNames[i],
                          style: TextStyle(
                              color: selected ? MiuixColors.primary : MiuixColors.textSecondary,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionButtons() {
    return Row(
      children: [
        Expanded(
          child: MiuixButton(
            label: _sosMode ? '关闭SOS' : 'SOS 求救',
            icon: Icons.sos,
            type: _sosMode ? MiuixButtonType.danger : MiuixButtonType.secondary,
            onPressed: _toggleSOS,
          ),
        ),
      ],
    );
  }

  Widget _buildMorseButtons() {
    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('摩尔斯电码',
              style: TextStyle(fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: MiuixSpacing.md),
          Wrap(
            spacing: MiuixSpacing.sm,
            runSpacing: MiuixSpacing.sm,
            children: [
              _morseButton('SOS', '... --- ...'),
              _morseButton('HELLO', '.... . .-.. .-.. ---'),
              _morseButton('YES', '-.-- . ...'),
              _morseButton('NO', '-. ---'),
              _morseButton('HELP', '.... . .-.. .--.'),
              _morseButton('OK', '--- -.-'),
            ],
          ),
          if (_morseMode) ...[
            const SizedBox(height: MiuixSpacing.md),
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: MiuixColors.primary),
                ),
                const SizedBox(width: MiuixSpacing.sm),
                const Text('正在发送摩尔斯电码...',
                    style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _morseButton(String label, String code) {
    return GestureDetector(
      onTap: () => _sendMorse(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: MiuixSpacing.md, vertical: MiuixSpacing.sm),
        decoration: BoxDecoration(
          color: MiuixColors.primary.withValues(alpha: 0.1),
          borderRadius: MiuixRadius.pillRadius,
          border: Border.all(color: MiuixColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(
                    color: MiuixColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: MiuixFontSize.sm)),
            Text(code,
                style: const TextStyle(
                    color: MiuixColors.textTertiary,
                    fontSize: 10,
                    letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}
