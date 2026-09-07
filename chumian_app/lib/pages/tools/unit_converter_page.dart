import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_input.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// UnitConverterPage —— 单位换算
/// 长度/重量/温度/面积/体积/速度/数据单位
/// 输入输出，实时换算，粉色主题
/// ============================================================

enum UnitCategory { length, weight, temperature, area, volume, speed, data }

class UnitConverterPage extends StatefulWidget {
  const UnitConverterPage({super.key});

  @override
  State<UnitConverterPage> createState() => _UnitConverterPageState();
}

class _UnitConverterPageState extends State<UnitConverterPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  UnitCategory _category = UnitCategory.length;
  String _fromUnit = '米';
  String _toUnit = '厘米';
  final TextEditingController _inputController = TextEditingController(text: '1');
  String _result = '';

  static const Map<UnitCategory, List<String>> _units = {
    UnitCategory.length: ['米', '千米', '厘米', '毫米', '英寸', '英尺', '英里', '码'],
    UnitCategory.weight: ['千克', '克', '毫克', '吨', '磅', '盎司', '斤', '两'],
    UnitCategory.temperature: ['摄氏度', '华氏度', '开尔文'],
    UnitCategory.area: ['平方米', '平方千米', '平方厘米', '公顷', '亩', '平方英尺', '平方英寸'],
    UnitCategory.volume: ['升', '毫升', '立方米', '立方厘米', '加仑', '夸脱', '品脱', '杯'],
    UnitCategory.speed: ['米/秒', '千米/时', '英里/时', '节', '马赫'],
    UnitCategory.data: ['字节', '千字节', '兆字节', '吉字节', '太字节', '位'],
  };

  static const Map<String, double> _toBase = {
    // 长度 -> 米
    '米': 1, '千米': 1000, '厘米': 0.01, '毫米': 0.001,
    '英寸': 0.0254, '英尺': 0.3048, '英里': 1609.344, '码': 0.9144,
    // 重量 -> 千克
    '千克': 1, '克': 0.001, '毫克': 0.000001, '吨': 1000,
    '磅': 0.453592, '盎司': 0.0283495, '斤': 0.5, '两': 0.05,
    // 面积 -> 平方米
    '平方米': 1, '平方千米': 1000000, '平方厘米': 0.0001,
    '公顷': 10000, '亩': 666.667, '平方英尺': 0.092903, '平方英寸': 0.000645,
    // 体积 -> 升
    '升': 1, '毫升': 0.001, '立方米': 1000, '立方厘米': 0.001,
    '加仑': 3.78541, '夸脱': 0.946353, '品脱': 0.473176, '杯': 0.236588,
    // 速度 -> 米/秒
    '米/秒': 1, '千米/时': 0.277778, '英里/时': 0.44704, '节': 0.514444, '马赫': 340.29,
    // 数据 -> 字节
    '字节': 1, '千字节': 1024, '兆字节': 1048576, '吉字节': 1073741824,
    '太字节': 1099511627776, '位': 0.125,
  };

  static const List<Map<String, dynamic>> _categories = [
    {'category': UnitCategory.length, 'label': '长度', 'icon': Icons.straighten},
    {'category': UnitCategory.weight, 'label': '重量', 'icon': Icons.scale},
    {'category': UnitCategory.temperature, 'label': '温度', 'icon': Icons.thermostat},
    {'category': UnitCategory.area, 'label': '面积', 'icon': Icons.crop_square},
    {'category': UnitCategory.volume, 'label': '体积', 'icon': Icons.water_drop},
    {'category': UnitCategory.speed, 'label': '速度', 'icon': Icons.speed},
    {'category': UnitCategory.data, 'label': '数据', 'icon': Icons.storage},
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: MiuixDuration.slow);
    _entryController.forward();
    _inputController.addListener(_convert);
    _convert();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _convert() {
    final input = double.tryParse(_inputController.text);
    if (input == null) {
      setState(() => _result = '');
      return;
    }

    double result;
    if (_category == UnitCategory.temperature) {
      result = _convertTemperature(input, _fromUnit, _toUnit);
    } else {
      final fromFactor = _toBase[_fromUnit] ?? 1;
      final toFactor = _toBase[_toUnit] ?? 1;
      result = input * fromFactor / toFactor;
    }

    setState(() {
      if (result.abs() >= 1e15 || (result.abs() < 1e-6 && result != 0)) {
        _result = result.toStringAsExponential(6);
      } else {
        _result = result.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      }
    });
  }

  double _convertTemperature(double value, String from, String to) {
    double celsius;
    switch (from) {
      case '华氏度':
        celsius = (value - 32) * 5 / 9;
        break;
      case '开尔文':
        celsius = value - 273.15;
        break;
      default:
        celsius = value;
    }
    switch (to) {
      case '华氏度':
        return celsius * 9 / 5 + 32;
      case '开尔文':
        return celsius + 273.15;
      default:
        return celsius;
    }
  }

  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
    });
    _convert();
  }

  void _selectCategory(UnitCategory category) {
    setState(() {
      _category = category;
      final units = _units[category]!;
      _fromUnit = units.first;
      _toUnit = units.length > 1 ? units[1] : units.first;
    });
    _convert();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: const MiuixAppBar(title: '单位换算'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.md),
        child: Column(
          children: [
            _buildCategorySelector(),
            const SizedBox(height: MiuixSpacing.lg),
            _buildConverterCard(),
            const SizedBox(height: MiuixSpacing.lg),
            _buildQuickReference(),
            const SizedBox(height: MiuixSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return FadeTransition(
      opacity: _entryController,
      child: SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: MiuixSpacing.sm),
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final isSelected = _category == cat['category'];
            return MiuixRipple(
              onTap: () => _selectCategory(cat['category'] as UnitCategory),
              borderRadius: MiuixRadius.lg,
              child: AnimatedContainer(
                duration: MiuixDuration.fast,
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: MiuixSpacing.sm),
                decoration: BoxDecoration(
                  gradient: isSelected ? const LinearGradient(colors: MiuixColors.primaryGradient) : null,
                  color: isSelected ? null : MiuixColors.surface,
                  borderRadius: MiuixRadius.lgRadius,
                  border: Border.all(color: isSelected ? Colors.transparent : MiuixColors.borderLight, width: 1),
                  boxShadow: isSelected ? [BoxShadow(color: MiuixColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(cat['icon'] as IconData, size: 22, color: isSelected ? Colors.white : MiuixColors.textTertiary),
                    const SizedBox(height: 4),
                    Text(cat['label'] as String, style: TextStyle(fontSize: MiuixFontSize.xs, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : MiuixColors.textSecondary)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildConverterCard() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryController, curve: const Interval(0.1, 0.5, curve: MiuixCurves.easeOut)),
      child: MiuixCard(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: Column(
          children: [
            _buildUnitRow('从', _fromUnit, _inputController, true),
            const SizedBox(height: MiuixSpacing.md),
            MiuixRipple(
              onTap: _swapUnits,
              borderRadius: MiuixRadius.pill,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: MiuixColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.swap_vert, size: 20, color: MiuixColors.primary),
              ),
            ),
            const SizedBox(height: MiuixSpacing.md),
            _buildUnitRow('到', _toUnit, null, false),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitRow(String label, String unit, TextEditingController? controller, bool isInput) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
        const SizedBox(height: MiuixSpacing.xs),
        Row(
          children: [
            Expanded(
              child: isInput
                  ? MiuixInput(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      hintText: '输入数值',
                      textStyle: const TextStyle(fontSize: MiuixFontSize.xl, fontWeight: FontWeight.w700, color: MiuixColors.primary),
                    )
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: MiuixSpacing.md, vertical: MiuixSpacing.md),
                      decoration: BoxDecoration(
                        color: MiuixColors.primary.withValues(alpha: 0.06),
                        borderRadius: MiuixRadius.mdRadius,
                        border: Border.all(color: MiuixColors.primary.withValues(alpha: 0.2), width: 1),
                      ),
                      child: Text(
                        _result.isEmpty ? '—' : _result,
                        style: const TextStyle(fontSize: MiuixFontSize.xl, fontWeight: FontWeight.w700, color: MiuixColors.primary),
                      ),
                    ),
            ),
            const SizedBox(width: MiuixSpacing.sm),
            _buildUnitDropdown(unit, isInput),
          ],
        ),
      ],
    );
  }

  Widget _buildUnitDropdown(String currentUnit, bool isFrom) {
    return MiuixRipple(
      onTap: () => _showUnitPicker(isFrom),
      borderRadius: MiuixRadius.md,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: MiuixSpacing.md, vertical: MiuixSpacing.md),
        decoration: BoxDecoration(
          color: MiuixColors.surfaceVariant,
          borderRadius: MiuixRadius.mdRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(currentUnit, style: const TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 18, color: MiuixColors.textTertiary),
          ],
        ),
      ),
    );
  }

  void _showUnitPicker(bool isFrom) {
    final units = _units[_category]!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: MiuixColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(MiuixRadius.xl)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: MiuixSpacing.sm),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: MiuixColors.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: MiuixSpacing.md),
              const Text('选择单位', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
              const SizedBox(height: MiuixSpacing.md),
              ...units.map((unit) {
                final isSelected = isFrom ? unit == _fromUnit : unit == _toUnit;
                return MiuixRipple(
                  onTap: () {
                    setState(() {
                      if (isFrom) {
                        _fromUnit = unit;
                      } else {
                        _toUnit = unit;
                      }
                    });
                    _convert();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: MiuixSpacing.xl, vertical: MiuixSpacing.md),
                    decoration: BoxDecoration(
                      color: isSelected ? MiuixColors.primary.withValues(alpha: 0.06) : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Text(unit, style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? MiuixColors.primary : MiuixColors.textPrimary)),
                        const Spacer(),
                        if (isSelected) const Icon(Icons.check, size: 18, color: MiuixColors.primary),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: MiuixSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickReference() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryController, curve: const Interval(0.2, 0.6, curve: MiuixCurves.easeOut)),
      child: MiuixCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 18, color: MiuixColors.warning),
                SizedBox(width: MiuixSpacing.sm),
                Text('常用换算', style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
              ],
            ),
            const SizedBox(height: MiuixSpacing.md),
            _buildReferenceRow('1 千米', '= 1000 米'),
            _buildReferenceRow('1 千克', '= 2.20462 磅'),
            _buildReferenceRow('0 摄氏度', '= 32 华氏度'),
            _buildReferenceRow('1 公顷', '= 10000 平方米'),
            _buildReferenceRow('1 吉字节', '= 1024 兆字节'),
          ],
        ),
      ),
    );
  }

  Widget _buildReferenceRow(String from, String to) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MiuixSpacing.sm),
      child: Row(
        children: [
          Text(from, style: const TextStyle(fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w600, color: MiuixColors.primary)),
          const SizedBox(width: MiuixSpacing.sm),
          Text(to, style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textSecondary)),
        ],
      ),
    );
  }
}
