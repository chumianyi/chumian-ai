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
/// AISocialMediaPage —— AI 社交媒体文案
/// 平台选择(微博/小红书/抖音/朋友圈/推特)，类型(种草/日常/推广/互动)
/// 主题输入，生成文案，话题标签，emoji 建议
/// ============================================================
class AISocialMediaPage extends StatefulWidget {
  const AISocialMediaPage({super.key});

  @override
  State<AISocialMediaPage> createState() => _AISocialMediaPageState();
}

class _AISocialMediaPageState extends State<AISocialMediaPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _typewriterController;

  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();

  int _selectedPlatform = 1;
  int _selectedType = 0;
  bool _isGenerating = false;
  bool _hasResult = false;
  bool _hasError = false;
  String _errorMessage = \'\';
  String _displayedText = '';
  int _typewriterIndex = 0;
  List<String> _hashtags = [];
  List<String> _emojis = [];

  static const List<String> _platforms = ['微博', '小红书', '抖音', '朋友圈', '推特'];
  static const List<IconData> _platformIcons = [
    Icons.campaign,
    Icons.book,
    Icons.music_note,
    Icons.people,
    Icons.flutter_dash,
  ];
  static const List<String> _contentTypes = ['种草', '日常', '推广', '互动'];
  static const List<String> _sampleTopics = [
    '新买的粉色连衣裙，太好看了',
    '周末去了一家超棒的咖啡店',
    '新品口红试色分享',
    '减脂餐打卡第一天',
    '推荐一本最近在读的书',
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: MiuixDuration.slow);
    _typewriterController = AnimationController(vsync: this, duration: const Duration(milliseconds: 35));
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
    final animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: MiuixCurves.miuixSpring)));
    final slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: Curves.easeOutCubic)));
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Opacity(opacity: animation.value, child: Transform.translate(offset: slide.value, child: child)),
    );
  }

  Future<void> _generateContent() async {
    if (_topicController.text.trim().isEmpty) {
      MiuixToast.show(context, message: '请输入文案主题', type: MiuixToastType.warning);
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
        systemPrompt: '你是一位社交媒体运营专家。请根据用户提供的主题和平台，撰写一篇吸引人的社交媒体文案，包含标题、正文和话题标签。',
        userInput: "主题："+_topicController.text+"\n平台："+_platforms[_selectedPlatform],
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
    _startTypewriter(_resultController.text);
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
        if (_typewriterIndex > _resultController.text.length) _typewriterIndex = _resultController.text.length;
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
    if (mounted) MiuixToast.show(context, message: '已复制到剪贴板', type: MiuixToastType.success);
  }

  Future<void> _copyHashtags() async {
    if (_hashtags.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _hashtags.join(' ')));
    if (mounted) MiuixToast.show(context, message: '话题标签已复制', type: MiuixToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(title: 'AI 社交媒体文案', backgroundColor: MiuixColors.background),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedItem(_buildPlatformSelector(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildTypeSelector(), 1),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildTopicInput(), 2),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildGenerateButton(), 3),
            const SizedBox(height: 20),
            if (_isGenerating) _buildAnimatedItem(_buildLoadingCard(), 4),
            if (_hasError) _buildAnimatedItem(_buildErrorCard(), 5),

            if (_hasResult) ...[
              _buildAnimatedItem(_buildResultCard(), 4),
              const SizedBox(height: 16),
              _buildAnimatedItem(_buildHashtagCard(), 5),
              const SizedBox(height: 16),
              _buildAnimatedItem(_buildEmojiCard(), 6),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformSelector() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('选择平台', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_platforms.length, (index) {
              final isSelected = _selectedPlatform == index;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 4 ? 6 : 0),
                  child: MiuixRipple(
                    borderRadius: MiuixRadius.md,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPlatform = index),
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
                            Icon(_platformIcons[index], size: 20, color: isSelected ? Colors.white : MiuixColors.primary),
                            const SizedBox(height: 4),
                            Text(_platforms[index], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : MiuixColors.textSecondary)),
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

  Widget _buildTypeSelector() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('文案类型', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_contentTypes.length, (index) {
              final isSelected = _selectedType == index;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 3 ? 10 : 0),
                  child: MiuixRipple(
                    borderRadius: MiuixRadius.md,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = index),
                      child: AnimatedContainer(
                        duration: MiuixDuration.fast,
                        curve: MiuixCurves.miuixSpring,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: isSelected ? const LinearGradient(colors: MiuixColors.primaryGradient) : null,
                          color: isSelected ? null : MiuixColors.surfaceVariant,
                          borderRadius: MiuixRadius.mdRadius,
                          boxShadow: isSelected ? MiuixShadows.sm : null,
                        ),
                        child: Center(child: Text(_contentTypes[index], style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : MiuixColors.textSecondary))),
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
          const Text('文案主题', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          MiuixInput(
            controller: _topicController,
            hintText: '请输入文案主题或想表达的内容...',
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
                label: _sampleTopics[index].length > 12 ? '${_sampleTopics[index].substring(0, 12)}...' : _sampleTopics[index],
                onTap: () => _topicController.text = _sampleTopics[index],
                style: MiuixChipStyle.normal,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: _isGenerating ? '生成中...' : '生成文案',
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
          const MiuixProgress(type: MiuixProgressType.circularIndeterminate, size: 48, strokeWidth: 4),
          const SizedBox(height: 16),
          const Text('AI 正在撰写文案...', style: TextStyle(fontSize: MiuixFontSize.md, color: MiuixColors.textSecondary)),
          const SizedBox(height: 8),
          Text('${_platforms[_selectedPlatform]} · ${_contentTypes[_selectedType]}文案', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)]),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.smRadius), child: const Icon(Icons.create, color: Colors.white, size: 20)),
              const SizedBox(width: 10),
              const Expanded(child: Text('文案内容', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary))),
              MiuixIconButton(icon: Icons.copy, style: MiuixIconButtonStyle.outlined, size: 36, iconSize: 18, onPressed: _copyResult),
              const SizedBox(width: 8),
              MiuixIconButton(icon: Icons.refresh, style: MiuixIconButtonStyle.outlined, size: 36, iconSize: 18, onPressed: _generateContent),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: MiuixRadius.mdRadius, border: Border.all(color: MiuixColors.borderLight)),
            child: SingleChildScrollView(
              maxHeight: 350,
              child: Text(_displayedText, style: const TextStyle(fontSize: MiuixFontSize.md, height: 1.8, color: MiuixColors.textPrimary)),
            ),
          ),
          if (_typewriterIndex < _resultController.text.length)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(MiuixColors.primary))),
                  const SizedBox(width: 8),
                  const Text('正在输出文字...', style: TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHashtagCard() {
    if (_hashtags.isEmpty) return const SizedBox.shrink();
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tag, size: 20, color: MiuixColors.primary),
              const SizedBox(width: 8),
              const Expanded(child: Text('话题标签', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary))),
              MiuixIconButton(icon: Icons.copy, style: MiuixIconButtonStyle.outlined, size: 32, iconSize: 16, onPressed: _copyHashtags),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_hashtags.length, (index) {
              return MiuixChip(label: _hashtags[index], style: MiuixChipStyle.normal, isSelected: true);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiCard() {
    if (_emojis.isEmpty) return const SizedBox.shrink();
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_emotions, size: 20, color: MiuixColors.primary),
              const SizedBox(width: 8),
              const Expanded(child: Text('Emoji 建议', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary))),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: List.generate(_emojis.length, (index) {
              return MiuixRipple(
                borderRadius: MiuixRadius.sm,
                child: GestureDetector(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: _emojis[index]));
                    if (mounted) MiuixToast.show(context, message: '已复制 ${_emojis[index]}', type: MiuixToastType.success);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: MiuixColors.surfaceVariant, borderRadius: MiuixRadius.mdRadius, border: Border.all(color: MiuixColors.borderLight)),
                    child: Center(child: Text(_emojis[index], style: const TextStyle(fontSize: 28))),
                  ),
                ),
              );
            }),
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
