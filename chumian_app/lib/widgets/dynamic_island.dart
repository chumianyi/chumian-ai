/// 灵动岛 / 原子岛组件（Neumorphism 风格，可配置大小位置）。
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum IslandStyle { dynamic, atomic }

class IslandMessage {
  final String title;
  final String body;
  final IconData icon;
  const IslandMessage({required this.title, required this.body, required this.icon});
}

class DynamicIsland extends StatefulWidget {
  final bool enabled;
  final IslandStyle style;
  final double width;
  final double height;
  final double topPadding;
  final double leftPadding;
  final IslandMessage? message;
  final VoidCallback? onTap;
  final bool isMusicPlaying;
  final String? musicTitle;
  final VoidCallback? onMusicToggle;

  const DynamicIsland({
    super.key,
    required this.enabled,
    this.style = IslandStyle.dynamic,
    this.width = 120,
    this.height = 34,
    this.topPadding = 12,
    this.leftPadding = 0,
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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
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
    final bgColor = isDark ? const Color(0xFF1E1E24) : const Color(0xFF2A2A32);
    final isAtomic = widget.style == IslandStyle.atomic;

    return Positioned(
      top: widget.topPadding,
      left: widget.leftPadding > 0 ? widget.leftPadding : null,
      right: widget.leftPadding > 0 ? null : 0,
      child: Center(
        widthFactor: 1,
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
              final expandedW = widget.width + t * (isAtomic ? 180 : 200);
              final expandedH = widget.height + t * (isAtomic ? 40 : 46);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: expandedW,
                height: expandedH,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(
                    isAtomic ? 14 : expandedH / 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(-1, -1),
                    ),
                  ],
                ),
                child: (_expanded || t > 0.1)
                    ? _buildExpanded(t, isDark)
                    : _buildCollapsed(isDark),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsed(bool isDark) {
    if (widget.musicTitle != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.isMusicPlaying ? Icons.music_note : Icons.play_arrow,
              color: const Color(0xFFFF6B9D),
              size: 14,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                widget.musicTitle!,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (widget.onMusicToggle != null)
              GestureDetector(
                onTap: widget.onMusicToggle,
                child: Icon(
                  widget.isMusicPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white70,
                  size: 14,
                ),
              ),
          ],
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(color: Color(0xFFFF6B9D), shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        const Text('初眠', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildExpanded(double t, bool isDark) {
    final msg = widget.message;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B9D).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(msg?.icon ?? Icons.notifications, color: const Color(0xFFFF6B9D), size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  msg?.title ?? '初眠AI',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (msg != null)
                  Text(
                    msg.body.length > 50 ? '${msg.body.substring(0, 50)}...' : msg.body,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 10),
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

/// 灵动岛配置管理
class IslandConfig {
  static const _kEnabled = 'island_enabled';
  static const _kStyle = 'island_style';
  static const _kWidth = 'island_width';
  static const _kHeight = 'island_height';
  static const _kTop = 'island_top';

  static Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool(_kEnabled) ?? false,
      'style': IslandStyle.values[prefs.getInt(_kStyle) ?? 0],
      'width': prefs.getDouble(_kWidth) ?? 120,
      'height': prefs.getDouble(_kHeight) ?? 34,
      'top': prefs.getDouble(_kTop) ?? 12,
    };
  }

  static Future<void> save(Map<String, dynamic> config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, config['enabled']);
    await prefs.setInt(_kStyle, (config['style'] as IslandStyle).index);
    await prefs.setDouble(_kWidth, config['width']);
    await prefs.setDouble(_kHeight, config['height']);
    await prefs.setDouble(_kTop, config['top']);
  }
}
