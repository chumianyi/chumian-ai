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
/// AIGrammarPage —— AI 语法检查
/// 文本输入，语言选择(中文/英文)，错误标注，修改建议
/// 语法解释，复制修改后文本
/// ============================================================
class AIGrammarPage extends StatefulWidget {
  const AIGrammarPage({super.key});

  @override
  State<AIGrammarPage> createState() => _AIGrammarPageState();
}

class _AIGrammarPageState extends State<AIGrammarPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  final TextEditingController _textController = TextEditingController();
  final TextEditingController _correctedController = TextEditingController();

  int _selectedLang = 0;
  bool _isChecking = false;
  bool _hasResult = false;
  bool _hasError = false;
  String _errorMessage = '';
  List<Map<String, String>> _errors = [];

  static const List<String> _languages = ['中文', 'English'];
  static const List<String> _sampleTexts = [
    '通过这次学习，使我明白了很多道理。我们要努力学习，提高自己的素质和能力。',
    'He dont like apples, but he like oranges very much. Me and him is good friends.',
    '关于这个问题，我们需要进一步的讨论和研究。通过大家的共同努力，一定能够取得成功。',
    'The book which I bought it yesterday is very interesting. It have many good storys.',
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: MiuixDuration.slow);
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _textController.dispose();
    _correctedController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: MiuixCurves.miuixSpring)));
    final slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: Curves.easeOutCubic)));
    return AnimatedBuilder(animation: animation, builder: (_, __) => Opacity(opacity: animation.value, child: Transform.translate(offset: slide.value, child: child)));
  }

  Future<void> _checkGrammar() async {
    if (_textController.text.trim().isEmpty) {
      MiuixToast.show(context, message: '请输入要检查的文本', type: MiuixToastType.warning);
      return;
    }
    setState(() {
      _isChecking = true;
      _hasResult = false;
      _hasError = false;
      _errorMessage = '';
      _errors = [];
    });

    try {
      final lang = _languages[_selectedLang];
      final result = await ApiService.aiToolComplete(
        systemPrompt: '你是一位专业的$lang语法检查专家。请检查以下文本的语法错误，输出格式为：第一行输出修正后的完整文本，然后逐行列出每个错误（格式：错误类型|原文|修正|解释）。如果没有错误，只输出"未发现语法错误"。',
        userInput: _textController.text.trim(),
      );
      if (mounted) {
        final lines = result.split('\n');
        _correctedController.text = lines.isNotEmpty ? lines.first : result;
        // 解析错误列表
        _errors = [];
        for (final line in lines.skip(1)) {
          final parts = line.split('|');
          if (parts.length >= 4) {
            _errors.add({
              'type': parts[0].trim(),
              'original': parts[1].trim(),
              'corrected': parts[2].trim(),
              'explanation': parts[3].trim(),
            });
          }
        }
        setState(() {
          _isChecking = false;
          _hasResult = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _copyCorrected() async {
    if (_correctedController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _correctedController.text));
    if (mounted) MiuixToast.show(context, message: '已复制修正后文本', type: MiuixToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(title: 'AI 语法检查', backgroundColor: MiuixColors.background),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedItem(_buildLangSelector(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildTextInput(), 1),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildCheckButton(), 2),
            const SizedBox(height: 20),
            if (_isChecking) _buildAnimatedItem(_buildLoadingCard(), 3),
            if (_hasResult) ...[
              _buildAnimatedItem(_buildCorrectedCard(), 3),
              const SizedBox(height: 16),
              _buildAnimatedItem(_buildErrorsList(), 4),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLangSelector() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('选择语言', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_languages.length, (index) {
              final isSelected = _selectedLang == index;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 1 ? 12 : 0),
                  child: MiuixRipple(
                    borderRadius: MiuixRadius.md,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedLang = index),
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
                        child: Center(child: Text(_languages[index], style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : MiuixColors.textSecondary))),
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
              const Text('待检查文本', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
              Text('${_textController.text.length} 字', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 12),
          MiuixInput(
            controller: _textController,
            hintText: _selectedLang == 0 ? '输入要检查的中文文本...' : 'Enter English text to check...',
            prefixIcon: Icons.edit,
            maxLines: 6,
            minLines: 4,
            type: MiuixInputType.multiline,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_sampleTexts.length, (index) {
              final sample = _sampleTexts[index];
              final isEn = index % 2 == 1;
              if ((_selectedLang == 0 && isEn) || (_selectedLang == 1 && !isEn)) return const SizedBox.shrink();
              return MiuixChip(
                label: sample.length > 18 ? '${sample.substring(0, 18)}...' : sample,
                onTap: () => _textController.text = sample,
                style: MiuixChipStyle.normal,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: _isChecking ? '检查中...' : '开始语法检查',
        icon: Icons.spellcheck,
        type: MiuixButtonType.gradient,
        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
        size: MiuixButtonSize.large,
        loading: _isChecking,
        onPressed: _isChecking ? null : _checkGrammar,
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
        const Text('AI 正在检查语法...', style: TextStyle(fontSize: MiuixFontSize.md, color: MiuixColors.textSecondary)),
        const SizedBox(height: 8),
        Text('${_languages[_selectedLang]}语法分析中', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
      ]),
    );
  }

  Widget _buildCorrectedCard() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)]),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.smRadius), child: const Icon(Icons.check_circle, color: Colors.white, size: 20)),
              const SizedBox(width: 10),
              Expanded(child: Text('检查完成 · 发现 ${_errors.length} 处问题', style: const TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary))),
              MiuixIconButton(icon: Icons.copy, style: MiuixIconButtonStyle.outlined, size: 36, iconSize: 18, onPressed: _copyCorrected),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: MiuixRadius.mdRadius, border: Border.all(color: MiuixColors.borderLight)),
            child: SingleChildScrollView(
              maxHeight: 300,
              child: Text(_correctedController.text, style: const TextStyle(fontSize: MiuixFontSize.md, height: 1.8, color: MiuixColors.textPrimary)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: MiuixButton(label: '复制修正后文本', icon: Icons.copy_all, type: MiuixButtonType.primary, onPressed: _copyCorrected)),
        ],
      ),
    );
  }

  Widget _buildErrorsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.only(left: 4, bottom: 12), child: Text('错误详情', style: TextStyle(fontSize: MiuixFontSize.xl, fontWeight: FontWeight.w700, color: MiuixColors.textPrimary))),
        ...List.generate(_errors.length, (index) {
          final error = _errors[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MiuixCard(
              style: MiuixCardStyle.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(color: MiuixColors.error.withValues(alpha: 0.1), borderRadius: MiuixRadius.smRadius),
                        child: Center(child: Text('${index + 1}', style: const TextStyle(color: MiuixColors.error, fontWeight: FontWeight.w700))),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: MiuixColors.error.withValues(alpha: 0.1), borderRadius: MiuixRadius.pillRadius),
                        child: Text(error['type']!, style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.error, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.close, size: 18, color: MiuixColors.error),
                      const SizedBox(width: 6),
                      const Text('原文：', style: TextStyle(fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w600, color: MiuixColors.textSecondary)),
                      Expanded(child: Text(error['original']!, style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.error, decoration: TextDecoration.lineThrough))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check, size: 18, color: MiuixColors.success),
                      const SizedBox(width: 6),
                      const Text('修正：', style: TextStyle(fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w600, color: MiuixColors.textSecondary)),
                      Expanded(child: Text(error['corrected']!, style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.success, fontWeight: FontWeight.w600))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: MiuixColors.surfaceVariant, borderRadius: MiuixRadius.smRadius),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 16, color: MiuixColors.primary),
                        const SizedBox(width: 6),
                        Expanded(child: Text(error['explanation']!, style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textSecondary, height: 1.5))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
