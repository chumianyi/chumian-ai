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
/// AIMathPage —— AI 数学解题
/// 题目输入(支持图片描述)，年级，题型选择，逐步解答
/// 知识点讲解，类似题目推荐
/// ============================================================
class AIMathPage extends StatefulWidget {
  const AIMathPage({super.key});

  @override
  State<AIMathPage> createState() => _AIMathPageState();
}

class _AIMathPageState extends State<AIMathPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _typewriterController;

  final TextEditingController _problemController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();

  int _selectedGrade = 1;
  int _selectedType = 0;
  bool _isGenerating = false;
  bool _hasResult = false;
  bool _hasError = false;
  String _errorMessage = \'\';
  String _displayedText = '';
  int _typewriterIndex = 0;

  static const List<String> _grades = ['小学', '初中', '高中', '大学'];
  static const List<String> _problemTypes = ['代数', '几何', '概率统计', '微积分', '应用题', '其他'];
  static const List<String> _sampleProblems = [
    '解方程：2x + 5 = 17',
    '一个长方形的长是宽的2倍，周长是36cm，求面积',
    '求函数 f(x) = x² - 4x + 3 的最小值',
    '掷两枚骰子，点数之和为7的概率是多少',
    '甲乙两人同时从A地出发，甲速度5km/h，乙速度3km/h...',
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
    _problemController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: MiuixCurves.miuixSpring)));
    final slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: Curves.easeOutCubic)));
    return AnimatedBuilder(animation: animation, builder: (_, __) => Opacity(opacity: animation.value, child: Transform.translate(offset: slide.value, child: child)));
  }

  Future<void> _solveProblem() async {
    if (_problemController.text.trim().isEmpty) {
      MiuixToast.show(context, message: '请输入数学题目', type: MiuixToastType.warning);
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
        systemPrompt: '你是一位专业的数学老师。请详细解答用户提出的数学问题，给出清晰的解题步骤和最终答案。',
        userInput: _problemController.text,
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
    if (mounted) MiuixToast.show(context, message: '已复制解答', type: MiuixToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(title: 'AI 数学解题', backgroundColor: MiuixColors.background),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedItem(_buildProblemInput(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildGradeTypeRow(), 1),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildSolveButton(), 2),
            const SizedBox(height: 20),
            if (_isGenerating) _buildAnimatedItem(_buildLoadingCard(), 3),
            if (_hasError) _buildAnimatedItem(_buildErrorCard(), 5),

            if (_hasResult) _buildAnimatedItem(_buildResultCard(), 3),
          ],
        ),
      ),
    );
  }

  Widget _buildProblemInput() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('数学题目', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          MiuixInput(
            controller: _problemController,
            hintText: '输入数学题目，如：解方程 2x+5=17\n（也可描述图片中的题目）',
            prefixIcon: Icons.functions,
            maxLines: 4,
            minLines: 3,
            type: MiuixInputType.multiline,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_sampleProblems.length, (index) {
              return MiuixChip(
                label: _sampleProblems[index].length > 16 ? '${_sampleProblems[index].substring(0, 16)}...' : _sampleProblems[index],
                onTap: () => _problemController.text = _sampleProblems[index],
                style: MiuixChipStyle.normal,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeTypeRow() {
    return Row(
      children: [
        Expanded(
          child: MiuixCard(
            style: MiuixCardStyle.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('年级', style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(_grades.length, (index) {
                    return MiuixChip(label: _grades[index], isSelected: _selectedGrade == index, onTap: () => setState(() => _selectedGrade = index), height: 30);
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
                const Text('题型', style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(_problemTypes.length, (index) {
                    return MiuixChip(label: _problemTypes[index], isSelected: _selectedType == index, onTap: () => setState(() => _selectedType = index), height: 30);
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSolveButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: _isGenerating ? '解题中...' : '开始解题',
        icon: Icons.calculate,
        type: MiuixButtonType.gradient,
        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
        size: MiuixButtonSize.large,
        loading: _isGenerating,
        onPressed: _isGenerating ? null : _solveProblem,
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
        const Text('AI 正在思考解题方法...', style: TextStyle(fontSize: MiuixFontSize.md, color: MiuixColors.textSecondary)),
        const SizedBox(height: 8),
        Text('${_grades[_selectedGrade]} · ${_problemTypes[_selectedType]}', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
      ]),
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
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.smRadius), child: const Icon(Icons.calculate, color: Colors.white, size: 20)),
              const SizedBox(width: 10),
              const Expanded(child: Text('详细解答', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary))),
              MiuixIconButton(icon: Icons.copy, style: MiuixIconButtonStyle.outlined, size: 36, iconSize: 18, onPressed: _copyResult),
              const SizedBox(width: 8),
              MiuixIconButton(icon: Icons.refresh, style: MiuixIconButtonStyle.outlined, size: 36, iconSize: 18, onPressed: _solveProblem),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: MiuixRadius.mdRadius, border: Border.all(color: MiuixColors.borderLight)),
            child: SingleChildScrollView(
              maxHeight: 500,
              child: Text(_displayedText, style: const TextStyle(fontSize: MiuixFontSize.md, height: 1.8, color: MiuixColors.textPrimary)),
            ),
          ),
          if (_typewriterIndex < _resultController.text.length)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(MiuixColors.primary))),
                const SizedBox(width: 8),
                const Text('正在输出解答...', style: TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
              ]),
            ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: MiuixButton(label: '复制解答', icon: Icons.copy_all, type: MiuixButtonType.primary, onPressed: _copyResult)),
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
