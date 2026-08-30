import 'package:flutter/material.dart';
import '../widgets/context_ext.dart';
import '../widgets/app_card.dart';
import '../widgets/feedback.dart';
import '../widgets/gradient_header.dart';
import '../widgets/buttons.dart';
import '../widgets/tiles.dart';
import '../utils/formatters.dart';
import '../utils/constants.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});
  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  bool _loading = true;
  bool _loadFailed = false;
  bool _playedToday = false;
  Map<String, dynamic>? _todayRecord;
  List<dynamic> _history = [];
  final TextEditingController _pointsCtrl = TextEditingController();
  String _choice = 'big';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _pointsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() {
      _loading = _history.isEmpty && !_playedToday;
      _loadFailed = false;
    });
    try {
      final data = await ApiService.guessStatus();
      if (!mounted) return;
      setState(() {
        _playedToday = data['played_today'] == true;
        _todayRecord = data['today_record'];
        _history = data['history'] ?? [];
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

  Future<void> _play() async {
    final points = int.tryParse(_pointsCtrl.text) ?? 0;
    if (points <= 0) {
      _showSnack('请输入有效的积分数量');
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await ApiService.guessActivity(points, _choice);
      if (!mounted) return;
      final won = result['won'] == true;
      final change = result['points_change'] ?? 0;
      final roll = result['roll'];
      final resultText = result['result'] == 'big' ? '大' : '小';
      await _showResultDialog(won, change, roll, resultText);
      _loadStatus();
    } catch (e) {
      if (!mounted) return;
      _showSnack('参与失败: ${ErrorMessages.of(e)}');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showResultDialog(
    bool won,
    int change,
    dynamic roll,
    String resultText,
  ) {
    final accent = won ? context.success : context.danger;
    return showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  won ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                  size: 38,
                  color: accent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                won ? '恭喜赢了' : '很遗憾输了',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: context.surfaceSubtle,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      '开出：$resultText',
                      style: TextStyle(fontSize: 14, color: context.textPrimary),
                    ),
                    if (roll != null)
                      Text(
                        '点数：$roll',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '积分变动：${change > 0 ? '+' : ''}$change',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: '知道了',
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('活动中心')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const ListSkeleton(items: 4);
    if (_loadFailed) {
      return ErrorRetry(message: '活动数据加载失败', onRetry: _loadStatus);
    }
    return AppRefreshable(
      onRefresh: _loadStatus,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildGameCard(),
          SectionHeader(
            title: '历史记录',
            subtitle: '共 ${_history.length} 次参与',
          ),
          if (_history.isEmpty)
            const EmptyState(
              icon: Icons.history_rounded,
              title: '暂无历史记录',
              subtitle: '参与猜大小后，结果会记录在这里',
            )
          else
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: _history.map((h) {
                  final won = h['won'] == 1;
                  final change = h['points_change'] ?? 0;
                  final bet = h['choice'] == 'big' ? '大' : '小';
                  final result = h['result'] == 'big' ? '大' : '小';
                  return Column(
                    children: [
                      InfoRow(
                        leadingIcon: won
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        title: '${h['guess_date']} 押$bet 开$result',
                        subtitle: won ? '赢得 $change 积分' : '输掉 ${change.abs()} 积分',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (won ? context.success : context.danger)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${change > 0 ? '+' : ''}$change',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: won ? context.success : context.danger,
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

  Widget _buildGameCard() {
    return GradientCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF5A623), Color(0xFFFFCE7A)],
      ),
      shadow: const [
        BoxShadow(color: Color(0x26000000), blurRadius: 18, offset: Offset(0, 6)),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.casino_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '猜大小',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '每天一次，押对积分翻倍',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              PillTag(
                text: _playedToday ? '今日已玩' : '可参与',
                color: Colors.white,
                background: Colors.white.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_playedToday)
            _buildTodayResult()
          else
            _buildPlayForm(),
        ],
      ),
    );
  }

  Widget _buildTodayResult() {
    final rec = _todayRecord;
    final resultText = rec?['result'] == 'big' ? '大' : '小';
    final roll = rec?['roll'] ?? 0;
    final won = rec?['won'] == 1;
    final change = rec?['points_change'] ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            '今日已参与',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _resultChip('结果', resultText),
              const SizedBox(width: 12),
              _resultChip('点数', '$roll'),
              const SizedBox(width: 12),
              _resultChip(
                won ? '赢了' : '输了',
                '${change > 0 ? '+' : ''}$change',
                highlight: won,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultChip(String label, String value, {bool highlight = false}) {
    final fg = highlight ? const Color(0xFFFFE082) : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '预测点数结果，押大或押小，猜对积分翻倍',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _pointsCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            labelText: '押注积分数量',
            hintText: '输入要押的积分',
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            prefixIcon: Icon(
              Icons.stars_rounded,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _choiceChip('大', _choice == 'big', () {
                setState(() => _choice = 'big');
              }, const Color(0xFFE8445C)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _choiceChip('小', _choice == 'small', () {
                setState(() => _choice = 'small');
              }, const Color(0xFF3D7BF0)),
            ),
          ],
        ),
        const SizedBox(height: 18),
        GradientButton(
          label: '立即参与',
          icon: Icons.casino_rounded,
          loading: _submitting,
          onPressed: _play,
        ),
      ],
    );
  }

  Widget _choiceChip(
    String label,
    bool selected,
    VoidCallback onTap,
    Color color,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? color
              : Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.white : Colors.white.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
