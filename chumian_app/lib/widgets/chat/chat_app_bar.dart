import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// ChatAppBar —— 聊天顶栏
/// 历史按钮，标题+模型名，模型切换按钮(右上角)
/// 新对话按钮，搜索消息按钮，更多操作，水晕反馈
/// 毛玻璃背景，粉色主题
/// ============================================================

class ChatAppBar extends StatefulWidget implements PreferredSizeWidget {
  const ChatAppBar({
    super.key,
    this.title = '初眠AI',
    this.subtitle,
    this.currentModel = 'glm-4-flash',
    this.onHistory,
    this.onNewChat,
    this.onSearch,
    this.onModelSwitch,
    this.onMore,
    this.showBackButton = false,
    this.onBack,
    this.height = 56.0,
  });

  /// 标题
  final String title;

  /// 副标题（会话名等）
  final String? subtitle;

  /// 当前模型名
  final String currentModel;

  /// 历史按钮回调
  final VoidCallback? onHistory;

  /// 新对话回调
  final VoidCallback? onNewChat;

  /// 搜索回调
  final VoidCallback? onSearch;

  /// 模型切换回调
  final VoidCallback? onModelSwitch;

  /// 更多操作回调
  final VoidCallback? onMore;

  /// 是否显示返回按钮
  final bool showBackButton;

  /// 返回回调
  final VoidCallback? onBack;

  /// 高度
  final double height;

  @override
  final Size preferredSize = const Size.fromHeight(56.0);

  @override
  State<ChatAppBar> createState() => _ChatAppBarState();
}

class _ChatAppBarState extends State<ChatAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _showModelMenu = false;

  static const List<Map<String, dynamic>> _modelOptions = [
    {'name': 'glm-4-flash', 'desc': '快速响应', 'icon': Icons.bolt},
    {'name': 'glm-4-plus', 'desc': '深度推理', 'icon': Icons.psychology},
    {'name': 'glm-4v', 'desc': '多模态', 'icon': Icons.visibility},
    {'name': 'code-gecko', 'desc': '代码专用', 'icon': Icons.code},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: widget.height + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: MiuixColors.surface.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(color: MiuixColors.borderLight, width: 1),
            ),
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  if (widget.showBackButton)
                    _buildBarButton(
                      icon: Icons.arrow_back_ios_new,
                      onTap: widget.onBack ?? () => Navigator.of(context).pop(),
                    )
                  else
                    _buildBarButton(
                      icon: Icons.history,
                      onTap: widget.onHistory,
                      tooltip: '历史对话',
                    ),
                  Expanded(child: _buildTitleSection()),
                  _buildModelSwitchButton(),
                  _buildBarButton(
                    icon: Icons.add_comment_outlined,
                    onTap: widget.onNewChat,
                    tooltip: '新对话',
                  ),
                  _buildBarButton(
                    icon: Icons.search,
                    onTap: widget.onSearch,
                    tooltip: '搜索消息',
                  ),
                  _buildBarButton(
                    icon: Icons.more_vert,
                    onTap: widget.onMore,
                    tooltip: '更多',
                  ),
                ],
              ),
              if (_showModelMenu) _buildModelMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return GestureDetector(
      onTap: () {},
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: MiuixColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: MiuixColors.primary
                              .withValues(alpha: 0.3 + _pulseController.value * 0.4),
                          blurRadius: 6 + _pulseController.value * 6,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: MiuixFontSize.lg,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
            ],
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              widget.subtitle!,
              style: const TextStyle(
                fontSize: MiuixFontSize.xs,
                color: MiuixColors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModelSwitchButton() {
    return MiuixRipple(
      onTap: () => setState(() => _showModelMenu = !_showModelMenu),
      borderRadius: MiuixRadius.pill,
      child: AnimatedContainer(
        duration: MiuixDuration.fast,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: _showModelMenu
              ? const LinearGradient(colors: MiuixColors.primaryGradient)
              : null,
          color: _showModelMenu ? null : MiuixColors.surfaceVariant,
          borderRadius: MiuixRadius.pillRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 14,
              color: _showModelMenu ? Colors.white : MiuixColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              widget.currentModel,
              style: TextStyle(
                fontSize: MiuixFontSize.xs,
                fontWeight: FontWeight.w600,
                color: _showModelMenu ? Colors.white : MiuixColors.textSecondary,
              ),
            ),
            Icon(
              Icons.expand_more,
              size: 14,
              color: _showModelMenu ? Colors.white : MiuixColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelMenu() {
    return Positioned(
      top: widget.height - 4,
      right: MiuixSpacing.md,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(MiuixSpacing.sm),
          decoration: BoxDecoration(
            color: MiuixColors.surface,
            borderRadius: MiuixRadius.lgRadius,
            border: Border.all(color: MiuixColors.border, width: 1),
            boxShadow: MiuixShadows.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MiuixSpacing.sm,
                  vertical: MiuixSpacing.xs,
                ),
                child: Text(
                  '选择模型',
                  style: TextStyle(
                    fontSize: MiuixFontSize.sm,
                    fontWeight: FontWeight.w600,
                    color: MiuixColors.textTertiary,
                  ),
                ),
              ),
              ..._modelOptions.map((model) {
                final isSelected = model['name'] == widget.currentModel;
                return MiuixRipple(
                  onTap: () {
                    widget.onModelSwitch?.call();
                    setState(() => _showModelMenu = false);
                  },
                  borderRadius: MiuixRadius.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MiuixSpacing.sm,
                      vertical: MiuixSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? MiuixColors.primary.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: MiuixRadius.mdRadius,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: MiuixColors.primaryGradient)
                                : null,
                            color: isSelected
                                ? null
                                : MiuixColors.surfaceVariant,
                            borderRadius: MiuixRadius.smRadius,
                          ),
                          child: Icon(
                            model['icon'] as IconData,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : MiuixColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: MiuixSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                model['name'] as String,
                                style: TextStyle(
                                  fontSize: MiuixFontSize.md,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? MiuixColors.primary
                                      : MiuixColors.textPrimary,
                                ),
                              ),
                              Text(
                                model['desc'] as String,
                                style: const TextStyle(
                                  fontSize: MiuixFontSize.xs,
                                  color: MiuixColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            size: 18,
                            color: MiuixColors.primary,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarButton({
    required IconData icon,
    required VoidCallback? onTap,
    String? tooltip,
  }) {
    return MiuixRipple(
      onTap: onTap,
      borderRadius: MiuixRadius.pill,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 22,
          color: MiuixColors.textSecondary,
        ),
      ),
    );
  }
}
