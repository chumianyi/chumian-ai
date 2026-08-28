import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'providers/user_provider.dart';
import 'pages/login_page.dart';
import 'pages/oobe_page.dart';
import 'pages/home_page.dart';
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChumianApp());
}

class ChumianApp extends StatelessWidget {
  const ChumianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProvider()..init(),
      child: MaterialApp(
        title: '初眠AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppInitializer(),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _verifying = true;

  @override
  void initState() {
    super.initState();
    _verifyApp();
  }

  Future<void> _verifyApp() async {
    String packageName = 'com.chumian.chumian_ai';
    String apkMd5 = 'official_release';
    await Future.delayed(const Duration(milliseconds: 800));
    await ApiService.verifyApp(packageName, apkMd5);
    if (mounted) {
      setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_verifying) {
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
                child: const Icon(
                  Icons.auto_awesome,
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '初眠AI',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '正在启动...',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<UserProvider>(
      builder: (context, user, _) {
        if (user.isLoading) {
          return const Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!user.isLoggedIn) {
          return const LoginPage();
        }
        if (!user.oobeCompleted) {
          return const OobePage();
        }
        return const HomePage();
      },
    );
  }
}
