import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final floatingWindowServiceProvider =
    Provider((ref) => FloatingWindowService());

class FloatingWindowService {
  static const platform = MethodChannel('com.emojihub.floating_window');

  Future<void> show() async {
    try {
      print('FloatingWindowService: 发送显示悬浮窗命令');
      await platform.invokeMethod('showFloatingWindow');
      print('FloatingWindowService: 显示悬浮窗命令已发送');
    } on PlatformException catch (e) {
      print('FloatingWindowService: 显示悬浮窗失败: ${e.message}');
      print('FloatingWindowService: 错误详情: ${e.details}');
      rethrow;
    } catch (e) {
      print('FloatingWindowService: 未知错误: $e');
      rethrow;
    }
  }

  Future<void> hide() async {
    try {
      print('FloatingWindowService: 发送隐藏悬浮窗命令');
      await platform.invokeMethod('hideFloatingWindow');
      print('FloatingWindowService: 隐藏悬浮窗命令已发送');
    } on PlatformException catch (e) {
      print('FloatingWindowService: 隐藏悬浮窗失败: ${e.message}');
      print('FloatingWindowService: 错误详情: ${e.details}');
      rethrow;
    } catch (e) {
      print('FloatingWindowService: 未知错误: $e');
      rethrow;
    }
  }

  Future<void> toggle() async {
    try {
      print('FloatingWindowService: 发送切换悬浮窗命令');
      await platform.invokeMethod('toggleFloatingWindow');
      print('FloatingWindowService: 切换悬浮窗命令已发送');
    } on MissingPluginException catch (e) {
      print('FloatingWindowService: 平台通道未注册: $e');
      rethrow;
    } on PlatformException catch (e) {
      print('FloatingWindowService: 切换悬浮窗失败: ${e.message}');
      print('FloatingWindowService: 错误详情: ${e.details}');
      rethrow;
    } catch (e) {
      print('FloatingWindowService: 未知错误: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    try {
      await platform.invokeMethod('closeFloatingWindow');
    } on PlatformException catch (e) {
      print('Failed to close floating window: ${e.message}');
    }
  }
}
