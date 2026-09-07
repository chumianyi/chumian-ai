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
/// AIPPTOutlinePage —— AI PPT 大纲
/// 主题，受众，页数，风格，生成大纲(每页标题+要点+备注)，导出文本
/// ============================================================
class AIPPTOutlinePage extends StatefulWidget {
  const AIPPTOutlinePage({super.key});

  @override
  State<AIPPTOutlinePage> createState() => _AIPPTOutlinePageState();
}

class _AIPPTOutlinePageState extends State<AIPPTOutlinePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _audienceController = TextEditingController();

  int _pageCount = 10;
  int _selectedStyle = 0;
  bool _isGenerating = false;
  bool _hasResult = false;
  bool _hasError = false;
  String _errorMessage = \'\';
  List<Map<String, dynamic>> _outline = [];
  final Set<int> _expanded = {};

  static const List<String> _styles = ['商务', '学术', '创意', '简约'];
  static const List<IconData> _styleIcons = [Icons.business, Icons.school, Icons.brush, Icons.crop_square];
  static const List<String> _sampleTopics = ['人工智能的发展与应用', '产品介绍与市场分析', '年度工作总结与规划', '创新创业项目路演'];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: MiuixDuration.slow);
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _topicController.dispose();
    _audienceController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: MiuixCurves.miuixSpring)));
    final slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: Curves.easeOutCubic)));
    return AnimatedBuilder(animation: animation, builder: (_, __) => Opacity(opacity: animation.value, child: Transform.translate(offset: slide.value, child: child)));
  }

  Future<void> _generateOutline() async {
    if (_topicController.text.trim().isEmpty) {
      MiuixToast.show(context, message: '请输入PPT主题', type: MiuixToastType.warning);
      return;
    }
    setState(() {
      _isGenerating = true;
      _hasResult = false;
      _outline = [];
      _expanded.clear();
    });
    try {
      final result = await ApiService.aiToolComplete(
        systemPrompt: '你是一位专业的PPT策划师。请根据用户提供的主题，生成一个结构清晰、逻辑严密的PPT大纲，包含每页的标题和要点。',
        userInput: _topicController.text,
      );
      if (mounted) {
        _outlineText = result;
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
  }

  List<Map<String, dynamic>> _buildOutlineData() {
    final topic = _topicController.text.trim();
    final audience = _audienceController.text.trim().isEmpty ? '通用受众' : _audienceController.text.trim();
    final style = _styles[_selectedStyle];

    List<Map<String, dynamic>> pages = [
      {
        'page': 1,
        'title': topic,
        'subtitle': '——$style风格演示文稿',
        'type': '封面',
        'points': ['主标题：$topic', '副标题：$audience专场', '演讲者：[您的姓名]', '日期：[当前日期]'],
        'notes': '封面页保持简洁大气，主标题字号不小于40pt，可加入公司Logo和背景图。演讲时微笑致意，用一句话引出主题。',
      },
      {
        'page': 2,
        'title': '目录',
        'subtitle': 'CONTENTS',
        'type': '目录',
        'points': ['01 背景与现状', '02 核心内容', '03 案例分析', '04 总结与展望'],
        'notes': '目录页用数字+标题的形式，建议加入图标增强视觉效果。演讲时快速带过，告诉听众接下来的内容框架。',
      },
      {
        'page': 3,
        'title': '背景与现状',
        'subtitle': 'Background',
        'type': '内容',
        'points': ['行业发展现状概述', '当前面临的主要挑战', '市场规模与增长趋势', '为什么要关注这个话题'],
        'notes': '用数据说话，加入图表（柱状图/折线图）展示趋势。引用权威数据源增加可信度。这一页控制在2分钟内。',
      },
      {
        'page': 4,
        'title': '核心概念解析',
        'subtitle': 'Core Concepts',
        'type': '内容',
        'points': ['什么是$topic', '核心原理与关键要素', '与传统方式的对比', '常见误区澄清'],
        'notes': '概念页避免大段文字，用图标+关键词的方式呈现。可以用对比表格展示新旧方式差异。用通俗的语言解释专业概念。',
      },
      {
        'page': 5,
        'title': '关键技术/方法',
        'subtitle': 'Key Methods',
        'type': '内容',
        'points': ['核心技术/方法一：详细说明', '核心技术/方法二：详细说明', '技术路线图/流程图', '实施步骤与注意事项'],
        'notes': '技术页建议用流程图展示完整链路。每个要点不超过20字，详细内容放在演讲者备注里。可以加入架构图或示意图。',
      },
      {
        'page': 6,
        'title': '案例分析一',
        'subtitle': 'Case Study 1',
        'type': '案例',
        'points': ['案例背景介绍', '面临的问题与挑战', '解决方案与实施过程', '取得的成果与数据'],
        'notes': '案例页是最吸引人的部分，用故事化的方式讲述。前后对比数据要醒目（用大字号+粉色高亮）。可以加入客户Logo增强说服力。',
      },
      {
        'page': 7,
        'title': '案例分析二',
        'subtitle': 'Case Study 2',
        'type': '案例',
        'points': ['另一个典型场景', '不同的解决思路', '关键成功因素', '可复制的经验总结'],
        'notes': '第二个案例选择不同行业或场景，展示普适性。与第一个案例形成互补。重点讲"可复制的经验"，让听众觉得自己也能做到。',
      },
      {
        'page': 8,
        'title': '数据与成果',
        'subtitle': 'Results & Data',
        'type': '数据',
        'points': ['关键指标提升：XX%', '用户/客户增长数据', '成本降低/效率提升', 'ROI投资回报率分析'],
        'notes': '数据页是全篇的高潮，用大数字+图表的方式呈现。每个数据不超过3个，突出重点。可以用仪表盘或进度环展示完成率。数据要真实可信。',
      },
      {
        'page': 9,
        'title': '未来展望与规划',
        'subtitle': 'Future Outlook',
        'type': '内容',
        'points': ['短期目标（3-6个月）', '中期规划（1-2年）', '长期愿景（3-5年）', '需要的支持与资源'],
        'notes': '展望页用时间轴展示规划路线。目标要具体可衡量。可以加入Roadmap图。这一页展示你的远见和规划能力，给听众信心。',
      },
      {
        'page': 10,
        'title': '总结与致谢',
        'subtitle': 'Thank You',
        'type': '结尾',
        'points': ['核心要点回顾（3句话）', '关键结论重申', 'Q&A互动环节', '联系方式：邮箱/电话/微信'],
        'notes': '结尾页简洁有力，用三句话总结全篇。留出Q&A时间。联系方式清晰可见。可以加入二维码方便听众联系。演讲结束时鞠躬致谢。',
      },
    ];

    // 根据页数调整
    if (_pageCount <= 8) {
      pages = [pages[0], pages[1], pages[2], pages[3], pages[5], pages[7], pages[8], pages[9]];
    } else if (_pageCount >= 12) {
      pages.insert(5, {
        'page': 6,
        'title': '补充内容',
        'subtitle': 'Additional',
        'type': '内容',
        'points': ['补充要点一', '补充要点二', '补充要点三', '补充要点四'],
        'notes': '补充页根据需要添加，确保内容完整。',
      });
      pages.insert(8, {
        'page': 9,
        'title': '常见问题解答',
        'subtitle': 'FAQ',
        'type': '内容',
        'points': ['问题一：解答', '问题二：解答', '问题三：解答', '问题四：解答'],
        'notes': 'FAQ页预判听众可能的疑问，主动解答增加专业度。',
      });
    }

    // 重新编号
    for (int i = 0; i < pages.length && i < _pageCount; i++) {
      pages[i]['page'] = i + 1;
    }

    return pages.take(_pageCount).toList();
  }

  void _toggleExpand(int index) {
    setState(() {
      if (_expanded.contains(index)) {
        _expanded.remove(index);
      } else {
        _expanded.add(index);
      }
    });
  }

  Future<void> _exportOutline() async {
    String text = '《${_topicController.text}》PPT大纲\n';
    text += '受众：${_audienceController.text.isEmpty ? "通用" : _audienceController.text}\n';
    text += '风格：${_styles[_selectedStyle]}\n';
    text += '页数：${_outline.length}页\n\n';
    text += '=' * 40 + '\n\n';
    for (var page in _outline) {
      text += '【第${page['page']}页 · ${page['type']}】\n';
      text += '标题：${page['title']}\n';
      if (page['subtitle'] != null) text += '副标题：${page['subtitle']}\n';
      text += '要点：\n';
      for (var p in page['points']) text += '  • $p\n';
      text += '演讲备注：${page['notes']}\n\n';
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) MiuixToast.show(context, message: '大纲已复制到剪贴板', type: MiuixToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(title: 'AI PPT 大纲', backgroundColor: MiuixColors.background),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedItem(_buildTopicInput(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildStyleSelector(), 1),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildPageCountSlider(), 2),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildGenerateButton(), 3),
            const SizedBox(height: 20),
            if (_isGenerating) _buildAnimatedItem(_buildLoadingCard(), 4),
            if (_hasError) _buildAnimatedItem(_buildErrorCard(), 5),

            if (_hasResult) ...[
              _buildAnimatedItem(_buildExportBar(), 4),
              const SizedBox(height: 12),
              ..._buildOutlineCards(),
            ],
          ],
        ),
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
          const Text('PPT 主题', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          MiuixInput(controller: _topicController, hintText: '如：人工智能的发展与应用', prefixIcon: Icons.title),
          const SizedBox(height: 12),
          MiuixInput(controller: _audienceController, hintText: '目标受众（选填），如：公司管理层/技术团队', prefixIcon: Icons.people),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_sampleTopics.length, (index) {
              return MiuixChip(label: _sampleTopics[index], onTap: () => _topicController.text = _sampleTopics[index], style: MiuixChipStyle.normal);
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
          const Text('演示风格', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_styles.length, (index) {
              final isSelected = _selectedStyle == index;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 3 ? 6 : 0),
                  child: MiuixRipple(
                    borderRadius: MiuixRadius.md,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedStyle = index),
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
                            Icon(_styleIcons[index], size: 20, color: isSelected ? Colors.white : MiuixColors.primary),
                            const SizedBox(height: 4),
                            Text(_styles[index], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : MiuixColors.textSecondary)),
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

  Widget _buildPageCountSlider() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PPT 页数', style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.pillRadius),
                child: Text('$_pageCount 页', style: const TextStyle(color: Colors.white, fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w600)),
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
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(value: _pageCount.toDouble(), min: 6, max: 15, divisions: 9, label: '$_pageCount页', onChanged: (val) => setState(() => _pageCount = val.toInt())),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: _isGenerating ? '生成中...' : '生成 PPT 大纲',
        icon: Icons.slideshow,
        type: MiuixButtonType.gradient,
        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
        size: MiuixButtonSize.large,
        loading: _isGenerating,
        onPressed: _isGenerating ? null : _generateOutline,
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
        const Text('AI 正在构思大纲...', style: TextStyle(fontSize: MiuixFontSize.md, color: MiuixColors.textSecondary)),
        const SizedBox(height: 8),
        Text('${_styles[_selectedStyle]}风格 · $_pageCount页', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
      ]),
    );
  }

  Widget _buildExportBar() {
    return Row(
      children: [
        Expanded(
          child: MiuixCard(
            style: MiuixCardStyle.gradient,
            gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('已生成 ${_outline.length} 页大纲', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        MiuixIconButton(icon: Icons.file_download, style: MiuixIconButtonStyle.filled, size: 44, iconSize: 22, onPressed: _exportOutline),
      ],
    );
  }

  List<Widget> _buildOutlineCards() {
    return List.generate(_outline.length, (index) {
      final page = _outline[index];
      final isExpanded = _expanded.contains(index);
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildAnimatedItem(
          MiuixCard(
            style: MiuixCardStyle.surface,
            padding: const EdgeInsets.all(14),
            onTap: () => _toggleExpand(index),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.smRadius),
                      child: Center(child: Text('${page['page']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(page['title'], style: const TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
                          if (page['subtitle'] != null) Text(page['subtitle'], style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: MiuixColors.surfaceVariant, borderRadius: MiuixRadius.pillRadius),
                      child: Text(page['type'], style: const TextStyle(fontSize: 10, color: MiuixColors.primary, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: MiuixColors.textTertiary, size: 20),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  const Divider(color: MiuixColors.divider, height: 1),
                  const SizedBox(height: 10),
                  const Text('页面要点', style: TextStyle(fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w600, color: MiuixColors.textSecondary)),
                  const SizedBox(height: 6),
                  ...List.generate((page['points'] as List).length, (pIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 5, height: 5, margin: const EdgeInsets.only(top: 7), decoration: const BoxDecoration(color: MiuixColors.primary, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(page['points'][pIndex], style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textPrimary, height: 1.5))),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: MiuixColors.surfaceVariant, borderRadius: MiuixRadius.smRadius),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.record_voice_over, size: 16, color: MiuixColors.primary),
                        const SizedBox(width: 6),
                        Expanded(child: Text('演讲备注：${page['notes']}', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textSecondary, height: 1.5))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          index + 5,
        ),
      );
    });

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
