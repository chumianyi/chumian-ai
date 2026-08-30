import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CustomModel {
  final String id;
  String name;
  String baseUrl;
  String apiKey;
  String modelId;

  CustomModel({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.modelId,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'baseUrl': baseUrl, 'apiKey': apiKey, 'modelId': modelId,
  };

  factory CustomModel.fromJson(Map<String, dynamic> j) => CustomModel(
    id: j['id'], name: j['name'], baseUrl: j['baseUrl'],
    apiKey: j['apiKey'], modelId: j['modelId'],
  );
}

class CustomModelsPage extends StatefulWidget {
  const CustomModelsPage({super.key});

  @override
  State<CustomModelsPage> createState() => _CustomModelsPageState();
}

class _CustomModelsPageState extends State<CustomModelsPage> {
  List<CustomModel> _models = [];
  static const String _prefsKey = 'custom_models';

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefsKey);
    if (data != null) {
      final List<dynamic> list = jsonDecode(data);
      setState(() => _models = list.map((e) => CustomModel.fromJson(e)).toList());
    }
  }

  Future<void> _saveModels() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_models.map((e) => e.toJson()).toList()));
  }

  void _showAddEditDialog({CustomModel? model}) {
    final nameCtrl = TextEditingController(text: model?.name ?? '');
    final urlCtrl = TextEditingController(text: model?.baseUrl ?? 'https://open.bigmodel.cn/api/paas/v4');
    final keyCtrl = TextEditingController(text: model?.apiKey ?? '');
    final modelIdCtrl = TextEditingController(text: model?.modelId ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(model == null ? '添加自定义模型' : '编辑模型'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '显示名称', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'API 地址 (base_url)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: keyCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'API Key', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: modelIdCtrl, decoration: const InputDecoration(labelText: '模型 ID', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              if (model == null)
                TextButton.icon(
                  onPressed: () async {
                    // 获取模型列表（简化：直接填充常用模型）
                    if (urlCtrl.text.isNotEmpty && keyCtrl.text.isNotEmpty) {
                      modelIdCtrl.text = 'glm-4-flash';
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('已填充默认模型ID')));
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('获取模型列表'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || urlCtrl.text.trim().isEmpty || modelIdCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('请填写名称、地址和模型ID')));
                return;
              }
              if (model == null) {
                _models.add(CustomModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text.trim(),
                  baseUrl: urlCtrl.text.trim(),
                  apiKey: keyCtrl.text.trim(),
                  modelId: modelIdCtrl.text.trim(),
                ));
              } else {
                model.name = nameCtrl.text.trim();
                model.baseUrl = urlCtrl.text.trim();
                model.apiKey = keyCtrl.text.trim();
                model.modelId = modelIdCtrl.text.trim();
              }
              await _saveModels();
              setState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('模型管理'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddEditDialog()),
        ],
      ),
      body: _models.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.extension_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('暂无自定义模型', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('自定义模型不计积分，本地存储', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _models.length,
              itemBuilder: (_, i) {
                final model = _models[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.memory, color: Colors.teal),
                    ),
                    title: Text(model.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(model.modelId, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(model.baseUrl, style: const TextStyle(fontSize: 11, color: Colors.grey, overflow: TextOverflow.ellipsis), maxLines: 1),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('删除模型'), content: Text('确定删除「${model.name}」？'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除'))]));
                        if (ok == true) {
                          setState(() => _models.removeAt(i));
                          await _saveModels();
                        }
                      },
                    ),
                    onTap: () => _showAddEditDialog(model: model),
                  ),
                );
              },
            ),
    );
  }
}
