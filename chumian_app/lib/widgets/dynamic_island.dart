/// 灵动岛 / 原子岛组件：应用内顶部悬浮通知，支持展开/收起、配置大小位置。
library;

import 'package:flutter/material.dart';

enum IslandStyle { dynamic, atomic }

class IslandMessage {
  final String title;
  final String body;
  final IconData icon;
  final IslandType type;
  const IslandMessage({
    required this.title,
    required this.body,
    required this.icon,
    this.type = IslandType.info,
  });
}

enum IslandType { info, music, message }

class DynamicIsland extends StatefulWidget {
  final bool enabled;
  final IslandStyle style;
  final double width;
  final double height;
  final double topPadding;
  final IslandMessage? message;
  final VoidCallback? onTap;
  final bool isMusicPlaying;
  final String? musicTitle;
  final VoidCallback? onMusicToggle;

  const DynamicIsland({
    super.key,
    required this.enabled,
    this.style = IslandStyle.dynamic,
    this.width = 126,
    this.height = 36,
    this.topPadding = 8,
    this.message,
    this.onTap,
    this.isMusicPlaying = false,
    this.musicTitle,
    this.onMusicToggle,
  });

  @override
  State<DynamicIsland> createState() => _DynamicIslandState();
}

class _DynamicIslandState extends State<DynamicIsland> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(DynamicIsland oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message != null && oldWidget.message != widget.message) {
      _expand();
    }
  }

  void _expand() {
    _expanded = true;
    _controller.forward();
    Future.delayed(const Duration(seconds: 3), _collapse);
  }

  void _collapse() {
    if (mounted) {
      _expanded = false;
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.black;

    return Positioned(
      top: widget.topPadding,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () {
            if (_expanded) {
              _collapse();
              widget.onTap?.call();
            } else {
              _expand();
            }
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = Curves.easeOutCubic.transform(_controller.value);
              final expandedWidth = widget.width + t * 200;
              final expandedHeight = widget.height + t * 50;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: expandedWidth,
                height: expandedHeight,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(
                    widget.style == IslandStyle.atomic ? 16 : expandedHeight / 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _expanded || t > 0.1
                    ? _buildExpandedContent(t, isDark)
                    : _buildCollapsedContent(isDark),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedContent(bool isDark) {
    if (widget.musicTitle != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.isMusicPlaying ? Icons.music_note : Icons.play_arrow,
            color: const Color(0xFFFF6B9D),
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              widget.musicTitle!,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (widget.onMusicToggle != null)
            GestureDetector(
              onTap: widget.onMusicToggle,
              child: Icon(
                widget.isMusicPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 16,
              ),
            ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFFFF6B9D),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '初眠AI',
          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildExpandedContent(double t, bool isDark) {
    final msg = widget.message;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            msg?.icon ?? Icons.notifications,
            color: const Color(0xFFFF6B9D),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  msg?.title ?? '初眠AI',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (msg != null)
                  Text(
                    msg.body.length > 50 ? '${msg.body.substring(0, 50)}...' : msg.body,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
