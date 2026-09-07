import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_input.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// ContactUsPage —— 联系我们
/// 联系方式(邮箱/QQ群/公众号)，反馈表单，mascot形象
/// 粉色主题，错落入场动画
/// ============================================================

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  String _feedbackType = '功能建议';
  bool _isSubmitting = false;

  static const List<String> _feedbackTypes = ['功能建议', 'Bug反馈', '体验问题', '其他'];

  static const List<Map<String, dynamic>> _contactMethods = [
    {
      'icon': Icons.email_outlined,
      'title': '客服邮箱',
      'value': 'support@chumian.ai',
      'color': MiuixColors.primary,
      'action': '复制',
    },
    {
      'icon': Icons.people_outline,
      'title': '官方QQ群',
      'value': '123456789',
      'color': MiuixColors.info,
      'action': '加群',
    },
    {
      'icon': Icons.chat_outlined,
      'title': '微信公众号',
      'value': '初眠AI',
      'color': MiuixColors.success,
      'action': '关注',
    },
    {
      'icon': Icons.headset_mic_outlined,
      'title': '在线客服',
      'value': '工作日 9:00-22:00',
      'color': MiuixColors.warning,
      'action': '咨询',
    },
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
    _feedbackController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    _feedbackController.clear();
    _contactController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('反馈提交成功，感谢您的建议！'),
        backgroundColor: MiuixColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: MiuixRadius.lgRadius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: const MiuixAppBar(title: '联系我们'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.md),
        child: Column(
          children: [
            _buildMascotHeader(),
            const SizedBox(height: MiuixSpacing.lg),
            _buildContactMethods(),
            const SizedBox(height: MiuixSpacing.lg),
            _buildFeedbackForm(),
            const SizedBox(height: MiuixSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildMascotHeader() {
    return FadeTransition(
      opacity: _entryController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _entryController,
          curve: const Interval(0.0, 0.5, curve: MiuixCurves.easeOut),
        )),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(MiuixSpacing.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                MiuixColors.primary.withOpacity(0.08),
                MiuixColors.primaryLight.withOpacity(0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: MiuixRadius.xlRadius,
            border: Border.all(color: MiuixColors.primary.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: MiuixColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: MiuixColors.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
              ),
              const SizedBox(height: MiuixSpacing.md),
              const Text(
                '初眠AI团队',
                style: TextStyle(
                  fontSize: MiuixFontSize.xl,
                  fontWeight: FontWeight.w700,
                  color: MiuixColors.textPrimary,
                ),
              ),
              const SizedBox(height: MiuixSpacing.xs),
              const Text(
                '我们随时倾听您的声音\n您的每一条反馈都是我们前进的动力',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: MiuixFontSize.sm,
                  color: MiuixColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactMethods() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.1, 0.6, curve: MiuixCurves.easeOut),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: MiuixSpacing.xs),
            child: Text(
              '联系方式',
              style: TextStyle(
                fontSize: MiuixFontSize.lg,
                fontWeight: FontWeight.w600,
                color: MiuixColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: MiuixSpacing.md),
          ..._contactMethods.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: MiuixSpacing.sm),
              child: _buildContactCard(entry.value, entry.key),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> method, int index) {
    final anim = CurvedAnimation(
      parent: _entryController,
      curve: Interval(
        0.15 + index * 0.05,
        1.0,
        curve: MiuixCurves.easeOut,
      ),
    );

    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.05, 0),
          end: Offset.zero,
        ).animate(anim),
        child: MiuixCard(
          onTap: () {},
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (method['color'] as Color).withOpacity(0.1),
                  borderRadius: MiuixRadius.mdRadius,
                ),
                child: Icon(
                  method['icon'] as IconData,
                  size: 22,
                  color: method['color'] as Color,
                ),
              ),
              const SizedBox(width: MiuixSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method['title'] as String,
                      style: const TextStyle(
                        fontSize: MiuixFontSize.md,
                        fontWeight: FontWeight.w600,
                        color: MiuixColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      method['value'] as String,
                      style: const TextStyle(
                        fontSize: MiuixFontSize.sm,
                        color: MiuixColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: MiuixSpacing.md, vertical: 6),
                decoration: BoxDecoration(
                  color: MiuixColors.primary.withOpacity(0.08),
                  borderRadius: MiuixRadius.pillRadius,
                ),
                child: Text(
                  method['action'] as String,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.sm,
                    fontWeight: FontWeight.w500,
                    color: MiuixColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackForm() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.3, 0.8, curve: MiuixCurves.easeOut),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: MiuixSpacing.xs),
            child: Text(
              '意见反馈',
              style: TextStyle(
                fontSize: MiuixFontSize.lg,
                fontWeight: FontWeight.w600,
                color: MiuixColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: MiuixSpacing.md),
          MiuixCard(
            padding: const EdgeInsets.all(MiuixSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '反馈类型',
                  style: TextStyle(
                    fontSize: MiuixFontSize.sm,
                    fontWeight: FontWeight.w600,
                    color: MiuixColors.textSecondary,
                  ),
                ),
                const SizedBox(height: MiuixSpacing.sm),
                Wrap(
                  spacing: MiuixSpacing.sm,
                  runSpacing: MiuixSpacing.sm,
                  children: _feedbackTypes.map((type) {
                    final isSelected = _feedbackType == type;
                    return MiuixChip(
                      label: type,
                      isSelected: isSelected,
                      onTap: () => setState(() => _feedbackType = type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: MiuixSpacing.lg),
                const Text(
                  '反馈内容',
                  style: TextStyle(
                    fontSize: MiuixFontSize.sm,
                    fontWeight: FontWeight.w600,
                    color: MiuixColors.textSecondary,
                  ),
                ),
                const SizedBox(height: MiuixSpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    color: MiuixColors.surfaceVariant,
                    borderRadius: MiuixRadius.mdRadius,
                    border: Border.all(color: MiuixColors.borderLight, width: 1),
                  ),
                  child: TextField(
                    controller: _feedbackController,
                    maxLines: 5,
                    maxLength: 500,
                    cursorColor: MiuixColors.primary,
                    style: const TextStyle(
                      fontSize: MiuixFontSize.md,
                      color: MiuixColors.textPrimary,
                      height: 1.5,
                    ),
                    decoration: const InputDecoration(
                      hintText: '请详细描述您的问题或建议，我们会认真对待每一条反馈...',
                      hintStyle: TextStyle(
                        fontSize: MiuixFontSize.md,
                        color: MiuixColors.textTertiary,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(MiuixSpacing.md),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(height: MiuixSpacing.md),
                MiuixInput(
                  controller: _contactController,
                  hintText: '联系方式（选填，便于我们回复您）',
                  prefixIcon: Icons.contact_phone_outlined,
                ),
                const SizedBox(height: MiuixSpacing.lg),
                MiuixButton(
                  label: '提交反馈',
                  type: MiuixButtonType.primary,
                  icon: Icons.send,
                  loading: _isSubmitting,
                  disabled: _isSubmitting || _feedbackController.text.trim().isEmpty,
                  onPressed: _submitFeedback,
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
