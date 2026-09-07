import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixColorPicker —— Miuix 风格颜色选择器
/// 色轮 + 饱和度亮度面板 + 预设色板，粉色主题，实时预览
/// ============================================================

/// Miuix 风格颜色选择器
///
/// 用法：
/// ```dart
/// MiuixColorPicker(
///   initialColor: MiuixColors.primary,
///   onColorChanged: (color) {},
/// )
/// ```
class MiuixColorPicker extends StatefulWidget {
  const MiuixColorPicker({
    super.key,
    this.initialColor = MiuixColors.primary,
    this.onColorChanged,
    this.presetColors = const [
      MiuixColors.primary,
      Color(0xFFFF4081),
      Color(0xFFE91E63),
      Color(0xFF9C27B0),
      Color(0xFFFF9800),
      Color(0xFFFFC107),
      Color(0xFF4CAF50),
      Color(0xFF2196F3),
    ],
    this.showPreview = true,
    this.showPresets = true,
  });

  /// 初始颜色
  final Color initialColor;

  /// 颜色变化回调
  final ValueChanged<Color>? onColorChanged;

  /// 预设色板
  final List<Color> presetColors;

  /// 是否显示实时预览
  final bool showPreview;

  /// 是否显示预设色板
  final bool showPresets;

  @override
  State<MiuixColorPicker> createState() => _MiuixColorPickerState();
}

class _MiuixColorPickerState extends State<MiuixColorPicker> {
  late double _hue;
  late double _saturation;
  late double _value;
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initialColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
    _currentColor = widget.initialColor;
  }

  void _updateColor() {
    final hsv = HSVColor.fromAHSV(1.0, _hue, _saturation, _value);
    setState(() => _currentColor = hsv.toColor());
    widget.onColorChanged?.call(_currentColor);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MiuixSpacing.lg),
      decoration: BoxDecoration(
        color: MiuixColors.surface,
        borderRadius: BorderRadius.circular(MiuixRadius.lg),
        boxShadow: MiuixShadows.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showPreview) _buildPreview(),
          const SizedBox(height: MiuixSpacing.lg),
          _buildSaturationValuePanel(),
          const SizedBox(height: MiuixSpacing.lg),
          _buildHueSlider(),
          if (widget.showPresets) ...[
            const SizedBox(height: MiuixSpacing.lg),
            _buildPresets(),
          ],
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _currentColor,
            borderRadius: BorderRadius.circular(MiuixRadius.md),
            boxShadow: [
              BoxShadow(
                color: _currentColor.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(width: MiuixSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '#${_currentColor.value.toRadixString(16).substring(2).toUpperCase()}',
              style: const TextStyle(
                color: MiuixColors.textPrimary,
                fontSize: MiuixFontSize.md,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'R:${_currentColor.red} G:${_currentColor.green} B:${_currentColor.blue}',
              style: const TextStyle(
                color: MiuixColors.textTertiary,
                fontSize: MiuixFontSize.sm,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaturationValuePanel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return GestureDetector(
          onPanUpdate: (details) {
            final renderBox = context.findRenderObject() as RenderBox;
            final localPos = details.localPosition;
            setState(() {
              _saturation =
                  (localPos.dx / size).clamp(0.0, 1.0);
              _value = (1 - localPos.dy / size).clamp(0.0, 1.0);
            });
            _updateColor();
          },
          onPanDown: (details) {
            final localPos = details.localPosition;
            setState(() {
              _saturation = (localPos.dx / size).clamp(0.0, 1.0);
              _value = (1 - localPos.dy / size).clamp(0.0, 1.0);
            });
            _updateColor();
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(MiuixRadius.md),
            child: CustomPaint(
              size: Size(size, size * 0.7),
              painter: _SaturationValuePainter(hue: _hue),
              child: Stack(
                children: [
                  Positioned(
                    left: _saturation * size - 10,
                    top: (1 - _value) * size * 0.7 - 10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHueSlider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _hue = (details.localPosition.dx / width * 360)
                  .clamp(0.0, 360.0);
            });
            _updateColor();
          },
          onPanDown: (details) {
            setState(() {
              _hue = (details.localPosition.dx / width * 360)
                  .clamp(0.0, 360.0);
            });
            _updateColor();
          },
          child: Container(
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(MiuixRadius.pill),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF0000),
                  Color(0xFFFFFF00),
                  Color(0xFF00FF00),
                  Color(0xFF00FFFF),
                  Color(0xFF0000FF),
                  Color(0xFFFF00FF),
                  Color(0xFFFF0000),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: _hue / 360 * width - 12,
                  top: 2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: HSVColor.fromAHSV(1.0, _hue, 1.0, 1.0).toColor(),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPresets() {
    return Wrap(
      spacing: MiuixSpacing.sm,
      runSpacing: MiuixSpacing.sm,
      children: widget.presetColors.map((color) {
        final isSelected = color.value == _currentColor.value;
        return GestureDetector(
          onTap: () {
            final hsv = HSVColor.fromColor(color);
            setState(() {
              _hue = hsv.hue;
              _saturation = hsv.saturation;
              _value = hsv.value;
              _currentColor = color;
            });
            widget.onColorChanged?.call(color);
          },
          child: AnimatedContainer(
            duration: MiuixDuration.fast,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: MiuixColors.primary, width: 3)
                  : Border.all(color: MiuixColors.border, width: 1),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

/// 饱和度-亮度面板绘制器
class _SaturationValuePainter extends CustomPainter {
  _SaturationValuePainter({required this.hue});

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    // 饱和度渐变（水平）
    final saturationShader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.white,
        HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor(),
      ],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = saturationShader);

    // 亮度渐变（垂直，黑色遮罩）
    final valueShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        Colors.black,
      ],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = valueShader);
  }

  @override
  bool shouldRepaint(covariant _SaturationValuePainter oldDelegate) =>
      oldDelegate.hue != hue;
}
