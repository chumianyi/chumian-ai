import 'package:flutter/material.dart';
import 'theme.dart';
import 'services/api_service.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/oobe_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  runApp(const ChumianApp());
}

class ChumianApp extends StatefulWidget {
  const ChumianApp({super.key});
  @override
  State<ChumianApp> createState() => _ChumianAppState();
}

class _ChumianAppState extends State<ChumianApp> {
  final ThemeProvider _themeProvider = ThemeProvider();
  @override
  void initState() {
    super.initState();
    _themeProvider.load();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeProvider,
      builder: (context, _) => MaterialApp(
        title: '初眠AI',
        debugShowCheckedModeBanner: false,
        theme: _themeProvider.theme,
        home: AppInitializer(themeProvider: _themeProvider),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  final ThemeProvider themeProvider;
  const AppInitializer({super.key, required this.themeProvider});
  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _loading = true;
  bool _isValid = true;
  bool _isLoggedIn = false;
  bool _oobeCompleted = false;
  String? _birthdayBlessing;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final valid = await ApiService.verifyApp('com.chumian.ai', 'official_release');
      if (!valid) {
        setState(() { _isValid = false; _loading = false; });
        return;
      }
      if (ApiService.token != null) {
        try {
          final info = await ApiService.getUserInfo();
          _isLoggedIn = true;
          _oobeCompleted = info['oobe_completed'] == true;
        } catch (_) {
          await ApiService.setToken(null);
          _isLoggedIn = false;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final tp = widget.themeProvider;
    if (_loading) {
      return Scaffold(
        backgroundColor: tp.backgroundColor,
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(color: tp.primaryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(24)), child: Icon(Icons.auto_awesome, size: 40, color: tp.primaryColor)),
          const SizedBox(height: 24),
          Text('初眠AI', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: tp.textPrimary)),
          const SizedBox(height: 16),
          CircularProgressIndicator(color: tp.primaryColor),
        ])),
      );
    }
    if (!_isValid) {
      return Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
        Icon(Icons.error_outline, size: 64, color: Colors.red),
        SizedBox(height: 16),
        Text('你使用的不是官方版', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('请从官方渠道下载初眠AI', textAlign: TextAlign.center),
      ]))));
    }
    if (!_isLoggedIn) {
      return LoginPage(onLoginSuccess: (blessing) {
        setState(() { _isLoggedIn = true; _oobeCompleted = false; _birthdayBlessing = blessing; });
      });
    }
    if (!_oobeCompleted) {
      return OobePage(onComplete: () => setState(() => _oobeCompleted = true));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_birthdayBlessing != null) {
        showDialog(context: context, builder: (ctx) => AlertDialog(
          title: const Text('🎂 生日快乐'),
          content: Text(_birthdayBlessing!),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('谢谢'))],
        ));
        _birthdayBlessing = null;
      }
    });
    return HomePage(themeProvider: tp);
  }
}
