import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_slider.dart';

/// ============================================================
/// MagnifierPage —— 放大镜
/// 模拟放大效果，缩放控制，滤镜(灰度/反色/暖色)
/// 粉色主题边框，自定义绘制
/// ============================================================
class MagnifierPage extends StatefulWidget {
  const MagnifierPage({super.key});

  @override
  State<MagnifierPage> createState() => _MagnifierPageState();
}

class _MagnifierPageState extends State<MagnifierPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;

  double _zoom = 2.0;
  int _filter = 0; // 0=正常, 1=灰度, 2=反色, 3=暖色
  Offset _lensPosition = const Offset(150, 150);
  bool _isDragging = false;

  static const List<String> _filterNames = ['正常', '灰度', '反色', '暖色'];
  static const List<IconData> _filterIcons = [
    Icons.filter_none,
    Icons.filter_b_and_w,
    Icons.invert_colors,
    Icons.thermostat,
  ];

  // 模拟的文字内容
  static const String _sampleText =
      '初眠AI 是一款基于先进人工智能技术的智能助手应用。'
      '它集成了自然语言处理、图像识别、语音合成等多种AI能力，'
      '为用户提供智能对话、内容创作、知识问答、翻译等全方位服务。'
      '初眠AI采用粉色系Miuix设计语言，界面优雅，交互流畅，'
      '致力于为用户带来温暖、贴心的AI体验。';

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
        curve: Interval(index * 0.06, (index * 0.06) + 0.4,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.06, (index * 0.06) + 0.4,
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
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(title: '放大镜'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: Column(
          children: [
            _buildAnimatedItem(_buildZoomControl(), 0),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildFilterSelector(), 1),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildMagnifierArea(), 2),
            const SizedBox(height: MiuixSpacing.lg),
            _buildAnimatedItem(_buildInfoCard(), 3),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomControl() {
    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('放大倍数',
                  style: TextStyle(fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
              Text('${_zoom.toStringAsFixed(1)}x',
                  style: const TextStyle(color: MiuixColors.primary, fontWeight: FontWeight.bold, fontSize: MiuixFontSize.lg)),
            ],
          ),
          const SizedBox(height: MiuixSpacing.sm),
          MiuixSlider(
            value: _zoom,
            min: 1.0,
            max: 5.0,
            divisions: 40,
            onChanged: (v) => setState(() => _zoom = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MiuixButton(
                label: '-',
                type: MiuixButtonType.secondary,
                width: 50,
                onPressed: () => setState(() => _zoom = max(1.0, _zoom - 0.5)),
              ),
              MiuixButton(
                label: '重置',
                type: MiuixButtonType.text,
                onPressed: () => setState(() => _zoom = 2.0),
              ),
              MiuixButton(
                label: '+',
                width: 50,
                onPressed: () => setState(() => _zoom = min(5.0, _zoom + 0.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSelector() {
    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('滤镜效果',
              style: TextStyle(fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
          const SizedBox(height: MiuixSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_filterNames.length, (i) {
              final selected = _filter == i;
              return GestureDetector(
                onTap: () => setState(() => _filter = i),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: selected ? MiuixColors.primary : MiuixColors.surfaceVariant,
                        borderRadius: MiuixRadius.mdRadius,
                        border: Border.all(
                          color: selected ? MiuixColors.primary : MiuixColors.borderLight,
                        ),
                      ),
                      child: Icon(_filterIcons[i],
                          color: selected ? Colors.white : MiuixColors.primary,
                          size: 22),
                    ),
                    const SizedBox(height: MiuixSpacing.xs),
                    Text(_filterNames[i],
                        style: TextStyle(
                            color: selected ? MiuixColors.primary : MiuixColors.textSecondary,
                            fontSize: MiuixFontSize.xs,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMagnifierArea() {
    return MiuixCard(
      padding: const EdgeInsets.all(MiuixSpacing.md),
      child: GestureDetector(
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanUpdate: (details) {
          setState(() {
            _lensPosition = Offset(
              (_lensPosition.dx + details.delta.dx).clamp(0.0, 300.0),
              (_lensPosition.dy + details.delta.dy).clamp(0.0, 300.0),
            );
          });
        },
        onPanEnd: (_) => setState(() => _isDragging = false),
        child: SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            children: [
              // 底层文字
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(MiuixSpacing.md),
                  child: _applyFilter(
                    Text(
                      _sampleText,
                      style: const TextStyle(
                          fontSize: 10,
                          color: MiuixColors.textPrimary,
                          height: 1.8),
                    ),
                  ),
                ),
              ),
              // 放大镜
              Positioned(
                left: _lensPosition.dx - 60,
                top: _lensPosition.dy - 60,
                child: _buildMagnifierLens(),
              ),
              // 提示
              if (!_isDragging)
                const Positioned(
                  bottom: 8,
                  right: 8,
                  child: Text('拖动放大镜',
                      style: TextStyle(color: MiuixColors.textTertiary, fontSize: 10)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMagnifierLens() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: MiuixColors.primary, width: 4),
        boxShadow: [
          BoxShadow(
            color: MiuixColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Transform.scale(
          scale: _zoom,
          child: Transform.translate(
            offset: Offset(
              -(150 - _lensPosition.dx) * (_zoom - 1) / _zoom,
              -(150 - _lensPosition.dy) * (_zoom - 1) / _zoom,
            ),
            child: SizedBox(
              width: 300,
              height: 300,
              child: Padding(
                padding: const EdgeInsets.all(MiuixSpacing.md),
                child: _applyFilter(
                  Text(
                    _sampleText,
                    style: const TextStyle(
                        fontSize: 10,
                        color: MiuixColors.textPrimary,
                        height: 1.8),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _applyFilter(Widget child) {
    switch (_filter) {
      case 1: // 灰度
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: child,
        );
      case 2: // 反色
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            -1, 0, 0, 0, 255,
            0, -1, 0, 0, 255,
            0, 0, -1, 0, 255,
            0, 0, 0, 1, 0,
          ]),
          child: child,
        );
      case 3: // 暖色
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            1.2, 0.1, 0, 0, 0,
            0.1, 1.0, 0, 0, 0,
            0, 0, 0.8, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: child,
        );
      default:
        return child;
    }
  }

  Widget _buildInfoCard() {
    return MiuixCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoItem(Icons.zoom_in, '${_zoom.toStringAsFixed(1)}x', '放大倍数'),
          Container(width: 1, height: 36, color: MiuixColors.divider),
          _infoItem(Icons.filter_list, _filterNames[_filter], '当前滤镜'),
          Container(width: 1, height: 36, color: MiuixColors.divider),
          _infoItem(Icons.touch_app, '拖动', '操作方式'),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: MiuixColors.primary, size: 20),
        const SizedBox(height: MiuixSpacing.xs),
        Text(value,
            style: const TextStyle(
                fontSize: MiuixFontSize.md,
                fontWeight: FontWeight.bold,
                color: MiuixColors.primaryDark)),
        Text(label,
            style: const TextStyle(
                fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary)),
      ],
    );
  }
}
