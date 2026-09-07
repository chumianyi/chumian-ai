import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixGlassContainer —— 毛玻璃容器
/// BackdropFilter 模糊 + 半透明白色边框 + 粉色微光
/// 对标 HyperOS 毛玻璃质感
/// ============================================================

/// 毛玻璃容器组件
///
/// 用法：
/// ```dart
/// MiuixGlassContainer(
///   blur: 20,
///   borderRadius: MiuixRadius.lg,
///   child: Text('毛玻璃内容'),
/// )
/// ```
class MiuixGlassContainer extends StatelessWidget {
  const MiuixGlassContainer({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.borderRadius,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.shadow,
    this.gradient,
    this.alignment,
    this.clipBehavior = Clip.antiAlias,
  });

  /// 子组件
  final Widget child;

  /// 背景模糊强度，默认 20
  final double blur;

  /// 圆角，默认 MiuixRadius.lg
  final double? borderRadius;

  /// 宽度
  final double? width;

  /// 高度
  final double? height;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 外边距
  final EdgeInsetsGeometry? margin;

  /// 背景色（半透明叠加在模糊之上），默认白色 15% 透明度
  final Color? backgroundColor;

  /// 边框颜色，默认 MiuixColors.glassBorder
  final Color? borderColor;

  /// 边框宽度，默认 1.0
  final double borderWidth;

  /// 阴影，默认 MiuixShadows.sm
  final List<BoxShadow>? shadow;

  /// 背景渐变（覆盖 backgroundColor）
  final Gradient? gradient;

  /// 子组件对齐方式
  final AlignmentGeometry? alignment;

  /// 裁剪行为
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final double radius = borderRadius ?? MiuixRadius.lg;
    final BorderRadius borderRadiusObj = BorderRadius.circular(radius);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadiusObj,
        boxShadow: shadow ?? MiuixShadows.sm,
      ),
      child: ClipRRect(
        borderRadius: borderRadiusObj,
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            alignment: alignment,
            decoration: BoxDecoration(
              borderRadius: borderRadiusObj,
              color: backgroundColor ?? Colors.white.withOpacity(0.15),
              gradient: gradient,
              border: Border.all(
                color: borderColor ?? MiuixColors.glassBorder,
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// MiuixGlassCard —— 带粉色微光的毛玻璃卡片
/// 在 MiuixGlassContainer 基础上增加顶部高光和粉色微光
/// ============================================================

/// 带粉色微光效果的毛玻璃卡片
class MiuixGlassCard extends StatelessWidget {
  const MiuixGlassCard({
    super.key,
    required this.child,
    this.blur = 24.0,
    this.borderRadius,
    this.padding = const EdgeInsets.all(MiuixSpacing.lg),
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.elevation = 0,
  });

  final Widget child;
  final double blur;
  final double? borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final double radius = borderRadius ?? MiuixRadius.lg;
    return MiuixGlassContainer(
      blur: blur,
      borderRadius: radius,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      backgroundColor: Colors.white.withOpacity(0.18),
      borderColor: MiuixColors.glassBorder,
      shadow: [
        BoxShadow(
          color: MiuixColors.primary.withOpacity(0.08),
          blurRadius: 20 + elevation * 4,
          offset: Offset(0, 4 + elevation * 2),
        ),
      ],
      child: Stack(
        children: [
          // 顶部粉色微光
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    MiuixColors.primaryLight.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // 内容
          child,
        ],
      ),
    );
  }
}
