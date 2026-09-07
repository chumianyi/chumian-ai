import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/models/search_result.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// ChatSearchResults —— 搜索来源展示
/// AI 回复下方的搜索来源卡片列表
/// 标题+摘要+链接+来源图标，点击打开，粉色卡片，错落入场
/// ============================================================

class ChatSearchResults extends StatefulWidget {
  const ChatSearchResults({
    super.key,
    required this.results,
    this.onResultTap,
    this.maxVisible = 3,
  });

  /// 搜索结果列表
  final List<SearchResult> results;

  /// 结果点击回调
  final ValueChanged<SearchResult>? onResultTap;

  /// 最大显示数量
  final int maxVisible;

  @override
  State<ChatSearchResults> createState() => _ChatSearchResultsState();
}

class _ChatSearchResultsState extends State<ChatSearchResults>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MiuixDuration.normal,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<SearchResult> get _visibleResults {
    if (_expanded) return widget.results;
    return widget.results.take(widget.maxVisible).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(
        left: MiuixSpacing.md,
        right: MiuixSpacing.md,
        top: MiuixSpacing.xs,
        bottom: MiuixSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: MiuixSpacing.sm),
          ..._visibleResults.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: MiuixSpacing.sm),
              child: _buildResultCard(entry.value, entry.key),
            );
          }),
          if (widget.results.length > widget.maxVisible) _buildExpandButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _controller,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MiuixSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
              borderRadius: MiuixRadius.xsRadius,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.public, size: 12, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  '搜索来源',
                  style: TextStyle(
                    fontSize: MiuixFontSize.xs,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: MiuixSpacing.sm),
          Text(
            '${widget.results.length} 条结果',
            style: const TextStyle(
              fontSize: MiuixFontSize.xs,
              color: MiuixColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(SearchResult result, int index) {
    final anim = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        0.1 + index * 0.08,
        1.0,
        curve: MiuixCurves.easeOut,
      ),
    );

    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.05, 0.1),
          end: Offset.zero,
        ).animate(anim),
        child: MiuixRipple(
          onTap: () => widget.onResultTap?.call(result),
          borderRadius: MiuixRadius.md,
          child: Container(
            padding: const EdgeInsets.all(MiuixSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MiuixColors.primary.withOpacity(0.04),
                  MiuixColors.primaryLight.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: MiuixRadius.mdRadius,
              border: Border.all(
                color: MiuixColors.primary.withOpacity(0.12),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildSourceIcon(result),
                    const SizedBox(width: MiuixSpacing.sm),
                    Expanded(
                      child: Text(
                        result.source ?? '未知来源',
                        style: const TextStyle(
                          fontSize: MiuixFontSize.xs,
                          color: MiuixColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.open_in_new,
                      size: 12,
                      color: MiuixColors.textTertiary,
                    ),
                  ],
                ),
                const SizedBox(height: MiuixSpacing.xs),
                Text(
                  result.title,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.md,
                    fontWeight: FontWeight.w600,
                    color: MiuixColors.textPrimary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (result.snippet != null && result.snippet!.isNotEmpty) ...[
                  const SizedBox(height: MiuixSpacing.xs),
                  Text(
                    result.snippet!,
                    style: const TextStyle(
                      fontSize: MiuixFontSize.sm,
                      color: MiuixColors.textSecondary,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceIcon(SearchResult result) {
    IconData icon = Icons.language;
    final source = result.source?.toLowerCase() ?? '';
    if (source.contains('wiki')) {
      icon = Icons.menu_book;
    } else if (source.contains('github')) {
      icon = Icons.code;
    } else if (source.contains('zhihu') || source.contains('知乎')) {
      icon = Icons.question_answer;
    } else if (source.contains('baidu') || source.contains('百度')) {
      icon = Icons.search;
    } else if (source.contains('bilibili') || source.contains('B站')) {
      icon = Icons.play_circle;
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: MiuixColors.primary.withOpacity(0.1),
        borderRadius: MiuixRadius.xsRadius,
      ),
      child: Icon(
        icon,
        size: 14,
        color: MiuixColors.primary,
      ),
    );
  }

  Widget _buildExpandButton() {
    return MiuixRipple(
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: MiuixRadius.pill,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MiuixSpacing.md,
          vertical: MiuixSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: MiuixColors.primary.withOpacity(0.06),
          borderRadius: MiuixRadius.pillRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _expanded
                  ? '收起'
                  : '查看全部 ${widget.results.length} 条',
              style: const TextStyle(
                fontSize: MiuixFontSize.sm,
                fontWeight: FontWeight.w500,
                color: MiuixColors.primary,
              ),
            ),
            Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              size: 16,
              color: MiuixColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
