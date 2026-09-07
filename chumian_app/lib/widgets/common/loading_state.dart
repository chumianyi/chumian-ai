import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================================
/// LoadingState —— 加载状态组件
///
/// 粉色加载动画，可选文字提示，骨架屏集成。
/// 用于数据加载、页面初始化等等待场景。
/// ============================================================================
class LoadingState extends StatefulWidget {
  /// 加载提示文字
  final String? message;

  /// 加载动画类型
  final LoadingType loadingType;

  /// 动画大小
  final double size;

  /// 是否显示骨架屏
  final bool showSkeleton;

  /// 骨架屏行数
  final int skeletonLines;

  /// 自定义加载组件（优先级高于内置动画）
  final Widget? customIndicator;

  const LoadingState({
    super.key,
    this.message,
    this.loadingType = LoadingType.spinner,
    this.size = 48.0,
    this.showSkeleton = false,
    this.skeletonLines = 5,
    this.customIndicator,
  });

  @override
  State<LoadingState> createState() => _LoadingStateState();
}

/// 加载动画类型
enum LoadingType {
  /// 旋转圆环
  spinner,

  /// 跳动圆点
  dots,

  /// 脉冲圆环
  pulse,

  /// 旋转方块
  square,

  /// 双环旋转
  dualRing,
}

class _LoadingStateState extends State<LoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showSkeleton) {
      return _buildSkeleton();
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.customIndicator ?? _buildIndicator(),
            if (widget.message != null && widget.message!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildMessage(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator() {
    switch (widget.loadingType) {
      case LoadingType.spinner:
        return _buildSpinner();
      case LoadingType.dots:
        return _buildDots();
      case LoadingType.pulse:
        return _buildPulse();
      case LoadingType.square:
        return _buildSquare();
      case LoadingType.dualRing:
        return _buildDualRing();
    }
  }

  // 旋转圆环
  Widget _buildSpinner() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * 2 * pi,
            child: child,
          );
        },
        child: CircularProgressIndicator(
          strokeWidth: 4,
          valueColor: AlwaysStoppedAnimation<Color>(MiuixColors.primary),
          backgroundColor: MiuixColors.surfaceVariant,
        ),
      ),
    );
  }

  // 跳动圆点
  Widget _buildDots() {
    return SizedBox(
      width: widget.size * 1.8,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final delay = i * 0.15;
              final t = ((_controller.value + delay) % 1.0);
              final bounce = sin(t * pi) * widget.size * 0.3;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.size * 0.08),
                child: Transform.translate(
                  offset: Offset(0, -bounce),
                  child: Container(
                    width: widget.size * 0.25,
                    height: widget.size * 0.25,
                    decoration: BoxDecoration(
                      color: MiuixColors.primary
                          .withOpacity(0.5 + t * 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  // 脉冲圆环
  Widget _buildPulse() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 0.5 + _controller.value * 0.5;
          final opacity = 1.0 - _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size * scale,
                height: widget.size * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MiuixColors.primary.withOpacity(opacity * 0.3),
                ),
              ),
              Container(
                width: widget.size * 0.4,
                height: widget.size * 0.4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: MiuixColors.primaryGradient,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 旋转方块
  Widget _buildSquare() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * pi,
            child: Container(
              width: widget.size * 0.5,
              height: widget.size * 0.5,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: MiuixColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
      ),
    );
  }

  // 双环旋转
  Widget _buildDualRing() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // 外环顺时针
              Transform.rotate(
                angle: _controller.value * 2 * pi,
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    value: 0.7,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(MiuixColors.primary),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              // 内环逆时针
              Transform.rotate(
                angle: -_controller.value * 2 * pi,
                child: SizedBox(
                  width: widget.size * 0.6,
                  height: widget.size * 0.6,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    value: 0.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        MiuixColors.primaryLight),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessage() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.message!,
          style: TextStyle(
            fontSize: MiuixFontSize.md,
            color: MiuixColors.textSecondary,
          ),
        ),
        // 省略号动画
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final dotCount = (_controller.value * 3).floor() + 1;
            return Text(
              '.' * dotCount,
              style: TextStyle(
                fontSize: MiuixFontSize.md,
                color: MiuixColors.primary,
              ),
            );
          },
        ),
      ],
    );
  }

  // 骨架屏
  Widget _buildSkeleton() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.skeletonLines,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  // 圆形头像骨架
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _skeletonColor(index * 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 文字骨架
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _skeletonColor(index * 0.1 + 0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: MediaQuery.of(context).size.width * 0.5,
                          decoration: BoxDecoration(
                            color: _skeletonColor(index * 0.1 + 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _skeletonColor(double offset) {
    final t = ((_controller.value + offset) % 1.0);
    final base = MiuixColors.surfaceVariant;
    final highlight = MiuixColors.surfaceHover;
    return Color.lerp(base, highlight, sin(t * pi) * 0.5 + 0.5)!;
  }
}
