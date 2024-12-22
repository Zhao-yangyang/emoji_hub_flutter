import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';

class ImageCacheManager {
  static final instance = DefaultCacheManager();
  static final Map<String, File> _memoryCache = {};

  static Future<void> cacheImage(String path) async {
    if (_memoryCache.containsKey(path)) return;

    final file = File(path);
    if (await file.exists()) {
      _memoryCache[path] = file;
    }
  }

  static Future<File?> getCachedImage(String path) async {
    // 先从内存缓存获取
    if (_memoryCache.containsKey(path)) {
      return _memoryCache[path];
    }

    // 如果是绝对路径，直接返回文件
    if (path.startsWith('/')) {
      final file = File(path);
      if (await file.exists()) {
        _memoryCache[path] = file;
        return file;
      }
      return null;
    }

    // 如果是相对路径，拼接完整路径
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$path');
    if (await file.exists()) {
      _memoryCache[path] = file;
      return file;
    }

    return null;
  }

  static Future<void> clearCache() async {
    _memoryCache.clear();
    await instance.emptyCache();
  }

  static Future<int> getCacheSize() async {
    return _memoryCache.length;
  }
}
