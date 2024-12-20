import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/category_provider.dart';
import '../../providers/app_provider.dart';
import 'category_card.dart';
import '../../core/utils/animation_utils.dart';
import 'add_category_dialog.dart';
import '../../data/repositories/category_repository.dart';
import '../../core/utils/error_handler.dart';
import '../../data/models/category.dart';

class CategoryList extends ConsumerWidget {
  const CategoryList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return SizedBox(
      height: 120,
      child: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (categories) => ReorderableListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacing / 2,
          ),
          onReorder: (oldIndex, newIndex) async {
            await _updateCategoryOrder(
                context, ref, categories, oldIndex, newIndex);
          },
          children: [
            for (final category in categories)
              CategoryCard(
                key: ValueKey(category.id),
                name: category.name,
                icon: category.icon,
                isSelected:
                    ref.watch(selectedCategoryIdProvider) == category.id,
                onTap: () {
                  ref.read(selectedCategoryIdProvider.notifier).state =
                      category.id;
                },
              ),
            CategoryCard(
              key: const ValueKey('add'),
              name: '添加分类',
              icon: Icons.add_rounded,
              isSelected: false,
              onTap: () => _showAddCategoryDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCategoryDialog(
      BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddCategoryDialog(),
    );

    if (result != null) {
      final repository = ref.read(categoryRepositoryProvider);
      final category = await repository.addCategory(
        result['name'] as String,
        result['icon'] as IconData,
      );
      if (category != null) {
        ref.invalidate(categoriesProvider);
      }
    }
  }

  Future<void> _updateCategoryOrder(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      final repository = ref.read(categoryRepositoryProvider);
      final category = categories[oldIndex];
      final targetCategory = categories[newIndex];

      await repository.updateCategory(
        category.copyWith(sortOrder: targetCategory.sortOrder),
      );
      await repository.updateCategory(
        targetCategory.copyWith(sortOrder: category.sortOrder),
      );

      ref.invalidate(categoriesProvider);
    } catch (e) {
      ErrorHandler.showError(context, '更新分类顺序失败: $e');
    }
  }
}
