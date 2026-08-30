import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../widgets/context_ext.dart';
import '../services/api_service.dart';
import '../widgets/context_ext.dart';

class AgentPage extends StatefulWidget {
  const AgentPage({super.key});

  @override
  State<AgentPage> createState() => _AgentPageState();
}

class _AgentPageState extends State<AgentPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _chatCtrl = TextEditingController();
  final List<Map<String, dynamic>> _chatMessages = [];
  final List<Map<String, dynamic>> _actionLogs = [];
  bool _isExecuting = false;
  bool _accessibilityEnabled = false;
  bool _highRiskConfirm = true;
  String? _screenshotPath;
  List<FileSystemEntity> _files = [];
  String? _agentStatus;
  String? _applyReason;
  String? _reviewResult;
  bool _loadingStatus = true;
  bool _submitting = false;
  final TextEditingController _applyCtrl = TextEditingController();
  static const _agentChannel = MethodChannel('com.chumian.chumian_ai/agent');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadFiles();
    _checkAccessibility();
    _loadAgentStatus();
    _chatMessages.add({
      'role': 'assistant',
      'content': '你好！我是本地AGENT助手。我可以帮你：\n\n• 写代码并保存到工作目录\n• 读取屏幕内容并分析\n• 模拟点击、滑动、输入操作\n• 自动化完成手机操作任务\n\n请告诉我你想做什么？',
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAccessibility() async {
    try {
      final result = await _agentChannel.invokeMethod('isAccessibilityEnabled');
      setState(() => _accessibilityEnabled = result == true);
    } catch (_) {}
  }

  Future<void> _openAccessibilitySettings() async {
    try {
      await _agentChannel.invokeMethod('openAccessibilitySettings');
    } catch (_) {}
  }

  Future<void> _loadAgentStatus() async {
    try {
      final data = await ApiService.agentApplyStatus();
      setState(() {
        _agentStatus = data['status'];
        _applyReason = data['reason'];
        _reviewResult = data['review_result'];
        _loadingStatus = false;
      });
    } catch (_) {
      setState(() => _loadingStatus = false);
    }
  }

  Future<void> _submitApplication() async {
    final reason = _applyCtrl.text.trim();
    if (reason.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('申请理由至少10个字')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ApiService.agentApply(reason);
      setState(() {
        _agentStatus = 'pending';
        _applyReason = reason;
      });
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

  Future<void> _takeScreenshot() async {
    try {
      final path = await _agentChannel.invokeMethod('takeScreenshot');
      if (path != null) {
        setState(() => _screenshotPath = path);
        _addLog('截图', '屏幕截图已保存');
      }
    } catch (e) {
      _addLog('截图失败', e.toString());
    }
  }

  Future<void> _loadFiles() async {
    try {
      final dir = Directory('/storage/emulated/0/ChumianAI/agent');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final files = dir.listSync();
      setState(() => _files = files);
    } catch (_) {
      try {
        final dir = Directory('${Directory.systemTemp.path}/agent_workspace');
        if (!await dir.exists()) await dir.create(recursive: true);
        setState(() => _files = dir.listSync());
      } catch (_) {}
    }
  }

  Future<void> _sendMessage() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty || _isExecuting) return;
    _chatCtrl.clear();
    setState(() {
      _chatMessages.add({'role': 'user', 'content': text});
      _isExecuting = true;
    });

    // 判断是否需要写代码
    final isCodeTask = RegExp(r'写.*代码|创建.*文件|写个.*(脚本|程序|函数|类)', caseSensitive: false).hasMatch(text);

    if (isCodeTask) {
      // 调用AI写代码
      try {
        final completer = Completer<String>();
        String fullContent = '';
        final sub = ApiService.chatStream(
          message: text,
          model: 'glm-4-flash',
          webSearch: false,
        ).listen((data) {
          if (data['type'] == 'content') {
            fullContent += data['content'] ?? '';
          } else if (data['type'] == 'done') {
            completer.complete(fullContent);
          }
        });
        final aiReply = await completer.future.timeout(const Duration(seconds: 60));
        sub.cancel();

        // 提取代码块并保存
        final codeMatch = RegExp(r'```(\w+)?\n(.*?)```', dotAll: true).firstMatch(aiReply);
        String? savedFile;
        if (codeMatch != null) {
          final lang = codeMatch.group(1) ?? 'txt';
          final code = codeMatch.group(2) ?? '';
          final ext = {'python': 'py', 'dart': 'dart', 'javascript': 'js', 'java': 'java', 'shell': 'sh', 'bash': 'sh'};
          final fileName = 'agent_code_${DateTime.now().millisecondsSinceEpoch}.${ext[lang] ?? lang}';
          try {
            final dir = Directory('/storage/emulated/0/ChumianAI/agent');
            if (!await dir.exists()) await dir.create(recursive: true);
            final file = File('${dir.path}/$fileName');
            await file.writeAsString(code);
            savedFile = fileName;
            _addLog('写代码', '已保存文件: $fileName');
            _loadFiles();
          } catch (e) {
            _addLog('保存失败', e.toString());
          }
        }

        setState(() {
          _chatMessages.add({
            'role': 'assistant',
            'content': aiReply + (savedFile != null ? '\n\n📁 代码已保存到工作目录: $savedFile' : ''),
          });
          _isExecuting = false;
        });
      } catch (e) {
        setState(() {
          _chatMessages.add({'role': 'assistant', 'content': '出错了: $e'});
          _isExecuting = false;
        });
      }
    } else {
      // 屏幕操控任务：截图 -> 视觉分析 -> 执行操作
      await _executeScreenTask(text);
    }
  }

  Future<void> _executeScreenTask(String task) async {
    if (!_accessibilityEnabled) {
      setState(() {
        _chatMessages.add({
          'role': 'assistant',
          'content': '⚠️ 请先开启无障碍服务权限，才能使用屏幕操控功能。\n\n点击右上角设置按钮开启。',
        });
        _isExecuting = false;
      });
      return;
    }

    try {
      // 1. 截图
      _addLog('任务开始', task);
      await _takeScreenshot();
      await Future.delayed(const Duration(seconds: 1));

      // 2. 读取控件树
      String nodeTree = '';
      try {
        nodeTree = await _agentChannel.invokeMethod('getNodeTree') ?? '';
      } catch (_) {}

      // 3. 调用视觉模型分析（用GLM-4V，这里用文本模型模拟决策）
      final decision = await _getAIDecision(task, nodeTree);

      // 4. 执行操作
      if (decision['action'] == 'click') {
        final text = decision['target'] ?? '';
        try {
          final result = await _agentChannel.invokeMethod('clickByText', {'text': text});
          _addLog('点击操作', '点击: $text -> ${result ?? "成功"}');
        } catch (e) {
          _addLog('点击失败', e.toString());
        }
      } else if (decision['action'] == 'input') {
        final text = decision['text'] ?? '';
        try {
          await _agentChannel.invokeMethod('inputText', {'text': text});
          _addLog('输入操作', '输入: $text');
        } catch (e) {
          _addLog('输入失败', e.toString());
        }
      } else if (decision['action'] == 'back') {
        try {
          await _agentChannel.invokeMethod('performGlobalAction', {'action': 'back'});
          _addLog('返回操作', '已返回');
        } catch (e) {
          _addLog('返回失败', e.toString());
        }
      }

      await Future.delayed(const Duration(seconds: 1));
      await _takeScreenshot();

      setState(() {
        _chatMessages.add({
          'role': 'assistant',
          'content': '已执行操作: ${decision['action']}\n目标: ${decision['target'] ?? decision['text'] ?? ''}\n说明: ${decision['explanation'] ?? ''}',
        });
        _isExecuting = false;
      });
    } catch (e) {
      setState(() {
        _chatMessages.add({'role': 'assistant', 'content': '执行出错: $e'});
        _isExecuting = false;
      });
    }
  }

  Future<Map<String, String>> _getAIDecision(String task, String nodeTree) async {
    try {
      final prompt = '''
当前屏幕控件树:
$nodeTree

用户任务: $task

请分析当前屏幕，决定要执行的操作。只回复JSON格式:
{"action": "click/input/back/none", "target": "要点击的文字", "text": "要输入的文字", "explanation": "操作说明"}
''';
      final completer = Completer<String>();
      String full = '';
      final sub = ApiService.chatStream(
        message: prompt,
        model: 'glm-4-flash',
        webSearch: false,
      ).listen((data) {
        if (data['type'] == 'content') full += data['content'] ?? '';
        else if (data['type'] == 'done') completer.complete(full);
      });
      final result = await completer.future.timeout(const Duration(seconds: 30));
      sub.cancel();
      final jsonMatch = RegExp(r'\{[^{}]*\}').firstMatch(result);
      if (jsonMatch != null) {
        final parsed = Map<String, String>.from(
          (jsonDecode(jsonMatch.group(0)!) as Map).map((k, v) => MapEntry(k, v.toString())),
        );
        return parsed;
      }
    } catch (_) {}
    return {'action': 'none', 'explanation': '无法决策'};
  }

  void _addLog(String action, String detail) {
    setState(() {
      _actionLogs.insert(0, {
        'time': DateTime.now().toString().substring(11, 19),
        'action': action,
        'detail': detail,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingStatus) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_agentStatus != 'approved') {
      return _buildStatusPage();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('AGENT'),
        actions: [
          IconButton(
            icon: Icon(_accessibilityEnabled ? Icons.accessibility_new : Icons.accessibility_new_outlined,
                color: _accessibilityEnabled ? Colors.green : null),
            onPressed: _openAccessibilitySettings,
            tooltip: '无障碍服务',
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'high_risk') {
                setState(() => _highRiskConfirm = !_highRiskConfirm);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'high_risk', child: Row(children: [
                Icon(_highRiskConfirm ? Icons.check_box : Icons.check_box_outline_blank, size: 18),
                const SizedBox(width: 8),
                const Text('高危操作确认'),
              ])),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.chat_rounded), text: '对话'),
            Tab(icon: Icon(Icons.folder_rounded), text: '文件'),
            Tab(icon: Icon(Icons.screenshot_monitor_rounded), text: '屏幕'),
            Tab(icon: Icon(Icons.receipt_long_rounded), text: '日志'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildChatTab(), _buildFileTab(), _buildScreenTab(), _buildLogsTab()],
      ),
    );
  }

  Widget _buildStatusPage() {
    return Scaffold(
      appBar: AppBar(title: const Text('AGENT')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 24),
            if (_agentStatus == 'none' || _agentStatus == null) _buildApplyForm(),
            if (_agentStatus == 'pending') _buildPendingCard(),
            if (_agentStatus == 'rejected') _buildRejectedCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    IconData icon;
    String title;
    String subtitle;
    Color color;
    if (_agentStatus == 'pending') {
      icon = Icons.hourglass_empty_rounded;
      title = '审核中';
      subtitle = '您的申请正在审核中，预计3~4个工作日出结果';
      color = Colors.orange;
    } else if (_agentStatus == 'rejected') {
      icon = Icons.cancel_rounded;
      title = '申请未通过';
      subtitle = '您可以修改理由后重新申请';
      color = Colors.red;
    } else {
      icon = Icons.smart_toy_rounded;
      title = '本地AGENT功能';
      subtitle = '让AI操控你的手机，写代码、自动化操作、屏幕识别';
      color = Colors.purple;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.6)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 44),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
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
          controller: _applyCtrl,
          maxLines: 4,
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
            onPressed: _submitting ? null : _submitApplication,
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

  Widget _buildPendingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('审核中', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('预计3~4个工作日出结果，请耐心等待',
                style: TextStyle(color: context.textSecondary, fontSize: 14)),
            const SizedBox(height: 16),
            if (_applyReason != null)
              Text('申请理由: $_applyReason',
                  style: TextStyle(color: context.textTertiary, fontSize: 13)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loadAgentStatus,
              child: const Text('刷新状态'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedCard() {
    return Column(
      children: [
        Card(
          color: Colors.red.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.cancel_rounded, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                const Text('申请未通过', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 8),
                Text('拒绝原因: ${_reviewResult ?? "未提供"}', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('重新申请', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _applyCtrl,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: '请修改申请理由后重新提交（至少10字）',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submitApplication,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: _submitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('重新提交', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
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
          Text('• 需要开启无障碍服务权限，AGENT可读取屏幕内容并模拟点击操作', style: TextStyle(fontSize: 12)),
          Text('• 需要屏幕截图权限，用于AI视觉分析当前界面', style: TextStyle(fontSize: 12)),
          Text('• 高危操作（安装/卸载应用、删除文件、支付等）需要手动确认', style: TextStyle(fontSize: 12)),
          Text('• 请勿在涉及支付、隐私的场景下使用自动操控', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        if (!_accessibilityEnabled)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.orange.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                const Expanded(child: Text('无障碍服务未开启，屏幕操控功能不可用', style: TextStyle(fontSize: 12))),
                TextButton(onPressed: _openAccessibilitySettings, child: const Text('去开启')),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _chatMessages.length,
            itemBuilder: (_, i) {
              final msg = _chatMessages[i];
              final isUser = msg['role'] == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                  decoration: BoxDecoration(
                    color: isUser ? context.primary : context.surfaceSubtle,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(msg['content'] ?? '',
                      style: TextStyle(color: isUser ? Colors.white : context.textPrimary, fontSize: 14)),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatCtrl,
                  decoration: InputDecoration(
                    hintText: '输入任务，如"帮我写个Python脚本"或"打开微信"',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isExecuting ? null : _sendMessage,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(gradient: context.vibrantGradient, shape: BoxShape.circle),
                  child: _isExecuting
                      ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFileTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.folder_rounded, size: 20),
              const SizedBox(width: 8),
              const Text('工作目录', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadFiles),
            ],
          ),
        ),
        Expanded(
          child: _files.isEmpty
              ? const Center(child: Text('暂无文件，让AGENT写代码后会出现在这里'))
              : ListView.builder(
                  itemCount: _files.length,
                  itemBuilder: (_, i) {
                    final f = _files[i];
                    final name = f.path.split('/').last;
                    return ListTile(
                      leading: Icon(name.endsWith('.py') ? Icons.code : Icons.insert_drive_file_rounded),
                      title: Text(name),
                      subtitle: Text(f is File ? '${(f).lengthSync()} 字节' : '目录'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          if (_highRiskConfirm) {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(title: const Text('确认删除'), content: Text('确定删除 $name ?'), actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
                              ]),
                            );
                            if (ok != true) return;
                          }
                          await f.delete();
                          _addLog('删除文件', name);
                          _loadFiles();
                        },
                      ),
                      onTap: () async {
                        if (f is File) {
                          final content = await f.readAsString();
                          showDialog(context: context, builder: (_) => AlertDialog(title: Text(name), content: SizedBox(width: 300, height: 400, child: SingleChildScrollView(child: SelectableText(content))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))]));
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildScreenTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.screenshot_monitor, size: 20),
              const SizedBox(width: 8),
              const Text('屏幕预览', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(onPressed: _takeScreenshot, icon: const Icon(Icons.camera_alt), label: const Text('截图')),
            ],
          ),
        ),
        Expanded(
          child: _screenshotPath == null
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('点击"截图"按钮获取当前屏幕'),
                ]))
              : InteractiveViewer(
                  child: Image.file(File(_screenshotPath!), fit: BoxFit.contain),
                ),
        ),
      ],
    );
  }

  Widget _buildLogsTab() {
    return _actionLogs.isEmpty
        ? const Center(child: Text('暂无操作日志'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _actionLogs.length,
            itemBuilder: (_, i) {
              final log = _actionLogs[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: context.surfaceSubtle, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log['time'] ?? '', style: TextStyle(color: context.textTertiary, fontSize: 12, fontFamily: 'monospace')),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(log['action'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(log['detail'] ?? '', style: TextStyle(color: context.textSecondary, fontSize: 12)),
                    ])),
                  ],
                ),
              );
            },
          );
  }
}
