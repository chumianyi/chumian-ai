import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================================
/// DownloadProgress —— 下载进度组件
///
/// 支持圆形/线性两种进度样式，速度显示，暂停/取消控制，粉色主题。
/// 用于文件下载、模型下载、资源更新等场景。
/// ============================================================================

/// 下载状态
enum DownloadStatus {
  /// 等待中
  pending,

  /// 下载中
  downloading,

  /// 已暂停
  paused,

  /// 已完成
  completed,

  /// 失败
  failed,

  /// 已取消
  cancelled,
}

class DownloadProgress extends StatefulWidget {
  /// 文件名
  final String fileName;

  /// 文件大小（字节）
  final int totalBytes;

  /// 已下载字节
  final int downloadedBytes;

  /// 下载速度（字节/秒）
  final double speed;

  /// 下载状态
  final DownloadStatus status;

  /// 显示样式：圆形或线性
  final bool useCircular;

  /// 暂停回调
  final VoidCallback? onPause;

  /// 继续回调
  final VoidCallback? onResume;

  /// 取消回调
  final VoidCallback? onCancel;

  /// 重试回调
  final VoidCallback? onRetry;

  /// 圆形进度大小
  final double circularSize;

  /// 内边距
  final EdgeInsetsGeometry padding;

  const DownloadProgress({
    super.key,
    required this.fileName,
    required this.totalBytes,
    this.downloadedBytes = 0,
    this.speed = 0,
    this.status = DownloadStatus.downloading,
    this.useCircular = false,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onRetry,
    this.circularSize = 64.0,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<DownloadProgress> createState() => _DownloadProgressState();
}

class _DownloadProgressState extends State<DownloadProgress> {
  /// 进度百分比
  double get _progress {
    if (widget.totalBytes <= 0) return 0.0;
    return (widget.downloadedBytes / widget.totalBytes).clamp(0.0, 1.0);
  }

  /// 格式化文件大小
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// 格式化速度
  String _formatSpeed(double bytesPerSec) {
    if (bytesPerSec < 1024) return '${bytesPerSec.toStringAsFixed(0)} B/s';
    if (bytesPerSec < 1024 * 1024) {
      return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(2)} MB/s';
  }

  /// 预计剩余时间
  String get _remainingTime {
    if (widget.speed <= 0 || widget.status != DownloadStatus.downloading) {
      return '--:--';
    }
    final remainingBytes = widget.totalBytes - widget.downloadedBytes;
    final remainingSeconds = remainingBytes ~/ widget.speed;
    if (remainingSeconds <= 0) return '00:00';
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: MiuixColors.surface,
        borderRadius: BorderRadius.circular(MiuixRadius.lg),
        border: Border.all(color: MiuixColors.borderLight),
      ),
      child: widget.useCircular ? _buildCircular() : _buildLinear(),
    );
  }

  // ===== 线性样式 =====
  Widget _buildLinear() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 文件名 + 状态
        Row(
          children: [
            Icon(
              _getStatusIcon(),
              color: _getStatusColor(),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.fileName,
                style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _getStatusText(),
              style: TextStyle(
                fontSize: MiuixFontSize.sm,
                color: _getStatusColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 进度条
        _buildProgressBar(),
        const SizedBox(height: 8),
        // 详细信息
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_formatBytes(widget.downloadedBytes)} / ${_formatBytes(widget.totalBytes)}',
              style: TextStyle(
                fontSize: MiuixFontSize.sm,
                color: MiuixColors.textSecondary,
              ),
            ),
            if (widget.status == DownloadStatus.downloading)
              Text(
                '${_formatSpeed(widget.speed)} · 剩余 $_remainingTime',
                style: TextStyle(
                  fontSize: MiuixFontSize.sm,
                  color: MiuixColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // 控制按钮
        _buildControls(),
      ],
    );
  }

  Widget _buildProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: _progress,
        minHeight: 6,
        backgroundColor: MiuixColors.surfaceVariant,
        valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
      ),
    );
  }

  // ===== 圆形样式 =====
  Widget _buildCircular() {
    return Row(
      children: [
        // 圆形进度
        SizedBox(
          width: widget.circularSize,
          height: widget.circularSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: widget.circularSize,
                height: widget.circularSize,
                child: CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 5,
                  backgroundColor: MiuixColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(_progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _getStatusColor(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // 信息
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.fileName,
                style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatBytes(widget.downloadedBytes)} / ${_formatBytes(widget.totalBytes)}',
                style: TextStyle(
                  fontSize: MiuixFontSize.sm,
                  color: MiuixColors.textSecondary,
                ),
              ),
              if (widget.status == DownloadStatus.downloading) ...[
                const SizedBox(height: 2),
                Text(
                  '${_formatSpeed(widget.speed)} · 剩余 $_remainingTime',
                  style: TextStyle(
                    fontSize: MiuixFontSize.sm,
                    color: MiuixColors.primary,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              _buildControls(),
            ],
          ),
        ),
      ],
    );
  }

  // ===== 控制按钮 =====
  Widget _buildControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.status == DownloadStatus.downloading &&
            widget.onPause != null)
          _buildControlButton(
            icon: Icons.pause,
            label: '暂停',
            onTap: widget.onPause,
          ),
        if (widget.status == DownloadStatus.paused && widget.onResume != null)
          _buildControlButton(
            icon: Icons.play_arrow,
            label: '继续',
            onTap: widget.onResume,
          ),
        if (widget.status == DownloadStatus.failed && widget.onRetry != null)
          _buildControlButton(
            icon: Icons.refresh,
            label: '重试',
            onTap: widget.onRetry,
          ),
        if ((widget.status == DownloadStatus.downloading ||
                widget.status == DownloadStatus.paused) &&
            widget.onCancel != null) ...[
          const SizedBox(width: 8),
          _buildControlButton(
            icon: Icons.close,
            label: '取消',
            onTap: widget.onCancel,
            isDestructive: true,
          ),
        ],
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? MiuixColors.error : MiuixColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(MiuixRadius.pill),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: MiuixFontSize.sm,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== 状态辅助 =====
  IconData _getStatusIcon() {
    switch (widget.status) {
      case DownloadStatus.pending:
        return Icons.schedule;
      case DownloadStatus.downloading:
        return Icons.download;
      case DownloadStatus.paused:
        return Icons.pause_circle;
      case DownloadStatus.completed:
        return Icons.check_circle;
      case DownloadStatus.failed:
        return Icons.error;
      case DownloadStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case DownloadStatus.pending:
        return MiuixColors.textTertiary;
      case DownloadStatus.downloading:
        return MiuixColors.primary;
      case DownloadStatus.paused:
        return MiuixColors.warning;
      case DownloadStatus.completed:
        return MiuixColors.success;
      case DownloadStatus.failed:
        return MiuixColors.error;
      case DownloadStatus.cancelled:
        return MiuixColors.textTertiary;
    }
  }

  String _getStatusText() {
    switch (widget.status) {
      case DownloadStatus.pending:
        return '等待中';
      case DownloadStatus.downloading:
        return '下载中';
      case DownloadStatus.paused:
        return '已暂停';
      case DownloadStatus.completed:
        return '已完成';
      case DownloadStatus.failed:
        return '失败';
      case DownloadStatus.cancelled:
        return '已取消';
    }
  }
}
