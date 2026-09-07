import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_chip.dart';
import 'package:chumian_ai/widgets/miuix/miuix_input.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_segment.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/services/api_service.dart';
import 'package:chumian_ai/utils/clipboard_utils.dart';

/// ============================================================
/// AICodePage —— AI 代码助手
/// 语言选择，代码输入框(等宽字体)，代码生成，语法高亮(简易)
/// 复制按钮，解释代码功能
/// ============================================================
class AICodePage extends StatefulWidget {
  const AICodePage({super.key});

  @override
  State<AICodePage> createState() => _AICodePageState();
}

class _AICodePageState extends State<AICodePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _explainController = TextEditingController();

  int _selectedLang = 0;
  int _selectedMode = 0; // 0: 生成代码, 1: 解释代码
  bool _isGenerating = false;
  bool _hasResult = false;
  bool _hasError = false;
  String _errorMessage = '';

  static const List<CodeLanguage> _languages = [
    CodeLanguage(name: 'Dart', icon: Icons.flutter_dash, color: Color(0xFF0175C2)),
    CodeLanguage(name: 'Python', icon: Icons.code, color: Color(0xFF3776AB)),
    CodeLanguage(name: 'JavaScript', icon: Icons.javascript, color: Color(0xFFF7DF1E)),
    CodeLanguage(name: 'Java', icon: Icons.coffee, color: Color(0xFFED8B00)),
    CodeLanguage(name: 'C++', icon: Icons.memory, color: Color(0xFF00599C)),
    CodeLanguage(name: 'Go', icon: Icons.bolt, color: Color(0xFF00ADD8)),
    CodeLanguage(name: 'Rust', icon: Icons.shield, color: Color(0xFFDEA584)),
    CodeLanguage(name: 'SQL', icon: Icons.storage, color: Color(0xFFCC2927)),
  ];

  static const List<String> _samplePrompts = [
    '快速排序算法',
    '斐波那契数列',
    'HTTP请求封装',
    '单例模式',
    '二分查找',
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _promptController.dispose();
    _codeController.dispose();
    _explainController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.08, (index * 0.08) + 0.4,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.08, (index * 0.08) + 0.4,
            curve: Curves.easeOutCubic),
      ),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) => Opacity(
        opacity: anim.value,
        child: Transform.translate(offset: slide.value, child: child),
      ),
    );
  }

  Future<void> _generate() async {
    final input = _selectedMode == 0
        ? _promptController.text
        : _codeController.text;
    if (input.trim().isEmpty) {
      MiuixToast.show(context,
          message: _selectedMode == 0 ? '请输入功能描述' : '请输入代码',
          type: MiuixToastType.warning);
      return;
    }
    setState(() {
      _isGenerating = true;
      _hasResult = false;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      if (_selectedMode == 0) {
        // 生成代码：调用真实 AI 接口
        final lang = _languages[_selectedLang].name;
        final code = await ApiService.aiToolComplete(
          systemPrompt: '你是一位专业的$lang程序员。请根据用户的功能描述，生成完整、可运行的$lang代码，包含必要的注释。只输出代码，不要额外解释。',
          userInput: _promptController.text,
        );
        _codeController.text = code;
        // 同时生成代码解释
        final explain = await ApiService.aiToolComplete(
          systemPrompt: '你是一位编程讲师。请用简洁的中文解释以下代码的功能、核心逻辑和时间复杂度。',
          userInput: code,
        );
        _explainController.text = explain;
      } else {
        // 解释代码：调用真实 AI 接口
        final explain = await ApiService.aiToolComplete(
          systemPrompt: '你是一位编程讲师。请详细分析以下代码，说明其功能、结构、变量使用、优化建议和性能评估。',
          userInput: _codeController.text,
        );
        _explainController.text = explain;
      }
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _hasResult = true;
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

  Future<void> _copyCode() async {
    await ClipboardUtils.copy(_codeController.text);
    if (mounted) {
      MiuixToast.show(context,
          message: '代码已复制', type: MiuixToastType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: 'AI 代码助手',
        backgroundColor: MiuixColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            _buildAnimatedItem(_buildModeSegment(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildLanguageGrid(), 1),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildInputArea(), 2),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildGenerateButton(), 3),
            const SizedBox(height: 20),
            if (_hasResult || _isGenerating)
              _buildAnimatedItem(_buildResultArea(), 4),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSegment() {
    return MiuixSegmentControl(
      items: const [
        MiuixSegmentItem(label: '生成代码', icon: Icons.auto_awesome),
        MiuixSegmentItem(label: '解释代码', icon: Icons.lightbulb_outline),
      ],
      selectedIndex: _selectedMode,
      onChanged: (i) => setState(() => _selectedMode = i),
    );
  }

  Widget _buildLanguageGrid() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择编程语言',
            style: TextStyle(
              fontSize: MiuixFontSize.md,
              fontWeight: FontWeight.w600,
              color: MiuixColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_languages.length, (index) {
              final isSelected = _selectedLang == index;
              final lang = _languages[index];
              return MiuixRipple(
                borderRadius: MiuixRadius.md,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedLang = index),
                  child: AnimatedContainer(
                    duration: MiuixDuration.fast,
                    curve: MiuixCurves.miuixSpring,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(colors: [
                              lang.color.withOpacity(0.9),
                              lang.color,
                            ])
                          : null,
                      color: isSelected ? null : MiuixColors.surfaceVariant,
                      borderRadius: MiuixRadius.mdRadius,
                      border: Border.all(
                        color: isSelected
                            ? lang.color
                            : MiuixColors.borderLight,
                      ),
                      boxShadow: isSelected ? MiuixShadows.sm : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(lang.icon,
                            size: 18,
                            color: isSelected ? Colors.white : lang.color),
                        const SizedBox(width: 6),
                        Text(
                          lang.name,
                          style: TextStyle(
                            fontSize: MiuixFontSize.sm,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : MiuixColors.textSecondary,
                          ),
                        ),
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

  Widget _buildInputArea() {
    if (_selectedMode == 0) {
      return MiuixCard(
        style: MiuixCardStyle.surface,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '功能描述',
              style: TextStyle(
                fontSize: MiuixFontSize.md,
                fontWeight: FontWeight.w600,
                color: MiuixColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            MiuixInput(
              controller: _promptController,
              hintText: '描述你想要实现的功能，例如：实现一个快速排序算法',
              type: MiuixInputType.multiline,
              maxLines: 4,
              minLines: 3,
              prefixIcon: Icons.psychology,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_samplePrompts.length, (index) {
                return MiuixChip(
                  label: _samplePrompts[index],
                  onTap: () => _promptController.text = _samplePrompts[index],
                );
              }),
            ),
          ],
        ),
      );
    } else {
      return MiuixCard(
        style: MiuixCardStyle.surface,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '粘贴代码',
                  style: TextStyle(
                    fontSize: MiuixFontSize.md,
                    fontWeight: FontWeight.w600,
                    color: MiuixColors.textPrimary,
                  ),
                ),
                const Spacer(),
                MiuixIconButton(
                  icon: Icons.paste,
                  style: MiuixIconButtonStyle.ghost,
                  size: 32,
                  iconSize: 16,
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      _codeController.text = data!.text!;
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: MiuixRadius.mdRadius,
              ),
              child: TextField(
                controller: _codeController,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFCDD6F4),
                  height: 1.5,
                ),
                maxLines: 8,
                minLines: 5,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                  hintText: '在此粘贴需要解释的代码...',
                  hintStyle: TextStyle(
                    color: Color(0xFF6C7086),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: _isGenerating
            ? '处理中...'
            : (_selectedMode == 0 ? '生成代码' : '解释代码'),
        icon: _selectedMode == 0 ? Icons.code : Icons.lightbulb,
        type: MiuixButtonType.gradient,
        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
        size: MiuixButtonSize.large,
        loading: _isGenerating,
        onPressed: _isGenerating ? null : _generate,
      ),
    );
  }

  Widget _buildResultArea() {
    return Column(
      children: [
        if (_selectedMode == 0) _buildCodeResult(),
        const SizedBox(height: 16),
        _buildExplainResult(),
      ],
    );
  }

  Widget _buildCodeResult() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF181825),
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(MiuixRadius.lg)),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5F57),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEBC2E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF28C840),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_languages[_selectedLang].name} 代码',
                  style: const TextStyle(
                    color: Color(0xFFCDD6F4),
                    fontSize: MiuixFontSize.sm,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                MiuixIconButton(
                  icon: Icons.copy,
                  style: MiuixIconButtonStyle.ghost,
                  size: 32,
                  iconSize: 16,
                  onPressed: _copyCode,
                ),
              ],
            ),
          ),
          _isGenerating
              ? Container(
                  height: 200,
                  color: const Color(0xFF1E1E2E),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation(MiuixColors.primary),
                    ),
                  ),
                )
              : Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 350),
                  color: const Color(0xFF1E1E2E),
                  padding: const EdgeInsets.all(14),
                  child: SingleChildScrollView(
                    child: _buildHighlightedCode(_codeController.text),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildHighlightedCode(String code) {
    final lines = code.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines.length, (index) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 36,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF45475A),
                ),
              ),
            ),
            Expanded(
              child: Text(
                lines[index],
                style: TextStyle(
                  fontSize: 13,
                  color: _getLineColor(lines[index]),
                  height: 1.5,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Color _getLineColor(String line) {
    final trimmed = line.trim();
    if (trimmed.startsWith('//') || trimmed.startsWith('#')) {
      return const Color(0xFF6C7086);
    }
    if (trimmed.contains('class') ||
        trimmed.contains('def ') ||
        trimmed.contains('function') ||
        trimmed.contains('void ')) {
      return const Color(0xFFCBA6F7);
    }
    if (trimmed.contains('return') ||
        trimmed.contains('if ') ||
        trimmed.contains('for ') ||
        trimmed.contains('while ')) {
      return const Color(0xFFF38BA8);
    }
    if (trimmed.contains('print') || trimmed.contains('console.log')) {
      return const Color(0xFFA6E3A1);
    }
    return const Color(0xFFCDD6F4);
  }

  Widget _buildExplainResult() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: MiuixColors.primaryGradient),
                  borderRadius: MiuixRadius.smRadius,
                ),
                child: const Icon(Icons.lightbulb,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                '代码解释',
                style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _isGenerating
              ? const SizedBox(
                  height: 80,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(MiuixColors.primary),
                    ),
                  ),
                )
              : Text(
                  _explainController.text,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.md,
                    height: 1.7,
                    color: MiuixColors.textPrimary,
                  ),
                ),
        ],
      ),
    );
  }
}

class CodeLanguage {
  final String name;
  final IconData icon;
  final Color color;
  const CodeLanguage(
      {required this.name, required this.icon, required this.color});
}
