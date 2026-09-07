import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_chip.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/utils/clipboard_utils.dart';

/// ============================================================
/// JokesPage —— 笑话大全
/// 笑话列表，分类(冷笑话/段子/幽默)，上一个/下一个
/// 收藏，分享，粉色卡片，错落入场
/// ============================================================
class JokesPage extends StatefulWidget {
  const JokesPage({super.key});

  @override
  State<JokesPage> createState() => _JokesPageState();
}

class _JokesPageState extends State<JokesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  int _category = 0; // 0=全部, 1=冷笑话, 2=段子, 3=幽默
  int _currentIndex = 0;
  final Set<int> _favorites = {};
  bool _showFavorites = false;
  final Random _random = Random();

  static const List<String> _categories = ['全部', '冷笑话', '段子', '幽默'];

  static const List<Joke> _allJokes = [
    Joke(category: 1, content: '为什么程序员总是分不清万圣节和圣诞节？因为 Oct 31 == Dec 25。'),
    Joke(category: 1, content: '一只蜗牛爬上了苹果树，树上的毛毛虫问：你是谁？蜗牛说：我是蜗牛。毛毛虫说：那你背上的壳是什么？蜗牛说：那是我的家。毛毛虫说：那你家怎么在背上？蜗牛说：因为我买不起房。'),
    Joke(category: 1, content: '为什么数学书总是很忧郁？因为它有太多的问题。'),
    Joke(category: 1, content: '冰箱里有两根香肠，一根说：好冷啊。另一根说：哇，你会说话！'),
    Joke(category: 1, content: '为什么企鹅的肚子是白的？因为它手短，洗澡只能洗到肚子。'),
    Joke(category: 2, content: '今天去买西瓜，老板说不甜不要钱。我说：那给我来个不甜的。老板：……'),
    Joke(category: 2, content: '老婆问我：你说我和你妈同时掉水里你先救谁？我说：你忘了我妈是游泳教练吗？老婆：那我呢？我说：你不是会潜水吗？'),
    Joke(category: 2, content: '面试的时候，面试官问我：你最大的缺点是什么？我说：太诚实。面试官说：我不觉得诚实是缺点。我说：我不在乎你怎么想。'),
    Joke(category: 2, content: '今天我问朋友：你知道为什么海是蓝色的吗？他说：因为鱼在里面吐泡泡，blue blue blue。'),
    Joke(category: 2, content: '医生对病人说：你这个病，需要好好休息。病人说：医生，我睡不着啊。医生说：那你数羊吧。病人说：我数过了，数到1200只的时候，天就亮了。'),
    Joke(category: 3, content: '人生就像打电话，不是你先挂就是我先挂。'),
    Joke(category: 3, content: '我不是在减肥，我只是在给身体一个重新认识自己的机会。'),
    Joke(category: 3, content: '世上无难事，只要肯放弃。'),
    Joke(category: 3, content: '我的钱包就像洋葱，每次打开都让我想哭。'),
    Joke(category: 3, content: '不要说我懒，我只是在积攒能量，准备一次性爆发——然后继续躺着。'),
    Joke(category: 1, content: '为什么海绵宝宝总是很开心？因为他住在菠萝里，没有房贷压力。'),
    Joke(category: 2, content: '今天在电梯里放了个屁，为了掩饰，我转头对旁边的人说：你闻到了吗？是咖啡的香味。他说：你这咖啡是从哪儿买的？这么冲。'),
    Joke(category: 3, content: '我以为我很颓废，今天我才知道，原来我早就报废了。'),
  ];

  List<Joke> get _filteredJokes {
    var list = _category == 0
        ? _allJokes
        : _allJokes.where((j) => j.category == _category).toList();
    if (_showFavorites) {
      list = list.asMap().entries.where((e) => _favorites.contains(_allJokes.indexOf(e.value))).map((e) => e.value).toList();
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _nextJoke() {
    final list = _filteredJokes;
    if (list.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % list.length;
    });
  }

  void _prevJoke() {
    final list = _filteredJokes;
    if (list.isEmpty) return;
    setState(() {
      _currentIndex = (_currentIndex - 1 + list.length) % list.length;
    });
  }

  void _randomJoke() {
    final list = _filteredJokes;
    if (list.isEmpty) return;
    setState(() {
      _currentIndex = _random.nextInt(list.length);
    });
  }

  void _toggleFavorite() {
    final list = _filteredJokes;
    if (list.isEmpty) return;
    final realIndex = _allJokes.indexOf(list[_currentIndex]);
    setState(() {
      if (_favorites.contains(realIndex)) {
        _favorites.remove(realIndex);
        MiuixToast.show(context, '已取消收藏', icon: Icons.favorite_border);
      } else {
        _favorites.add(realIndex);
        MiuixToast.show(context, '已收藏', icon: Icons.favorite);
      }
    });
  }

  Future<void> _shareJoke() async {
    final list = _filteredJokes;
    if (list.isEmpty) return;
    await ClipboardUtils.copy(list[_currentIndex].content);
    MiuixToast.show(context, '已复制到剪贴板', icon: Icons.copy);
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.06, (index * 0.06) + 0.4,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.06, (index * 0.06) + 0.4,
            curve: Curves.easeOutCubic),
      ),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) => Opacity(
        opacity: anim.value,
        child: Transform.translate(offset: slide.value, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredJokes;
    final currentJoke = list.isNotEmpty ? list[_currentIndex % list.length] : null;
    final realIndex = currentJoke != null ? _allJokes.indexOf(currentJoke) : -1;
    final isFavorite = _favorites.contains(realIndex);

    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '笑话大全',
        actions: [
          MiuixIconButton(
            icon: _showFavorites ? Icons.favorite : Icons.favorite_border,
            onPressed: () {
              setState(() {
                _showFavorites = !_showFavorites;
                _currentIndex = 0;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: Column(
          children: [
            _buildAnimatedItem(_buildCategoryChips(), 0),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(
              currentJoke != null
                  ? _buildJokeCard(currentJoke, isFavorite)
                  : _buildEmptyState(),
              1,
            ),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildNavigationButtons(), 2),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildActionButtons(), 3),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: MiuixSpacing.sm,
      runSpacing: MiuixSpacing.sm,
      children: List.generate(_categories.length, (i) {
        return MiuixChip(
          label: _categories[i],
          selected: _category == i,
          onTap: () {
            setState(() {
              _category = i;
              _currentIndex = 0;
            });
          },
        );
      }),
    );
  }

  Widget _buildJokeCard(Joke joke, bool isFavorite) {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(
        colors: [Color(0xFFFFF5F8), Color(0xFFFFEEF3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.all(MiuixSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: MiuixSpacing.md, vertical: MiuixSpacing.xs),
                decoration: BoxDecoration(
                  color: MiuixColors.primary.withValues(alpha: 0.15),
                  borderRadius: MiuixRadius.pillRadius,
                ),
                child: Text(_categories[joke.category],
                    style: const TextStyle(
                        color: MiuixColors.primary,
                        fontSize: MiuixFontSize.xs,
                        fontWeight: FontWeight.w500)),
              ),
              const Spacer(),
              Text('${_currentIndex + 1}/${_filteredJokes.length}',
                  style: const TextStyle(
                      color: MiuixColors.textTertiary, fontSize: MiuixFontSize.sm)),
            ],
          ),
          const SizedBox(height: MiuixSpacing.xl),
          const Icon(Icons.format_quote,
              color: MiuixColors.primary, size: 32),
          const SizedBox(height: MiuixSpacing.md),
          AnimatedSwitcher(
            duration: MiuixDuration.normal,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0, 0.1), end: Offset.zero)
                    .animate(anim),
                child: child,
              ),
            ),
            child: Text(
              joke.content,
              key: ValueKey(joke.content),
              style: const TextStyle(
                  fontSize: MiuixFontSize.xl,
                  color: MiuixColors.textPrimary,
                  height: 1.8,
                  fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: MiuixSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.format_quote,
                  color: MiuixColors.primary.withValues(alpha: 0.5), size: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return MiuixCard(
      child: const Padding(
        padding: EdgeInsets.all(MiuixSpacing.xxxl),
        child: Column(
          children: [
            Icon(Icons.sentiment_dissatisfied,
                color: MiuixColors.textTertiary, size: 48),
            SizedBox(height: MiuixSpacing.md),
            Text('暂无笑话',
                style: TextStyle(color: MiuixColors.textTertiary)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MiuixIconButton(
          icon: Icons.arrow_back_ios,
          onPressed: _prevJoke,
        ),
        const SizedBox(width: MiuixSpacing.xl),
        MiuixIconButton(
          icon: Icons.shuffle,
          onPressed: _randomJoke,
        ),
        const SizedBox(width: MiuixSpacing.xl),
        MiuixIconButton(
          icon: Icons.arrow_forward_ios,
          onPressed: _nextJoke,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: MiuixButton(
            label: _favorites.contains(_allJokes.indexOf(_filteredJokes.isNotEmpty ? _filteredJokes[_currentIndex % _filteredJokes.length] : Joke(category: 0, content: ''))) ? '已收藏' : '收藏',
            icon: Icons.favorite,
            type: MiuixButtonType.secondary,
            onPressed: _toggleFavorite,
          ),
        ),
        const SizedBox(width: MiuixSpacing.md),
        Expanded(
          child: MiuixButton(
            label: '分享',
            icon: Icons.share,
            onPressed: _shareJoke,
          ),
        ),
      ],
    );
  }
}

class Joke {
  final int category;
  final String content;

  const Joke({required this.category, required this.content});
}
