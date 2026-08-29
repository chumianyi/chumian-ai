/// 头像与在线/关注状态徽标。
library;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'context_ext.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

/// 通用头像：支持网络图 / 首字符占位 / 在线点 / 尺寸。
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final Color? color;
  final bool showOnline;
  final bool showBorder;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 44,
    this.color,
    this.showOnline = false,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? ColorTools.fromSeed(name ?? '');
    final borderRadius = BorderRadius.circular(size * 0.32);

    Widget content;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      content = ClipRRect(
        borderRadius: borderRadius,
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _placeholder(bg, borderRadius),
          errorWidget: (_, __, ___) => _placeholder(bg, borderRadius),
        ),
      );
    } else {
      content = _placeholder(bg, borderRadius);
    }

    if (showBorder) {
      content = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: context.surface,
          shape: BoxShape.circle,
        ),
        child: content,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          if (showOnline)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: context.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder(Color bg, BorderRadius radius) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bg, bg.withValues(alpha: 0.75)],
        ),
        borderRadius: radius,
      ),
      child: Text(
        Formatters.initialOf(name),
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// 关注关系标签。
class FollowBadge extends StatelessWidget {
  final bool isMutual;
  final bool isFollowing;

  const FollowBadge({
    super.key,
    this.isMutual = false,
    this.isFollowing = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isMutual) {
      return _badge(context, '互相关注', context.info);
    }
    if (isFollowing) {
      return _badge(context, '已关注', context.success);
    }
    return _badge(context, '未关注', context.textTertiary);
  }

  Widget _badge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// 关注按钮。
class FollowButton extends StatefulWidget {
  final bool isFollowing;
  final ValueChanged<bool> onChanged;
  final bool compact;

  const FollowButton({
    super.key,
    required this.isFollowing,
    required this.onChanged,
    this.compact = false,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  late bool _following;

  @override
  void initState() {
    super.initState();
    _following = widget.isFollowing;
  }

  @override
  void didUpdateWidget(FollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFollowing != widget.isFollowing) {
      _following = widget.isFollowing;
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.compact ? 34.0 : 40.0;
    return GestureDetector(
      onTap: () {
        setState(() => _following = !_following);
        widget.onChanged(_following);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        padding: EdgeInsets.symmetric(horizontal: widget.compact ? 14 : 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: _following ? null : context.vibrantGradient,
          color: _following ? context.surface : null,
          borderRadius: BorderRadius.circular(height / 2),
          border: _following ? Border.all(color: context.primary.withValues(alpha: 0.5)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _following ? Icons.check_rounded : Icons.person_add_alt_1_rounded,
              size: 16,
              color: _following ? context.primary : context.onPrimary,
            ),
            const SizedBox(width: 5),
            Text(
              _following ? '已关注' : '关注',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _following ? context.primary : context.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
