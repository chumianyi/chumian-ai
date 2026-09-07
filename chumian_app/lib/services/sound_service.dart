import 'package:audioplayers/audioplayers.dart';
import 'package:chumian_ai/providers/settings_provider.dart';

/// ============================================================================
/// SoundService —— 全局音效播放服务（单例）
///
/// 基于 audioplayers 封装，预加载 assets/sounds/ 下 12 个 WAV 音效。
/// 提供 playSend / playReceive / playClick / playRipple / playSuccess /
/// playError 等语义化方法。
///
/// 音效开关由 SettingsProvider.soundEnabled 控制，关闭时所有方法静默返回。
/// ============================================================================
class SoundService {
  SoundService._internal();
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;

  /// 各音效对应的 AudioPlayer 实例（独立播放器避免互相打断）
  final AudioPlayer _sendPlayer = AudioPlayer(playerId: 'sound_send');
  final AudioPlayer _receivePlayer = AudioPlayer(playerId: 'sound_receive');
  final AudioPlayer _clickPlayer = AudioPlayer(playerId: 'sound_click');
  final AudioPlayer _ripplePlayer = AudioPlayer(playerId: 'sound_ripple');
  final AudioPlayer _successPlayer = AudioPlayer(playerId: 'sound_success');
  final AudioPlayer _errorPlayer = AudioPlayer(playerId: 'sound_error');
  final AudioPlayer _notificationPlayer =
      AudioPlayer(playerId: 'sound_notification');
  final AudioPlayer _deletePlayer = AudioPlayer(playerId: 'sound_delete');
  final AudioPlayer _recordStartPlayer =
      AudioPlayer(playerId: 'sound_record_start');
  final AudioPlayer _recordStopPlayer =
      AudioPlayer(playerId: 'sound_record_stop');
  final AudioPlayer _pageTransitionPlayer =
      AudioPlayer(playerId: 'sound_page_transition');
  final AudioPlayer _loadingPlayer = AudioPlayer(playerId: 'sound_loading');

  /// 是否已初始化（预加载完成）
  bool _initialized = false;

  /// SettingsProvider 引用（由 main.dart 或 App 初始化时注入）
  SettingsProvider? _settingsProvider;

  /// 注入 SettingsProvider 以读取音效开关
  void setSettingsProvider(SettingsProvider provider) {
    _settingsProvider = provider;
  }

  /// 当前音效是否启用（未注入 SettingsProvider 时默认开启）
  bool get _soundEnabled => _settingsProvider?.soundEnabled ?? true;

  /// 预加载所有音效到内存，减少首次播放延迟
  Future<void> init() async {
    if (_initialized) return;
    try {
      await Future.wait([
        _sendPlayer.setReleaseMode(ReleaseMode.stop),
        _receivePlayer.setReleaseMode(ReleaseMode.stop),
        _clickPlayer.setReleaseMode(ReleaseMode.stop),
        _ripplePlayer.setReleaseMode(ReleaseMode.stop),
        _successPlayer.setReleaseMode(ReleaseMode.stop),
        _errorPlayer.setReleaseMode(ReleaseMode.stop),
        _notificationPlayer.setReleaseMode(ReleaseMode.stop),
        _deletePlayer.setReleaseMode(ReleaseMode.stop),
        _recordStartPlayer.setReleaseMode(ReleaseMode.stop),
        _recordStopPlayer.setReleaseMode(ReleaseMode.stop),
        _pageTransitionPlayer.setReleaseMode(ReleaseMode.stop),
        _loadingPlayer.setReleaseMode(ReleaseMode.stop),
      ]);
      // 设置较低音量，避免突兀
      await Future.wait([
        _sendPlayer.setVolume(0.6),
        _receivePlayer.setVolume(0.6),
        _clickPlayer.setVolume(0.4),
        _ripplePlayer.setVolume(0.3),
        _successPlayer.setVolume(0.7),
        _errorPlayer.setVolume(0.7),
        _notificationPlayer.setVolume(0.6),
        _deletePlayer.setVolume(0.5),
        _recordStartPlayer.setVolume(0.6),
        _recordStopPlayer.setVolume(0.6),
        _pageTransitionPlayer.setVolume(0.3),
        _loadingPlayer.setVolume(0.3),
      ]);
      _initialized = true;
    } catch (_) {
      // 音效初始化失败不影响主流程
    }
  }

  /// 内部播放方法
  Future<void> _play(AudioPlayer player, String assetPath) async {
    if (!_soundEnabled) return;
    try {
      await player.stop();
      await player.play(AssetSource(assetPath));
    } catch (_) {
      // 播放失败静默处理
    }
  }

  // ===== 语义化播放方法 =====

  /// 发送消息音效
  Future<void> playSend() => _play(_sendPlayer, 'sounds/send.wav');

  /// 收到 AI 回复音效
  Future<void> playReceive() => _play(_receivePlayer, 'sounds/receive.wav');

  /// 按钮点击音效
  Future<void> playClick() => _play(_clickPlayer, 'sounds/click.wav');

  /// 水波纹扩散音效
  Future<void> playRipple() => _play(_ripplePlayer, 'sounds/ripple.wav');

  /// 操作成功音效
  Future<void> playSuccess() => _play(_successPlayer, 'sounds/success.wav');

  /// 操作失败/错误音效
  Future<void> playError() => _play(_errorPlayer, 'sounds/error.wav');

  /// 通知到达音效
  Future<void> playNotification() =>
      _play(_notificationPlayer, 'sounds/notification.wav');

  /// 删除操作音效
  Future<void> playDelete() => _play(_deletePlayer, 'sounds/delete.wav');

  /// 开始录音音效
  Future<void> playRecordStart() =>
      _play(_recordStartPlayer, 'sounds/record_start.wav');

  /// 停止录音音效
  Future<void> playRecordStop() =>
      _play(_recordStopPlayer, 'sounds/record_stop.wav');

  /// 页面切换音效
  Future<void> playPageTransition() =>
      _play(_pageTransitionPlayer, 'sounds/page_transition.wav');

  /// 加载中循环音效（调用方需自行停止）
  Future<void> playLoading() => _play(_loadingPlayer, 'sounds/loading.wav');

  /// 释放所有播放器资源
  Future<void> dispose() async {
    await Future.wait([
      _sendPlayer.dispose(),
      _receivePlayer.dispose(),
      _clickPlayer.dispose(),
      _ripplePlayer.dispose(),
      _successPlayer.dispose(),
      _errorPlayer.dispose(),
      _notificationPlayer.dispose(),
      _deletePlayer.dispose(),
      _recordStartPlayer.dispose(),
      _recordStopPlayer.dispose(),
      _pageTransitionPlayer.dispose(),
      _loadingPlayer.dispose(),
    ]);
    _initialized = false;
  }
}
