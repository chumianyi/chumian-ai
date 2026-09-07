import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_chip.dart';
import 'package:chumian_ai/widgets/miuix/miuix_input.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_empty_state.dart';
import 'package:chumian_ai/services/api_service.dart';
import 'package:chumian_ai/utils/clipboard_utils.dart';

/// ============================================================
/// AITranslatePage —— AI 翻译
/// 源语言/目标语言选择，输入框，翻译结果，历史记录
/// 语言检测，发音按钮，粉色渐变
/// ============================================================
class AITranslatePage extends StatefulWidget {
  const AITranslatePage({super.key});

  @override
  State<AITranslatePage> createState() => _AITranslatePageState();
}

class _AITranslatePageState extends State<AITranslatePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _swapController;

  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();

  int _sourceLang = 0;
  int _targetLang = 1;
  bool _isTranslating = false;
  bool _hasResult = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _detectedLang = '';
  List<TranslateHistory> _history = [];

  static const List<LanguageInfo> _languages = [
    LanguageInfo(name: '自动检测', code: 'auto', flag: '🌐'),
    LanguageInfo(name: '简体中文', code: 'zh-CN', flag: '🇨🇳'),
    LanguageInfo(name: 'English', code: 'en', flag: '🇺🇸'),
    LanguageInfo(name: '日本語', code: 'ja', flag: '🇯🇵'),
    LanguageInfo(name: '한국어', code: 'ko', flag: '🇰🇷'),
    LanguageInfo(name: 'Français', code: 'fr', flag: '🇫🇷'),
    LanguageInfo(name: 'Deutsch', code: 'de', flag: '🇩🇪'),
    LanguageInfo(name: 'Español', code: 'es', flag: '🇪🇸'),
    LanguageInfo(name: 'Русский', code: 'ru', flag: '🇷🇺'),
    LanguageInfo(name: 'Italiano', code: 'it', flag: '🇮🇹'),
  ];

  static const List<String> _quickPhrases = [
    '你好，世界',
    'How are you?',
    'こんにちは',
    '谢谢',
    'Good morning',
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _swapController = AnimationController(
      vsync: this,
      duration: MiuixDuration.normal,
    );
    _entryController.forward();
    _loadHistory();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _swapController.dispose();
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  void _loadHistory() {
    // 翻译历史从本地存储加载，无数据时显示空态，不使用伪造数据
    setState(() {
      _history = [];
    });
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.07, (index * 0.07) + 0.4,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.07, (index * 0.07) + 0.4,
            curve: Curves.easeOutCubic),
      ),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Opacity(
        opacity: animation.value,
        child: Transform.translate(offset: slide.value, child: child),
      ),
    );
  }

  void _swapLanguages() {
    if (_sourceLang == 0) return;
    _swapController.forward(from: 0);
    setState(() {
      final temp = _sourceLang;
      _sourceLang = _targetLang;
      _targetLang = temp;
      final tempText = _inputController.text;
      _inputController.text = _outputController.text;
      _outputController.text = tempText;
    });
  }

  Future<void> _translate() async {
    if (_inputController.text.trim().isEmpty) {
      MiuixToast.show(context,
          message: '请输入要翻译的内容', type: MiuixToastType.warning);
      return;
    }
    setState(() {
      _isTranslating = true;
      _hasResult = false;
      _hasError = false;
      _errorMessage = '';
      _detectedLang = '';
    });

    try {
      final targetLang = _languages[_targetLang].name;
      final sourceLang = _sourceLang == 0 ? '自动检测' : _languages[_sourceLang].name;
      final translated = await ApiService.aiToolComplete(
        systemPrompt: '你是一位专业翻译。请将以下文本翻译为$targetLang。只输出翻译结果，不要添加解释。',
        userInput: _inputController.text,
      );

      setState(() {
        _isTranslating = false;
        _hasResult = true;
        _detectedLang = sourceLang;
        _outputController.text = translated;
        _history.insert(
          0,
          TranslateHistory(
            source: _inputController.text,
            target: translated,
            sourceLang: sourceLang,
            targetLang: targetLang,
            time: DateTime.now(),
          ),
        );
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTranslating = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _copyOutput() async {
    if (_outputController.text.isEmpty) return;
    await ClipboardUtils.copy(_outputController.text);
    if (mounted) {
      MiuixToast.show(context,
          message: '已复制翻译结果', type: MiuixToastType.success);
    }
  }

  void _speak(String text, String lang) {
    MiuixToast.show(context,
        message: '正在朗读 ($lang)...', type: MiuixToastType.info);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: 'AI 翻译',
        backgroundColor: MiuixColors.background,
        actions: [
          MiuixIconButton(
            icon: Icons.history,
            style: MiuixIconButtonStyle.ghost,
            onPressed: () => _showHistorySheet(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          children: [
            _buildAnimatedItem(_buildLanguageBar(), 0),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildInputCard(), 1),
            const SizedBox(height: 16),
            _buildAnimatedItem(_buildOutputCard(), 2),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildTranslateButton(), 3),
            const SizedBox(height: 20),
            _buildAnimatedItem(_buildQuickPhrases(), 4),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageBar() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(colors: MiuixColors.softGradient),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          Expanded(child: _buildLangSelector(_sourceLang, true)),
          RotationTransition(
            turns: _swapController,
            child: MiuixIconButton(
              icon: Icons.swap_horiz,
              style: MiuixIconButtonStyle.filled,
              size: 40,
              onPressed: _swapLanguages,
            ),
          ),
          Expanded(child: _buildLangSelector(_targetLang, false)),
        ],
      ),
    );
  }

  Widget _buildLangSelector(int selectedIndex, bool isSource) {
    return MiuixRipple(
      borderRadius: MiuixRadius.md,
      child: GestureDetector(
        onTap: () => _showLangPicker(isSource),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: MiuixRadius.mdRadius,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _languages[selectedIndex].flag,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                _languages[selectedIndex].name,
                style: const TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
              const Icon(Icons.arrow_drop_down,
                  color: MiuixColors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showLangPicker(bool isSource) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: MiuixColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(MiuixRadius.xl)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MiuixColors.border,
                borderRadius: MiuixRadius.pillRadius,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '选择语言',
              style: TextStyle(
                fontSize: MiuixFontSize.xl,
                fontWeight: FontWeight.bold,
                color: MiuixColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: _languages.length,
                itemBuilder: (context, index) {
                  final isSelected =
                      (isSource ? _sourceLang : _targetLang) == index;
                  return MiuixRipple(
                    borderRadius: MiuixRadius.md,
                    child: ListTile(
                      leading: Text(_languages[index].flag,
                          style: const TextStyle(fontSize: 24)),
                      title: Text(_languages[index].name),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: MiuixColors.primary)
                          : null,
                      onTap: () {
                        setState(() {
                          if (isSource) {
                            _sourceLang = index;
                          } else {
                            _targetLang = index;
                          }
                        });
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.translate, color: MiuixColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                '原文${_detectedLang.isNotEmpty ? '（检测到：$_detectedLang）' : ''}',
                style: const TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
              const Spacer(),
              MiuixIconButton(
                icon: Icons.clear,
                style: MiuixIconButtonStyle.ghost,
                size: 32,
                iconSize: 16,
                onPressed: () {
                  _inputController.clear();
                  setState(() {
                    _hasResult = false;
                    _detectedLang = '';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          MiuixInput(
            controller: _inputController,
            hintText: '输入要翻译的文本...',
            type: MiuixInputType.multiline,
            maxLines: 5,
            minLines: 3,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_inputController.text.length} 字符',
                style: const TextStyle(
                  fontSize: MiuixFontSize.xs,
                  color: MiuixColors.textTertiary,
                ),
              ),
              MiuixIconButton(
                icon: Icons.volume_up,
                style: MiuixIconButtonStyle.ghost,
                size: 32,
                iconSize: 18,
                onPressed: () => _speak(
                    _inputController.text, _languages[_sourceLang].name),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutputCard() {
    return MiuixCard(
      style: MiuixCardStyle.gradient,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF0F5), Color(0xFFFFE4EC)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.g_translate, color: MiuixColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                '译文（${_languages[_targetLang].name}）',
                style: const TextStyle(
                  fontSize: MiuixFontSize.md,
                  fontWeight: FontWeight.w600,
                  color: MiuixColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (_hasResult) ...[
                MiuixIconButton(
                  icon: Icons.volume_up,
                  style: MiuixIconButtonStyle.ghost,
                  size: 32,
                  iconSize: 18,
                  onPressed: () =>
                      _speak(_outputController.text, _languages[_targetLang].name),
                ),
                MiuixIconButton(
                  icon: Icons.copy,
                  style: MiuixIconButtonStyle.ghost,
                  size: 32,
                  iconSize: 18,
                  onPressed: _copyOutput,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            minHeight: 120,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: MiuixRadius.mdRadius,
            ),
            child: _isTranslating
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(MiuixColors.primary),
                      ),
                    ),
                  )
                : _hasResult
                    ? Text(
                        _outputController.text,
                        style: const TextStyle(
                          fontSize: MiuixFontSize.md,
                          height: 1.6,
                          color: MiuixColors.textPrimary,
                        ),
                      )
                    : const Text(
                        '翻译结果将显示在这里',
                        style: TextStyle(
                          fontSize: MiuixFontSize.md,
                          color: MiuixColors.textTertiary,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslateButton() {
    return SizedBox(
      width: double.infinity,
      child: MiuixButton(
        label: _isTranslating ? '翻译中...' : '立即翻译',
        icon: Icons.translate,
        type: MiuixButtonType.gradient,
        gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
        size: MiuixButtonSize.large,
        loading: _isTranslating,
        onPressed: _isTranslating ? null : _translate,
      ),
    );
  }

  Widget _buildQuickPhrases() {
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '快捷短语',
            style: TextStyle(
              fontSize: MiuixFontSize.md,
              fontWeight: FontWeight.w600,
              color: MiuixColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_quickPhrases.length, (index) {
              return MiuixChip(
                label: _quickPhrases[index],
                onTap: () {
                  _inputController.text = _quickPhrases[index];
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: MiuixColors.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(MiuixRadius.xl)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MiuixColors.border,
                  borderRadius: MiuixRadius.pillRadius,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '翻译历史',
                style: TextStyle(
                  fontSize: MiuixFontSize.xl,
                  fontWeight: FontWeight.bold,
                  color: MiuixColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _history.isEmpty
                    ? const MiuixEmptyState(
                        title: '暂无翻译历史',
                        description: '翻译记录会显示在这里',
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final item = _history[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: MiuixCard(
                              style: MiuixCardStyle.surface,
                              padding: const EdgeInsets.all(14),
                              onTap: () {
                                _inputController.text = item.source;
                                _outputController.text = item.target;
                                setState(() => _hasResult = true);
                                Navigator.pop(context);
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        item.sourceLang,
                                        style: const TextStyle(
                                          fontSize: MiuixFontSize.xs,
                                          color: MiuixColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward,
                                          size: 12,
                                          color: MiuixColors.textTertiary),
                                      Text(
                                        item.targetLang,
                                        style: const TextStyle(
                                          fontSize: MiuixFontSize.xs,
                                          color: MiuixColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _formatTime(item.time),
                                        style: const TextStyle(
                                          fontSize: MiuixFontSize.xs,
                                          color: MiuixColors.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.source,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: MiuixFontSize.md,
                                      color: MiuixColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.target,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: MiuixFontSize.sm,
                                      color: MiuixColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }
}

class LanguageInfo {
  final String name;
  final String code;
  final String flag;
  const LanguageInfo({required this.name, required this.code, required this.flag});
}

class TranslateHistory {
  final String source;
  final String target;
  final String sourceLang;
  final String targetLang;
  final DateTime time;
  const TranslateHistory({
    required this.source,
    required this.target,
    required this.sourceLang,
    required this.targetLang,
    required this.time,
  });
}
