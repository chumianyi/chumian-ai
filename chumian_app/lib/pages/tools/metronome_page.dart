import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_slider.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';

/// ============================================================
/// MetronomePage —— 节拍器
/// BPM调节(30-300)，节拍动画，拍号选择
/// 开始/暂停，粉色脉冲，视觉节拍
/// ============================================================
class MetronomePage extends StatefulWidget {
  const MetronomePage({super.key});

  @override
  State<MetronomePage> createState() => _MetronomePageState();
}

class _MetronomePageState extends State<MetronomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _pulseController;

  int _bpm = 120;
  int _beatsPerMeasure = 4; // 拍号分子
  int _beatUnit = 4; // 拍号分母
  int _currentBeat = 0;
  bool _isPlaying = false;
  Timer? _timer;
  double _pendulumAngle = 0;

  static const List<int> _beatOptions = [2, 3, 4, 5, 6, 7, 8, 9];
  static const List<int> _unitOptions = [2, 4, 8, 16];
  static const List<String> _tempoMarks = [
    ' Grave 庄板', 'Largo 广板', 'Lento 慢板', 'Adagio 柔板',
    'Andante 行板', 'Moderato 中板', 'Allegro 快板', 'Vivace 急板',
    'Presto 最急板',
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
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _tempoName {
    if (_bpm < 40) return _tempoMarks[0];
    if (_bpm < 60) return _tempoMarks[1];
    if (_bpm < 66) return _tempoMarks[2];
    if (_bpm < 76) return _tempoMarks[3];
    if (_bpm < 108) return _tempoMarks[4];
    if (_bpm < 120) return _tempoMarks[5];
    if (_bpm < 156) return _tempoMarks[6];
    if (_bpm < 176) return _tempoMarks[7];
    return _tempoMarks[8];
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _startTick();
      MiuixToast.show(context, '节拍器已启动', icon: Icons.music_note);
    } else {
      _timer?.cancel();
      _currentBeat = 0;
    }
  }

  void _startTick() {
    _timer?.cancel();
    final interval = (60000 / _bpm).round();
    _timer = Timer.periodic(Duration(milliseconds: interval), (_) {
      if (!mounted) return;
      setState(() {
        _currentBeat = (_currentBeat + 1) % _beatsPerMeasure;
        _pendulumAngle = _currentBeat % 2 == 0 ? 0.4 : -0.4;
      });
      _pulseController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _pendulumAngle = 0);
      });
    });
  }

  void _updateBpm(int value) {
    setState(() => _bpm = value);
    if (_isPlaying) _startTick();
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
      appBar: MiuixAppBar(title: '节拍器'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: Column(
          children: [
            _buildAnimatedItem(_buildBpmDisplay(), 0),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildPendulum(), 1),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildBeatIndicator(), 2),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildBpmSlider(), 3),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildTimeSignature(), 4),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildPlayButton(), 5),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildQuickBpm(), 6),
          ],
        ),
      ),
    );
  }

  Widget _buildBpmDisplay() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
      child: Column(
        children: [
          const Text('BPM',
              style: TextStyle(color: Colors.white70, fontSize: MiuixFontSize.sm, letterSpacing: 4)),
          const SizedBox(height: MiuixSpacing.sm),
          AnimatedSwitcher(
            duration: MiuixDuration.fast,
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Text('$_bpm',
                key: ValueKey(_bpm),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 64,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: MiuixSpacing.xs),
          Text(_tempoName,
              style: const TextStyle(color: Colors.white70, fontSize: MiuixFontSize.sm)),
        ],
      ),
    );
  }

  Widget _buildPendulum() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final pulse = _isPlaying ? _pulseController.value : 0.0;
        return Container(
          height: 160,
          decoration: BoxDecoration(
            color: MiuixColors.surface,
            borderRadius: MiuixRadius.lgRadius,
            border: Border.all(color: MiuixColors.borderLight),
          ),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // 顶部支点
              Positioned(
                top: 10,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: MiuixColors.primaryDeep,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // 摆杆
              AnimatedRotation(
                duration: const Duration(milliseconds: 100),
                turns: _pendulumAngle / (2 * pi),
                child: Container(
                  width: 4,
                  height: 120,
                  margin: const EdgeInsets.only(top: 18),
                  decoration: BoxDecoration(
                    color: MiuixColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 28 + pulse * 10,
                      height: 28 + pulse * 10,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: MiuixColors.primary.withOpacity(0.4 + pulse * 0.3),
                            blurRadius: 12 + pulse * 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // 脉冲光晕
              if (_isPlaying && pulse > 0)
                Positioned(
                  top: 70,
                  child: Container(
                    width: 60 * pulse,
                    height: 60 * pulse,
                    decoration: BoxDecoration(
                      color: MiuixColors.primary.withOpacity((1 - pulse) * 0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBeatIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_beatsPerMeasure, (i) {
        final isActive = _isPlaying && _currentBeat == i;
        final isAccent = i == 0;
        return AnimatedContainer(
          duration: MiuixDuration.fast,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isAccent ? 24 : 18,
          height: isAccent ? 24 : 18,
          decoration: BoxDecoration(
            color: isActive
                ? (isAccent ? MiuixColors.primaryDeep : MiuixColors.primary)
                : MiuixColors.surfaceVariant,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? MiuixColors.primary : MiuixColors.border,
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: MiuixColors.primary.withOpacity(0.5),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text('${i + 1}',
                style: TextStyle(
                    color: isActive ? Colors.white : MiuixColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        );
      }),
    );
  }

  Widget _buildBpmSlider() {
    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('速度调节',
              style: TextStyle(fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: MiuixSpacing.md),
          MiuixSlider(
            value: _bpm.toDouble(),
            min: 30,
            max: 300,
            divisions: 270,
            label: '$_bpm BPM',
            onChanged: (v) => _updateBpm(v.toInt()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MiuixButton(
                label: '-5',
                type: MiuixButtonType.secondary,
                width: 60,
                onPressed: () => _updateBpm(max(30, _bpm - 5)),
              ),
              MiuixButton(
                label: '-1',
                type: MiuixButtonType.secondary,
                width: 50,
                onPressed: () => _updateBpm(max(30, _bpm - 1)),
              ),
              MiuixButton(
                label: '+1',
                width: 50,
                onPressed: () => _updateBpm(min(300, _bpm + 1)),
              ),
              MiuixButton(
                label: '+5',
                width: 60,
                onPressed: () => _updateBpm(min(300, _bpm + 5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSignature() {
    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('拍号',
              style: TextStyle(fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: MiuixSpacing.md),
          Row(
            children: [
              const Text('每小节拍数:', style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm)),
              const SizedBox(width: MiuixSpacing.sm),
              Expanded(
                child: Wrap(
                  spacing: 4,
                  children: _beatOptions.map((b) {
                    final selected = _beatsPerMeasure == b;
                    return GestureDetector(
                      onTap: () => setState(() => _beatsPerMeasure = b),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: selected ? MiuixColors.primary : MiuixColors.surfaceVariant,
                          borderRadius: MiuixRadius.smRadius,
                          border: Border.all(color: selected ? MiuixColors.primary : MiuixColors.borderLight),
                        ),
                        child: Center(
                          child: Text('$b',
                              style: TextStyle(
                                  color: selected ? Colors.white : MiuixColors.textSecondary,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: MiuixSpacing.md),
          Row(
            children: [
              const Text('节拍单位:', style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm)),
              const SizedBox(width: MiuixSpacing.sm),
              Wrap(
                spacing: 4,
                children: _unitOptions.map((u) {
                  final selected = _beatUnit == u;
                  return GestureDetector(
                    onTap: () => setState(() => _beatUnit = u),
                    child: Container(
                      width: 36,
                      height: 32,
                      decoration: BoxDecoration(
                        color: selected ? MiuixColors.primary : MiuixColors.surfaceVariant,
                        borderRadius: MiuixRadius.smRadius,
                        border: Border.all(color: selected ? MiuixColors.primary : MiuixColors.borderLight),
                      ),
                      child: Center(
                        child: Text('$u',
                            style: TextStyle(
                                color: selected ? Colors.white : MiuixColors.textSecondary,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: MiuixSpacing.sm),
          Text('当前拍号: $_beatsPerMeasure/$_beatUnit',
              style: const TextStyle(color: MiuixColors.primary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: _togglePlay,
      child: AnimatedContainer(
        duration: MiuixDuration.fast,
        curve: MiuixCurves.miuixSpring,
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: _isPlaying
              ? const LinearGradient(colors: [MiuixColors.error, MiuixColors.primaryDeep])
              : const LinearGradient(colors: MiuixColors.primaryGradient),
          shape: BoxShape.circle,
          boxShadow: MiuixShadows.lg,
        ),
        child: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildQuickBpm() {
    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('常用速度',
              style: TextStyle(fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: MiuixSpacing.md),
          Wrap(
            spacing: MiuixSpacing.sm,
            runSpacing: MiuixSpacing.sm,
            children: [
              _quickBpmChip(60, '慢板'),
              _quickBpmChip(80, '行板'),
              _quickBpmChip(100, '中板'),
              _quickBpmChip(120, '标准'),
              _quickBpmChip(140, '快板'),
              _quickBpmChip(160, '急板'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickBpmChip(int bpm, String label) {
    final selected = _bpm == bpm;
    return GestureDetector(
      onTap: () => _updateBpm(bpm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: MiuixSpacing.md, vertical: MiuixSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? MiuixColors.primary : MiuixColors.surfaceVariant,
          borderRadius: MiuixRadius.pillRadius,
          border: Border.all(color: selected ? MiuixColors.primary : MiuixColors.borderLight),
        ),
        child: Text('$label $bpm',
            style: TextStyle(
                color: selected ? Colors.white : MiuixColors.textSecondary,
                fontSize: MiuixFontSize.sm,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}
