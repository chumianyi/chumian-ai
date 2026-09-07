import 'dart:io';
import 'dart:ui';

/// ============================================================================
/// PlatformUtils —— 平台工具
///
/// 功能：
///   1. 操作系统检测：Android/iOS/Windows/macOS/Linux/Web
///   2. 版本获取：操作系统版本号
///   3. 设备类型：手机/平板/桌面
///   4. 屏幕尺寸：宽度/高度/像素密度
///   5. 安全区域：刘海屏/底部手势区域
///   6. 刘海屏检测：判断是否有刘海/挖孔
///   7. 暗色模式检测：系统是否为暗色模式
/// ============================================================================
class PlatformUtils {
  // ==========================================================================
  // 操作系统检测
  // ==========================================================================

  /// 是否为 Android
  static bool get isAndroid => Platform.isAndroid;

  /// 是否为 iOS
  static bool get isIOS => Platform.isIOS;

  /// 是否为 Windows
  static bool get isWindows => Platform.isWindows;

  /// 是否为 macOS
  static bool get isMacOS => Platform.isMacOS;

  /// 是否为 Linux
  static bool get isLinux => Platform.isLinux;

  /// 是否为 Web
  static bool get isWeb => false; // 非 Web 环境

  /// 是否为移动端
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;

  /// 是否为桌面端
  static bool get isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  /// 获取操作系统名称
  static String get osName {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  /// 获取操作系统标识（小写）
  static String get osKey {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  // ==========================================================================
  // 版本获取
  // ==========================================================================

  /// 获取操作系统版本
  static String get osVersion => Platform.operatingSystemVersion;

  /// 获取 Dart 版本
  static String get dartVersion => Platform.version;

  /// 获取操作系统版本号（纯数字部分）
  static String get osVersionNumber {
    final version = Platform.operatingSystemVersion;
    final match = RegExp(r'(\d+\.\d+(\.\d+)?)').firstMatch(version);
    return match?.group(1) ?? '0.0.0';
  }

  /// 获取主版本号
  static int get majorVersion {
    final version = osVersionNumber;
    return int.tryParse(version.split('.').first) ?? 0;
  }

  /// 获取次版本号
  static int get minorVersion {
    final parts = osVersionNumber.split('.');
    return parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  }

  // ==========================================================================
  // 设备类型
  // ==========================================================================

  /// 设备类型枚举
  static DeviceType get deviceType {
    if (isDesktop) return DeviceType.desktop;
    final size = screenSize;
    // 平板判断：最短边 >= 600 dp
    final shortestSide = size.width < size.height ? size.width : size.height;
    if (shortestSide >= 600) return DeviceType.tablet;
    return DeviceType.phone;
  }

  /// 是否为手机
  static bool get isPhone => deviceType == DeviceType.phone;

  /// 是否为平板
  static bool get isTablet => deviceType == DeviceType.tablet;

  /// 是否为桌面设备
  static bool get isDesktopDevice => deviceType == DeviceType.desktop;

  /// 获取设备类型名称
  static String get deviceTypeName {
    switch (deviceType) {
      case DeviceType.phone:
        return '手机';
      case DeviceType.tablet:
        return '平板';
      case DeviceType.desktop:
        return '桌面';
    }
  }

  // ==========================================================================
  // 屏幕尺寸
  // ==========================================================================

  /// 获取屏幕逻辑尺寸（dp）
  static Size get screenSize {
    final view = PlatformDispatcher.instance.views.first;
    return view.physicalSize / view.devicePixelRatio;
  }

  /// 获取屏幕物理尺寸（px）
  static Size get physicalScreenSize {
    return PlatformDispatcher.instance.views.first.physicalSize;
  }

  /// 屏幕宽度（dp）
  static double get screenWidth => screenSize.width;

  /// 屏幕高度（dp）
  static double get screenHeight => screenSize.height;

  /// 屏幕宽度（px）
  static double get physicalWidth => physicalScreenSize.width;

  /// 屏幕高度（px）
  static double get physicalHeight => physicalScreenSize.height;

  /// 设备像素比
  static double get devicePixelRatio =>
      PlatformDispatcher.instance.views.first.devicePixelRatio;

  /// 屏幕最短边（dp）
  static double get shortestSide =>
      screenWidth < screenHeight ? screenWidth : screenHeight;

  /// 屏幕最长边（dp）
  static double get longestSide =>
      screenWidth > screenHeight ? screenWidth : screenHeight;

  /// 屏幕对角线长度（英寸，估算）
  static double get diagonalInches {
    // 假设常见密度，实际需要设备信息
    final physicalDiagonal =
        sqrt(physicalWidth * physicalWidth + physicalHeight * physicalHeight);
    return physicalDiagonal / (devicePixelRatio * 160);
  }

  /// 是否为横屏
  static bool get isLandscape => screenWidth > screenHeight;

  /// 是否为竖屏
  static bool get isPortrait => screenHeight > screenWidth;

  /// 获取屏幕方向
  static ScreenOrientation get orientation =>
      isLandscape ? ScreenOrientation.landscape : ScreenOrientation.portrait;

  // ==========================================================================
  // 安全区域
  // ==========================================================================

  /// 获取安全区域（padding）
  static WindowPadding get safeArea =>
      PlatformDispatcher.instance.views.first.padding;

  /// 顶部安全区域（dp）
  static double get safeAreaTop => safeArea.top / devicePixelRatio;

  /// 底部安全区域（dp）
  static double get safeAreaBottom => safeArea.bottom / devicePixelRatio;

  /// 左侧安全区域（dp）
  static double get safeAreaLeft => safeArea.left / devicePixelRatio;

  /// 右侧安全区域（dp）
  static double get safeAreaRight => safeArea.right / devicePixelRatio;

  /// 是否有顶部安全区域（刘海/状态栏）
  static bool get hasTopSafeArea => safeAreaTop > 0;

  /// 是否有底部安全区域（手势条）
  static bool get hasBottomSafeArea => safeAreaBottom > 0;

  // ==========================================================================
  // 刘海屏检测
  // ==========================================================================

  /// 是否可能为刘海屏（顶部安全区域较大）
  static bool get hasNotch {
    if (!isMobile) return false;
    // iOS 刘海屏顶部安全区域通常 >= 44dp
    // Android 挖孔屏通常 >= 24dp
    return safeAreaTop >= 24;
  }

  /// 是否可能为底部手势条（iPhone X+ 或 Android 手势导航）
  static bool get hasBottomGesture => safeAreaBottom >= 20;

  /// 刘海高度（dp）
  static double get notchHeight => safeAreaTop;

  /// 底部手势条高度（dp）
  static double get bottomGestureHeight => safeAreaBottom;

  // ==========================================================================
  // 暗色模式检测
  // ==========================================================================

  /// 系统是否为暗色模式
  static bool get isDarkMode {
    final brightness =
        PlatformDispatcher.instance.views.first.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  /// 系统是否为亮色模式
  static bool get isLightMode => !isDarkMode;

  /// 获取系统亮度模式
  static Brightness get platformBrightness =>
      PlatformDispatcher.instance.views.first.platformDispatcher.platformBrightness;

  // ==========================================================================
  // 环境信息
  // ==========================================================================

  /// 获取当前区域设置
  static Locale get locale {
    final localeName = Platform.localeName;
    final parts = localeName.split('_');
    if (parts.length >= 2) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(parts.isNotEmpty ? parts[0] : 'en');
  }

  /// 获取语言代码
  static String get languageCode => locale.languageCode;

  /// 获取国家代码
  static String? get countryCode => locale.countryCode;

  /// 获取本地时区名称
  static String get timezoneName => DateTime.now().timeZoneName;

  /// 获取本地时区偏移
  static Duration get timezoneOffset => DateTime.now().timeZoneOffset;

  /// 获取环境变量
  static Map<String, String> get environment => Platform.environment;

  /// 获取指定环境变量
  static String? getEnvironmentVariable(String key) =>
      Platform.environment[key];

  /// 获取可执行文件路径
  static String get executablePath => Platform.resolvedExecutable;

  /// 获取脚本路径
  static String get scriptPath => Platform.script.path;

  // ==========================================================================
  // 工具方法
  // ==========================================================================

  /// 获取完整的设备信息
  static Map<String, dynamic> getDeviceInfo() {
    return {
      'os_name': osName,
      'os_key': osKey,
      'os_version': osVersion,
      'os_version_number': osVersionNumber,
      'dart_version': dartVersion,
      'device_type': deviceTypeName,
      'is_mobile': isMobile,
      'is_desktop': isDesktop,
      'screen_width': screenWidth,
      'screen_height': screenHeight,
      'physical_width': physicalWidth,
      'physical_height': physicalHeight,
      'device_pixel_ratio': devicePixelRatio,
      'is_landscape': isLandscape,
      'is_portrait': isPortrait,
      'safe_area_top': safeAreaTop,
      'safe_area_bottom': safeAreaBottom,
      'safe_area_left': safeAreaLeft,
      'safe_area_right': safeAreaRight,
      'has_notch': hasNotch,
      'has_bottom_gesture': hasBottomGesture,
      'is_dark_mode': isDarkMode,
      'locale': Platform.localeName,
      'language_code': languageCode,
      'country_code': countryCode,
      'timezone_name': timezoneName,
      'timezone_offset_hours': timezoneOffset.inHours,
    };
  }

  /// 格式化屏幕尺寸
  static String formatScreenSize() {
    return '${screenWidth.toStringAsFixed(0)} x ${screenHeight.toStringAsFixed(0)} dp';
  }

  /// 格式化物理尺寸
  static String formatPhysicalSize() {
    return '${physicalWidth.toStringAsFixed(0)} x ${physicalHeight.toStringAsFixed(0)} px';
  }

  /// 检查是否满足最小屏幕宽度
  static bool minWidth(double width) => screenWidth >= width;

  /// 检查是否满足最小屏幕高度
  static bool minHeight(double height) => screenHeight >= height;

  /// 检查是否为小屏幕手机（宽度 < 360dp）
  static bool get isSmallPhone => screenWidth < 360;

  /// 检查是否为大屏手机（宽度 >= 400dp）
  static bool get isLargePhone => screenWidth >= 400 && isPhone;

  /// 获取平台特定的文件分隔符
  static String get pathSeparator => Platform.pathSeparator;

  /// 是否支持指定平台特性
  static bool supportsFeature(PlatformFeature feature) {
    switch (feature) {
      case PlatformFeature.notifications:
        return isMobile;
      case PlatformFeature.shortcuts:
        return isAndroid || isIOS;
      case PlatformFeature.widgets:
        return isAndroid || isIOS;
      case PlatformFeature.biometrics:
        return isMobile;
      case PlatformFeature.bluetooth:
        return isMobile || isDesktop;
      case PlatformFeature.camera:
        return isMobile;
      case PlatformFeature.gps:
        return isMobile;
      case PlatformFeature.fileSystem:
        return isDesktop || isAndroid;
      case PlatformFeature.backgroundFetch:
        return isMobile;
    }
  }
}

/// 设备类型
enum DeviceType { phone, tablet, desktop }

/// 屏幕方向
enum ScreenOrientation { portrait, landscape }

/// 平台特性
enum PlatformFeature {
  notifications,
  shortcuts,
  widgets,
  biometrics,
  bluetooth,
  camera,
  gps,
  fileSystem,
  backgroundFetch,
}
