import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================================
/// ImageGallery —— 图片画廊组件
///
/// 网格布局，点击放大预览，粉色主题，加载占位，删除按钮。
/// 用于图片展示墙、相册、用户上传图片管理等场景。
/// ============================================================================
class ImageGallery extends StatefulWidget {
  /// 图片 URL 列表
  final List<String> imageUrls;

  /// 网格列数
  final int crossAxisCount;

  /// 网格间距
  final double spacing;

  /// 行间距
  final double runSpacing;

  /// 图片圆角
  final double borderRadius;

  /// 图片宽高比
  final double aspectRatio;

  /// 是否显示删除按钮
  final bool showDelete;

  /// 删除回调
  final ValueChanged<int>? onDelete;

  /// 图片点击回调（返回索引，默认打开预览）
  final ValueChanged<int>? onImageTap;

  /// 最大显示数量（null 表示全部）
  final int? maxCount;

  /// 超出最大数量时显示"+N"
  final bool showOverflow;

  /// 内边距
  final EdgeInsetsGeometry padding;

  const ImageGallery({
    super.key,
    required this.imageUrls,
    this.crossAxisCount = 3,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.borderRadius = 12.0,
    this.aspectRatio = 1.0,
    this.showDelete = false,
    this.onDelete,
    this.onImageTap,
    this.maxCount,
    this.showOverflow = true,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  @override
  Widget build(BuildContext context) {
    final displayUrls = widget.maxCount != null &&
            widget.imageUrls.length > widget.maxCount!
        ? widget.imageUrls.sublist(0, widget.maxCount!)
        : widget.imageUrls;
    final overflowCount = widget.maxCount != null &&
            widget.imageUrls.length > widget.maxCount!
        ? widget.imageUrls.length - widget.maxCount!
        : 0;

    return Padding(
      padding: widget.padding,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          mainAxisSpacing: widget.runSpacing,
          crossAxisSpacing: widget.spacing,
          childAspectRatio: widget.aspectRatio,
        ),
        itemCount: displayUrls.length + (overflowCount > 0 ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= displayUrls.length) {
            return _buildOverflowItem(overflowCount);
          }
          return _buildImageItem(displayUrls[index], index);
        },
      ),
    );
  }

  Widget _buildImageItem(String url, int index) {
    return GestureDetector(
      onTap: () {
        if (widget.onImageTap != null) {
          widget.onImageTap!.call(index);
        } else {
          _openPreview(index);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: MiuixColors.surfaceVariant,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(MiuixColors.primary),
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: MiuixColors.surfaceVariant,
                child: Icon(
                  Icons.broken_image,
                  color: MiuixColors.textTertiary,
                  size: 32,
                ),
              ),
            ),
          ),
          // 删除按钮
          if (widget.showDelete)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => widget.onDelete?.call(index),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverflowItem(int count) {
    return GestureDetector(
      onTap: () {
        if (widget.onImageTap != null) {
          widget.onImageTap!.call(widget.maxCount!);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Container(
          color: MiuixColors.primary.withOpacity(0.15),
          child: Center(
            child: Text(
              '+$count',
              style: TextStyle(
                color: MiuixColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 打开图片预览
  void _openPreview(int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _ImagePreviewPage(
            imageUrls: widget.imageUrls,
            initialIndex: initialIndex,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

/// 图片预览页面
class _ImagePreviewPage extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _ImagePreviewPage({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<_ImagePreviewPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.imageUrls[index],
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          );
        },
      ),
      // 底部指示器
      bottomNavigationBar: widget.imageUrls.length > 1
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.imageUrls.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _currentIndex ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _currentIndex
                          ? MiuixColors.primary
                          : Colors.white30,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            )
          : null,
    );
  }
}
