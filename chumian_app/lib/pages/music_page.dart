/// 音乐播放器页面。
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/music_service.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  late StreamSubscription _posSub;
  late StreamSubscription _durSub;

  @override
  void initState() {
    super.initState();
    _posSub = MusicService.instance.positionStream.listen((p) {
      if (p != null && mounted) setState(() => _position = p);
    });
    _durSub = MusicService.instance.durationStream.listen((d) {
      if (d != null && mounted) setState(() => _duration = d);
    });
  }

  @override
  void dispose() {
    _posSub.cancel();
    _durSub.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF2A2E35) : const Color(0xFFE8ECF0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(title: const Text('音乐')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Album art (neumorphic)
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                boxShadow: isDark
                    ? [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(6, 6)),
                        BoxShadow(color: Colors.white.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(-6, -6)),
                      ]
                    : [
                        BoxShadow(color: Colors.white.withValues(alpha: 0.9), blurRadius: 16, offset: const Offset(-6, -6)),
                        BoxShadow(color: const Color(0xFFA3B1C6).withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(6, 6)),
                      ],
              ),
              child: const Icon(Icons.music_note, size: 64, color: Color(0xFFFF6B9D)),
            ),
            const SizedBox(height: 32),
            Text(
              MusicService.instance.currentTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '初眠音乐',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 32),
            // Progress bar
            Slider(
              value: _duration.inMilliseconds > 0
                  ? _position.inMilliseconds / _duration.inMilliseconds
                  : 0,
              onChanged: (v) {
                MusicService.instance.seek(
                  Duration(milliseconds: (v * _duration.inMilliseconds).toInt()),
                );
              },
              activeColor: const Color(0xFFFF6B9D),
              inactiveColor: Colors.grey[300],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmt(_position), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  Text(_fmt(_duration), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous, size: 36),
                  onPressed: () => MusicService.instance.previous(),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () => MusicService.instance.toggle(),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: bg,
                      shape: BoxShape.circle,
                      boxShadow: isDark
                          ? [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(4, 4)),
                              BoxShadow(color: Colors.white.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(-4, -4)),
                            ]
                          : [
                              BoxShadow(color: Colors.white.withValues(alpha: 0.9), blurRadius: 10, offset: const Offset(-4, -4)),
                              BoxShadow(color: const Color(0xFFA3B1C6).withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(4, 4)),
                            ],
                    ),
                    child: Icon(
                      MusicService.instance.isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 36,
                      color: const Color(0xFFFF6B9D),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 36),
                  onPressed: () => MusicService.instance.next(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
