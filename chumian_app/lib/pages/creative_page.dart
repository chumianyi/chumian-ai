import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_glass.dart';
import 'package:chumian_ai/providers/theme_provider.dart';
import 'package:chumian_ai/pages/chat_page.dart';

/// ============================================================
/// CreativePage —— 创意工坊
/// AI创作模板列表，点击进入聊天并带入prompt
/// ============================================================
class CreativePage extends StatefulWidget {
  const CreativePage({super.key});

  @override
  State<CreativePage> createState() => _CreativePageState();
}

class _CreativePageState extends State<CreativePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const List<CreativeTemplate> _templates = [
    CreativeTemplate(
      id: 'article',
      icon: Icons.edit_note,
      title: '写文章',
      description: '根据主题生成结构完整、文笔流畅的文章',
      gradient: [Color(0xFFFF8FB5), Color(0xFFFF6B9D)],
      prompt: '请帮我写一篇关于',
    ),
    CreativeTemplate(
      id: 'translate',
      icon: Icons.translate,
      title: '翻译',
      description: '支持中英日韩等多语言互译，准确自然',
      gradient: [Color(0xFFFFB3C9), Color(0xFFFF8FB5)],
      prompt: '请将以下内容翻译成英文：',
    ),
    CreativeTemplate(
      id: 'summary',
      icon: Icons.summarize,
      title: '总结',
      description: '快速提炼长文本的核心要点和关键信息',
      gradient: [Color(0xFFFF9DBB), Color(0xFFFF6B9D)],
      prompt: '请帮我总结以下内容的核心要点：',
    ),
    CreativeTemplate(
      id: 'code',
      icon: Icons.code,
      title: '写代码',
      description: '生成、解释、优化代码，支持多种编程语言',
      gradient: [Color(0xFFFFC0D6), Color(0xFFFF9DBB)],
      prompt: '请帮我用Python写一个',
    ),
    CreativeTemplate(
      id: 'poem',
      icon: Icons.auto_awesome,
      title: '写诗',
      description: '创作古诗词、现代诗，风格多样意境优美',
      gradient: [Color(0xFFFF8FB5), Color(0xFFFF5588)],
      prompt: '请帮我写一首关于春天的现代诗：',
    ),
    CreativeTemplate(
      id: 'copywriting',
      icon: Icons.campaign,
      title: '文案',
      description: '生成营销文案、广告语、朋友圈文案等',
      gradient: [Color(0xFFFFB3C9), Color(0xFFFF6B9D)],
      prompt: '请帮我写一段产品推广文案，产品是',
    ),
    CreativeTemplate(
      id: 'brainstorm',
      icon: Icons.lightbulb_outline,
      title: '头脑风暴',
      description: '围绕主题发散思维，提供创意灵感和方案',
      gradient: [Color(0xFFFF9DBB), Color(0xFFFF8FB5)],
      prompt: '请围绕以下主题进行头脑风暴：',
    ),
    CreativeTemplate(
      id: 'email',
      icon: Icons.email_outlined,
      title: '写邮件',
      description: '生成专业得体的商务邮件和日常邮件',
      gradient: [Color(0xFFFFC0D6), Color(0xFFFF8FB5)],
      prompt: '请帮我写一封商务邮件，内容是',
    ),
    CreativeTemplate(
      id: 'resume',
      icon: Icons.description_outlined,
      title: '简历优化',
      description: '优化简历内容，突出亮点提升竞争力',
      gradient: [Color(0xFFFF8FB5), Color(0xFFFF9DBB)],
      prompt: '请帮我优化以下简历内容：',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: MiuixDuration.slow);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTemplateTap(CreativeTemplate template) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => FadeTransition(
          opacity: anim,
          child: ChatPage(initialPrompt: template.prompt),
        ),
        transitionDuration: MiuixDuration.page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? MiuixColors.darkBackground : MiuixColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(isDark)),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final template = _templates[index];
                  final animation = Tween<double>(begin: 0, end: 1).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: Interval((index / _templates.length) * 0.6, (index / _templates.length) * 0.6 + 0.4, curve: MiuixCurves.easeOut),
                    ),
                  );
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
                      child: _buildTemplateCard(template, isDark),
                    ),
                  );
                },
                childCount: _templates.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(colors: MiuixColors.primaryGradient).createShader(bounds),
            child: const Text(
              '创意工坊',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '选择模板，一键开启AI创作',
            style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.md),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(CreativeTemplate template, bool isDark) {
    return MiuixRipple(
      borderRadius: MiuixRadius.lg,
      child: GestureDetector(
        onTap: () => _onTemplateTap(template),
        child: MiuixGlassContainer(
          borderRadius: MiuixRadius.lg,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: template.gradient),
                  borderRadius: MiuixRadius.mdRadius,
                  boxShadow: [
                    BoxShadow(color: template.gradient.last.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Icon(template.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 14),
              Text(
                template.title,
                style: TextStyle(color: isDark ? MiuixColors.darkTextPrimary : MiuixColors.textPrimary, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  template.description,
                  style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm, height: 1.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('立即使用', style: TextStyle(color: MiuixColors.primary, fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward, color: MiuixColors.primary, size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreativeTemplate {
  const CreativeTemplate({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.prompt,
  });

  final String id;
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;
  final String prompt;
}
