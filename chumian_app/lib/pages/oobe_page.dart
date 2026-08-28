import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../theme.dart';

class OobePage extends StatefulWidget {
  const OobePage({super.key});

  @override
  State<OobePage> createState() => _OobePageState();
}

class _OobePageState extends State<OobePage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OobeItem> _items = [
    _OobeItem(
      icon: Icons.chat_bubble_outline,
      title: '智能对话',
      description: '支持多种免费AI模型，流式输出，思考过程可查看。Markdown格式完美渲染，代码高亮一应俱全。',
      color: AppTheme.primaryColor,
    ),
    _OobeItem(
      icon: Icons.image_outlined,
      title: '多模态创作',
      description: '文字对话、图片生成、视频生成，一个App全部搞定。每日9000万积分，尽情使用。',
      color: const Color(0xFFB8E8D0),
    ),
    _OobeItem(
      icon: Icons.explore_outlined,
      title: '社区探索',
      description: '发现有趣的内容，点赞评论互动。创意模板一键使用，智能体市场等你探索。',
      color: const Color(0xFFE8D4B8),
    ),
  ];

  void _next() {
    if (_currentPage < _items.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.read<UserProvider>().completeOobe();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.read<UserProvider>().completeOobe(),
                child: const Text('跳过'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(
                            item.icon,
                            size: 70,
                            color: item.color,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_items.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppTheme.primaryColor
                        : AppTheme.primaryColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Text(_currentPage == _items.length - 1 ? '开始使用' : '下一步'),
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
  final String description;
  final Color color;

  _OobeItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
