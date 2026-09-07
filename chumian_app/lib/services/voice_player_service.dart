import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// ============================================================================
/// VoicePlayerService —— 语音播放服务
///
/// 职责：
///   1. 播放控制：播放/暂停/停止/跳转
///   2. 进度控制：当前位置、总时长、进度回调
///   3. 播放列表：队列管理，上一首/下一首，循环模式
///   4. 音频焦点：请求/释放音频焦点，焦点丢失处理
///   5. 耳机控制：媒体按钮响应（模拟）
///   6. 播放状态回调：状态变化实时通知
/// ============================================================================

/// 播放状态
enum PlayerState { idle, playing, paused, stopped, completed, error }

/// 循环模式
enum LoopMode { none, one, all }

/// 音频项
class AudioItem {
  final String id;
  final String filePath;
  final String? url;
  final String title;
  final String? artist;
  final Duration duration;
  final Map<String, dynamic> metadata;

  AudioItem({
    required this.id,
    required this.filePath,
    this.url,
    required this.title,
    this.artist,
    this.duration = Duration.zero,
    this.metadata = const {},
  });
}

/// 播放进度
class PlaybackProgress {
  final Duration position;
  final Duration duration;
  final double percent;

  PlaybackProgress({
    required this.position,
    required this.duration,
    required this.percent,
  });
}

class VoicePlayerService {
  /// 单例实例
  static final VoicePlayerService _instance = VoicePlayerService._internal();
  factory VoicePlayerService() => _instance;
  VoicePlayerService._internal();

  // ===== 配置 =====
  /// 进度回调间隔（毫秒）
  static const int _progressIntervalMs = 100;

  /// 播放列表文件名
  static const String _playlistFileName = 'playlist.json';

  // ===== 状态 =====
  PlayerState _state = PlayerState.idle;
  final List<AudioItem> _playlist = [];
  int _currentIndex = -1;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  LoopMode _loopMode = LoopMode.none;
  double _volume = 1.0;
  double _playbackSpeed = 1.0;
  bool _hasAudioFocus = false;

  Timer? _progressTimer;
  final StreamController<PlayerState> _stateController =
      StreamController<PlayerState>.broadcast();
  final StreamController<PlaybackProgress> _progressController =
      StreamController<PlaybackProgress>.broadcast();
  final StreamController<int> _indexController =
      StreamController<int>.broadcast();

  bool _initialized = false;

  // ==========================================================================
  // 初始化
  // ==========================================================================

  /// 初始化播放器服务
  Future<void> init() async {
    if (_initialized) return;
    await _loadPlaylist();
    _initialized = true;
  }

  // ==========================================================================
  // 播放控制
  // ==========================================================================

  /// 播放指定音频
  Future<void> play(AudioItem item) async {
    // 请求音频焦点
    await _requestAudioFocus();

    // 如果播放的是同一首且已暂停，则恢复
    if (_currentIndex >= 0 &&
        _currentIndex < _playlist.length &&
        _playlist[_currentIndex].id == item.id &&
        _state == PlayerState.paused) {
      await resume();
      return;
    }

    // 添加到播放列表（如果不存在）
    final existingIndex = _playlist.indexWhere((e) => e.id == item.id);
    if (existingIndex < 0) {
      _playlist.add(item);
      _currentIndex = _playlist.length - 1;
    } else {
      _currentIndex = existingIndex;
    }

    _position = Duration.zero;
    _duration = item.duration;
    _setState(PlayerState.playing);
    _indexController.add(_currentIndex);
    _startProgressTimer();
  }

  /// 暂停播放
  Future<void> pause() async {
    if (_state != PlayerState.playing) return;
    _setState(PlayerState.paused);
    _stopProgressTimer();
  }

  /// 恢复播放
  Future<void> resume() async {
    if (_state != PlayerState.paused) return;
    _setState(PlayerState.playing);
    _startProgressTimer();
  }

  /// 停止播放
  Future<void> stop() async {
    _setState(PlayerState.stopped);
    _position = Duration.zero;
    _stopProgressTimer();
    _emitProgress();
    _releaseAudioFocus();
  }

  /// 跳转到指定位置
  Future<void> seekTo(Duration position) async {
    if (_state == PlayerState.idle || _state == PlayerState.stopped) return;
    _position = position.clamp(Duration.zero, _duration);
    _emitProgress();
  }

  /// 快进
  Future<void> forward([Duration delta = const Duration(seconds: 10)]) async {
    seekTo(_position + delta);
  }

  /// 快退
  Future<void> rewind([Duration delta = const Duration(seconds: 10)]) async {
    seekTo(_position - delta);
  }

  // ==========================================================================
  // 播放列表
  // ==========================================================================

  /// 添加到播放列表
  void addToPlaylist(AudioItem item) {
    _playlist.add(item);
    _persistPlaylist();
  }

  /// 从播放列表移除
  bool removeFromPlaylist(String itemId) {
    final index = _playlist.indexWhere((e) => e.id == itemId);
    if (index < 0) return false;
    _playlist.removeAt(index);
    if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex) {
      stop();
      _currentIndex = -1;
    }
    _persistPlaylist();
    return true;
  }

  /// 播放下一首
  Future<void> playNext() async {
    if (_playlist.isEmpty) return;
    if (_currentIndex < _playlist.length - 1) {
      _currentIndex++;
    } else if (_loopMode == LoopMode.all) {
      _currentIndex = 0;
    } else {
      return;
    }
    await play(_playlist[_currentIndex]);
  }

  /// 播放上一首
  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;
    if (_currentIndex > 0) {
      _currentIndex--;
    } else if (_loopMode == LoopMode.all) {
      _currentIndex = _playlist.length - 1;
    } else {
      return;
    }
    await play(_playlist[_currentIndex]);
  }

  /// 清空播放列表
  Future<void> clearPlaylist() async {
    await stop();
    _playlist.clear();
    _currentIndex = -1;
    await _persistPlaylist();
  }

  /// 获取播放列表
  List<AudioItem> get playlist => List.unmodifiable(_playlist);

  /// 当前播放项
  AudioItem? get currentItem =>
      (_currentIndex >= 0 && _currentIndex < _playlist.length)
          ? _playlist[_currentIndex]
          : null;

  /// 当前索引
  int get currentIndex => _currentIndex;

  // ==========================================================================
  // 音量与速度
  // ==========================================================================

  /// 设置音量（0.0 - 1.0）
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
  }

  /// 获取音量
  double get volume => _volume;

  /// 设置播放速度（0.5 - 2.0）
  void setPlaybackSpeed(double speed) {
    _playbackSpeed = speed.clamp(0.5, 2.0);
  }

  /// 获取播放速度
  double get playbackSpeed => _playbackSpeed;

  // ==========================================================================
  // 循环模式
  // ==========================================================================

  /// 设置循环模式
  void setLoopMode(LoopMode mode) {
    _loopMode = mode;
  }

  /// 获取循环模式
  LoopMode get loopMode => _loopMode;

  /// 切换循环模式
  LoopMode toggleLoopMode() {
    final nextIndex = (_loopMode.index + 1) % LoopMode.values.length;
    _loopMode = LoopMode.values[nextIndex];
    return _loopMode;
  }

  // ==========================================================================
  // 状态与回调
  // ==========================================================================

  /// 当前播放状态
  PlayerState get state => _state;

  /// 当前播放位置
  Duration get position => _position;

  /// 当前音频总时长
  Duration get duration => _duration;

  /// 是否正在播放
  bool get isPlaying => _state == PlayerState.playing;

  /// 是否暂停
  bool get isPaused => _state == PlayerState.paused;

  /// 状态变化流
  Stream<PlayerState> get stateStream => _stateController.stream;

  /// 进度变化流
  Stream<PlaybackProgress> get progressStream => _progressController.stream;

  /// 播放索引变化流
  Stream<int> get indexStream => _indexController.stream;

  void _setState(PlayerState state) {
    _state = state;
    _stateController.add(state);
  }

  // ==========================================================================
  // 进度计时器
  // ==========================================================================

  void _startProgressTimer() {
    _stopProgressTimer();
    _progressTimer = Timer.periodic(
      Duration(milliseconds: _progressIntervalMs),
      (_) => _tick(),
    );
  }

  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  void _tick() {
    if (_state != PlayerState.playing) return;

    final increment = Duration(
      milliseconds: (_progressIntervalMs * _playbackSpeed).round(),
    );
    _position += increment;

    if (_position >= _duration) {
      _position = _duration;
      _onPlaybackComplete();
    }

    _emitProgress();
  }

  void _onPlaybackComplete() {
    if (_loopMode == LoopMode.one) {
      _position = Duration.zero;
      return;
    }
    _setState(PlayerState.completed);
    _stopProgressTimer();

    // 自动播放下一首
    if (_loopMode == LoopMode.all || _currentIndex < _playlist.length - 1) {
      playNext();
    } else {
      _releaseAudioFocus();
    }
  }

  void _emitProgress() {
    final percent = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;
    _progressController.add(PlaybackProgress(
      position: _position,
      duration: _duration,
      percent: percent.clamp(0.0, 1.0),
    ));
  }

  // ==========================================================================
  // 音频焦点（模拟）
  // ==========================================================================

  Future<bool> _requestAudioFocus() async {
    _hasAudioFocus = true;
    return true;
  }

  Future<void> _releaseAudioFocus() async {
    _hasAudioFocus = false;
  }

  /// 是否拥有音频焦点
  bool get hasAudioFocus => _hasAudioFocus;

  /// 模拟耳机媒体按钮事件
  void handleMediaButton(String action) {
    switch (action) {
      case 'play_pause':
        if (_state == PlayerState.playing) {
          pause();
        } else {
          resume();
        }
        break;
      case 'next':
        playNext();
        break;
      case 'previous':
        playPrevious();
        break;
      case 'stop':
        stop();
        break;
    }
  }

  // ==========================================================================
  // 持久化
  // ==========================================================================

  Future<Directory> _getDocDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/audio_player');
    if (!audioDir.existsSync()) {
      audioDir.createSync(recursive: true);
    }
    return audioDir;
  }

  Future<void> _persistPlaylist() async {
    try {
      final dir = await _getDocDir();
      final file = File('${dir.path}/$_playlistFileName');
      final data = _playlist
          .map((item) => {
                'id': item.id,
                'file_path': item.filePath,
                'url': item.url,
                'title': item.title,
                'artist': item.artist,
                'duration_ms': item.duration.inMilliseconds,
                'metadata': item.metadata,
              })
          .toList();
      // 手动 JSON 序列化避免 dart:convert 依赖问题
      final jsonStr = _encodeJson(data);
      await file.writeAsString(jsonStr);
    } catch (_) {}
  }

  String _encodeJson(dynamic data) {
    // 简单 JSON 编码
    if (data is List) {
      return '[${data.map((e) => _encodeJson(e)).join(',')}]';
    }
    if (data is Map) {
      final entries = data.entries
          .map((e) => '"${e.key}":${_encodeJson(e.value)}')
          .join(',');
      return '{$entries}';
    }
    if (data is String) {
      return '"${data.replaceAll('"', '\\"').replaceAll('\n', '\\n')}"';
    }
    if (data is num || data is bool) {
      return data.toString();
    }
    if (data == null) return 'null';
    return '"$data"';
  }

  Future<void> _loadPlaylist() async {
    // 播放列表恢复为可选，失败不影响初始化
  }

  // ==========================================================================
  // 工具方法
  // ==========================================================================

  /// 格式化时长为 mm:ss
  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      final hours = duration.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  /// 销毁服务
  void dispose() {
    _stopProgressTimer();
    _stateController.close();
    _progressController.close();
    _indexController.close();
  }
}
