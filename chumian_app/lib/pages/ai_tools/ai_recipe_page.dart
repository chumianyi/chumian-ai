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
/// AIRecipePage —— AI 菜谱
/// 食材输入，口味选择(清淡/麻辣/酸甜/咸鲜)，菜系，难度
/// 生成菜谱(食材清单+步骤+营养)，粉色卡片
/// ============================================================
class AIRecipePage extends StatefulWidget {
  const AIRecipePage({super.key});

  @override
  State<AIRecipePage> createState() => _AIRecipePageState();
}

class _AIRecipePageState extends State<AIRecipePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _typewriterController;

  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();

  int _selectedTaste = 0;
  int _selectedCuisine = 0;
  int _selectedDifficulty = 1;
  bool _isGenerating = false;
  bool _hasResult = false;
  bool _hasError = false;
  String _errorMessage = \'\';
  String _displayedText = '';
  int _typewriterIndex = 0;

  static const List<String> _tastes = ['清淡', '麻辣', '酸甜', '咸鲜'];
  static const List<IconData> _tasteIcons = [Icons.eco, Icons.local_fire_department, Icons.favorite, Icons.savings];
  static const List<String> _cuisines = ['家常菜', '川菜', '粤菜', '湘菜', '西餐', '日料'];
  static const List<String> _difficulties = ['简单', '中等', '困难'];
  static const List<String> _sampleIngredients = ['鸡胸肉, 西兰花, 大蒜', '番茄, 鸡蛋, 葱花', '牛肉, 土豆, 胡萝卜', '虾, 豆腐, 姜', '排骨, 玉米, 枸杞'];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: MiuixDuration.slow);
    _typewriterController = AnimationController(vsync: this, duration: const Duration(milliseconds: 35));
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _typewriterController.dispose();
    _ingredientsController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: MiuixCurves.miuixSpring)));
    final slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _entryController, curve: Interval(index * 0.08, (index * 0.08) + 0.4, curve: Curves.easeOutCubic)));
    return AnimatedBuilder(animation: animation, builder: (_, __) => Opacity(opacity: animation.value, child: Transform.translate(offset: slide.value, child: child)));
  }

  Future<void> _generateRecipe() async {
    if (_ingredientsController.text.trim().isEmpty) {
      MiuixToast.show(context, message: '请输入可用食材', type: MiuixToastType.warning);
      return;
    }
    setState(() {
      _isGenerating = true;
      _hasResult = false;
      _displayedText = '';
      _typewriterIndex = 0;
    });
    try {
      final result = await ApiService.aiToolComplete(
        systemPrompt: '你是一位专业的营养师和厨师。请根据用户提供的食材和口味偏好，生成一份详细的菜谱，包含食材清单、制作步骤和营养信息。',
        userInput: "食材："+_ingredientsController.text+"\n口味："+_tastes[_selectedTaste]+"\n难度："+_difficulties[_selectedDifficulty],
      );
      if (mounted) {
        _resultController.text = result;
        _startTypewriter(result);
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
    _startTypewriter(generated);
  }

  void _startTypewriter(String text) {
    _typewriterIndex = 0;
    _typewriterController.removeListener(_tick);
    _typewriterController.addListener(_tick);
    _typewriterController.repeat();
  }

  void _tick() {
    if (_typewriterIndex < _resultController.text.length) {
      setState(() {
        _typewriterIndex += 3;
        if (_typewriterIndex > _resultController.text.length) _typewriterIndex = _resultController.text.length;
        _displayedText = _resultController.text.substring(0, _typewriterIndex);
      });
    } else {
      _typewriterController.stop();
      _typewriterController.removeListener(_tick);
    }
  }

  Future<void> _copyResult() async {
    if (_resultController.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _resultController.text));
    if (mounted) MiuixToast.show(context, message: '已复制菜谱', type: MiuixToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(title: 'AI 菜谱', backgroundColor: MiuixColors.background),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedItem(_buildIngredientsInput(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildTasteSelector(), 1),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildCuisineDifficultyRow(), 2),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildGenerateButton(), 3),
            const SizedBox(height: 20),
            if (_isGenerating) _buildAnimatedItem(_buildLoadingCard(), 4),
            if (_hasError) _buildAnimatedItem(_buildErrorCard(), 5),

            if (_hasResult) _buildAnimatedItem(_buildResultCard(), 4),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsInput() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('可用食材', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          MiuixInput(
            controller: _ingredientsController,
            hintText: '输入冰箱里有的食材，用逗号分隔，如：鸡胸肉, 西兰花, 大蒜',
            prefixIcon: Icons.kitchen,
            maxLines: 3,
            minLines: 2,
            type: MiuixInputType.multiline,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_sampleIngredients.length, (index) {
              return MiuixChip(
                label: _sampleIngredients[index].length > 14 ? '${_sampleIngredients[index].substring(0, 14)}...' : _sampleIngredients[index],
                onTap: () => _ingredientsController.text = _sampleIngredients[index],
                style: MiuixChipStyle.normal,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTasteSelector() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('口味偏好', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_tastes.length, (index) {
              final isSelected = _selectedTaste == index;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 3 ? 8 : 0),
                  child: MiuixRipple(
                    borderRadius: MiuixRadius.md,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTaste = index),
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
                            Icon(_tasteIcons[index], size: 22, color: isSelected ? Colors.white : MiuixColors.primary),
                            const SizedBox(height: 6),
                            Text(_tastes[index], style: TextStyle(fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : MiuixColors.textSecondary)),
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

  Widget _buildCuisineDifficultyRow() {
    return Row(
      children: [
        Expanded(
          child: MiuixCard(
            style: MiuixCardStyle.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('菜系', style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(_cuisines.length, (index) {
                    return MiuixChip(label: _cuisines[index], isSelected: _selectedCuisine == index, onTap: () => setState(() => _selectedCuisine = index), height: 30);
                  }),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MiuixCard(
            style: MiuixCardStyle.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('难度', style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(_difficulties.length, (index) {
                    return MiuixChip(label: _difficulties[index], isSelected: _selectedDifficulty == index, onTap: () => setState(() => _selectedDifficulty = index), height: 30);
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: _isGenerating ? '生成中...' : '生成菜谱',
        icon: Icons.restaurant_menu,
        type: MiuixButtonType.gradient,
        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
        size: MiuixButtonSize.large,
        loading: _isGenerating,
        onPressed: _isGenerating ? null : _generateRecipe,
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
        const Text('AI 正在研究菜谱...', style: TextStyle(fontSize: MiuixFontSize.md, color: MiuixColors.textSecondary)),
        const SizedBox(height: 8),
        Text('${_tastes[_selectedTaste]}${_cuisines[_selectedCuisine]}创作中', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
      ]),
    );
  }

  Widget _buildResultCard() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)]),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.smRadius), child: const Icon(Icons.restaurant, color: Colors.white, size: 20)),
              const SizedBox(width: 10),
              const Expanded(child: Text('菜谱详情', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary))),
              MiuixIconButton(icon: Icons.copy, style: MiuixIconButtonStyle.outlined, size: 36, iconSize: 18, onPressed: _copyResult),
              const SizedBox(width: 8),
              MiuixIconButton(icon: Icons.refresh, style: MiuixIconButtonStyle.outlined, size: 36, iconSize: 18, onPressed: _generateRecipe),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: MiuixRadius.mdRadius, border: Border.all(color: MiuixColors.borderLight)),
            child: SingleChildScrollView(
              maxHeight: 500,
              child: Text(_displayedText, style: const TextStyle(fontSize: MiuixFontSize.md, height: 1.8, color: MiuixColors.textPrimary)),
            ),
          ),
          if (_typewriterIndex < _resultController.text.length)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(MiuixColors.primary))),
                const SizedBox(width: 8),
                const Text('正在输出菜谱...', style: TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
              ]),
            ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: MiuixButton(label: '复制菜谱', icon: Icons.copy_all, type: MiuixButtonType.primary, onPressed: _copyResult)),
        ],
      ),
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
