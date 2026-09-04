import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CreativePage extends StatelessWidget {
  const CreativePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pink50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('AI创作', style: AppTextStyles.headingMedium.copyWith(color: AppColors.pink600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CreativeCard(
            title: '图片生成',
            subtitle: 'AI绘画，文字转图片',
            icon: Icons.image,
            gradient: [AppColors.pink300, AppColors.pink400],
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _CreativeCard(
            title: '视频生成',
            subtitle: 'AI视频创作，文字转视频',
            icon: Icons.videocam,
            gradient: [AppColors.pink400, AppColors.pink500],
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _CreativeCard(
            title: '文章写作',
            subtitle: 'AI辅助写作，一键生成',
            icon: Icons.edit_note,
            gradient: [AppColors.pink200, AppColors.pink300],
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _CreativeCard(
            title: '代码生成',
            subtitle: 'AI编程助手，多语言支持',
            icon: Icons.code,
            gradient: [AppColors.pink500, AppColors.pink600],
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _CreativeCard(
            title: '音乐创作',
            subtitle: 'AI音乐生成，自定义风格',
            icon: Icons.music_note,
            gradient: [AppColors.pink300, AppColors.pink500],
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _CreativeCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _CreativeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_CreativeCard> createState() => _CreativeCardState();
}

class _CreativeCardState extends State<_CreativeCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: widget.gradient),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: widget.gradient.first.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: AppTextStyles.headingSmall.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(widget.subtitle, style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withOpacity(0.85))),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
