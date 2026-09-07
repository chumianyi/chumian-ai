import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_input.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// HelpCenterPage —— 帮助中心
/// FAQ 分类列表，常见问题展开，联系客服，反馈入口
/// 粉色主题，错落入场动画
/// ============================================================

class FAQCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<FAQItem> items;

  const FAQCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });
}

class FAQItem {
  final String question;
  final String answer;

  const FAQItem({required this.question, required this.answer});
}

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  final TextEditingController _searchController = TextEditingController();
  int _expandedCategory = -1;
  int _expandedFAQ = -1;
  String _searchQuery = '';

  static const List<FAQCategory> _categories = [
    FAQCategory(
      title: '账号与登录',
      icon: Icons.person_outline,
      color: MiuixColors.primary,
      items: [
        FAQItem(
          question: '如何注册初眠AI账号？',
          answer: '您可以通过手机号、邮箱或第三方账号（微信/QQ/抖音）快速注册。打开应用后点击"注册"按钮，按照提示完成验证即可。',
        ),
        FAQItem(
          question: '忘记密码怎么办？',
          answer: '在登录页面点击"忘记密码"，通过注册时绑定的手机号或邮箱接收验证码，即可重置密码。',
        ),
        FAQItem(
          question: '如何修改绑定的手机号？',
          answer: '进入"我的-设置-账号安全-手机号"，点击"更换"，先验证原手机号，再输入新手机号完成验证即可。',
        ),
      ],
    ),
    FAQCategory(
      title: '聊天与AI',
      icon: Icons.chat_bubble_outline,
      color: MiuixColors.info,
      items: [
        FAQItem(
          question: '如何开启联网搜索？',
          answer: '在聊天输入框上方有一个"联网搜索"胶囊按钮，点击即可开启。开启后AI回复会引用实时搜索结果。',
        ),
        FAQItem(
          question: '如何切换AI模型？',
          answer: '点击聊天顶栏右上角的模型名称胶囊，在弹出的菜单中选择您需要的模型。不同模型适用于不同场景。',
        ),
        FAQItem(
          question: '聊天记录会被保存吗？',
          answer: '您的聊天记录会安全地保存在服务器上，仅您本人可见。您可以在设置中导出或清除聊天记录。',
        ),
        FAQItem(
          question: '如何停止AI正在生成的回复？',
          answer: '在AI生成回复时，输入栏右侧的发送按钮会变为停止按钮，点击即可立即停止生成。',
        ),
      ],
    ),
    FAQCategory(
      title: '会员与支付',
      icon: Icons.card_membership_outlined,
      color: MiuixColors.warning,
      items: [
        FAQItem(
          question: 'SVIP会员有哪些权益？',
          answer: 'SVIP会员享受：无限次AI对话、优先使用最新模型、高清AI绘画、专属客服通道、去广告等多项权益。',
        ),
        FAQItem(
          question: '如何退款？',
          answer: '如对服务不满意，可在购买后7天内联系客服申请退款。退款将在3-5个工作日内原路返回。',
        ),
      ],
    ),
    FAQCategory(
      title: '社区与互动',
      icon: Icons.people_outline,
      color: MiuixColors.success,
      items: [
        FAQItem(
          question: '如何发布帖子？',
          answer: '进入社区页面，点击右下角的"发帖"按钮，填写标题和内容后即可发布。首次发帖需要完成实名认证。',
        ),
        FAQItem(
          question: '如何屏蔽用户？',
          answer: '在用户主页点击右上角"..."菜单，选择"屏蔽"即可。被屏蔽的用户无法与您互动，您也不会看到其内容。',
        ),
      ],
    ),
    FAQCategory(
      title: '其他问题',
      icon: Icons.help_outline,
      color: MiuixColors.textSecondary,
      items: [
        FAQItem(
          question: '初眠AI支持哪些平台？',
          answer: '初眠AI目前支持Android、iOS、Web和桌面端（Windows/macOS），所有平台数据实时同步。',
        ),
        FAQItem(
          question: '如何联系人工客服？',
          answer: '您可以通过"设置-联系我们"页面找到客服邮箱、QQ群和公众号，工作时间内通常会在2小时内回复。',
        ),
      ],
    ),
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
    _searchController.dispose();
    super.dispose();
  }

  List<FAQCategory> get _filteredCategories {
    if (_searchQuery.isEmpty) return _categories;
    return _categories
        .map((cat) => FAQCategory(
              title: cat.title,
              icon: cat.icon,
              color: cat.color,
              items: cat.items
                  .where((item) =>
                      item.question.contains(_searchQuery) ||
                      item.answer.contains(_searchQuery))
                  .toList(),
            ))
        .where((cat) => cat.items.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '帮助中心',
        actions: [
          MiuixIconButton(
            icon: Icons.headset_mic_outlined,
            style: MiuixIconButtonStyle.ghost,
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(MiuixSpacing.md),
              children: [
                _buildQuickActions(),
                const SizedBox(height: MiuixSpacing.lg),
                ..._filteredCategories.asMap().entries.map((entry) {
                  return _buildCategorySection(entry.value, entry.key);
                }),
                const SizedBox(height: MiuixSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MiuixSpacing.md,
        MiuixSpacing.sm,
        MiuixSpacing.md,
        MiuixSpacing.sm,
      ),
      child: MiuixInput(
        controller: _searchController,
        hintText: '搜索帮助问题...',
        prefixIcon: Icons.search,
        type: MiuixInputType.search,
        onChanged: (value) => setState(() => _searchQuery = value),
        showClearButton: true,
        onClear: () {
          _searchController.clear();
          setState(() => _searchQuery = '');
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return FadeTransition(
      opacity: _entryController,
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.headset_mic,
              title: '在线客服',
              subtitle: '9:00-22:00',
              color: MiuixColors.primary,
            ),
          ),
          const SizedBox(width: MiuixSpacing.md),
          Expanded(
            child: _buildQuickActionCard(
              icon: Icons.feedback_outlined,
              title: '意见反馈',
              subtitle: '告诉我们',
              color: MiuixColors.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return MiuixRipple(
      onTap: () {},
      borderRadius: MiuixRadius.lg,
      child: Container(
        padding: const EdgeInsets.all(MiuixSpacing.md),
        decoration: BoxDecoration(
          color: MiuixColors.surface,
          borderRadius: MiuixRadius.lgRadius,
          border: Border.all(color: MiuixColors.borderLight, width: 1),
          boxShadow: MiuixShadows.xs,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: MiuixRadius.smRadius,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: MiuixSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.sm,
                    fontWeight: FontWeight.w600,
                    color: MiuixColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.xs,
                    color: MiuixColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(FAQCategory category, int index) {
    final anim = CurvedAnimation(
      parent: _entryController,
      curve: Interval(
        0.1 + index * 0.06,
        1.0,
        curve: MiuixCurves.easeOut,
      ),
    );
    final isExpanded = _expandedCategory == index;

    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(anim),
        child: Padding(
          padding: const EdgeInsets.only(bottom: MiuixSpacing.md),
          child: MiuixCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                MiuixRipple(
                  onTap: () => setState(() {
                    _expandedCategory = isExpanded ? -1 : index;
                    _expandedFAQ = -1;
                  }),
                  borderRadius: MiuixRadius.lg,
                  child: Padding(
                    padding: const EdgeInsets.all(MiuixSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: category.color.withValues(alpha: 0.1),
                            borderRadius: MiuixRadius.smRadius,
                          ),
                          child: Icon(category.icon, size: 18, color: category.color),
                        ),
                        const SizedBox(width: MiuixSpacing.md),
                        Expanded(
                          child: Text(
                            category.title,
                            style: const TextStyle(
                              fontSize: MiuixFontSize.md,
                              fontWeight: FontWeight.w600,
                              color: MiuixColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${category.items.length}个问题',
                          style: const TextStyle(
                            fontSize: MiuixFontSize.xs,
                            color: MiuixColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: MiuixSpacing.sm),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: MiuixDuration.fast,
                          child: const Icon(
                            Icons.expand_more,
                            size: 20,
                            color: MiuixColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isExpanded)
                  ...category.items.asMap().entries.map((entry) {
                    return _buildFAQItem(entry.value, entry.key, index);
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(FAQItem item, int faqIndex, int catIndex) {
    final isExpanded = _expandedFAQ == faqIndex && _expandedCategory == catIndex;

    return Column(
      children: [
        Container(
          height: 1,
          color: MiuixColors.divider,
          margin: const EdgeInsets.symmetric(horizontal: MiuixSpacing.md),
        ),
        MiuixRipple(
          onTap: () => setState(() {
            _expandedFAQ = isExpanded ? -1 : faqIndex;
          }),
          borderRadius: MiuixRadius.md,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MiuixSpacing.md,
              vertical: MiuixSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.question,
                        style: TextStyle(
                          fontSize: MiuixFontSize.sm,
                          fontWeight: isExpanded ? FontWeight.w600 : FontWeight.w500,
                          color: isExpanded ? MiuixColors.primary : MiuixColors.textPrimary,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: MiuixDuration.fast,
                      child: Icon(
                        Icons.expand_more,
                        size: 18,
                        color: isExpanded ? MiuixColors.primary : MiuixColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: MiuixSpacing.sm),
                  Text(
                    item.answer,
                    style: const TextStyle(
                      fontSize: MiuixFontSize.sm,
                      color: MiuixColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: MiuixSpacing.sm),
                  Row(
                    children: [
                      const Text(
                        '这个回答有帮助吗？',
                        style: TextStyle(fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary),
                      ),
                      const SizedBox(width: MiuixSpacing.sm),
                      MiuixRipple(
                        onTap: () {},
                        borderRadius: MiuixRadius.pill,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: MiuixColors.success.withValues(alpha: 0.1),
                            borderRadius: MiuixRadius.pillRadius,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.thumb_up, size: 12, color: MiuixColors.success),
                              SizedBox(width: 4),
                              Text('有帮助', style: TextStyle(fontSize: 10, color: MiuixColors.success)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: MiuixSpacing.xs),
                      MiuixRipple(
                        onTap: () {},
                        borderRadius: MiuixRadius.pill,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: MiuixColors.error.withValues(alpha: 0.1),
                            borderRadius: MiuixRadius.pillRadius,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.thumb_down, size: 12, color: MiuixColors.error),
                              SizedBox(width: 4),
                              Text('没帮助', style: TextStyle(fontSize: 10, color: MiuixColors.error)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
