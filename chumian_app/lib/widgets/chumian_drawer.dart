import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/svg_icons.dart';
import '../widgets/default_avatar.dart';
import '../pages/scheduled_tasks_page.dart';
import '../pages/skills_page.dart';
import '../pages/ai_create_page.dart';
import '../pages/camera_page.dart';
import '../pages/scan_page.dart';

/// 豆包风格侧边栏：纯白底、搜索框、功能列表、置顶/最近分区、底部交互栏
class ChumianDrawer extends StatefulWidget {
  final String? nickname;
  final String? avatar;
  final int currentPageIndex;
  final Function(int pageIndex) onNavigate;
  final Function(String convId, String title) onOpenConversation;
  final VoidCallback onClose;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenNotifications;

  const ChumianDrawer({
    super.key,
    this.nickname,
    this.avatar,
    required this.currentPageIndex,
    required this.onNavigate,
    required this.onOpenConversation,
    required this.onClose,
    required this.onOpenSettings,
    required this.onOpenNotifications,
  });

  @override
  State<ChumianDrawer> createState() => _ChumianDrawerState();
}

class _ChumianDrawerState extends State<ChumianDrawer> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<dynamic> _conversations = [];
  List<dynamic> _filteredConversations = [];
  bool _loading = true;
  final Set<String> _pinnedIds = {};
  static const List<Color> _convColors = [
    Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFF14B8A6),
    Color(0xFFF59E0B), Color(0xFF8B5CF6), Color(0xFFEF4444),
    Color(0xFF06B6D4), Color(0xFF84CC16),
  ];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      final convs = await ApiService.getConversations();
      setState(() {
        _conversations = convs;
        _filteredConversations = convs;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _filterConversations(String query) {
    if (query.isEmpty) {
      setState(() => _filteredConversations = _conversations);
    } else {
      setState(() {
        _filteredConversations = _conversations.where((c) {
          final title = (c['title'] ?? '').toString().toLowerCase();
          return title.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  Color _colorForConv(String id) {
    final hash = id.hashCode.abs();
    return _convColors[hash % _convColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final nickname = widget.nickname ?? '用户';
    return Container(
      width: 280,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            // ===== 顶部：搜索栏区域 =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          SvgIcons.search(size: 18, color: const Color(0xFF999999)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: _filterConversations,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                              decoration: const InputDecoration(
                                hintText: '搜索',
                                hintStyle: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              _filterConversations('');
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: SvgIcons.edit(size: 16, color: const Color(0xFF999999)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: SvgIcons.collapse(size: 20, color: const Color(0xFF666666)),
                    ),
                  ),
                ],
              ),
            ),

            // ===== 可滚动区域 =====
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),

                    // ===== 固定功能快捷入口（4项） =====
                    _buildFunctionItem(
                      icon: _buildAvatarMini(nickname),
                      label: nickname,
                      isAvatar: true,
                      onTap: () => widget.onNavigate(5),
                    ),
                    _buildFunctionItem(
                      icon: SvgIcons.clock(size: 22, color: const Color(0xFF555555)),
                      label: '定时任务',
                      onTap: () {
                        widget.onClose();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduledTasksPage()));
                      },
                    ),
                    _buildFunctionItem(
                      icon: SvgIcons.connector(size: 22, color: const Color(0xFF555555)),
                      label: '技能·连接器',
                      onTap: () {
                        widget.onClose();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SkillsPage()));
                      },
                    ),
                    _buildFunctionItem(
                      icon: SvgIcons.aiCreate(size: 22, color: const Color(0xFF555555)),
                      label: 'AI创作',
                      onTap: () {
                        widget.onClose();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AICreatePage()));
                      },
                    ),

                    // ===== 功能区和会话区分割线 =====
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 12),

                    // ===== 置顶分区 =====
                    _buildSectionHeader('置顶'),
                    if (_loading)
                      const Padding(padding: EdgeInsets.all(16), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
                    else if (_pinnedIds.isEmpty)
                      _buildEmptyHint('暂无置顶会话，长按会话可置顶')
                    else
                      ..._pinnedIds.map((id) {
                        final conv = _conversations.firstWhere(
                          (c) => c['id'] == id,
                          orElse: () => {'id': id, 'title': '会话'},
                        );
                        return _buildConversationItem(conv, showAlert: true);
                      }),

                    const SizedBox(height: 12),

                    // ===== 最近分区 =====
                    _buildSectionHeader('最近'),
                    if (_loading)
                      const SizedBox.shrink()
                    else if (_filteredConversations.isEmpty)
                      _buildEmptyHint('暂无会话')
                    else
                      ..._filteredConversations.take(10).map((conv) => _buildConversationItem(conv, showAlert: false)),
                  ],
                ),
              ),
            ),

            // ===== 底部交互栏（6项） =====
            Container(
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: () => widget.onNavigate(5),
                    child: _buildBottomAvatar(nickname),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nickname,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildBottomIcon(SvgIcons.qrScan(size: 20, color: const Color(0xFF666666)), '扫码', () {
                    widget.onClose();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanPage()));
                  }),
                  _buildBottomIcon(SvgIcons.bell(size: 20, color: const Color(0xFF666666)), '通知', widget.onOpenNotifications),
                  _buildBottomIcon(SvgIcons.settings(size: 20, color: const Color(0xFF666666)), '设置', widget.onOpenSettings),
                  _buildBottomIcon(SvgIcons.camera(size: 20, color: const Color(0xFF666666)), '拍照', () {
                    widget.onClose();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraPage()));
                  }),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunctionItem({required Widget icon, required String label, bool isAvatar = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            SizedBox(width: 24, height: 24, child: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: isAvatar ? const Color(0xFF111111) : const Color(0xFF333333),
                  fontWeight: isAvatar ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF999999), fontWeight: FontWeight.w500, letterSpacing: 0.5),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: SvgIcons.moreVert(size: 16, color: const Color(0xFFBBBBBB)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(dynamic conv, {required bool showAlert}) {
    final id = (conv['id'] ?? '').toString();
    final title = (conv['title'] ?? '新对话').toString();
    final color = _colorForConv(id);
    final isPinned = _pinnedIds.contains(id);

    return GestureDetector(
      onTap: () {
        widget.onOpenConversation(id, title);
        widget.onClose();
      },
      onLongPress: () {
        setState(() {
          if (isPinned) {
            _pinnedIds.remove(id);
          } else {
            _pinnedIds.add(id);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isPinned ? '已取消置顶' : '已置顶'), duration: const Duration(seconds: 1)),
        );
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // 信息图标（不再用首字）
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: SvgIcons.chatBubble(size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showAlert) ...[
              const SizedBox(width: 8),
              SvgIcons.alert(size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFFCCCCCC))),
    );
  }

  Widget _buildBottomIcon(Widget icon, String tooltip, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: icon,
      ),
    );
  }

  Widget _buildAvatarMini(String nickname) {
    if (widget.avatar != null && widget.avatar!.isNotEmpty) {
      return ClipOval(
        child: Image.network(widget.avatar!, width: 24, height: 24, fit: BoxFit.cover),
      );
    }
    return const DefaultAvatar(size: 24);
  }

  Widget _buildBottomAvatar(String nickname) {
    if (widget.avatar != null && widget.avatar!.isNotEmpty) {
      return ClipOval(
        child: Image.network(widget.avatar!, width: 32, height: 32, fit: BoxFit.cover),
      );
    }
    return const DefaultAvatar(size: 32);
  }
}
