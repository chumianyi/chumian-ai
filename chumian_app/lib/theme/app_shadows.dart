import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 全局阴影规范 - 粉色系柔和阴影
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> none = [];

  static const List<BoxShadow> xs = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x18000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> xl = [
    BoxShadow(color: Color(0x26000000), blurRadius: 36, offset: Offset(0, 12)),
  ];

  static const List<BoxShadow> xxl = [
    BoxShadow(color: Color(0x33000000), blurRadius: 48, offset: Offset(0, 16)),
  ];

  // ---- 粉色阴影 ----
  static const List<BoxShadow> pinkXs = [
    BoxShadow(color: Color(0x1AFF6B9D), blurRadius: 6, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> pinkSm = [
    BoxShadow(color: Color(0x24FF6B9D), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> pinkMd = [
    BoxShadow(color: Color(0x33FF6B9D), blurRadius: 20, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> pinkLg = [
    BoxShadow(color: Color(0x40FF6B9D), blurRadius: 32, offset: Offset(0, 10)),
  ];
  static const List<BoxShadow> pinkXl = [
    BoxShadow(color: Color(0x4DFF6B9D), blurRadius: 48, offset: Offset(0, 16)),
  ];

  // ---- 卡片阴影 ----
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 3)),
  ];
  static const List<BoxShadow> cardElevated = [
    BoxShadow(color: Color(0x18000000), blurRadius: 20, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> cardFloating = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 28, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  // ---- 按钮阴影 ----
  static const List<BoxShadow> button = [
    BoxShadow(color: Color(0x33FF6B9D), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> buttonPressed = [
    BoxShadow(color: Color(0x1AFF6B9D), blurRadius: 6, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> buttonGlow = [
    BoxShadow(color: Color(0x4DFF6B9D), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x26FF6B9D), blurRadius: 8, offset: Offset(0, 2)),
  ];

  // ---- 悬浮阴影 ----
  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x26000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> floatingPink = [
    BoxShadow(color: Color(0x40FF6B9D), blurRadius: 28, offset: Offset(0, 10)),
  ];

  // ---- 对话框阴影 ----
  static const List<BoxShadow> dialog = [
    BoxShadow(color: Color(0x33000000), blurRadius: 40, offset: Offset(0, 16)),
  ];

  // ---- 底部弹窗阴影 ----
  static const List<BoxShadow> bottomSheet = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 32, offset: Offset(0, -8)),
  ];

  // ---- 导航栏阴影 ----
  static const List<BoxShadow> navBar = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4)),
  ];

  // ---- AppBar 阴影 ----
  static const List<BoxShadow> appBar = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  // ---- 输入框阴影 ----
  static const List<BoxShadow> input = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> inputFocused = [
    BoxShadow(color: Color(0x26FF6B9D), blurRadius: 12, offset: Offset(0, 2)),
  ];

  // ---- 图片阴影 ----
  static const List<BoxShadow> image = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 6)),
  ];

  // ---- 头像阴影 ----
  static const List<BoxShadow> avatar = [
    BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  // ---- 徽章阴影 ----
  static const List<BoxShadow> badge = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  // ---- Neumorphism 粉色系 ----
  static List<BoxShadow> neuRaised(Color base) => [
    BoxShadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 8, offset: const Offset(-3, -3)),
    BoxShadow(color: base.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(3, 3)),
  ];
  static List<BoxShadow> neuPressed(Color base) => [
    BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 4, offset: const Offset(2, 2)),
    BoxShadow(color: base.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(-2, -2)),
  ];
  static List<BoxShadow> neuSoft(Color base) => [
    BoxShadow(color: Colors.white.withValues(alpha: 0.6), blurRadius: 6, offset: const Offset(-2, -2)),
    BoxShadow(color: base.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(2, 2)),
  ];
}
