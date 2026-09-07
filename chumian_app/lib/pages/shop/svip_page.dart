import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// SvipPage —— SVIP 会员页
/// 会员权益展示，价格方案，购买按钮
/// 粉色渐变背景，会员标识动画
/// ============================================================
class SvipPage extends StatefulWidget {
  const SvipPage({super.key});

  @override
  State<SvipPage> createState() => _SvipPageState();
}

class _SvipPageState extends State<SvipPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _badgeController;

  int _selectedPlan = 1; // 0:月卡 1:季卡 2:年卡
  bool _isPurchasing = false;

  static const List<MembershipPlan> _plans = [
    MembershipPlan(name: '月卡', price: '18', originalPrice: '25', duration: '30天', badge: ''),
    MembershipPlan(name: '季卡', price: '48', originalPrice: '75', duration: '90天', badge: '推荐'),
    MembershipPlan(name: '年卡', price: '168', originalPrice: '216', duration: '365天', badge: '超值'),
  ];

  static const List<BenefitItem> _benefits = [
    BenefitItem(icon: Icons.all_inclusive, title: '无限AI对话', desc: '不限次数使用AI对话功能'),
    BenefitItem(icon: Icons.brush, title: 'AI绘画特权', desc: '每月100次AI绘画额度'),
    BenefitItem(icon: Icons.code, title: 'AI代码助手', desc: '高级代码生成和解释'),
    BenefitItem(icon: Icons.auto_awesome, title: '高级模型', desc: '优先使用最新AI模型'),
    BenefitItem(icon: Icons.download, title: '高清下载', desc: '无水印高清图片下载'),
    BenefitItem(icon: Icons.workspace_premium, title: '专属标识', desc: 'SVIP专属头像框和标识'),
    BenefitItem(icon: Icons.support_agent, title: '优先客服', desc: '专属客服优先响应'),
    BenefitItem(icon: Icons.card_giftcard, title: '生日礼包', desc: '生日当月领取专属礼包'),
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.06, (index * 0.06) + 0.4,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.06, (index * 0.06) + 0.4,
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

  Future<void> _purchase() async {
    setState(() => _isPurchasing = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() => _isPurchasing = false);
    MiuixToast.show(context,
        message: '开通成功！欢迎加入SVIP', type: MiuixToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(),
            ),
            leading: MiuixIconButton(
              icon: Icons.arrow_back,
              style: MiuixIconButtonStyle.glass,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildAnimatedItem(_buildPlansSection(), 0),
                const SizedBox(height: 16),
                _buildAnimatedItem(_buildBenefitsSection(), 1),
                const SizedBox(height: 16),
                _buildAnimatedItem(_buildFaqSection(), 2),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildPurchaseBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD700),
            Color(0xFFFFA500),
            Color(0xFFFF6B9D),
            Color(0xFFFF5588),
          ],
        ),
      ),
      child: Stack(
        children: [
          // 装饰粒子
          ...List.generate(20, (index) {
            final random = math.Random(index);
            return Positioned(
              left: random.nextDouble() * 400,
              top: random.nextDouble() * 280,
              child: AnimatedBuilder(
                animation: _badgeController,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.3 +
                        0.3 *
                            math.sin(_badgeController.value * 2 * math.pi + index),
                    child: Icon(
                      Icons.star,
                      size: 8 + random.nextDouble() * 12,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            );
          }),
          // 主内容
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // 旋转的SVIP标识
                AnimatedBuilder(
                  animation: _badgeController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _badgeController.value * 0.1 * math.sin(
                          _badgeController.value * 2 * math.pi),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: MiuixRadius.pillRadius,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium,
                                color: Colors.white, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'SVIP 会员',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: MiuixFontSize.xl,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  '解锁全部高级功能',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MiuixFontSize.md,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '已有 128,560 位用户开通',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: MiuixFontSize.sm,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择套餐',
            style: TextStyle(
              fontSize: MiuixFontSize.lg,
              fontWeight: FontWeight.w600,
              color: MiuixColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_plans.length, (index) {
              final plan = _plans[index];
              final isSelected = _selectedPlan == index;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 2 ? 10 : 0),
                  child: MiuixRipple(
                    borderRadius: MiuixRadius.lg,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPlan = index),
                      child: AnimatedContainer(
                        duration: MiuixDuration.fast,
                        curve: MiuixCurves.miuixSpring,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFFD700),
                                    Color(0xFFFFA500),
                                  ],
                                )
                              : null,
                          color: isSelected ? null : MiuixColors.surface,
                          borderRadius: MiuixRadius.lgRadius,
                          border: Border.all(
                            color: isSelected
                                ? MiuixColors.warning
                                : MiuixColors.borderLight,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected ? MiuixShadows.md : null,
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            if (plan.badge.isNotEmpty)
                              Positioned(
                                top: -10,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 2),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                          colors: MiuixColors.primaryGradient),
                                      borderRadius: MiuixRadius.pillRadius,
                                    ),
                                    child: Text(
                                      plan.badge,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Column(
                              children: [
                                Text(
                                  plan.name,
                                  style: TextStyle(
                                    fontSize: MiuixFontSize.md,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : MiuixColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '¥',
                                      style: TextStyle(
                                        fontSize: MiuixFontSize.md,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : MiuixColors.primary,
                                      ),
                                    ),
                                    Text(
                                      plan.price,
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : MiuixColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '原价¥${plan.originalPrice}',
                                  style: TextStyle(
                                    fontSize: MiuixFontSize.xs,
                                    color: isSelected
                                        ? Colors.white.withOpacity(0.7)
                                        : MiuixColors.textTertiary,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  plan.duration,
                                  style: TextStyle(
                                    fontSize: MiuixFontSize.xs,
                                    color: isSelected
                                        ? Colors.white.withOpacity(0.9)
                                        : MiuixColors.textSecondary,
                                  ),
                                ),
                              ],
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
    );
  }

  Widget _buildBenefitsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MiuixCard(
        style: MiuixCardStyle.surface,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.card_giftcard, color: MiuixColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  '会员权益',
                  style: TextStyle(
                    fontSize: MiuixFontSize.lg,
                    fontWeight: FontWeight.w600,
                    color: MiuixColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _benefits.length,
              itemBuilder: (context, index) {
                final benefit = _benefits[index];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: MiuixColors.surfaceVariant,
                    borderRadius: MiuixRadius.mdRadius,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient:
                              const LinearGradient(colors: MiuixColors.primaryGradient),
                          borderRadius: MiuixRadius.smRadius,
                        ),
                        child: Icon(benefit.icon,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              benefit.title,
                              style: const TextStyle(
                                fontSize: MiuixFontSize.sm,
                                fontWeight: FontWeight.w600,
                                color: MiuixColors.textPrimary,
                              ),
                            ),
                            Text(
                              benefit.desc,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: MiuixColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MiuixCard(
        style: MiuixCardStyle.surface,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.help_outline, color: MiuixColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  '常见问题',
                  style: TextStyle(
                    fontSize: MiuixFontSize.lg,
                    fontWeight: FontWeight.w600,
                    color: MiuixColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFaqItem('SVIP会员可以退款吗？', '开通后7天内未使用可申请全额退款，超过7天按使用天数折算。'),
            _buildFaqItem('会员到期后数据会保留吗？', '会员到期后，您的所有数据和创作内容都会保留，只是高级功能无法使用。'),
            _buildFaqItem('可以赠送会员给好友吗？', '支持赠送功能，在购买时选择"赠送好友"即可。'),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text(
        question,
        style: const TextStyle(
          fontSize: MiuixFontSize.md,
          fontWeight: FontWeight.w500,
          color: MiuixColors.textPrimary,
        ),
      ),
      iconColor: MiuixColors.primary,
      children: [
        Text(
          answer,
          style: const TextStyle(
            fontSize: MiuixFontSize.sm,
            color: MiuixColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseBar() {
    final plan = _plans[_selectedPlan];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: MiuixColors.surface,
        boxShadow: [
          BoxShadow(
            color: MiuixColors.shadowSoft,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '¥',
                      style: TextStyle(
                        fontSize: MiuixFontSize.md,
                        fontWeight: FontWeight.bold,
                        color: MiuixColors.primary,
                      ),
                    ),
                    Text(
                      plan.price,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: MiuixColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '/ ${plan.duration}',
                      style: const TextStyle(
                        fontSize: MiuixFontSize.sm,
                        color: MiuixColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '立省¥${int.parse(plan.originalPrice) - int.parse(plan.price)}',
                  style: const TextStyle(
                    fontSize: MiuixFontSize.xs,
                    color: MiuixColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MiuixButton(
                label: _isPurchasing ? '开通中...' : '立即开通',
                icon: Icons.workspace_premium,
                type: MiuixButtonType.gradient,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                size: MiuixButtonSize.large,
                loading: _isPurchasing,
                onPressed: _isPurchasing ? null : _purchase,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MembershipPlan {
  final String name;
  final String price;
  final String originalPrice;
  final String duration;
  final String badge;
  const MembershipPlan({
    required this.name,
    required this.price,
    required this.originalPrice,
    required this.duration,
    required this.badge,
  });
}

class BenefitItem {
  final IconData icon;
  final String title;
  final String desc;
  const BenefitItem({
    required this.icon,
    required this.title,
    required this.desc,
  });
}
