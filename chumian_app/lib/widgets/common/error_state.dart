import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';

/// ============================================================================
/// ErrorState —— 错误状态组件
///
/// 粉色错误图标动画，错误信息展示，重试按钮。
/// 用于网络请求失败、数据加载失败等错误场景。
/// ============================================================================
class ErrorState extends StatefulWidget {
  /// 错误标题
  final String? title;

  /// 错误信息
  final String? message;

  /// 错误代码
  final String? errorCode;

  /// 自定义错误图标
  final IconData? icon;

  /// 重试按钮文字
  final String retryText;

  /// 重试回调
  final VoidCallback? onRetry;

  /// 是否显示重试按钮
  final bool showRetry;

  /// 图标大小
  final double iconSize;

  /// 动画类型
  final ErrorAnimationType animationType;

  const ErrorState({
    super.key,
    this.title,
    this.message,
    this.errorCode,
    this.icon,
    this.retryText = '重试',
    this.onRetry,
    this.showRetry = true,
    this.iconSize = 80.0,
    this.animationType = ErrorAnimationType.shake,
  });

  @override
  State<ErrorState> createState() => _ErrorStateState();
}

/// 错误动画类型
enum ErrorAnimationType {
  /// 抖动
  shake,

  /// 脉冲
  pulse,

  /// 旋转
  rotate,
}

class _ErrorStateState extends State<ErrorState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    // 延迟后开始动画
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        switch (widget.animationType) {
          case ErrorAnimationType.shake:
            _controller.forward();
            break;
          case ErrorAnimationType.pulse:
          case ErrorAnimationType.rotate:
            _controller.repeat(reverse: true);
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 动画错误图标
            _buildAnimatedIcon(),
            const SizedBox(height: 24),
            // 标题
            Text(
              widget.title ?? '出错了',
              style: TextStyle(
                fontSize: MiuixFontSize.xxl,
                fontWeight: FontWeight.w700,
                color: MiuixColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            // 错误信息
            if (widget.message != null && widget.message!.isNotEmpty)
              Text(
                widget.message!,
                style: TextStyle(
                  fontSize: MiuixFontSize.md,
                  color: MiuixColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            // 错误代码
            if (widget.errorCode != null && widget.errorCode!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: MiuixColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(MiuixRadius.xs),
                ),
                child: Text(
                  '错误码: ${widget.errorCode}',
                  style: TextStyle(
                    fontSize: 11,
                    color: MiuixColors.error,
                  ),
                ),
              ),
            ],
            // 重试按钮
            if (widget.showRetry && widget.onRetry != null) ...[
              const SizedBox(height: 28),
              _buildRetryButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    final icon = widget.icon ?? Icons.error_outline;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        switch (widget.animationType) {
          case ErrorAnimationType.shake:
            // 抖动：前 60% 抖动，后 40% 静止
            final t = _controller.value;
            double shake = 0;
            if (t < 0.6) {
              shake = sin(t * 5 * pi * 2) * 8 * (1 - t / 0.6);
            }
            return Transform.translate(
              offset: Offset(shake, 0),
              child: _buildIconContainer(icon),
            );
          case ErrorAnimationType.pulse:
            final scale = 0.9 + _controller.value * 0.15;
            return Transform.scale(
              scale: scale,
              child: _buildIconContainer(icon),
            );
          case ErrorAnimationType.rotate:
            final rotation = sin(_controller.value * pi * 2) * 0.05;
            return Transform.rotate(
              angle: rotation,
              child: _buildIconContainer(icon),
            );
        }
      },
    );
  }

  Widget _buildIconContainer(IconData icon) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 背景圆
        Container(
          width: widget.iconSize,
          height: widget.iconSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                MiuixColors.error.withValues(alpha: 0.15),
                MiuixColors.error.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
        ),
        // 图标
        Container(
          width: widget.iconSize * 0.65,
          height: widget.iconSize * 0.65,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                MiuixColors.error,
                MiuixColors.error.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: MiuixColors.error.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: widget.iconSize * 0.35,
          ),
        ),
      ],
    );
  }

  Widget _buildRetryButton() {
    return GestureDetector(
      onTap: widget.onRetry,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: MiuixColors.primaryGradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(MiuixRadius.pill),
          boxShadow: [
            BoxShadow(
              color: MiuixColors.primary.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              widget.retryText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
