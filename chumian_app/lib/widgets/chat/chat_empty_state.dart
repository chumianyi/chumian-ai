import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// ChatEmptyState —— 聊天空状态
/// mascot 图片，欢迎语，模型信息，建议问题标签(点击发送)
/// 错落入场动画，粉色主题
/// ============================================================

class ChatEmptyState extends StatefulWidget {
  const ChatEmptyState({
    super.key,
    this.title = '你好，我是初眠AI',
    this.subtitle = '有什么可以帮你的吗？',
    this.modelName = 'glm-4-flash',
    this.suggestions = const [
      '帮我写一首关于春天的诗',
      '解释一下量子力学的基本原理',
      '推荐几本适合初学者的编程书籍',
      '帮我制定一个一周健身计划',
    ],
    this.onSuggestionTap,
    this.mascotImage,
  });

  /// 欢迎标题
  final String title;

  /// 欢迎副标题
  final String subtitle;

  /// 当前模型名
  final String modelName;

  /// 建议问题列表
  final List<String> suggestions;

  /// 建议问题点击回调
  final ValueChanged<String>? onSuggestionTap;

  /// mascot 图片路径
  final String? mascotImage;

  @override
  State<ChatEmptyState> createState() => _ChatEmptyStateState();
}

class _ChatEmptyStateState extends State<ChatEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _fadeAnim(double delay) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(delay, 1.0, curve: MiuixCurves.easeOut),
    );
  }

  Animation<Offset> _slideAnim(double delay, {Offset? begin}) {
    return Tween<Offset>(
      begin: begin ?? const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(delay, 1.0, curve: MiuixCurves.easeOut),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MiuixSpacing.xl,
          vertical: MiuixSpacing.xxl,
        ),
        child: Column(
          children: [
            const SizedBox(height: MiuixSpacing.xxxl),
            _buildMascot(),
            const SizedBox(height: MiuixSpacing.xl),
            _buildWelcomeText(),
            const SizedBox(height: MiuixSpacing.md),
            _buildModelBadge(),
            const SizedBox(height: MiuixSpacing.xxl),
            _buildSuggestions(),
            const SizedBox(height: MiuixSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildMascot() {
    return FadeTransition(
      opacity: _fadeAnim(0.0),
      child: SlideTransition(
        position: _slideAnim(0.0),
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: MiuixColors.softGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: MiuixColors.primary.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: MiuixColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: MiuixShadows.sm,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: MiuixColors.primary,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return FadeTransition(
      opacity: _fadeAnim(0.15),
      child: SlideTransition(
        position: _slideAnim(0.15),
        child: Column(
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: MiuixFontSize.xxl,
                fontWeight: FontWeight.w700,
                color: MiuixColors.textPrimary,
              ),
            ),
            const SizedBox(height: MiuixSpacing.sm),
            Text(
              widget.subtitle,
              style: const TextStyle(
                fontSize: MiuixFontSize.md,
                color: MiuixColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelBadge() {
    return FadeTransition(
      opacity: _fadeAnim(0.25),
      child: SlideTransition(
        position: _slideAnim(0.25),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: MiuixSpacing.md,
            vertical: MiuixSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: MiuixColors.primary.withValues(alpha: 0.08),
            borderRadius: MiuixRadius.pillRadius,
            border: Border.all(
              color: MiuixColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 14,
                color: MiuixColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '当前模型：${widget.modelName}',
                style: const TextStyle(
                  fontSize: MiuixFontSize.sm,
                  fontWeight: FontWeight.w500,
                  color: MiuixColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return FadeTransition(
      opacity: _fadeAnim(0.35),
      child: SlideTransition(
        position: _slideAnim(0.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: MiuixSpacing.xs),
              child: Text(
                '试试这些',
                style: TextStyle(
                  fontSize: MiuixFontSize.sm,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: MiuixSpacing.sm),
            ...widget.suggestions.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: MiuixSpacing.sm),
                child: _buildSuggestionCard(
                  entry.value,
                  entry.key,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(String text, int index) {
    final icons = [
      Icons.edit_note,
      Icons.science,
      Icons.menu_book,
      Icons.fitness_center,
    ];
    final icon = icons[index % icons.length];

    return MiuixRipple(
      onTap: () => widget.onSuggestionTap?.call(text),
      borderRadius: MiuixRadius.lg,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final anim = CurvedAnimation(
            parent: _controller,
            curve: Interval(
              0.4 + index * 0.08,
              1.0,
              curve: MiuixCurves.easeOut,
            ),
          );
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(MiuixSpacing.md),
          decoration: BoxDecoration(
            color: MiuixColors.surface,
            borderRadius: MiuixRadius.lgRadius,
            border: Border.all(color: MiuixColors.borderLight, width: 1),
            boxShadow: MiuixShadows.xs,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: MiuixColors.softGradient,
                  ),
                  borderRadius: MiuixRadius.smRadius,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: MiuixColors.primary,
                ),
              ),
              const SizedBox(width: MiuixSpacing.md),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.md,
                    color: MiuixColors.textPrimary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: MiuixColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
