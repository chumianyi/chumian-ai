import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_switch.dart';
import 'package:chumian_ai/widgets/miuix/miuix_slider.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// ChatSettingsPage —— 聊天设置
/// 默认模型，字体大小，消息气泡样式，Enter发送
/// 自动播放语音，消息预览，MiuixSwitch，粉色主题
/// ============================================================

enum BubbleStyle { standard, compact, bubble, minimal }

class ChatSettingsPage extends StatefulWidget {
  const ChatSettingsPage({super.key});

  @override
  State<ChatSettingsPage> createState() => _ChatSettingsPageState();
}

class _ChatSettingsPageState extends State<ChatSettingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  // 设置状态
  String _defaultModel = 'glm-4-flash';
  double _fontSize = 14.0;
  BubbleStyle _bubbleStyle = BubbleStyle.standard;
  bool _enterToSend = true;
  bool _autoPlayVoice = false;
  bool _showMessagePreview = true;
  bool _showThinking = true;
  bool _webSearchDefault = false;
  bool _streamOutput = true;
  double _bubbleRadius = 20.0;
  bool _showTimestamp = false;
  bool _markdownRender = true;

  static const List<Map<String, dynamic>> _modelOptions = [
    {'name': 'glm-4-flash', 'desc': '快速响应，日常对话', 'icon': Icons.bolt},
    {'name': 'glm-4-plus', 'desc': '深度推理，复杂任务', 'icon': Icons.psychology},
    {'name': 'glm-4v', 'desc': '多模态，图文理解', 'icon': Icons.visibility},
    {'name': 'code-gecko', 'desc': '代码专用，编程辅助', 'icon': Icons.code},
  ];

  static const List<Map<String, dynamic>> _bubbleStyles = [
    {'style': BubbleStyle.standard, 'label': '标准', 'icon': Icons.chat_bubble},
    {'style': BubbleStyle.compact, 'label': '紧凑', 'icon': Icons.view_agenda},
    {'style': BubbleStyle.bubble, 'label': '气泡', 'icon': Icons.message},
    {'style': BubbleStyle.minimal, 'label': '极简', 'icon': Icons.remove},
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
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: const MiuixAppBar(title: '聊天设置'),
      body: ListView(
        padding: const EdgeInsets.all(MiuixSpacing.md),
        children: [
          _buildModelSection(),
          const SizedBox(height: MiuixSpacing.lg),
          _buildDisplaySection(),
          const SizedBox(height: MiuixSpacing.lg),
          _buildBehaviorSection(),
          const SizedBox(height: MiuixSpacing.lg),
          _buildAdvancedSection(),
          const SizedBox(height: MiuixSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MiuixSpacing.md, left: MiuixSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: MiuixColors.primary),
          const SizedBox(width: MiuixSpacing.sm),
          Text(
            title,
            style: const TextStyle(fontSize: MiuixFontSize.lg, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildModelSection() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.4, curve: MiuixCurves.easeOut)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('默认模型', Icons.auto_awesome),
          MiuixCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: _modelOptions.asMap().entries.map((entry) {
                final model = entry.value;
                final isSelected = _defaultModel == model['name'];
                return Column(
                  children: [
                    if (entry.key > 0) Container(height: 1, color: MiuixColors.divider, margin: const EdgeInsets.symmetric(horizontal: MiuixSpacing.md)),
                    MiuixRipple(
                      onTap: () => setState(() => _defaultModel = model['name'] as String),
                      borderRadius: MiuixRadius.md,
                      child: Padding(
                        padding: const EdgeInsets.all(MiuixSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: (isSelected ? MiuixColors.primary : MiuixColors.textTertiary).withOpacity(0.1),
                                borderRadius: MiuixRadius.smRadius,
                              ),
                              child: Icon(model['icon'] as IconData, size: 18, color: isSelected ? MiuixColors.primary : MiuixColors.textTertiary),
                            ),
                            const SizedBox(width: MiuixSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(model['name'] as String, style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: isSelected ? MiuixColors.primary : MiuixColors.textPrimary)),
                                  Text(model['desc'] as String, style: const TextStyle(fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary)),
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
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplaySection() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryController, curve: const Interval(0.1, 0.5, curve: MiuixCurves.easeOut)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('显示设置', Icons.visibility_outlined),
          MiuixCard(
            child: Column(
              children: [
                _buildFontSizeRow(),
                _buildDivider(),
                _buildBubbleStyleRow(),
                _buildDivider(),
                _buildBubbleRadiusRow(),
                _buildDivider(),
                _buildSwitchRow(
                  icon: Icons.access_time,
                  title: '显示时间戳',
                  subtitle: '在消息旁显示发送时间',
                  value: _showTimestamp,
                  onChanged: (v) => setState(() => _showTimestamp = v),
                ),
                _buildDivider(),
                _buildSwitchRow(
                  icon: Icons.code,
                  title: 'Markdown渲染',
                  subtitle: '渲染Markdown格式和代码高亮',
                  value: _markdownRender,
                  onChanged: (v) => setState(() => _markdownRender = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MiuixSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.text_fields, size: 20, color: MiuixColors.textTertiary),
              const SizedBox(width: MiuixSpacing.md),
              const Expanded(child: Text('字体大小', style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w500, color: MiuixColors.textPrimary))),
              Text('${_fontSize.toInt()}px', style: const TextStyle(fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w600, color: MiuixColors.primary)),
            ],
          ),
          const SizedBox(height: MiuixSpacing.sm),
          Slider(
            value: _fontSize,
            min: 12,
            max: 20,
            divisions: 8,
            activeColor: MiuixColors.primary,
            inactiveColor: MiuixColors.surfaceVariant,
            label: '${_fontSize.toInt()}px',
            onChanged: (v) => setState(() => _fontSize = v),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MiuixSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('小', style: TextStyle(fontSize: 12, color: _fontSize <= 13 ? MiuixColors.primary : MiuixColors.textTertiary)),
                Text('标准', style: TextStyle(fontSize: 14, color: _fontSize >= 14 && _fontSize <= 16 ? MiuixColors.primary : MiuixColors.textTertiary)),
                Text('大', style: TextStyle(fontSize: 16, color: _fontSize >= 17 ? MiuixColors.primary : MiuixColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleStyleRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MiuixSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline, size: 20, color: MiuixColors.textTertiary),
              const SizedBox(width: MiuixSpacing.md),
              const Expanded(child: Text('气泡样式', style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w500, color: MiuixColors.textPrimary))),
            ],
          ),
          const SizedBox(height: MiuixSpacing.sm),
          Row(
            children: _bubbleStyles.map((style) {
              final isSelected = _bubbleStyle == style['style'];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: style == _bubbleStyles.last ? 0 : MiuixSpacing.xs),
                  child: MiuixRipple(
                    onTap: () => setState(() => _bubbleStyle = style['style'] as BubbleStyle),
                    borderRadius: MiuixRadius.md,
                    child: AnimatedContainer(
                      duration: MiuixDuration.fast,
                      padding: const EdgeInsets.symmetric(vertical: MiuixSpacing.sm),
                      decoration: BoxDecoration(
                        color: isSelected ? MiuixColors.primary.withOpacity(0.08) : MiuixColors.surfaceVariant,
                        borderRadius: MiuixRadius.mdRadius,
                        border: Border.all(color: isSelected ? MiuixColors.primary : Colors.transparent, width: 1),
                      ),
                      child: Column(
                        children: [
                          Icon(style['icon'] as IconData, size: 18, color: isSelected ? MiuixColors.primary : MiuixColors.textTertiary),
                          const SizedBox(height: 2),
                          Text(style['label'] as String, style: TextStyle(fontSize: MiuixFontSize.xs, color: isSelected ? MiuixColors.primary : MiuixColors.textTertiary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleRadiusRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MiuixSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.circle_outlined, size: 20, color: MiuixColors.textTertiary),
              const SizedBox(width: MiuixSpacing.md),
              const Expanded(child: Text('气泡圆角', style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w500, color: MiuixColors.textPrimary))),
              Text('${_bubbleRadius.toInt()}', style: const TextStyle(fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w600, color: MiuixColors.primary)),
            ],
          ),
          Slider(
            value: _bubbleRadius,
            min: 8,
            max: 32,
            divisions: 12,
            activeColor: MiuixColors.primary,
            inactiveColor: MiuixColors.surfaceVariant,
            onChanged: (v) => setState(() => _bubbleRadius = v),
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorSection() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryController, curve: const Interval(0.2, 0.6, curve: MiuixCurves.easeOut)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('行为设置', Icons.tune),
          MiuixCard(
            child: Column(
              children: [
                _buildSwitchRow(
                  icon: Icons.keyboard_return,
                  title: 'Enter发送消息',
                  subtitle: '关闭后Enter换行，Ctrl+Enter发送',
                  value: _enterToSend,
                  onChanged: (v) => setState(() => _enterToSend = v),
                ),
                _buildDivider(),
                _buildSwitchRow(
                  icon: Icons.volume_up,
                  title: '自动播放语音',
                  subtitle: '收到语音消息时自动播放',
                  value: _autoPlayVoice,
                  onChanged: (v) => setState(() => _autoPlayVoice = v),
                ),
                _buildDivider(),
                _buildSwitchRow(
                  icon: Icons.preview,
                  title: '消息预览',
                  subtitle: '在通知中显示消息内容预览',
                  value: _showMessagePreview,
                  onChanged: (v) => setState(() => _showMessagePreview = v),
                ),
                _buildDivider(),
                _buildSwitchRow(
                  icon: Icons.psychology_outlined,
                  title: '显示思考过程',
                  subtitle: '展示AI的推理思考过程',
                  value: _showThinking,
                  onChanged: (v) => setState(() => _showThinking = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryController, curve: const Interval(0.3, 0.7, curve: MiuixCurves.easeOut)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('高级设置', Icons.settings_suggest_outlined),
          MiuixCard(
            child: Column(
              children: [
                _buildSwitchRow(
                  icon: Icons.public,
                  title: '默认开启联网搜索',
                  subtitle: '每次新对话自动开启联网搜索',
                  value: _webSearchDefault,
                  onChanged: (v) => setState(() => _webSearchDefault = v),
                ),
                _buildDivider(),
                _buildSwitchRow(
                  icon: Icons.stream,
                  title: '流式输出',
                  subtitle: '逐字显示AI回复，关闭后等待完整回复',
                  value: _streamOutput,
                  onChanged: (v) => setState(() => _streamOutput = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: MiuixSpacing.lg),
          MiuixButton(
            label: '恢复默认设置',
            type: MiuixButtonType.secondary,
            icon: Icons.restore,
            onPressed: () {
              setState(() {
                _defaultModel = 'glm-4-flash';
                _fontSize = 14.0;
                _bubbleStyle = BubbleStyle.standard;
                _enterToSend = true;
                _autoPlayVoice = false;
                _showMessagePreview = true;
                _showThinking = true;
                _webSearchDefault = false;
                _streamOutput = true;
                _bubbleRadius = 20.0;
                _showTimestamp = false;
                _markdownRender = true;
              });
            },
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
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
          MiuixSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: MiuixColors.divider, margin: const EdgeInsets.symmetric(horizontal: MiuixSpacing.md));
  }
}
