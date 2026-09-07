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
/// AIMindmapPage —— AI 思维导图
/// 中心主题，层级数，生成思维导图结构(树形展示)
/// 可展开折叠，导出
/// ============================================================
class AIMindmapPage extends StatefulWidget {
  const AIMindmapPage({super.key});

  @override
  State<AIMindmapPage> createState() => _AIMindmapPageState();
}

class _AIMindmapPageState extends State<AIMindmapPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  final TextEditingController _topicController = TextEditingController();

  int _levelCount = 3;
  bool _isGenerating = false;
  bool _hasResult = false;
  bool _hasError = false;
  String _errorMessage = \'\';
  Map<String, dynamic> _mindmap = {};
  final Set<String> _collapsed = {};

  static const List<String> _sampleTopics = ['人工智能', '产品设计', '学习计划', '创业项目', '自我提升'];

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
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: MiuixCurves.miuixSpring)));
    final slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: Curves.easeOutCubic)));
    return AnimatedBuilder(animation: animation, builder: (_, __) => Opacity(opacity: animation.value, child: Transform.translate(offset: slide.value, child: child)));
  }

  Future<void> _generateMindmap() async {
    if (_topicController.text.trim().isEmpty) {
      MiuixToast.show(context, message: '请输入中心主题', type: MiuixToastType.warning);
      return;
    }
    setState(() {
      _isGenerating = true;
      _hasResult = false;
      _mindmap = {};
      _collapsed.clear();
    });
    try {
      final result = await ApiService.aiToolComplete(
        systemPrompt: '你是一位思维导图专家。请根据用户提供的主题，生成一个结构清晰的思维导图，用层级缩进的文本格式表示。',
        userInput: _topicController.text,
      );
      if (mounted) {
        _resultText = result;
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

  Map<String, dynamic> _buildMindmapData() {
    final topic = _topicController.text.trim();
    return {
      'title': topic,
      'children': [
        {
          'title': '概念与定义',
          'children': [
            {'title': '什么是$topic', 'children': [
              {'title': '核心内涵'},
              {'title': '本质特征'},
              {'title': '与相关概念的区别'},
            ]},
            {'title': '发展历程', 'children': [
              {'title': '起源与萌芽'},
              {'title': '快速发展期'},
              {'title': '成熟与普及'},
            ]},
            {'title': '分类与类型', 'children': [
              {'title': '按应用领域分'},
              {'title': '按技术路线分'},
              {'title': '按成熟度分'},
            ]},
          ],
        },
        {
          'title': '核心技术/方法',
          'children': [
            {'title': '基础原理', 'children': [
              {'title': '底层逻辑'},
              {'title': '关键算法'},
              {'title': '理论基础'},
            ]},
            {'title': '关键技术', 'children': [
              {'title': '技术一详解'},
              {'title': '技术二详解'},
              {'title': '技术三详解'},
            ]},
            {'title': '工具与框架', 'children': [
              {'title': '主流工具对比'},
              {'title': '推荐框架'},
              {'title': '选型建议'},
            ]},
          ],
        },
        {
          'title': '应用场景',
          'children': [
            {'title': '行业应用', 'children': [
              {'title': '金融领域'},
              {'title': '医疗健康'},
              {'title': '教育培训'},
              {'title': '智能制造'},
            ]},
            {'title': '日常应用', 'children': [
              {'title': '个人效率提升'},
              {'title': '学习辅助'},
              {'title': '生活便利'},
            ]},
            {'title': '前沿探索', 'children': [
              {'title': '最新研究方向'},
              {'title': '未来可能性'},
              {'title': '伦理与挑战'},
            ]},
          ],
        },
        {
          'title': '学习与实践',
          'children': [
            {'title': '学习路径', 'children': [
              {'title': '入门阶段'},
              {'title': '进阶阶段'},
              {'title': '精通阶段'},
            ]},
            {'title': '实践项目', 'children': [
              {'title': '入门级项目'},
              {'title': '进阶级项目'},
              {'title': '实战项目'},
            ]},
            {'title': '资源推荐', 'children': [
              {'title': '经典书籍'},
              {'title': '在线课程'},
              {'title': '社区与论坛'},
            ]},
          ],
        },
        {
          'title': '趋势与展望',
          'children': [
            {'title': '当前趋势', 'children': [
              {'title': '技术发展方向'},
              {'title': '市场需求变化'},
              {'title': '政策导向'},
            ]},
            {'title': '未来预测', 'children': [
              {'title': '短期预测(1-2年)'},
              {'title': '中期预测(3-5年)'},
              {'title': '长期展望(5年+)'},
            ]},
            {'title': '机遇与挑战', 'children': [
              {'title': '发展机遇'},
              {'title': '面临挑战'},
              {'title': '应对策略'},
            ]},
          ],
        },
      ],
    };
  }

  void _toggleNode(String key) {
    setState(() {
      if (_collapsed.contains(key)) {
        _collapsed.remove(key);
      } else {
        _collapsed.add(key);
      }
    });
  }

  Future<void> _exportMindmap() async {
    String text = '# ${_mindmap['title']}\n\n';
    void exportNode(Map<String, dynamic> node, int level) {
      text += '${"#" * (level + 1)} ${node['title']}\n';
      if (node['children'] != null) {
        for (var child in node['children']) {
          exportNode(child, level + 1);
        }
      }
      text += '\n';
    }
    if (_mindmap['children'] != null) {
      for (var child in _mindmap['children']) {
        exportNode(child, 1);
      }
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) MiuixToast.show(context, message: '思维导图已导出(Markdown格式)', type: MiuixToastType.success);
  }

  int _countNodes(Map<String, dynamic> node) {
    int count = 1;
    if (node['children'] != null) {
      for (var child in node['children']) {
        count += _countNodes(child);
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(title: 'AI 思维导图', backgroundColor: MiuixColors.background),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedItem(_buildTopicInput(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildLevelSelector(), 1),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildGenerateButton(), 2),
            const SizedBox(height: 20),
            if (_isGenerating) _buildAnimatedItem(_buildLoadingCard(), 3),
            if (_hasError) _buildAnimatedItem(_buildErrorCard(), 5),

            if (_hasResult) ...[
              _buildAnimatedItem(_buildStatsBar(), 3),
              const SizedBox(height: 12),
              _buildAnimatedItem(_buildMindmapTree(), 4),
              const SizedBox(height: 16),
              _buildAnimatedItem(_buildExportButton(), 5),
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
          const Text('中心主题', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          MiuixInput(controller: _topicController, hintText: '输入思维导图的中心主题，如：人工智能', prefixIcon: Icons.center_focus_strong),
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

  Widget _buildLevelSelector() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('展开层级', style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.pillRadius),
                child: Text('$_levelCount 层', style: const TextStyle(color: Colors.white, fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: MiuixColors.primary,
              inactiveTrackColor: MiuixColors.surfaceVariant,
              thumbColor: Colors.white,
              overlayColor: MiuixColors.primaryLight.withOpacity(0.3),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(value: _levelCount.toDouble(), min: 2, max: 4, divisions: 2, label: '$_levelCount层', onChanged: (val) => setState(() => _levelCount = val.toInt())),
          ),
          const Text('层级越多，思维导图越详细，但节点数量也会越多', style: TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: _isGenerating ? '生成中...' : '生成思维导图',
        icon: Icons.account_tree,
        type: MiuixButtonType.gradient,
        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
        size: MiuixButtonSize.large,
        loading: _isGenerating,
        onPressed: _isGenerating ? null : _generateMindmap,
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
        const Text('AI 正在构建思维导图...', style: TextStyle(fontSize: MiuixFontSize.md, color: MiuixColors.textSecondary)),
      ]),
    );
  }

  Widget _buildStatsBar() {
    final totalNodes = _countNodes(_mindmap);
    return Row(
      children: [
        Expanded(
          child: MiuixCard(
            style: MiuixCardStyle.gradient,
            gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('$totalNodes', '总节点'),
                Container(width: 1, height: 24, color: Colors.white.withOpacity(0.3)),
                _statItem('${(_mindmap['children'] as List).length}', '主分支'),
                Container(width: 1, height: 24, color: Colors.white.withOpacity(0.3)),
                _statItem('$_levelCount', '层级'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: MiuixFontSize.xl, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: MiuixFontSize.sm)),
      ],
    );
  }

  Widget _buildMindmapTree() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 中心节点
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
                borderRadius: MiuixRadius.pillRadius,
                boxShadow: MiuixShadows.md,
              ),
              child: Text(_mindmap['title'], style: const TextStyle(color: Colors.white, fontSize: MiuixFontSize.xl, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          // 连接线
          Center(child: Container(width: 2, height: 20, color: MiuixColors.primaryLight)),
          const SizedBox(height: 4),
          // 子节点
          ...List.generate((_mindmap['children'] as List).length, (index) {
            return _buildTreeNode(_mindmap['children'][index], 0, 'root_$index');
          }),
        ],
      ),
    );
  }

  Widget _buildTreeNode(Map<String, dynamic> node, int level, String key) {
    final hasChildren = node['children'] != null && (node['children'] as List).isNotEmpty;
    final isCollapsed = _collapsed.contains(key);
    final colors = [MiuixColors.primary, MiuixColors.primaryLight, const Color(0xFFFFA5C4), const Color(0xFFFFC0D6)];
    final color = colors[level.clamp(0, 3)];

    return Padding(
      padding: EdgeInsets.only(left: level * 16.0, top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (level > 0) Container(width: 12, height: 2, color: color.withOpacity(0.5)),
              MiuixRipple(
                borderRadius: MiuixRadius.sm,
                child: GestureDetector(
                  onTap: hasChildren ? () => _toggleNode(key) : null,
                  child: AnimatedContainer(
                    duration: MiuixDuration.fast,
                    padding: EdgeInsets.symmetric(horizontal: 12 + level * 2.0, vertical: 8),
                    decoration: BoxDecoration(
                      color: level == 0 ? color.withOpacity(0.15) : MiuixColors.surfaceVariant,
                      borderRadius: MiuixRadius.smRadius,
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasChildren) Icon(isCollapsed ? Icons.chevron_right : Icons.expand_more, size: 16, color: color),
                        if (hasChildren) const SizedBox(width: 4),
                        Icon(level == 0 ? Icons.folder : Icons.label, size: 14, color: color),
                        const SizedBox(width: 6),
                        Text(node['title'], style: TextStyle(fontSize: level == 0 ? MiuixFontSize.md : MiuixFontSize.sm, fontWeight: level == 0 ? FontWeight.w600 : FontWeight.w500, color: MiuixColors.textPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (hasChildren && !isCollapsed) ...[
            Padding(
              padding: EdgeInsets.only(left: level > 0 ? 12.0 : 0),
              child: Container(width: 2, height: 4, color: color.withOpacity(0.3)),
            ),
            ...List.generate((node['children'] as List).length, (childIndex) {
              return _buildTreeNode(node['children'][childIndex], level + 1, '${key}_$childIndex');
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: '导出思维导图 (Markdown)',
        icon: Icons.file_download,
        type: MiuixButtonType.primary,
        size: MiuixButtonSize.large,
        onPressed: _exportMindmap,
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
