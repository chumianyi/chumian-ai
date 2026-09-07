import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';

/// ============================================================================
/// AppIcons —— 统一管理 assets/icons/ 下 68 个粉色 Miuix 风格 SVG 图标路径
///
/// 用法：
///   SvgPicture.asset(AppIcons.chat, width: 24, colorFilter: ...)
///
/// 所有图标均为 24x24 视口的粉色线条风格，通过 colorFilter 可动态着色。
/// ============================================================================
class AppIcons {
  AppIcons._();

  // ===== 基础导航 =====
  static const String chat = 'assets/icons/chat.svg';
  static const String creative = 'assets/icons/creative.svg';
  static const String explore = 'assets/icons/explore.svg';
  static const String activity = 'assets/icons/activity.svg';
  static const String points = 'assets/icons/points.svg';
  static const String profile = 'assets/icons/profile.svg';

  // ===== 聊天输入 =====
  static const String send = 'assets/icons/send.svg';
  static const String stop = 'assets/icons/stop.svg';
  static const String microphone = 'assets/icons/microphone.svg';
  static const String attachment = 'assets/icons/attachment.svg';
  static const String emoji = 'assets/icons/emoji.svg';

  // ===== 通用操作 =====
  static const String copy = 'assets/icons/copy.svg';
  static const String settings = 'assets/icons/settings.svg';
  static const String search = 'assets/icons/search.svg';
  static const String close = 'assets/icons/close.svg';
  static const String back = 'assets/icons/back.svg';
  static const String check = 'assets/icons/check.svg';
  static const String bell = 'assets/icons/bell.svg';
  static const String shop = 'assets/icons/shop.svg';
  static const String checkin = 'assets/icons/checkin.svg';
  static const String leaderboard = 'assets/icons/leaderboard.svg';
  static const String globe = 'assets/icons/globe.svg';
  static const String robot = 'assets/icons/robot.svg';
  static const String plus = 'assets/icons/plus.svg';
  static const String minus = 'assets/icons/minus.svg';
  static const String edit = 'assets/icons/edit.svg';
  static const String trash = 'assets/icons/trash.svg';
  static const String download = 'assets/icons/download.svg';
  static const String upload = 'assets/icons/upload.svg';
  static const String refresh = 'assets/icons/refresh.svg';
  static const String more = 'assets/icons/more.svg';
  static const String filter = 'assets/icons/filter.svg';
  static const String sort = 'assets/icons/sort.svg';

  // ===== 媒体 =====
  static const String image = 'assets/icons/image.svg';
  static const String video = 'assets/icons/video.svg';
  static const String play = 'assets/icons/play.svg';
  static const String pause = 'assets/icons/pause.svg';
  static const String volume = 'assets/icons/volume.svg';

  // ===== 社交 =====
  static const String heart = 'assets/icons/heart.svg';
  static const String comment = 'assets/icons/comment.svg';
  static const String share = 'assets/icons/share.svg';
  static const String bookmark = 'assets/icons/bookmark.svg';
  static const String follow = 'assets/icons/follow.svg';

  // ===== 创作工具 =====
  static const String pen = 'assets/icons/pen.svg';
  static const String brush = 'assets/icons/brush.svg';
  static const String code = 'assets/icons/code.svg';
  static const String terminal = 'assets/icons/terminal.svg';
  static const String calculator = 'assets/icons/calculator.svg';
  static const String clock = 'assets/icons/clock.svg';
  static const String calendar = 'assets/icons/calendar.svg';

  // ===== 状态提示 =====
  static const String success = 'assets/icons/success.svg';
  static const String error = 'assets/icons/error.svg';
  static const String warning = 'assets/icons/warning.svg';
  static const String info = 'assets/icons/info.svg';
  static const String retry = 'assets/icons/retry.svg';
  static const String history = 'assets/icons/history.svg';

  // ===== 装饰/等级 =====
  static const String star = 'assets/icons/star.svg';
  static const String fire = 'assets/icons/fire.svg';
  static const String crown = 'assets/icons/crown.svg';
  static const String gift = 'assets/icons/gift.svg';
  static const String lock = 'assets/icons/lock.svg';
  static const String eye = 'assets/icons/eye.svg';
  static const String eyeOff = 'assets/icons/eye_off.svg';

  // ===== 网络/主题 =====
  static const String wifi = 'assets/icons/wifi.svg';
  static const String wifiOff = 'assets/icons/wifi_off.svg';
  static const String moon = 'assets/icons/moon.svg';
  static const String sun = 'assets/icons/sun.svg';
  static const String sparkles = 'assets/icons/sparkles.svg';

  /// 便捷方法：构建一个已着色的 SvgPicture
  static Widget svg(
    String path, {
    double width = 24,
    double height = 24,
    Color? color,
  }) {
    return SvgPicture.asset(
      path,
      width: width,
      height: height,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
    );
  }
}
