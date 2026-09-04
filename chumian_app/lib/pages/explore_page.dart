import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pink50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('发现', style: AppTextStyles.headingMedium.copyWith(color: AppColors.pink600)),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: AppColors.pink400), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle(title: '热门智能体'),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _AgentCard(index: i),
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: '社区精选'),
          const SizedBox(height: 12),
          ...List.generate(4, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CommunityCard(index: i),
          )),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.headingSmall.copyWith(color: AppColors.pink600));
  }
}

class _AgentCard extends StatelessWidget {
  final int index;
  const _AgentCard({required this.index});

  static const _names = ['写作助手', '代码专家', '翻译官', '情感陪伴', '学习导师', '创意总监'];
  static const _descs = ['专业文章创作', '多语言编程', '精准翻译', '温暖陪伴', '高效学习', '灵感无限'];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.pink100.withOpacity(0.5), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.pink300, AppColors.pink400]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.smart_toy, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 10),
          Text(_names[index], style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(_descs[index], style: AppTextStyles.caption.copyWith(color: AppColors.pink400), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  final int index;
  const _CommunityCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.pink100.withOpacity(0.4), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 18, backgroundColor: AppColors.pink200, child: Icon(Icons.person, color: AppColors.pink500, size: 18)),
              const SizedBox(width: 10),
              Text('用户${index + 1}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('2小时前', style: AppTextStyles.caption.copyWith(color: AppColors.pink300)),
            ],
          ),
          const SizedBox(height: 10),
          Text('这是一个社区精选内容展示，用户分享了使用初眠AI的精彩体验和创作成果。', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.favorite_border, size: 18, color: AppColors.pink400),
              const SizedBox(width: 4),
              Text('${128 + index * 37}', style: AppTextStyles.caption.copyWith(color: AppColors.pink400)),
              const SizedBox(width: 16),
              Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.pink400),
              const SizedBox(width: 4),
              Text('${23 + index * 8}', style: AppTextStyles.caption.copyWith(color: AppColors.pink400)),
            ],
          ),
        ],
      ),
    );
  }
}
