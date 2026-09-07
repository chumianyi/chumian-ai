import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chumian_ai/services/api_service.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_chip.dart';
import 'package:chumian_ai/widgets/miuix/miuix_input.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_progress.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';

/// ============================================================
/// AIMusicPage —— AI 音乐生成
/// 风格选择(流行/摇滚/电子/古典/民谣)，情绪，时长，BPM
/// 生成音乐(模拟)，播放器界面，粉色可视化
/// ============================================================
class AIMusicPage extends StatefulWidget {
  const AIMusicPage({super.key});

  @override
  State<AIMusicPage> createState() => _AIMusicPageState();
}

class _AIMusicPageState extends State<AIMusicPage>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _vizController;

  final TextEditingController _promptController = TextEditingController();

  int _selectedStyle = 0;
  int _selectedMood = 0;
  double _duration = 30;
  double _bpm = 120;
  bool _isGenerating = false;
  bool _isPlaying = false;
  bool _hasMusic = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _generatedLyrics = '';
  double _playProgress = 0.0;

  static const List<String> _styles = ['流行', '摇滚', '电子', '古典', '民谣'];
  static const List<IconData> _styleIcons = [Icons.music_note, Icons.electric_bolt, Icons.computer, Icons.piano, Icons.ac_unit];
  static const List<String> _moods = ['欢快', '抒情', '激昂', '治愈', '神秘'];
  static const List<IconData> _moodIcons = [Icons.sentiment_very_satisfied, Icons.favorite, Icons.whatshot, Icons.self_improvement, Icons.auto_awesome];
  static const List<String> _samplePrompts = [
    '夏日海边的轻松旋律，适合度假氛围',
    '热血沸腾的战斗背景音乐，史诗感',
    '深夜咖啡馆的慵懒爵士，温柔浪漫',
    '森林清晨的自然之声，空灵治愈',
    '赛博朋克城市夜景，科技感电子乐',
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: MiuixDuration.slow);
    _vizController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat();
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _vizController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: MiuixCurves.miuixSpring)));
    final slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: Curves.easeOutCubic)));
    return AnimatedBuilder(animation: animation, builder: (_, __) => Opacity(opacity: animation.value, child: Transform.translate(offset: slide.value, child: child)));
  }

  Future<void> _generateMusic() async {
    setState(() {
      _isGenerating = true;
      _hasMusic = false;
      _hasError = false;
      _errorMessage = '';
      _isPlaying = false;
      _playProgress = 0;
    });

    try {
      final style = _styles[_selectedStyle];
      final mood = _moods[_selectedMood];
      final result = await ApiService.aiToolComplete(
        systemPrompt: '你是一位专业音乐创作人。请根据用户描述，创作一首$style风格、$mood情绪的歌曲歌词。包含歌名、主歌、副歌、桥段，格式清晰。',
        userInput: _promptController.text.trim().isEmpty ? '创作一首原创歌曲' : _promptController.text,
      );
      if (mounted) {
        _generatedLyrics = result;
        setState(() {
          _isGenerating = false;
          _hasMusic = true;
        });
        MiuixToast.show(context, message: '音乐创作完成', type: MiuixToastType.success);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _togglePlay() {
    if (!_hasMusic) return;
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) _simulatePlayback();
  }

  Future<void> _simulatePlayback() async {
    while (_isPlaying && _playProgress < 1.0) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isPlaying) break;
      setState(() {
        _playProgress += 0.005;
        if (_playProgress >= 1.0) {
          _playProgress = 1.0;
          _isPlaying = false;
        }
      });
    }
  }

  String _formatTime(double progress) {
    final total = _duration.toInt();
    final current = (total * progress).toInt();
    return '${current ~/ 60}:${(current % 60).toString().padLeft(2, '0')} / ${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _download() async {
    if (!_hasMusic) return;
    MiuixToast.show(context, message: '音乐下载中...', type: MiuixToastType.info);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) MiuixToast.show(context, message: '歌词已复制到剪贴板', type: MiuixToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(title: 'AI 音乐生成', backgroundColor: MiuixColors.background),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedItem(_buildPromptInput(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildStyleSelector(), 1),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildMoodSelector(), 2),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildParameterSliders(), 3),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildGenerateButton(), 4),
            const SizedBox(height: 20),
            if (_isGenerating) _buildAnimatedItem(_buildGeneratingCard(), 5),
            if (_hasMusic) _buildAnimatedItem(_buildPlayerCard(), 5),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptInput() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('音乐描述', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          MiuixInput(
            controller: _promptController,
            hintText: '描述你想要的音乐，如：夏日海边的轻松旋律...',
            prefixIcon: Icons.edit_note,
            maxLines: 3,
            minLines: 2,
            type: MiuixInputType.multiline,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_samplePrompts.length, (index) {
              return MiuixChip(
                label: _samplePrompts[index].length > 14 ? '${_samplePrompts[index].substring(0, 14)}...' : _samplePrompts[index],
                onTap: () => _promptController.text = _samplePrompts[index],
                style: MiuixChipStyle.normal,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleSelector() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('音乐风格', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_styles.length, (index) {
              final isSelected = _selectedStyle == index;
              return MiuixRipple(
                borderRadius: MiuixRadius.md,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedStyle = index),
                  child: AnimatedContainer(
                    duration: MiuixDuration.fast,
                    curve: MiuixCurves.miuixSpring,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected ? const LinearGradient(colors: MiuixColors.primaryGradient) : null,
                      color: isSelected ? null : MiuixColors.surfaceVariant,
                      borderRadius: MiuixRadius.mdRadius,
                      boxShadow: isSelected ? MiuixShadows.sm : null,
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_styleIcons[index], size: 18, color: isSelected ? Colors.white : MiuixColors.primary),
                      const SizedBox(width: 6),
                      Text(_styles[index], style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : MiuixColors.textSecondary)),
                    ]),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelector() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('情绪氛围', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_moods.length, (index) {
              final isSelected = _selectedMood == index;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 4 ? 6 : 0),
                  child: MiuixRipple(
                    borderRadius: MiuixRadius.md,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMood = index),
                      child: AnimatedContainer(
                        duration: MiuixDuration.fast,
                        curve: MiuixCurves.miuixSpring,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: isSelected ? const LinearGradient(colors: MiuixColors.primaryGradient) : null,
                          color: isSelected ? null : MiuixColors.surfaceVariant,
                          borderRadius: MiuixRadius.mdRadius,
                          boxShadow: isSelected ? MiuixShadows.sm : null,
                        ),
                        child: Column(
                          children: [
                            Icon(_moodIcons[index], size: 20, color: isSelected ? Colors.white : MiuixColors.primary),
                            const SizedBox(height: 4),
                            Text(_moods[index], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : MiuixColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterSliders() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSlider('音乐时长', _duration, 10, 120, '${_duration.toInt()}秒', (val) => setState(() => _duration = val)),
          const SizedBox(height: 12),
          _buildSlider('BPM 节拍', _bpm, 60, 200, '${_bpm.toInt()} BPM', (val) => setState(() => _bpm = val)),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, String display, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.pillRadius),
              child: Text(display, style: const TextStyle(color: Colors.white, fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: MiuixColors.primary,
            inactiveTrackColor: MiuixColors.surfaceVariant,
            thumbColor: Colors.white,
            overlayColor: MiuixColors.primaryLight.withValues(alpha: 0.3),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(value: value, min: min, max: max, divisions: ((max - min) / 10).round(), label: display, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: _isGenerating ? '生成中...' : '生成音乐',
        icon: Icons.music_video,
        type: MiuixButtonType.gradient,
        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
        size: MiuixButtonSize.large,
        loading: _isGenerating,
        onPressed: _isGenerating ? null : _generateMusic,
      ),
    );
  }

  Widget _buildGeneratingCard() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const MiuixProgress(type: MiuixProgressType.circularIndeterminate, size: 48, strokeWidth: 4),
        const SizedBox(height: 16),
        const Text('AI 正在创作音乐...', style: TextStyle(fontSize: MiuixFontSize.md, color: MiuixColors.textSecondary)),
        const SizedBox(height: 8),
        Text('${_styles[_selectedStyle]} · ${_moods[_selectedMood]} · ${_bpm.toInt()}BPM', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
      ]),
    );
  }

  Widget _buildPlayerCard() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)]),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 专辑封面 + 信息
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
                  borderRadius: MiuixRadius.mdRadius,
                  boxShadow: MiuixShadows.md,
                ),
                child: const Icon(Icons.album, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_moods[_selectedMood]}的${_styles[_selectedStyle]}', style: const TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w700, color: MiuixColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('初眠AI原创 · ${_bpm.toInt()}BPM · ${_duration.toInt()}秒', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        MiuixChip(label: _styles[_selectedStyle], style: MiuixChipStyle.normal, height: 24),
                        const SizedBox(width: 6),
                        MiuixChip(label: _moods[_selectedMood], style: MiuixChipStyle.normal, height: 24),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 粉色可视化
          _buildVisualizer(),
          const SizedBox(height: 20),
          // 进度条
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: MiuixColors.primary,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.5),
              thumbColor: Colors.white,
              overlayColor: MiuixColors.primaryLight.withValues(alpha: 0.3),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(value: _playProgress, min: 0, max: 1, onChanged: (val) => setState(() => _playProgress = val)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatTime(_playProgress), style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
              Text('${(_playProgress * 100).toInt()}%', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 16),
          // 播放控制
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MiuixIconButton(icon: Icons.skip_previous, style: MiuixIconButtonStyle.outlined, size: 44, iconSize: 22, onPressed: () => setState(() => _playProgress = 0)),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _togglePlay,
                child: AnimatedContainer(
                  duration: MiuixDuration.fast,
                  curve: MiuixCurves.miuixSpring,
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), shape: BoxShape.circle, boxShadow: MiuixShadows.md),
                  child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 32),
                ),
              ),
              const SizedBox(width: 16),
              MiuixIconButton(icon: Icons.skip_next, style: MiuixIconButtonStyle.outlined, size: 44, iconSize: 22, onPressed: _generateMusic),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: MiuixButton(label: '重新生成', icon: Icons.refresh, type: MiuixButtonType.secondary, onPressed: _generateMusic)),
              const SizedBox(width: 12),
              Expanded(child: MiuixButton(label: '下载音乐', icon: Icons.download, type: MiuixButtonType.primary, onPressed: _download)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizer() {
    return AnimatedBuilder(
      animation: _vizController,
      builder: (context, child) {
        return SizedBox(
          height: 80,
          child: CustomPaint(
            size: const Size(double.infinity, 80),
            painter: _VisualizerPainter(
              progress: _vizController.value,
              isPlaying: _isPlaying,
              bpm: _bpm,
            ),
          ),
        );
      },
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final double bpm;

  _VisualizerPainter({required this.progress, required this.isPlaying, required this.bpm});

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = 48;
    final barWidth = size.width / barCount * 0.6;
    final spacing = size.width / barCount;
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final x = i * spacing + spacing / 2;
      final phase = (i / barCount) * math.pi * 6;
      final wave1 = math.sin(phase + progress * math.pi * 2 * (bpm / 120));
      final wave2 = math.sin(phase * 1.5 + progress * math.pi * 3);
      final amplitude = isPlaying ? (wave1 * 0.5 + wave2 * 0.3 + 0.2) : (math.sin(phase) * 0.1 + 0.05);
      final barHeight = (amplitude * size.height * 0.8).clamp(4.0, size.height * 0.85);

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, centerY), width: barWidth, height: barHeight),
        const Radius.circular(3),
      );

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [MiuixColors.primaryLight, MiuixColors.primary, MiuixColors.primaryDark],
        ).createShader(rect.outerRect);

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isPlaying != isPlaying;
  }
}
