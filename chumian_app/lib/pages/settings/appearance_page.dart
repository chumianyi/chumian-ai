import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_switch.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_segment.dart';

/// ============================================================
/// AppearancePage —— 外观设置
/// 主题色选择(粉色系多色)，深色模式开关，字体大小调节
/// 动画强度，粉色预览
/// ============================================================
class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  int _selectedColor = 0;
  bool _darkMode = false;
  double _fontSize = 14;
  int _animationLevel = 1; // 0: 关闭, 1: 标准, 2: 增强
  bool _amoledBlack = false;

  static const List<ColorTheme> _themes = [
    ColorTheme(name: '初眠粉', primary: Color(0xFFFF6B9D), light: Color(0xFFFF8FB5)),
    ColorTheme(name: '樱花粉', primary: Color(0xFFFFB7C5), light: Color(0xFFFFD1DC)),
    ColorTheme(name: '玫瑰红', primary: Color(0xFFFF4081), light: Color(0xFFFF79A8)),
    ColorTheme(name: '桃粉色', primary: Color(0xFFFFA07A), light: Color(0xFFFFC4A3)),
    ColorTheme(name: '紫罗兰', primary: Color(0xFF9C27B0), light: Color(0xFFBA68C8)),
    ColorTheme(name: '天空蓝', primary: Color(0xFF03A9F4), light: Color(0xFF4FC3F7)),
  ];

  static const List<String> _fontSizes = ['小', '标准', '大', '特大'];
  static const List<double> _fontSizeValues = [12, 14, 16, 18];
  static const List<String> _animLevels = ['关闭', '标准', '增强'];

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

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.07, (index * 0.07) + 0.4,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.07, (index * 0.07) + 0.4,
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

  @override
  Widget build(BuildContext context) {
    final theme = _themes[_selectedColor];
    return Scaffold(
      backgroundColor: _darkMode ? MiuixColors.darkBackground : MiuixColors.background,
      appBar: MiuixAppBar(
        title: '外观设置',
        backgroundColor:
            _darkMode ? MiuixColors.darkBackground : MiuixColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            _buildAnimatedItem(_buildPreviewCard(theme), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildThemeSelector(theme), 1),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildDarkModeSection(theme), 2),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildFontSizeSection(theme), 3),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildAnimationSection(theme), 4),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(ColorTheme theme) {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [theme.light.withOpacity(0.3), theme.primary.withOpacity(0.2)],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility, color: theme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '实时预览',
                style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: _darkMode
                      ? MiuixColors.darkTextPrimary
                      : MiuixColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _darkMode
                  ? MiuixColors.darkSurface
                  : Colors.white.withOpacity(0.8),
              borderRadius: MiuixRadius.lgRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [theme.light, theme.primary]),
                    borderRadius: MiuixRadius.pillRadius,
                  ),
                  child: Text(
                    '主题色：${theme.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: MiuixFontSize.sm,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '这是预览文字，字号 ${_fontSize.toInt()}',
                  style: TextStyle(
                    fontSize: _fontSize,
                    color: _darkMode
                        ? MiuixColors.darkTextPrimary
                        : MiuixColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '深色模式：${_darkMode ? "开启" : "关闭"}，动画：${_animLevels[_animationLevel]}',
                  style: TextStyle(
                    fontSize: _fontSize - 2,
                    color: _darkMode
                        ? MiuixColors.darkTextSecondary
                        : MiuixColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [theme.light, theme.primary]),
                        borderRadius: MiuixRadius.pillRadius,
                      ),
                      child: const Center(
                        child: Text(
                          '按钮',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite,
                          color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(ColorTheme theme) {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette, color: theme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                '主题色',
                style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _themes.length,
            itemBuilder: (context, index) {
              final t = _themes[index];
              final isSelected = _selectedColor == index;
              return MiuixRipple(
                borderRadius: MiuixRadius.md,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedColor = index),
                  child: AnimatedContainer(
                    duration: MiuixDuration.fast,
                    curve: MiuixCurves.miuixSpring,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [t.light, t.primary]),
                      borderRadius: MiuixRadius.mdRadius,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected ? MiuixShadows.md : null,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            t.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: MiuixFontSize.sm,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Positioned(
                            top: 6,
                            right: 6,
                            child: Icon(Icons.check_circle,
                                color: Colors.white, size: 18),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDarkModeSection(ColorTheme theme) {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          _buildSwitchRow(
            icon: Icons.dark_mode,
            title: '深色模式',
            subtitle: '夜间使用更护眼',
            value: _darkMode,
            color: theme.primary,
            onChanged: (v) => setState(() => _darkMode = v),
          ),
          if (_darkMode) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 1,
                color: MiuixColors.divider,
              ),
            ),
            _buildSwitchRow(
              icon: Icons.brightness_2,
              title: '纯黑模式 (AMOLED)',
              subtitle: '使用纯黑色背景，更省电',
              value: _amoledBlack,
              color: theme.primary,
              onChanged: (v) => setState(() => _amoledBlack = v),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFontSizeSection(ColorTheme theme) {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.text_fields, color: theme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                '字体大小',
                style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${_fontSize.toInt()}sp',
                style: TextStyle(
                  color: theme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: theme.primary,
              inactiveTrackColor: MiuixColors.surfaceVariant,
              thumbColor: Colors.white,
              overlayColor: theme.light.withOpacity(0.3),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: _fontSize,
              min: 12,
              max: 20,
              divisions: 4,
              label: '${_fontSize.toInt()}sp',
              onChanged: (v) => setState(() => _fontSize = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_fontSizes.length, (index) {
              final isSelected =
                  (_fontSize - 12) ~/ 2 == index;
              return Text(
                _fontSizes[index],
                style: TextStyle(
                  fontSize: MiuixFontSize.xs,
                  color: isSelected
                      ? theme.primary
                      : MiuixColors.textTertiary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimationSection(ColorTheme theme) {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.animation, color: theme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                '动画强度',
                style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MiuixSegmentControl(
            items: List.generate(
              _animLevels.length,
              (index) => MiuixSegmentItem(label: _animLevels[index]),
            ),
            selectedIndex: _animationLevel,
            onChanged: (i) => setState(() => _animationLevel = i),
          ),
          const SizedBox(height: 12),
          Text(
            _animationLevel == 0
                ? '关闭所有过渡动画，操作更直接'
                : _animationLevel == 1
                    ? '标准动画效果，平衡流畅与性能'
                    : '增强动画效果，更丰富的视觉反馈',
            style: const TextStyle(
              fontSize: MiuixFontSize.sm,
              color: MiuixColors.textTertiary,
            ),
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
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: MiuixRadius.smRadius,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.md,
                    fontWeight: FontWeight.w500,
                    color: MiuixColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: MiuixFontSize.xs,
                    color: MiuixColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          MiuixSwitch(value: value, onChanged: onChanged, activeColor: color),
        ],
      ),
    );
  }
}

class ColorTheme {
  final String name;
  final Color primary;
  final Color light;
  const ColorTheme(
      {required this.name, required this.primary, required this.light});
}
