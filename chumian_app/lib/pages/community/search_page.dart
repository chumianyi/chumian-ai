import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_chip.dart';
import 'package:chumian_ai/widgets/miuix/miuix_input.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_tab_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_empty_state.dart';

/// ============================================================
/// SearchPage —— 搜索页
/// 搜索框，热搜标签，历史记录，搜索结果(Tab:帖子/用户/Agent)
/// 粉色主题
/// ============================================================
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late TabController _tabController;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<String> _history = ['初眠AI', 'Flutter教程', 'AI绘画', '粉色主题'];
  bool _hasSearched = false;
  bool _isSearching = false;

  static const List<String> _hotSearches = [
    '初眠AI新版本发布',
    'AI绘画技巧',
    'Flutter开发最佳实践',
    '社区创作活动',
    'SVIP会员权益',
    'Agent创建教程',
    '积分兑换攻略',
    '签到连续奖励',
  ];

  static const List<SearchResult> _postResults = [
    SearchResult(id: '1', title: '初眠AI使用体验分享', desc: '用了一段时间，整体体验非常棒...', author: '樱花飘落', likes: 128, type: 'post'),
    SearchResult(id: '2', title: 'AI绘画Prompt技巧大全', desc: '分享几个实用的prompt技巧...', author: '设计师小王', likes: 256, type: 'post'),
    SearchResult(id: '3', title: 'Flutter性能优化指南', desc: '从入门到精通的性能优化...', author: '代码大师', likes: 89, type: 'post'),
  ];

  static const List<SearchResult> _userResults = [
    SearchResult(id: '1', title: '初眠AI官方', desc: '官方账号，发布最新动态', author: '', likes: 0, type: 'user', avatar: '🤖'),
    SearchResult(id: '2', title: '樱花飘落', desc: '热爱生活的二次元少女', author: '', likes: 0, type: 'user', avatar: '🌸'),
    SearchResult(id: '3', title: '代码大师', desc: '分享编程技巧和经验', author: '', likes: 0, type: 'user', avatar: '💻'),
  ];

  static const List<SearchResult> _agentResults = [
    SearchResult(id: '1', title: '小眠助手', desc: '温柔贴心的生活助手', author: '官方', likes: 1280, type: 'agent', avatar: '🌸'),
    SearchResult(id: '2', title: '代码大师', desc: '精通多种编程语言', author: '开发者', likes: 856, type: 'agent', avatar: '💻'),
    SearchResult(id: '3', title: '文学少女', desc: '热爱文学创作', author: '创作者', likes: 432, type: 'agent', avatar: '📚'),
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _tabController = TabController(length: 3, vsync: this);
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _search(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _hasSearched = false;
    });
    if (!_history.contains(query)) {
      _history.insert(0, query);
      if (_history.length > 10) _history.removeLast();
    }
    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() {
        _isSearching = false;
        _hasSearched = true;
      });
    });
  }

  void _clearHistory() {
    setState(() => _history.clear());
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.06, (index * 0.06) + 0.35,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) => Opacity(opacity: anim.value, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        titleWidget: _buildSearchBar(),
        backgroundColor: MiuixColors.background,
        showBackButton: true,
      ),
      body: _hasSearched ? _buildResults() : _buildSearchHome(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: MiuixColors.surfaceVariant,
        borderRadius: MiuixRadius.pillRadius,
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        onSubmitted: _search,
        style: const TextStyle(fontSize: MiuixFontSize.md),
        decoration: InputDecoration(
          hintText: '搜索帖子、用户、Agent...',
          hintStyle: const TextStyle(
            color: MiuixColors.textTertiary,
            fontSize: MiuixFontSize.md,
          ),
          prefixIcon: const Icon(Icons.search, color: MiuixColors.primary, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _hasSearched = false;
                    });
                  },
                  child: const Icon(Icons.clear,
                      color: MiuixColors.textTertiary, size: 18),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildSearchHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_history.isNotEmpty) _buildAnimatedItem(_buildHistorySection(), 0),
          if (_history.isNotEmpty) const SizedBox(height: 20),
          _buildAnimatedItem(_buildHotSearchSection(), 1),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, color: MiuixColors.primary, size: 18),
            const SizedBox(width: 6),
            const Text(
              '搜索历史',
              style: TextStyle(
                fontSize: MiuixFontSize.md,
                fontWeight: FontWeight.w600,
                color: MiuixColors.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _clearHistory,
              child: const Text(
                '清空',
                style: TextStyle(
                  fontSize: MiuixFontSize.sm,
                  color: MiuixColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_history.length, (index) {
            return MiuixChip(
              label: _history[index],
              onTap: () {
                _searchController.text = _history[index];
                _search(_history[index]);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHotSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_fire_department,
                color: MiuixColors.error, size: 18),
            const SizedBox(width: 6),
            const Text(
              '热门搜索',
              style: TextStyle(
                fontSize: MiuixFontSize.md,
                fontWeight: FontWeight.w600,
                color: MiuixColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        MiuixCard(
          style: MiuixCardStyle.surface,
          padding: const EdgeInsets.all(0),
          child: Column(
            children: List.generate(_hotSearches.length, (index) {
              return Column(
                children: [
                  if (index > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 56),
                      child: Container(height: 1, color: MiuixColors.divider),
                    ),
                  MiuixRipple(
                    child: ListTile(
                      leading: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: index < 3
                              ? const LinearGradient(
                                  colors: MiuixColors.primaryGradient)
                              : null,
                          color: index < 3
                              ? null
                              : MiuixColors.surfaceVariant,
                          borderRadius: MiuixRadius.smRadius,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: index < 3
                                ? Colors.white
                                : MiuixColors.textTertiary,
                            fontWeight: FontWeight.bold,
                            fontSize: MiuixFontSize.sm,
                          ),
                        ),
                      ),
                      title: Text(
                        _hotSearches[index],
                        style: const TextStyle(
                          fontSize: MiuixFontSize.md,
                          color: MiuixColors.textPrimary,
                        ),
                      ),
                      trailing: index < 3
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: MiuixColors.error.withValues(alpha: 0.1),
                                borderRadius: MiuixRadius.pillRadius,
                              ),
                              child: Text(
                                index == 0 ? '热' : index == 1 ? '新' : '荐',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: MiuixColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : null,
                      onTap: () {
                        _searchController.text = _hotSearches[index];
                        _search(_hotSearches[index]);
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    return Column(
      children: [
        MiuixTabBar(
          items: const [
            MiuixTabItem(label: '帖子', icon: Icons.article),
            MiuixTabItem(label: '用户', icon: Icons.person),
            MiuixTabItem(label: 'Agent', icon: Icons.smart_toy),
          ],
          controller: _tabController,
        ),
        Expanded(
          child: _isSearching
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(MiuixColors.primary),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildResultList(_postResults),
                    _buildResultList(_userResults),
                    _buildResultList(_agentResults),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildResultList(List<SearchResult> results) {
    if (results.isEmpty) {
      return const MiuixEmptyState(
        title: '没有找到相关结果',
        description: '换个关键词试试吧',
        icon: Icons.search_off,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return _buildResultItem(results[index]);
      },
    );
  }

  Widget _buildResultItem(SearchResult result) {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () {
        MiuixToast.show(context,
            message: '查看 ${result.title}', type: MiuixToastType.info);
      },
      child: Row(
        children: [
          if (result.type != 'post')
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB6C1), Color(0xFFFF69B4)],
                ),
                borderRadius: MiuixRadius.lgRadius,
              ),
              child: Center(
                child: Text(result.avatar ?? '📄',
                    style: const TextStyle(fontSize: 24)),
              ),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: MiuixColors.primaryLight.withValues(alpha: 0.2),
                borderRadius: MiuixRadius.lgRadius,
              ),
              child: const Icon(Icons.article,
                  color: MiuixColors.primary, size: 24),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.title,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.md,
                    fontWeight: FontWeight.w600,
                    color: MiuixColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.sm,
                    color: MiuixColors.textSecondary,
                  ),
                ),
                if (result.type == 'post') ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        result.author,
                        style: const TextStyle(
                          fontSize: MiuixFontSize.xs,
                          color: MiuixColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.favorite,
                          size: 12, color: MiuixColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        '${result.likes}',
                        style: const TextStyle(
                          fontSize: MiuixFontSize.xs,
                          color: MiuixColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SearchResult {
  final String id;
  final String title;
  final String desc;
  final String author;
  final int likes;
  final String type;
  final String? avatar;
  const SearchResult({
    required this.id,
    required this.title,
    required this.desc,
    required this.author,
    required this.likes,
    required this.type,
    this.avatar,
  });
}
