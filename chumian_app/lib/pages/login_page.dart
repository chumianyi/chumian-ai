import 'package:flutter/material.dart';
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

  Future<void> _submit() async {
    if (_loading) return;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入账号')));
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入密码')));
      return;
    }

    if (!_isLogin) {
      final confirm = _confirmPasswordController.text;
      final nickname = _nicknameController.text.trim();
      if (password != confirm) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('两次密码不一致')));
        return;
      }
      if (nickname.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入昵称')));
        return;
      }
    }

    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await ApiService.login(username, password);
      } else {
        await ApiService.register(
          username: username,
          password: password,
          nickname: _nicknameController.text.trim(),
        );
      }
      widget.onLoginSuccess();
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('400')) msg = '信息有误，请检查';
      if (msg.contains('401')) msg = '账号或密码错误';
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
                controller: _usernameController,
                decoration: const InputDecoration(labelText: '账号', hintText: '请输入账号', prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 16),
              if (!_isLogin) ...[
                TextField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(labelText: '昵称', prefixIcon: Icon(Icons.badge_outlined)),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: '密码', prefixIcon: Icon(Icons.lock_outline)),
              ),
              const SizedBox(height: 16),
              if (!_isLogin) ...[
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '确认密码', prefixIcon: Icon(Icons.lock_outline)),
                ),
                const SizedBox(height: 24),
              ],
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
