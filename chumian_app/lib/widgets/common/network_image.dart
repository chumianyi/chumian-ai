import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================================
/// NetworkImageWidget —— 网络图片封装组件
///
/// 缓存管理，加载占位，错误占位，粉色主题，圆角。
/// 统一处理网络图片的加载、缓存、错误等状态。
/// ============================================================================
class NetworkImageWidget extends StatefulWidget {
  /// 图片 URL
  final String imageUrl;

  /// 宽度
  final double? width;

  /// 高度
  final double? height;

  /// 圆角
  final double borderRadius;

  /// 填充模式
  final BoxFit fit;

  /// 占位图标
  final IconData placeholderIcon;

  /// 错误图标
  final IconData errorIcon;

  /// 自定义占位组件
  final Widget? placeholder;

  /// 自定义错误组件
  final Widget? errorWidget;

  /// 点击回调
  final VoidCallback? onTap;

  /// 是否显示加载进度
  final bool showProgress;

  /// 图片对齐
  final Alignment alignment;

  /// 渐入动画时长
  final Duration fadeInDuration;

  const NetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.image,
    this.errorIcon = Icons.broken_image,
    this.placeholder,
    this.errorWidget,
    this.onTap,
    this.showProgress = true,
    this.alignment = Alignment.center,
    this.fadeInDuration = const Duration(milliseconds: 300),
  });

  @override
  State<NetworkImageWidget> createState() => _NetworkImageWidgetState();
}

class _NetworkImageWidgetState extends State<NetworkImageWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.isEmpty) {
      return _buildPlaceholderContainer();
    }

    final image = CachedNetworkImage(
      imageUrl: widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      fadeInDuration: widget.fadeInDuration,
      fadeOutDuration: const Duration(milliseconds: 200),
      placeholder: (context, url) => widget.placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) =>
          widget.errorWidget ?? _buildErrorWidget(),
      progressIndicatorBuilder: widget.showProgress
          ? (context, url, downloadProgress) {
              return _buildProgressPlaceholder(downloadProgress);
            }
          : null,
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: _clipImage(image),
      );
    }
    return _clipImage(image);
  }

  Widget _clipImage(Widget image) {
    if (widget.borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: image,
      );
    }
    return image;
  }

  // 占位容器（URL 为空时）
  Widget _buildPlaceholderContainer() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: MiuixColors.surfaceVariant,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Center(
        child: Icon(
          widget.placeholderIcon,
          color: MiuixColors.textTertiary,
          size: 32,
        ),
      ),
    );
  }

  // 加载占位
  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: MiuixColors.surfaceVariant,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(MiuixColors.primary),
          ),
        ),
      ),
    );
  }

  // 带进度的占位
  Widget _buildProgressPlaceholder(ImageChunkEvent? downloadProgress) {
    final progress = downloadProgress?.progress;
    return Container(
      width: widget.width,
      height: widget.height,
      color: MiuixColors.surfaceVariant,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                value: progress,
                valueColor:
                    AlwaysStoppedAnimation<Color>(MiuixColors.primary),
                backgroundColor: MiuixColors.border,
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: MiuixColors.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 错误占位
  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MiuixColors.surfaceVariant,
            MiuixColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MiuixColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.errorIcon,
                color: MiuixColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: 12,
                color: MiuixColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// CircleAvatarWidget —— 圆形头像封装
/// ============================================================================
class CircleAvatarWidget extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final String? fallbackText;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool showBorder;
  final double borderWidth;

  const CircleAvatarWidget({
    super.key,
    required this.imageUrl,
    this.radius = 24.0,
    this.fallbackText,
    this.backgroundColor,
    this.onTap,
    this.showBorder = false,
    this.borderWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: MiuixColors.primary, width: borderWidth)
            : null,
      ),
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: backgroundColor ?? MiuixColors.surfaceVariant,
                  child: Center(
                    child: SizedBox(
                      width: radius * 0.6,
                      height: radius * 0.6,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(MiuixColors.primary),
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: backgroundColor ?? MiuixColors.primaryLight,
                  child: Center(
                    child: Text(
                      fallbackText ?? '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: radius * 0.7,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
            : Container(
                color: backgroundColor ?? MiuixColors.primaryLight,
                child: Center(
                  child: Text(
                    fallbackText ?? '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: radius * 0.7,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }
    return avatar;
  }
}
