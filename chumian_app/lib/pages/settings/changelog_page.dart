import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_chip.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// ChangelogPage —— 更新日志
/// 版本列表，每个版本的新功能/修复/改进
/// 时间线展示，粉色主题，错落入场动画
/// ============================================================

enum ChangeType { feature, fix, improvement, performance, ui }

class ChangeItem {
  final ChangeType type;
  final String description;

  const ChangeItem({required this.type, required this.description});
}

class VersionInfo {
  final String version;
  final String date;
  final bool isLatest;
  final List<ChangeItem> changes;

  const VersionInfo({
    required this.version,
    required this.date,
    this.isLatest = false,
    required this.changes,
  });
}

class ChangelogPage extends StatefulWidget {
  const ChangelogPage({super.key});

  @override
  State<ChangelogPage> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  static const List<VersionInfo> _versions = [
    VersionInfo(
      version: '3.2.0',
      date: '2026-09-01',
      isLatest: true,
      changes: [
        ChangeItem(type: ChangeType.feature, description: '新增语音消息播放功能，支持波形图可视化'),
        ChangeItem(type: ChangeType.feature, description: '新增文件消息支持，可发送PDF/Word/Excel等'),
        ChangeItem(type: ChangeType.ui, description: '全新Miuix设计语言，毛玻璃效果升级'),
        ChangeItem(type: ChangeType.improvement, description: '优化流式输出性能，响应速度提升30%'),
        ChangeItem(type: ChangeType.fix, description: '修复部分机型输入框聚焦异常问题'),
      ],
    ),
    VersionInfo(
      version: '3.1.2',
      date: '2026-08-15',
      changes: [
        ChangeItem(type: ChangeType.feature, description: '新增快捷回复功能，AI回复后可一键继续追问'),
        ChangeItem(type: ChangeType.improvement, description: '优化联网搜索来源展示，新增摘要预览'),
        ChangeItem(type: ChangeType.performance, description: '优化大图加载，内存占用降低20%'),
        ChangeItem(type: ChangeType.fix, description: '修复深色模式下部分文字颜色异常'),
      ],
    ),
    VersionInfo(
      version: '3.1.0',
      date: '2026-08-01',
      changes: [
        ChangeItem(type: ChangeType.feature, description: '新增社区功能，支持发帖、评论、转发'),
        ChangeItem(type: ChangeType.feature, description: '新增话题广场，热门话题实时更新'),
        ChangeItem(type: ChangeType.ui, description: '个人主页全新改版，数据展示更清晰'),
        ChangeItem(type: ChangeType.improvement, description: '优化消息气泡，支持代码块高亮'),
        ChangeItem(type: ChangeType.fix, description: '修复长消息滚动卡顿问题'),
      ],
    ),
    VersionInfo(
      version: '3.0.0',
      date: '2026-07-15',
      changes: [
        ChangeItem(type: ChangeType.feature, description: '初眠AI 3.0重大版本更新'),
        ChangeItem(type: ChangeType.feature, description: '全新Miuix设计语言，连续曲率圆角'),
        ChangeItem(type: ChangeType.feature, description: '新增AI绘画功能，支持多种风格'),
        ChangeItem(type: ChangeType.feature, description: '新增Agent市场，可创建和分享专属AI'),
        ChangeItem(type: ChangeType.performance, description: '全面性能优化，启动速度提升50%'),
        ChangeItem(type: ChangeType.ui, description: '粉色系主题全面升级，更柔和的视觉体验'),
      ],
    ),
    VersionInfo(
      version: '2.8.5',
      date: '2026-06-20',
      changes: [
        ChangeItem(type: ChangeType.improvement, description: '优化模型切换体验，新增模型对比说明'),
        ChangeItem(type: ChangeType.fix, description: '修复网络异常时消息丢失问题'),
        ChangeItem(type: ChangeType.fix, description: '修复部分用户登录态异常'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  (IconData, Color, String) _getTypeInfo(ChangeType type) {
    switch (type) {
      case ChangeType.feature:
        return (Icons.new_releases, MiuixColors.primary, '新功能');
      case ChangeType.fix:
        return (Icons.bug_report, MiuixColors.error, '修复');
      case ChangeType.improvement:
        return (Icons.trending_up, MiuixColors.success, '改进');
      case ChangeType.performance:
        return (Icons.speed, MiuixColors.info, '性能');
      case ChangeType.ui:
        return (Icons.palette, MiuixColors.warning, '界面');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '更新日志',
        actions: [
          MiuixIconButton(
            icon: Icons.download_outlined,
            style: MiuixIconButtonStyle.ghost,
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(MiuixSpacing.md),
        itemCount: _versions.length,
        itemBuilder: (context, index) => _buildVersionSection(_versions[index], index),
      ),
    );
  }

  Widget _buildVersionSection(VersionInfo version, int index) {
    final anim = CurvedAnimation(
      parent: _entryController,
      curve: Interval(
        0.1 + index * 0.08,
        1.0,
        curve: MiuixCurves.easeOut,
      ),
    );

    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(anim),
        child: Padding(
          padding: const EdgeInsets.only(bottom: MiuixSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimeline(version.isLatest, index == _versions.length - 1),
              const SizedBox(width: MiuixSpacing.md),
              Expanded(child: _buildVersionCard(version)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(bool isLatest, bool isLast) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: isLatest
                ? const LinearGradient(colors: MiuixColors.primaryGradient)
                : null,
            color: isLatest ? null : MiuixColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: isLatest ? Colors.transparent : MiuixColors.border,
              width: 2,
            ),
            boxShadow: isLatest
                ? [
                    BoxShadow(
                      color: MiuixColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            isLatest ? Icons.star : Icons.circle,
            size: isLatest ? 16 : 8,
            color: isLatest ? Colors.white : MiuixColors.textTertiary,
          ),
        ),
        if (!isLast)
          Container(
            width: 2,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MiuixColors.primary.withOpacity(0.3),
                  MiuixColors.border,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVersionCard(VersionInfo version) {
    return MiuixCard(
      padding: const EdgeInsets.all(MiuixSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'v${version.version}',
                style: const TextStyle(
                  fontSize: MiuixFontSize.xl,
                  fontWeight: FontWeight.w700,
                  color: MiuixColors.textPrimary,
                ),
              ),
              const SizedBox(width: MiuixSpacing.sm),
              if (version.isLatest)
                MiuixChip(
                  label: '最新版本',
                  isSelected: true,
                  height: 24,
                ),
              const Spacer(),
              Text(
                version.date,
                style: const TextStyle(
                  fontSize: MiuixFontSize.sm,
                  color: MiuixColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: MiuixSpacing.md),
          Container(
            height: 1,
            color: MiuixColors.divider,
          ),
          const SizedBox(height: MiuixSpacing.md),
          ...version.changes.asMap().entries.map((entry) {
            return _buildChangeItem(entry.value, entry.key);
          }),
        ],
      ),
    );
  }

  Widget _buildChangeItem(ChangeItem change, int index) {
    final (icon, color, label) = _getTypeInfo(change.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: MiuixSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: MiuixRadius.xsRadius,
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: MiuixSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: MiuixFontSize.xs,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  change.description,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.sm,
                    color: MiuixColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
