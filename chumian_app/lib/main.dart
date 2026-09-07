import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/miuix_colors.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/settings_provider.dart';
import 'services/api_service.dart';
import 'widgets/miuix/miuix_ripple.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/oobe_page.dart';

/// 初眠AI 应用入口
/// 整体粉色 Miuix 风格，全系统字体，全局粉色水晕，动画拉满
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 API 服务（加载 token 等）
  await ApiService.init();

  runApp(const ChumianApp());
}

/// 初眠AI 根组件
/// 配置 MultiProvider、主题、全局水晕、路由
class ChumianApp extends StatelessWidget {
  const ChumianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
        ChangeNotifierProvider(create: (_) => UserProvider()..init()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: '初眠AI',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.theme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            // 全局粉色水晕覆盖层
            builder: (context, child) {
              return GlobalRippleOverlay(
                child: child!,
              );
            },
            home: const AppInitializer(),
            // 自定义页面转场动画
            onGenerateRoute: _onGenerateRoute,
          );
        },
      ),
    );
  }

  /// 自定义路由生成 —— 所有页面转场使用缩放淡入动画
  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final WidgetBuilder? builder = _routes[settings.name];
    if (builder == null) return null;
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) =>
          builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: MiuixCurves.easeOut,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
            child: child,
          ),
        );
      },
      transitionDuration: MiuixDuration.normal,
    );
  }

  /// 命名路由表
  static final Map<String, WidgetBuilder> _routes = {
    '/login': (context) => const LoginPage(),
    '/register': (context) => const RegisterPage(),
    '/home': (context) => const HomePage(),
  };
}

/// 应用初始化器
/// 检查登录状态、OOBE 完成状态，决定进入哪个页面
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _isValid = true;
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotate;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoRotate = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 800), _checkStatus);
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final userProvider = context.read<UserProvider>();
    try {
      final valid = await ApiService.verifyApp(
        'com.chumian.chumian_ai',
        'official_release',
      );
      if (!valid) {
        if (mounted) {
          setState(() {
            _isValid = false;
            _loading = false;
          });
        }
        return;
      }
      await userProvider.init();
      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;
    final bgColor = isDark ? MiuixColors.darkBackground : MiuixColors.background;

    if (_loading) {
      return _buildSplashScreen(bgColor, isDark);
    }
    if (!_isValid) {
      return _buildInvalidScreen(bgColor);
    }
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (userProvider.isLoading) {
          return _buildSplashScreen(bgColor, isDark);
        }
        if (!userProvider.isLoggedIn) {
          return const LoginPage();
        }
        if (!userProvider.oobeCompleted) {
          return OobePage(
            onComplete: () {
              userProvider.completeOobe();
            },
          );
        }
        return const HomePage();
      },
    );
  }

  Widget _buildSplashScreen(Color bgColor, bool isDark) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [MiuixColors.darkBackground, MiuixColors.darkSurface]
                : MiuixColors.backgroundGradient,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoScale.value,
                    child: Transform.rotate(
                      angle: _logoRotate.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: MiuixColors.primaryGradient,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: MiuixColors.primary.withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 20),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  '初眠AI',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? MiuixColors.darkTextPrimary
                        : MiuixColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '智能助手 · 粉色Miuix',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? MiuixColors.darkTextSecondary
                      : MiuixColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    MiuixColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvalidScreen(Color bgColor) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: MiuixColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: MiuixColors.error,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '你使用的不是官方版',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '请从官方渠道下载初眠AI',
                textAlign: TextAlign.center,
                style: TextStyle(color: MiuixColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
