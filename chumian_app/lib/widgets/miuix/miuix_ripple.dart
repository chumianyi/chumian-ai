import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixRipple —— 全局粉色水晕涟漪
/// 从触点位置扩散的粉色圆形水波纹，可叠加多层，不阻挡点击事件
/// 扩散动画 600ms，颜色 primary 带透明度
/// 支持在任意 widget 上包裹使用
/// ============================================================

/// 单个涟漪动画的配置与状态
class _RippleData {
  _RippleData({
    required this.position,
    required this.controller,
  });

  /// 涟漪在子组件中的相对位置（全局坐标转换后）
  final Offset position;

  /// 该涟漪的动画控制器
  final AnimationController controller;
}

/// MiuixRipple —— 包裹任意 Widget，在其范围内点击时产生粉色水晕涟漪
///
/// 用法：
/// ```dart
/// MiuixRipple(
///   child: Container(width: 200, height: 80, color: Colors.white),
/// )
/// ```
///
/// 特性：
/// - 涟漪从触点位置开始扩散
/// - 可同时叠加多层涟漪（快速连续点击）
/// - 不阻挡子组件的点击事件（使用 Listener 而非 GestureDetector）
/// - 扩散时长 600ms，粉色半透明
class MiuixRipple extends StatefulWidget {
  const MiuixRipple({
    super.key,
    required this.child,
    this.color,
    this.duration = const Duration(milliseconds: 600),
    this.maxRadius,
    this.borderRadius,
  });

  /// 被包裹的子组件
  final Widget child;

  /// 涟漪颜色，默认 MiuixColors.primary 带 25% 透明度
  final Color? color;

  /// 扩散动画时长，默认 600ms
  final Duration duration;

  /// 最大扩散半径，默认自动计算为子组件对角线的一半
  final double? maxRadius;

  /// 涟漪裁剪圆角，默认与子组件一致（不裁剪则为 null）
  final BorderRadius? borderRadius;

  @override
  State<MiuixRipple> createState() => _MiuixRippleState();
}

class _MiuixRippleState extends State<MiuixRipple>
    with TickerProviderStateMixin {
  /// 当前活跃的涟漪列表
  final List<_RippleData> _ripples = [];

  /// 子组件的全局 key，用于测量尺寸和坐标转换
  final GlobalKey _containerKey = GlobalKey();

  /// 添加一个新涟漪
  void _addRipple(Offset globalPosition) {
    final RenderBox? renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // 将全局坐标转换为子组件局部坐标
    final Offset localPosition = renderBox.globalToLocal(globalPosition);

    // 计算最大扩散半径：子组件对角线的一半
    final Size size = renderBox.size;
    final double maxR = widget.maxRadius ??
        math.sqrt(size.width * size.width + size.height * size.height) / 2;

    // 创建动画控制器
    final AnimationController controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final _RippleData ripple = _RippleData(
      position: localPosition,
      controller: controller,
    );

    setState(() {
      _ripples.add(ripple);
    });

    // 动画结束后移除该涟漪
    controller.forward().then((_) {
      if (mounted) {
        setState(() {
          _ripples.remove(ripple);
        });
        controller.dispose();
      }
    });
  }

  @override
  void dispose() {
    // 释放所有未完成的涟漪控制器
    for (final ripple in _ripples) {
      ripple.controller.dispose();
    }
    _ripples.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // 使用 Listener 而非 GestureDetector，避免与滚动/点击冲突
      onPointerDown: (PointerDownEvent event) {
        _addRipple(event.position);
      },
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: Stack(
          key: _containerKey,
          children: [
            // 子组件
            Positioned.fill(child: widget.child),
            // 涟漪层（不阻挡点击）
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _RipplePainter(
                    ripples: _ripples,
                    color: widget.color ??
                        MiuixColors.primary.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 涟漪绘制器 —— 同时绘制多层扩散中的涟漪
class _RipplePainter extends CustomPainter {
  _RipplePainter({
    required this.ripples,
    required this.color,
  });

  final List<_RippleData> ripples;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (final ripple in ripples) {
      final double t = ripple.controller.value;
      // 半径从 0 扩散到最大，使用 easeOut 曲线
      final double radius = Curves.easeOut.transform(t) *
          math.sqrt(size.width * size.width + size.height * size.height);
      // 透明度从 0.6 渐隐到 0
      final double opacity = (1.0 - t) * 0.6;

      final Paint paint = Paint()
        ..color = color.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(ripple.position, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) {
    return oldDelegate.ripples.length != ripples.length;
  }
}

/// ============================================================
/// GlobalRippleOverlay —— 全局 Overlay 注入方案
/// 在整个 app 上捕获指针按下并显示水晕
/// 使用 Listener 而非 GestureDetector，避免与滚动冲突
/// ============================================================

/// 全局涟漪管理类 —— 通过 Overlay 在整个应用上方显示水晕
class GlobalRippleOverlay {
  GlobalRippleOverlay._();

  static final GlobalRippleOverlay instance = GlobalRippleOverlay._();

  OverlayEntry? _overlayEntry;
  final List<_GlobalRipple> _globalRipples = [];
  final GlobalKey<_GlobalRippleLayerState> _layerKey =
      GlobalKey<_GlobalRippleLayerState>();

  /// 初始化全局涟漪层，在 app 根节点调用
  /// 用法：在 MaterialApp 的 builder 中包裹
  void init(BuildContext context) {
    if (_overlayEntry != null) return;
    _overlayEntry = OverlayEntry(
      builder: (context) => _GlobalRippleLayer(key: _layerKey),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Overlay.of(context).insert(_overlayEntry!);
    });
  }

  /// 在指定全局位置显示一个涟漪
  void showRipple(Offset globalPosition, {double maxRadius = 120}) {
    _layerKey.currentState?.addRipple(globalPosition, maxRadius);
  }

  /// 移除全局涟漪层
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

/// 全局涟漪层 Widget —— 覆盖整个屏幕，不阻挡点击
class _GlobalRippleLayer extends StatefulWidget {
  const _GlobalRippleLayer({super.key});

  @override
  State<_GlobalRippleLayer> createState() => _GlobalRippleLayerState();
}

class _GlobalRippleLayerState extends State<_GlobalRippleLayer>
    with TickerProviderStateMixin {
  final List<_GlobalRipple> _ripples = [];

  void addRipple(Offset position, double maxRadius) {
    final AnimationController controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    final ripple = _GlobalRipple(
      position: position,
      controller: controller,
      maxRadius: maxRadius,
    );
    setState(() {
      _ripples.add(ripple);
    });
    controller.forward().then((_) {
      if (mounted) {
        setState(() {
          _ripples.remove(ripple);
        });
        controller.dispose();
      }
    });
  }

  @override
  void dispose() {
    for (final r in _ripples) {
      r.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _GlobalRipplePainter(ripples: _ripples),
      ),
    );
  }
}

class _GlobalRipple {
  _GlobalRipple({
    required this.position,
    required this.controller,
    required this.maxRadius,
  });

  final Offset position;
  final AnimationController controller;
  final double maxRadius;
}

class _GlobalRipplePainter extends CustomPainter {
  _GlobalRipplePainter({required this.ripples});

  final List<_GlobalRipple> ripples;

  @override
  void paint(Canvas canvas, Size size) {
    for (final ripple in ripples) {
      final double t = ripple.controller.value;
      final double radius = Curves.easeOut.transform(t) * ripple.maxRadius;
      final double opacity = (1.0 - t) * 0.35;
      final Paint paint = Paint()
        ..color = MiuixColors.primary.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(ripple.position, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlobalRipplePainter oldDelegate) =>
      oldDelegate.ripples.length != ripples.length;
}

/// ============================================================
/// PinkRippleEffect —— 便捷的粉色水晕效果混入
/// 用于在自定义组件中快速添加涟漪渲染
/// ============================================================

/// 粉色涟漪效果工具类
class PinkRippleEffect {
  /// 创建一个粉色涟漪的 Paint
  static Paint createPaint(double progress, {double baseOpacity = 0.25}) {
    final double opacity = (1.0 - progress) * baseOpacity;
    return Paint()
      ..color = MiuixColors.primary.withValues(alpha: opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;
  }

  /// 计算涟漪半径
  static double calculateRadius(double progress, double maxRadius) {
    return Curves.easeOut.transform(progress) * maxRadius;
  }
}
