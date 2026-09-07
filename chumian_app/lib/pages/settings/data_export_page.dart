import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_chip.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_progress.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// DataExportPage —— 数据导出
/// 导出聊天记录/个人数据，格式选择，导出进度，下载链接
/// 粉色主题，错落入场动画
/// ============================================================

enum ExportFormat { json, markdown, txt, csv }
enum ExportDataType { chat, profile, all }

class DataExportPage extends StatefulWidget {
  const DataExportPage({super.key});

  @override
  State<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends State<DataExportPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  ExportFormat _selectedFormat = ExportFormat.markdown;
  ExportDataType _selectedType = ExportDataType.all;
  bool _includeMedia = true;
  bool _includeSearch = false;
  bool _isExporting = false;
  double _exportProgress = 0.0;
  String? _downloadUrl;
  String? _exportFileName;
  Timer? _progressTimer;

  static const List<Map<String, dynamic>> _formatOptions = [
    {'format': ExportFormat.json, 'label': 'JSON', 'desc': '结构化数据，适合程序处理', 'icon': Icons.data_object},
    {'format': ExportFormat.markdown, 'label': 'Markdown', 'desc': '保留格式，适合阅读分享', 'icon': Icons.edit_note},
    {'format': ExportFormat.txt, 'label': 'TXT', 'desc': '纯文本，兼容性最好', 'icon': Icons.text_snippet},
    {'format': ExportFormat.csv, 'label': 'CSV', 'desc': '表格格式，适合Excel', 'icon': Icons.table_chart},
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
    _progressTimer?.cancel();
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _startExport() async {
    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
      _downloadUrl = null;
    });

    _progressTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) return;
      setState(() {
        _exportProgress += 0.03 + (0.02 * (1 - _exportProgress));
        if (_exportProgress >= 1.0) {
          _exportProgress = 1.0;
          _isExporting = false;
          timer.cancel();
          final typeName = _selectedType == ExportDataType.chat
              ? '聊天记录'
              : _selectedType == ExportDataType.profile
                  ? '个人数据'
                  : '全部数据';
          _exportFileName = '初眠AI_${typeName}_${DateTime.now().millisecondsSinceEpoch}.${_selectedFormat.name}';
          _downloadUrl = 'https://export.chumian.ai/download/$_exportFileName';
        }
      });
    });
  }

  void _resetExport() {
    setState(() {
      _isExporting = false;
      _exportProgress = 0.0;
      _downloadUrl = null;
      _exportFileName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: const MiuixAppBar(title: '数据导出'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBanner(),
            const SizedBox(height: MiuixSpacing.lg),
            _buildDataTypeSelector(),
            const SizedBox(height: MiuixSpacing.lg),
            _buildFormatSelector(),
            const SizedBox(height: MiuixSpacing.lg),
            _buildOptions(),
            const SizedBox(height: MiuixSpacing.lg),
            if (_isExporting || _downloadUrl != null) _buildExportProgress(),
            const SizedBox(height: MiuixSpacing.xl),
            _buildActionButton(),
            const SizedBox(height: MiuixSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return FadeTransition(
      opacity: _entryController,
      child: Container(
        padding: const EdgeInsets.all(MiuixSpacing.md),
        decoration: BoxDecoration(
          color: MiuixColors.info.withOpacity(0.08),
          borderRadius: MiuixRadius.lgRadius,
          border: Border.all(color: MiuixColors.info.withOpacity(0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 20, color: MiuixColors.info),
            SizedBox(width: MiuixSpacing.sm),
            Expanded(
              child: Text(
                '您的数据仅保存在您的账户中，导出文件将在24小时后自动删除。请妥善保管下载链接。',
                style: TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textSecondary, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTypeSelector() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.1, 0.5, curve: MiuixCurves.easeOut),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '导出内容',
            style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary),
          ),
          const SizedBox(height: MiuixSpacing.md),
          Row(
            children: [
              Expanded(child: _buildTypeCard(ExportDataType.chat, Icons.chat_bubble_outline, '聊天记录', '所有对话消息')),
              const SizedBox(width: MiuixSpacing.sm),
              Expanded(child: _buildTypeCard(ExportDataType.profile, Icons.person_outline, '个人数据', '资料/收藏/设置')),
              const SizedBox(width: MiuixSpacing.sm),
              Expanded(child: _buildTypeCard(ExportDataType.all, Icons.all_inclusive, '全部数据', '包含以上所有')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(ExportDataType type, IconData icon, String title, String desc) {
    final isSelected = _selectedType == type;
    return MiuixRipple(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: MiuixRadius.lg,
      child: AnimatedContainer(
        duration: MiuixDuration.fast,
        padding: const EdgeInsets.all(MiuixSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? MiuixColors.primary.withOpacity(0.06) : MiuixColors.surface,
          borderRadius: MiuixRadius.lgRadius,
          border: Border.all(
            color: isSelected ? MiuixColors.primary : MiuixColors.borderLight,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: isSelected ? MiuixColors.primary : MiuixColors.textTertiary),
            const SizedBox(height: MiuixSpacing.sm),
            Text(
              title,
              style: TextStyle(
                fontSize: MiuixFontSize.sm,
                fontWeight: FontWeight.w600,
                color: isSelected ? MiuixColors.primary : MiuixColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: const TextStyle(fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatSelector() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 0.6, curve: MiuixCurves.easeOut),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '导出格式',
            style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary),
          ),
          const SizedBox(height: MiuixSpacing.md),
          ..._formatOptions.asMap().entries.map((entry) {
            final option = entry.value;
            final isSelected = _selectedFormat == option['format'];
            return Padding(
              padding: const EdgeInsets.only(bottom: MiuixSpacing.sm),
              child: MiuixRipple(
                onTap: () => setState(() => _selectedFormat = option['format'] as ExportFormat),
                borderRadius: MiuixRadius.lg,
                child: AnimatedContainer(
                  duration: MiuixDuration.fast,
                  padding: const EdgeInsets.all(MiuixSpacing.md),
                  decoration: BoxDecoration(
                    color: isSelected ? MiuixColors.primary.withOpacity(0.04) : MiuixColors.surface,
                    borderRadius: MiuixRadius.lgRadius,
                    border: Border.all(
                      color: isSelected ? MiuixColors.primary : MiuixColors.borderLight,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: (isSelected ? MiuixColors.primary : MiuixColors.textTertiary).withOpacity(0.1),
                          borderRadius: MiuixRadius.smRadius,
                        ),
                        child: Icon(option['icon'] as IconData, size: 18, color: isSelected ? MiuixColors.primary : MiuixColors.textTertiary),
                      ),
                      const SizedBox(width: MiuixSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option['label'] as String,
                              style: TextStyle(
                                fontSize: MiuixFontSize.md,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? MiuixColors.primary : MiuixColors.textPrimary,
                              ),
                            ),
                            Text(
                              option['desc'] as String,
                              style: const TextStyle(fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: MiuixDuration.fast,
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: isSelected ? MiuixColors.primary : Colors.transparent,
                          border: Border.all(color: isSelected ? MiuixColors.primary : MiuixColors.border, width: 1.5),
                          shape: BoxShape.circle,
                        ),
                        child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.3, 0.7, curve: MiuixCurves.easeOut),
      ),
      child: MiuixCard(
        child: Column(
          children: [
            _buildOptionRow(
              icon: Icons.image_outlined,
              title: '包含媒体文件',
              subtitle: '导出聊天中的图片和视频',
              value: _includeMedia,
              onChanged: (v) => setState(() => _includeMedia = v),
            ),
            Container(height: 1, color: MiuixColors.divider, margin: const EdgeInsets.symmetric(horizontal: MiuixSpacing.md)),
            _buildOptionRow(
              icon: Icons.search,
              title: '包含搜索记录',
              subtitle: '导出联网搜索历史和来源',
              value: _includeSearch,
              onChanged: (v) => setState(() => _includeSearch = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MiuixSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: MiuixColors.textTertiary),
          const SizedBox(width: MiuixSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w500, color: MiuixColors.textPrimary)),
                Text(subtitle, style: const TextStyle(fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: MiuixColors.primary,
            activeTrackColor: MiuixColors.primary.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildExportProgress() {
    return FadeTransition(
      opacity: _entryController,
      child: MiuixCard(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: MiuixColors.primary.withOpacity(0.1),
                    borderRadius: MiuixRadius.mdRadius,
                  ),
                  child: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(MiuixColors.primary)),
                        )
                      : const Icon(Icons.check_circle, size: 24, color: MiuixColors.success),
                ),
                const SizedBox(width: MiuixSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isExporting ? '正在导出数据...' : '导出完成',
                        style: const TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary),
                      ),
                      Text(
                        _isExporting ? '请稍候，正在打包您的数据' : _exportFileName ?? '',
                        style: const TextStyle(fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(_exportProgress * 100).toInt()}%',
                  style: const TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w700, color: MiuixColors.primary),
                ),
              ],
            ),
            const SizedBox(height: MiuixSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _exportProgress,
                minHeight: 6,
                backgroundColor: MiuixColors.surfaceVariant,
                valueColor: const AlwaysStoppedAnimation<Color>(MiuixColors.primary),
              ),
            ),
            if (_downloadUrl != null) ...[
              const SizedBox(height: MiuixSpacing.md),
              MiuixButton(
                label: '下载文件',
                type: MiuixButtonType.primary,
                icon: Icons.download,
                onPressed: () {},
                width: double.infinity,
              ),
              const SizedBox(height: MiuixSpacing.sm),
              MiuixButton(
                label: '重新导出',
                type: MiuixButtonType.secondary,
                icon: Icons.refresh,
                onPressed: _resetExport,
                width: double.infinity,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isExporting) return const SizedBox.shrink();
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.4, 0.8, curve: MiuixCurves.easeOut),
      ),
      child: MiuixButton(
        label: _downloadUrl != null ? '重新导出' : '开始导出',
        type: MiuixButtonType.primary,
        icon: _downloadUrl != null ? Icons.refresh : Icons.file_download_outlined,
        onPressed: _startExport,
        width: double.infinity,
        height: 50,
      ),
    );
  }
}
