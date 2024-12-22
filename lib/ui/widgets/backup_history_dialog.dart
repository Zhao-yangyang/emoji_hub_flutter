import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/sync_manager.dart';
import '../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../core/utils/loading_manager.dart';
import '../../core/utils/error_handler.dart';
import '../../providers/app_provider.dart' show backupHistoryProvider;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class BackupHistoryDialog extends ConsumerWidget {
  const BackupHistoryDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('备份历史'),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: '清空历史',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确认清空'),
                  content: const Text('确定要清空所有备份历史吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await ref.read(syncManagerProvider).clearBackupHistory();
                ref.invalidate(backupHistoryProvider); // 刷新列表
              }
            },
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 300,
        child: ref.watch(backupHistoryProvider).when(
              data: (histories) {
                if (histories.isEmpty) {
                  return const Center(child: Text('暂无备份记录'));
                }

                return ListView.builder(
                  itemCount: histories.length,
                  itemBuilder: (context, index) {
                    final history = histories[index];
                    return ListTile(
                      title: Text(DateFormat('yyyy-MM-dd HH:mm:ss')
                          .format(history.timestamp)),
                      subtitle: Text(
                        '${history.type == BackupType.export ? "导出" : "导入"} - '
                        '分类: ${history.categoryCount} 表情: ${history.emojiCount}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.restore),
                            tooltip: '恢复此备份',
                            onPressed: () async {
                              try {
                                ref
                                    .read(loadingProvider.notifier)
                                    .startLoading('正在恢复数据...');

                                // 读取备份文件
                                final backupFile = File(history.path);
                                final backupDir = backupFile.parent;

                                // 检查备份文件和目录是否存在
                                if (!await backupFile.exists()) {
                                  throw Exception('备份文件不存在: ${history.path}');
                                }
                                if (!await backupDir.exists()) {
                                  throw Exception('备份目录不存在: ${backupDir.path}');
                                }

                                // 读取备份数据
                                final jsonString =
                                    await backupFile.readAsString();
                                final data =
                                    SyncData.fromJson(jsonDecode(jsonString));

                                // 检查备份数据
                                print(
                                    '备份数据: ${data.categories.length} 个分类, ${data.emojis.length} 个表情');
                                for (var emoji in data.emojis) {
                                  final sourceFile =
                                      File('${backupDir.path}/${emoji.path}');
                                  print(
                                      '检查表情文件: ${sourceFile.path}, 存在: ${await sourceFile.exists()}');
                                }

                                // 导入数据
                                await ref
                                    .read(syncManagerProvider)
                                    .importData(jsonString);

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('恢复成功')),
                                  );
                                }
                              } catch (e) {
                                print('恢复失败: $e');
                                if (context.mounted) {
                                  ErrorHandler.showError(context, '恢复失败: $e');
                                }
                              } finally {
                                ref
                                    .read(loadingProvider.notifier)
                                    .stopLoading();
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            tooltip: '删除此记录',
                            onPressed: () async {
                              await ref
                                  .read(syncManagerProvider)
                                  .deleteBackupHistory(history.path);
                              ref.invalidate(backupHistoryProvider); // 刷新列表
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('加载失败: $error')),
            ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
