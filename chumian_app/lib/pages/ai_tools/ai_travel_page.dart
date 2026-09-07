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
/// AITravelPage —— AI 旅行规划
/// 目的地，天数，人数，预算，风格(休闲/探险/文化/美食)
/// 生成行程(每日安排+景点+餐饮+交通)，粉色时间线
/// ============================================================
class AITravelPage extends StatefulWidget {
  const AITravelPage({super.key});

  @override
  State<AITravelPage> createState() => _AITravelPageState();
}

class _AITravelPageState extends State<AITravelPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  int _selectedDays = 3;
  int _selectedPeople = 2;
  int _selectedStyle = 0;
  bool _isGenerating = false;
  bool _hasResult = false;
  bool _hasError = false;
  String _errorMessage = \'\';
  List<Map<String, dynamic>> _itinerary = [];

  static const List<String> _styles = ['休闲', '探险', '文化', '美食'];
  static const List<IconData> _styleIcons = [Icons.beach_access, Icons.terrain, Icons.museum, Icons.restaurant];
  static const List<String> _sampleDestinations = ['成都', '厦门', '丽江', '西安', '杭州', '三亚'];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: MiuixDuration.slow);
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _destinationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: MiuixCurves.miuixSpring)));
    final slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: Curves.easeOutCubic)));
    return AnimatedBuilder(animation: animation, builder: (_, __) => Opacity(opacity: animation.value, child: Transform.translate(offset: slide.value, child: child)));
  }

  Future<void> _generateItinerary() async {
    if (_destinationController.text.trim().isEmpty) {
      MiuixToast.show(context, message: '请输入目的地', type: MiuixToastType.warning);
      return;
    }
    setState(() {
      _isGenerating = true;
      _hasResult = false;
      _itinerary = [];
    });
    try {
      final result = await ApiService.aiToolComplete(
        systemPrompt: '你是一位专业的旅行规划师。请根据用户提供的目的地、天数和预算，生成一份详细的旅行计划，包含每日行程、景点推荐和注意事项。',
        userInput: "目的地："+_destinationController.text+"\n天数："+_daysController.text+"天\n预算："+_budgetController.text,
      );
      if (mounted) {
        _itineraryText = result;
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

  Future<void> _copyItinerary() async {
    String text = '';
    for (var day in _itinerary) {
      text += '【${day['title']}】\n';
      text += '交通：${day['transport']}\n';
      text += '住宿：${day['accommodation']}\n';
      for (var item in day['schedule']) {
        text += '${item['time']} ${item['activity']}\n';
      }
      text += '当日预算：${day['cost']}\n\n';
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) MiuixToast.show(context, message: '行程已复制', type: MiuixToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(title: 'AI 旅行规划', backgroundColor: MiuixColors.background),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedItem(_buildDestinationInput(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildStyleSelector(), 1),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildSettingsCard(), 2),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildGenerateButton(), 3),
            const SizedBox(height: 20),
            if (_isGenerating) _buildAnimatedItem(_buildLoadingCard(), 4),
            if (_hasError) _buildAnimatedItem(_buildErrorCard(), 5),

            if (_hasResult) ...[
              _buildAnimatedItem(_buildSummaryCard(), 4),
              const SizedBox(height: 16),
              ..._buildDayTimelines(),
              const SizedBox(height: 16),
              _buildAnimatedItem(_buildCopyButton(), 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationInput() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('目的地', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          MiuixInput(controller: _destinationController, hintText: '你想去哪里？如：成都、厦门、丽江...', prefixIcon: Icons.location_on),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_sampleDestinations.length, (index) {
              return MiuixChip(label: _sampleDestinations[index], onTap: () => _destinationController.text = _sampleDestinations[index], style: MiuixChipStyle.normal);
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
          const Text('旅行风格', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
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

  Widget _buildSettingsCard() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _settingColumn('旅行天数', _selectedDays, [2, 3, 4, 5, 7], (v) => setState(() => _selectedDays = v), '天')),
              Container(width: 1, height: 60, color: MiuixColors.divider),
              Expanded(child: _settingColumn('出行人数', _selectedPeople, [1, 2, 3, 4, 5], (v) => setState(() => _selectedPeople = v), '人')),
            ],
          ),
          const SizedBox(height: 16),
          MiuixInput(controller: _budgetController, hintText: '总预算（元），如：3000', prefixIcon: Icons.account_balance_wallet, type: MiuixInputType.number),
        ],
      ),
    );
  }

  Widget _settingColumn(String label, int value, List<int> options, Function(int) onSelect, String unit) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MiuixIconButton(icon: Icons.remove, style: MiuixIconButtonStyle.outlined, size: 32, iconSize: 16, onPressed: () { if (value > options.first) onSelect(value - 1); }),
            const SizedBox(width: 12),
            Text('$value$unit', style: const TextStyle(fontSize: MiuixFontSize.xl, fontWeight: FontWeight.w700, color: MiuixColors.primary)),
            const SizedBox(width: 12),
            MiuixIconButton(icon: Icons.add, style: MiuixIconButtonStyle.outlined, size: 32, iconSize: 16, onPressed: () { if (value < options.last) onSelect(value + 1); }),
          ],
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: _isGenerating ? '规划中...' : '生成旅行计划',
        icon: Icons.flight_takeoff,
        type: MiuixButtonType.gradient,
        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
        size: MiuixButtonSize.large,
        loading: _isGenerating,
        onPressed: _isGenerating ? null : _generateItinerary,
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
        const Text('AI 正在规划行程...', style: TextStyle(fontSize: MiuixFontSize.md, color: MiuixColors.textSecondary)),
        const SizedBox(height: 8),
        Text('${_destinationController.text} · ${_styles[_selectedStyle]}之旅', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
      ]),
    );
  }

  Widget _buildSummaryCard() {
    final budget = _budgetController.text.trim().isEmpty ? '3000' : _budgetController.text.trim();
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)]),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.smRadius), child: const Icon(Icons.flight_takeoff, color: Colors.white, size: 20)),
              const SizedBox(width: 10),
              Expanded(child: Text('${_destinationController.text} ${_selectedDays}日${_styles[_selectedStyle]}之旅', style: const TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem(Icons.calendar_today, '$_selectedDays天', '行程天数'),
              _summaryItem(Icons.people, '$_selectedPeople人', '出行人数'),
              _summaryItem(Icons.payments, budget, '总预算(元)'),
              _summaryItem(Icons.style, _styles[_selectedStyle], '旅行风格'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 22, color: MiuixColors.primary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w700, color: MiuixColors.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 10, color: MiuixColors.textTertiary)),
      ],
    );
  }

  List<Widget> _buildDayTimelines() {
    return List.generate(_itinerary.length, (dayIndex) {
      final day = _itinerary[dayIndex];
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildAnimatedItem(
          MiuixCard(
            style: MiuixCardStyle.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.mdRadius),
                      child: Center(child: Text('D${day['day']}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(day['title'], style: const TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary))),
                    Text(day['cost'], style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                _infoRow(Icons.directions_transit, '交通', day['transport']),
                const SizedBox(height: 6),
                _infoRow(Icons.hotel, '住宿', day['accommodation']),
                const SizedBox(height: 12),
                const Divider(color: MiuixColors.divider, height: 1),
                const SizedBox(height: 12),
                // 粉色时间线
                ...List.generate((day['schedule'] as List).length, (idx) {
                  final item = day['schedule'][idx];
                  final isLast = idx == (day['schedule'] as List).length - 1;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                          ),
                          if (!isLast) Container(width: 2, height: 60, color: MiuixColors.primaryLight.withValues(alpha: 0.4)),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(item['time'], style: const TextStyle(fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w700, color: MiuixColors.primary)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: MiuixColors.surfaceVariant, borderRadius: MiuixRadius.pillRadius),
                                    child: Text(item['type'], style: const TextStyle(fontSize: 10, color: MiuixColors.textSecondary)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(item['activity'], style: const TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w500, color: MiuixColors.textPrimary)),
                              if (item['note'].toString().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(item['note'], style: const TextStyle(fontSize: 11, color: MiuixColors.textTertiary)),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          dayIndex + 5,
        ),
      );
    });
  }

  Widget _infoRow(IconData icon, String label, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: MiuixColors.primary),
        const SizedBox(width: 6),
        Text('$label：', style: const TextStyle(fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w600, color: MiuixColors.textSecondary)),
        Expanded(child: Text(text, style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary))),
      ],
    );
  }

  Widget _buildCopyButton() {
    return SizedBox(width: double.infinity, child: MiuixButton(label: '复制完整行程', icon: Icons.copy_all, type: MiuixButtonType.primary, onPressed: _copyItinerary));

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
