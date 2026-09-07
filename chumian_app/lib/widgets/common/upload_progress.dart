import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================================
/// UploadProgress —— 上传进度组件
///
/// 文件列表展示，每个文件独立进度条，成功/失败状态，粉色主题。
/// 用于多文件上传、图片上传、附件上传等场景。
/// ============================================================================

/// 上传文件项
class UploadFileItem {
  /// 文件唯一标识
  final String id;

  /// 文件名
  final String name;

  /// 文件大小（字节）
  final int size;

  /// 已上传字节
  int uploadedBytes;

  /// 上传状态
  UploadStatus status;

  /// 错误信息（失败时）
  String? errorMessage;

  /// 文件类型图标
  final IconData icon;

  UploadFileItem({
    required this.id,
    required this.name,
    required this.size,
    this.uploadedBytes = 0,
    this.status = UploadStatus.pending,
    this.errorMessage,
    this.icon = Icons.insert_drive_file,
  });

  /// 进度百分比
  double get progress {
    if (size <= 0) return 0.0;
    return (uploadedBytes / size).clamp(0.0, 1.0);
  }
}

/// 上传状态
enum UploadStatus {
  pending,
  uploading,
  completed,
  failed,
  cancelled,
}

class UploadProgress extends StatefulWidget {
  /// 文件列表
  final List<UploadFileItem> files;

  /// 重试回调
  final ValueChanged<String>? onRetry;

  /// 取消回调
  final ValueChanged<String>? onCancel;

  /// 删除回调
  final ValueChanged<String>? onDelete;

  /// 是否显示总进度
  final bool showOverallProgress;

  /// 是否可展开/折叠
  final bool collapsible;

  /// 内边距
  final EdgeInsetsGeometry padding;

  const UploadProgress({
    super.key,
    required this.files,
    this.onRetry,
    this.onCancel,
    this.onDelete,
    this.showOverallProgress = true,
    this.collapsible = true,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<UploadProgress> createState() => _UploadProgressState();
}

class _UploadProgressState extends State<UploadProgress> {
  bool _isExpanded = true;

  /// 总进度
  double get _overallProgress {
    if (widget.files.isEmpty) return 0.0;
    final totalSize =
        widget.files.fold<int>(0, (sum, f) => sum + f.size);
    if (totalSize <= 0) return 0.0;
    final uploadedSize =
        widget.files.fold<int>(0, (sum, f) => sum + f.uploadedBytes);
    return (uploadedSize / totalSize).clamp(0.0, 1.0);
  }

  /// 已完成数量
  int get _completedCount =>
      widget.files.where((f) => f.status == UploadStatus.completed).length;

  /// 失败数量
  int get _failedCount =>
      widget.files.where((f) => f.status == UploadStatus.failed).length;

  /// 上传中数量
  int get _uploadingCount =>
      widget.files.where((f) => f.status == UploadStatus.uploading).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: MiuixColors.surface,
        borderRadius: BorderRadius.circular(MiuixRadius.lg),
        border: Border.all(color: MiuixColors.borderLight),
        boxShadow: MiuixShadows.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头部
          _buildHeader(),
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            // 文件列表
            ...widget.files.map((file) => _buildFileItem(file)),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: widget.collapsible
          ? () => setState(() => _isExpanded = !_isExpanded)
          : null,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: MiuixColors.primaryGradient,
              ),
              borderRadius: BorderRadius.circular(MiuixRadius.sm),
            ),
            child: const Icon(Icons.upload, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '上传文件 (${widget.files.length})',
                  style: TextStyle(
                    fontSize: MiuixFontSize.lg,
                    fontWeight: FontWeight.w600,
                    color: MiuixColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _buildStatusSummary(),
                  style: TextStyle(
                    fontSize: MiuixFontSize.sm,
                    color: MiuixColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          // 总进度
          if (widget.showOverallProgress)
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _overallProgress,
                    strokeWidth: 3,
                    backgroundColor: MiuixColors.surfaceVariant,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(MiuixColors.primary),
                  ),
                  Text(
                    '${(_overallProgress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: MiuixColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          if (widget.collapsible) ...[
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.expand_more,
                color: MiuixColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _buildStatusSummary() {
    final parts = <String>[];
    if (_completedCount > 0) parts.add('$_completedCount 已完成');
    if (_uploadingCount > 0) parts.add('$_uploadingCount 上传中');
    if (_failedCount > 0) parts.add('$_failedCount 失败');
    if (parts.isEmpty) return '等待上传';
    return parts.join(' · ');
  }

  Widget _buildFileItem(UploadFileItem file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MiuixColors.background,
        borderRadius: BorderRadius.circular(MiuixRadius.md),
        border: Border.all(
          color: _getStatusColor(file.status).withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // 文件图标
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _getStatusColor(file.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(MiuixRadius.sm),
                ),
                child: Icon(
                  file.icon,
                  color: _getStatusColor(file.status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              // 文件名 + 大小
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      file.name,
                      style: TextStyle(
                        fontSize: MiuixFontSize.md,
                        fontWeight: FontWeight.w500,
                        color: MiuixColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatBytes(file.uploadedBytes)} / ${_formatBytes(file.size)}',
                      style: TextStyle(
                        fontSize: MiuixFontSize.sm,
                        color: MiuixColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              // 状态
              _buildStatusWidget(file),
            ],
          ),
          const SizedBox(height: 8),
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: file.progress,
              minHeight: 4,
              backgroundColor: MiuixColors.surfaceVariant,
              valueColor:
                  AlwaysStoppedAnimation<Color>(_getStatusColor(file.status)),
            ),
          ),
          // 错误信息
          if (file.status == UploadStatus.failed &&
              file.errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              file.errorMessage!,
              style: TextStyle(
                fontSize: MiuixFontSize.sm,
                color: MiuixColors.error,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusWidget(UploadFileItem file) {
    switch (file.status) {
      case UploadStatus.uploading:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(MiuixColors.primary),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${(file.progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: MiuixFontSize.sm,
                color: MiuixColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.onCancel != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: MiuixColors.textTertiary,
                onPressed: () => widget.onCancel!.call(file.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        );
      case UploadStatus.completed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: MiuixColors.success, size: 20),
            const SizedBox(width: 4),
            Text(
              '完成',
              style: TextStyle(
                fontSize: MiuixFontSize.sm,
                color: MiuixColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      case UploadStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onRetry != null)
              GestureDetector(
                onTap: () => widget.onRetry!.call(file.id),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: MiuixColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(MiuixRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh,
                          color: MiuixColors.primary, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        '重试',
                        style: TextStyle(
                          fontSize: 11,
                          color: MiuixColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (widget.onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: MiuixColors.error,
                onPressed: () => widget.onDelete!.call(file.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        );
      case UploadStatus.pending:
        return Text(
          '等待',
          style: TextStyle(
            fontSize: MiuixFontSize.sm,
            color: MiuixColors.textTertiary,
          ),
        );
      case UploadStatus.cancelled:
        return Text(
          '已取消',
          style: TextStyle(
            fontSize: MiuixFontSize.sm,
            color: MiuixColors.textTertiary,
          ),
        );
    }
  }

  Color _getStatusColor(UploadStatus status) {
    switch (status) {
      case UploadStatus.uploading:
        return MiuixColors.primary;
      case UploadStatus.completed:
        return MiuixColors.success;
      case UploadStatus.failed:
        return MiuixColors.error;
      case UploadStatus.pending:
      case UploadStatus.cancelled:
        return MiuixColors.textTertiary;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
