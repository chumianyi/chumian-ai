import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';
import 'providers/app_providers.dart';
import 'pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppTheme.instance.load();
  runApp(const ChumianAIApp());
}

class ChumianAIApp extends StatelessWidget {
  const ChumianAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppProviders.providers,
      child: AnimatedBuilder(
        animation: AppTheme.instance,
        builder: (context, child) {
          return MaterialApp(
            title: '初眠AI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.instance.theme,
            darkTheme: AppTheme.instance.theme,
            themeMode: ThemeMode.light,
            home: const SplashPage(),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.0),
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
