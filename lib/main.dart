import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'ui/screens/home_screen.dart';
import 'data/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 清理数据库中的路径
  final db = DatabaseService();
  await db.cleanupDatabase();

  // 根据平台初始化 SQLite
  if (Platform.isWindows || Platform.isLinux) {
    // 桌面平台使用 FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // 移动平台使用默认实现，不需要特殊初始化

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
