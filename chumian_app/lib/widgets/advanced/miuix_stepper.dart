import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================
/// MiuixStepper —— Miuix 风格步骤指示器
/// 横向/纵向步骤条，当前步骤粉色高亮，完成态对勾动画，连接线渐变
/// ============================================================

/// 步骤方向
enum MiuixStepperDirection {
  /// 横向
  horizontal,

  /// 纵向
  vertical,
}

/// 单个步骤数据
class MiuixStep {
  const MiuixStep({
    required this.title,
    this.subtitle,
    this.content,
    this.icon,
  });

  /// 步骤标题
  final String title;

  /// 步骤副标题
  final String? subtitle;

  /// 步骤内容（纵向模式下展开显示）
  final Widget? content;

  /// 自定义图标
  final IconData? icon;
}

/// Miuix 风格步骤指示器
///
/// 用法：
/// ```dart
/// MiuixStepper(
///   steps: [
///     MiuixStep(title: '下单', subtitle: '选择商品'),
///     MiuixStep(title: '支付', subtitle: '完成付款'),
///     MiuixStep(title: '完成', subtitle: '等待收货'),
///   ],
///   currentStep: 1,
/// )
/// ```
class MiuixStepper extends StatefulWidget {
  const MiuixStepper({
    super.key,
    required this.steps,
    this.currentStep = 0,
    this.direction = MiuixStepperDirection.horizontal,
    this.onStepTap,
    this.animate = true,
  });

  /// 步骤列表
  final List<MiuixStep> steps;

  /// 当前步骤索引
  final int currentStep;

  /// 方向
  final MiuixStepperDirection direction;

  /// 步骤点击回调
  final ValueChanged<int>? onStepTap;

  /// 是否启用动画
  final bool animate;

  @override
  State<MiuixStepper> createState() => _MiuixStepperState();
}

class _MiuixStepperState extends State<MiuixStepper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: MiuixCurves.easeInOut,
    );
    if (widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(MiuixStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.direction == MiuixStepperDirection.horizontal) {
      return _buildHorizontal();
    }
    return _buildVertical();
  }

  Widget _buildHorizontal() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: List.generate(widget.steps.length, (index) {
                final step = widget.steps[index];
                final isCompleted = index < widget.currentStep;
                final isCurrent = index == widget.currentStep;
                final progress = _animation.value;

                return Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (index > 0)
                            Expanded(
                              child: _buildConnector(
                                isCompleted: index <= widget.currentStep,
                                progress: isCurrent ? progress : 1.0,
                              ),
                            )
                          else
                            const Spacer(),
                          _StepCircle(
                            index: index,
                            isCompleted: isCompleted,
                            isCurrent: isCurrent,
                            icon: step.icon,
                            progress: isCurrent ? progress : 1.0,
                            onTap: widget.onStepTap != null
                                ? () => widget.onStepTap!(index)
                                : null,
                          ),
                          if (index < widget.steps.length - 1)
                            Expanded(
                              child: _buildConnector(
                                isCompleted: index < widget.currentStep,
                                progress:
                                    isCurrent ? 0.0 : (isCompleted ? 1.0 : 0.0),
                              ),
                            )
                          else
                            const Spacer(),
                        ],
                      ),
                      const SizedBox(height: MiuixSpacing.sm),
                      Text(
                        step.title,
                        style: TextStyle(
                          color: isCurrent
                              ? MiuixColors.primary
                              : isCompleted
                                  ? MiuixColors.textSecondary
                                  : MiuixColors.textTertiary,
                          fontSize: MiuixFontSize.sm,
                          fontWeight:
                              isCurrent ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (step.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          step.subtitle!,
                          style: const TextStyle(
                            color: MiuixColors.textTertiary,
                            fontSize: MiuixFontSize.xs,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVertical() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: List.generate(widget.steps.length, (index) {
            final step = widget.steps[index];
            final isCompleted = index < widget.currentStep;
            final isCurrent = index == widget.currentStep;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      _StepCircle(
                        index: index,
                        isCompleted: isCompleted,
                        isCurrent: isCurrent,
                        icon: step.icon,
                        progress: 1.0,
                        onTap: widget.onStepTap != null
                            ? () => widget.onStepTap!(index)
                            : null,
                      ),
                      if (index < widget.steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: isCompleted
                                    ? [MiuixColors.primary, MiuixColors.primaryLight]
                                    : [MiuixColors.border, MiuixColors.borderLight],
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: MiuixSpacing.md),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: MiuixSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: TextStyle(
                              color: isCurrent
                                  ? MiuixColors.primary
                                  : isCompleted
                                      ? MiuixColors.textSecondary
                                      : MiuixColors.textTertiary,
                              fontSize: MiuixFontSize.md,
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                          if (step.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              step.subtitle!,
                              style: const TextStyle(
                                color: MiuixColors.textTertiary,
                                fontSize: MiuixFontSize.sm,
                              ),
                            ),
                          ],
                          if (step.content != null && isCurrent) ...[
                            const SizedBox(height: MiuixSpacing.sm),
                            AnimatedOpacity(
                              opacity: isCurrent ? 1.0 : 0.0,
                              duration: MiuixDuration.normal,
                              child: step.content,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildConnector({
    required bool isCompleted,
    required double progress,
  }) {
    return Container(
      height: 2.5,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          colors: isCompleted
              ? [MiuixColors.primaryLight, MiuixColors.primary]
              : [MiuixColors.borderLight, MiuixColors.border],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: constraints.maxWidth * progress,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  colors: [MiuixColors.primaryLight, MiuixColors.primary],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 步骤圆圈
class _StepCircle extends StatefulWidget {
  const _StepCircle({
    required this.index,
    required this.isCompleted,
    required this.isCurrent,
    required this.progress,
    this.icon,
    this.onTap,
  });

  final int index;
  final bool isCompleted;
  final bool isCurrent;
  final double progress;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  State<_StepCircle> createState() => _StepCircleState();
}

class _StepCircleState extends State<_StepCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

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
        tween: Tween(begin: 1.0, end: 0.85)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.85, end: 1.0)
            .chain(CurveTween(curve: MiuixCurves.miuixSpring)),
        weight: 70,
      ),
    ]).animate(_scaleController);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isCurrent ? 32.0 : 28.0;

    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) _scaleController.forward();
      },
      onTapUp: (_) {
        if (widget.onTap != null) _scaleController.reverse();
      },
      onTapCancel: () => _scaleController.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: MiuixDuration.normal,
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: widget.isCompleted || widget.isCurrent
                ? const LinearGradient(
                    colors: MiuixColors.primaryGradient,
                  )
                : null,
            color: widget.isCompleted || widget.isCurrent
                ? null
                : MiuixColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isCompleted || widget.isCurrent
                  ? Colors.transparent
                  : MiuixColors.border,
              width: 2,
            ),
            boxShadow: widget.isCurrent
                ? [
                    BoxShadow(
                      color: MiuixColors.primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : widget.icon != null
                    ? Icon(
                        widget.icon,
                        color: widget.isCurrent
                            ? Colors.white
                            : MiuixColors.textTertiary,
                        size: 14,
                      )
                    : Text(
                        '${widget.index + 1}',
                        style: TextStyle(
                          color: widget.isCurrent
                              ? Colors.white
                              : MiuixColors.textTertiary,
                          fontSize: MiuixFontSize.sm,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}
