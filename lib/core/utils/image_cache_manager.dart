import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageCacheManager {
  static Future<String> cacheImage(String imagePath) async {
    try {
      // 获取应用缓存目录
      final cacheDir = await getTemporaryDirectory();
      final fileName = path.basename(imagePath);
      final cachedFile = File(path.join(cacheDir.path, fileName));

      // 如果缓存中已经存在该文件，直接返回缓存路径
      if (await cachedFile.exists()) {
        return cachedFile.path;
      }

      // 复制文件到缓存目录
      await File(imagePath).copy(cachedFile.path);
      return cachedFile.path;
    } catch (e) {
      print('[ImageCacheManager] 缓存图片失败: $e');
      return imagePath; // 如果缓存失败，返回原始路径
    }
  }

  static Future<void> clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (e) {
      print('[ImageCacheManager] 清除缓存失败: $e');
    }
  }

  static Future<File?> getCachedImage(String imagePath) async {
    try {
      // 如果不是绝对路径，获取应用文档目录
      if (!imagePath.startsWith('/')) {
        final appDir = await getApplicationDocumentsDirectory();
        imagePath = '${appDir.path}/$imagePath';
      }

      final file = File(imagePath);
      if (!await file.exists()) {
        print('[ImageCacheManager] 原始文件不存在: $imagePath');
        // 尝试重新创建目录
        final dir = file.parent;
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        return null;
      }

      final cacheDir = await getTemporaryDirectory();
      final fileName = path.basename(imagePath);
      final cachedFile = File(path.join(cacheDir.path, fileName));

      if (await cachedFile.exists()) {
        return cachedFile;
      }

      // 如果缓存不存在，复制并返回新文件
      await file.copy(cachedFile.path);
      return cachedFile;
    } catch (e) {
      print('[ImageCacheManager] 获取缓存图片失败: $e');
      return null;
    }
  }

  static Future<int> getCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final files = await cacheDir.list().toList();
      return files.length;
    } catch (e) {
      print('[ImageCacheManager] 获取缓存大小失败: $e');
      return 0;
    }
  }
}
