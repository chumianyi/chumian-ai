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
/// AIParaphrasePage —— AI 改写润色
/// 文本输入，风格选择(正式/口语/学术/简洁/扩写)
/// 改写结果，对比展示，复制
/// ============================================================
class AIParaphrasePage extends StatefulWidget {
  const AIParaphrasePage({super.key});

  @override
  State<AIParaphrasePage> createState() => _AIParaphrasePageState();
}

class _AIParaphrasePageState extends State<AIParaphrasePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _typewriterController;

  final TextEditingController _textController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();

  int _selectedStyle = 0;
  bool _isGenerating = false;
  bool _hasResult = false;
  bool _hasError = false;
  String _errorMessage = \'\';
  String _displayedText = '';
  int _typewriterIndex = 0;

  static const List<String> _styles = ['正式', '口语', '学术', '简洁', '扩写'];
  static const List<IconData> _styleIcons = [Icons.business, Icons.chat_bubble_outline, Icons.school, Icons.compress, Icons.expand];
  static const List<String> _sampleTexts = [
    '这个产品真的超级好用，我用了之后感觉特别棒，强烈推荐给大家！',
    '人工智能技术在近年来取得了飞速发展，已经深入到我们生活的方方面面。',
    '我觉得这个方案不太行，有很多问题需要改，希望大家再想想别的办法。',
    '今天天气真好，我们一起出去玩吧，去公园散步或者去看电影都行。',
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: MiuixDuration.slow);
    _typewriterController = AnimationController(vsync: this, duration: const Duration(milliseconds: 30));
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _typewriterController.dispose();
    _textController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: MiuixCurves.miuixSpring)));
    final slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: Curves.easeOutCubic)));
    return AnimatedBuilder(animation: animation, builder: (_, __) => Opacity(opacity: animation.value, child: Transform.translate(offset: slide.value, child: child)));
  }

  Future<void> _paraphrase() async {
    if (_textController.text.trim().isEmpty) {
      MiuixToast.show(context, message: '请输入要改写的文本', type: MiuixToastType.warning);
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
        systemPrompt: '你是一位专业的文本改写专家。请在保持原意的基础上，用不同的表达方式改写用户提供的文本，使表达更加流畅自然。',
        userInput: _inputController.text,
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
    _typewriterController.removeListener(_tick);
    _typewriterController.addListener(_tick);
    _typewriterController.repeat();
  }

  void _tick() {
    if (_typewriterIndex < _resultController.text.length) {
      setState(() {
        _typewriterIndex += 4;
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
    if (mounted) MiuixToast.show(context, message: '已复制改写结果', type: MiuixToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(title: 'AI 改写润色', backgroundColor: MiuixColors.background),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedItem(_buildStyleSelector(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildTextInput(), 1),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildGenerateButton(), 2),
            const SizedBox(height: 20),
            if (_isGenerating) _buildAnimatedItem(_buildLoadingCard(), 3),
            if (_hasError) _buildAnimatedItem(_buildErrorCard(), 5),

            if (_hasResult) ...[
              _buildAnimatedItem(_buildCompareCard(), 3),
              const SizedBox(height: 16),
              _buildAnimatedItem(_buildResultCard(), 4),
            ],
          ],
        ),
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
          const Text('改写风格', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
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
              const Text('原始文本', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
              Text('${_textController.text.length} 字', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 12),
          MiuixInput(
            controller: _textController,
            hintText: '输入要改写润色的文本...',
            prefixIcon: Icons.edit,
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

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: _isGenerating ? '改写中...' : '开始改写',
        icon: Icons.auto_fix_high,
        type: MiuixButtonType.gradient,
        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
        size: MiuixButtonSize.large,
        loading: _isGenerating,
        onPressed: _isGenerating ? null : _paraphrase,
      ),
    );
  }

  Widget _buildLoadingCard() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const MiuixProgress(type: MiuixProgressType.circularIndeterminate, size: 48, strokeWidth: 4),
        const SizedBox(height: 16),
        const Text('AI 正在改写润色...', style: TextStyle(fontSize: MiuixFontSize.md, color: MiuixColors.textSecondary)),
        const SizedBox(height: 8),
        Text('${_styles[_selectedStyle]}风格改写中', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
      ]),
    );
  }

  Widget _buildCompareCard() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('原文 vs 改写', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: MiuixColors.surfaceVariant, borderRadius: MiuixRadius.pillRadius),
                      child: const Text('原文', style: TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textSecondary, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 8),
                    Text(_textController.text.trim(), style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary, height: 1.6)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward, color: MiuixColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.pillRadius),
                      child: Text('${_styles[_selectedStyle]}版', style: const TextStyle(fontSize: MiuixFontSize.sm, color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 8),
                    Text(_resultController.text.split('━━━━━━')[0].replaceAll('【${_styles[_selectedStyle]}版改写】', '').trim(), style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textPrimary, height: 1.6, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
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
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.smRadius), child: const Icon(Icons.auto_fix_high, color: Colors.white, size: 20)),
              const SizedBox(width: 10),
              const Expanded(child: Text('改写结果', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary))),
              MiuixIconButton(icon: Icons.copy, style: MiuixIconButtonStyle.outlined, size: 36, iconSize: 18, onPressed: _copyResult),
              const SizedBox(width: 8),
              MiuixIconButton(icon: Icons.refresh, style: MiuixIconButtonStyle.outlined, size: 36, iconSize: 18, onPressed: _paraphrase),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: MiuixRadius.mdRadius, border: Border.all(color: MiuixColors.borderLight)),
            child: SingleChildScrollView(
              maxHeight: 400,
              child: Text(_displayedText, style: const TextStyle(fontSize: MiuixFontSize.md, height: 1.8, color: MiuixColors.textPrimary)),
            ),
          ),
          if (_typewriterIndex < _resultController.text.length)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(MiuixColors.primary))),
                const SizedBox(width: 8),
                const Text('正在输出改写结果...', style: TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
              ]),
            ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: MiuixButton(label: '复制改写结果', icon: Icons.copy_all, type: MiuixButtonType.primary, onPressed: _copyResult)),
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
