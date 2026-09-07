import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/providers/user_provider.dart';

/// ============================================================
/// OobePage —— 新手引导页
/// 4 页引导，粉色渐变 + mascot + 滑动/点击进入
/// ============================================================
class OobePage extends StatefulWidget {
  const OobePage({super.key});

  @override
  State<OobePage> createState() => _OobePageState();
}

class _OobePageState extends State<OobePage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _controller;
  late Animation<double> _bounceAnim;

  static const List<_OobeItem> _items = [
    _OobeItem(
      icon: Icons.smart_toy,
      title: '你好，我是初眠',
      description: '你的专属AI智能助手，随时为你解答疑问、陪伴聊天、创作内容。',
      gradient: [Color(0xFFFF8FB5), Color(0xFFFF6B9D)],
    ),
    _OobeItem(
      icon: Icons.auto_awesome,
      title: '创意无限',
      description: '写文章、翻译、总结、代码、写诗、文案……一键生成，激发你的灵感。',
      gradient: [Color(0xFFFFB3C9), Color(0xFFFF8FB5)],
    ),
    _OobeItem(
      icon: Icons.public,
      title: '联网搜索',
      description: '支持实时联网搜索，获取最新资讯，回答更加准确全面。',
      gradient: [Color(0xFFFFC0D6), Color(0xFFFF9DBB)],
    ),
    _OobeItem(
      icon: Icons.favorite,
      title: '开始体验',
      description: '加入初眠AI社区，探索更多精彩功能，开启你的智能之旅！',
      gradient: [Color(0xFFFF6B9D), Color(0xFFFF4081)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _bounceAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: MiuixDuration.page,
        curve: MiuixCurves.easeInOut,
      );
    } else {
      _completeOobe();
    }
  }

  Future<void> _completeOobe() async {
    try {
      await context.read<UserProvider>().completeOobe();
    } catch (_) {}
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF0F5), Color(0xFFFFF5F8), Color(0xFFFFEEF3)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSkipButton(),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    return _buildPageItem(_items[index], index);
                  },
                ),
              ),
              _buildIndicator(),
              const SizedBox(height: 24),
              _buildNextButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 8),
        child: TextButton(
          onPressed: _completeOobe,
          child: Text(
            '跳过',
            style: TextStyle(
              color: MiuixColors.textSecondary,
              fontSize: MiuixFontSize.md,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageItem(_OobeItem item, int index) {
    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.85 + 0.15 * _bounceAnim.value,
          child: Opacity(
            opacity: _bounceAnim.value,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIconCircle(item),
                  const SizedBox(height: 40),
                  Text(
                    item.title,
                    style: TextStyle(
                      color: MiuixColors.textPrimary,
                      fontSize: MiuixFontSize.xxxl,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.description,
                    style: TextStyle(
                      color: MiuixColors.textSecondary,
                      fontSize: MiuixFontSize.lg,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconCircle(_OobeItem item) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: item.gradient),
        boxShadow: [
          BoxShadow(
            color: item.gradient.last.withOpacity(0.4),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(item.icon, color: Colors.white, size: 56),
          Positioned(
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: item.gradient.first.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_items.length, (index) {
        final isActive = _currentPage == index;
        return AnimatedContainer(
          duration: MiuixDuration.fast,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? MiuixColors.primary : MiuixColors.border,
            borderRadius: MiuixRadius.pillRadius,
          ),
        );
      }),
    );
  }

  Widget _buildNextButton() {
    final isLast = _currentPage == _items.length - 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton(
          onPressed: _nextPage,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(27),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLast ? '开始体验' : '下一步',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!isLast) ...[
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OobeItem {
  const _OobeItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;
}
