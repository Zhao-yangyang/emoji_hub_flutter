import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final permissionServiceProvider = Provider((ref) => PermissionService());

class PermissionService {
  static const platform = MethodChannel('com.emojihub.permissions');

  Future<bool> checkOverlayPermission() async {
    try {
      print('PermissionService: 检查悬浮窗权限');
      final bool hasPermission =
          await platform.invokeMethod('checkOverlayPermission');
      print('PermissionService: 权限状态: $hasPermission');
      return hasPermission;
    } on MissingPluginException catch (e) {
      print('PermissionService: 平台通道未注册: $e');
      rethrow;
    } on PlatformException catch (e) {
      print('PermissionService: 检查权限失败: ${e.message}');
      print('PermissionService: 错误详情: ${e.details}');
      rethrow;
    } catch (e) {
      print('PermissionService: 未知错误: $e');
      rethrow;
    }
  }

  Future<void> requestOverlayPermission() async {
    try {
      print('PermissionService: 请求悬浮窗权限');
      await platform.invokeMethod('requestOverlayPermission');
      print('PermissionService: 权限请求已发送');
    } on MissingPluginException catch (e) {
      print('PermissionService: 平台通道未注册: $e');
      rethrow;
    } on PlatformException catch (e) {
      print('PermissionService: 请求权限失败: ${e.message}');
      print('PermissionService: 错误详情: ${e.details}');
      rethrow;
    } catch (e) {
      print('PermissionService: 未知错误: $e');
      rethrow;
    }
  }
}
