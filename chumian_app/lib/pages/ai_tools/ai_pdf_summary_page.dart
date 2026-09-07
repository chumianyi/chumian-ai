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
/// AIPdfSummaryPage —— AI PDF 总结
/// 文件选择(模拟)，总结长度，生成摘要，关键要点
/// 问答功能，导出
/// ============================================================
class AIPdfSummaryPage extends StatefulWidget {
  const AIPdfSummaryPage({super.key});

  @override
  State<AIPdfSummaryPage> createState() => _AIPdfSummaryPageState();
}

class _AIPdfSummaryPageState extends State<AIPdfSummaryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _typewriterController;

  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();

  int _summaryLength = 1; // 0=简短, 1=中等, 2=详细
  bool _isSummarizing = false;
  bool _hasSummary = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _displayedSummary = '';
  int _typewriterIndex = 0;
  String _selectedFile = '';
  bool _isAnswering = false;
  String _answer = '';

  static const List<String> _lengths = ['简短', '中等', '详细'];
  static const List<String> _sampleFiles = [
    '产品需求文档.pdf (2.3MB)',
    '年度财务报告.pdf (5.1MB)',
    '技术方案设计.pdf (3.8MB)',
    '市场调研报告.pdf (4.2MB)',
    '学术论文.pdf (1.5MB)',
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
    _questionController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: MiuixCurves.miuixSpring)));
    final slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: Curves.easeOutCubic)));
    return AnimatedBuilder(animation: animation, builder: (_, __) => Opacity(opacity: animation.value, child: Transform.translate(offset: slide.value, child: child)));
  }

  Future<void> _summarize(String file) async {
    setState(() {
      _isSummarizing = true;
      _hasSummary = false;
      _hasError = false;
      _errorMessage = '';
      _selectedFile = file;
      _displayedSummary = '';
      _typewriterIndex = 0;
      _answer = '';
    });

    try {
      final length = _lengths[_summaryLength];
      final result = await ApiService.aiToolComplete(
        systemPrompt: '你是一位专业的文档总结专家。请对以下文档生成一份$length的摘要，包含核心观点、关键要点和结论建议。',
        userInput: '文档名称：$file\n请生成$length摘要',
      );
      if (mounted) {
        _summaryController.text = result;
        setState(() {
          _isSummarizing = false;
          _hasSummary = true;
        });
        _startTypewriter(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSummarizing = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _startTypewriter(String text) {
    _typewriterIndex = 0;
    _typewriterController.removeListener(_tick);
    _typewriterController.addListener(_tick);
    _typewriterController.repeat();
  }

  void _tick() {
    if (_typewriterIndex < _summaryController.text.length) {
      setState(() {
        _typewriterIndex += 4;
        if (_typewriterIndex > _summaryController.text.length) _typewriterIndex = _summaryController.text.length;
        _displayedSummary = _summaryController.text.substring(0, _typewriterIndex);
      });
    } else {
      _typewriterController.stop();
      _typewriterController.removeListener(_tick);
    }
  }


  Future<void> _askQuestion() async {
    if (_questionController.text.trim().isEmpty) {
      MiuixToast.show(context, message: '请输入问题', type: MiuixToastType.warning);
      return;
    }
    setState(() => _isAnswering = true);
    try {
      final result = await ApiService.aiToolComplete(
        systemPrompt: '你是一位文档问答专家。请根据文档摘要内容，回答用户提出的问题。如果摘要中没有相关信息，请如实说明。',
        userInput: '文档摘要：
' + _summaryController.text + '

用户问题：' + _questionController.text,
      );
      if (mounted) {
        _answer = result;
        setState(() => _isAnswering = false);
      }
    } catch (e) {
      if (mounted) {
        _answer = '回答失败：' + e.toString();
        setState(() => _isAnswering = false);
      }
    }
  }

  Future<void> _copySummary() async {
    if (_summaryController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _summaryController.text));
    if (mounted) MiuixToast.show(context, message: '已复制摘要', type: MiuixToastType.success);
  }

  Future<void> _exportSummary() async {
    final text = '文档摘要\n来源：$_selectedFile\n生成时间：2024年\n\n${_summaryController.text}';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) MiuixToast.show(context, message: '摘要已导出(已复制)', type: MiuixToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(title: 'AI PDF 总结', backgroundColor: MiuixColors.background),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedItem(_buildFilePicker(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildLengthSelector(), 1),
            const SizedBox(height: 20),
            if (_isSummarizing) _buildAnimatedItem(_buildSummarizingCard(), 2),
            if (_hasSummary) ...[
              _buildAnimatedItem(_buildSummaryCard(), 2),
              const SizedBox(height: 16),
              _buildAnimatedItem(_buildActionButtons(), 3),
              const SizedBox(height: 16),
              _buildAnimatedItem(_buildQASection(), 4),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilePicker() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('选择 PDF 文件', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('点击下方文件选择并进行AI总结', style: TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
          const SizedBox(height: 12),
          ...List.generate(_sampleFiles.length, (index) {
            final file = _sampleFiles[index];
            final isSelected = _selectedFile == file;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MiuixRipple(
                borderRadius: MiuixRadius.sm,
                child: GestureDetector(
                  onTap: () => _summarize(file),
                  child: AnimatedContainer(
                    duration: MiuixDuration.fast,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? MiuixColors.primaryLight.withValues(alpha: 0.1) : MiuixColors.surfaceVariant,
                      borderRadius: MiuixRadius.smRadius,
                      border: Border.all(color: isSelected ? MiuixColors.primary : MiuixColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: MiuixColors.primary.withValues(alpha: 0.1), borderRadius: MiuixRadius.smRadius),
                          child: const Icon(Icons.picture_as_pdf, color: MiuixColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(file.split(' ')[0], style: const TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w500, color: MiuixColors.textPrimary)),
                              Text(file.split(' ')[1], style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
                            ],
                          ),
                        ),
                        if (isSelected) const Icon(Icons.check_circle, color: MiuixColors.primary, size: 20),
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

  Widget _buildLengthSelector() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('总结长度', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_lengths.length, (index) {
              final isSelected = _summaryLength == index;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 2 ? 10 : 0),
                  child: MiuixRipple(
                    borderRadius: MiuixRadius.md,
                    child: GestureDetector(
                      onTap: () => setState(() => _summaryLength = index),
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
                        child: Center(child: Text(_lengths[index], style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : MiuixColors.textSecondary))),
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

  Widget _buildSummarizingCard() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const MiuixProgress(type: MiuixProgressType.circularIndeterminate, size: 48, strokeWidth: 4),
        const SizedBox(height: 16),
        const Text('AI 正在阅读文档...', style: TextStyle(fontSize: MiuixFontSize.md, color: MiuixColors.textSecondary)),
        const SizedBox(height: 8),
        Text('${_lengths[_summaryLength]}版摘要生成中，请稍候', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
      ]),
    );
  }

  Widget _buildSummaryCard() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)]),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.smRadius), child: const Icon(Icons.summary, color: Colors.white, size: 20)),
              const SizedBox(width: 10),
              Expanded(child: Text('AI 摘要 · ${_lengths[_summaryLength]}版', style: const TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary))),
              MiuixIconButton(icon: Icons.copy, style: MiuixIconButtonStyle.outlined, size: 36, iconSize: 18, onPressed: _copySummary),
            ],
          ),
          const SizedBox(height: 8),
          Text('来源：$_selectedFile', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: MiuixRadius.mdRadius, border: Border.all(color: MiuixColors.borderLight)),
            child: SingleChildScrollView(
              maxHeight: 500,
              child: Text(_displayedSummary, style: const TextStyle(fontSize: MiuixFontSize.md, height: 1.8, color: MiuixColors.textPrimary)),
            ),
          ),
          if (_typewriterIndex < _summaryController.text.length)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(MiuixColors.primary))),
                const SizedBox(width: 8),
                const Text('正在生成摘要...', style: TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(child: MiuixButton(label: '复制摘要', icon: Icons.copy, type: MiuixButtonType.secondary, onPressed: _copySummary)),
        const SizedBox(width: 12),
        Expanded(child: MiuixButton(label: '导出摘要', icon: Icons.file_download, type: MiuixButtonType.primary, onPressed: _exportSummary)),
      ],
    );
  }

  Widget _buildQASection() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: MiuixColors.primary.withValues(alpha: 0.1), borderRadius: MiuixRadius.smRadius), child: const Icon(Icons.question_answer, color: MiuixColors.primary, size: 18)),
              const SizedBox(width: 8),
              const Text('文档问答', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          MiuixInput(
            controller: _questionController,
            hintText: '针对文档内容提问，如：项目预算是多少？',
            prefixIcon: Icons.help_outline,
            maxLines: 2,
            minLines: 1,
            type: MiuixInputType.multiline,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: MiuixButton(
              label: _isAnswering ? '回答中...' : '提问',
              icon: Icons.send,
              type: MiuixButtonType.primary,
              loading: _isAnswering,
              onPressed: _isAnswering ? null : _askQuestion,
            ),
          ),
          if (_answer.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: MiuixColors.surfaceVariant, borderRadius: MiuixRadius.smRadius),
              child: SingleChildScrollView(
                maxHeight: 300,
                child: Text(_answer, style: const TextStyle(fontSize: MiuixFontSize.sm, height: 1.7, color: MiuixColors.textPrimary)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
