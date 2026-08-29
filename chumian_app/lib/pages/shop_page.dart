import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/context_ext.dart';
import '../widgets/app_card.dart';
import '../widgets/feedback.dart';
import '../widgets/gradient_header.dart';
import '../widgets/buttons.dart';
import '../utils/formatters.dart';
import '../utils/constants.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});
  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  int _premiumPoints = 0;
  int _normalPoints = 0;
  final TextEditingController _exchangeCtrl = TextEditingController();
  bool _loading = true;
  bool _loadFailed = false;
  bool _exchanging = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _exchangeCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _load() async {
    setState(() {
      _loading = _premiumPoints == 0;
      _loadFailed = false;
    });
    try {
      final info = await ApiService.getUserInfo();
      if (!mounted) return;
      setState(() {
        _premiumPoints = info['premium_points'] ?? 0;
        _normalPoints = info['daily_points'] ?? 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _exchange() async {
    final amount = int.tryParse(_exchangeCtrl.text) ?? 0;
    if (amount <= 0) {
      _showSnack('请输入有效的数量');
      return;
    }
    if (amount > _premiumPoints) {
      _showSnack('高级积分不足');
      return;
    }
    setState(() => _exchanging = true);
    try {
      final result = await ApiService.exchangePoints(amount);
      if (!mounted) return;
      _showSnack('兑换成功，获得 ${result['normal_points_added']} 普通积分');
      _exchangeCtrl.clear();
      _load();
    } catch (e) {
      if (!mounted) return;
      _showSnack('兑换失败: ${ErrorMessages.of(e)}');
    } finally {
      if (mounted) setState(() => _exchanging = false);
    }
  }

  Future<void> _buySvip(String plan, int cost, String name) async {
    if (_premiumPoints < cost) {
      _showSnack('高级积分不足');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.workspace_premium_rounded, size: 40, color: ctx.warning),
        title: Text('购买 SVIP $name'),
        content: Text('确认花费 $cost 高级积分购买 SVIP $name？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ctx.warning,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认购买'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.buySvip(plan);
      if (!mounted) return;
      _showSnack('购买成功！');
      _load();
    } catch (e) {
      if (!mounted) return;
      _showSnack('购买失败: ${ErrorMessages.of(e)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('积分商店')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const ListSkeleton(items: 4);
    if (_loadFailed) {
      return ErrorRetry(message: '商店数据加载失败', onRetry: _load);
    }
    return AppRefreshable(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          GradientStatPanel(
            label: '我的高级积分',
            value: Formatters.formatPoints(_premiumPoints),
            icon: Icons.diamond_rounded,
            subtitle: '普通积分 ${Formatters.formatPoints(_normalPoints)}',
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4D8DFF), Color(0xFF7CB4FF)],
            ),
          ),
          SectionHeader(
            title: '积分兑换',
            subtitle: '1 高级积分 = 2000万 普通积分',
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _exchangeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '兑换数量（高级积分）',
                    hintText: '输入要兑换的高级积分数量',
                    prefixIcon: Icon(Icons.swap_horiz_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                GradientButton(
                  label: '立即兑换',
                  icon: Icons.swap_vert_rounded,
                  loading: _exchanging,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4D8DFF), Color(0xFF7CB4FF)],
                  ),
                  onPressed: _exchange,
                ),
              ],
            ),
          ),
          SectionHeader(
            title: 'SVIP 会员',
            subtitle: '开通会员享更多权益',
          ),
          _buildSvipCard(
            planId: 'monthly',
            name: '月卡',
            cost: 200,
            icon: Icons.star_rounded,
            color: const Color(0xFF4D8DFF),
            features: ['每日签到积分加成', '普通模型无限次数', '优先排队'],
          ),
          _buildSvipCard(
            planId: 'yearly',
            name: '年卡',
            cost: 2000,
            icon: Icons.workspace_premium_rounded,
            color: const Color(0xFF9C6ADE),
            features: ['月卡全部权益', '智能体数量翻倍', '专属客服通道'],
          ),
          _buildSvipCard(
            planId: 'lifetime',
            name: '终身',
            cost: 100000,
            icon: Icons.diamond_rounded,
            color: const Color(0xFFF5A623),
            features: ['年卡全部权益', '高质模型不限次', '新功能抢先体验'],
          ),
        ],
      ),
    );
  }

  Widget _buildSvipCard({
    required String planId,
    required String name,
    required int cost,
    required IconData icon,
    required Color color,
    required List<String> features,
  }) {
    final affordable = _premiumPoints >= cost;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: () => _buySvip(planId, cost, name),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'SVIP $name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    PillTag(
                      text: '$cost 高级积分',
                      color: color,
                      background: color.withValues(alpha: 0.12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: features
                      .map(
                        (f) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 12,
                              color: context.success,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              f,
                              style: TextStyle(
                                fontSize: 11,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              GradientButton(
                label: '购买',
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: affordable
                      ? [color, color.withValues(alpha: 0.7)]
                      : [context.textTertiary, context.textTertiary],
                ),
                onPressed: () => _buySvip(planId, cost, name),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
