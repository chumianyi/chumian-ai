import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_chip.dart';
import 'package:chumian_ai/widgets/miuix/miuix_input.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// CreatePostPage —— 发帖页
/// 标题输入，内容输入(多行)，图片添加，类型选择，发布按钮
/// 粉色输入框
/// ============================================================
class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  int _selectedType = 0;
  List<String> _images = [];
  bool _isPublishing = false;
  bool _allowComment = true;
  bool _isPublic = true;

  static const List<String> _postTypes = ['分享', '教程', '提问', '活动', '其他'];
  static const List<IconData> _typeIcons = [
    Icons.share,
    Icons.menu_book,
    Icons.help_outline,
    Icons.event,
    Icons.more_horiz,
  ];

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
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
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
      begin: const Offset(0, 0.05),
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

  Future<void> _publish() async {
    if (_titleController.text.trim().isEmpty) {
      MiuixToast.show(context,
          message: '请输入帖子标题', type: MiuixToastType.warning);
      return;
    }
    if (_contentController.text.trim().isEmpty) {
      MiuixToast.show(context,
          message: '请输入帖子内容', type: MiuixToastType.warning);
      return;
    }
    setState(() => _isPublishing = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() => _isPublishing = false);
    MiuixToast.show(context,
        message: '发布成功！', type: MiuixToastType.success);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) Navigator.pop(context);
    });
  }

  void _addImage() {
    if (_images.length >= 9) {
      MiuixToast.show(context,
          message: '最多添加9张图片', type: MiuixToastType.warning);
      return;
    }
    setState(() {
      _images.add('image_${DateTime.now().millisecondsSinceEpoch}');
    });
    MiuixToast.show(context,
        message: '图片已添加', type: MiuixToastType.success);
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '发布帖子',
        backgroundColor: MiuixColors.background,
        actions: [
          TextButton(
            onPressed: _isPublishing ? null : _saveDraft,
            child: const Text(
              '存草稿',
              style: TextStyle(color: MiuixColors.primary, fontSize: 14),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            _buildAnimatedItem(_buildTypeSelector(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildTitleInput(), 1),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildContentInput(), 2),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildImageSection(), 3),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildSettings(), 4),
            const SizedBox(height: 24),
            _buildAnimatedItem(_buildPublishButton(), 5),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '帖子类型',
            style: TextStyle(
              fontSize: MiuixFontSize.md,
              fontWeight: FontWeight.w600,
              color: MiuixColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_postTypes.length, (index) {
              final isSelected = _selectedType == index;
              return MiuixRipple(
                borderRadius: MiuixRadius.md,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedType = index),
                  child: AnimatedContainer(
                    duration: MiuixDuration.fast,
                    curve: MiuixCurves.miuixSpring,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _typeIcons[index],
                          size: 18,
                          color: isSelected
                              ? Colors.white
                              : MiuixColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _postTypes[index],
                          style: TextStyle(
                            fontSize: MiuixFontSize.sm,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : MiuixColors.textSecondary,
                          ),
                        ),
                      ],
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

  Widget _buildTitleInput() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '标题',
                style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${_titleController.text.length}/30',
                style: TextStyle(
                  fontSize: MiuixFontSize.xs,
                  color: _titleController.text.length > 30
                      ? MiuixColors.error
                      : MiuixColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MiuixInput(
            controller: _titleController,
            hintText: '输入吸引人的标题...',
            prefixIcon: Icons.title,
            maxLength: 30,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildContentInput() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '正文',
                style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${_contentController.text.length}/2000',
                style: TextStyle(
                  fontSize: MiuixFontSize.xs,
                  color: _contentController.text.length > 2000
                      ? MiuixColors.error
                      : MiuixColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MiuixInput(
            controller: _contentController,
            hintText: '分享你的想法、经验或问题...',
            type: MiuixInputType.multiline,
            maxLines: 8,
            minLines: 5,
            maxLength: 2000,
            prefixIcon: Icons.edit,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '添加图片',
                style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${_images.length}/9',
                style: const TextStyle(
                  fontSize: MiuixFontSize.xs,
                  color: MiuixColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _images.length + 1,
            itemBuilder: (context, index) {
              if (index == _images.length) {
                return MiuixRipple(
                  borderRadius: MiuixRadius.md,
                  child: GestureDetector(
                    onTap: _addImage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: MiuixColors.surfaceVariant,
                        borderRadius: MiuixRadius.mdRadius,
                        border: Border.all(
                          color: MiuixColors.border,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo,
                              color: MiuixColors.primary, size: 28),
                          SizedBox(height: 4),
                          Text(
                            '添加图片',
                            style: TextStyle(
                              fontSize: MiuixFontSize.xs,
                              color: MiuixColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          MiuixColors.primaryLight.withOpacity(0.4),
                          MiuixColors.primary.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: MiuixRadius.mdRadius,
                    ),
                    child: const Center(
                      child: Icon(Icons.image,
                          color: Colors.white, size: 32),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          _buildSettingRow(
            icon: Icons.comment,
            title: '允许评论',
            subtitle: '其他用户可以评论你的帖子',
            value: _allowComment,
            onChanged: (v) => setState(() => _allowComment = v),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 72),
            child: Container(height: 1, color: MiuixColors.divider),
          ),
          _buildSettingRow(
            icon: Icons.public,
            title: '公开可见',
            subtitle: '所有人可见，关闭后仅自己可见',
            value: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MiuixColors.primaryLight.withOpacity(0.15),
              borderRadius: MiuixRadius.smRadius,
            ),
            child: Icon(icon, color: MiuixColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.md,
                    fontWeight: FontWeight.w500,
                    color: MiuixColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.xs,
                    color: MiuixColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: MiuixColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPublishButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: _isPublishing ? '发布中...' : '发布帖子',
        icon: Icons.send,
        type: MiuixButtonType.gradient,
        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
        size: MiuixButtonSize.large,
        loading: _isPublishing,
        onPressed: _isPublishing ? null : _publish,
      ),
    );
  }

  void _saveDraft() {
    MiuixToast.show(context,
        message: '草稿已保存', type: MiuixToastType.success);
  }
}
