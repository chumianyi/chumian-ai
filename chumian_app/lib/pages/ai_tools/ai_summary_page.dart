import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chumian_ai/services/api_service.dart';
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
import 'package:chumian_ai/utils/clipboard_utils.dart';

/// ============================================================
/// AISummaryPage —— AI 总结
/// 长文本输入，总结长度选择，要点提取，思维导图式展示，复制
/// ============================================================
class AISummaryPage extends StatefulWidget {
  const AISummaryPage({super.key});

  @override
  State<AISummaryPage> createState() => _AISummaryPageState();
}

class _AISummaryPageState extends State<AISummaryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();

  int _selectedLength = 1;
  int _selectedMode = 0; // 0: 摘要, 1: 要点, 2: 思维导图
  bool _isSummarizing = false;
  bool _hasResult = false;
  bool _hasError = false;
  String _errorMessage = '';
  List<SummaryPoint> _points = [];
  MindMapNode? _mindMap;

  static const List<String> _lengths = ['简短', '标准', '详细'];
  static const List<String> _lengthDesc = ['约100字', '约300字', '约500字'];

  static const String _sampleText =
      '人工智能（Artificial Intelligence，简称AI）是计算机科学的一个分支，它企图了解智能的实质，并生产出一种新的能以人类智能相似的方式做出反应的智能机器。该领域的研究包括机器人、语言识别、图像识别、自然语言处理和专家系统等。人工智能从诞生以来，理论和技术日益成熟，应用领域也不断扩大，可以设想，未来人工智能带来的科技产品，将会是人类智慧的"容器"。人工智能可以对人的意识、思维的信息过程的模拟。人工智能不是人的智能，但能像人那样思考、也可能超过人的智能。';

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
    _inputController.dispose();
    _summaryController.dispose();
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

  Future<void> _summarize() async {
    if (_inputController.text.trim().isEmpty) {
      MiuixToast.show(context,
          message: '请输入需要总结的文本', type: MiuixToastType.warning);
      return;
    }
    setState(() {
      _isSummarizing = true;
      _hasResult = false;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final length = _lengths[_selectedLength];
      final mode = _selectedMode == 0 ? '摘要' : _selectedMode == 1 ? '要点列表（每行一条）' : '思维导图（用层级缩进文本表示）';
      final result = await ApiService.aiToolComplete(
        systemPrompt: '你是一位专业的文本总结专家。请将以下文本总结为$length的$mode。要求：准确、简洁、保留核心信息。',
        userInput: _inputController.text.trim(),
      );
      if (mounted) {
        _summaryController.text = result;
        if (_selectedMode == 1) {
          _points = result.split('\n')
              .where((l) => l.trim().isNotEmpty)
              .map((l) => SummaryPoint(
                    icon: Icons.circle,
                    title: l.trim().replaceAll(RegExp(r'^[•\-\d.\s]+'), ''),
                    content: '',
                  ))
              .toList();
        }
        setState(() {
          _isSummarizing = false;
          _hasResult = true;
        });
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

  Future<void> _copyResult() async {
    final text = _selectedMode == 0
        ? _summaryController.text
        : _points.map((p) => '${p.title}：${p.content}').join('\n');
    await ClipboardUtils.copy(text);
    if (mounted) {
      MiuixToast.show(context,
          message: '已复制到剪贴板', type: MiuixToastType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: 'AI 总结',
        backgroundColor: MiuixColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            _buildAnimatedItem(_buildInputCard(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildSettingsRow(), 1),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildSummarizeButton(), 2),
            const SizedBox(height: 20),
            if (_hasResult || _isSummarizing)
              _buildAnimatedItem(_buildResultArea(), 3),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '输入文本',
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
                    _inputController.text = data!.text!;
                  }
                },
              ),
              MiuixIconButton(
                icon: Icons.clear,
                style: MiuixIconButtonStyle.ghost,
                size: 32,
                iconSize: 16,
                onPressed: () {
                  _inputController.clear();
                  setState(() => _hasResult = false);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          MiuixInput(
            controller: _inputController,
            hintText: '粘贴或输入需要总结的长文本...',
            type: MiuixInputType.multiline,
            maxLines: 8,
            minLines: 5,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_inputController.text.length} 字符',
                style: const TextStyle(
                  fontSize: MiuixFontSize.xs,
                  color: MiuixColors.textTertiary,
                ),
              ),
              MiuixChip(
                label: '使用示例文本',
                onTap: () => _inputController.text = _sampleText,
                height: 28,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow() {
    return Row(
      children: [
        Expanded(
          child: MiuixCard(
            style: MiuixCardStyle.surface,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '总结长度',
                  style: TextStyle(
                    fontSize: MiuixFontSize.sm,
                    fontWeight: FontWeight.w600,
                    color: MiuixColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(_lengths.length, (index) {
                    final isSelected = _selectedLength == index;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: index < 2 ? 6 : 0),
                        child: MiuixRipple(
                          borderRadius: MiuixRadius.sm,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedLength = index),
                            child: AnimatedContainer(
                              duration: MiuixDuration.fast,
                              curve: MiuixCurves.miuixSpring,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: MiuixColors.primaryGradient)
                                    : null,
                                color: isSelected
                                    ? null
                                    : MiuixColors.surfaceVariant,
                                borderRadius: MiuixRadius.smRadius,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _lengths[index],
                                    style: TextStyle(
                                      fontSize: MiuixFontSize.sm,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : MiuixColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    _lengthDesc[index],
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.8)
                                          : MiuixColors.textTertiary,
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
          ),
        ),
      ],
    );
  }

  Widget _buildSummarizeButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: _isSummarizing ? '总结中...' : '智能总结',
        icon: Icons.summarize,
        type: MiuixButtonType.gradient,
        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
        size: MiuixButtonSize.large,
        loading: _isSummarizing,
        onPressed: _isSummarizing ? null : _summarize,
      ),
    );
  }

  Widget _buildResultArea() {
    return Column(
      children: [
        MiuixSegmentControl(
          items: const [
            MiuixSegmentItem(label: '摘要', icon: Icons.article),
            MiuixSegmentItem(label: '要点', icon: Icons.format_list_bulleted),
            MiuixSegmentItem(label: '思维导图', icon: Icons.account_tree),
          ],
          selectedIndex: _selectedMode,
          onChanged: (i) => setState(() => _selectedMode = i),
        ),
        const SizedBox(height: 16),
        if (_selectedMode == 0) _buildSummaryCard(),
        if (_selectedMode == 1) _buildPointsCard(),
        if (_selectedMode == 2) _buildMindMapCard(),
      ],
    );
  }

  Widget _buildSummaryCard() {
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
                child: const Icon(Icons.article, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                '内容摘要',
                style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
              const Spacer(),
              MiuixIconButton(
                icon: Icons.copy,
                style: MiuixIconButtonStyle.ghost,
                size: 32,
                iconSize: 16,
                onPressed: _copyResult,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _isSummarizing
              ? const SizedBox(
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation(MiuixColors.primary),
                    ),
                  ),
                )
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: MiuixRadius.mdRadius,
                  ),
                  child: Text(
                    _summaryController.text,
                    style: const TextStyle(
                      fontSize: MiuixFontSize.md,
                      height: 1.8,
                      color: MiuixColors.textPrimary,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildPointsCard() {
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
                child: const Icon(Icons.format_list_bulleted,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                '核心要点',
                style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
              const Spacer(),
              MiuixIconButton(
                icon: Icons.copy,
                style: MiuixIconButtonStyle.ghost,
                size: 32,
                iconSize: 16,
                onPressed: _copyResult,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isSummarizing)
            const SizedBox(
              height: 150,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(MiuixColors.primary),
                ),
              ),
            )
          else
            ...List.generate(_points.length, (index) {
              final point = _points[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: MiuixRadius.mdRadius,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: MiuixColors.primaryLight.withOpacity(0.2),
                          borderRadius: MiuixRadius.smRadius,
                        ),
                        child: Icon(point.icon,
                            size: 18, color: MiuixColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              point.title,
                              style: const TextStyle(
                                fontSize: MiuixFontSize.md,
                                fontWeight: FontWeight.w600,
                                color: MiuixColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              point.content,
                              style: const TextStyle(
                                fontSize: MiuixFontSize.sm,
                                color: MiuixColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMindMapCard() {
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
                child: const Icon(Icons.account_tree,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                '思维导图',
                style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isSummarizing)
            const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(MiuixColors.primary),
                ),
              ),
            )
          else
            _buildMindMapNode(_mindMap!, 0),
        ],
      ),
    );
  }

  Widget _buildMindMapNode(MindMapNode node, int depth) {
    return Padding(
      padding: EdgeInsets.only(left: depth > 0 ? 16.0 : 0, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (depth > 0)
                Container(
                  width: 3,
                  height: 20,
                  color: node.color,
                ),
              if (depth > 0) const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: node.color,
                    borderRadius: MiuixRadius.pillRadius,
                    boxShadow: MiuixShadows.xs,
                  ),
                  child: Text(
                    node.title,
                    style: TextStyle(
                      color: depth == 0 ? Colors.white : MiuixColors.textPrimary,
                      fontSize: depth == 0
                          ? MiuixFontSize.md
                          : MiuixFontSize.sm,
                      fontWeight:
                          depth == 0 ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (node.children != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: node.children!
                    .map((child) => _buildMindMapNode(child, depth + 1))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class SummaryPoint {
  final IconData icon;
  final String title;
  final String content;
  const SummaryPoint(
      {required this.icon, required this.title, required this.content});
}

class MindMapNode {
  final String title;
  final Color color;
  final List<MindMapNode>? children;
  const MindMapNode(
      {required this.title, required this.color, this.children});
}
