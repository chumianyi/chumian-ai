import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// ============================================================================
/// LottieLoading —— 封装 Lottie 加载/成功动画的通用组件
///
/// 支持三种预设：
///   - LottieLoadingType.loading  : assets/lottie/loading.json（加载中）
///   - LottieLoadingType.success  : assets/lottie/success_check.json（成功对勾）
///   - LottieLoadingType.star     : assets/lottie/star.json（星星/签到成功）
///   - LottieLoadingType.ripple   : assets/lottie/ripple.json（水波纹）
///
/// 用法：
///   LottieLoading(type: LottieLoadingType.loading, size: 80)
/// ============================================================================
enum LottieLoadingType {
  loading,
  success,
  star,
  ripple,
}

class LottieLoading extends StatelessWidget {
  const LottieLoading({
    super.key,
    this.type = LottieLoadingType.loading,
    this.size = 64,
    this.repeat = true,
    this.alignment,
  });

  /// 动画类型
  final LottieLoadingType type;

  /// 动画尺寸（宽高相同）
  final double size;

  /// 是否循环播放（success/star 建议设为 false）
  final bool repeat;

  /// 对齐方式
  final AlignmentGeometry? alignment;

  /// 根据类型获取资源路径
  String get _assetPath {
    switch (type) {
      case LottieLoadingType.loading:
        return 'assets/lottie/loading.json';
      case LottieLoadingType.success:
        return 'assets/lottie/success_check.json';
      case LottieLoadingType.star:
        return 'assets/lottie/star.json';
      case LottieLoadingType.ripple:
        return 'assets/lottie/ripple.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        _assetPath,
        width: size,
        height: size,
        repeat: repeat,
        animate: true,
        alignment: alignment ?? Alignment.center,
        // 资源加载失败时回退到系统 CircularProgressIndicator
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: SizedBox(
              width: size * 0.5,
              height: size * 0.5,
              child: const CircularProgressIndicator(strokeWidth: 3),
            ),
          );
        },
      ),
    );
  }
}

/// ============================================================================
/// LottieLoadingOverlay —— 全屏/半屏加载遮罩
///
/// 在异步操作期间显示半透明背景 + Lottie 加载动画，阻止用户交互。
/// ============================================================================
class LottieLoadingOverlay extends StatelessWidget {
  const LottieLoadingOverlay({
    super.key,
    this.message = '加载中...',
    this.size = 80,
    this.barrierColor = Colors.black54,
  });

  final String message;
  final double size;
  final Color barrierColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: barrierColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LottieLoading(type: LottieLoadingType.loading, size: size),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
