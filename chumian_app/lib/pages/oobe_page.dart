import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

class OobePage extends StatefulWidget {
  final VoidCallback onComplete;
  const OobePage({super.key, required this.onComplete});

  @override
  State<OobePage> createState() => _OobePageState();
}

class _OobePageState extends State<OobePage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OobeItem> _pages = [
    _OobeItem(icon: Icons.chat_bubble_outline, title: '智能对话', desc: '与初眠进行自然流畅的多轮对话，支持流式输出和Markdown渲染'),
    _OobeItem(icon: Icons.auto_awesome, title: '创意无限', desc: '丰富的模板和智能体，一键生成图片、视频，激发你的创造力'),
    _OobeItem(icon: Icons.explore, title: '社区探索', desc: '发现有趣的帖子，与其他用户互动交流，分享你的创意作品'),
    _OobeItem(icon: Icons.psychology, title: '深度思考', desc: '初眠会认真思考每一个问题，思考过程可随时查看，答案更可靠'),
  ];

  Future<void> _finish() async {
    try {
      await ApiService.completeOobe();
    } catch (_) {}
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.15), borderRadius: BorderRadius.circular(36)),
                          child: Icon(page.icon, size: 56, color: AppTheme.primaryColor),
                        ),
                        const SizedBox(height: 32),
                        Text(page.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Text(page.desc, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary, height: 1.6)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(color: _currentPage == i ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        } else {
                          _finish();
                        }
                      },
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: Text(_currentPage < _pages.length - 1 ? '下一步' : '开始使用', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  if (_currentPage < _pages.length - 1)
                    TextButton(onPressed: _finish, child: const Text('跳过')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OobeItem {
  final IconData icon;
  final String title;
  final String desc;
  _OobeItem({required this.icon, required this.title, required this.desc});
}
