import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_dialog.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// StoragePage —— 存储管理
/// 缓存大小显示，清除缓存动画，图片/视频/文件分类
/// 存储空间进度环
/// ============================================================
class StoragePage extends StatefulWidget {
  const StoragePage({super.key});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _clearController;

  double _cacheSize = 256.8; // MB
  double _imageSize = 512.3;
  double _videoSize = 1024.5;
  double _fileSize = 128.2;
  double _totalStorage = 8192; // 8GB
  bool _isClearing = false;

  static const List<StorageCategory> _categories = [
    StorageCategory(icon: Icons.image, label: '图片缓存', color: Color(0xFFFF8FB5)),
    StorageCategory(icon: Icons.videocam, label: '视频缓存', color: Color(0xFFFF6B9D)),
    StorageCategory(icon: Icons.insert_drive_file, label: '文件缓存', color: Color(0xFFFF5588)),
    StorageCategory(icon: Icons.delete_sweep, label: '其他缓存', color: Color(0xFFE8558A)),
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _clearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _clearController.dispose();
    super.dispose();
  }

  double get _usedStorage => _cacheSize + _imageSize + _videoSize + _fileSize;
  double get _usagePercent => (_usedStorage / _totalStorage).clamp(0.0, 1.0);

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.07, (index * 0.07) + 0.4,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.07, (index * 0.07) + 0.4,
            curve: Curves.easeOutCubic),
      ),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) => Opacity(
        opacity: anim.value,
        child: Transform.translate(offset: slide.value, child: child),
      ),
    );
  }

  Future<void> _clearCache() async {
    MiuixDialog.show(
      context,
      title: '清除缓存',
      content: '将清除 ${_formatSize(_cacheSize)} 缓存数据，不影响已保存的文件。确定继续吗？',
      type: MiuixDialogType.info,
      confirmText: '清除',
      onConfirm: () async {
        setState(() => _isClearing = true);
        _clearController.forward(from: 0);
        await Future.delayed(const Duration(milliseconds: 1500));
        setState(() {
          _cacheSize = 0;
          _isClearing = false;
        });
        MiuixToast.show(context,
            message: '缓存清除成功', type: MiuixToastType.success);
      },
    );
  }

  Future<void> _clearAll() async {
    MiuixDialog.show(
      context,
      title: '清除全部数据',
      content: '将清除所有缓存数据（${_formatSize(_usedStorage)}），包括图片、视频和文件缓存。此操作不可恢复。',
      type: MiuixDialogType.warning,
      confirmText: '全部清除',
      onConfirm: () async {
        setState(() => _isClearing = true);
        await Future.delayed(const Duration(milliseconds: 1500));
        setState(() {
          _cacheSize = 0;
          _imageSize = 0;
          _videoSize = 0;
          _fileSize = 0;
          _isClearing = false;
        });
        MiuixToast.show(context,
            message: '全部数据已清除', type: MiuixToastType.success);
      },
    );
  }

  String _formatSize(double mb) {
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(1)} GB';
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '存储管理',
        backgroundColor: MiuixColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            _buildAnimatedItem(_buildStorageOverview(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildUsageBreakdown(), 1),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildCacheActions(), 2),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildCategoryList(), 3),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageOverview() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF8FB5), Color(0xFFFF6B9D), Color(0xFFFF5588)],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: AnimatedBuilder(
              animation: _entryController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _StorageRingPainter(
                    progress: _usagePercent * _entryController.value,
                    isClearing: _isClearing,
                    clearProgress: _clearController.value,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatSize(_usedStorage),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '/ ${_formatSize(_totalStorage)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: MiuixFontSize.xs,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '已使用存储空间',
            style: TextStyle(
              color: Colors.white,
              fontSize: MiuixFontSize.md,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(_usagePercent * 100).toStringAsFixed(1)}% 已使用',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: MiuixFontSize.sm,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageBreakdown() {
    final items = [
      _BreakdownItem('图片', _imageSize, const Color(0xFFFF8FB5)),
      _BreakdownItem('视频', _videoSize, const Color(0xFFFF6B9D)),
      _BreakdownItem('文件', _fileSize, const Color(0xFFFF5588)),
      _BreakdownItem('缓存', _cacheSize, const Color(0xFFE8558A)),
    ];

    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '存储分布',
            style: TextStyle(
              fontSize: MiuixFontSize.md,
              fontWeight: FontWeight.w600,
              color: MiuixColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // 堆叠进度条
          ClipRRect(
            borderRadius: MiuixRadius.pillRadius,
            child: SizedBox(
              height: 12,
              child: Row(
                children: items.map((item) {
                  final percent = _usedStorage > 0
                      ? (item.size / _usedStorage).clamp(0.0, 1.0)
                      : 0.0;
                  return Expanded(
                    flex: (percent * 100).toInt(),
                    child: Container(color: item.color),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: MiuixRadius.xsRadius,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: MiuixFontSize.sm,
                      color: MiuixColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatSize(item.size),
                    style: const TextStyle(
                      fontSize: MiuixFontSize.sm,
                      fontWeight: FontWeight.w600,
                      color: MiuixColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCacheActions() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: MiuixColors.primaryLight.withOpacity(0.15),
                  borderRadius: MiuixRadius.mdRadius,
                ),
                child: const Icon(Icons.cleaning_services,
                    color: MiuixColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '缓存清理',
                      style: TextStyle(
                        fontSize: MiuixFontSize.md,
                        fontWeight: FontWeight.w600,
                        color: MiuixColors.textPrimary,
                      ),
                    ),
                    Text(
                      '可清理 ${_formatSize(_cacheSize)} 缓存',
                      style: const TextStyle(
                        fontSize: MiuixFontSize.sm,
                        color: MiuixColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MiuixButton(
                  label: _isClearing ? '清理中...' : '清除缓存',
                  icon: Icons.delete_sweep,
                  type: MiuixButtonType.primary,
                  loading: _isClearing,
                  onPressed: _isClearing ? null : _clearCache,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MiuixButton(
                  label: '全部清除',
                  icon: Icons.delete_forever,
                  type: MiuixButtonType.danger,
                  onPressed: _isClearing ? null : _clearAll,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    final data = [
      _CategoryData(
        icon: Icons.image,
        title: '图片缓存',
        size: _imageSize,
        count: 256,
        color: const Color(0xFFFF8FB5),
      ),
      _CategoryData(
        icon: Icons.videocam,
        title: '视频缓存',
        size: _videoSize,
        count: 12,
        color: const Color(0xFFFF6B9D),
      ),
      _CategoryData(
        icon: Icons.insert_drive_file,
        title: '文件缓存',
        size: _fileSize,
        count: 45,
        color: const Color(0xFFFF5588),
      ),
    ];

    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(0),
      child: Column(
        children: List.generate(data.length, (index) {
          final item = data[index];
          return Column(
            children: [
              if (index > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 72),
                  child: Container(height: 1, color: MiuixColors.divider),
                ),
              MiuixRipple(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.15),
                          borderRadius: MiuixRadius.mdRadius,
                        ),
                        child: Icon(item.icon, color: item.color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: MiuixFontSize.md,
                                fontWeight: FontWeight.w500,
                                color: MiuixColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${item.count} 个文件',
                              style: const TextStyle(
                                fontSize: MiuixFontSize.xs,
                                color: MiuixColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatSize(item.size),
                        style: const TextStyle(
                          fontSize: MiuixFontSize.md,
                          fontWeight: FontWeight.w600,
                          color: MiuixColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right,
                          color: MiuixColors.textTertiary, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _BreakdownItem {
  final String label;
  final double size;
  final Color color;
  const _BreakdownItem(this.label, this.size, this.color);
}

class _CategoryData {
  final IconData icon;
  final String title;
  final double size;
  final int count;
  final Color color;
  const _CategoryData({
    required this.icon,
    required this.title,
    required this.size,
    required this.count,
    required this.color,
  });
}

class StorageCategory {
  final IconData icon;
  final String label;
  final Color color;
  const StorageCategory(
      {required this.icon, required this.label, required this.color});
}

/// 存储进度环绘制器
class _StorageRingPainter extends CustomPainter {
  final double progress;
  final bool isClearing;
  final double clearProgress;

  _StorageRingPainter({
    required this.progress,
    required this.isClearing,
    required this.clearProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;

    // 背景环
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // 进度环
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [Colors.white, Colors.white.withOpacity(0.7), Colors.white],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    // 清除动画粒子
    if (isClearing) {
      for (int i = 0; i < 12; i++) {
        final angle = (i / 12) * 2 * math.pi + clearProgress * 2 * math.pi;
        final r = radius + 12 + sin(clearProgress * math.pi * 3 + i) * 6;
        final dx = center.dx + cos(angle) * r;
        final dy = center.dy + sin(angle) * r;
        canvas.drawCircle(
          Offset(dx, dy),
          2 + sin(angle * 2) * 1,
          Paint()..color = Colors.white.withOpacity(0.6 - clearProgress * 0.6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
