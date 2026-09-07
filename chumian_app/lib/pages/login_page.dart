import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chumian_ai/theme/miuix_colors.dart';
import 'package:chumian_ai/widgets/miuix/miuix_ripple.dart';
import 'package:chumian_ai/widgets/miuix/miuix_glass.dart';
import 'package:chumian_ai/providers/user_provider.dart';
import 'package:chumian_ai/pages/register_page.dart';
import 'package:chumian_ai/pages/settings/privacy_policy_page.dart';
import 'package:chumian_ai/pages/settings/user_agreement_page.dart';

/// ============================================================
/// LoginPage —— 登录页
/// 粉色渐变背景 + mascot + MiuixInput + MiuixButton
/// ============================================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _agreeTerms = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;

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
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: MiuixCurves.easeOut));
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: MiuixCurves.miuixSpring),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
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
      await context.read<UserProvider>().login(
            _usernameController.text.trim(),
            _passwordController.text,
          );
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('登录失败：$e'),
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
            child: SlideTransition(
              position: _slideAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      _buildMascot(),
                      const SizedBox(height: 16),
                      _buildTitle(),
                      const SizedBox(height: 32),
                      _buildForm(),
                      const SizedBox(height: 20),
                      _buildLoginButton(),
                      const SizedBox(height: 16),
                      _buildForgotPassword(),
                      const SizedBox(height: 24),
                      _buildRegisterLink(),
                      const SizedBox(height: 16),
                      _buildAgreement(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMascot() {
    return Hero(
      tag: 'mascot_hero',
      child: Image.asset(
        'assets/illustrations/login_welcome.png',
        width: 160,
        height: 160,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: MiuixColors.primaryGradient),
          ),
          child: const Icon(Icons.smart_toy, color: Colors.white, size: 56),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: MiuixColors.primaryGradient,
          ).createShader(bounds),
          child: const Text(
            '初眠AI',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '你的智能陪伴助手',
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
            _buildInputField(
              controller: _usernameController,
              icon: Icons.person_outline,
              hintText: '用户名 / 邮箱',
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '请输入用户名';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _passwordController,
              icon: Icons.lock_outline,
              hintText: '密码',
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
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
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
      style: TextStyle(
        color: MiuixColors.textPrimary,
        fontSize: MiuixFontSize.md,
      ),
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

  Widget _buildLoginButton() {
    return MiuixRipple(
      borderRadius: MiuixRadius.pill,
      child: GestureDetector(
        onTap: _isLoading ? null : _handleLogin,
        child: AnimatedContainer(
          duration: MiuixDuration.fast,
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: MiuixColors.primaryGradient),
            borderRadius: MiuixRadius.pillRadius,
            boxShadow: _isLoading ? null : MiuixShadows.md,
          ),
          child: Center(
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
                    '登 录',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: MiuixFontSize.lg,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('请联系客服重置密码'),
              backgroundColor: MiuixColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: MiuixRadius.mdRadius),
            ),
          );
        },
        child: Text(
          '忘记密码？',
          style: TextStyle(
            color: MiuixColors.textSecondary,
            fontSize: MiuixFontSize.sm,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '还没有账号？',
          style: TextStyle(
            color: MiuixColors.textSecondary,
            fontSize: MiuixFontSize.md,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, anim, __) =>
                    FadeTransition(opacity: anim, child: const RegisterPage()),
                transitionDuration: MiuixDuration.page,
              ),
            );
          },
          child: Text(
            '立即注册',
            style: TextStyle(
              color: MiuixColors.primary,
              fontSize: MiuixFontSize.md,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
            width: 20,
            height: 20,
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
          style: TextStyle(
            color: MiuixColors.textSecondary,
            fontSize: MiuixFontSize.sm,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const UserAgreementPage()),
          ),
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
          child: Text(
            '《用户协议》',
            style: TextStyle(
              color: MiuixColors.primary,
              fontSize: MiuixFontSize.sm,
            ),
          ),
        ),
        Text(
          '和',
          style: TextStyle(
            color: MiuixColors.textSecondary,
            fontSize: MiuixFontSize.sm,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
          ),
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
          child: Text(
            '《隐私政策》',
            style: TextStyle(
              color: MiuixColors.primary,
              fontSize: MiuixFontSize.sm,
            ),
          ),
        ),
      ],
    );
  }
}
