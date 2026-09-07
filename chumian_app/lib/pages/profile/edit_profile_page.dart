import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_input.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_segment.dart';

/// ============================================================
/// EditProfilePage —— 编辑资料
/// 头像上传，昵称，签名，生日，QQ，性别，保存按钮，粉色输入框
/// ============================================================
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  final TextEditingController _nicknameController =
      TextEditingController(text: '初眠用户');
  final TextEditingController _bioController =
      TextEditingController(text: '这个人很懒，什么都没留下~');
  final TextEditingController _qqController = TextEditingController(text: '');
  final TextEditingController _birthdayController =
      TextEditingController(text: '2000-01-01');

  int _gender = 0; // 0: 保密, 1: 男, 2: 女
  bool _isSaving = false;

  static const List<String> _genders = ['保密', '男', '女'];
  static const List<IconData> _genderIcons = [
    Icons.lock_outline,
    Icons.male,
    Icons.female,
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
    _nicknameController.dispose();
    _bioController.dispose();
    _qqController.dispose();
    _birthdayController.dispose();
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

  Future<void> _save() async {
    if (_nicknameController.text.trim().isEmpty) {
      MiuixToast.show(context,
          message: '昵称不能为空', type: MiuixToastType.warning);
      return;
    }
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _isSaving = false);
    MiuixToast.show(context,
        message: '资料保存成功', type: MiuixToastType.success);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _pickBirthday() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: MiuixColors.primary,
              onPrimary: Colors.white,
              surface: MiuixColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      _birthdayController.text =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '编辑资料',
        backgroundColor: MiuixColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            _buildAnimatedItem(_buildAvatarSection(), 0),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildBasicInfo(), 1),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildGenderSelector(), 2),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildBirthdaySection(), 3),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildContactInfo(), 4),
            const SizedBox(height: 24),
            _buildAnimatedItem(_buildSaveButton(), 5),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: MiuixColors.primaryGradient,
                  ),
                  borderRadius: MiuixRadius.xlRadius,
                  boxShadow: MiuixShadows.md,
                ),
                child: const Center(
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: MiuixIconButton(
                  icon: Icons.camera_alt,
                  style: MiuixIconButtonStyle.filled,
                  size: 36,
                  iconSize: 18,
                  onPressed: () {
                    MiuixToast.show(context,
                        message: '选择头像图片', type: MiuixToastType.info);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '点击更换头像',
            style: TextStyle(
              fontSize: MiuixFontSize.sm,
              color: MiuixColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '支持 JPG/PNG，最大 5MB',
            style: TextStyle(
              fontSize: MiuixFontSize.xs,
              color: MiuixColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '基本信息',
            style: TextStyle(
              fontSize: MiuixFontSize.lg,
              fontWeight: FontWeight.w600,
              color: MiuixColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '昵称',
            style: TextStyle(
              fontSize: MiuixFontSize.md,
              fontWeight: FontWeight.w500,
              color: MiuixColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          MiuixInput(
            controller: _nicknameController,
            hintText: '请输入昵称',
            prefixIcon: Icons.person_outline,
            maxLength: 20,
          ),
          const SizedBox(height: 16),
          const Text(
            '个性签名',
            style: TextStyle(
              fontSize: MiuixFontSize.md,
              fontWeight: FontWeight.w500,
              color: MiuixColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          MiuixInput(
            controller: _bioController,
            hintText: '介绍一下自己吧...',
            type: MiuixInputType.multiline,
            maxLines: 3,
            minLines: 2,
            maxLength: 50,
            prefixIcon: Icons.edit_note,
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '性别',
            style: TextStyle(
              fontSize: MiuixFontSize.md,
              fontWeight: FontWeight.w500,
              color: MiuixColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_genders.length, (index) {
              final isSelected = _gender == index;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 2 ? 10 : 0),
                  child: MiuixRipple(
                    borderRadius: MiuixRadius.md,
                    child: GestureDetector(
                      onTap: () => setState(() => _gender = index),
                      child: AnimatedContainer(
                        duration: MiuixDuration.fast,
                        curve: MiuixCurves.miuixSpring,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: MiuixColors.primaryGradient)
                              : null,
                          color: isSelected
                              ? null
                              : MiuixColors.surfaceVariant,
                          borderRadius: MiuixRadius.mdRadius,
                          border: Border.all(
                            color: isSelected
                                ? MiuixColors.primary
                                : MiuixColors.borderLight,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _genderIcons[index],
                              size: 24,
                              color: isSelected
                                  ? Colors.white
                                  : MiuixColors.primary,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _genders[index],
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
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthdaySection() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '生日',
            style: TextStyle(
              fontSize: MiuixFontSize.md,
              fontWeight: FontWeight.w500,
              color: MiuixColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          MiuixRipple(
            borderRadius: MiuixRadius.md,
            child: GestureDetector(
              onTap: _pickBirthday,
              child: AbsorbPointer(
                child: MiuixInput(
                  controller: _birthdayController,
                  hintText: '选择生日',
                  prefixIcon: Icons.cake,
                  enabled: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '联系方式',
            style: TextStyle(
              fontSize: MiuixFontSize.lg,
              fontWeight: FontWeight.w600,
              color: MiuixColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'QQ 号',
            style: TextStyle(
              fontSize: MiuixFontSize.md,
              fontWeight: FontWeight.w500,
              color: MiuixColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          MiuixInput(
            controller: _qqController,
            hintText: '请输入 QQ 号（选填）',
            type: MiuixInputType.number,
            prefixIcon: Icons.chat_bubble_outline,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MiuixColors.primaryLight.withOpacity(0.1),
              borderRadius: MiuixRadius.smRadius,
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: MiuixColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '联系方式仅对互相关注的好友可见',
                    style: TextStyle(
                      fontSize: MiuixFontSize.xs,
                      color: MiuixColors.textSecondary,
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

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: _isSaving ? '保存中...' : '保存修改',
        icon: Icons.save,
        type: MiuixButtonType.gradient,
        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
        size: MiuixButtonSize.large,
        loading: _isSaving,
        onPressed: _isSaving ? null : _save,
      ),
    );
  }
}
