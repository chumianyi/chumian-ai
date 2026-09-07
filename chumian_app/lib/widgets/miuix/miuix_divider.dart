import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixDivider —— 粉色细分割线
/// 带渐变淡出
/// ============================================================

/// 分割线方向
enum MiuixDividerDirection {
  horizontal,
  vertical,
}

/// Miuix 风格分割线
///
/// 用法：
/// ```dart
/// MiuixDivider()
/// ```
class MiuixDivider extends StatelessWidget {
  const MiuixDivider({
    super.key,
    this.direction = MiuixDividerDirection.horizontal,
    this.thickness = 1.0,
    this.color,
    this.gradient,
    this.indent = 0,
    this.endIndent = 0,
    this.fadeEdges = true,
    this.height,
    this.width,
    this.padding,
  });

  /// 方向
  final MiuixDividerDirection direction;

  /// 厚度
  final double thickness;

  /// 颜色
  final Color? color;

  /// 渐变（覆盖 color）
  final Gradient? gradient;

  /// 起始缩进
  final double indent;

  /// 结束缩进
  final double endIndent;

  /// 是否边缘渐变淡出
  final bool fadeEdges;

  /// 高度（水平时的总高度）
  final double? height;

  /// 宽度（垂直时的总宽度）
  final double? width;

  /// 外边距
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    Widget divider;

    if (direction == MiuixDividerDirection.horizontal) {
      divider = Container(
        height: thickness,
        margin: EdgeInsets.only(left: indent, right: endIndent),
        decoration: BoxDecoration(
          gradient: gradient ??
              (fadeEdges
                  ? LinearGradient(
                      colors: [
                        Colors.transparent,
                        color ?? MiuixColors.divider,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    )
                  : null),
          color: fadeEdges ? null : (color ?? MiuixColors.divider),
        ),
      );

      if (height != null) {
        divider = SizedBox(height: height, child: divider);
      }
    } else {
      divider = Container(
        width: thickness,
        margin: EdgeInsets.only(top: indent, bottom: endIndent),
        decoration: BoxDecoration(
          gradient: gradient ??
              (fadeEdges
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        color ?? MiuixColors.divider,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    )
                  : null),
          color: fadeEdges ? null : (color ?? MiuixColors.divider),
        ),
      );

      if (width != null) {
        divider = SizedBox(width: width, child: divider);
      }
    }

    if (padding != null) {
      divider = Padding(padding: padding!, child: divider);
    }

    return divider;
  }
}

/// ============================================================
/// MiuixVerticalDivider —— 垂直分割线快捷方式
/// ============================================================

/// 垂直分割线
class MiuixVerticalDivider extends StatelessWidget {
  const MiuixVerticalDivider({
    super.key,
    this.height = 20,
    this.thickness = 1,
    this.color,
  });

  final double height;
  final double thickness;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return MiuixDivider(
      direction: MiuixDividerDirection.vertical,
      thickness: thickness,
      color: color,
      height: height,
      fadeEdges: false,
    );
  }
}

/// ============================================================
/// MiuixSectionDivider —— 带标题的分段分割线
/// ============================================================

/// 带标题的分段分割线
class MiuixSectionDivider extends StatelessWidget {
  const MiuixSectionDivider({
    super.key,
    this.title,
    this.action,
    this.onAction,
    this.padding,
  });

  final String? title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: MiuixSpacing.lg,
            vertical: MiuixSpacing.md,
          ),
      child: Row(
        children: [
          if (title != null)
            Text(
              title!,
              style: TextStyle(
                color: MiuixColors.textSecondary,
                fontSize: MiuixFontSize.sm,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(width: MiuixSpacing.sm),
          Expanded(child: MiuixDivider()),
          if (action != null) ...[
            const SizedBox(width: MiuixSpacing.sm),
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: TextStyle(
                  color: MiuixColors.primary,
                  fontSize: MiuixFontSize.sm,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
