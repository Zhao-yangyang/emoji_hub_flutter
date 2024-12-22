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
      // 直接使用传入的路径，不再进行文件复制
      final id = await _db.insertEmoji(Emoji(
        name: name,
        path: path,
        categoryId: categoryId,
      ));

      return Emoji(
        id: id,
        name: name,
        path: path,
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
