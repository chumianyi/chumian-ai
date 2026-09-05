import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _isRegister = false;
  bool _obscurePwd = true;
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _nicknameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final provider = context.read<UserProvider>();
    bool ok;
    if (_isRegister) {
      ok = await provider.register(
        _usernameCtrl.text.trim(),
        _passwordCtrl.text,
        _nicknameCtrl.text.trim(),
        _codeCtrl.text.trim(),
      );
    } else {
      ok = await provider.login(_usernameCtrl.text.trim(), _passwordCtrl.text);
    }
    if (ok && mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  Future<void> _sendCode() async {
    if (_usernameCtrl.text.trim().isEmpty) return;
    try {
      await ApiService().sendCode(_usernameCtrl.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('验证码已发送')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发送失败：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryVibrantGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: const Icon(Icons.nightlight_round, color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(child: Text('初眠AI', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryDeep, fontFamily: 'LXGW WenKai'))),
                  const SizedBox(height: 8),
                  Center(child: Text(_isRegister ? '创建新账号' : '欢迎回来', style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, fontFamily: 'LXGW WenKai'))),
                  const SizedBox(height: 40),
                  _buildTextField(_usernameCtrl, '邮箱/账号', Icons.person_outline),
                  const SizedBox(height: 16),
                  if (_isRegister) ...[
                    _buildTextField(_nicknameCtrl, '昵称', Icons.badge_outlined),
                    const SizedBox(height: 16),
                  ],
                  _buildPasswordField(),
                  if (_isRegister) ...[
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _buildTextField(_codeCtrl, '验证码', Icons.verified_outlined)),
                      const SizedBox(width: 12),
                      TextButton(onPressed: _sendCode, child: const Text('获取验证码', style: TextStyle(color: AppColors.primary, fontFamily: 'LXGW WenKai'))),
                    ]),
                  ],
                  const SizedBox(height: 32),
                  if (provider.error != null)
                    Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(provider.error!, style: const TextStyle(color: AppColors.error, fontSize: 13, fontFamily: 'LXGW WenKai'))),
                  GestureDetector(
                    onTap: provider.isLoading ? null : _submit,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryVibrantGradient,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Center(child: provider.isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Text(_isRegister ? '注 册' : '登 录', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'LXGW WenKai')),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(_isRegister ? '已有账号？' : '还没有账号？', style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'LXGW WenKai')),
                    TextButton(
                      onPressed: () => setState(() { _isRegister = !_isRegister; provider.clearError(); }),
                      child: Text(_isRegister ? '去登录' : '去注册', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontFamily: 'LXGW WenKai')),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  const Row(children: [Expanded(child: Divider(color: AppColors.border)), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('其他方式', style: TextStyle(color: AppColors.textTertiary, fontSize: 12, fontFamily: 'LXGW WenKai'))), Expanded(child: Divider(color: AppColors.border))]),
                  const SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GitHub登录请在设置中绑定'))),
                      child: Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)]),
                        child: const Icon(Icons.code, color: Colors.black87, size: 28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 8)]),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(fontFamily: 'LXGW WenKai', color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint, hintStyle: const TextStyle(color: AppColors.textHint, fontFamily: 'LXGW WenKai'),
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 8)]),
      child: TextField(
        controller: _passwordCtrl,
        obscureText: _obscurePwd,
        style: const TextStyle(fontFamily: 'LXGW WenKai', color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: '密码', hintStyle: const TextStyle(color: AppColors.textHint, fontFamily: 'LXGW WenKai'),
          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
          suffixIcon: IconButton(icon: Icon(_obscurePwd ? Icons.visibility_off : Icons.visibility, color: AppColors.textTertiary), onPressed: () => setState(() => _obscurePwd = !_obscurePwd)),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
