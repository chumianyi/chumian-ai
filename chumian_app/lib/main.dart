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
        if (mounted) {
          setState(() {
            _isValid = false;
            _loading = false;
          });
        }
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: tp.primaryGradient,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x24000000),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 44,
                  color: tp.textOnPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '初眠AI',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: tp.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '让每一次对话都更有温度',
                style: TextStyle(fontSize: 13, color: tp.textSecondary),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: tp.primaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (!_isValid) {
      return Scaffold(
        backgroundColor: tp.backgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: tp.dangerColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 42,
                    color: tp.dangerColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '你使用的不是官方版',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: tp.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '请从官方渠道下载初眠AI',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: tp.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (!_isLoggedIn) {
      return LoginPage(
        onLoginSuccess: (blessing) {
          setState(() {
            _isLoggedIn = true;
            _oobeCompleted = false;
            _birthdayBlessing = blessing;
          });
        },
      );
    }
    if (!_oobeCompleted) {
      return OobePage(onComplete: () => setState(() => _oobeCompleted = true));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_birthdayBlessing != null) {
        _showBirthdayDialog(_birthdayBlessing!);
        _birthdayBlessing = null;
      }
    });
    return HomePage(themeProvider: tp);
  }

  void _showBirthdayDialog(String blessing) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: widget.themeProvider.primaryColor.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.cake_rounded,
            color: widget.themeProvider.primaryColor,
            size: 28,
          ),
        ),
        title: const Text('生日快乐'),
        content: Text(
          blessing,
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('谢谢'),
          ),
        ],
      ),
    );
  }
}
