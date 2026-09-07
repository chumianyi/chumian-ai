import 'package:flutter/material.dart';
import 'package:chumian_ai/services/api_service.dart';
import 'package:flutter/services.dart';
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
/// AIContinueStoryPage —— AI 续写故事
/// 故事开头输入，风格选择(玄幻/都市/科幻/言情/悬疑)，字数
/// 生成续写，章节展示，继续续写按钮
/// ============================================================
class AIContinueStoryPage extends StatefulWidget {
  const AIContinueStoryPage({super.key});

  @override
  State<AIContinueStoryPage> createState() => _AIContinueStoryPageState();
}

class _AIContinueStoryPageState extends State<AIContinueStoryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _typewriterController;

  final TextEditingController _openingController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();

  int _selectedStyle = 0;
  double _wordCount = 500;
  bool _isGenerating = false;
  bool _hasResult = false;
  bool _hasError = false;
  String _errorMessage = \'\';
  String _displayedText = '';
  int _typewriterIndex = 0;
  int _chapterCount = 0;
  final List<String> _chapters = [];

  static const List<String> _styles = ['玄幻', '都市', '科幻', '言情', '悬疑'];
  static const List<IconData> _styleIcons = [
    Icons.auto_awesome,
    Icons.location_city,
    Icons.rocket_launch,
    Icons.favorite,
    Icons.search,
  ];

  static const List<String> _sampleOpenings = [
    '深夜，我独自走在回家的路上，突然听到身后传来一阵奇怪的脚步声...',
    '林晓推开那扇尘封已久的大门，眼前的景象让她屏住了呼吸...',
    '公元2156年，人类首次发现了来自半人马座的信号...',
    '他站在雨中，手里攥着那封信，已经整整十年了...',
    '那栋别墅的第七个房间，从来没有人敢在午夜之后打开...',
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
        vsync: this, duration: MiuixDuration.slow);
    _typewriterController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 35));
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _typewriterController.dispose();
    _openingController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.08, (index * 0.08) + 0.4,
            curve: MiuixCurves.miuixSpring)));
    final slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entryController,
            curve: Interval(index * 0.08, (index * 0.08) + 0.4,
                curve: Curves.easeOutCubic)));
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Opacity(
          opacity: animation.value,
          child: Transform.translate(offset: slide.value, child: child)),
    );
  }

  Future<void> _generateContinue() async {
    final opening = _openingController.text.trim();
    if (opening.isEmpty && _chapters.isEmpty) {
      MiuixToast.show(context,
          message: '请先输入故事开头', type: MiuixToastType.warning);
      return;
    }
    setState(() {
      _isGenerating = true;
      _hasResult = false;
      _displayedText = '';
      _typewriterIndex = 0;
    });
    try {
      final result = await ApiService.aiToolComplete(
        systemPrompt: '你是一位专业的故事续写作家。请根据用户提供的故事开头，自然地续写后续情节，保持风格一致，情节连贯。',
        userInput: _openingController.text,
      );
      if (mounted) {
        _chapterCount++;
        _chapters.add(result);
        _resultController.text = result;
        _startTypewriter(result);
        setState(() {
          _isGenerating = false;
          _hasResult = true;
          _hasError = false;
        });
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
    _startTypewriter(generated);
  }

  void _startTypewriter(String text) {
    _typewriterIndex = 0;
    _typewriterController.removeListener(_tick);
    _typewriterController.addListener(_tick);
    _typewriterController.repeat();
  }

  void _tick() {
    if (_typewriterIndex < _resultController.text.length) {
      setState(() {
        _typewriterIndex += 3;
        if (_typewriterIndex > _resultController.text.length) {
          _typewriterIndex = _resultController.text.length;
        }
        _displayedText = _resultController.text.substring(0, _typewriterIndex);
      });
    } else {
      _typewriterController.stop();
      _typewriterController.removeListener(_tick);
    }
  }

  Future<void> _copyResult() async {
    if (_resultController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _resultController.text));
    if (mounted) {
      MiuixToast.show(context,
          message: '已复制到剪贴板', type: MiuixToastType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(title: 'AI 续写故事', backgroundColor: MiuixColors.background),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedItem(_buildOpeningInput(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildStyleSelector(), 1),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildWordCountSlider(), 2),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildGenerateButton(), 3),
            const SizedBox(height: 20),
            if (_isGenerating) _buildAnimatedItem(_buildLoadingCard(), 4),
            if (_hasError) _buildAnimatedItem(_buildErrorCard(), 5),

            if (_hasResult) _buildAnimatedItem(_buildResultCard(), 4),
            if (_chapters.length > 1) _buildAnimatedItem(_buildChapterList(), 5),
          ],
        ),
      ),
    );
  }

  Widget _buildOpeningInput() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('故事开头',
              style: TextStyle(
                  fontSize: MiuixFontSize.lg,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          MiuixInput(
            controller: _openingController,
            hintText: '输入故事的开头，AI将为你续写精彩剧情...',
            prefixIcon: Icons.edit_outlined,
            maxLines: 4,
            minLines: 3,
            type: MiuixInputType.multiline,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_sampleOpenings.length, (index) {
              return MiuixChip(
                label: _sampleOpenings[index].length > 12
                    ? '${_sampleOpenings[index].substring(0, 12)}...'
                    : _sampleOpenings[index],
                onTap: () => _openingController.text = _sampleOpenings[index],
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
          const Text('故事风格',
              style: TextStyle(
                  fontSize: MiuixFontSize.lg,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary)),
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
                      gradient: isSelected
                          ? const LinearGradient(colors: MiuixColors.primaryGradient)
                          : null,
                      color: isSelected ? null : MiuixColors.surfaceVariant,
                      borderRadius: MiuixRadius.mdRadius,
                      boxShadow: isSelected ? MiuixShadows.sm : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_styleIcons[index],
                            size: 18,
                            color: isSelected ? Colors.white : MiuixColors.primary),
                        const SizedBox(width: 6),
                        Text(_styles[index],
                            style: TextStyle(
                                fontSize: MiuixFontSize.md,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : MiuixColors.textSecondary)),
                      ],
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

  Widget _buildWordCountSlider() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('续写字数',
                  style: TextStyle(
                      fontSize: MiuixFontSize.md,
                      fontWeight: FontWeight.w600,
                      color: MiuixColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
                  borderRadius: MiuixRadius.pillRadius,
                ),
                child: Text('${_wordCount.toInt()} 字',
                    style: const TextStyle(
                        color: Colors.white, fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: MiuixColors.primary,
              inactiveTrackColor: MiuixColors.surfaceVariant,
              thumbColor: Colors.white,
              overlayColor: MiuixColors.primaryLight.withOpacity(0.3),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: _wordCount,
              min: 300,
              max: 2000,
              divisions: 17,
              label: '${_wordCount.toInt()}字',
              onChanged: (val) => setState(() => _wordCount = val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: _isGenerating
            ? '续写中...'
            : (_chapters.isEmpty ? '开始续写' : '继续续写'),
        icon: Icons.auto_awesome,
        type: MiuixButtonType.gradient,
        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
        size: MiuixButtonSize.large,
        loading: _isGenerating,
        onPressed: _isGenerating ? null : _generateContinue,
      ),
    );
  }

  Widget _buildLoadingCard() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const MiuixProgress(
              type: MiuixProgressType.circularIndeterminate, size: 48, strokeWidth: 4),
          const SizedBox(height: 16),
          Text('AI 正在构思第${_chapterCount + 1}章...',
              style: const TextStyle(fontSize: MiuixFontSize.md, color: MiuixColors.textSecondary)),
          const SizedBox(height: 8),
          Text('${_styles[_selectedStyle]}风格续写中，请稍候',
              style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)]),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
                  borderRadius: MiuixRadius.smRadius,
                ),
                child: const Icon(Icons.auto_stories, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('第 $_chapterCount 章',
                    style: const TextStyle(
                        fontSize: MiuixFontSize.lg,
                        fontWeight: FontWeight.w600,
                        color: MiuixColors.textPrimary)),
              ),
              MiuixIconButton(
                  icon: Icons.copy,
                  style: MiuixIconButtonStyle.outlined,
                  size: 36,
                  iconSize: 18,
                  onPressed: _copyResult),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: MiuixRadius.mdRadius,
              border: Border.all(color: MiuixColors.borderLight),
            ),
            child: SingleChildScrollView(
              maxHeight: 450,
              child: Text(_displayedText,
                  style: const TextStyle(
                      fontSize: MiuixFontSize.md, height: 1.8, color: MiuixColors.textPrimary)),
            ),
          ),
          if (_typewriterIndex < _resultController.text.length)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, valueColor: AlwaysStoppedAnimation(MiuixColors.primary)),
                  ),
                  const SizedBox(width: 8),
                  const Text('正在输出文字...',
                      style: TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MiuixButton(
                    label: '复制本章',
                    icon: Icons.copy_all,
                    type: MiuixButtonType.secondary,
                    onPressed: _copyResult),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MiuixButton(
                    label: '继续续写',
                    icon: Icons.navigate_next,
                    type: MiuixButtonType.primary,
                    onPressed: _generateContinue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChapterList() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('已生成章节',
              style: TextStyle(
                  fontSize: MiuixFontSize.lg,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          ...List.generate(_chapters.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MiuixRipple(
                borderRadius: MiuixRadius.sm,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: index == _chapters.length - 1
                        ? MiuixColors.surfaceVariant
                        : MiuixColors.surface,
                    borderRadius: MiuixRadius.smRadius,
                    border: Border.all(color: MiuixColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
                          borderRadius: MiuixRadius.smRadius,
                        ),
                        child: Center(
                          child: Text('${index + 1}',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('第${index + 1}章 · ${_styles[_selectedStyle]}',
                            style: const TextStyle(
                                fontSize: MiuixFontSize.md, color: MiuixColors.textPrimary)),
                      ),
                      Text('${_chapters[index].length}字',
                          style: const TextStyle(
                              fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );

  /// 错误状态卡片（请求失败时显示，含重试按钮）
  Widget _buildErrorCard() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: MiuixColors.error, size: 48),
          const SizedBox(height: 12),
          Text('生成失败', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.error)),
          const SizedBox(height: 8),
          Text(_errorMessage, style: TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          MiuixButton(
            label: '重试',
            icon: Icons.refresh,
            type: MiuixButtonType.gradient,
            gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
            onPressed: () => setState(() => _hasError = false),
          ),
        ],
      ),
    );
  }

  }
}
