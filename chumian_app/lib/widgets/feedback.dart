/// 反馈类组件：空态 / 加载 / 错误重试 / 骨架屏。
library;

import 'package:flutter/material.dart';
import 'context_ext.dart';
import '../theme.dart';

/// 空态占位。
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize + 24,
              height: iconSize + 24,
              decoration: BoxDecoration(
                color: context.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: iconSize, color: context.primary.withValues(alpha: 0.65)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.textPrimary),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: context.textSecondary, height: 1.4),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// 全屏加载态。
class LoadingView extends StatelessWidget {
  final String? message;

  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: context.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(fontSize: 13, color: context.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// 加载失败 + 重试。
class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorRetry({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: '加载失败',
      subtitle: message,
      action: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('重试'),
      ),
    );
  }
}

/// 骨架屏占位块。
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius radius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = R.allXs,
  });

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.light
        ? const Color(0xFFEDE7F0)
        : const Color(0xFF2C2C3A);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: radius,
      ),
    );
  }
}

/// 页面骨架屏（列表结构）。
class ListSkeleton extends StatelessWidget {
  final int items;
  final bool showHeader;

  const ListSkeleton({super.key, this.items = 5, this.showHeader = true});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: items,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: R.allLg,
          ),
          child: Row(
            children: [
              const SkeletonBox(width: 46, height: 46, radius: R.allMd),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 120, height: 14),
                    SizedBox(height: 8),
                    SkeletonBox(width: 200, height: 12),
                    SizedBox(height: 8),
                    SkeletonBox(width: 160, height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 卡片网格骨架屏。
class GridSkeleton extends StatelessWidget {
  final int items;
  final int columns;

  const GridSkeleton({super.key, this.items = 6, this.columns = 2});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: items,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: R.allLg,
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 40, height: 40, radius: R.allMd),
              SizedBox(height: 12),
              SkeletonBox(width: 120, height: 14),
              SizedBox(height: 8),
              SkeletonBox(width: 180, height: 12),
            ],
          ),
        );
      },
    );
  }
}

/// 下拉刷新包装。
class AppRefreshable extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;

  const AppRefreshable({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? context.primary,
      backgroundColor: context.surface,
      displacement: 48,
      edgeOffset: 0,
      child: child,
    );
  }
}
