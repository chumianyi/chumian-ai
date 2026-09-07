import 'package:flutter/material.dart';
import 'package:chumian_ai/services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_chip.dart';
import 'package:chumian_ai/widgets/miuix/miuix_input.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_segment.dart';
import 'package:chumian_ai/widgets/miuix/miuix_progress.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/utils/clipboard_utils.dart';

/// ============================================================
/// AIWritingPage —— AI 写作工具
/// 文章类型选择(作文/论文/小说/文案)，参数设置(字数/风格/语气)
/// 输入主题，生成结果展示，粉色卡片，打字机动画，复制/重新生成
/// ============================================================
class AIWritingPage extends StatefulWidget {
  const AIWritingPage({super.key});

  @override
  State<AIWritingPage> createState() => _AIWritingPageState();
}

class _AIWritingPageState extends State<AIWritingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _typewriterController;

  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();

  int _selectedType = 0;
  int _selectedStyle = 0;
  int _selectedTone = 0;
  double _wordCount = 800;
  bool _isGenerating = false;
  bool _hasResult = false;
  bool _hasError = false;
  String _errorMessage = \'\';
  String _displayedText = '';
  int _typewriterIndex = 0;

  static const List<String> _articleTypes = ['作文', '论文', '小说', '文案'];
  static const List<IconData> _typeIcons = [
    Icons.edit_note,
    Icons.menu_book,
    Icons.auto_stories,
    Icons.campaign,
  ];
  static const List<String> _styles = ['正式', '活泼', '文艺', '幽默', '犀利'];
  static const List<String> _tones = ['客观', '感性', '理性', '热情', '冷静'];

  static const List<String> _sampleTopics = [
    '人工智能对未来教育的影响',
    '春天的校园',
    '一次难忘的旅行经历',
    '环保与可持续发展',
    '科技改变生活',
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _typewriterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _typewriterController.dispose();
    _topicController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(
          index * 0.08,
          (index * 0.08) + 0.4,
          curve: MiuixCurves.miuixSpring,
        ),
      ),
    );
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(
          index * 0.08,
          (index * 0.08) + 0.4,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: slideAnimation.value,
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _generateContent() async {
    if (_topicController.text.trim().isEmpty) {
      MiuixToast.show(
        context,
        message: '请先输入写作主题',
        type: MiuixToastType.warning,
      );
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
        systemPrompt: '你是一位专业的写作助手。请根据用户提供的主题、文体、风格和字数要求，撰写一篇高质量的文章。',
        userInput: "主题："+_topicController.text+"\n类型："+_articleTypes[_selectedType]+"\n风格："+_styles[_selectedStyle]+"\n语气："+_tones[_selectedTone]+"\n字数：约"+_wordCount.toInt()+"字,
      );
      if (mounted) {
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
    _typewriterController.removeListener(_typewriterTick);
    _typewriterController.addListener(_typewriterTick);
    _typewriterController.repeat();
  }

  void _typewriterTick() {
    if (_typewriterIndex < _resultController.text.length) {
      setState(() {
        _typewriterIndex += 2;
        if (_typewriterIndex > _resultController.text.length) {
          _typewriterIndex = _resultController.text.length;
        }
        _displayedText = _resultController.text.substring(0, _typewriterIndex);
      });
    } else {
      _typewriterController.stop();
      _typewriterController.removeListener(_typewriterTick);
    }
  }

  Future<void> _copyResult() async {
    if (_resultController.text.isEmpty) return;
    await ClipboardUtils.copy(_resultController.text);
    if (mounted) {
      MiuixToast.show(
        context,
        message: '已复制到剪贴板',
        type: MiuixToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: 'AI 写作',
        backgroundColor: MiuixColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedItem(_buildTypeSelector(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildTopicInput(), 1),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildStyleToneRow(), 2),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildWordCountSlider(), 3),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildGenerateButton(), 4),
            const SizedBox(height: 20),
            if (_isGenerating) _buildAnimatedItem(_buildLoadingCard(), 5),
            if (_hasError) _buildAnimatedItem(_buildErrorCard(), 5),

            if (_hasResult) _buildAnimatedItem(_buildResultCard(), 5),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '文章类型',
            style: TextStyle(
              fontSize: MiuixFontSize.lg,
              fontWeight: FontWeight.w600,
              color: MiuixColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_articleTypes.length, (index) {
              final isSelected = _selectedType == index;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 3 ? 8 : 0),
                  child: MiuixRipple(
                    borderRadius: MiuixRadius.md,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = index),
                      child: AnimatedContainer(
                        duration: MiuixDuration.fast,
                        curve: MiuixCurves.miuixSpring,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(colors: MiuixColors.primaryGradient)
                              : null,
                          color: isSelected ? null : MiuixColors.surfaceVariant,
                          borderRadius: MiuixRadius.mdRadius,
                          boxShadow: isSelected ? MiuixShadows.sm : null,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _typeIcons[index],
                              size: 24,
                              color: isSelected
                                  ? Colors.white
                                  : MiuixColors.primary,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _articleTypes[index],
                              style: TextStyle(
                                fontSize: MiuixFontSize.sm,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : MiuixColors.textSecondary,
                              ),
                            ),
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

  Widget _buildTopicInput() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '写作主题',
            style: TextStyle(
              fontSize: MiuixFontSize.lg,
              fontWeight: FontWeight.w600,
              color: MiuixColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          MiuixInput(
            controller: _topicController,
            hintText: '请输入文章主题或关键词...',
            prefixIcon: Icons.edit_outlined,
            maxLines: 3,
            minLines: 2,
            type: MiuixInputType.multiline,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_sampleTopics.length, (index) {
              return MiuixChip(
                label: _sampleTopics[index],
                onTap: () {
                  _topicController.text = _sampleTopics[index];
                },
                style: MiuixChipStyle.normal,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleToneRow() {
    return Row(
      children: [
        Expanded(
          child: MiuixCard(
            style: MiuixCardStyle.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '风格',
                  style: TextStyle(
                    fontSize: MiuixFontSize.md,
                    fontWeight: FontWeight.w600,
                    color: MiuixColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(_styles.length, (index) {
                    return MiuixChip(
                      label: _styles[index],
                      isSelected: _selectedStyle == index,
                      onTap: () => setState(() => _selectedStyle = index),
                      height: 30,
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MiuixCard(
            style: MiuixCardStyle.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '语气',
                  style: TextStyle(
                    fontSize: MiuixFontSize.md,
                    fontWeight: FontWeight.w600,
                    color: MiuixColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(_tones.length, (index) {
                    return MiuixChip(
                      label: _tones[index],
                      isSelected: _selectedTone == index,
                      onTap: () => setState(() => _selectedTone = index),
                      height: 30,
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
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
              const Text(
                '目标字数',
                style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
                  borderRadius: MiuixRadius.pillRadius,
                ),
                child: Text(
                  '${_wordCount.toInt()} 字',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: MiuixFontSize.sm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: MiuixColors.primary,
              inactiveTrackColor: MiuixColors.surfaceVariant,
              thumbColor: Colors.white,
              overlayColor: MiuixColors.primaryLight.withValues(alpha: 0.3),
              valueIndicatorColor: MiuixColors.primary,
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: _wordCount,
              min: 300,
              max: 3000,
              divisions: 27,
              label: '${_wordCount.toInt()}字',
              onChanged: (val) => setState(() => _wordCount = val),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('300', style: TextStyle(color: MiuixColors.textTertiary, fontSize: 11)),
              Text('1500', style: TextStyle(color: MiuixColors.textTertiary, fontSize: 11)),
              Text('3000', style: TextStyle(color: MiuixColors.textTertiary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: _isGenerating ? '生成中...' : '开始写作',
        icon: Icons.auto_awesome,
        type: MiuixButtonType.gradient,
        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
        size: MiuixButtonSize.large,
        loading: _isGenerating,
        onPressed: _isGenerating ? null : _generateContent,
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
            type: MiuixProgressType.circularIndeterminate,
            size: 48,
            strokeWidth: 4,
          ),
          const SizedBox(height: 16),
          const Text(
            'AI 正在构思中...',
            style: TextStyle(
              fontSize: MiuixFontSize.md,
              color: MiuixColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '正在生成${_articleTypes[_selectedType]}，请稍候',
            style: const TextStyle(
              fontSize: MiuixFontSize.sm,
              color: MiuixColors.textTertiary,
            ),
          ),
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
        colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)],
      ),
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
                child: const Icon(Icons.article, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '生成结果',
                  style: TextStyle(
                    fontSize: MiuixFontSize.lg,
                    fontWeight: FontWeight.w600,
                    color: MiuixColors.textPrimary,
                  ),
                ),
              ),
              MiuixIconButton(
                icon: Icons.copy,
                style: MiuixIconButtonStyle.outlined,
                size: 36,
                iconSize: 18,
                onPressed: _copyResult,
              ),
              const SizedBox(width: 8),
              MiuixIconButton(
                icon: Icons.refresh,
                style: MiuixIconButtonStyle.outlined,
                size: 36,
                iconSize: 18,
                onPressed: _generateContent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: MiuixRadius.mdRadius,
              border: Border.all(color: MiuixColors.borderLight),
            ),
            child: SingleChildScrollView(
              maxHeight: 400,
              child: Text(
                _displayedText,
                style: const TextStyle(
                  fontSize: MiuixFontSize.md,
                  height: 1.8,
                  color: MiuixColors.textPrimary,
                ),
              ),
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
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(MiuixColors.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '正在输出文字...',
                    style: TextStyle(
                      fontSize: MiuixFontSize.sm,
                      color: MiuixColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MiuixButton(
                  label: '复制全文',
                  icon: Icons.copy_all,
                  type: MiuixButtonType.secondary,
                  onPressed: _copyResult,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MiuixButton(
                  label: '重新生成',
                  icon: Icons.refresh,
                  type: MiuixButtonType.primary,
                  onPressed: _generateContent,
                ),
              ),
            ],
          ),
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
