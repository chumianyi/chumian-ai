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
/// AIInterviewPage —— AI 面试模拟
/// 职位选择，问题类型(技术/行为/压力)，模拟问答，回答评估
/// 改进建议，常见问题库
/// ============================================================
class AIInterviewPage extends StatefulWidget {
  const AIInterviewPage({super.key});

  @override
  State<AIInterviewPage> createState() => _AIInterviewPageState();
}

class _AIInterviewPageState extends State<AIInterviewPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  int _selectedType = 1;
  bool _isGenerating = false;
  bool _hasQuestion = false;
  bool _hasEvaluation = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _currentQuestion = '';
  String _evaluation = '';
  int _questionIndex = 0;
  int _score = 0;

  static const List<String> _questionTypes = ['技术', '行为', '压力'];
  static const List<IconData> _typeIcons = [Icons.code, Icons.people, Icons.local_fire_department];
  static const List<String> _samplePositions = ['前端开发工程师', '产品经理', 'Java后端工程师', 'UI设计师', '数据分析师'];

  static const Map<String, List<String>> _questionBank = {
    '技术': [
      '请介绍一下你最熟悉的技术栈，以及你在项目中是如何选型的？',
      '遇到过最难的技术问题是什么？你是如何定位和解决的？',
      '请解释一下你对系统设计的理解，如何保证高可用和高性能？',
      '在代码质量方面，你有哪些实践和原则？',
      '请描述一次你主导的技术重构经历，为什么要重构，结果如何？',
    ],
    '行为': [
      '请分享一次你与团队成员产生分歧的经历，你是如何处理的？',
      '描述一个你主动承担额外责任的例子，结果如何？',
      '在压力最大的一个项目中，你是如何管理时间和情绪的？',
      '请分享一次你从失败中学习的经历，你学到了什么？',
      '描述一个你影响他人改变想法的案例，你是怎么做的？',
    ],
    '压力': [
      '如果我们告诉你，你今天的表现不如其他候选人，你会怎么回应？',
      '你的简历中有一段空白期，能解释一下吗？',
      '如果你的直属领导是一个很难相处的人，你会怎么办？',
      '我们这个岗位需要经常加班，你能接受吗？为什么？',
      '如果入职后发现工作内容和面试时说的完全不一样，你会怎么做？',
    ],
  };

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: MiuixDuration.slow);
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _positionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: MiuixCurves.miuixSpring)));
    final slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: Curves.easeOutCubic)));
    return AnimatedBuilder(animation: animation, builder: (_, __) => Opacity(opacity: animation.value, child: Transform.translate(offset: slide.value, child: child)));
  }

  Future<void> _nextQuestion() async {
    if (_positionController.text.trim().isEmpty) {
      MiuixToast.show(context, message: '请先输入目标职位', type: MiuixToastType.warning);
      return;
    }
    setState(() {
      _isGenerating = true;
      _hasQuestion = false;
      _hasEvaluation = false;
      _answerController.clear();
    });
    await Future.delayed(const Duration(milliseconds: 1000));
    final questions = _questionBank[_questionTypes[_selectedType]] ?? _questionBank['行为']!;
    _questionIndex = (_questionIndex + 1) % questions.length;
    _currentQuestion = questions[_questionIndex];
    setState(() {
      _isGenerating = false;
      _hasQuestion = true;
    });
  }

  Future<void> _submitAnswer() async {
    if (_answerController.text.trim().isEmpty) {
      MiuixToast.show(context, message: '请先输入你的回答', type: MiuixToastType.warning);
      return;
    }
    if (_answerController.text.trim().length < 20) {
      MiuixToast.show(context, message: '回答太短了，至少20个字', type: MiuixToastType.warning);
      return;
    }
    setState(() {
      _isGenerating = true;
      _hasEvaluation = false;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final position = _positionController.text.trim();
      final qType = _questionTypes[_selectedType];
      final evaluation = await ApiService.aiToolComplete(
        systemPrompt: '你是一位资深的$position面试官。请针对以下$qType类面试问题和候选人的回答，给出专业的评估报告，包含：综合评分(0-100)、亮点、待提升、改进建议。格式清晰，用中文回答。',
        userInput: '面试问题：$_currentQuestion\n\n候选人回答：${_answerController.text.trim()}',
      );
      if (mounted) {
        setState(() {
          _evaluation = evaluation;
          _isGenerating = false;
          _hasEvaluation = true;
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
  }

  Future<void> _copyEvaluation() async {
    if (_evaluation.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _evaluation));
    if (mounted) MiuixToast.show(context, message: '已复制评估报告', type: MiuixToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(title: 'AI 面试模拟', backgroundColor: MiuixColors.background),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedItem(_buildPositionInput(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildTypeSelector(), 1),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildStartButton(), 2),
            const SizedBox(height: 20),
            if (_isGenerating && !_hasQuestion) _buildAnimatedItem(_buildThinkingCard(), 3),
            if (_hasQuestion) ...[
              _buildAnimatedItem(_buildQuestionCard(), 3),
              const SizedBox(height: 16),
              _buildAnimatedItem(_buildAnswerInput(), 4),
              const SizedBox(height: 16),
              _buildAnimatedItem(_buildSubmitButton(), 5),
              const SizedBox(height: 20),
              if (_isGenerating && _hasQuestion) _buildAnimatedItem(_buildEvaluatingCard(), 6),
              if (_hasEvaluation) _buildAnimatedItem(_buildEvaluationCard(), 6),
            ],
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildQuestionBank(), 7),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionInput() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('目标职位', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          MiuixInput(controller: _positionController, hintText: '如：前端开发工程师、产品经理...', prefixIcon: Icons.work),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_samplePositions.length, (index) {
              return MiuixChip(label: _samplePositions[index], onTap: () => _positionController.text = _samplePositions[index], style: MiuixChipStyle.normal);
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
          const Text('问题类型', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_questionTypes.length, (index) {
              final isSelected = _selectedType == index;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 2 ? 10 : 0),
                  child: MiuixRipple(
                    borderRadius: MiuixRadius.md,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = index),
                      child: AnimatedContainer(
                        duration: MiuixDuration.fast,
                        curve: MiuixCurves.miuixSpring,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: isSelected ? const LinearGradient(colors: MiuixColors.primaryGradient) : null,
                          color: isSelected ? null : MiuixColors.surfaceVariant,
                          borderRadius: MiuixRadius.mdRadius,
                          boxShadow: isSelected ? MiuixShadows.sm : null,
                        ),
                        child: Column(
                          children: [
                            Icon(_typeIcons[index], size: 24, color: isSelected ? Colors.white : MiuixColors.primary),
                            const SizedBox(height: 6),
                            Text(_questionTypes[index], style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : MiuixColors.textSecondary)),
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

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: _hasQuestion ? '下一题' : '开始模拟面试',
        icon: Icons.play_arrow,
        type: MiuixButtonType.gradient,
        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
        size: MiuixButtonSize.large,
        onPressed: _nextQuestion,
      ),
    );
  }

  Widget _buildThinkingCard() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const MiuixProgress(type: MiuixProgressType.circularIndeterminate, size: 48, strokeWidth: 4),
        const SizedBox(height: 16),
        const Text('AI 面试官正在思考问题...', style: TextStyle(fontSize: MiuixFontSize.md, color: MiuixColors.textSecondary)),
      ]),
    );
  }

  Widget _buildQuestionCard() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)]),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.smRadius), child: const Icon(Icons.help_outline, color: Colors.white, size: 20)),
              const SizedBox(width: 10),
              Text('第 ${_questionIndex + 1} 题 · ${_questionTypes[_selectedType]}题', style: const TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.primary)),
            ],
          ),
          const SizedBox(height: 14),
          Text(_currentQuestion, style: const TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary, height: 1.6)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: MiuixRadius.smRadius),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, size: 16, color: MiuixColors.primary),
                const SizedBox(width: 6),
                const Expanded(child: Text('建议使用STAR法则回答，控制在2-3分钟', style: TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textSecondary))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerInput() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('你的回答', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
              Text('${_answerController.text.length} 字', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 12),
          MiuixInput(
            controller: _answerController,
            hintText: '在这里输入你的回答...\n\n建议结构：\n1. 开头亮明观点\n2. 分点展开（结合具体案例）\n3. 总结升华',
            prefixIcon: Icons.edit,
            maxLines: 8,
            minLines: 6,
            type: MiuixInputType.multiline,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: _isGenerating ? '评估中...' : '提交回答，获取评估',
        icon: Icons.assessment,
        type: MiuixButtonType.primary,
        size: MiuixButtonSize.large,
        loading: _isGenerating,
        onPressed: _isGenerating ? null : _submitAnswer,
      ),
    );
  }

  Widget _buildEvaluatingCard() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const MiuixProgress(type: MiuixProgressType.circularIndeterminate, size: 48, strokeWidth: 4),
        const SizedBox(height: 16),
        const Text('AI 面试官正在评估你的回答...', style: TextStyle(fontSize: MiuixFontSize.md, color: MiuixColors.textSecondary)),
      ]),
    );
  }

  Widget _buildEvaluationCard() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)]),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.smRadius), child: const Icon(Icons.assessment, color: Colors.white, size: 20)),
              const SizedBox(width: 10),
              const Expanded(child: Text('评估报告', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.pillRadius),
                child: Text('$_score分', style: const TextStyle(color: Colors.white, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              MiuixIconButton(icon: Icons.copy, style: MiuixIconButtonStyle.outlined, size: 36, iconSize: 18, onPressed: _copyEvaluation),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: MiuixRadius.mdRadius, border: Border.all(color: MiuixColors.borderLight)),
            child: SingleChildScrollView(
              maxHeight: 450,
              child: Text(_evaluation, style: const TextStyle(fontSize: MiuixFontSize.md, height: 1.8, color: MiuixColors.textPrimary)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: MiuixButton(label: '复制报告', icon: Icons.copy_all, type: MiuixButtonType.secondary, onPressed: _copyEvaluation)),
              const SizedBox(width: 12),
              Expanded(child: MiuixButton(label: '下一题', icon: Icons.navigate_next, type: MiuixButtonType.primary, onPressed: _nextQuestion)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionBank() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('常见问题库', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          ...List.generate(_questionTypes.length, (typeIndex) {
            final type = _questionTypes[typeIndex];
            final questions = _questionBank[type] ?? [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_typeIcons[typeIndex], size: 18, color: MiuixColors.primary),
                      const SizedBox(width: 6),
                      Text('$type类', style: const TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(questions.length, (qIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: MiuixRipple(
                        borderRadius: MiuixRadius.sm,
                        child: GestureDetector(
                          onTap: () {
                            _positionController.text = _positionController.text.isEmpty ? '前端开发工程师' : _positionController.text;
                            setState(() {
                              _selectedType = typeIndex;
                              _questionIndex = qIndex;
                              _currentQuestion = questions[qIndex];
                              _hasQuestion = true;
                              _hasEvaluation = false;
                              _answerController.clear();
                            });
                            MiuixToast.show(context, message: '已加载该题目', type: MiuixToastType.info);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: MiuixColors.surfaceVariant, borderRadius: MiuixRadius.smRadius),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${qIndex + 1}.', style: const TextStyle(fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w600, color: MiuixColors.primary)),
                                const SizedBox(width: 6),
                                Expanded(child: Text(questions[qIndex], style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textSecondary, height: 1.5))),
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
          }),
        ],
      ),
    );
  }
}
