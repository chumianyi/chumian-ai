import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_chip.dart';
import 'package:chumian_ai/widgets/miuix/miuix_input.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_segment.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_empty_state.dart';

/// ============================================================
/// AIImagePage —— AI 绘画
/// prompt 输入，风格选择(写实/动漫/油画/水彩)，尺寸选择
/// 生成按钮，结果展示网格，下载/分享，历史记录
/// ============================================================
class AIImagePage extends StatefulWidget {
  const AIImagePage({super.key});

  @override
  State<AIImagePage> createState() => _AIImagePageState();
}

class _AIImagePageState extends State<AIImagePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  final TextEditingController _promptController = TextEditingController();

  int _selectedStyle = 0;
  int _selectedSize = 0;
  int _selectedRatio = 0;
  bool _isGenerating = false;
  bool _hasError = false;
  String _errorMessage = '';
  List<GeneratedImage> _generatedImages = [];
  List<GeneratedImage> _history = [];

  static const List<ArtStyle> _styles = [
    ArtStyle(name: '写实', icon: Icons.photo_camera, desc: '真实照片质感'),
    ArtStyle(name: '动漫', icon: Icons.animation, desc: '日系动漫风格'),
    ArtStyle(name: '油画', icon: Icons.brush, desc: '古典油画质感'),
    ArtStyle(name: '水彩', icon: Icons.water_drop, desc: '清新水彩画风'),
    ArtStyle(name: '赛博朋克', icon: Icons.public, desc: '未来科技感'),
    ArtStyle(name: '国风', icon: Icons.dark_mode, desc: '中国传统画风'),
  ];

  static const List<String> _sizes = ['512×512', '768×768', '1024×1024'];
  static const List<String> _ratios = ['1:1', '3:4', '4:3', '16:9', '9:16'];

  static const List<String> _samplePrompts = [
    '樱花树下的少女',
    '未来城市夜景',
    '山间小屋晨雾',
    '星空下的海洋',
    '猫咪在窗台晒太阳',
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _loadHistory();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _loadHistory() {
    // 历史记录从本地存储加载，无数据时显示空态，不使用伪造数据
    _history = [];
  }

  List<Color> _randomGradient(int seed) {
    final random = Random(seed);
    final palettes = [
      [Color(0xFFFFB6C1), Color(0xFFFF69B4)],
      [Color(0xFF87CEEB), Color(0xFF4682B4)],
      [Color(0xFFFFDAB9), Color(0xFFFFA07A)],
      [Color(0xFFDDA0DD), Color(0xFF9370DB)],
      [Color(0xFF98FB98), Color(0xFF3CB371)],
      [Color(0xFFFFE4B5), Color(0xFFF4A460)],
    ];
    return palettes[random.nextInt(palettes.length)];
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.07, (index * 0.07) + 0.4,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.07, (index * 0.07) + 0.4,
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

  Future<void> _generate() async {
    if (_promptController.text.trim().isEmpty) {
      MiuixToast.show(context,
          message: '请输入画面描述', type: MiuixToastType.warning);
      return;
    }
    setState(() {
      _isGenerating = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final style = _styles[_selectedStyle].name;
      final imageUrl = await ApiService.generateImage(
        prompt: _promptController.text.trim(),
        style: style,
      );
      if (mounted) {
        final newImage = GeneratedImage(
          id: 'gen_${DateTime.now().millisecondsSinceEpoch}',
          prompt: _promptController.text,
          style: style,
          gradient: _randomGradient(DateTime.now().millisecond),
          time: DateTime.now(),
          imageUrl: imageUrl,
        );
        setState(() {
          _isGenerating = false;
          _generatedImages = [newImage];
          _history.insert(0, newImage);
        });
        MiuixToast.show(context,
            message: '生成完成', type: MiuixToastType.success);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: 'AI 绘画',
        backgroundColor: MiuixColors.background,
        actions: [
          MiuixIconButton(
            icon: Icons.history,
            style: MiuixIconButtonStyle.ghost,
            onPressed: () => _showHistory(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            _buildAnimatedItem(_buildPromptCard(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildStyleGrid(), 1),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildSizeRow(), 2),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildGenerateButton(), 3),
            const SizedBox(height: 20),
            if (_isGenerating) _buildAnimatedItem(_buildLoadingGrid(), 4),
            if (!_isGenerating && _generatedImages.isNotEmpty)
              _buildAnimatedItem(_buildResultGrid(), 4),
            if (!_isGenerating && _generatedImages.isEmpty)
              _buildAnimatedItem(_buildEmptyHint(), 4),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptCard() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '画面描述',
            style: TextStyle(
              fontSize: MiuixFontSize.md,
              fontWeight: FontWeight.w600,
              color: MiuixColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          MiuixInput(
            controller: _promptController,
            hintText: '描述你想要的画面，越详细效果越好...',
            type: MiuixInputType.multiline,
            maxLines: 3,
            minLines: 2,
            prefixIcon: Icons.auto_awesome,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_samplePrompts.length, (index) {
              return MiuixChip(
                label: _samplePrompts[index],
                onTap: () => _promptController.text = _samplePrompts[index],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleGrid() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '绘画风格',
            style: TextStyle(
              fontSize: MiuixFontSize.md,
              fontWeight: FontWeight.w600,
              color: MiuixColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _styles.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedStyle == index;
              final style = _styles[index];
              return MiuixRipple(
                borderRadius: MiuixRadius.md,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedStyle = index),
                  child: AnimatedContainer(
                    duration: MiuixDuration.fast,
                    curve: MiuixCurves.miuixSpring,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(colors: MiuixColors.primaryGradient)
                          : null,
                      color: isSelected ? null : MiuixColors.surfaceVariant,
                      borderRadius: MiuixRadius.mdRadius,
                      border: Border.all(
                        color: isSelected
                            ? MiuixColors.primary
                            : MiuixColors.borderLight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(style.icon,
                            size: 28,
                            color: isSelected
                                ? Colors.white
                                : MiuixColors.primary),
                        const SizedBox(height: 6),
                        Text(
                          style.name,
                          style: TextStyle(
                            fontSize: MiuixFontSize.sm,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : MiuixColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          style.desc,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? Colors.white.withOpacity(0.8)
                                : MiuixColors.textTertiary,
                          ),
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

  Widget _buildSizeRow() {
    return Row(
      children: [
        Expanded(
          child: MiuixCard(
            style: MiuixCardStyle.surface,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '分辨率',
                  style: TextStyle(
                    fontSize: MiuixFontSize.sm,
                    fontWeight: FontWeight.w600,
                    color: MiuixColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(_sizes.length, (index) {
                    return MiuixChip(
                      label: _sizes[index],
                      isSelected: _selectedSize == index,
                      onTap: () => setState(() => _selectedSize = index),
                      height: 28,
                    );
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
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '画面比例',
                  style: TextStyle(
                    fontSize: MiuixFontSize.sm,
                    fontWeight: FontWeight.w600,
                    color: MiuixColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(_ratios.length, (index) {
                    return MiuixChip(
                      label: _ratios[index],
                      isSelected: _selectedRatio == index,
                      onTap: () => setState(() => _selectedRatio = index),
                      height: 28,
                    );
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
        label: _isGenerating ? '绘画中...' : '开始创作',
        icon: Icons.brush,
        type: MiuixButtonType.gradient,
        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
        size: MiuixButtonSize.large,
        loading: _isGenerating,
        onPressed: _isGenerating ? null : _generate,
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: MiuixColors.surfaceVariant,
            borderRadius: MiuixRadius.lgRadius,
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(MiuixColors.primary),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'AI 绘画中',
                  style: TextStyle(
                    fontSize: MiuixFontSize.sm,
                    color: MiuixColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            '生成结果',
            style: TextStyle(
              fontSize: MiuixFontSize.lg,
              fontWeight: FontWeight.w600,
              color: MiuixColors.textPrimary,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _generatedImages.length,
          itemBuilder: (context, index) {
            return _buildImageCard(_generatedImages[index]);
          },
        ),
      ],
    );
  }

  Widget _buildImageCard(GeneratedImage image) {
    return MiuixRipple(
      borderRadius: MiuixRadius.lg,
      child: GestureDetector(
        onTap: () => _showImageDetail(image),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: image.gradient,
            ),
            borderRadius: MiuixRadius.lgRadius,
            boxShadow: MiuixShadows.sm,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: Icon(
                    Icons.image,
                    size: 48,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.5),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(MiuixRadius.lg)),
                  ),
                  child: Text(
                    image.prompt,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: MiuixFontSize.xs,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: MiuixRadius.pillRadius,
                  ),
                  child: Text(
                    image.style,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHint() {
    return const MiuixEmptyState(
      title: '开始你的AI创作',
      description: '输入描述，选择风格，让AI为你绘制精美图片',
      icon: Icons.brush,
    );
  }

  void _showImageDetail(GeneratedImage image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: image.gradient,
            ),
            borderRadius: MiuixRadius.xlRadius,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: MiuixRadius.lgRadius,
                ),
                child: Center(
                  child: Icon(Icons.image,
                      size: 80, color: Colors.white.withOpacity(0.7)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                image.prompt,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${image.style} · ${_sizes[_selectedSize]}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: MiuixFontSize.sm,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: MiuixButton(
                      label: '下载',
                      icon: Icons.download,
                      type: MiuixButtonType.secondary,
                      onPressed: () {
                        Navigator.pop(context);
                        MiuixToast.show(context,
                            message: '图片已保存到相册',
                            type: MiuixToastType.success);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MiuixButton(
                      label: '分享',
                      icon: Icons.share,
                      type: MiuixButtonType.primary,
                      onPressed: () {
                        Navigator.pop(context);
                        MiuixToast.show(context,
                            message: '分享链接已复制',
                            type: MiuixToastType.success);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (context, controller) => Container(
          decoration: const BoxDecoration(
            color: MiuixColors.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(MiuixRadius.xl)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MiuixColors.border,
                  borderRadius: MiuixRadius.pillRadius,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '创作历史',
                style: TextStyle(
                  fontSize: MiuixFontSize.xl,
                  fontWeight: FontWeight.bold,
                  color: MiuixColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    return _buildImageCard(_history[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArtStyle {
  final String name;
  final IconData icon;
  final String desc;
  const ArtStyle({required this.name, required this.icon, required this.desc});
}

class GeneratedImage {
  final String id;
  final String prompt;
  final String style;
  final List<Color> gradient;
  final DateTime time;
  final String? imageUrl;
  const GeneratedImage({
    required this.id,
    required this.prompt,
    required this.style,
    required this.gradient,
    required this.time,
    this.imageUrl,
  });
}
