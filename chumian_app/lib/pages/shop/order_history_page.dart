import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_empty_state.dart';

/// ============================================================
/// OrderHistoryPage —— 订单记录
/// 兑换历史列表，订单状态，商品信息，粉色卡片，时间线
/// ============================================================
class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  List<OrderItem> _orders = [];
  bool _isLoading = true;
  int _selectedFilter = 0;

  static const List<String> _filters = ['全部', '待发货', '已完成', '已取消'];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _loadOrders();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _orders = [
        OrderItem(
          id: 'ORD202401001',
          productName: 'SVIP月卡',
          productDesc: '初眠AI SVIP会员 30天',
          points: 5000,
          status: 'completed',
          time: DateTime.now().subtract(const Duration(days: 1)),
          icon: Icons.workspace_premium,
          gradient: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        OrderItem(
          id: 'ORD202401002',
          productName: '初眠AI定制T恤',
          productDesc: '粉色限定款 M码',
          points: 2000,
          status: 'shipping',
          time: DateTime.now().subtract(const Duration(days: 2)),
          icon: Icons.checkroom,
          gradient: [Color(0xFFFF6B9D), Color(0xFFFF5588)],
        ),
        OrderItem(
          id: 'ORD202401003',
          productName: '积分大礼包',
          productDesc: '1000积分 + 抽奖机会x3',
          points: 800,
          status: 'completed',
          time: DateTime.now().subtract(const Duration(days: 5)),
          icon: Icons.card_giftcard,
          gradient: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
        ),
        OrderItem(
          id: 'ORD202401004',
          productName: '吉祥物周边套装',
          productDesc: '钥匙扣+贴纸+明信片',
          points: 1500,
          status: 'completed',
          time: DateTime.now().subtract(const Duration(days: 8)),
          icon: Icons.toys,
          gradient: [Color(0xFF03A9F4), Color(0xFF4FC3F7)],
        ),
        OrderItem(
          id: 'ORD202401005',
          productName: 'AI绘画次数包',
          productDesc: '50次AI绘画额度',
          points: 300,
          status: 'cancelled',
          time: DateTime.now().subtract(const Duration(days: 12)),
          icon: Icons.image,
          gradient: [Color(0xFF4CAF50), Color(0xFF81C784)],
        ),
        OrderItem(
          id: 'ORD202401006',
          productName: 'SVIP季卡',
          productDesc: '初眠AI SVIP会员 90天',
          points: 12000,
          status: 'completed',
          time: DateTime.now().subtract(const Duration(days: 20)),
          icon: Icons.workspace_premium,
          gradient: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
      ];
      _isLoading = false;
    });
  }

  List<OrderItem> get _filteredOrders {
    if (_selectedFilter == 0) return _orders;
    final statusMap = {1: 'shipping', 2: 'completed', 3: 'cancelled'};
    return _orders
        .where((o) => o.status == statusMap[_selectedFilter])
        .toList();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.06, (index * 0.06) + 0.35,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0.04, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.06, (index * 0.06) + 0.35,
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

  String _getStatusText(String status) {
    switch (status) {
      case 'shipping':
        return '待发货';
      case 'completed':
        return '已完成';
      case 'cancelled':
        return '已取消';
      default:
        return '未知';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'shipping':
        return MiuixColors.warning;
      case 'completed':
        return MiuixColors.success;
      case 'cancelled':
        return MiuixColors.textTertiary;
      default:
        return MiuixColors.textSecondary;
    }
  }

  String _formatDate(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '订单记录',
        backgroundColor: MiuixColors.background,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(MiuixColors.primary),
                    ),
                  )
                : _filteredOrders.isEmpty
                    ? const MiuixEmptyState(
                        title: '暂无订单',
                        description: '去积分商城兑换心仪的商品吧',
                        icon: Icons.shopping_bag_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, index) {
                          return _buildAnimatedItem(
                            _buildOrderCard(_filteredOrders[index]),
                            index,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = _selectedFilter == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: MiuixRipple(
              borderRadius: MiuixRadius.pill,
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = index),
                child: AnimatedContainer(
                  duration: MiuixDuration.fast,
                  curve: MiuixCurves.miuixSpring,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(colors: MiuixColors.primaryGradient)
                        : null,
                    color: isSelected ? null : MiuixColors.surface,
                    borderRadius: MiuixRadius.pillRadius,
                    border: Border.all(
                      color: isSelected
                          ? MiuixColors.primary
                          : MiuixColors.borderLight,
                    ),
                  ),
                  child: Text(
                    _filters[index],
                    style: TextStyle(
                      fontSize: MiuixFontSize.sm,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : MiuixColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOrderCard(OrderItem order) {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // 订单头
          Row(
            children: [
              Text(
                '订单号：${order.id}',
                style: const TextStyle(
                  fontSize: MiuixFontSize.xs,
                  color: MiuixColors.textTertiary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withValues(alpha: 0.1),
                  borderRadius: MiuixRadius.pillRadius,
                ),
                child: Text(
                  _getStatusText(order.status),
                  style: TextStyle(
                    fontSize: MiuixFontSize.xs,
                    color: _getStatusColor(order.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 商品信息
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: order.gradient),
                  borderRadius: MiuixRadius.lgRadius,
                ),
                child: Center(
                  child: Icon(order.icon, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.productName,
                      style: const TextStyle(
                        fontSize: MiuixFontSize.md,
                        fontWeight: FontWeight.w600,
                        color: MiuixColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.productDesc,
                      style: const TextStyle(
                        fontSize: MiuixFontSize.sm,
                        color: MiuixColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.stars,
                            size: 14, color: MiuixColors.primary),
                        const SizedBox(width: 2),
                        Text(
                          '${order.points} 积分',
                          style: const TextStyle(
                            fontSize: MiuixFontSize.sm,
                            color: MiuixColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 时间线
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: MiuixColors.surfaceVariant,
              borderRadius: MiuixRadius.smRadius,
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time,
                    size: 14, color: MiuixColors.textTertiary),
                const SizedBox(width: 6),
                Text(
                  _formatDate(order.time),
                  style: const TextStyle(
                    fontSize: MiuixFontSize.xs,
                    color: MiuixColors.textTertiary,
                  ),
                ),
                const Spacer(),
                if (order.status == 'shipping')
                  GestureDetector(
                    onTap: () {
                      MiuixToast.show(context,
                          message: '查看物流信息', type: MiuixToastType.info);
                    },
                    child: const Text(
                      '查看物流 >',
                      style: TextStyle(
                        fontSize: MiuixFontSize.xs,
                        color: MiuixColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (order.status == 'completed')
                  GestureDetector(
                    onTap: () {
                      MiuixToast.show(context,
                          message: '申请售后', type: MiuixToastType.info);
                    },
                    child: const Text(
                      '申请售后 >',
                      style: TextStyle(
                        fontSize: MiuixFontSize.xs,
                        color: MiuixColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrderItem {
  final String id;
  final String productName;
  final String productDesc;
  final int points;
  final String status;
  final DateTime time;
  final IconData icon;
  final List<Color> gradient;
  const OrderItem({
    required this.id,
    required this.productName,
    required this.productDesc,
    required this.points,
    required this.status,
    required this.time,
    required this.icon,
    required this.gradient,
  });
}
