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
/// AIVoicePage —— AI 语音合成
/// 文本输入，音色选择(甜美/磁性/温柔/活力)，语速，音调
/// 生成播放(模拟)，下载，粉色波形动画
/// ============================================================
class AIVoicePage extends StatefulWidget {
  const AIVoicePage({super.key});

  @override
  State<AIVoicePage> createState() => _AIVoicePageState();
}

class _AIVoicePageState extends State<AIVoicePage>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _waveController;

  final TextEditingController _textController = TextEditingController();

  int _selectedVoice = 0;
  double _speed = 1.0;
  double _pitch = 1.0;
  bool _isGenerating = false;
  bool _isPlaying = false;
  bool _hasAudio = false;
  bool _hasError = false;
  String _errorMessage = '';
  double _playProgress = 0.0;

  static const List<String> _voices = ['甜美', '磁性', '温柔', '活力'];
  static const List<IconData> _voiceIcons = [Icons.favorite, Icons.mic, Icons.self_improvement, Icons.bolt];
  static const List<String> _voiceDescs = ['清甜少女音，适合故事和旁白', '低沉大叔音，适合新闻和解说', '柔和治愈音，适合助眠和情感', '元气少女音，适合广告和短视频'];
  static const List<String> _sampleTexts = [
    '大家好，欢迎来到初眠AI，今天我们要一起探索人工智能的奇妙世界。',
    '在一个遥远的国度，有一位勇敢的少年，他踏上了寻找宝藏的旅程。',
    '各位听众朋友们晚上好，今天是2024年3月15日，星期五，欢迎收听晚间新闻。',
    '限时特惠！全场五折起，错过再等一年！赶紧下单吧！',
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: MiuixDuration.slow);
    _waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _waveController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: MiuixCurves.miuixSpring)));
    final slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: Curves.easeOutCubic)));
    return AnimatedBuilder(animation: animation, builder: (_, __) => Opacity(opacity: animation.value, child: Transform.translate(offset: slide.value, child: child)));
  }

  Future<void> _generateVoice() async {
    if (_textController.text.trim().isEmpty) {
      MiuixToast.show(context, message: '请输入要合成的文本', type: MiuixToastType.warning);
      return;
    }
    setState(() {
      _isGenerating = true;
      _hasAudio = false;
      _hasError = false;
      _errorMessage = '';
      _isPlaying = false;
      _playProgress = 0;
    });

    try {
      final voice = _voices[_selectedVoice];
      final result = await ApiService.aiToolComplete(
        systemPrompt: '你是一位语音合成助手。用户希望用$voice的声音朗读以下文本。请确认文本内容，并给出朗读时的语气、停顿和情感建议。',
        userInput: _textController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _hasAudio = true;
        });
        MiuixToast.show(context, message: '语音合成完成', type: MiuixToastType.success);
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
    if (!_hasAudio) return;
    setState(() {
      _isPlaying = !_isPlaying;
    });
    if (_isPlaying) {
      _simulatePlayback();
    }
  }

  Future<void> _simulatePlayback() async {
    while (_isPlaying && _playProgress < 1.0) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isPlaying) break;
      setState(() {
        _playProgress += 0.01 * _speed;
        if (_playProgress >= 1.0) {
          _playProgress = 1.0;
          _isPlaying = false;
        }
      });
    }
  }

  void _resetPlayback() {
    setState(() {
      _isPlaying = false;
      _playProgress = 0;
    });
  }

  Future<void> _download() async {
    if (!_hasAudio) return;
    MiuixToast.show(context, message: '语音文件下载中...', type: MiuixToastType.info);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) MiuixToast.show(context, message: '下载完成：voice_${_voices[_selectedVoice]}.mp3', type: MiuixToastType.success);
  }

  String _formatDuration(double progress) {
    final total = (5 + _textController.text.length * 0.05 / _speed).toInt();
    final current = (total * progress).toInt();
    return '${current ~/ 60}:${(current % 60).toString().padLeft(2, '0')} / ${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(title: 'AI 语音合成', backgroundColor: MiuixColors.background),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedItem(_buildTextInput(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildVoiceSelector(), 1),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildParameterSliders(), 2),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildGenerateButton(), 3),
            const SizedBox(height: 20),
            if (_isGenerating) _buildAnimatedItem(_buildGeneratingCard(), 4),
            if (_hasAudio) _buildAnimatedItem(_buildPlayerCard(), 4),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('合成文本', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
              Text('${_textController.text.length} 字', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 12),
          MiuixInput(
            controller: _textController,
            hintText: '输入要合成为语音的文本内容...',
            prefixIcon: Icons.text_fields,
            maxLines: 5,
            minLines: 3,
            type: MiuixInputType.multiline,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_sampleTexts.length, (index) {
              return MiuixChip(
                label: _sampleTexts[index].length > 16 ? '${_sampleTexts[index].substring(0, 16)}...' : _sampleTexts[index],
                onTap: () => _textController.text = _sampleTexts[index],
                style: MiuixChipStyle.normal,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceSelector() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('选择音色', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          ...List.generate(_voices.length, (index) {
            final isSelected = _selectedVoice == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MiuixRipple(
                borderRadius: MiuixRadius.md,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedVoice = index),
                  child: AnimatedContainer(
                    duration: MiuixDuration.fast,
                    curve: MiuixCurves.miuixSpring,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: isSelected ? const LinearGradient(colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)]) : null,
                      color: isSelected ? null : MiuixColors.surfaceVariant,
                      borderRadius: MiuixRadius.mdRadius,
                      border: Border.all(color: isSelected ? MiuixColors.primary : MiuixColors.borderLight, width: isSelected ? 1.5 : 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(gradient: isSelected ? const LinearGradient(colors: MiuixColors.primaryGradient) : null, color: isSelected ? null : MiuixColors.primaryLight.withOpacity(0.2), borderRadius: MiuixRadius.smRadius),
                          child: Icon(_voiceIcons[index], color: isSelected ? Colors.white : MiuixColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_voices[index], style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: isSelected ? MiuixColors.primary : MiuixColors.textPrimary)),
                              Text(_voiceDescs[index], style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
                            ],
                          ),
                        ),
                        if (isSelected) const Icon(Icons.check_circle, color: MiuixColors.primary, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
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
          _buildSlider('语速', _speed, 0.5, 2.0, '${_speed.toStringAsFixed(1)}x', (val) => setState(() => _speed = val)),
          const SizedBox(height: 12),
          _buildSlider('音调', _pitch, 0.5, 2.0, '${_pitch.toStringAsFixed(1)}x', (val) => setState(() => _pitch = val)),
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
            overlayColor: MiuixColors.primaryLight.withOpacity(0.3),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(value: value, min: min, max: max, divisions: 15, label: display, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: _isGenerating ? '合成中...' : '生成语音',
        icon: Icons.record_voice_over,
        type: MiuixButtonType.gradient,
        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
        size: MiuixButtonSize.large,
        loading: _isGenerating,
        onPressed: _isGenerating ? null : _generateVoice,
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
        const Text('AI 正在合成语音...', style: TextStyle(fontSize: MiuixFontSize.md, color: MiuixColors.textSecondary)),
        const SizedBox(height: 8),
        Text('${_voices[_selectedVoice]}音色 · 语速${_speed.toStringAsFixed(1)}x', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
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
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.smRadius), child: const Icon(Icons.graphic_eq, color: Colors.white, size: 20)),
              const SizedBox(width: 10),
              Expanded(child: Text('语音合成结果 · ${_voices[_selectedVoice]}', style: const TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary))),
            ],
          ),
          const SizedBox(height: 20),
          // 粉色波形动画
          _buildWaveform(),
          const SizedBox(height: 20),
          // 进度条
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: MiuixColors.primary,
              inactiveTrackColor: Colors.white.withOpacity(0.5),
              thumbColor: Colors.white,
              overlayColor: MiuixColors.primaryLight.withOpacity(0.3),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(value: _playProgress, min: 0, max: 1, onChanged: (val) => setState(() => _playProgress = val)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(_playProgress), style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
              Text('${(_playProgress * 100).toInt()}%', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 16),
          // 播放控制
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MiuixIconButton(icon: Icons.replay_10, style: MiuixIconButtonStyle.outlined, size: 44, iconSize: 22, onPressed: () => setState(() => _playProgress = (_playProgress - 0.1).clamp(0.0, 1.0))),
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
              MiuixIconButton(icon: Icons.forward_10, style: MiuixIconButtonStyle.outlined, size: 44, iconSize: 22, onPressed: () => setState(() => _playProgress = (_playProgress + 0.1).clamp(0.0, 1.0))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: MiuixButton(label: '重新生成', icon: Icons.refresh, type: MiuixButtonType.secondary, onPressed: _generateVoice)),
              const SizedBox(width: 12),
              Expanded(child: MiuixButton(label: '下载语音', icon: Icons.download, type: MiuixButtonType.primary, onPressed: _download)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(40, (index) {
              final phase = (index / 40) * math.pi * 4;
              final baseHeight = 8.0 + math.sin(phase + _waveController.value * math.pi * 2) * 12;
              final animatedHeight = _isPlaying ? baseHeight : (8.0 + math.sin(phase) * 4);
              return Container(
                width: 4,
                height: animatedHeight.clamp(4.0, 40.0),
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [MiuixColors.primaryLight, MiuixColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
