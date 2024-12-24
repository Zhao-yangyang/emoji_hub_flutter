import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import 'widgets/floating_toolbar.dart';

class OverlayEntryPoint extends StatelessWidget {
  const OverlayEntryPoint({super.key});

  @override
  Widget build(BuildContext context) {
    print('OverlayEntryPoint build 被调用');
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.primary,
            brightness: Brightness.dark,
          ),
        ),
        home: Builder(
          builder: (context) {
            print('FloatingToolbar 准备构建');
            return const Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: FloatingToolbar(),
              ),
            );
          },
        ),
      ),
    );
  }
}
