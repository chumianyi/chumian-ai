import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// ChatInputBar —— 聊天输入栏组件
/// 扁平化单层输入框，上方两枚 SVG 胶囊(联网搜索/更换模型)
/// 麦克风长按录音，发送/停止按钮切换，语音波形动画
/// 附件按钮，表情按钮，聚焦粉色光晕，毛玻璃背景
/// ============================================================

/// 输入栏状态
enum InputState { idle, typing, recording, sending }

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    this.onSend,
    this.onStop,
    this.onAttachment,
    this.onEmoji,
    this.onModelSwitch,
    this.onWebSearchToggle,
    this.onVoiceStart,
    this.onVoiceEnd,
    this.onVoiceCancel,
    this.webSearchEnabled = false,
    this.isSending = false,
    this.currentModel = 'glm-4-flash',
    this.hintText = '输入消息...',
    this.controller,
    this.focusNode,
  });

  /// 发送消息回调
  final ValueChanged<String>? onSend;

  /// 停止生成回调
  final VoidCallback? onStop;

  /// 附件按钮回调
  final VoidCallback? onAttachment;

  /// 表情按钮回调
  final VoidCallback? onEmoji;

  /// 模型切换回调
  final VoidCallback? onModelSwitch;

  /// 联网搜索开关回调
  final ValueChanged<bool>? onWebSearchToggle;

  /// 语音开始回调
  final VoidCallback? onVoiceStart;

  /// 语音结束回调
  final ValueChanged<String>? onVoiceEnd;

  /// 语音取消回调
  final VoidCallback? onVoiceCancel;

  /// 联网搜索是否开启
  final bool webSearchEnabled;

  /// 是否正在发送
  final bool isSending;

  /// 当前模型名
  final String currentModel;

  /// 占位文字
  final String hintText;

  /// 文本控制器
  final TextEditingController? controller;

  /// 焦点节点
  final FocusNode? focusNode;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  InputState _state = InputState.idle;
  bool _isFocused = false;
  bool _showEmojiPanel = false;
  double _recordProgress = 0.0;
  List<double> _waveformLevels = [];
  Timer? _waveformTimer;
  final math.Random _random = math.Random();

  static const List<String> _emojis = [
    '😊', '😂', '🥰', '😎', '🤔', '😴', '🥺', '😤',
    '👍', '👏', '🙏', '💪', '❤️', '🔥', '✨', '🎉',
    '🌸', '🌙', '⭐', '☕', '🍰', '🎵', '📚', '💻',
  ];

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChange);

    _glowController = AnimationController(
      vsync: this,
      duration: MiuixDuration.normal,
    );
    _glowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _glowController, curve: MiuixCurves.easeInOut),
    );
  }

  @override
  void dispose() {
    _waveformTimer?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _controller.removeListener(_onTextChange);
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
      if (_isFocused) {
        _glowController.forward();
        _state = InputState.typing;
      } else {
        _glowController.reverse();
        if (_controller.text.isEmpty) _state = InputState.idle;
      }
    });
  }

  void _onTextChange() {
    setState(() {
      if (_controller.text.isNotEmpty) {
        _state = InputState.typing;
      } else if (!_isFocused) {
        _state = InputState.idle;
      }
    });
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSending) return;
    widget.onSend?.call(text);
    _controller.clear();
    setState(() => _state = InputState.idle);
  }

  void _handleStop() {
    widget.onStop?.call();
  }

  void _startRecording() {
    setState(() {
      _state = InputState.recording;
      _recordProgress = 0;
      _waveformLevels = List.generate(40, (_) => 0.2);
    });
    widget.onVoiceStart?.call();
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      setState(() {
        _waveformLevels.removeAt(0);
        _waveformLevels.add(0.2 + _random.nextDouble() * 0.8);
        _recordProgress = (_recordProgress + 0.01).clamp(0.0, 1.0);
      });
    });
  }

  void _stopRecording() {
    _waveformTimer?.cancel();
    setState(() => _state = InputState.idle);
    widget.onVoiceEnd?.call('识别的语音文本');
  }

  void _cancelRecording() {
    _waveformTimer?.cancel();
    setState(() => _state = InputState.idle);
    widget.onVoiceCancel?.call();
  }

  void _insertEmoji(String emoji) {
    final text = _controller.text;
    final selection = _controller.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      emoji,
    );
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + emoji.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MiuixColors.surface.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: MiuixColors.borderLight, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_state == InputState.recording) _buildRecordingOverlay(),
            _buildTopCapsules(),
            _buildInputRow(),
            if (_showEmojiPanel) _buildEmojiPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCapsules() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MiuixSpacing.md,
        MiuixSpacing.sm,
        MiuixSpacing.md,
        MiuixSpacing.xs,
      ),
      child: Row(
        children: [
          _buildCapsuleButton(
            icon: Icons.public,
            label: '联网搜索',
            isActive: widget.webSearchEnabled,
            onTap: () => widget.onWebSearchToggle?.call(!widget.webSearchEnabled),
          ),
          const SizedBox(width: MiuixSpacing.sm),
          _buildCapsuleButton(
            icon: Icons.swap_horiz,
            label: widget.currentModel,
            isActive: false,
            onTap: widget.onModelSwitch,
          ),
        ],
      ),
    );
  }

  Widget _buildCapsuleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback? onTap,
  }) {
    return MiuixRipple(
      onTap: onTap,
      borderRadius: MiuixRadius.pill,
      child: AnimatedContainer(
        duration: MiuixDuration.fast,
        curve: MiuixCurves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: MiuixSpacing.md,
          vertical: MiuixSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(colors: MiuixColors.primaryGradient)
              : null,
          color: isActive ? null : MiuixColors.surfaceVariant,
          borderRadius: MiuixRadius.pillRadius,
          border: Border.all(
            color: isActive ? Colors.transparent : MiuixColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : MiuixColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: MiuixFontSize.sm,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : MiuixColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MiuixSpacing.md,
        MiuixSpacing.xs,
        MiuixSpacing.md,
        MiuixSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildIconButton(
            icon: Icons.add_circle_outline,
            onTap: widget.onAttachment,
          ),
          const SizedBox(width: MiuixSpacing.xs),
          Expanded(child: _buildInputField()),
          const SizedBox(width: MiuixSpacing.xs),
          _buildIconButton(
            icon: Icons.emoji_emotions_outlined,
            onTap: () => setState(() => _showEmojiPanel = !_showEmojiPanel),
            isActive: _showEmojiPanel,
          ),
          const SizedBox(width: MiuixSpacing.xs),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onTap,
    bool isActive = false,
  }) {
    return MiuixRipple(
      onTap: onTap,
      borderRadius: MiuixRadius.pill,
      child: AnimatedContainer(
        duration: MiuixDuration.fast,
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive
              ? MiuixColors.primary.withValues(alpha: 0.1)
              : MiuixColors.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 22,
          color: isActive ? MiuixColors.primary : MiuixColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: MiuixColors.primary
                    .withValues(alpha: 0.15 * _glowAnimation.value),
                blurRadius: 16 * _glowAnimation.value,
                spreadRadius: 1 * _glowAnimation.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 40, maxHeight: 120),
        decoration: BoxDecoration(
          color: MiuixColors.surfaceVariant,
          borderRadius: MiuixRadius.lgRadius,
          border: Border.all(
            color: _isFocused ? MiuixColors.primary : MiuixColors.borderLight,
            width: _isFocused ? 1.5 : 1,
          ),
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          cursorColor: MiuixColors.primary,
          style: const TextStyle(
            fontSize: MiuixFontSize.md,
            color: MiuixColors.textPrimary,
            height: 1.4,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(
              fontSize: MiuixFontSize.md,
              color: MiuixColors.textTertiary,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: MiuixSpacing.md,
              vertical: MiuixSpacing.sm,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (widget.isSending) {
      return _buildStopButton();
    }
    if (_controller.text.isNotEmpty) {
      return _buildSendButton();
    }
    return _buildMicButton();
  }

  Widget _buildSendButton() {
    return MiuixRipple(
      onTap: _handleSend,
      borderRadius: MiuixRadius.pill,
      child: AnimatedContainer(
        duration: MiuixDuration.fast,
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: MiuixColors.primaryGradient),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.send,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStopButton() {
    return MiuixRipple(
      onTap: _handleStop,
      borderRadius: MiuixRadius.pill,
      child: AnimatedContainer(
        duration: MiuixDuration.fast,
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: MiuixColors.error,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: MiuixColors.error.withValues(alpha: 0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Icon(
          Icons.stop,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      onLongPressCancel: _cancelRecording,
      child: AnimatedContainer(
        duration: MiuixDuration.fast,
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: MiuixColors.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.mic_none,
          size: 22,
          color: MiuixColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildRecordingOverlay() {
    return Container(
      margin: const EdgeInsets.all(MiuixSpacing.md),
      padding: const EdgeInsets.all(MiuixSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MiuixColors.primary.withValues(alpha: 0.1),
            MiuixColors.primaryLight.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: MiuixRadius.lgRadius,
        border: Border.all(color: MiuixColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: MiuixColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: MiuixSpacing.sm),
              const Text(
                '正在录音... 松开发送，上滑取消',
                style: TextStyle(
                  fontSize: MiuixFontSize.sm,
                  color: MiuixColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${(_recordProgress * 60).toInt()}s',
                style: const TextStyle(
                  fontSize: MiuixFontSize.sm,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: MiuixSpacing.md),
          SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(40, (i) {
                final level = _waveformLevels[i];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  width: 3,
                  height: 6 + level * 30,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: MiuixColors.primary.withValues(alpha: 0.6 + level * 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPanel() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(MiuixSpacing.md),
      decoration: BoxDecoration(
        color: MiuixColors.surface,
        border: Border(
          top: BorderSide(color: MiuixColors.borderLight, width: 1),
        ),
      ),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: MiuixSpacing.sm,
          crossAxisSpacing: MiuixSpacing.sm,
        ),
        itemCount: _emojis.length,
        itemBuilder: (context, index) {
          return MiuixRipple(
            onTap: () => _insertEmoji(_emojis[index]),
            borderRadius: MiuixRadius.sm,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: MiuixColors.surfaceVariant,
                borderRadius: MiuixRadius.smRadius,
              ),
              child: Text(
                _emojis[index],
                style: const TextStyle(fontSize: 24),
              ),
            ),
          );
        },
      ),
    );
  }
}
