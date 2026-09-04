import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../animations/scale_animations.dart';
import '../animations/animation_constants.dart';
import '../widgets/pink_button.dart';
import '../widgets/pink_card.dart';
import '../widgets/pink_container.dart';
import '../widgets/pink_app_bar.dart';
import '../widgets/pink_text_field.dart';
import '../widgets/pink_list_tile.dart';
import '../widgets/pink_progress.dart';
import '../widgets/pink_icon_button.dart';
import '../widgets/pink_avatar.dart';
import '../widgets/pink_image.dart';
import '../widgets/pink_badge.dart';
import '../widgets/pink_chip.dart';
import '../widgets/pink_tag.dart';
import '../widgets/pink_switch.dart';
import '../widgets/pink_checkbox.dart';
import '../widgets/pink_slider.dart';
import '../widgets/pink_dropdown.dart';
import '../widgets/pink_expansion_tile.dart';
import '../widgets/pink_refresh_indicator.dart';
import '../services/api_service.dart';

/// Customized content page
class CustomizedPage extends StatefulWidget {
  final String? id;
  final String? title;
  final Map<String, dynamic>? arguments;
  final VoidCallback? onBack;
  final ValueChanged<Map<String, dynamic>>? onResult;

  const CustomizedPage({
    super.key,
    this.id,
    this.title,
    this.arguments,
    this.onBack,
    this.onResult,
  });

  @override
  State<CustomizedPage> createState() => _CustomizedPageState();
}

class _CustomizedPageState extends State<CustomizedPage> with TickerProviderStateMixin {
  late AnimationController _pageController;
  late AnimationController _listController;
  late AnimationController _fabController;
  late Animation<double> _pageScale;
  late Animation<double> _pageFade;
  late Animation<Offset> _pageSlide;
  late Animation<double> _fabScale;
  late Animation<double> _fabRotation;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _showSearch = false;
  bool _isFabVisible = true;
  int _selectedIndex = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  int _itemCount = 0;

  final List<Map<String, dynamic>> _items = [];
  final List<Map<String, dynamic>> _filteredItems = [];
  final Set<String> _selectedIds = {};
  final Map<String, dynamic> _formData = {};

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _listController.dispose();
    _fabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _pageController = AnimationController(
      vsync: this,
      duration: AnimationConstants.navDuration,
    );
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pageScale = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(parent: _pageController, curve: AnimationConstants.navScaleIn),
    );
    _pageFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeOut),
    );
    _pageSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeOutCubic),
    );
    _fabScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );
    _fabRotation = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeOut),
    );

    _pageController.forward();
    _fabController.forward();
  }

  void _onScroll() {
    if (_scrollController.position.pixels > 200) {
      if (_isFabVisible) setState(() => _isFabVisible = false);
    } else {
      if (!_isFabVisible) setState(() => _isFabVisible = true);
    }
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems.clear();
        _filteredItems.addAll(_items);
      } else {
        _filteredItems.clear();
        _filteredItems.addAll(_items.where((item) =>
          (item['title'] ?? '').toString().toLowerCase().contains(query) ||
          (item['subtitle'] ?? '').toString().toLowerCase().contains(query)
        ));
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _items.clear();
      for (int i = 0; i < 20; i++) {
        _items.add({
          'id': 'item_${widget.id ?? 'page'}_$i',
          'title': 'CustomizedPage Item $i',
          'subtitle': 'Description for item $i',
          'icon': Icons.star,
          'color': AppColors.primary,
          'index': i,
          'createdAt': DateTime.now().subtract(Duration(minutes: i * 15)).toIso8601String(),
          'likes': random.nextInt(1000),
          'comments': random.nextInt(100),
          'views': random.nextInt(10000),
          'isFavorite': random.nextBool(),
          'isLiked': random.nextBool(),
          'tags': List.generate(3, (j) => 'tag_$j'),
        });
      }
      _filteredItems.clear();
      _filteredItems.addAll(_items);
      _itemCount = _items.length;
      _totalPages = 5;
      _listController.forward();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _currentPage >= _totalPages) return;
    setState(() => _isLoading = true);
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      _currentPage++;
      for (int i = 0; i < 10; i++) {
        final idx = _items.length;
        _items.add({
          'id': 'item_${widget.id ?? 'page'}_$idx',
          'title': 'CustomizedPage Item $idx',
          'subtitle': 'Description for item $idx',
          'icon': Icons.star,
          'color': AppColors.primary,
          'index': idx,
          'createdAt': DateTime.now().subtract(Duration(minutes: idx * 15)).toIso8601String(),
          'likes': random.nextInt(1000),
          'comments': random.nextInt(100),
          'views': random.nextInt(10000),
          'isFavorite': random.nextBool(),
          'isLiked': random.nextBool(),
          'tags': List.generate(3, (j) => 'tag_$j'),
        });
      }
      _filteredItems.clear();
      _filteredItems.addAll(_items);
      _itemCount = _items.length;
    } catch (e) {
      // ignore
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    _currentPage = 1;
    await _loadData();
    setState(() => _isRefreshing = false);
  }

  void _onItemTap(Map<String, dynamic> item) {
    setState(() {
      _selectedIndex = item['index'] as int;
    });
    widget.onResult?.call(item);
  }

  void _onItemLongPress(Map<String, dynamic> item) {
    final id = item['id'] as String;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleFavorite(Map<String, dynamic> item) {
    setState(() {
      item['isFavorite'] = !item['isFavorite'];
    });
  }

  void _toggleLike(Map<String, dynamic> item) {
    setState(() {
      item['isLiked'] = !item['isLiked'];
      item['likes'] = (item['likes'] as int) + (item['isLiked'] ? 1 : -1);
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (_showSearch) {
        _searchFocus.requestFocus();
      } else {
        _searchController.clear();
        _searchFocus.unfocus();
      }
    });
  }

  void _onBack() {
    widget.onBack?.call();
    Navigator.of(context).maybePop();
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => Container(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('CustomizedPage Actions', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            ...['Share', 'Save', 'Download', 'Report', 'Block'].map((action) =>
              PinkListTile(
                text: action,
                icon: Icons.adaptive.share,
                onTap: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirm(Map<String, dynamic> item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete Item', style: AppTextStyles.titleMedium),
        content: Text('Are you sure you want to delete "${item['title']}"?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          PinkButton(text: 'Delete', onTap: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (result == true) {
      setState(() {
        _items.removeWhere((e) => e['id'] == item['id']);
        _filteredItems.removeWhere((e) => e['id'] == item['id']);
        _itemCount = _items.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: AnimatedBuilder(
        animation: _pageController,
        builder: (context, child) {
          return Transform.scale(
            scale: _pageScale.value,
            child: Opacity(
              opacity: _pageFade.value,
              child: SlideTransition(position: _pageSlide, child: child),
            ),
          );
        },
        child: _buildBody(),
      ),
      floatingActionButton: _isFabVisible ? AnimatedBuilder(
        animation: _fabController,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabScale.value,
            child: Transform.rotate(angle: _fabRotation.value * 3.14159, child: child),
          );
        },
        child: FloatingActionButton(
          onPressed: _showBottomSheet,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ) : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: _onBack,
      ),
      title: _showSearch
          ? PinkTextField(
              controller: _searchController,
              focusNode: _searchFocus,
              hintText: 'Search...',
              autofocus: true,
            )
          : Text(widget.title ?? 'CustomizedPage', style: AppTextStyles.titleLarge),
      actions: [
        IconButton(
          icon: Icon(_showSearch ? Icons.close : Icons.search, color: AppColors.textPrimary),
          onPressed: _toggleSearch,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
          onPressed: _showBottomSheet,
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading && _items.isEmpty) {
      return const Center(child: PinkProgress());
    }
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(_errorMessage ?? 'An error occurred', style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            PinkButton(text: 'Retry', onTap: _loadData),
          ],
        ),
      );
    }
    return PinkRefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildFilters()),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildListItem(index),
              childCount: _filteredItems.length + (_isLoading ? 1 : 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title ?? 'CustomizedPage', style: AppTextStyles.headlineLarge),
          const SizedBox(height: AppSpacing.xs),
          Text('$_itemCount items found', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: 6,
        itemBuilder: (context, index) {
          final labels = ['All', 'Popular', 'New', 'Trending', 'Featured', 'Top'];
          final isSelected = _selectedIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: PinkChip(
              text: labels[index],
              selected: isSelected,
              onTap: () => setState(() => _selectedIndex = index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListItem(int index) {
    if (index >= _filteredItems.length) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: PinkProgress()),
      );
    }
    final item = _filteredItems[index];
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _listController,
        curve: Interval((index / 20).clamp(0.0, 1.0) * 0.5, 1.0, curve: Curves.easeOut),
      ),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(animation),
        child: PinkCard(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
          onTap: () => _onItemTap(item),
          onLongPress: () => _onItemLongPress(item),
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Row(
              children: [
                PinkAvatar(icon: item['icon'] as IconData, color: item['color'] as Color),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title'] as String, style: AppTextStyles.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: AppSpacing.xs),
                      Text(item['subtitle'] as String, style: AppTextStyles.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(Icons.favorite, size: 14, color: item['isLiked'] ? AppColors.error : AppColors.textHint),
                          const SizedBox(width: 4),
                          Text('${item['likes']}', style: AppTextStyles.caption),
                          const SizedBox(width: AppSpacing.md),
                          const Icon(Icons.comment, size: 14, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text('${item['comments']}', style: AppTextStyles.caption),
                          const SizedBox(width: AppSpacing.md),
                          const Icon(Icons.visibility, size: 14, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text('${item['views']}', style: AppTextStyles.caption),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    PinkIconButton(icon: item['isFavorite'] ? Icons.favorite : Icons.favorite_border, onTap: () => _toggleFavorite(item)),
                    PinkIconButton(icon: Icons.more_horiz, onTap: () => _showDeleteConfirm(item)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
