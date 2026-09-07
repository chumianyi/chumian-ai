import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixAvatar —— 圆形/圆角头像
/// 粉色渐变占位，在线状态点，边框，支持网络图片+缓存
/// ============================================================

/// 头像形状
enum MiuixAvatarShape {
  circle,
  rounded,
  square,
}

/// Miuix 风格头像
///
/// 用法：
/// ```dart
/// MiuixAvatar(
///   imageUrl: 'https://...',
///   size: 48,
///   showOnline: true,
/// )
/// ```
class MiuixAvatar extends StatelessWidget {
  const MiuixAvatar({
    super.key,
    this.imageUrl,
    this.imageProvider,
    this.child,
    this.initials,
    this.size = 48.0,
    this.shape = MiuixAvatarShape.circle,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 2.0,
    this.showBorder = false,
    this.showOnline = false,
    this.isOnline = false,
    this.onlineColor,
    this.onlineSize,
    this.onlineAlignment = Alignment.bottomRight,
    this.gradient,
    this.fit = BoxFit.cover,
    this.onTap,
    this.placeholder,
    this.errorWidget,
  });

  /// 网络图片 URL
  final String? imageUrl;

  /// 自定义 ImageProvider
  final ImageProvider? imageProvider;

  /// 自定义子组件
  final Widget? child;

  /// 首字母占位
  final String? initials;

  /// 尺寸
  final double size;

  /// 形状
  final MiuixAvatarShape shape;

  /// 圆角（仅 rounded 形状）
  final double? borderRadius;

  /// 背景色
  final Color? backgroundColor;

  /// 边框颜色
  final Color? borderColor;

  /// 边框宽度
  final double borderWidth;

  /// 是否显示边框
  final bool showBorder;

  /// 是否显示在线状态
  final bool showOnline;

  /// 是否在线
  final bool isOnline;

  /// 在线点颜色
  final Color? onlineColor;

  /// 在线点大小
  final double? onlineSize;

  /// 在线点位置
  final Alignment onlineAlignment;

  /// 背景渐变
  final Gradient? gradient;

  /// 图片填充模式
  final BoxFit fit;

  /// 点击回调
  final VoidCallback? onTap;

  /// 占位 Widget
  final Widget? placeholder;

  /// 错误 Widget
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final double radius = _getRadius();
    final double onlineSz = onlineSize ?? size * 0.28;

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? MiuixColors.primaryLight,
        gradient: gradient ??
            LinearGradient(
              colors: [
                MiuixColors.primaryLight,
                MiuixColors.primary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
        borderRadius: _getBorderRadius(),
        border: showBorder
            ? Border.all(
                color: borderColor ?? Colors.white,
                width: borderWidth,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: MiuixColors.primary.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: _getBorderRadius(),
        child: _buildContent(),
      ),
    );

    // 在线状态点
    if (showOnline) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: onlineAlignment == Alignment.bottomRight ? -2 : null,
            left: onlineAlignment == Alignment.bottomLeft ? -2 : null,
            bottom: -2,
            child: Container(
              width: onlineSz,
              height: onlineSz,
              decoration: BoxDecoration(
                color: isOnline
                    ? (onlineColor ?? MiuixColors.success)
                    : MiuixColors.textTertiary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  Widget _buildContent() {
    if (child != null) return child!;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: fit,
        placeholder: (context, url) =>
            placeholder ?? _buildPlaceholder(),
        errorWidget: (context, url, error) =>
            errorWidget ?? _buildPlaceholder(),
      );
    }

    if (imageProvider != null) {
      return Image(image: imageProvider!, fit: fit);
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Center(
      child: initials != null && initials!.isNotEmpty
          ? Text(
              initials!.length > 2
                  ? initials!.substring(0, 2).toUpperCase()
                  : initials!.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.35,
                fontWeight: FontWeight.w700,
              ),
            )
          : Icon(
              Icons.person,
              size: size * 0.5,
              color: Colors.white.withValues(alpha: 0.8),
            ),
    );
  }

  double _getRadius() {
    switch (shape) {
      case MiuixAvatarShape.circle:
        return size / 2;
      case MiuixAvatarShape.rounded:
        return borderRadius ?? MiuixRadius.md;
      case MiuixAvatarShape.square:
        return 0;
    }
  }

  BorderRadius _getBorderRadius() {
    return BorderRadius.circular(_getRadius());
  }
}

/// ============================================================
/// MiuixAvatarGroup —— 头像组（重叠显示）
/// ============================================================

/// 头像组
class MiuixAvatarGroup extends StatelessWidget {
  const MiuixAvatarGroup({
    super.key,
    required this.avatars,
    this.size = 36.0,
    this.overlap = 0.35,
    this.maxShow = 4,
    this.showMoreCount = true,
  });

  final List<MiuixAvatar> avatars;
  final double size;
  final double overlap;
  final int maxShow;
  final bool showMoreCount;

  @override
  Widget build(BuildContext context) {
    final int showCount = avatars.length.clamp(0, maxShow);
    final int moreCount = avatars.length - showCount;
    final double offset = size * (1 - overlap);

    return SizedBox(
      height: size,
      width: offset * (showCount - 1) +
          size +
          (moreCount > 0 && showMoreCount ? offset : 0),
      child: Stack(
        children: [
          ...List.generate(showCount, (index) {
            return Positioned(
              left: index * offset,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: avatars[index],
              ),
            );
          }),
          if (moreCount > 0 && showMoreCount)
            Positioned(
              left: showCount * offset,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: MiuixColors.surfaceVariant,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$moreCount',
                  style: TextStyle(
                    color: MiuixColors.primary,
                    fontSize: size * 0.28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
