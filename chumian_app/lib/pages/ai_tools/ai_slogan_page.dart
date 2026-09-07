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
/// AISloganPage —— AI 标语生成
/// 品牌名，行业，风格(简约/幽默/文艺/霸气)，数量
/// 生成多条标语，复制，收藏
/// ============================================================
class AISloganPage extends StatefulWidget {
  const AISloganPage({super.key});

  @override
  State<AISloganPage> createState() => _AISloganPageState();
}

class _AISloganPageState extends State<AISloganPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _industryController = TextEditingController();

  int _selectedStyle = 0;
  int _sloganCount = 5;
  bool _isGenerating = false;
  bool _hasResult = false;
  bool _hasError = false;
  String _errorMessage = \'\';
  List<String> _slogans = [];
  final Set<int> _favorites = {};

  static const List<String> _styles = ['简约', '幽默', '文艺', '霸气'];
  static const List<IconData> _styleIcons = [
    Icons.circle_outlined,
    Icons.sentiment_very_satisfied,
    Icons.auto_awesome,
    Icons.local_fire_department,
  ];
  static const List<String> _sampleBrands = ['初眠', '花漾', '轻食光', '云栖', '粉墨'];
  static const List<String> _sampleIndustries = ['美妆护肤', '咖啡茶饮', '健康轻食', '智能家居', '文创潮玩'];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: MiuixDuration.slow);
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _brandController.dispose();
    _industryController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: MiuixCurves.miuixSpring)));
    final slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: Curves.easeOutCubic)));
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Opacity(opacity: animation.value, child: Transform.translate(offset: slide.value, child: child)),
    );
  }

  Future<void> _generateSlogans() async {
    if (_brandController.text.trim().isEmpty) {
      MiuixToast.show(context, message: '请输入品牌名称', type: MiuixToastType.warning);
      return;
    }
    setState(() {
      _isGenerating = true;
      _hasResult = false;
      _slogans = [];
    });
    try {
      final result = await ApiService.aiToolComplete(
        systemPrompt: '你是一位创意广告文案专家。请根据用户提供的品牌/产品信息，生成5-10条简洁有力、朗朗上口的宣传标语，每条一行。',
        userInput: "品牌/产品："+_brandController.text+"\n特点："+_featureController.text,
      );
      if (mounted) {
        _slogans = result.split('\n').where((l) => l.trim().isNotEmpty).toList();
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

  Future<void> _copySlogan(int index) async {
    await Clipboard.setData(ClipboardData(text: _slogans[index]));
    if (mounted) MiuixToast.show(context, message: '已复制标语', type: MiuixToastType.success);
  }

  void _toggleFavorite(int index) {
    setState(() {
      if (_favorites.contains(index)) {
        _favorites.remove(index);
      } else {
        _favorites.add(index);
        MiuixToast.show(context, message: '已收藏', type: MiuixToastType.success);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(title: 'AI 标语生成', backgroundColor: MiuixColors.background),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedItem(_buildBrandInput(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildStyleSelector(), 1),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildCountSelector(), 2),
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

  Widget _buildBrandInput() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('品牌信息', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          MiuixInput(controller: _brandController, hintText: '品牌名称', prefixIcon: Icons.business_center),
          const SizedBox(height: 12),
          MiuixInput(controller: _industryController, hintText: '所属行业（选填）', prefixIcon: Icons.category),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_sampleBrands.length, (index) {
              return MiuixChip(
                label: _sampleBrands[index],
                onTap: () {
                  _brandController.text = _sampleBrands[index];
                  _industryController.text = _sampleIndustries[index];
                },
                style: MiuixChipStyle.normal,
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
          const Text('标语风格', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
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

  Widget _buildCountSelector() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('生成数量', style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.pillRadius),
                child: Text('$_sloganCount 条', style: const TextStyle(color: Colors.white, fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: MiuixColors.primary,
              inactiveTrackColor: MiuixColors.surfaceVariant,
              thumbColor: Colors.white,
              overlayColor: MiuixColors.primaryLight.withValues(alpha: 0.3),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(value: _sloganCount.toDouble(), min: 3, max: 8, divisions: 5, label: '$_sloganCount条', onChanged: (val) => setState(() => _sloganCount = val.toInt())),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: _isGenerating ? '生成中...' : '生成标语',
        icon: Icons.auto_awesome,
        type: MiuixButtonType.gradient,
        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
        size: MiuixButtonSize.large,
        loading: _isGenerating,
        onPressed: _isGenerating ? null : _generateSlogans,
      ),
    );
  }

  Widget _buildLoadingCard() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const MiuixProgress(type: MiuixProgressType.circularIndeterminate, size: 48, strokeWidth: 4),
          const SizedBox(height: 16),
          const Text('AI 正在头脑风暴...', style: TextStyle(fontSize: MiuixFontSize.md, color: MiuixColors.textSecondary)),
          const SizedBox(height: 8),
          Text('${_styles[_selectedStyle]}风格标语创作中', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildResultList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text('生成结果', style: TextStyle(fontSize: MiuixFontSize.xl, fontWeight: FontWeight.w700, color: MiuixColors.textPrimary)),
        ),
        ...List.generate(_slogans.length, (index) {
          final isFav = _favorites.contains(index);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MiuixCard(
              style: MiuixCardStyle.gradient,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isFav ? [const Color(0xFFFFE0EC), const Color(0xFFFFD0E0)] : [const Color(0xFFFFF5F8), const Color(0xFFFFEEF3)],
              ),
              padding: const EdgeInsets.all(16),
              onTap: () => _copySlogan(index),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.smRadius),
                    child: Center(child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_slogans[index], style: const TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w500, color: MiuixColors.textPrimary, height: 1.5)),
                  ),
                  const SizedBox(width: 8),
                  MiuixIconButton(
                    icon: isFav ? Icons.favorite : Icons.favorite_border,
                    style: MiuixIconButtonStyle.ghost,
                    size: 36,
                    iconSize: 20,
                    color: isFav ? MiuixColors.primary : MiuixColors.textTertiary,
                    onPressed: () => _toggleFavorite(index),
                  ),
                  MiuixIconButton(icon: Icons.copy, style: MiuixIconButtonStyle.outlined, size: 36, iconSize: 18, onPressed: () => _copySlogan(index)),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: MiuixButton(label: '重新生成', icon: Icons.refresh, type: MiuixButtonType.secondary, onPressed: _generateSlogans),
        ),
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
