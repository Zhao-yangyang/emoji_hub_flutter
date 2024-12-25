import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emoji.dart';
import '../services/database_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart';

final emojiRepositoryProvider = Provider((ref) => EmojiRepository());

class EmojiRepository {
  final _db = DatabaseService();

  Future<String> _getEmojisDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final emojisDir = Directory('${appDir.path}/emojis');
    if (!await emojisDir.exists()) {
      await emojisDir.create(recursive: true);
    }
    return emojisDir.path;
  }

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
      // 复制文件到应用目录
      final emojisDir = await _getEmojisDirectory();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}${extension(path)}';
      final newPath = '$emojisDir/$fileName';

      await File(path).copy(newPath);

      // 存储相对路径
      final relativePath = 'emojis/$fileName';

      final id = await _db.insertEmoji(Emoji(
        name: name,
        path: relativePath,
        categoryId: categoryId,
      ));

      return Emoji(
        id: id,
        name: name,
        path: relativePath,
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

  Future<void> deleteAllEmojis() async {
    await _db.deleteAllEmojis();
  }
}
