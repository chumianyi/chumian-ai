import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_glass.dart';
import 'package:chumian_ai/services/web_search_service.dart';

/// ============================================================
/// WebSearchResultsPage —— 联网搜索结果页
/// 搜索框 + 结果列表(标题+摘要+链接+来源) + url_launcher打开 + 粉色卡片
/// ============================================================
class WebSearchResultsPage extends StatefulWidget {
  const WebSearchResultsPage({super.key, this.query = ''});

  final String query;

  @override
  State<WebSearchResultsPage> createState() => _WebSearchResultsPageState();
}

class _WebSearchResultsPageState extends State<WebSearchResultsPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<SearchResultItem> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    if (widget.query.isNotEmpty) {
      _searchController.text = widget.query;
      _doSearch();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _doSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _results.clear();
    });

    try {
      final service = WebSearchService();
      final results = await service.search(query);
      if (mounted) {
        setState(() {
          _results.addAll(results.map((r) => SearchResultItem(
                title: r.title,
                url: r.url,
                snippet: r.summary,
                source: r.displaySource,
              )));
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('无法打开链接'), backgroundColor: MiuixColors.error, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: AppBar(backgroundColor: MiuixColors.surface, elevation: 0, scrolledUnderElevation: 0, centerTitle: true, leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: MiuixColors.primary), onPressed: () => Navigator.pop(context)), title: const Text('联网搜索', style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.xl, fontWeight: FontWeight.w600))),
      body: Column(children: [
        _buildSearchBar(),
        Expanded(child: _buildResults()),
      ]),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: MiuixColors.surface,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: MiuixColors.surfaceVariant,
                borderRadius: MiuixRadius.pillRadius,
                border: Border.all(color: MiuixColors.border, width: 1),
              ),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _doSearch(),
                style: const TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.md),
                decoration: InputDecoration(
                  hintText: '输入搜索关键词',
                  hintStyle: const TextStyle(color: MiuixColors.textTertiary),
                  prefixIcon: const Icon(Icons.search, color: MiuixColors.primary, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: MiuixColors.textTertiary, size: 18),
                          onPressed: () => setState(() => _searchController.clear()),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          MiuixRipple(
            borderRadius: MiuixRadius.pill,
            child: GestureDetector(
              onTap: _doSearch,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
                  borderRadius: MiuixRadius.pillRadius,
                ),
                child: const Text('搜索', style: TextStyle(color: Colors.white, fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isSearching) {
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 5,
        itemBuilder: (_, i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: MiuixColors.surfaceVariant,
            borderRadius: MiuixRadius.lgRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 150, height: 16, decoration: BoxDecoration(color: MiuixColors.border, borderRadius: MiuixRadius.xsRadius)),
              const SizedBox(height: 8),
              Container(width: double.infinity, height: 12, decoration: BoxDecoration(color: MiuixColors.border, borderRadius: MiuixRadius.xsRadius)),
              const SizedBox(height: 4),
              Container(width: 250, height: 12, decoration: BoxDecoration(color: MiuixColors.border, borderRadius: MiuixRadius.xsRadius)),
            ],
          ),
        ),
      );
    }
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.public, color: MiuixColors.textTertiary, size: 64),
            const SizedBox(height: 16),
            const Text('输入关键词开始搜索', style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.md)),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, color: MiuixColors.textTertiary, size: 64),
            const SizedBox(height: 16),
            const Text('未找到相关结果', style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.md)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: MiuixDuration.normal,
          curve: Interval((index % 5) * 0.1, (index % 5) * 0.1 + 0.9, curve: MiuixCurves.easeOut),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(offset: Offset(0, (1 - value) * 20), child: child),
          ),
          child: _buildResultCard(result),
        );
      },
    );
  }

  Widget _buildResultCard(SearchResultItem result) {
    return MiuixRipple(
      borderRadius: MiuixRadius.lg,
      child: GestureDetector(
        onTap: () => _openUrl(result.url),
        child: MiuixGlassContainer(
          margin: const EdgeInsets.only(bottom: 12),
          borderRadius: MiuixRadius.lg,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: MiuixColors.primary.withOpacity(0.1),
                      borderRadius: MiuixRadius.xsRadius,
                    ),
                    child: Text(result.source, style: const TextStyle(color: MiuixColors.primary, fontSize: MiuixFontSize.xs, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(result.url, style: const TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(result.title, style: const TextStyle(color: MiuixColors.textLink, fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, decoration: TextDecoration.underline), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(result.snippet, style: const TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

class SearchResultItem {
  SearchResultItem({required this.title, required this.url, required this.snippet, required this.source});
  final String title;
  final String url;
  final String snippet;
  final String source;
}
