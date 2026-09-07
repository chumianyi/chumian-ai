import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_glass.dart';
import 'package:chumian_ai/services/api_service.dart';

/// ============================================================
/// ShopPage —— 积分商城
/// 商品列表(SVIP/积分包/装扮) + 商品卡片 + 兑换按钮 + 支付弹窗
/// ============================================================
class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _userPoints = 90000000;

  static const List<String> _tabs = ['SVIP会员', '积分包', '装扮'];

  static const List<ShopItem> _svipItems = [
    ShopItem(id: 'svip_month', title: 'SVIP月卡', desc: '30天SVIP会员权益', price: 5000, originalPrice: 6000, icon: Icons.workspace_premium, tag: '热门'),
    ShopItem(id: 'svip_quarter', title: 'SVIP季卡', desc: '90天SVIP会员权益', price: 13800, originalPrice: 18000, icon: Icons.workspace_premium, tag: '超值'),
    ShopItem(id: 'svip_year', title: 'SVIP年卡', desc: '365天SVIP会员权益', price: 48800, originalPrice: 72000, icon: Icons.workspace_premium, tag: '推荐'),
  ];

  static const List<ShopItem> _pointItems = [
    ShopItem(id: 'points_1000', title: '1000积分', desc: '即时到账', price: 0, icon: Icons.stars, isMoney: true, moneyPrice: '¥6'),
    ShopItem(id: 'points_5000', title: '5000积分', desc: '即时到账，送500', price: 0, icon: Icons.stars, isMoney: true, moneyPrice: '¥28'),
    ShopItem(id: 'points_10000', title: '10000积分', desc: '即时到账，送2000', price: 0, icon: Icons.stars, isMoney: true, moneyPrice: '¥58'),
  ];

  static const List<ShopItem> _decoItems = [
    ShopItem(id: 'deco_pink', title: '粉色主题', desc: '专属粉色界面主题', price: 2000, icon: Icons.palette, tag: '新品'),
    ShopItem(id: 'deco_avatar', title: '限定头像框', desc: '初眠周年纪念头像框', price: 3000, icon: Icons.face, tag: '限定'),
    ShopItem(id: 'deco_bubble', title: '聊天气泡', desc: '粉色渐变聊天气泡', price: 1500, icon: Icons.chat_bubble),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onExchange(ShopItem item) {
    if (item.isMoney) {
      _showPayDialog(item);
    } else if (_userPoints >= item.price) {
      _showConfirmDialog(item);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('积分不足，快去赚取更多积分吧！'), backgroundColor: MiuixColors.error, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius)),
      );
    }
  }

  void _showConfirmDialog(ShopItem item) {
    showDialog(context: context, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: MiuixRadius.lgRadius),
      title: Text('确认兑换'),
      content: Text('确定使用 ${item.price} 积分兑换「${item.title}」吗？'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('取消', style: TextStyle(color: MiuixColors.textSecondary))),
        TextButton(onPressed: () {
          Navigator.pop(context);
          setState(() => _userPoints -= item.price);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('兑换成功！${item.title}已到账'), backgroundColor: MiuixColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius)));
        }, child: Text('确定', style: TextStyle(color: MiuixColors.primary))),
      ],
    ));
  }

  void _showPayDialog(ShopItem item) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(
      decoration: BoxDecoration(color: MiuixColors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(MiuixRadius.xl))),
      child: SafeArea(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: MiuixColors.border, borderRadius: MiuixRadius.pillRadius)),
          const SizedBox(height: 16),
          Text('确认支付', style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.xl, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          MiuixGlassContainer(borderRadius: MiuixRadius.md, padding: const EdgeInsets.all(16), child: Row(children: [
            Icon(item.icon, color: MiuixColors.primary, size: 32),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600)),
              Text(item.desc, style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.sm)),
            ])),
            Text(item.moneyPrice ?? '', style: TextStyle(color: MiuixColors.primary, fontSize: MiuixFontSize.xl, fontWeight: FontWeight.bold)),
          ])),
          const SizedBox(height: 20),
          MiuixRipple(borderRadius: MiuixRadius.pill, child: GestureDetector(onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('支付成功！${item.title}已到账'), backgroundColor: MiuixColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius)));
          }, child: Container(width: double.infinity, height: 50, decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.pillRadius, boxShadow: MiuixShadows.md), child: Center(child: Text('立即支付 ${item.moneyPrice}', style: const TextStyle(color: Colors.white, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600)))))),
          const SizedBox(height: 12),
        ]),
      )),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: AppBar(
        backgroundColor: MiuixColors.surface, elevation: 0, scrolledUnderElevation: 0, centerTitle: true,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: MiuixColors.primary), onPressed: () => Navigator.pop(context)),
        title: Text('积分商城', style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.xl, fontWeight: FontWeight.w600)),
        actions: [Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(color: MiuixColors.primary.withOpacity(0.1), borderRadius: MiuixRadius.pillRadius), child: Row(children: [Icon(Icons.stars, color: MiuixColors.primary, size: 16), const SizedBox(width: 4), Text('$_userPoints', style: TextStyle(color: MiuixColors.primary, fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w600))]))],
        bottom: TabBar(controller: _tabController, indicatorColor: MiuixColors.primary, indicatorWeight: 3, indicatorSize: TabBarIndicatorSize.label, labelColor: MiuixColors.primary, unselectedLabelColor: MiuixColors.textTertiary, labelStyle: const TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600), tabs: _tabs.map((t) => Tab(text: t)).toList()),
      ),
      body: TabBarView(controller: _tabController, children: [
        _buildItemList(_svipItems),
        _buildItemList(_pointItems),
        _buildItemList(_decoItems),
      ]),
    );
  }

  Widget _buildItemList(List<ShopItem> items) {
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: items.length, itemBuilder: (context, index) {
      final item = items[index];
      return TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: 1), duration: MiuixDuration.normal, curve: Interval(index * 0.1, index * 0.1 + 0.9, curve: MiuixCurves.easeOut), builder: (context, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, (1 - value) * 20), child: child)), child: _buildItemCard(item));
    });
  }

  Widget _buildItemCard(ShopItem item) {
    return MiuixRipple(
      borderRadius: MiuixRadius.lg,
      child: MiuixGlassContainer(margin: const EdgeInsets.only(bottom: 12), borderRadius: MiuixRadius.lg, padding: const EdgeInsets.all(16), child: Row(children: [
        Stack(children: [
          Container(width: 64, height: 64, decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.softGradient), borderRadius: MiuixRadius.mdRadius), child: Icon(item.icon, color: MiuixColors.primary, size: 32)),
          if (item.tag != null) Positioned(top: -4, right: -4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.xsRadius), child: Text(item.tag!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)))),
        ]),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.title, style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(item.desc, style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.sm)),
          const SizedBox(height: 6),
          Row(children: [
            if (!item.isMoney) ...[Text('${item.price}', style: TextStyle(color: MiuixColors.primary, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.bold)), const SizedBox(width: 2), Icon(Icons.stars, color: MiuixColors.primary, size: 14), const SizedBox(width: 8)],
            if (item.originalPrice > 0) Text('${item.originalPrice}', style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.sm, decoration: TextDecoration.lineThrough)),
            if (item.isMoney) Text(item.moneyPrice ?? '', style: TextStyle(color: MiuixColors.primary, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.bold)),
          ]),
        ])),
        MiuixRipple(borderRadius: MiuixRadius.pill, child: GestureDetector(onTap: () => _onExchange(item), child: Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8), decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.pillRadius, boxShadow: MiuixShadows.sm), child: Text(item.isMoney ? '购买' : '兑换', style: const TextStyle(color: Colors.white, fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w600))))),
      ])),
    );
  }
}

class ShopItem {
  const ShopItem({required this.id, required this.title, required this.desc, required this.price, this.originalPrice = 0, required this.icon, this.tag, this.isMoney = false, this.moneyPrice});
  final String id;
  final String title;
  final String desc;
  final int price;
  final int originalPrice;
  final IconData icon;
  final String? tag;
  final bool isMoney;
  final String? moneyPrice;
}
