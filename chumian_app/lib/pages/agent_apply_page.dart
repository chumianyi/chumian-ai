import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/context_ext.dart';

class AgentApplyPage extends StatefulWidget {
  const AgentApplyPage({super.key});

  @override
  State<AgentApplyPage> createState() => _AgentApplyPageState();
}

class _AgentApplyPageState extends State<AgentApplyPage> {
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;
  String? _status;
  String? _reviewResult;
  String? _applyReason;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final data = await ApiService.agentApplyStatus();
      setState(() {
        _status = data['status'];
        _reviewResult = data['review_result'];
        _applyReason = data['reason'];
      });
    } catch (_) {}
  }

  Future<void> _submit() async {
    final reason = _reasonCtrl.text.trim();
    if (reason.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('申请理由至少10个字')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ApiService.agentApply(reason);
      setState(() => _status = 'pending');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('申请已提交，审核中（预计3-4个工作日）')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('本地AGENT申请')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            if (_status == 'pending') _buildPendingCard(),
            if (_status == 'approved') _buildApprovedCard(),
            if (_status == 'rejected') _buildRejectedCard(),
            if (_status == null || _status == 'none' || _status == 'rejected')
              _buildApplyForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: context.vibrantGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.smart_toy_rounded, color: Colors.white, size: 40),
          SizedBox(height: 12),
          Text('本地AGENT功能', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('让AI操控你的手机，写代码、自动化操作、屏幕识别',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPendingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            const Text('审核中', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('您的申请正在审核中，预计3-4个工作日出结果',
                style: TextStyle(color: context.textSecondary, fontSize: 14)),
            const SizedBox(height: 12),
            Text('申请理由: $_applyReason',
                style: TextStyle(color: context.textTertiary, fontSize: 13)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadStatus,
              child: const Text('刷新状态'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedCard() {
    return Card(
      color: Colors.green.withOpacity(0.1),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
            SizedBox(height: 12),
            Text('审核通过！', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            SizedBox(height: 8),
            Text('您已获得本地AGENT功能权限，返回主页即可看到AGENT导航栏',
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedCard() {
    return Card(
      color: Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.cancel_rounded, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text('审核未通过', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 8),
            Text('拒绝原因: $_reviewResult', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('申请理由', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _reasonCtrl,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: '请描述您使用本地AGENT的用途和场景（至少10字）',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 16),
        _buildRiskNotice(),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: _submitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('提交申请', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
            SizedBox(width: 6),
            Text('功能风险提示', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          ]),
          SizedBox(height: 8),
          Text('• 需要开启无障碍服务权限，AGENT可读取屏幕内容并模拟点击操作',
              style: TextStyle(fontSize: 12)),
          Text('• 需要屏幕截图权限，用于AI视觉分析当前界面', style: TextStyle(fontSize: 12)),
          Text('• 高危操作（安装/卸载应用、删除文件、支付等）需要手动确认', style: TextStyle(fontSize: 12)),
          Text('• 请勿在涉及支付、隐私的场景下使用自动操控', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
