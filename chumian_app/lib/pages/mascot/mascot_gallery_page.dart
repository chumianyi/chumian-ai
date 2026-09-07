import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// MascotGalleryPage —— 吉祥物画廊
/// mascot 图片展示，不同表情/姿态，粉色背景
/// 点击放大，角色介绍
/// ============================================================
class MascotGalleryPage extends StatefulWidget {
  const MascotGalleryPage({super.key});

  @override
  State<MascotGalleryPage> createState() => _MascotGalleryPageState();
}

class _MascotGalleryPageState extends State<MascotGalleryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  int _selectedCategory = 0;

  static const List<String> _categories = ['全部', '表情', '姿态', '节日', '周边'];

  static const List<MascotImage> _images = [
    MascotImage(id: '1', name: '初眠·微笑', emoji: '😊', category: '表情', desc: '温暖治愈的微笑，是初眠最经典的表情', gradient: [Color(0xFFFFB6C1), Color(0xFFFF69B4)]),
    MascotImage(id: '2', name: '初眠·开心', emoji: '😄', category: '表情', desc: '开心大笑的样子，眼睛都眯成了月牙', gradient: [Color(0xFFFFD700), Color(0xFFFFA500)]),
    MascotImage(id: '3', name: '初眠·思考', emoji: '🤔', category: '表情', desc: '认真思考问题时的样子，手托下巴', gradient: [Color(0xFF87CEEB), Color(0xFF4682B4)]),
    MascotImage(id: '4', name: '初眠·害羞', emoji: '😳', category: '表情', desc: '被夸奖时会害羞地脸红', gradient: [Color(0xFFFFB6C1), Color(0xFFFF8FB5)]),
    MascotImage(id: '5', name: '初眠·坐姿', emoji: '🧘', category: '姿态', desc: '优雅地坐着，安静地陪伴你', gradient: [Color(0xFFDDA0DD), Color(0xFF9370DB)]),
    MascotImage(id: '6', name: '初眠·跳跃', emoji: '💃', category: '姿态', desc: '开心到跳起来的活泼姿态', gradient: [Color(0xFF98FB98), Color(0xFF3CB371)]),
    MascotImage(id: '7', name: '初眠·挥手', emoji: '👋', category: '姿态', desc: '热情地挥手打招呼', gradient: [Color(0xFFFFE4B5), Color(0xFFF4A460)]),
    MascotImage(id: '8', name: '初眠·春节', emoji: '🧧', category: '节日', desc: '春节限定造型，拿着红包拜年', gradient: [Color(0xFFFF6B6B), Color(0xFFEE5A5A)]),
    MascotImage(id: '9', name: '初眠·中秋', emoji: '🥮', category: '节日', desc: '中秋限定，和月亮一起吃月饼', gradient: [Color(0xFFFFE4B5), Color(0xFFDEB887)]),
    MascotImage(id: '10', name: '初眠·圣诞', emoji: '🎄', category: '节日', desc: '圣诞限定，戴着圣诞帽', gradient: [Color(0xFF90EE90), Color(0xFF228B22)]),
    MascotImage(id: '11', name: '初眠·钥匙扣', emoji: '🔑', category: '周边', desc: '可爱的钥匙扣周边', gradient: [Color(0xFFFFB6C1), Color(0xFFFF69B4)]),
    MascotImage(id: '12', name: '初眠·公仔', emoji: '🧸', category: '周边', desc: '柔软的毛绒公仔，抱起来很舒服', gradient: [Color(0xFFDDA0DD), Color(0xFF9370DB)]),
  ];

  List<MascotImage> get _filteredImages {
    if (_selectedCategory == 0) return _images;
    return _images
        .where((img) => img.category == _categories[_selectedCategory])
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.04, (index * 0.04) + 0.3,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.04, (index * 0.04) + 0.3,
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

  void _showImageDetail(MascotImage image) {
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: MiuixRadius.xlRadius,
                ),
                child: Center(
                  child: Text(image.emoji, style: const TextStyle(fontSize: 80)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                image.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: MiuixFontSize.xl,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: MiuixRadius.pillRadius,
                ),
                child: Text(
                  image.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: MiuixFontSize.xs,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                image.desc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: MiuixFontSize.md,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: MiuixIconButton(
                      icon: Icons.download,
                      style: MiuixIconButtonStyle.glass,
                      onPressed: () {
                        Navigator.pop(context);
                        MiuixToast.show(context,
                            message: '图片已保存', type: MiuixToastType.success);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MiuixIconButton(
                      icon: Icons.share,
                      style: MiuixIconButtonStyle.glass,
                      onPressed: () {
                        Navigator.pop(context);
                        MiuixToast.show(context,
                            message: '分享链接已复制',
                            type: MiuixToastType.success);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MiuixIconButton(
                      icon: Icons.close,
                      style: MiuixIconButtonStyle.glass,
                      onPressed: () => Navigator.pop(context),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '吉祥物画廊',
        backgroundColor: MiuixColors.background,
      ),
      body: Column(
        children: [
          _buildCategoryBar(),
          _buildCharacterIntro(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: _filteredImages.length,
              itemBuilder: (context, index) {
                return _buildAnimatedItem(
                  _buildImageCard(_filteredImages[index]),
                  index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategory == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: MiuixRipple(
              borderRadius: MiuixRadius.pill,
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategory = index),
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
                    _categories[index],
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
        },
      ),
    );
  }

  Widget _buildCharacterIntro() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)],
        ),
        borderRadius: MiuixRadius.lgRadius,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
              borderRadius: MiuixRadius.xlRadius,
            ),
            child: const Center(
              child: Text('🌸', style: TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '初眠 (Chumian)',
                  style: TextStyle(
                    fontSize: MiuixFontSize.lg,
                    fontWeight: FontWeight.bold,
                    color: MiuixColors.primaryDeep,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '初眠AI的吉祥物，一只温柔治愈的小精灵，陪伴你度过每一个美好的瞬间。',
                  style: TextStyle(
                    fontSize: MiuixFontSize.xs,
                    color: MiuixColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(MascotImage image) {
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
              Center(
                child: Text(image.emoji, style: const TextStyle(fontSize: 56)),
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
                        Colors.black.withOpacity(0.4),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(MiuixRadius.lg)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        image.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: MiuixFontSize.sm,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        image.category,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: MiuixFontSize.xs,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MascotImage {
  final String id;
  final String name;
  final String emoji;
  final String category;
  final String desc;
  final List<Color> gradient;
  const MascotImage({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.desc,
    required this.gradient,
  });
}
