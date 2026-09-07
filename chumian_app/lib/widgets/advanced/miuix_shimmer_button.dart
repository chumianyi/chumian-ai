import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixShimmerButton —— Miuix 风格微光按钮
/// 粉色渐变+扫光动画，按压缩放，加载态，水晕
/// ============================================================

/// Miuix 风格微光按钮
///
/// 用法：
/// ```dart
/// MiuixShimmerButton(
///   label: '立即体验',
///   onPressed: () {},
/// )
/// ```
class MiuixShimmerButton extends StatefulWidget {
  const MiuixShimmerButton({
    super.key,
    required this.label,
    this.onPressed,
    this.width,
    this.height = 52,
    this.borderRadius,
    this.gradient,
    this.icon,
    this.loading = false,
    this.disabled = false,
    this.shimmerEnabled = true,
  });

  /// 按钮文字
  final String label;

  /// 点击回调
  final VoidCallback? onPressed;

  /// 宽度
  final double? width;

  /// 高度
  final double height;

  /// 圆角
  final double? borderRadius;

  /// 自定义渐变
  final Gradient? gradient;

  /// 图标
  final IconData? icon;

  /// 是否加载中
  final bool loading;

  /// 是否禁用
  final bool disabled;

  /// 是否启用扫光动画
  final bool shimmerEnabled;

  @override
  State<MiuixShimmerButton> createState() => _MiuixShimmerButtonState();
}

class _MiuixShimmerButtonState extends State<MiuixShimmerButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _shimmerController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: MiuixDuration.fast,
      reverseDuration: MiuixDuration.elastic,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.92)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: MiuixCurves.miuixSpring)),
        weight: 70,
      ),
    ]).animate(_scaleController);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.shimmerEnabled && !widget.disabled && !widget.loading) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(MiuixShimmerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.disabled || widget.loading) {
      _shimmerController.stop();
    } else if (widget.shimmerEnabled) {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  bool get _isDisabled => widget.disabled || widget.loading;

  void _onTapDown(TapDownDetails details) {
    if (_isDisabled) return;
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (_isDisabled) return;
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? MiuixRadius.pill;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _isDisabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _shimmerController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Opacity(
          opacity: _isDisabled ? 0.5 : 1.0,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: widget.gradient ??
                  const LinearGradient(
                    colors: MiuixColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: MiuixColors.primary.withOpacity(0.4),
                  blurRadius: _isPressed ? 8 : 16,
                  offset: Offset(0, _isPressed ? 2 : 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(
                children: [
                  // 扫光动画
                  if (widget.shimmerEnabled && !_isDisabled)
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        final dx = _shimmerController.value * 3 - 1.5;
                        return Positioned.fill(
                          child: Transform.translate(
                            offset: Offset(dx * widget.height, 0),
                            child: Container(
                              width: widget.height,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withOpacity(0.4),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  // 水晕效果
                  if (_isPressed)
                    Positioned.fill(
                      child: Container(
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                  // 内容
                  Center(
                    child: widget.loading
                        ? SizedBox(
                            width: widget.height * 0.45,
                            height: widget.height * 0.45,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(widget.icon,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                widget.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: MiuixFontSize.md,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// MiuixShimmerLoading —— 微光加载占位
/// 粉色扫光动画的骨架屏
/// ============================================================
class MiuixShimmerLoading extends StatefulWidget {
  const MiuixShimmerLoading({
    super.key,
    this.width,
    this.height = 48,
    this.borderRadius = MiuixRadius.md,
    this.baseColor,
    this.highlightColor,
  });

  final double? width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<MiuixShimmerLoading> createState() => _MiuixShimmerLoadingState();
}

class _MiuixShimmerLoadingState extends State<MiuixShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dx = _controller.value * 3 - 1.5;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.baseColor ?? MiuixColors.surfaceVariant,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(dx * widget.height, 0),
                    child: Container(
                      width: widget.height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            (widget.highlightColor ?? Colors.white)
                                .withOpacity(0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
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
}

/// ============================================================
/// MiuixShimmerList —— 微光加载列表
/// 多个微光占位项组成的列表骨架
/// ============================================================
class MiuixShimmerList extends StatelessWidget {
  const MiuixShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 72,
    this.spacing = MiuixSpacing.md,
  });

  final int itemCount;
  final double itemHeight;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(itemCount, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index < itemCount - 1 ? spacing : 0),
          child: Row(
            children: [
              MiuixShimmerLoading(
                width: itemHeight - 16,
                height: itemHeight - 16,
                borderRadius: MiuixRadius.pill,
              ),
              const SizedBox(width: MiuixSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MiuixShimmerLoading(
                      width: double.infinity,
                      height: 14,
                      borderRadius: MiuixRadius.sm,
                    ),
                    const SizedBox(height: MiuixSpacing.sm),
                    MiuixShimmerLoading(
                      width: 120,
                      height: 12,
                      borderRadius: MiuixRadius.sm,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
