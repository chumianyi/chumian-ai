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

class ChumianApp extends StatelessWidget {
  const ChumianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '初眠AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _loading = true;
  bool _isValid = true;
  bool _isLoggedIn = false;
  bool _oobeCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final valid = await ApiService.verifyApp('com.chumian.ai', 'official_release');
      if (!valid) {
        setState(() {
          _isValid = false;
          _loading = false;
        });
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

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.auto_awesome, size: 40, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 24),
              const Text('初眠AI', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    if (!_isValid) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('你使用的不是官方版', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('请从官方渠道下载初眠AI', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isLoggedIn) {
      return LoginPage(onLoginSuccess: () {
        setState(() {
          _isLoggedIn = true;
          _oobeCompleted = false;
        });
      });
    }

    if (!_oobeCompleted) {
      return OobePage(onComplete: () {
        setState(() => _oobeCompleted = true);
      });
    }

    return const HomePage();
  }
}
