import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_app_bar.dart';
import 'package:chumian_ai/widgets/miuix/miuix_card.dart';
import 'package:chumian_ai/widgets/miuix/miuix_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_switch.dart';
import 'package:chumian_ai/widgets/miuix/miuix_icon_button.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';

/// ============================================================
/// PasswordGeneratorPage —— 密码生成器
/// 长度滑块，字符类型开关(大写/小写/数字/符号)
/// 生成密码，强度指示，复制，历史记录
/// 粉色主题，错落入场动画
/// ============================================================

class PasswordGeneratorPage extends StatefulWidget {
  const PasswordGeneratorPage({super.key});

  @override
  State<PasswordGeneratorPage> createState() => _PasswordGeneratorPageState();
}

class _PasswordGeneratorPageState extends State<PasswordGeneratorPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _generateController;

  double _length = 16;
  bool _useUppercase = true;
  bool _useLowercase = true;
  bool _useNumbers = true;
  bool _useSymbols = true;
  String _currentPassword = '';
  List<String> _history = [];

  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _numbers = '0123456789';
  static const String _symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(vsync: this, duration: MiuixDuration.slow);
    _entryController.forward();
    _generateController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _generatePassword();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _generateController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    String charset = '';
    if (_useUppercase) charset += _uppercase;
    if (_useLowercase) charset += _lowercase;
    if (_useNumbers) charset += _numbers;
    if (_useSymbols) charset += _symbols;

    if (charset.isEmpty) {
      setState(() => _currentPassword = '');
      return;
    }

    final random = Random.secure();
    String password = '';
    for (int i = 0; i < _length.toInt(); i++) {
      password += charset[random.nextInt(charset.length)];
    }

    _generateController.forward(from: 0);
    setState(() {
      _currentPassword = password;
      if (!_history.contains(password)) {
        _history.insert(0, password);
        if (_history.length > 10) _history.removeLast();
      }
    });
  }

  void _copyPassword(String password) {
    Clipboard.setData(ClipboardData(text: password));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('密码已复制到剪贴板'),
        backgroundColor: MiuixColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: MiuixRadius.lgRadius),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  (double, String, Color) _getStrengthInfo() {
    if (_currentPassword.isEmpty) return (0, '无', MiuixColors.textTertiary);
    int score = 0;
    if (_length >= 8) score++;
    if (_length >= 12) score++;
    if (_length >= 16) score++;
    if (_useUppercase && _useLowercase) score++;
    if (_useNumbers) score++;
    if (_useSymbols) score++;

    if (score <= 2) return (0.25, '弱', MiuixColors.error);
    if (score <= 4) return (0.5, '中等', MiuixColors.warning);
    if (score <= 5) return (0.75, '强', MiuixColors.success);
    return (1.0, '非常强', MiuixColors.primary);
  }

  @override
  Widget build(BuildContext context) {
    final (strength, strengthLabel, strengthColor) = _getStrengthInfo();

    return Scaffold(
      backgroundColor: MiuixColors.background,
      appBar: const MiuixAppBar(title: '密码生成器'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MiuixSpacing.md),
        child: Column(
          children: [
            _buildPasswordDisplay(strength, strengthLabel, strengthColor),
            const SizedBox(height: MiuixSpacing.lg),
            _buildLengthSlider(),
            const SizedBox(height: MiuixSpacing.lg),
            _buildCharacterOptions(),
            const SizedBox(height: MiuixSpacing.lg),
            _buildGenerateButton(),
            const SizedBox(height: MiuixSpacing.lg),
            if (_history.isNotEmpty) _buildHistory(),
            const SizedBox(height: MiuixSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordDisplay(double strength, String label, Color color) {
    return FadeTransition(
      opacity: _entryController,
      child: MiuixCard(
        padding: const EdgeInsets.all(MiuixSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.password, size: 20, color: MiuixColors.primary),
                const SizedBox(width: MiuixSpacing.sm),
                const Text('生成的密码', style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
                const Spacer(),
                MiuixIconButton(
                  icon: Icons.refresh,
                  style: MiuixIconButtonStyle.ghost,
                  size: 32,
                  iconSize: 18,
                  onPressed: _generatePassword,
                ),
                MiuixIconButton(
                  icon: Icons.copy,
                  style: MiuixIconButtonStyle.filled,
                  size: 32,
                  iconSize: 16,
                  onPressed: () => _copyPassword(_currentPassword),
                ),
              ],
            ),
            const SizedBox(height: MiuixSpacing.md),
            AnimatedBuilder(
              animation: _generateController,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.5 + 0.5 * _generateController.value,
                  child: Transform.scale(
                    scale: 0.95 + 0.05 * _generateController.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(MiuixSpacing.lg),
                decoration: BoxDecoration(
                  color: MiuixColors.surfaceVariant,
                  borderRadius: MiuixRadius.mdRadius,
                  border: Border.all(color: MiuixColors.borderLight, width: 1),
                ),
                child: SelectableText(
                  _currentPassword.isEmpty ? '请选择至少一种字符类型' : _currentPassword,
                  style: TextStyle(
                    fontSize: MiuixFontSize.xl,
                    fontWeight: FontWeight.w700,
                    color: _currentPassword.isEmpty ? MiuixColors.textTertiary : MiuixColors.primary,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: MiuixSpacing.md),
            Row(
              children: [
                const Text('强度', style: TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textSecondary)),
                const SizedBox(width: MiuixSpacing.sm),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: strength,
                      minHeight: 6,
                      backgroundColor: MiuixColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: MiuixSpacing.sm),
                Text(label, style: TextStyle(fontSize: MiuixFontSize.sm, fontWeight: FontWeight.w600, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLengthSlider() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryController, curve: const Interval(0.1, 0.5, curve: MiuixCurves.easeOut)),
      child: MiuixCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.straighten, size: 20, color: MiuixColors.primary),
                const SizedBox(width: MiuixSpacing.sm),
                const Text('密码长度', style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: MiuixSpacing.md, vertical: 4),
                  decoration: BoxDecoration(
                    color: MiuixColors.primary.withOpacity(0.1),
                    borderRadius: MiuixRadius.pillRadius,
                  ),
                  child: Text('${_length.toInt()}', style: const TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w700, color: MiuixColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: MiuixSpacing.md),
            Slider(
              value: _length,
              min: 4,
              max: 64,
              divisions: 60,
              activeColor: MiuixColors.primary,
              inactiveColor: MiuixColors.surfaceVariant,
              label: '${_length.toInt()}',
              onChanged: (v) => setState(() => _length = v),
              onChangeEnd: (_) => _generatePassword(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('4', style: TextStyle(fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary)),
                Text('16 (推荐)', style: TextStyle(fontSize: MiuixFontSize.xs, color: MiuixColors.primary)),
                Text('64', style: TextStyle(fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterOptions() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryController, curve: const Interval(0.2, 0.6, curve: MiuixCurves.easeOut)),
      child: MiuixCard(
        child: Column(
          children: [
            _buildOptionRow(Icons.font_download, '大写字母 (A-Z)', 'ABCDEFG', _useUppercase, (v) => setState(() => _useUppercase = v)),
            _buildDivider(),
            _buildOptionRow(Icons.text_fields, '小写字母 (a-z)', 'abcdefg', _useLowercase, (v) => setState(() => _useLowercase = v)),
            _buildDivider(),
            _buildOptionRow(Icons.looks_one, '数字 (0-9)', '123456', _useNumbers, (v) => setState(() => _useNumbers = v)),
            _buildDivider(),
            _buildOptionRow(Icons.emoji_symbols, '特殊符号 (!@#)', '!@#\$%^', _useSymbols, (v) => setState(() => _useSymbols = v)),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionRow(IconData icon, String title, String sample, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MiuixSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: MiuixColors.textTertiary),
          const SizedBox(width: MiuixSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w500, color: MiuixColors.textPrimary)),
                Text(sample, style: const TextStyle(fontSize: MiuixFontSize.xs, color: MiuixColors.textTertiary, letterSpacing: 1)),
              ],
            ),
          ),
          MiuixSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryController, curve: const Interval(0.3, 0.7, curve: MiuixCurves.easeOut)),
      child: MiuixButton(
        label: '重新生成密码',
        type: MiuixButtonType.primary,
        icon: Icons.casino,
        onPressed: _generatePassword,
        width: double.infinity,
        height: 50,
      ),
    );
  }

  Widget _buildHistory() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryController, curve: const Interval(0.4, 0.8, curve: MiuixCurves.easeOut)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, size: 18, color: MiuixColors.textTertiary),
              const SizedBox(width: MiuixSpacing.sm),
              const Text('历史记录', style: TextStyle(fontSize: MiuixFontSize.md, fontWeight: FontWeight.w600, color: MiuixColors.textPrimary)),
              const Spacer(),
              MiuixRipple(
                onTap: () => setState(() => _history.clear()),
                borderRadius: MiuixRadius.pill,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: MiuixSpacing.sm, vertical: 4),
                  child: Text('清空', style: TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textTertiary)),
                ),
              ),
            ],
          ),
          const SizedBox(height: MiuixSpacing.sm),
          ..._history.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: MiuixSpacing.xs),
              child: MiuixRipple(
                onTap: () => _copyPassword(entry.value),
                borderRadius: MiuixRadius.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: MiuixSpacing.md, vertical: MiuixSpacing.sm),
                  decoration: BoxDecoration(
                    color: MiuixColors.surface,
                    borderRadius: MiuixRadius.mdRadius,
                    border: Border.all(color: MiuixColors.borderLight, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(fontSize: MiuixFontSize.sm, color: MiuixColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.copy, size: 14, color: MiuixColors.textTertiary),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDivider() => Container(height: 1, color: MiuixColors.divider, margin: const EdgeInsets.symmetric(horizontal: MiuixSpacing.md));
}
