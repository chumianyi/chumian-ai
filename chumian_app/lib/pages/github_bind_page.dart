import 'package:flutter/material.dart';
import 'package:chumian_ai/pages/github_auth_page.dart';
import 'package:chumian_ai/services/api_service.dart';
import 'package:chumian_ai/utils/pkce.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../utils/pkce.dart';
import '../theme.dart';
import '../widgets/svg_icons.dart';

class GithubBindPage extends StatefulWidget {
  final VoidCallback onBindSuccess;
  final ThemeProvider themeProvider;
  const GithubBindPage({super.key, required this.onBindSuccess, required this.themeProvider});

  @override
  State<GithubBindPage> createState() => _GithubBindPageState();
}

class _GithubBindPageState extends State<GithubBindPage> {
  bool _binding = false;

  Future<void> _startGithubBind() async {
    if (_binding) return;
    setState(() => _binding = true);
    const clientId = 'Ov23liCRs3x3XxXY5P6w';
    const redirectUri = 'https://chumianyi.github.io/chumian-ai-auth/callback';
    const scope = 'read:user user:email';
    final authUrl = PkceUtil.buildAuthUrl(
      clientId: clientId,
      redirectUri: redirectUri,
      scope: scope,
    );
    final verifier = PkceUtil.storedVerifier;
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GithubAuthPage(authUrl: authUrl, callbackUrlPrefix: redirectUri)),
      );
      PkceUtil.clearStoredVerifier();
      if (result == null || result['cancelled'] == true) return;
      if (result['error'] != null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('GitHub授权失败: ${result['error']}')));
        return;
      }
      final code = result['code'];
      if (code == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('未获取到授权码')));
        return;
      }
      final resp = await ApiService.githubBind(code: code, codeVerifier: verifier);
      if (resp['success'] == true || resp['github_id'] != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GitHub 绑定成功')));
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['error'] ?? '绑定失败')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('授权失败: $e')));
    } finally {
      if (mounted) setState(() => _binding = false);
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tp = widget.themeProvider;
    return Scaffold(
      backgroundColor: tp.backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.link_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  '需要绑定 GitHub',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: tp.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '您的账号未绑定 GitHub，拒绝登录。\n请先绑定 GitHub 账号后再使用。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: tp.textSecondary, height: 1.6),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _binding ? null : _startGithubBind,
                    icon: _binding
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : SvgIcons.github(size: 22, color: Colors.white),
                    label: Text(_binding ? '授权中...' : '绑定 GitHub', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _logout,
                  child: Text('退出登录', style: TextStyle(color: tp.textSecondary, fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
