import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_input.dart';
import 'package:chumian_ai/widgets/miuix/miuix_chip.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// RepostPage —— 转发页面
/// 原帖展示，转发语输入，发布按钮
/// 粉色主题，水晕反馈，错落入场
/// ============================================================

class RepostPage extends StatefulWidget {
  const RepostPage({
    super.key,
    this.originalAuthor = 'AI爱好者',
    this.originalContent = '初眠AI 3.0版本的Miuix设计语言太惊艳了，毛玻璃效果和粉色渐变搭配得恰到好处，聊天体验流畅了很多！强烈推荐大家更新体验。',
    this.originalTime = '2小时前',
  });

  final String originalAuthor;
  final String originalContent;
  final String originalTime;

  @override
  State<RepostPage> createState() => _RepostPageState();
}

class _RepostPageState extends State<RepostPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  final TextEditingController _repostController = TextEditingController();
  final FocusNode _repostFocus = FocusNode();
  bool _isPosting = false;
  int _charCount = 0;
  static const int _maxChars = 500;

  final List<String> _topics = ['#初眠AI', '#Miuix设计', '#AI体验', '#科技分享'];
  final List<String> _selectedTopics = [];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _repostController.addListener(() {
      setState(() => _charCount = _repostController.text.length);
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _repostController.dispose();
    _repostFocus.dispose();
    super.dispose();
  }

  Future<void> _submitRepost() async {
    if (_isPosting) return;
    setState(() => _isPosting = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _isPosting = false);
    Navigator.of(context).pop(true);
  }

  void _toggleTopic(String topic) {
    setState(() {
      if (_selectedTopics.contains(topic)) {
        _selectedTopics.remove(topic);
      } else {
        if (_selectedTopics.length < 3) {
          _selectedTopics.add(topic);
          final text = _repostController.text;
          _repostController.text = text.isEmpty ? '$topic ' : '$text $topic ';
          _repostController.selection = TextSelection.fromPosition(
            TextPosition(offset: _repostController.text.length),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '转发',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: MiuixSpacing.md),
            child: MiuixButton(
              label: '发布',
              type: MiuixButtonType.primary,
              size: MiuixButtonSize.small,
              loading: _isPosting,
              disabled: _isPosting,
              onPressed: _submitRepost,
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _entryController,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MiuixSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRepostInput(),
              const SizedBox(height: MiuixSpacing.md),
              _buildTopicSelector(),
              const SizedBox(height: MiuixSpacing.md),
              _buildOriginalPost(),
              const SizedBox(height: MiuixSpacing.md),
              _buildVisibilityOptions(),
              const SizedBox(height: MiuixSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepostInput() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.6, curve: MiuixCurves.easeOut),
      )),
      child: MiuixCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person, size: 20, color: Colors.white),
                ),
                const SizedBox(width: MiuixSpacing.md),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '我的账号',
                      style: TextStyle(
                        fontSize: MiuixFontSize.md,
                        fontWeight: FontWeight.w600,
                        color: MiuixColors.textPrimary,
                      ),
                    ),
                    Text(
                      '转发到社区',
                      style: TextStyle(
                        fontSize: MiuixFontSize.xs,
                        color: MiuixColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: MiuixSpacing.md),
            TextField(
              controller: _repostController,
              focusNode: _repostFocus,
              maxLines: 5,
              maxLength: _maxChars,
              cursorColor: MiuixColors.primary,
              style: const TextStyle(
                fontSize: MiuixFontSize.md,
                color: MiuixColors.textPrimary,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: '说点什么吧...',
                hintStyle: const TextStyle(
                  fontSize: MiuixFontSize.md,
                  color: MiuixColors.textTertiary,
                ),
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Row(
              children: [
                MiuixRipple(
                  onTap: () {},
                  borderRadius: MiuixRadius.pill,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.image_outlined, size: 20, color: MiuixColors.textTertiary),
                  ),
                ),
                MiuixRipple(
                  onTap: () {},
                  borderRadius: MiuixRadius.pill,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.emoji_emotions_outlined, size: 20, color: MiuixColors.textTertiary),
                  ),
                ),
                MiuixRipple(
                  onTap: () {},
                  borderRadius: MiuixRadius.pill,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.article_outlined, size: 20, color: MiuixColors.textTertiary),
                  ),
                ),
                const Spacer(),
                Text(
                  '$_charCount/$_maxChars',
                  style: TextStyle(
                    fontSize: MiuixFontSize.xs,
                    color: _charCount > _maxChars * 0.9
                        ? MiuixColors.error
                        : MiuixColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicSelector() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.1, 0.7, curve: MiuixCurves.easeOut),
      )),
      child: MiuixCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tag, size: 16, color: MiuixColors.primary),
                SizedBox(width: 6),
                Text(
                  '添加话题',
                  style: TextStyle(
                    fontSize: MiuixFontSize.md,
                    fontWeight: FontWeight.w600,
                    color: MiuixColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: MiuixSpacing.md),
            Wrap(
              spacing: MiuixSpacing.sm,
              runSpacing: MiuixSpacing.sm,
              children: _topics.map((topic) {
                final isSelected = _selectedTopics.contains(topic);
                return MiuixChip(
                  label: topic,
                  isSelected: isSelected,
                  onTap: () => _toggleTopic(topic),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOriginalPost() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 0.8, curve: MiuixCurves.easeOut),
      )),
      child: Container(
        padding: const EdgeInsets.all(MiuixSpacing.md),
        decoration: BoxDecoration(
          color: MiuixColors.surfaceVariant.withValues(alpha: 0.6),
          borderRadius: MiuixRadius.lgRadius,
          border: Border.all(color: MiuixColors.borderLight, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: MiuixColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      widget.originalAuthor[0],
                      style: const TextStyle(
                        fontSize: MiuixFontSize.sm,
                        fontWeight: FontWeight.w700,
                        color: MiuixColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: MiuixSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.originalAuthor,
                        style: const TextStyle(
                          fontSize: MiuixFontSize.sm,
                          fontWeight: FontWeight.w600,
                          color: MiuixColors.textSecondary,
                        ),
                      ),
                      Text(
                        widget.originalTime,
                        style: const TextStyle(
                          fontSize: MiuixFontSize.xs,
                          color: MiuixColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: MiuixColors.primary.withValues(alpha: 0.1),
                    borderRadius: MiuixRadius.xsRadius,
                  ),
                  child: const Text(
                    '原帖',
                    style: TextStyle(fontSize: 10, color: MiuixColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MiuixSpacing.sm),
            Text(
              widget.originalContent,
              style: const TextStyle(
                fontSize: MiuixFontSize.sm,
                color: MiuixColors.textSecondary,
                height: 1.5,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityOptions() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.3, 0.9, curve: MiuixCurves.easeOut),
      )),
      child: MiuixCard(
        child: Column(
          children: [
            _buildOptionRow(Icons.public, '公开', '所有人可见', true),
            _buildDivider(),
            _buildOptionRow(Icons.lock_outline, '仅粉丝', '仅粉丝可见', false),
            _buildDivider(),
            _buildOptionRow(Icons.lock, '私密', '仅自己可见', false),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionRow(IconData icon, String title, String desc, bool selected) {
    return MiuixRipple(
      onTap: () {},
      borderRadius: MiuixRadius.md,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: MiuixSpacing.sm),
        child: Row(
          children: [
            Icon(icon, size: 20, color: selected ? MiuixColors.primary : MiuixColors.textTertiary),
            const SizedBox(width: MiuixSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: MiuixFontSize.md,
                      fontWeight: FontWeight.w500,
                      color: selected ? MiuixColors.primary : MiuixColors.textPrimary,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: MiuixFontSize.xs,
                      color: MiuixColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, size: 20, color: MiuixColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: MiuixColors.divider,
    );
  }
}
