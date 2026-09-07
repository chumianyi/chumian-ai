import 'package:flutter/material.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_toast.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// LanguagePage —— 语言设置
/// 语言列表(简体中文/繁体中文/English/日本語)
/// 选中态粉色，切换动画
/// ============================================================
class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _switchController;

  int _selectedLang = 0;
  int _previousLang = 0;

  static const List<LanguageOption> _languages = [
    LanguageOption(
      name: '简体中文',
      nativeName: '简体中文',
      flag: '🇨🇳',
      code: 'zh-CN',
      region: '中国大陆',
    ),
    LanguageOption(
      name: '繁體中文',
      nativeName: '繁體中文',
      flag: '🇭🇰',
      code: 'zh-TW',
      region: '中國台灣',
    ),
    LanguageOption(
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
      code: 'en',
      region: 'United States',
    ),
    LanguageOption(
      name: '日本語',
      nativeName: '日本語',
      flag: '🇯🇵',
      code: 'ja',
      region: '日本',
    ),
    LanguageOption(
      name: '한국어',
      nativeName: '한국어',
      flag: '🇰🇷',
      code: 'ko',
      region: '대한민국',
    ),
    LanguageOption(
      name: 'Français',
      nativeName: 'Français',
      flag: '🇫🇷',
      code: 'fr',
      region: 'France',
    ),
    LanguageOption(
      name: 'Deutsch',
      nativeName: 'Deutsch',
      flag: '🇩🇪',
      code: 'de',
      region: 'Deutschland',
    ),
    LanguageOption(
      name: 'Español',
      nativeName: 'Español',
      flag: '🇪🇸',
      code: 'es',
      region: 'España',
    ),
    LanguageOption(
      name: 'Русский',
      nativeName: 'Русский',
      flag: '🇷🇺',
      code: 'ru',
      region: 'Россия',
    ),
    LanguageOption(
      name: 'Português',
      nativeName: 'Português',
      flag: '🇧🇷',
      code: 'pt',
      region: 'Brasil',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _switchController = AnimationController(
      vsync: this,
      duration: MiuixDuration.normal,
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _switchController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.04, (index * 0.04) + 0.3,
            curve: MiuixCurves.miuixSpring),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0.04, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Interval(index * 0.04, (index * 0.04) + 0.3,
            curve: Curves.easeOutCubic),
      ),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) => Opacity(
        opacity: anim.value,
        child: Transform.translate(offset: slide.value, child: child),
      ),
    );
  }

  void _selectLanguage(int index) {
    if (index == _selectedLang) return;
    _previousLang = _selectedLang;
    _switchController.forward(from: 0);
    setState(() => _selectedLang = index);
    MiuixToast.show(
      context,
      message: '已切换为 ${_languages[index].name}',
      type: MiuixToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: MiuixAppBar(
        title: '语言设置',
        backgroundColor: MiuixColors.background,
      ),
      body: Column(
        children: [
          _buildCurrentLanguage(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                return _buildAnimatedItem(
                  _buildLanguageItem(_languages[index], index),
                  index,
                );
              },
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildCurrentLanguage() {
    final current = _languages[_selectedLang];
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8FB5), Color(0xFFFF6B9D), Color(0xFFFF5588)],
        ),
        borderRadius: MiuixRadius.xlRadius,
        boxShadow: MiuixShadows.md,
      ),
      child: Row(
        children: [
          Text(current.flag, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '当前语言',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: MiuixFontSize.sm,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  current.nativeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: MiuixFontSize.xl,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${current.region} · ${current.code.toUpperCase()}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: MiuixFontSize.xs,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: MiuixRadius.pillRadius,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  '使用中',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MiuixFontSize.sm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageItem(LanguageOption lang, int index) {
    final isSelected = _selectedLang == index;
    return MiuixCard(
      style: MiuixCardStyle.surface,
      padding: const EdgeInsets.all(0),
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => _selectLanguage(index),
      child: AnimatedContainer(
        duration: MiuixDuration.fast,
        curve: MiuixCurves.miuixSpring,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    MiuixColors.primaryLight.withValues(alpha: 0.1),
                    MiuixColors.primary.withValues(alpha: 0.05),
                  ],
                )
              : null,
          borderRadius: MiuixRadius.lgRadius,
          border: Border.all(
            color: isSelected
                ? MiuixColors.primary
                : Colors.transparent,
            width: isSelected ? 1.5 : 0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(lang.flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.nativeName,
                    style: TextStyle(
                      fontSize: MiuixFontSize.lg,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? MiuixColors.primaryDeep
                          : MiuixColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${lang.name} · ${lang.region}',
                    style: const TextStyle(
                      fontSize: MiuixFontSize.xs,
                      color: MiuixColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: MiuixDuration.fast,
              transitionBuilder: (child, anim) {
                return ScaleTransition(scale: anim, child: child);
              },
              child: isSelected
                  ? Container(
                      key: ValueKey('selected_$index'),
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        gradient:
                            LinearGradient(colors: MiuixColors.primaryGradient),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 16),
                    )
                  : const SizedBox(key: ValueKey('unselected'), width: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MiuixColors.primaryLight.withValues(alpha: 0.1),
          borderRadius: MiuixRadius.mdRadius,
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline,
                color: MiuixColors.primary, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '切换语言后，应用界面将立即更新。部分系统组件可能仍显示设备默认语言。',
                style: TextStyle(
                  fontSize: MiuixFontSize.xs,
                  color: MiuixColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LanguageOption {
  final String name;
  final String nativeName;
  final String flag;
  final String code;
  final String region;
  const LanguageOption({
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.code,
    required this.region,
  });
}
