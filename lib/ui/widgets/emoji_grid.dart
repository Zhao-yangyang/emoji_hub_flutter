import 'package:flutter/material.dart';
import 'emoji_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_provider.dart';
import '../../data/models/emoji.dart';
import '../../core/utils/emoji_operations.dart';
import 'dart:io';

class EmojiGrid extends ConsumerWidget {
  const EmojiGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emojisAsync = ref.watch(emojisProvider);
    final isSelectionMode = ref.watch(selectionModeProvider);
    final selectedEmojis = ref.watch(selectedEmojisProvider);

    return Stack(
      children: [
        emojisAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (emojis) => emojis.isEmpty
              ? const Center(child: Text('暂无表情，请先选择分类并导入表情'))
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  padding: const EdgeInsets.all(12),
                  itemCount: emojis.length,
                  itemBuilder: (context, index) {
                    final emoji = emojis[index];
                    return EmojiCard(
                      emoji: emoji,
                      isSelectionMode: isSelectionMode,
                      isSelected: selectedEmojis.contains(emoji.id),
                      onSelected: (selected) {
                        final newSelection = {...selectedEmojis};
                        if (selected) {
                          newSelection.add(emoji.id!);
                        } else {
                          newSelection.remove(emoji.id!);
                        }
                        ref.read(selectedEmojisProvider.notifier).state =
                            newSelection;
                      },
                    );
                  },
                ),
        ),
        // 底部操作栏
        if (isSelectionMode)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SelectionActionBar(
                  selectedCount: selectedEmojis.length,
                  onCancel: () {
                    ref.read(selectionModeProvider.notifier).state = false;
                    ref.read(selectedEmojisProvider.notifier).state = {};
                  },
                ),
                // 减小底部空白，只保留足够放置 FAB 的空间
                SizedBox(height: 20), // 改为固定的小间距
              ],
            ),
          ),
      ],
    );
  }
}

// 底部操作栏
class _SelectionActionBar extends ConsumerWidget {
  final int selectedCount;
  final VoidCallback onCancel;

  const _SelectionActionBar({
    required this.selectedCount,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      elevation: 8,
      color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 第一行：操作按钮
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.select_all),
                onPressed: () {
                  final emojis = ref.read(emojisProvider).value ?? [];
                  final allSelected = emojis.every(
                      (e) => ref.read(selectedEmojisProvider).contains(e.id));
                  if (allSelected) {
                    ref.read(selectedEmojisProvider.notifier).state = {};
                  } else {
                    ref.read(selectedEmojisProvider.notifier).state =
                        Set.from(emojis.map((e) => e.id!));
                  }
                },
              ),
              Text('已选择 $selectedCount 项'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  final selectedEmojis = ref.read(selectedEmojisProvider);
                  final emojis = ref.read(emojisProvider).value ?? [];
                  final selectedEmojiList = emojis
                      .where((e) => selectedEmojis.contains(e.id))
                      .toList();
                  EmojiOperations.shareEmojis(context, selectedEmojiList);
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  final selectedEmojis = ref.read(selectedEmojisProvider);
                  final emojis = ref.read(emojisProvider).value ?? [];
                  final selectedEmojiList = emojis
                      .where((e) => selectedEmojis.contains(e.id))
                      .toList();
                  // 直接显示批量重命名对话框
                  _showBatchRenameDialog(context, ref, selectedEmojiList);
                },
              ),
              IconButton(
                icon: const Icon(Icons.drive_file_move),
                onPressed: () {
                  final selectedEmojis = ref.read(selectedEmojisProvider);
                  final emojis = ref.read(emojisProvider).value ?? [];
                  final selectedEmojiList = emojis
                      .where((e) => selectedEmojis.contains(e.id))
                      .toList();
                  _showMoveDialog(context, ref, selectedEmojiList);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  final selectedEmojis = ref.read(selectedEmojisProvider);
                  final emojis = ref.read(emojisProvider).value ?? [];
                  final selectedEmojiList = emojis
                      .where((e) => selectedEmojis.contains(e.id))
                      .toList();
                  EmojiOperations.deleteEmojis(context, ref, selectedEmojiList);
                },
              ),
            ],
          ),
          // 第二行：取消按钮
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: TextButton(
              onPressed: onCancel,
              child: const Text('取消'),
            ),
          ),
        ],
      ),
    );
  }

  // 批量移动对话框
  void _showMoveDialog(
      BuildContext context, WidgetRef ref, List<Emoji> emojis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移动到分类'),
        content: SizedBox(
          width: double.maxFinite,
          child: Consumer(
            builder: (context, ref, child) {
              final categoriesAsync = ref.watch(categoriesProvider);

              return categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('加载失败: $err')),
                data: (categories) {
                  // 过滤掉"全部"分类和当前分类
                  final availableCategories = categories.where((c) {
                    final defaultCategory =
                        ref.read(defaultCategoryProvider).value;
                    final currentCategory =
                        ref.read(selectedCategoryIdProvider);
                    return c.id != defaultCategory?.id &&
                        c.id != currentCategory;
                  }).toList();

                  if (availableCategories.isEmpty) {
                    return const Center(child: Text('没有可用的目标分类'));
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableCategories.length,
                    itemBuilder: (context, index) {
                      final category = availableCategories[index];
                      return ListTile(
                        title: Text(category.name),
                        onTap: () async {
                          // 移动表情到新分类
                          final repository = ref.read(emojiRepositoryProvider);
                          int successCount = 0;

                          for (var emoji in emojis) {
                            final updatedEmoji = emoji.copyWith(
                              categoryId: category.id,
                              updateTime: DateTime.now(),
                            );
                            final result =
                                await repository.updateEmoji(updatedEmoji);
                            if (result) successCount++;
                          }

                          if (context.mounted) {
                            ref.invalidate(emojisProvider);
                            ref.read(selectionModeProvider.notifier).state =
                                false;
                            ref.read(selectedEmojisProvider.notifier).state =
                                {};
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '将 $successCount 个表情移动到"${category.name}"',
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  // 添加批量重命名对话框方法
  void _showBatchRenameDialog(
      BuildContext context, WidgetRef ref, List<Emoji> emojis) {
    // 为每个表情创建一个编辑控制器
    final controllers =
        emojis.map((e) => TextEditingController(text: e.name)).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量重命名'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400, // 固定高度，可以滚动
          child: Column(
            children: [
              Text('选中了 ${emojis.length} 个表情'),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: emojis.length,
                  itemBuilder: (context, index) {
                    final emoji = emojis[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          // 表情预览
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: Image.file(
                              File(emoji.path),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.error),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // 名称输入框
                          Expanded(
                            child: TextField(
                              controller: controllers[index],
                              decoration: InputDecoration(
                                labelText: '表情 ${index + 1}',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final repository = ref.read(emojiRepositoryProvider);
                int successCount = 0;

                // 收集所有修改
                final updates = <Emoji, String>{};
                for (var i = 0; i < emojis.length; i++) {
                  final emoji = emojis[i];
                  final newName = controllers[i].text.trim();
                  if (newName.isNotEmpty && newName != emoji.name) {
                    updates[emoji] = newName;
                  }
                }

                // 先关闭对话框
                Navigator.pop(context);

                // 清空控制器
                for (var controller in controllers) {
                  controller.dispose();
                }

                // 执行更新
                for (var entry in updates.entries) {
                  final updatedEmoji = entry.key.copyWith(
                    name: entry.value,
                    updateTime: DateTime.now(),
                  );
                  final result = await repository.updateEmoji(updatedEmoji);
                  if (result) successCount++;
                }

                if (context.mounted && successCount > 0) {
                  ref.invalidate(emojisProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('成功重命名 $successCount 个表情')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('重命名失败: $e')),
                  );
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
