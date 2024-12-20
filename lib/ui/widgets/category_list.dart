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
    final selectedId = ref.watch(selectedCategoryIdProvider);
    final defaultCategoryAsync = ref.watch(defaultCategoryProvider);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (categories) => SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: categories.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return defaultCategoryAsync.when(
                loading: () => const SizedBox(),
                error: (err, stack) => const SizedBox(),
                data: (defaultCategory) => CategoryCard(
                  category: defaultCategory,
                  isSelected: selectedId == defaultCategory.id,
                  onTap: () => ref
                      .read(selectedCategoryIdProvider.notifier)
                      .state = defaultCategory.id,
                ),
              );
            }

            if (index == categories.length + 1) {
              return CategoryCard(
                category: Category(
                  name: '添加分类',
                  icon: Icons.add_rounded.codePoint,
                  sortOrder: -1,
                ),
                isSelected: false,
                onTap: () => _showAddCategoryDialog(context, ref),
              );
            }

            final category = categories[index - 1];
            if (category.name == '全部') return const SizedBox();

            return CategoryCard(
              category: category,
              isSelected: selectedId == category.id,
              onTap: () => ref.read(selectedCategoryIdProvider.notifier).state =
                  category.id,
            );
          },
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
