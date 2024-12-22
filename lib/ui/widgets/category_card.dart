import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart';
import '../../providers/app_provider.dart'
    show categoriesProvider, categoryEditModeProvider;
import '../widgets/category_edit_dialog.dart';

class CategoryCard extends ConsumerWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDefaultCategory = category.name == '全部';
    final isManageCategory = category.name == '管理分类' || category.name == '完成排序';
    final isEditMode = ref.watch(categoryEditModeProvider);

    print(
        'CategoryCard: ${category.name}, 颜色: 0x${category.color.toRadixString(16).toUpperCase()}');

    final cardColor = isManageCategory || isDefaultCategory
        ? AppTheme.accent
        : Color(category.color);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        side: BorderSide(
          color: isSelected ? cardColor : Colors.transparent,
          width: 2,
        ),
      ),
      color: isSelected
          ? cardColor.withOpacity(0.1)
          : isManageCategory
              ? AppTheme.surface
              : Color(category.color).withOpacity(0.05),
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            onLongPress: isDefaultCategory || isManageCategory || isEditMode
                ? null
                : () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.edit),
                            title: const Text('编辑分类'),
                            onTap: () {
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    CategoryEditDialog(category: category),
                              );
                            },
                          ),
                          ListTile(
                            leading:
                                const Icon(Icons.delete, color: Colors.red),
                            title: const Text('删除分类',
                                style: TextStyle(color: Colors.red)),
                            onTap: () {
                              Navigator.pop(context);
                              _showDeleteConfirm(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            child: Container(
              width: 80,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    IconData(category.icon, fontFamily: 'MaterialIcons'),
                    color: isSelected || isManageCategory
                        ? cardColor
                        : Color(category.color),
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.name,
                    style: TextStyle(
                      color: isSelected || isManageCategory
                          ? cardColor
                          : AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          if (isEditMode && !isDefaultCategory && !isManageCategory)
            Positioned(
              top: 4,
              right: 4,
              child: Icon(
                Icons.drag_handle,
                size: 16,
                color: AppTheme.textPrimary.withOpacity(0.5),
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除确认'),
        content: Text('确定要删除分类"${category.name}"吗？\n删除后该分类下的表情将移至"全部"分类。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () async {
                final repository = ref.read(categoryRepositoryProvider);
                final result = await repository.deleteCategory(category.id!);

                if (result && context.mounted) {
                  ref.invalidate(categoriesProvider);
                  Navigator.pop(context);
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
