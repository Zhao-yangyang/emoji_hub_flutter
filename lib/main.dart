import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'ui/screens/home_screen.dart';
import 'data/services/database_service.dart';
import 'ui/screens/floating_window_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbService = DatabaseService();
  await dbService.cleanupDatabase();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
      routes: {
        '/floating_window': (context) => const FloatingWindowScreen(),
      },
      onGenerateRoute: (settings) {
        // 如果是从悬浮窗启动，直接显示悬浮窗页面
        if (settings.name == '/floating_window') {
          return MaterialPageRoute(
            builder: (context) => const FloatingWindowScreen(),
          );
        }
        return null;
      },
    );
  }
}
