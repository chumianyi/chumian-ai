import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_glass.dart';
import 'package:chumian_ai/services/api_service.dart';

/// ============================================================
/// ModelPickerPage —— 模型选择底部表
/// 模型列表(名称+类型图标+描述+是否选中) + 分组(文本/图像/视频/思考) + 选中动画
/// ============================================================
class ModelPickerPage extends StatefulWidget {
  const ModelPickerPage({super.key, required this.currentModel, required this.onSelected});

  final String currentModel;
  final Function(String modelId, String modelName) onSelected;

  @override
  State<ModelPickerPage> createState() => _ModelPickerPageState();
}

class _ModelPickerPageState extends State<ModelPickerPage> {
  String _selectedModel = '';
  bool _isLoading = true;
  String? _errorMessage;
  final List<ModelGroup> _groups = [];

  @override
  void initState() {
    super.initState();
    _selectedModel = widget.currentModel;
    _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await ApiService.getModels();
      final groups = _parseModelGroups(data);
      setState(() {
        _groups.clear();
        _groups.addAll(groups);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 灵活解析后端模型列表响应，支持多种返回格式：
  ///   1. {"groups": [{"name": "...", "models": [...]}]}
  ///   2. {"models": [{...type...}]}  —— 按 type 字段自动分组
  ///   3. {"文本对话": [...], "图像生成": [...]}  —— 键即分组名
  List<ModelGroup> _parseModelGroups(Map<String, dynamic> data) {
    final groups = <ModelGroup>[];

    // 格式1：显式 groups
    if (data['groups'] is List) {
      for (final g in (data['groups'] as List)) {
        if (g is! Map) continue;
        final name = g['name']?.toString() ?? '未分组';
        final icon = _iconFromString(g['icon']?.toString());
        final models = (g['models'] as List? ?? [])
            .map((m) => _modelFromMap(m as Map<String, dynamic>))
            .toList();
        if (models.isNotEmpty) {
          groups.add(ModelGroup(name: name, icon: icon, models: models));
        }
      }
      if (groups.isNotEmpty) return groups;
    }

    // 格式2：扁平 models 列表，按 type 分组
    if (data['models'] is List) {
      final byType = <String, List<ModelItem>>{};
      for (final m in (data['models'] as List)) {
        if (m is! Map) continue;
        final item = _modelFromMap(Map<String, dynamic>.from(m));
        byType.putIfAbsent(item.type, () => []).add(item);
      }
      byType.forEach((type, models) {
        groups.add(ModelGroup(
          name: _typeLabel(type),
          icon: _getTypeIcon(type),
          models: models,
        ));
      });
      if (groups.isNotEmpty) return groups;
    }

    // 格式3：键即分组名
    for (final entry in data.entries) {
      if (entry.value is List) {
        final models = (entry.value as List)
            .whereType<Map>()
            .map((m) => _modelFromMap(Map<String, dynamic>.from(m)))
            .toList();
        if (models.isNotEmpty) {
          groups.add(ModelGroup(
            name: entry.key,
            icon: Icons.extension,
            models: models,
          ));
        }
      }
    }
    return groups;
  }

  ModelItem _modelFromMap(Map<String, dynamic> m) {
    return ModelItem(
      id: m['id']?.toString() ?? m['model']?.toString() ?? '',
      name: m['name']?.toString() ?? m['id']?.toString() ?? '未知模型',
      description: m['description']?.toString() ?? '',
      type: m['type']?.toString() ?? 'text',
      isFree: m['is_free'] == true || m['free'] == true,
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'text': return '文本对话';
      case 'image': return '图像生成';
      case 'video': return '视频生成';
      case 'thinking': return '深度思考';
      default: return type;
    }
  }

  IconData _iconFromString(String? icon) {
    switch (icon) {
      case 'chat': return Icons.chat;
      case 'image': return Icons.image;
      case 'video': return Icons.videocam;
      case 'thinking': return Icons.psychology;
      default: return Icons.extension;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'text': return Icons.chat_bubble_outline;
      case 'image': return Icons.image_outlined;
      case 'video': return Icons.videocam_outlined;
      case 'thinking': return Icons.psychology_outlined;
      default: return Icons.extension;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'text': return MiuixColors.primary;
      case 'image': return Colors.purple;
      case 'video': return MiuixColors.error;
      case 'thinking': return Colors.indigo;
      default: return MiuixColors.textTertiary;
    }
  }

  void _selectModel(ModelItem model) {
    HapticFeedback.lightImpact();
    setState(() => _selectedModel = model.id);
    Future.delayed(const Duration(milliseconds: 300), () {
      widget.onSelected(model.id, model.name);
      Navigator.pop(context);
    });
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: MiuixColors.error),
          const SizedBox(height: 12),
          const Text('加载失败', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: 4),
          Text(_errorMessage ?? '未知错误', style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _loadModels,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 72, height: 72, decoration: BoxDecoration(color: MiuixColors.surfaceVariant, shape: BoxShape.circle), child: const Icon(Icons.memory, size: 32, color: MiuixColors.textTertiary)),
          const SizedBox(height: 12),
          const Text('暂无可用模型', style: TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textSecondary)),
          const SizedBox(height: 4),
          const Text('请稍后再试', style: TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: MiuixColors.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(MiuixRadius.xxl))),
      child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: MiuixColors.border, borderRadius: MiuixRadius.pillRadius)),
        const SizedBox(height: 16),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.smRadius), child: const Icon(Icons.memory, color: Colors.white, size: 20)),
          const SizedBox(width: 10),
          const Text('选择模型', style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.xl, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(icon: Icon(Icons.close, color: MiuixColors.textTertiary), onPressed: () => Navigator.pop(context)),
        ])),
        const SizedBox(height: 8),
        _isLoading
            ? const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: MiuixColors.primary))
            : _errorMessage != null
                ? _buildErrorState()
                : _groups.isEmpty
                    ? _buildEmptyState()
                    : Expanded(child: ListView.builder(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), shrinkWrap: true, itemCount: _groups.length, itemBuilder: (context, gIndex) {
                final group = _groups[gIndex];
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [Icon(group.icon, color: MiuixColors.primary, size: 18), const SizedBox(width: 6), Text(group.name, style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600))])),
                  ...group.models.asMap().entries.map((entry) {
                    final model = entry.value;
                    final isSelected = _selectedModel == model.id;
                    return MiuixRipple(borderRadius: MiuixRadius.lg, child: GestureDetector(onTap: () => _selectModel(model), child: AnimatedContainer(duration: MiuixDuration.fast, margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: isSelected ? MiuixColors.primary.withValues(alpha: 0.08) : MiuixColors.surfaceVariant.withValues(alpha: 0.5), borderRadius: MiuixRadius.lgRadius, border: Border.all(color: isSelected ? MiuixColors.primary : MiuixColors.borderLight, width: isSelected ? 1.5 : 0.5)), child: Row(children: [
                      Container(width: 40, height: 40, decoration: BoxDecoration(color: _getTypeColor(model.type).withValues(alpha: 0.12), borderRadius: MiuixRadius.smRadius), child: Center(child: Icon(_getTypeIcon(model.type), color: _getTypeColor(model.type), size: 20))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [Text(model.name, style: TextStyle(color: isSelected ? MiuixColors.primary : MiuixColors.textPrimary, fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600)), const SizedBox(width: 6), if (model.isFree) Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: MiuixColors.success.withValues(alpha: 0.1), borderRadius: MiuixRadius.xsRadius), child: const Text('免费', style: TextStyle(color: MiuixColors.success, fontSize: 9, fontWeight: FontWeight.w500)))]),
                        const SizedBox(height: 2),
                        Text(model.description, style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.xs), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ])),
                      AnimatedScale(scale: isSelected ? 1.0 : 0.0, duration: MiuixDuration.fast, child: Container(width: 24, height: 24, decoration: const BoxDecoration(color: MiuixColors.primary, shape: BoxShape.circle), child: const Center(child: Icon(Icons.check, color: Colors.white, size: 16)))),
                    ]))));
                  }),
                ]);
              })),
      ])),
    );
  }
}

class ModelGroup {
  const ModelGroup({required this.name, required this.icon, required this.models});
  final String name;
  final IconData icon;
  final List<ModelItem> models;
}

class ModelItem {
  const ModelItem({required this.id, required this.name, required this.description, required this.type, required this.isFree});
  final String id;
  final String name;
  final String description;
  final String type;
  final bool isFree;
}
