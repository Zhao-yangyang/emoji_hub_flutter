import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emoji.dart';
import '../services/database_service.dart';

final emojiRepositoryProvider = Provider((ref) => EmojiRepository());

class EmojiRepository {
  final _db = DatabaseService();

  Future<List<Emoji>> getEmojis({
    int? categoryId,
    bool includeDeleted = false,
  }) async {
    return _db.getEmojis(
      categoryId: categoryId,
      includeDeleted: includeDeleted,
    );
  }

  Future<Emoji?> addEmoji({
    required String name,
    required String path,
    required int categoryId,
  }) async {
    try {
      // 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();
      final emojiDir = Directory('${appDir.path}/emojis');
      if (!await emojiDir.exists()) {
        await emojiDir.create(recursive: true);
      }

      // 复制图片到应用目录，使用相对路径
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.${path.split('.').last}';
      final relativePath = 'emojis/$fileName'; // 存储相对路径
      final fullPath = '${appDir.path}/$relativePath';
      await File(path).copy(fullPath);

      // 插入数据库
      final id = await _db.insertEmoji(Emoji(
        name: name,
        path: relativePath, // 保存相对路径
        categoryId: categoryId,
      ));

      return Emoji(
        id: id,
        name: name,
        path: relativePath, // 返回相对路径
        categoryId: categoryId,
      );
    } catch (e) {
      print('Error adding emoji: $e');
      return null;
    }
  }

  Future<bool> updateEmoji(Emoji emoji) async {
    final result = await _db.updateEmoji(emoji);
    return result != 0;
  }

  Future<bool> deleteEmoji(int id) async {
    final result = await _db.deleteEmoji(id);
    return result != 0;
  }
}
