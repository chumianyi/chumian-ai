import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../theme.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLogin = true;
  bool _loading = false;
  bool _codeSent = false;
  int _countdown = 0;

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _authCodeController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    _authCodeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.endsWith('@qq.com')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入有效的QQ邮箱')));
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await ApiService.sendCode(email);
      if (result['dev_code'] != null) {
        _codeController.text = result['dev_code'];
      }
      setState(() {
        _codeSent = true;
        _countdown = 60;
      });
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('验证码已发送')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发送失败: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _countdown--);
      return _countdown > 0;
    });
  }

  Future<void> _submit() async {
    if (_loading) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.endsWith('@qq.com')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入有效的QQ邮箱')));
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入密码')));
      return;
    }

    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await ApiService.login(email, password);
      } else {
        final code = _codeController.text.trim();
        final nickname = _nicknameController.text.trim();
        final authCode = _authCodeController.text.trim();
        if (code.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入验证码')));
          return;
        }
        if (nickname.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入昵称')));
          return;
        }
        if (authCode.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入授权码')));
          return;
        }
        await ApiService.register(
          email: email,
          code: code,
          password: password,
          nickname: nickname,
          authCode: authCode,
        );
      }
      widget.onLoginSuccess();
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('400')) msg = '信息有误，请检查';
      if (msg.contains('401')) msg = '邮箱或密码错误';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(24)),
                  child: const Icon(Icons.auto_awesome, size: 40, color: AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: 16),
              const Center(child: Text('初眠AI', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600))),
              const SizedBox(height: 8),
              Center(child: Text(_isLogin ? '欢迎回来' : '创建新账号', style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary))),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'QQ邮箱', hintText: 'example@qq.com', prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 16),
              if (!_isLogin) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                        decoration: const InputDecoration(labelText: '验证码', prefixIcon: Icon(Icons.verified_outlined)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: ElevatedButton(
                        onPressed: (_countdown > 0 || _loading) ? null : _sendCode,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: Text(_countdown > 0 ? '${_countdown}s' : '获取验证码'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(labelText: '昵称', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _authCodeController,
                  decoration: const InputDecoration(labelText: '授权码', prefixIcon: Icon(Icons.key_outlined)),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: '密码', prefixIcon: Icon(Icons.lock_outline)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isLogin ? '登录' : '注册', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin ? '没有账号？立即注册' : '已有账号？立即登录'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
