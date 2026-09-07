import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// ============================================================================
/// PermissionService —— 统一权限管理服务
///
/// 职责：
///   1. 统一管理麦克风、存储、相机、通知等权限
///   2. 权限请求与状态查询
///   3. Rationale 解释（权限被拒绝后展示原因）
///   4. 粉色主题权限请求弹窗
///   5. 打开应用设置引导用户手动授权
/// ============================================================================
class PermissionService {
  /// 单例实例
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // ==========================================================================
  // 权限状态查询
  // ==========================================================================

  /// 检查权限状态
  Future<PermissionStatus> checkPermission(AppPermission permission) async {
    final perm = _mapPermission(permission);
    return perm.status;
  }

  /// 判断权限是否已授予
  Future<bool> isGranted(AppPermission permission) async {
    final status = await checkPermission(permission);
    return status.isGranted;
  }

  /// 判断权限是否被永久拒绝（需要去设置页手动开启）
  Future<bool> isPermanentlyDenied(AppPermission permission) async {
    final status = await checkPermission(permission);
    return status.isPermanentlyDenied;
  }

  // ==========================================================================
  // 权限请求
  // ==========================================================================

  /// 请求单个权限
  ///
  /// 返回授权结果（true 表示已授予）
  Future<bool> requestPermission(
    AppPermission permission, {
    String? rationaleTitle,
    String? rationaleMessage,
  }) async {
    final status = await checkPermission(permission);

    // 已授权
    if (status.isGranted) return true;

    // 已永久拒绝，引导去设置
    if (status.isPermanentlyDenied) {
      return false;
    }

    // 需要展示 rationale
    if (status.isDenied && rationaleMessage != null) {
      // rationale 展示逻辑由 UI 层处理，这里直接请求
    }

    final perm = _mapPermission(permission);
    final result = await perm.request();
    return result.isGranted;
  }

  /// 批量请求多个权限
  ///
  /// 返回每个权限的授权状态映射
  Future<Map<AppPermission, bool>> requestPermissions(
    List<AppPermission> permissions,
  ) async {
    final results = <AppPermission, bool>{};
    for (final permission in permissions) {
      results[permission] = await requestPermission(permission);
    }
    return results;
  }

  // ==========================================================================
  // 打开应用设置
  // ==========================================================================

  /// 打开应用设置页面（用户手动授权）
  Future<bool> openAppSettings() async {
    return openAppSettings();
  }

  // ==========================================================================
  // 粉色权限弹窗（UI 层调用）
  // ==========================================================================

  /// 展示粉色主题的权限请求弹窗
  ///
  /// [context] 构建上下文，[permission] 目标权限
  /// [onGranted] 授权回调，[onDenied] 拒绝回调
  Future<void> showPermissionDialog({
    required BuildContext context,
    required AppPermission permission,
    VoidCallback? onGranted,
    VoidCallback? onDenied,
  }) async {
    final info = _getPermissionInfo(permission);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF69B4).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  info.icon,
                  color: const Color(0xFFFF69B4),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  info.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            info.description,
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onDenied?.call();
              },
              child: const Text(
                '暂不开启',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF69B4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final granted = await requestPermission(permission);
                if (granted) {
                  onGranted?.call();
                } else {
                  onDenied?.call();
                }
              },
              child: const Text('开启权限'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================================
  // 内部工具方法
  // ==========================================================================

  /// 将 AppPermission 映射到 permission_handler 的 Permission
  Permission _mapPermission(AppPermission permission) {
    switch (permission) {
      case AppPermission.microphone:
        return Permission.microphone;
      case AppPermission.storage:
        return Permission.storage;
      case AppPermission.camera:
        return Permission.camera;
      case AppPermission.notification:
        return Permission.notification;
      case AppPermission.photos:
        return Permission.photos;
      case AppPermission.location:
        return Permission.location;
      case AppPermission.contacts:
        return Permission.contacts;
      case AppPermission.speech:
        return Permission.speech;
    }
  }

  /// 获取权限说明信息
  _PermissionInfo _getPermissionInfo(AppPermission permission) {
    switch (permission) {
      case AppPermission.microphone:
        return _PermissionInfo(
          icon: Icons.mic,
          title: '麦克风权限',
          description: '初眠AI需要麦克风权限来进行语音输入和语音对话，'
              '请在设置中开启麦克风访问权限。',
        );
      case AppPermission.storage:
        return _PermissionInfo(
          icon: Icons.folder,
          title: '存储权限',
          description: '初眠AI需要存储权限来保存图片、文件和缓存数据，'
              '请在设置中开启存储访问权限。',
        );
      case AppPermission.camera:
        return _PermissionInfo(
          icon: Icons.camera_alt,
          title: '相机权限',
          description: '初眠AI需要相机权限来拍摄照片和进行扫码操作，'
              '请在设置中开启相机访问权限。',
        );
      case AppPermission.notification:
        return _PermissionInfo(
          icon: Icons.notifications,
          title: '通知权限',
          description: '初眠AI需要通知权限来推送消息提醒、活动通知和每日任务，'
              '请在设置中开启通知权限。',
        );
      case AppPermission.photos:
        return _PermissionInfo(
          icon: Icons.photo_library,
          title: '相册权限',
          description: '初眠AI需要相册权限来选择和保存图片，'
              '请在设置中开启相册访问权限。',
        );
      case AppPermission.location:
        return _PermissionInfo(
          icon: Icons.location_on,
          title: '位置权限',
          description: '初眠AI需要位置权限来提供天气信息和附近服务，'
              '请在设置中开启位置访问权限。',
        );
      case AppPermission.contacts:
        return _PermissionInfo(
          icon: Icons.contacts,
          title: '通讯录权限',
          description: '初眠AI需要通讯录权限来帮助您分享内容给好友，'
              '请在设置中开启通讯录访问权限。',
        );
      case AppPermission.speech:
        return _PermissionInfo(
          icon: Icons.record_voice_over,
          title: '语音识别权限',
          description: '初眠AI需要语音识别权限来将语音转换为文字，'
              '请在设置中开启语音识别权限。',
        );
    }
  }
}

/// 应用权限枚举
enum AppPermission {
  /// 麦克风
  microphone,

  /// 存储
  storage,

  /// 相机
  camera,

  /// 通知
  notification,

  /// 相册
  photos,

  /// 位置
  location,

  /// 通讯录
  contacts,

  /// 语音识别
  speech,
}

/// 权限说明信息
class _PermissionInfo {
  final IconData icon;
  final String title;
  final String description;

  _PermissionInfo({
    required this.icon,
    required this.title,
    required this.description,
  });
}
