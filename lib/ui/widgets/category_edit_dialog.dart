import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart'
    show categoryRepositoryProvider;
import '../../providers/app_provider.dart' show categoriesProvider;
import '../../ui/widgets/icon_picker_dialog.dart';
import '../../core/theme/app_theme.dart';
import '../../ui/widgets/color_picker_dialog.dart';

class CategoryEditDialog extends StatefulWidget {
  final Category? category; // 如果是编辑则传入现有分类

  const CategoryEditDialog({super.key, this.category});

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  final _nameController = TextEditingController();
  late IconData _selectedIcon;
  late int _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.category?.icon != null
        ? IconData(widget.category!.icon, fontFamily: 'MaterialIcons')
        : Icons.folder;
    _selectedColor = widget.category?.color ?? 0xFF00E5FF;
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? '新建分类' : '编辑分类'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // 图标选择器
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final icon = await showDialog<IconData>(
                      context: context,
                      builder: (context) => const IconPickerDialog(),
                    );
                    if (icon != null) {
                      setState(() {
                        _selectedIcon = icon;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.textSecondary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _selectedIcon,
                      size: 32,
                      color: Color(_selectedColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 颜色选择器
              InkWell(
                onTap: () async {
                  final color = await showDialog<int>(
                    context: context,
                    builder: (context) => const ColorPickerDialog(),
                  );
                  if (color != null) {
                    setState(() {
                      _selectedColor = color;
                    });
                  }
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(_selectedColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 名称输入框
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '分类名称',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              if (name.isEmpty) return;

              final repository = ref.read(categoryRepositoryProvider);
              bool success;

              if (widget.category == null) {
                // 新建分类
                final newCategory = await repository.addCategory(
                  name,
                  _selectedIcon,
                  color: _selectedColor,
                );
                success = newCategory != null;
              } else {
                // 编辑分类
                final updated = widget.category!.copyWith(
                  name: name,
                  icon: _selectedIcon.codePoint,
                  color: _selectedColor,
                );
                success = await repository.updateCategory(updated);
              }

              if (success && context.mounted) {
                // 添加调试输出
                final categories = await repository.getCategories();
                for (var c in categories) {
                  print(
                      '分类: ${c.name}, 颜色: 0x${c.color.toRadixString(16).toUpperCase()}');
                }

                ref.invalidate(categoriesProvider);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(widget.category == null ? '创建成功' : '更新成功')),
                );
              }
            },
            child: const Text('确定'),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
