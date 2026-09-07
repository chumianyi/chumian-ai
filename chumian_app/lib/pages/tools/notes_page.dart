import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_input.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_dialog.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_empty_state.dart';

/// ============================================================
/// NotesPage —— 便签工具
/// 便签列表，粉色/黄色/蓝色便签卡片，新建/编辑/删除
/// 网格布局，本地存储
/// ============================================================
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  List<NoteItem> _notes = [];
  bool _isLoading = true;
  int _selectedColor = 0;

  static const List<Color> _noteColors = [
    Color(0xFFFFE4EC), // 粉
    Color(0xFFFFF9C4), // 黄
    Color(0xFFE3F2FD), // 蓝
    Color(0xFFE8F5E9), // 绿
    Color(0xFFF3E5F5), // 紫
  ];

  static const List<Color> _noteBorderColors = [
    Color(0xFFFFB6C1),
    Color(0xFFFFF59D),
    Color(0xFF90CAF9),
    Color(0xFFA5D6A7),
    Color(0xFFCE93D8),
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _entryController.forward();
    _loadNotes();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() {
      _notes = [
        NoteItem(
          id: '1',
          title: '购物清单',
          content: '牛奶、面包、鸡蛋、水果、蔬菜\n记得买洗衣液',
          colorIndex: 0,
          time: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        NoteItem(
          id: '2',
          title: '会议记录',
          content: '下周项目评审会议\n准备演示文稿\n确认参会人员',
          colorIndex: 2,
          time: DateTime.now().subtract(const Duration(days: 1)),
        ),
        NoteItem(
          id: '3',
          title: '灵感记录',
          content: '新功能想法：AI辅助写作\n可以加入模板功能',
          colorIndex: 1,
          time: DateTime.now().subtract(const Duration(days: 2)),
        ),
        NoteItem(
          id: '4',
          title: '学习计划',
          content: 'Flutter进阶学习\n1. 状态管理\n2. 动画\n3. 性能优化',
          colorIndex: 4,
          time: DateTime.now().subtract(const Duration(days: 3)),
        ),
        NoteItem(
          id: '5',
          title: '读书笔记',
          content: '《设计心理学》核心要点\n1. 可供性\n2. 意符\n3. 约束',
          colorIndex: 3,
          time: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];
      _isLoading = false;
    });
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.05, (index * 0.05) + 0.35,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.05, (index * 0.05) + 0.35,
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

  void _addNote() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    int colorIndex = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: MiuixColors.surface,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(MiuixRadius.xl)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MiuixColors.border,
                    borderRadius: MiuixRadius.pillRadius,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '新建便签',
                  style: TextStyle(
                    fontSize: MiuixFontSize.xl,
                    fontWeight: FontWeight.bold,
                    color: MiuixColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                MiuixInput(
                  controller: titleController,
                  hintText: '标题',
                  prefixIcon: Icons.title,
                ),
                const SizedBox(height: 12),
                MiuixInput(
                  controller: contentController,
                  hintText: '内容...',
                  type: MiuixInputType.multiline,
                  maxLines: 4,
                  minLines: 3,
                  prefixIcon: Icons.edit,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('颜色：',
                        style: TextStyle(color: MiuixColors.textSecondary)),
                    const SizedBox(width: 8),
                    ...List.generate(_noteColors.length, (index) {
                      return GestureDetector(
                        onTap: () => setSheetState(() => colorIndex = index),
                        child: Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: _noteColors[index],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorIndex == index
                                  ? MiuixColors.primary
                                  : _noteBorderColors[index],
                              width: colorIndex == index ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: MiuixButton(
                    label: '保存',
                    icon: Icons.save,
                    type: MiuixButtonType.gradient,
                    gradient:
                        const LinearGradient(colors: MiuixColors.primaryGradient),
                    onPressed: () {
                      if (titleController.text.trim().isEmpty &&
                          contentController.text.trim().isEmpty) {
                        MiuixToast.show(context,
                            message: '请输入内容', type: MiuixToastType.warning);
                        return;
                      }
                      setState(() {
                        _notes.insert(
                          0,
                          NoteItem(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            title: titleController.text.isEmpty
                                ? '无标题'
                                : titleController.text,
                            content: contentController.text,
                            colorIndex: colorIndex,
                            time: DateTime.now(),
                          ),
                        );
                      });
                      Navigator.pop(context);
                      MiuixToast.show(context,
                          message: '便签已保存', type: MiuixToastType.success);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteNote(NoteItem note) {
    MiuixDialog.show(
      context,
      title: '删除便签',
      content: '确定要删除「${note.title}」吗？',
      type: MiuixDialogType.warning,
      confirmText: '删除',
      onConfirm: () {
        setState(() => _notes.removeWhere((n) => n.id == note.id));
        MiuixToast.show(context,
            message: '便签已删除', type: MiuixToastType.success);
      },
    );
  }

  void _editNote(NoteItem note) {
    final titleController = TextEditingController(text: note.title);
    final contentController = TextEditingController(text: note.content);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: MiuixColors.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(MiuixRadius.xl)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MiuixColors.border,
                  borderRadius: MiuixRadius.pillRadius,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '编辑便签',
                style: TextStyle(
                  fontSize: MiuixFontSize.xl,
                  fontWeight: FontWeight.bold,
                  color: MiuixColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              MiuixInput(
                controller: titleController,
                hintText: '标题',
                prefixIcon: Icons.title,
              ),
              const SizedBox(height: 12),
              MiuixInput(
                controller: contentController,
                hintText: '内容...',
                type: MiuixInputType.multiline,
                maxLines: 4,
                minLines: 3,
                prefixIcon: Icons.edit,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: MiuixButton(
                      label: '取消',
                      type: MiuixButtonType.secondary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MiuixButton(
                      label: '保存',
                      type: MiuixButtonType.primary,
                      onPressed: () {
                        setState(() {
                          final index =
                              _notes.indexWhere((n) => n.id == note.id);
                          if (index != -1) {
                            _notes[index] = NoteItem(
                              id: note.id,
                              title: titleController.text,
                              content: contentController.text,
                              colorIndex: note.colorIndex,
                              time: DateTime.now(),
                            );
                          }
                        });
                        Navigator.pop(context);
                        MiuixToast.show(context,
                            message: '已更新', type: MiuixToastType.success);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '便签',
        backgroundColor: MiuixColors.background,
        actions: [
          MiuixIconButton(
            icon: Icons.add,
            style: MiuixIconButtonStyle.filled,
            onPressed: _addNote,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(MiuixColors.primary),
              ),
            )
          : _notes.isEmpty
              ? const MiuixEmptyState(
                  title: '暂无便签',
                  description: '点击右上角+号创建第一条便签',
                  icon: Icons.note_add,
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    return _buildAnimatedItem(
                      _buildNoteCard(_notes[index]),
                      index,
                    );
                  },
                ),
    );
  }

  Widget _buildNoteCard(NoteItem note) {
    return MiuixRipple(
      borderRadius: MiuixRadius.lg,
      child: GestureDetector(
        onTap: () => _editNote(note),
        onLongPress: () => _deleteNote(note),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _noteColors[note.colorIndex],
            borderRadius: MiuixRadius.lgRadius,
            border: Border.all(
              color: _noteBorderColors[note.colorIndex],
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _noteBorderColors[note.colorIndex].withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: MiuixFontSize.md,
                        fontWeight: FontWeight.bold,
                        color: MiuixColors.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _deleteNote(note),
                    child: const Icon(Icons.close,
                        size: 16, color: MiuixColors.textTertiary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  note.content,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.sm,
                    color: MiuixColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatTime(note.time),
                style: const TextStyle(
                  fontSize: MiuixFontSize.xs,
                  color: MiuixColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${time.month}月${time.day}日';
  }
}

class NoteItem {
  final String id;
  final String title;
  final String content;
  final int colorIndex;
  final DateTime time;
  const NoteItem({
    required this.id,
    required this.title,
    required this.content,
    required this.colorIndex,
    required this.time,
  });
}
