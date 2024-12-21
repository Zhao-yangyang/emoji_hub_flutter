import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/emoji.dart';
import '../../providers/app_provider.dart';
import 'error_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class EmojiOperations {
  // 删除表情
  static Future<void> deleteEmojis(
    BuildContext context,
    WidgetRef ref,
    List<Emoji> emojis, {
    bool closeParentDialog = false,
  }) async {
    // 先显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除确认'),
        content: Text(emojis.length > 1
            ? '确定要删除选中的 ${emojis.length} 个表情吗？'
            : '确定要删除表情"${emojis[0].name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final repository = ref.read(emojiRepositoryProvider);
    int successCount = 0;

    for (var emoji in emojis) {
      final result = await repository.deleteEmoji(emoji.id!);
      if (result) successCount++;
    }

    if (context.mounted) {
      ref.invalidate(emojisProvider);

      // 如果是从预览对话框删除，需要先关闭预览对话框
      if (closeParentDialog) {
        Navigator.of(context).pop(); // 关闭预览对话框
      }

      // 如果是批量删除，清除选择状态
      if (emojis.length > 1) {
        ref.read(selectionModeProvider.notifier).state = false;
        ref.read(selectedEmojisProvider.notifier).state = {};
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            emojis.length > 1 ? '成功删除 $successCount 个表情' : '删除成功',
          ),
        ),
      );
    }
  }

  // 移动表情到其他分类
  static Future<void> moveEmojis(
    BuildContext context,
    WidgetRef ref,
    List<Emoji> emojis,
    int targetCategoryId,
    String categoryName, {
    bool closeParentDialog = false,
  }) async {
    final repository = ref.read(emojiRepositoryProvider);
    int successCount = 0;

    for (var emoji in emojis) {
      final updatedEmoji = emoji.copyWith(
        categoryId: targetCategoryId,
        updateTime: DateTime.now(),
      );
      final result = await repository.updateEmoji(updatedEmoji);
      if (result) successCount++;
    }

    if (context.mounted) {
      ref.invalidate(emojisProvider);
      // 如果是批量操作，清除选择状态
      if (emojis.length > 1) {
        ref.read(selectionModeProvider.notifier).state = false;
        ref.read(selectedEmojisProvider.notifier).state = {};
      }
      if (closeParentDialog) {
        Navigator.of(context).pop(); // 关闭分类选择对话框
        Navigator.of(context).pop(); // 关闭预览对话框
      } else {
        Navigator.of(context).pop(); // 只关闭分类选择对话框
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            emojis.length > 1
                ? '已将 $successCount 个表情移动到"$categoryName"'
                : '已移动到"$categoryName"',
          ),
        ),
      );
    }
  }

  // 分享表情
  static Future<void> shareEmojis(
    BuildContext context,
    List<Emoji> emojis,
  ) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final files = emojis.map((emoji) {
        final fullPath = emoji.path!.startsWith('/')
            ? emoji.path!
            : '${appDir.path}/${emoji.path!}';
        return XFile(fullPath);
      }).toList();

      await Share.shareXFiles(
        files,
        text: emojis.length > 1 ? '分享 ${emojis.length} 个表情' : emojis[0].name,
      );
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.showError(context, '分享失败: $e');
      }
    }
  }
}
