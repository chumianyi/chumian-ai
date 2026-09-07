import 'package:flutter/material.dart';
import 'package:chumian_ai/services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_chip.dart';
import 'package:chumian_ai/widgets/miuix/miuix_input.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/utils/clipboard_utils.dart';

/// ============================================================
/// AIPoetryPage —— AI 写诗
/// 诗体选择(五言/七言/词/现代诗)，主题输入，生成结果
/// 书法风格展示，粉色背景
/// ============================================================
class AIPoetryPage extends StatefulWidget {
  const AIPoetryPage({super.key});

  @override
  State<AIPoetryPage> createState() => _AIPoetryPageState();
}

class _AIPoetryPageState extends State<AIPoetryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _brushController;

  final TextEditingController _themeController = TextEditingController();
  final TextEditingController _poemController = TextEditingController();

  int _selectedForm = 0;
  bool _isGenerating = false;
  bool _hasResult = false;
  bool _hasError = false;
  String _errorMessage = \'\';
  String _poemTitle = '';

  static const List<PoetryForm> _forms = [
    PoetryForm(name: '五言绝句', desc: '四句二十字', icon: Icons.text_fields),
    PoetryForm(name: '七言绝句', desc: '四句二十八字', icon: Icons.text_rotate_up),
    PoetryForm(name: '词', desc: '长短句', icon: Icons.menu_book),
    PoetryForm(name: '现代诗', desc: '自由体', icon: Icons.auto_awesome),
  ];

  static const List<String> _themes = [
    '春天', '月亮', '思乡', '友情', '爱情', '山水', '边塞', '咏物',
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _brushController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _brushController.dispose();
    _themeController.dispose();
    _poemController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.08, (index * 0.08) + 0.4,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.08, (index * 0.08) + 0.4,
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

  Future<void> _generatePoem() async {
    if (_themeController.text.trim().isEmpty) {
      MiuixToast.show(context,
          message: '请输入诗歌主题', type: MiuixToastType.warning);
      return;
    }
    setState(() {
      _isGenerating = true;
      _hasResult = false;
    });
    _brushController.forward(from: 0);
    try {
      final result = await ApiService.aiToolComplete(
        systemPrompt: '你是一位才华横溢的诗人。请根据用户提供的主题和诗歌类型，创作一首意境优美的诗歌。',
        userInput: "主题："+_topicController.text+"\n类型："+_poemTypes[_selectedType],
      );
      if (mounted) {
        _poemContent = result;
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

  PoemResult _generatePoemText() {
    final theme = _themeController.text;
    switch (_selectedForm) {
      case 0:
        return PoemResult(
          title: '咏$theme',
          content: '春风拂绿柳，\n细雨润花开。\n$theme情意重，\n诗心入梦来。',
        );
      case 1:
        return PoemResult(
          title: '$theme有感',
          content: '千里$theme入画来，\n清风明月共徘徊。\n人间自有真情在，\n一曲高歌醉玉台。',
        );
      case 2:
        return PoemResult(
          title: '如梦令·$theme',
          content: '常记溪亭日暮，\n沉醉不知归路。\n兴尽晚回舟，\n误入藕花深处。\n争渡，争渡，\n惊起一滩鸥鹭。',
        );
      case 3:
        return PoemResult(
          title: '$theme之歌',
          content: '在这个温柔的季节里\n$theme如同一首无声的歌\n轻轻流淌在心间\n\n微风拂过面庞\n带来远方的消息\n那是关于$theme的记忆\n\n我愿化作一只蝴蝶\n在$theme的世界里翩翩起舞\n直到永远',
        );
      default:
        return PoemResult(title: '', content: '');
    }
  }

  Future<void> _copyPoem() async {
    await ClipboardUtils.copy('${_poemTitle}\n\n${_poemController.text}');
    if (mounted) {
      MiuixToast.show(context,
          message: '诗歌已复制', type: MiuixToastType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: 'AI 写诗',
        backgroundColor: MiuixColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            _buildAnimatedItem(_buildFormSelector(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildThemeInput(), 1),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildGenerateButton(), 2),
            const SizedBox(height: 20),
            if (_hasResult || _isGenerating)
              _buildAnimatedItem(_buildPoemDisplay(), 3),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSelector() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '诗体选择',
            style: TextStyle(
              fontSize: MiuixFontSize.lg,
              fontWeight: FontWeight.w600,
              color: MiuixColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _forms.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedForm == index;
              final form = _forms[index];
              return MiuixRipple(
                borderRadius: MiuixRadius.md,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedForm = index),
                  child: AnimatedContainer(
                    duration: MiuixDuration.fast,
                    curve: MiuixCurves.miuixSpring,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFFE4EC), Color(0xFFFFD6E4)],
                            )
                          : null,
                      color: isSelected ? null : MiuixColors.surfaceVariant,
                      borderRadius: MiuixRadius.mdRadius,
                      border: Border.all(
                        color: isSelected
                            ? MiuixColors.primary
                            : MiuixColors.borderLight,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: MiuixColors.primaryGradient)
                                : null,
                            color: isSelected
                                ? null
                                : MiuixColors.primaryLight.withValues(alpha: 0.2),
                            borderRadius: MiuixRadius.smRadius,
                          ),
                          child: Icon(
                            form.icon,
                            size: 20,
                            color: isSelected
                                ? Colors.white
                                : MiuixColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              form.name,
                              style: TextStyle(
                                fontSize: MiuixFontSize.md,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? MiuixColors.primaryDeep
                                    : MiuixColors.textPrimary,
                              ),
                            ),
                            Text(
                              form.desc,
                              style: const TextStyle(
                                fontSize: MiuixFontSize.xs,
                                color: MiuixColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeInput() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '诗歌主题',
            style: TextStyle(
              fontSize: MiuixFontSize.md,
              fontWeight: FontWeight.w600,
              color: MiuixColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          MiuixInput(
            controller: _themeController,
            hintText: '输入主题，如：春天、月亮、思乡...',
            prefixIcon: Icons.auto_awesome,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_themes.length, (index) {
              return MiuixChip(
                label: _themes[index],
                onTap: () => _themeController.text = _themes[index],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: _isGenerating ? '挥毫中...' : '开始作诗',
        icon: Icons.brush,
        type: MiuixButtonType.gradient,
        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
        size: MiuixButtonSize.large,
        loading: _isGenerating,
        onPressed: _isGenerating ? null : _generatePoem,
      ),
    );
  }

  Widget _buildPoemDisplay() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC), Color(0xFFFFD6E4)],
        ),
        borderRadius: MiuixRadius.xlRadius,
        boxShadow: MiuixShadows.md,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 装饰性边角
          _buildCornerDecoration(),
          const SizedBox(height: 16),
          if (_isGenerating)
            _buildGeneratingState()
          else
            _buildPoemContent(),
          const SizedBox(height: 16),
          _buildCornerDecoration(isBottom: true),
          const SizedBox(height: 16),
          if (_hasResult)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MiuixButton(
                  label: '复制',
                  icon: Icons.copy,
                  type: MiuixButtonType.secondary,
                  onPressed: _copyPoem,
                ),
                const SizedBox(width: 12),
                MiuixButton(
                  label: '再来一首',
                  icon: Icons.refresh,
                  type: MiuixButtonType.primary,
                  onPressed: _generatePoem,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCornerDecoration({bool isBottom = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                  color: MiuixColors.primary.withValues(alpha: 0.4), width: 2),
              top: isBottom
                  ? BorderSide.none
                  : BorderSide(
                      color: MiuixColors.primary.withValues(alpha: 0.4),
                      width: 2),
              bottom: isBottom
                  ? BorderSide(
                      color: MiuixColors.primary.withValues(alpha: 0.4),
                      width: 2)
                  : BorderSide.none,
            ),
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                  color: MiuixColors.primary.withValues(alpha: 0.4), width: 2),
              top: isBottom
                  ? BorderSide.none
                  : BorderSide(
                      color: MiuixColors.primary.withValues(alpha: 0.4),
                      width: 2),
              bottom: isBottom
                  ? BorderSide(
                      color: MiuixColors.primary.withValues(alpha: 0.4),
                      width: 2)
                  : BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratingState() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _brushController,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(80, 80),
              painter: _BrushPainter(_brushController.value),
            );
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'AI 正在挥毫泼墨...',
          style: TextStyle(
            fontSize: MiuixFontSize.md,
            color: MiuixColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPoemContent() {
    final lines = _poemController.text.split('\n');
    return Column(
      children: [
        // 标题
        Text(
          _poemTitle,
          style: const TextStyle(
            fontSize: MiuixFontSize.xxl,
            fontWeight: FontWeight.bold,
            color: MiuixColors.primaryDeep,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: 2,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
            borderRadius: MiuixRadius.pillRadius,
          ),
        ),
        const SizedBox(height: 20),
        // 诗句 - 竖排风格
        if (_selectedForm < 3)
          ...lines.map((line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  line,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.xl,
                    color: MiuixColors.textPrimary,
                    letterSpacing: 6,
                    height: 1.6,
                  ),
                ),
              ))
        else
          ...lines.map((line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  line,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.lg,
                    color: MiuixColors.textPrimary,
                    height: 1.8,
                  ),
                ),
              )),
        const SizedBox(height: 16),
        // 印章
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MiuixColors.error,
              borderRadius: MiuixRadius.smRadius,
            ),
            child: const Text(
              '初眠\nAI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

class PoetryForm {
  final String name;
  final String desc;
  final IconData icon;
  const PoetryForm(
      {required this.name, required this.desc, required this.icon});
}

class PoemResult {
  final String title;
  final String content;
  const PoemResult({required this.title, required this.content});
}

/// 毛笔动画绘制器
class _BrushPainter extends CustomPainter {
  final double progress;
  _BrushPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = MiuixColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // 绘制旋转的墨点
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * 3.14159 + progress * 2 * 3.14159;
      final radius = 25 + sin(progress * 3.14159 * 2 + i) * 5;
      final dx = center.dx + cos(angle) * radius;
      final dy = center.dy + sin(angle) * radius;
      canvas.drawCircle(
        Offset(dx, dy),
        3 + sin(angle * 2) * 1.5,
        Paint()..color = MiuixColors.primary.withValues(alpha: 0.6),
      );
    }

    // 中心墨滴
    canvas.drawCircle(
      center,
      8 + sin(progress * 3.14159 * 4) * 3,
      Paint()..color = MiuixColors.primaryDeep,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  /// 错误状态卡片（请求失败时显示，含重试按钮）
  Widget _buildErrorCard() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: MiuixColors.error, size: 48),
          const SizedBox(height: 12),
          Text(
            '生成失败',
            style: TextStyle(
              fontSize: MiuixFontSize.lg,
              fontWeight: FontWeight.w600,
              color: MiuixColors.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(
              fontSize: MiuixFontSize.sm,
              color: MiuixColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          MiuixButton(
            label: '重试',
            icon: Icons.refresh,
            type: MiuixButtonType.gradient,
            gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
            onPressed: () {
              setState(() => _hasError = false);
              // 重新调用生成方法
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // 由各页面具体的生成方法触发
              });
            },
          ),
        ],
      ),
    );
  }

}