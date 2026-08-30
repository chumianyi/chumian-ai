import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Skill {
  final String id;
  String name;
  String description;
  String triggerKeyword;
  String action;
  bool enabled;
  IconData icon;

  Skill({
    required this.id,
    required this.name,
    required this.description,
    required this.triggerKeyword,
    required this.action,
    this.enabled = true,
    this.icon = Icons.extension,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'description': description,
    'triggerKeyword': triggerKeyword, 'action': action, 'enabled': enabled,
  };

  factory Skill.fromJson(Map<String, dynamic> j) => Skill(
    id: j['id'], name: j['name'], description: j['description'],
    triggerKeyword: j['triggerKeyword'] ?? '', action: j['action'] ?? '',
    enabled: j['enabled'] ?? true,
  );
}

class SkillsPage extends StatefulWidget {
  const SkillsPage({super.key});

  @override
  State<SkillsPage> createState() => _SkillsPageState();
}

class _SkillsPageState extends State<SkillsPage> {
  List<Skill> _skills = [];
  static const String _prefsKey = 'custom_skills';

  final List<Skill> _presetSkills = [
    Skill(id: 'preset_translate', name: '翻译技能', description: '自动翻译多语言文本', triggerKeyword: '翻译', action: '调用翻译API', icon: Icons.translate),
    Skill(id: 'preset_code', name: '代码审查', description: '审查代码质量和潜在问题', triggerKeyword: '审查代码', action: '调用代码分析', icon: Icons.code),
    Skill(id: 'preset_weather', name: '天气查询', description: '查询实时天气信息', triggerKeyword: '天气', action: '调用天气API', icon: Icons.wb_sunny),
    Skill(id: 'preset_search', name: '联网搜索', description: '搜索互联网获取最新信息', triggerKeyword: '搜索', action: '调用搜索引擎', icon: Icons.search),
    Skill(id: 'preset_image', name: '图片生成', description: '根据描述生成图片', triggerKeyword: '生成图片', action: '调用CogView', icon: Icons.image),
  ];

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefsKey);
    List<Skill> custom = [];
    if (data != null) {
      final List<dynamic> list = jsonDecode(data);
      custom = list.map((e) => Skill.fromJson(e)).toList();
    }
    setState(() => _skills = [..._presetSkills, ...custom]);
  }

  Future<void> _saveCustomSkills() async {
    final custom = _skills.where((s) => !s.id.startsWith('preset_')).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(custom.map((e) => e.toJson()).toList()));
  }

  void _showAddEditDialog({Skill? skill}) {
    final nameCtrl = TextEditingController(text: skill?.name ?? '');
    final descCtrl = TextEditingController(text: skill?.description ?? '');
    final keywordCtrl = TextEditingController(text: skill?.triggerKeyword ?? '');
    final actionCtrl = TextEditingController(text: skill?.action ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(skill == null ? '添加技能' : '编辑技能'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '技能名称', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: '技能描述', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: keywordCtrl, decoration: const InputDecoration(labelText: '触发关键词', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: actionCtrl, decoration: const InputDecoration(labelText: '执行动作', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              if (skill == null) {
                final newSkill = Skill(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  triggerKeyword: keywordCtrl.text.trim(),
                  action: actionCtrl.text.trim(),
                );
                _skills.add(newSkill);
              } else {
                skill.name = nameCtrl.text.trim();
                skill.description = descCtrl.text.trim();
                skill.triggerKeyword = keywordCtrl.text.trim();
                skill.action = actionCtrl.text.trim();
              }
              await _saveCustomSkills();
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
        title: const Text('技能·连接器'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddEditDialog()),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _skills.length,
        itemBuilder: (_, i) {
          final skill = _skills[i];
          final isPreset = skill.id.startsWith('preset_');
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(skill.icon, color: Colors.purple),
              ),
              title: Row(
                children: [
                  Text(skill.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (isPreset) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                      child: const Text('预置', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ),
                  ],
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(skill.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (skill.triggerKeyword.isNotEmpty) Text('触发: ${skill.triggerKeyword}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              trailing: Switch(
                value: skill.enabled,
                onChanged: (v) async {
                  setState(() => skill.enabled = v);
                  await _saveCustomSkills();
                },
              ),
              onTap: isPreset ? null : () => _showAddEditDialog(skill: skill),
              onLongPress: isPreset ? null : () async {
                final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('删除技能'), content: Text('确定删除「${skill.name}」？'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除'))]));
                if (ok == true) {
                  setState(() => _skills.removeWhere((s) => s.id == skill.id));
                  await _saveCustomSkills();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
