import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/context_ext.dart';
import '../widgets/buttons.dart';
import '../utils/constants.dart';

class LoginPage extends StatefulWidget {
  final Function(String?) onLoginSuccess;
  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLogin = true;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (_loading) return;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      _showSnack('请输入账号');
      return;
    }
    if (password.isEmpty) {
      _showSnack('请输入密码');
      return;
    }

    if (!_isLogin) {
      final confirm = _confirmPasswordController.text;
      final nickname = _nicknameController.text.trim();
      if (password != confirm) {
        _showSnack('两次密码不一致');
        return;
      }
      if (nickname.isEmpty) {
        _showSnack('请输入昵称');
        return;
      }
    }

    setState(() => _loading = true);
    try {
      String? blessing;
      if (_isLogin) {
        final resp = await ApiService.login(username, password);
        blessing = resp['birthday_blessing'];
      } else {
        await ApiService.register(
          username: username,
          password: password,
          nickname: _nicknameController.text.trim(),
        );
      }
      widget.onLoginSuccess(blessing);
    } catch (e) {
      _showSnack(ErrorMessages.of(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _switchMode() {
    setState(() => _isLogin = !_isLogin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              _buildBrandHeader(),
              const SizedBox(height: 36),
              _buildForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: context.vibrantGradient,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 44,
            color: context.onPrimary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          AboutTexts.appName,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin ? '欢迎回来，继续你的创作之旅' : '创建账号，开启智能对话',
          style: TextStyle(fontSize: 14, color: context.textSecondary),
        ),
        const SizedBox(height: 20),
        // 模式切换胶囊
        Container(
          width: 220,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: context.surfaceSubtle,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              _modeTab('登录', _isLogin),
              _modeTab('注册', !_isLogin),
            ],
          ),
        ),
      ],
    );
  }

  Widget _modeTab(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: _switchMode,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? context.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? context.primary : context.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: '账号',
            hintText: '请输入账号',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 14),
        if (!_isLogin) ...[
          TextField(
            controller: _nicknameController,
            decoration: const InputDecoration(
              labelText: '昵称',
              hintText: '其他用户将看到这个昵称',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 14),
        ],
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: '密码',
            hintText: '请输入密码',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (!_isLogin) ...[
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: '确认密码',
              hintText: '再次输入密码',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        GradientButton(
          label: _isLogin ? '登录' : '注册',
          icon: _isLogin ? Icons.login_rounded : Icons.person_add_alt_1_rounded,
          loading: _loading,
          height: 52,
          onPressed: _submit,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '登录即代表你同意《用户协议》与《隐私政策》',
              style: TextStyle(fontSize: 11, color: context.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AboutTexts.features
              .map(
                (f) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 12, color: context.success),
                      const SizedBox(width: 3),
                      Text(
                        f,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
