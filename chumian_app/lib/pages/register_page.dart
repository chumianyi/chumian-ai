import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_glass.dart';
import 'package:chumian_ai/providers/user_provider.dart';
import 'package:chumian_ai/pages/settings/privacy_policy_page.dart';
import 'package:chumian_ai/pages/settings/user_agreement_page.dart';

/// ============================================================
/// RegisterPage —— 注册页
/// 用户名/昵称/密码/确认密码 + 协议勾选
/// ============================================================
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _agreeTerms = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MiuixDuration.slow,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: MiuixCurves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _usernameController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请先阅读并同意用户协议和隐私政策'),
          backgroundColor: MiuixColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<UserProvider>().register(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            nickname: _nicknameController.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/oobe');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('注册失败：$e'),
            backgroundColor: MiuixColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: MiuixColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFE4EC),
              Color(0xFFFFF5F8),
              Color(0xFFFFEEF3),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 28),
                  _buildForm(),
                  const SizedBox(height: 24),
                  _buildRegisterButton(),
                  const SizedBox(height: 20),
                  _buildAgreement(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
            boxShadow: MiuixShadows.md,
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/mascot/mascot_small.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.person_add, color: Colors.white, size: 36),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '创建账号',
          style: TextStyle(
            color: MiuixColors.textPrimary,
            fontSize: MiuixFontSize.xxl,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '加入初眠AI，开启智能之旅',
          style: TextStyle(
            color: MiuixColors.textSecondary,
            fontSize: MiuixFontSize.md,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: MiuixGlassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: MiuixRadius.xl,
        child: Column(
          children: [
            _buildField(
              controller: _usernameController,
              icon: Icons.person_outline,
              hintText: '用户名（登录用）',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '请输入用户名';
                if (v.trim().length < 3) return '用户名至少3个字符';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _nicknameController,
              icon: Icons.badge_outlined,
              hintText: '昵称（展示用）',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '请输入昵称';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _passwordController,
              icon: Icons.lock_outline,
              hintText: '密码（至少6位）',
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: MiuixColors.textTertiary,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return '请输入密码';
                if (v.length < 6) return '密码至少6位';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _confirmController,
              icon: Icons.lock_outline,
              hintText: '确认密码',
              obscureText: _obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  color: MiuixColors.textTertiary,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return '请确认密码';
                if (v != _passwordController.text) return '两次密码不一致';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(color: MiuixColors.textPrimary, fontSize: MiuixFontSize.md),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: MiuixColors.textTertiary),
        prefixIcon: Icon(icon, color: MiuixColors.primary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: MiuixRadius.mdRadius,
          borderSide: BorderSide(color: MiuixColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: MiuixRadius.mdRadius,
          borderSide: BorderSide(color: MiuixColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: MiuixRadius.mdRadius,
          borderSide: BorderSide(color: MiuixColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: MiuixRadius.mdRadius,
          borderSide: BorderSide(color: MiuixColors.error, width: 1),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                '注册',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
      ),
    );
  }

  Widget _buildAgreement() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => setState(() => _agreeTerms = !_agreeTerms),
          child: AnimatedContainer(
            duration: MiuixDuration.fast,
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: _agreeTerms ? MiuixColors.primary : Colors.transparent,
              border: Border.all(
                color: _agreeTerms ? MiuixColors.primary : MiuixColors.textTertiary,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: _agreeTerms
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '我已阅读并同意',
          style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const UserAgreementPage()),
          ),
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
          child: Text('《用户协议》',
              style: TextStyle(color: MiuixColors.primary, fontSize: MiuixFontSize.sm)),
        ),
        Text('和', style: TextStyle(color: MiuixColors.textSecondary, fontSize: MiuixFontSize.sm)),
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
          ),
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
          child: Text('《隐私政策》',
              style: TextStyle(color: MiuixColors.primary, fontSize: MiuixFontSize.sm)),
        ),
      ],
    );
  }
}
