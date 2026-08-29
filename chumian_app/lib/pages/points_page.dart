import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/context_ext.dart';
import '../widgets/app_card.dart';
import '../widgets/feedback.dart';
import '../widgets/gradient_header.dart';
import '../widgets/tiles.dart';
import '../utils/formatters.dart';
import 'checkin_page.dart';
import 'shop_page.dart';

class PointsPage extends StatefulWidget {
  const PointsPage({super.key});
  @override
  State<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends State<PointsPage> {
  Map<String, dynamic>? _info;
  List<dynamic> _logs = [];
  bool _loading = true;
  bool _loadFailed = false;
  bool _checkedToday = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _info == null;
      _loadFailed = false;
    });
    try {
      final info = await ApiService.getUserInfo();
      final logs = await ApiService.getPointsLog();
      final checkin = await ApiService.checkinStatus();
      if (!mounted) return;
      setState(() {
        _info = info;
        _logs = logs;
        _checkedToday = checkin['checked_today'] == true;
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

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  String _svipLabel(String? type) {
    switch (type) {
      case 'monthly':
        return '月卡';
      case 'yearly':
        return '年卡';
      case 'lifetime':
        return '终身';
      default:
        return 'SVIP';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('积分中心')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const ListSkeleton(items: 4);
    if (_loadFailed) {
      return ErrorRetry(message: '积分数据加载失败', onRetry: _load);
    }
    return AppRefreshable(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildPointsPanel(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.calendar_month_rounded,
                  title: '每日签到',
                  subtitle: _checkedToday ? '今日已签到' : '立即签到领积分',
                  highlight: !_checkedToday,
                  accent: context.success,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CheckinPage()),
                    );
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.storefront_rounded,
                  title: '积分商店',
                  subtitle: '兑换积分好礼',
                  highlight: false,
                  accent: context.warning,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ShopPage()),
                    );
                  },
                ),
              ),
            ],
          ),
          SectionHeader(
            title: '积分记录',
            subtitle: '最近 ${_logs.take(20).length} 条变动',
            trailing: IconButton(
              icon: Icon(Icons.refresh_rounded,
                  size: 20, color: context.textSecondary),
              onPressed: _load,
            ),
          ),
          if (_logs.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: '暂无积分记录',
              subtitle: '参与活动与签到后，这里会展示积分变动',
            )
          else
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: _logs.take(20).map((log) {
                  final points = (log['points'] ?? 0);
                  final positive = points > 0;
                  return Column(
                    children: [
                      InfoRow(
                        leadingIcon: positive
                            ? Icons.add_circle_outline_rounded
                            : Icons.remove_circle_outline_rounded,
                        title: log['reason'] ?? '积分变动',
                        subtitle: Formatters.formatDateTime(
                          log['created_at']?.toString(),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (positive ? context.success : context.danger)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${positive ? '+' : ''}$points',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color:
                                  positive ? context.success : context.danger,
                            ),
                          ),
                        ),
                      ),
                      const ThinDivider(),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPointsPanel() {
    final isSvip = (_info?['svip_type'] ?? 'none') != 'none';
    return GradientCard(
      shadow: const [
        BoxShadow(color: Color(0x26000000), blurRadius: 18, offset: Offset(0, 6)),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '我的积分',
                style: TextStyle(
                  fontSize: 13,
                  color: context.onPrimary.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: context.onPrimary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 13, color: context.onPrimary),
                    const SizedBox(width: 4),
                    Text(
                      isSvip
                          ? '${_svipLabel(_info?['svip_type'])}有效期至 ${Formatters.formatDate(DateTime.tryParse(_info?['svip_expire'] ?? '') ?? DateTime.now())}'
                          : '普通会员',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _pointsStat(
                  '普通积分',
                  Formatters.formatPoints(_info?['daily_points']),
                  Icons.stars_rounded,
                  const Color(0xFFFFE082),
                ),
              ),
              Container(
                width: 1,
                height: 44,
                color: context.onPrimary.withValues(alpha: 0.22),
              ),
              Expanded(
                child: _pointsStat(
                  '高级积分',
                  Formatters.formatPoints(_info?['premium_points']),
                  Icons.diamond_rounded,
                  const Color(0xFF80D8FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.onPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.tips_and_updates_outlined,
                    size: 16, color: context.onPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '每日签到、参与活动可获得积分，积分可在商店兑换好礼',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: context.onPrimary.withValues(alpha: 0.9),
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

  Widget _pointsStat(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: context.onPrimary,
                height: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.onPrimary.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool highlight,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: accent),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: highlight ? accent : context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
