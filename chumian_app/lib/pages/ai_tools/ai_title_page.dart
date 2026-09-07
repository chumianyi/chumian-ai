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
/// AITitlePage —— AI 标题生成
/// 内容摘要，平台选择(公众号/头条/知乎/小红书)
/// 风格(悬念/数字/疑问/情感)，生成多个标题，点击率预估
/// ============================================================
class AITitlePage extends StatefulWidget {
  const AITitlePage({super.key});

  @override
  State<AITitlePage> createState() => _AITitlePageState();
}

class _AITitlePageState extends State<AITitlePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  final TextEditingController _summaryController = TextEditingController();

  int _selectedPlatform = 0;
  int _selectedStyle = 0;
  bool _isGenerating = false;
  bool _hasResult = false;
  bool _hasError = false;
  String _errorMessage = \'\';
  List<Map<String, dynamic>> _titles = [];

  static const List<String> _platforms = ['公众号', '头条', '知乎', '小红书'];
  static const List<IconData> _platformIcons = [Icons.article, Icons.newspaper, Icons.psychology, Icons.book];
  static const List<String> _styles = ['悬念', '数字', '疑问', '情感'];
  static const List<IconData> _styleIcons = [Icons.help_outline, Icons.onetwothree, Icons.question_mark, Icons.favorite_border];
  static const List<String> _sampleSummaries = [
    '分享我从月薪3千到3万的转行经历，包括学习方法、面试技巧和职场建议',
    '测评最近很火的10款护肤品，告诉你哪些是真的好用哪些是智商税',
    '深度分析人工智能的发展趋势，以及普通人应该如何抓住AI时代的机遇',
    '记录我减肥30斤的全过程，包括饮食计划、运动方案和心态调整',
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
    _summaryController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: MiuixCurves.miuixSpring)));
    final slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: Curves.easeOutCubic)));
    return AnimatedBuilder(animation: animation, builder: (_, __) => Opacity(opacity: animation.value, child: Transform.translate(offset: slide.value, child: child)));
  }

  Future<void> _generateTitles() async {
    if (_summaryController.text.trim().isEmpty) {
      MiuixToast.show(context, message: '请输入内容摘要', type: MiuixToastType.warning);
      return;
    }
    setState(() {
      _isGenerating = true;
      _hasResult = false;
      _titles = [];
    });
    try {
      final result = await ApiService.aiToolComplete(
        systemPrompt: '你是一位标题创作专家。请根据用户提供的文章内容摘要，生成5-10个吸引人的标题，每条一行。',
        userInput: _contentController.text,
      );
      if (mounted) {
        _titles = result.split('\n').where((l) => l.trim().isNotEmpty).toList();
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

  List<Map<String, dynamic>> _buildTitleList() {
    final summary = _summaryController.text.trim();
    final platform = _platforms[_selectedPlatform];
    final style = _styles[_selectedStyle];
    final keyword = summary.length > 6 ? summary.substring(0, 6) : summary;

    Map<String, List<Map<String, dynamic>>> titlePool = {
      '悬念': [
        {'title': '我偷偷做了这件事，3个月后所有人都惊呆了', 'ctr': 8.5, 'reason': '制造神秘感，"偷偷做了这件事"引发好奇，"所有人都惊呆了"制造期待'},
        {'title': '为什么聪明人都在偷偷学这个？看完你就懂了', 'ctr': 7.8, 'reason': '"聪明人都在"制造从众心理，"看完你就懂了"承诺价值'},
        {'title': '那个从不加班的同事，后来怎么样了？', 'ctr': 9.2, 'reason': '反常识设定引发好奇，"后来怎么样了"是经典悬念句式'},
        {'title': '我花了3年才明白的道理，希望你早点知道', 'ctr': 7.5, 'reason': '"花了3年"增加可信度，"希望你早点知道"引发好奇和紧迫感'},
        {'title': '被删前赶紧看！这篇文章可能随时消失', 'ctr': 8.8, 'reason': '稀缺感+紧迫感，"被删前"制造危机感，点击率极高'},
      ],
      '数字': [
        {'title': '从月薪3千到3万，我只用了这5个方法', 'ctr': 9.0, 'reason': '具体数字对比制造冲击力，"5个方法"承诺可执行的干货'},
        {'title': '10个被90%的人忽略的细节，第3个最重要', 'ctr': 8.2, 'reason': '"10个"量化内容，"90%的人忽略"制造优越感，"第3个"引导阅读'},
        {'title': '坚持30天，我的生活发生了7个惊人变化', 'ctr': 8.6, 'reason': '"30天"可实现的时间周期，"7个惊人变化"承诺具体成果'},
        {'title': '年薪百万的人，都有这3个共同习惯', 'ctr': 9.3, 'reason': '"年薪百万"目标吸引，"3个共同习惯"简洁有力，可复制感强'},
        {'title': '读完这5本书，我的认知提升了不止一个档次', 'ctr': 7.6, 'reason': '"5本书"具体可操作，"认知提升"吸引成长型读者'},
      ],
      '疑问': [
        {'title': '为什么你越努力越穷？答案可能颠覆你的认知', 'ctr': 9.1, 'reason': '反常识问题引发思考，"颠覆认知"承诺新视角'},
        {'title': '普通人如何实现财务自由？这篇文章说透了', 'ctr': 8.7, 'reason': '"普通人"降低门槛，"财务自由"目标吸引，"说透了"承诺深度'},
        {'title': '你真的会学习吗？90%的人都在用错误的方法', 'ctr': 8.4, 'reason': '自我怀疑式提问，"90%的人都错"制造焦虑和优越感'},
        {'title': '30岁还没找到方向怎么办？过来人的真心话', 'ctr': 8.9, 'reason': '精准定位年龄焦虑，"过来人的真心话"增加可信度和亲切感'},
        {'title': '为什么你的努力总是白费？因为你忽略了这一点', 'ctr': 8.1, 'reason': '痛点提问+悬念，"忽略了这一点"引导点击寻找答案'},
      ],
      '情感': [
        {'title': '致每一个在深夜默默努力的你，辛苦了', 'ctr': 8.8, 'reason': '情感共鸣，"深夜默默努力"精准击中奋斗者，"辛苦了"温暖治愈'},
        {'title': '谢谢你，出现在我最糟糕的日子里', 'ctr': 9.0, 'reason': '感恩式标题，"最糟糕的日子"引发共鸣和故事好奇'},
        {'title': '成年人的崩溃，都是从"算了"开始的', 'ctr': 9.4, 'reason': '精准戳中成年人痛点，"算了"这个词引发强烈情感共鸣'},
        {'title': '愿你历尽千帆，归来仍是少年', 'ctr': 7.9, 'reason': '诗意表达，美好祝愿，适合情感类和成长类内容'},
        {'title': '那些打不倒你的，终将使你更强大', 'ctr': 8.3, 'reason': '励志金句，"打不倒"和"更强大"形成对比，传递力量感'},
      ],
    };

    var list = titlePool[style] ?? titlePool['悬念']!;
    // 根据平台微调
    if (platform == '小红书') {
      list = list.map((e) => {
        'title': '💕${e['title']}｜干货收藏',
        'ctr': (e['ctr'] as double) + 0.3,
        'reason': e['reason'],
      }).toList();
    } else if (platform == '知乎') {
      list = list.map((e) => {
        'title': '如何评价${e['title']}？',
        'ctr': (e['ctr'] as double) - 0.2,
        'reason': e['reason'],
      }).toList();
    }

    return list.take(5).toList();
  }

  Future<void> _copyTitle(String title) async {
    await Clipboard.setData(ClipboardData(text: title));
    if (mounted) MiuixToast.show(context, message: '已复制标题', type: MiuixToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(title: 'AI 标题生成', backgroundColor: MiuixColors.background),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedItem(_buildPlatformSelector(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildStyleSelector(), 1),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildSummaryInput(), 2),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildGenerateButton(), 3),
            const SizedBox(height: 20),
            if (_isGenerating) _buildAnimatedItem(_buildLoadingCard(), 4),
            if (_hasError) _buildAnimatedItem(_buildErrorCard(), 5),

            if (_hasResult) _buildAnimatedItem(_buildResultList(), 4),
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
          const Text('发布平台', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_platforms.length, (index) {
              final isSelected = _selectedPlatform == index;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 3 ? 6 : 0),
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

  Widget _buildStyleSelector() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('标题风格', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_styles.length, (index) {
              final isSelected = _selectedStyle == index;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 3 ? 8 : 0),
                  child: MiuixRipple(
                    borderRadius: MiuixRadius.md,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedStyle = index),
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
                        child: Column(
                          children: [
                            Icon(_styleIcons[index], size: 22, color: isSelected ? Colors.white : MiuixColors.primary),
                            const SizedBox(height: 6),
                            Text(_styles[index], style: TextStyle(fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : MiuixColors.textSecondary)),
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

  Widget _buildSummaryInput() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('内容摘要', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          MiuixInput(
            controller: _summaryController,
            hintText: '简要描述你的文章内容，AI将据此生成吸引人的标题...',
            prefixIcon: Icons.subject,
            maxLines: 4,
            minLines: 3,
            type: MiuixInputType.multiline,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_sampleSummaries.length, (index) {
              return MiuixChip(
                label: _sampleSummaries[index].length > 18 ? '${_sampleSummaries[index].substring(0, 18)}...' : _sampleSummaries[index],
                onTap: () => _summaryController.text = _sampleSummaries[index],
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
        label: _isGenerating ? '生成中...' : '生成标题',
        icon: Icons.title,
        type: MiuixButtonType.gradient,
        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
        size: MiuixButtonSize.large,
        loading: _isGenerating,
        onPressed: _isGenerating ? null : _generateTitles,
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
        const Text('AI 正在构思爆款标题...', style: TextStyle(fontSize: MiuixFontSize.md, color: MiuixColors.textSecondary)),
        const SizedBox(height: 8),
        Text('${_platforms[_selectedPlatform]} · ${_styles[_selectedStyle]}风格', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
      ]),
    );
  }

  Widget _buildResultList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.only(left: 4, bottom: 12), child: Text('推荐标题', style: TextStyle(fontSize: MiuixFontSize.xl, fontWeight: FontWeight.w700, color: MiuixColors.textPrimary))),
        ...List.generate(_titles.length, (index) {
          final item = _titles[index];
          final ctr = item['ctr'] as double;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MiuixCard(
              style: MiuixCardStyle.gradient,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: index == 0 ? [const Color(0xFFFFE0EC), const Color(0xFFFFD0E0)] : [const Color(0xFFFFF5F8), const Color(0xFFFFEEF3)],
              ),
              padding: const EdgeInsets.all(16),
              onTap: () => _copyTitle(item['title']),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.smRadius),
                        child: Center(child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                      ),
                      const SizedBox(width: 10),
                      if (index == 0) Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: MiuixColors.primary, borderRadius: MiuixRadius.pillRadius),
                        child: const Text('最佳推荐', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      MiuixIconButton(icon: Icons.copy, style: MiuixIconButtonStyle.outlined, size: 32, iconSize: 16, onPressed: () => _copyTitle(item['title'])),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(item['title'], style: const TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary, height: 1.5)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.trending_up, size: 16, color: MiuixColors.primary),
                      const SizedBox(width: 4),
                      Text('预估点击率 ${ctr.toStringAsFixed(1)}%', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.primary, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: MiuixRadius.pillRadius,
                          child: LinearProgressIndicator(
                            value: ctr / 10,
                            minHeight: 6,
                            backgroundColor: MiuixColors.surfaceVariant,
                            valueColor: const AlwaysStoppedAnimation(MiuixColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: MiuixRadius.smRadius),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 14, color: MiuixColors.primary),
                        const SizedBox(width: 4),
                        Expanded(child: Text(item['reason'], style: const TextStyle(fontSize: 11, color: MiuixColors.textSecondary, height: 1.5))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: MiuixButton(label: '换一批标题', icon: Icons.refresh, type: MiuixButtonType.secondary, onPressed: _generateTitles)),
      ],
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
