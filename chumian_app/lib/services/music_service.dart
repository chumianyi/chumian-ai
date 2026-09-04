/// 音乐播放服务（基于 just_audio）。
library;

import 'package:just_audio/just_audio.dart';

class MusicService {
  MusicService._();
  static final MusicService instance = MusicService._();

  final AudioPlayer _player = AudioPlayer();
  final List<String> _playlist = [
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
  ];
  final List<String> _titles = [
    'SoundHelix Song 1',
    'SoundHelix Song 2',
    'SoundHelix Song 3',
    'SoundHelix Song 4',
    'SoundHelix Song 5',
  ];
  int _currentIndex = 0;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;
  String get currentTitle => _titles[_currentIndex];
  Stream<Duration?> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  AudioPlayer get player => _player;

  Future<void> play() async {
    try {
      await _player.setUrl(_playlist[_currentIndex]);
      await _player.play();
      _isPlaying = true;
    } catch (_) {
      _isPlaying = false;
    }
  }

  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
  }

  Future<void> toggle() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> next() async {
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    await play();
  }

  Future<void> previous() async {
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    await play();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void dispose() {
    _player.dispose();
  }
}
