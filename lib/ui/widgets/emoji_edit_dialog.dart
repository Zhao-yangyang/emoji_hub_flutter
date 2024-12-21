import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/emoji.dart';
import '../../providers/app_provider.dart';

class EmojiEditDialog extends ConsumerStatefulWidget {
  final Emoji emoji;

  const EmojiEditDialog({
    super.key,
    required this.emoji,
  });

  @override
  ConsumerState<EmojiEditDialog> createState() => _EmojiEditDialogState();
}

class _EmojiEditDialogState extends ConsumerState<EmojiEditDialog> {
  late TextEditingController _nameController;
  late int _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.emoji.name);
    _selectedCategoryId = widget.emoji.categoryId;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '编辑表情',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 表情名称输入框
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '表情名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 分类选择下拉框
            categoriesAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('加载失败: $err'),
              data: (categories) => DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: '选择分类',
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 按钮区域
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveChanges,
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    final repository = ref.read(emojiRepositoryProvider);
    final updatedEmoji = widget.emoji.copyWith(
      name: _nameController.text,
      categoryId: _selectedCategoryId,
      updateTime: DateTime.now(),
    );

    final result = await repository.updateEmoji(updatedEmoji);

    if (result && mounted) {
      ref.invalidate(emojisProvider);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
