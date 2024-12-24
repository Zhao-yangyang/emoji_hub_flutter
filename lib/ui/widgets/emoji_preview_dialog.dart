import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/emoji.dart';
import '../../core/utils/error_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_provider.dart';
import '../../ui/widgets/emoji_edit_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/emoji_operations.dart';

class EmojiPreviewDialog extends ConsumerWidget {
  final Emoji emoji;

  const EmojiPreviewDialog({
    super.key,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 450,
        ),
        padding: EdgeInsets.only(
          top: 16.0,
          left: 16.0,
          right: 16.0,
          bottom: MediaQuery.of(context).padding.bottom + 32.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 预览图片
            Expanded(
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppConstants.cardBorderRadius),
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
                      fit: BoxFit.contain,
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
            ),

            const SizedBox(height: 16),

            // 表情名称
            Text(
              emoji.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // 操作按钮
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ActionButton(
                      icon: Icons.copy,
                      label: '复制',
                      onTap: () => _copyToClipboard(context, ref),
                    ),
                    _ActionButton(
                      icon: Icons.edit,
                      label: '编辑',
                      onTap: () => _showEditDialog(context, ref),
                    ),
                    _ActionButton(
                      icon: Icons.delete,
                      label: '删除',
                      onTap: () => EmojiOperations.deleteEmojis(
                        context,
                        ref,
                        [emoji],
                        closeParentDialog: true,
                      ),
                    ),
                    _ActionButton(
                      icon: Icons.share,
                      label: '分享',
                      onTap: () async {
                        print('点击分享按钮');
                        try {
                          print('开始分享...');
                          final appDir =
                              await getApplicationDocumentsDirectory();
                          print('应用目录: ${appDir.path}');

                          final fullPath = emoji.path.startsWith('/')
                              ? emoji.path
                              : '${appDir.path}/${emoji.path}';
                          print('分享文件路径: $fullPath');

                          // 检查文件是否存在
                          final file = File(fullPath);
                          final exists = await file.exists();
                          print('文件是否存在: $exists');
                          if (!exists) {
                            throw '文件不存在: $fullPath';
                          }

                          print('文件存在，准备分享');
                          final result = await Share.shareXFiles(
                            [XFile(fullPath)],
                            text: emoji.name,
                          );
                          print('分享完成: ${result.status}');

                          if (context.mounted &&
                              result.status == ShareResultStatus.success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('分享成功')),
                            );
                          }
                        } catch (e) {
                          print('分享失败: $e');
                          print('错误堆栈: ${StackTrace.current}');
                          if (context.mounted) {
                            ErrorHandler.showError(context, '分享失败: $e');
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(BuildContext context, WidgetRef ref) async {
    try {
      // 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();
      final fullPath = emoji.path.startsWith('/')
          ? emoji.path
          : '${appDir.path}/${emoji.path}';

      // 读取图片文件
      final file = File(fullPath);
      if (!await file.exists()) {
        throw Exception('图片文件不存在');
      }
      final bytes = await file.readAsBytes();

      // 创建剪贴板数据
      await Clipboard.setData(ClipboardData(
        text: emoji.name, // 复制表情名称
      ));

      // TODO: 实现图片数据复制到剪贴板
      // 这需要平台特定的实现，因为 Flutter 默认只支持文本复制
      // 我们可以:
      // 1. 使用平台通道实现
      // 2. 或者复制图片到临时目录并分享文件

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已复制表情名称到剪贴板')),
        );
      }
    } catch (e) {
      ErrorHandler.showError(context, '复制失败: $e');
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => EmojiEditDialog(emoji: emoji),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
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
                final repository = ref.read(emojiRepositoryProvider);
                final result = await repository.deleteEmoji(emoji.id!);

                if (result && context.mounted) {
                  ref.invalidate(emojisProvider);
                  Navigator.of(context).pop(); // 关闭确认对话框
                  Navigator.of(context).pop(); // 关闭预览对话框
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('删除成功')),
                  );
                }
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          print('_ActionButton tapped: $label');
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon),
              const SizedBox(height: 4),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
