import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_glass.dart';
import 'package:chumian_ai/services/api_service.dart';

/// ============================================================
/// AgentCreatePage —— 创建Agent页
/// 名称/描述/系统提示词/开场白/头像 + MiuixInput多行 + 创建按钮
/// ============================================================
class AgentCreatePage extends StatefulWidget {
  const AgentCreatePage({super.key});

  @override
  State<AgentCreatePage> createState() => _AgentCreatePageState();
}

class _AgentCreatePageState extends State<AgentCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _promptController = TextEditingController();
  final _openingController = TextEditingController();
  String _selectedCategory = '通用';
  bool _isCreating = false;

  static const List<String> _categories = ['通用', '文学', '编程', '教育', '生活', '职场', '健康', '娱乐'];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _promptController.dispose();
    _openingController.dispose();
    super.dispose();
  }

  Future<void> _createAgent() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isCreating = true);
    try {
      await ApiService.createAgent(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        systemPrompt: _promptController.text.trim(),
        openingMessage: _openingController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Agent创建成功！'), backgroundColor: MiuixColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('创建失败：$e'), backgroundColor: MiuixColors.error, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius)));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: AppBar(backgroundColor: MiuixColors.surface, elevation: 0, scrolledUnderElevation: 0, centerTitle: true, leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: MiuixColors.primary), onPressed: () => Navigator.pop(context)), title: Text('创建Agent', style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.xl, fontWeight: FontWeight.w600))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildAvatarSection(),
        const SizedBox(height: 20),
        _buildSectionTitle('基本信息'),
        const SizedBox(height: 12),
        _buildInputField(controller: _nameController, icon: Icons.badge, label: 'Agent名称', hint: '给你的Agent起个名字', maxLines: 1, validator: (v) => v?.trim().isEmpty ?? true ? '请输入Agent名称' : null),
        const SizedBox(height: 14),
        _buildInputField(controller: _descController, icon: Icons.description_outlined, label: 'Agent描述', hint: '简单描述这个Agent的功能和特点', maxLines: 2, validator: (v) => v?.trim().isEmpty ?? true ? '请输入Agent描述' : null),
        const SizedBox(height: 14),
        _buildCategorySelector(),
        const SizedBox(height: 24),
        _buildSectionTitle('高级设置'),
        const SizedBox(height: 12),
        _buildInputField(controller: _promptController, icon: Icons.psychology, label: '系统提示词', hint: '定义Agent的角色、能力和行为方式，越详细效果越好', maxLines: 8, validator: (v) => v?.trim().isEmpty ?? true ? '请输入系统提示词' : null),
        const SizedBox(height: 14),
        _buildInputField(controller: _openingController, icon: Icons.chat_bubble_outline, label: '开场白', hint: '用户开始对话时Agent说的第一句话', maxLines: 3, validator: null),
        const SizedBox(height: 32),
        _buildCreateButton(),
        const SizedBox(height: 20),
      ]))),
    );
  }

  Widget _buildAvatarSection() {
    return Center(child: Column(children: [
      Stack(children: [
        Container(width: 88, height: 88, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: MiuixColors.primaryGradient), border: Border.all(color: Colors.white, width: 3), boxShadow: MiuixShadows.md), child: const Center(child: Icon(Icons.smart_toy, color: Colors.white, size: 40))),
        Positioned(bottom: 0, right: 0, child: GestureDetector(onTap: () {}, child: Container(width: 30, height: 30, decoration: BoxDecoration(color: MiuixColors.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.camera_alt, color: Colors.white, size: 14)))),
      ]),
      const SizedBox(height: 8),
      Text('点击更换头像', style: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.sm)),
    ]));
  }

  Widget _buildSectionTitle(String title) {
    return Row(children: [Container(width: 4, height: 18, decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.pillRadius)), const SizedBox(width: 8), Text(title, style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.bold))]);
  }

  Widget _buildInputField({required TextEditingController controller, required IconData icon, required String label, required String hint, required int maxLines, String? Function(String?)? validator}) {
    return MiuixGlassContainer(borderRadius: MiuixRadius.md, padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: MiuixColors.primary, size: 18), const SizedBox(width: 6), Text(label, style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600))]),
      const SizedBox(height: 10),
      TextFormField(controller: controller, maxLines: maxLines, validator: validator, style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.md), decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: MiuixColors.textTertiary, fontSize: MiuixFontSize.sm), filled: true, fillColor: MiuixColors.surfaceVariant.withOpacity(0.5), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), border: OutlineInputBorder(borderRadius: MiuixRadius.smRadius, borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: MiuixRadius.smRadius, borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: MiuixRadius.smRadius, borderSide: BorderSide(color: MiuixColors.primary, width: 1.5)))),
    ]));
  }

  Widget _buildCategorySelector() {
    return MiuixGlassContainer(borderRadius: MiuixRadius.md, padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.category_outlined, color: MiuixColors.primary, size: 18), const SizedBox(width: 6), Text('分类', style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600))]),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: _categories.map((cat) => GestureDetector(onTap: () => setState(() => _selectedCategory = cat), child: AnimatedContainer(duration: MiuixDuration.fast, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: _selectedCategory == cat ? MiuixColors.primary : MiuixColors.surfaceVariant, borderRadius: MiuixRadius.pillRadius, border: _selectedCategory == cat ? null : Border.all(color: MiuixColors.border, width: 1)), child: Text(cat, style: TextStyle(color: _selectedCategory == cat ? Colors.white : MiuixColors.textSecondary, fontSize: MiuixFontSize.sm, fontWeight: _selectedCategory == cat ? FontWeight.w600 : FontWeight.w400))))).toList()),
    ]));
  }

  Widget _buildCreateButton() {
    return MiuixRipple(borderRadius: MiuixRadius.pill, child: GestureDetector(onTap: _isCreating ? null : _createAgent, child: AnimatedContainer(duration: MiuixDuration.fast, width: double.infinity, height: 54, decoration: BoxDecoration(gradient: const LinearGradient(colors: MiuixColors.primaryGradient), borderRadius: MiuixRadius.pillRadius, boxShadow: _isCreating ? null : MiuixShadows.lg), child: Center(child: _isCreating ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.auto_awesome, color: Colors.white, size: 22), SizedBox(width: 8), Text('创建Agent', style: TextStyle(color: Colors.white, fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600))])))));
  }
}
