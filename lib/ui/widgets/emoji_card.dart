import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../ui/widgets/emoji_preview_dialog.dart';
import '../../ui/widgets/emoji_edit_dialog.dart';
import '../../data/models/emoji.dart';
import 'package:flutter/services.dart';
import '../../core/utils/error_handler.dart';
import '../../data/repositories/emoji_repository.dart'
    hide emojiRepositoryProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_provider.dart';
import 'package:share_plus/share_plus.dart';

class EmojiCard extends StatelessWidget {
  final Emoji emoji;

  const EmojiCard({
    super.key,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => EmojiPreviewDialog(emoji: emoji),
          );
        },
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('复制'),
                  onTap: () async {
                    try {
                      // 获取应用文档目录
                      final appDir = await getApplicationDocumentsDirectory();
                      final fullPath = emoji.path.startsWith('/')
                          ? emoji.path
                          : '${appDir.path}/${emoji.path}';

                      // 复制表情名称到剪贴板
                      await Clipboard.setData(ClipboardData(
                        text: emoji.name,
                      ));

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已复制表情名称到剪贴板')),
                        );
                      }
                    } catch (e) {
                      ErrorHandler.showError(context, '复制失败: $e');
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('编辑'),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => EmojiEditDialog(emoji: emoji),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('删除'),
                  textColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('删除确认'),
                        content: Text('确定要删除表情"${emoji.name}"吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('取消'),
                          ),
                          Consumer(
                            builder: (context, ref, _) => TextButton(
                              onPressed: () async {
                                final repository =
                                    ref.read(emojiRepositoryProvider);
                                final result =
                                    await repository.deleteEmoji(emoji.id!);

                                if (result && context.mounted) {
                                  ref.invalidate(emojisProvider);
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('删���成功')),
                                  );
                                }
                              },
                              child: const Text('删除',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('分享'),
                  onTap: () async {
                    try {
                      final appDir = await getApplicationDocumentsDirectory();
                      final fullPath = emoji.path.startsWith('/')
                          ? emoji.path
                          : '${appDir.path}/${emoji.path}';

                      await Share.shareXFiles(
                        [XFile(fullPath)],
                        text: emoji.name,
                      );

                      if (context.mounted) {
                        Navigator.pop(context); // 关闭底部菜单
                      }
                    } catch (e) {
                      ErrorHandler.showError(context, '分享失败: $e');
                    }
                  },
                ),
              ],
            ),
          );
        },
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<String>(
                future: getApplicationDocumentsDirectory().then((dir) {
                  if (emoji.path.startsWith('/')) {
                    return emoji.path;
                  }
                  return '${dir.path}/${emoji.path}';
                }),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Image.file(
                    File(snapshot.data!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('图片加载失败: $error\n路径: ${snapshot.data}');
                      return const Center(
                        child: Icon(Icons.error_outline, color: Colors.red),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                emoji.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
