import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/context_ext.dart';
import '../widgets/buttons.dart';

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
    _OobeItem(
      icon: Icons.chat_bubble_outline_rounded,
      title: '智能对话',
      desc: '与初眠进行自然流畅的多轮对话，支持流式输出和Markdown渲染',
      gradient: const [Color(0xFF4D8DFF), Color(0xFF7CB4FF)],
    ),
    _OobeItem(
      icon: Icons.auto_awesome_rounded,
      title: '创意无限',
      desc: '丰富的模板和智能体，一键生成图片、视频，激发你的创造力',
      gradient: const [Color(0xFF9C6ADE), Color(0xFFC49BE8)],
    ),
    _OobeItem(
      icon: Icons.explore_rounded,
      title: '社区探索',
      desc: '发现有趣的帖子，与其他用户互动交流，分享你的创意作品',
      gradient: const [Color(0xFFF5A623), Color(0xFFF7C948)],
    ),
    _OobeItem(
      icon: Icons.psychology_rounded,
      title: '深度思考',
      desc: '初眠会认真思考每一个问题，思考过程可随时查看，答案更可靠',
      gradient: const [Color(0xFF2BB673), Color(0xFF66D19B)],
    ),
  ];

  Future<void> _finish() async {
    try {
      await ApiService.completeOobe();
    } catch (_) {}
    if (!mounted) return;
    widget.onComplete();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppTheme.darkBackground : AppTheme.backgroundColor;
    return Scaffold(
      backgroundColor: background,
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
                  final gradient = LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: page.gradient,
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: page.gradient
                                  .map((c) => c.withValues(alpha: 0.15))
                                  .toList(),
                            ),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: ShaderMask(
                            shaderCallback: (rect) => gradient.createShader(rect),
                            blendMode: BlendMode.srcIn,
                            child: Icon(page.icon, size: 60),
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          page.title,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.desc,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? _pages[i].gradient[0]
                              : _pages[i].gradient[0].withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    label: _currentPage < _pages.length - 1 ? '下一步' : '开始使用',
                    icon: _currentPage < _pages.length - 1
                        ? Icons.arrow_forward_rounded
                        : Icons.rocket_launch_rounded,
                    height: 54,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _pages[_currentPage].gradient,
                    ),
                    onPressed: _next,
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
  final List<Color> gradient;
  _OobeItem({
    required this.icon,
    required this.title,
    required this.desc,
    required this.gradient,
  });
}
