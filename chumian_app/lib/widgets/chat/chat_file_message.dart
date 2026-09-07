import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// ChatFileMessage —— 文件消息组件
/// 文件图标+文件名+大小，下载按钮，进度条
/// 支持 PDF/Word/Excel/图片等，粉色主题
/// ============================================================

/// 文件类型
enum FileType { pdf, word, excel, ppt, image, video, audio, zip, other }

/// 文件消息数据
class FileMessageData {
  final String fileName;
  final String fileSize;
  final String? fileUrl;
  final FileType fileType;
  final double? downloadProgress;
  final bool isDownloading;

  const FileMessageData({
    required this.fileName,
    required this.fileSize,
    this.fileUrl,
    this.fileType = FileType.other,
    this.downloadProgress,
    this.isDownloading = false,
  });
}

class ChatFileMessage extends StatefulWidget {
  const ChatFileMessage({
    super.key,
    required this.data,
    this.isUser = false,
    this.onTap,
    this.onDownload,
  });

  /// 文件数据
  final FileMessageData data;

  /// 是否为用户消息
  final bool isUser;

  /// 文件点击回调
  final VoidCallback? onTap;

  /// 下载回调
  final VoidCallback? onDownload;

  @override
  State<ChatFileMessage> createState() => _ChatFileMessageState();
}

class _ChatFileMessageState extends State<ChatFileMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: MiuixDuration.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: MiuixCurves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  (Color, Color, IconData) _getFileStyle(FileType type) {
    switch (type) {
      case FileType.pdf:
        return (const Color(0xFFFF4D4F), const Color(0xFFFF7875), Icons.picture_as_pdf);
      case FileType.word:
        return (const Color(0xFF1890FF), const Color(0xFF40A9FF), Icons.description);
      case FileType.excel:
        return (const Color(0xFF52C41A), const Color(0xFF73D13D), Icons.table_chart);
      case FileType.ppt:
        return (const Color(0xFFFA8C16), const Color(0xFFFFA940), Icons.slideshow);
      case FileType.image:
        return (MiuixColors.primary, MiuixColors.primaryLight, Icons.image);
      case FileType.video:
        return (const Color(0xFF722ED1), const Color(0xFF9254DE), Icons.videocam);
      case FileType.audio:
        return (const Color(0xFF13C2C2), const Color(0xFF36CFC9), Icons.audiotrack);
      case FileType.zip:
        return (const Color(0xFF8C8C8C), const Color(0xFFA6A6A6), Icons.folder_zip);
      case FileType.other:
        return (MiuixColors.textSecondary, MiuixColors.textTertiary, Icons.insert_drive_file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bgColor, lightColor, icon) = _getFileStyle(widget.data.fileType);

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: MiuixRipple(
          onTap: widget.onTap,
          borderRadius: MiuixRadius.lg,
          child: Container(
            width: 260,
            padding: const EdgeInsets.all(MiuixSpacing.md),
            decoration: BoxDecoration(
              color: widget.isUser ? null : MiuixColors.surface,
              gradient: widget.isUser
                  ? const LinearGradient(colors: MiuixColors.primaryGradient)
                  : null,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(MiuixRadius.lg),
                topRight: const Radius.circular(MiuixRadius.lg),
                bottomLeft: Radius.circular(
                  widget.isUser ? MiuixRadius.lg : MiuixRadius.sm,
                ),
                bottomRight: Radius.circular(
                  widget.isUser ? MiuixRadius.sm : MiuixRadius.lg,
                ),
              ),
              border: widget.isUser
                  ? null
                  : Border.all(color: MiuixColors.borderLight, width: 1),
              boxShadow: widget.isUser
                  ? [
                      BoxShadow(
                        color: MiuixColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : MiuixShadows.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildFileIcon(bgColor, lightColor, icon),
                    const SizedBox(width: MiuixSpacing.md),
                    Expanded(child: _buildFileInfo()),
                    _buildDownloadButton(),
                  ],
                ),
                if (widget.data.isDownloading &&
                    widget.data.downloadProgress != null) ...[
                  const SizedBox(height: MiuixSpacing.sm),
                  _buildProgressBar(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon(Color bgColor, Color lightColor, IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [lightColor, bgColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: MiuixRadius.mdRadius,
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 22,
        color: Colors.white,
      ),
    );
  }

  Widget _buildFileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.data.fileName,
          style: TextStyle(
            fontSize: MiuixFontSize.md,
            fontWeight: FontWeight.w600,
            color: widget.isUser ? Colors.white : MiuixColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          widget.data.fileSize,
          style: TextStyle(
            fontSize: MiuixFontSize.sm,
            color: widget.isUser
                ? Colors.white.withOpacity(0.7)
                : MiuixColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadButton() {
    if (widget.data.isDownloading) {
      return SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.isUser ? Colors.white : MiuixColors.primary,
          ),
        ),
      );
    }

    return MiuixRipple(
      onTap: widget.onDownload,
      borderRadius: MiuixRadius.pill,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: widget.isUser
              ? Colors.white.withOpacity(0.2)
              : MiuixColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.download,
          size: 16,
          color: widget.isUser ? Colors.white : MiuixColors.primary,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: widget.data.downloadProgress,
        minHeight: 4,
        backgroundColor: widget.isUser
            ? Colors.white.withOpacity(0.2)
            : MiuixColors.surfaceVariant,
        valueColor: AlwaysStoppedAnimation<Color>(
          widget.isUser ? Colors.white : MiuixColors.primary,
        ),
      ),
    );
  }
}
