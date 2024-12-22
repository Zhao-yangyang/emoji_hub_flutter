import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_provider.dart';
import 'category_card.dart';
import 'add_category_dialog.dart';
import '../../data/repositories/category_repository.dart';
import '../../core/utils/error_handler.dart';
import '../../data/models/category.dart';
import 'category_edit_dialog.dart';
import '../../core/theme/app_theme.dart';

class CategoryList extends ConsumerStatefulWidget {
  const CategoryList({super.key});

  @override
  ConsumerState<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends ConsumerState<CategoryList> {
  final _scrollController = ScrollController();
  bool _showEndArrow = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final isAtEnd = _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent;
      setState(() {
        _showEndArrow = !isAtEnd;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedId = ref.watch(selectedCategoryIdProvider);
    final defaultCategoryAsync = ref.watch(defaultCategoryProvider);
    final isEditMode = ref.watch(categoryEditModeProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 编辑模式提示栏
        if (isEditMode)
          Container(
            color: AppTheme.accent.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                const Text('拖动分类可调整顺序'),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    ref.read(categoryEditModeProvider.notifier).state = false;
                  },
                  icon: const Icon(Icons.done),
                  label: const Text('完成'),
                ),
              ],
            ),
          ),

        // 分类列表
        SizedBox(
          height: 100,
          child: Row(
            children: [
              // 默认分类（全部）
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: defaultCategoryAsync.when(
                  loading: () => const SizedBox(),
                  error: (err, stack) => const SizedBox(),
                  data: (defaultCategory) => CategoryCard(
                    key: ValueKey('category_${defaultCategory.id}'),
                    category: defaultCategory,
                    isSelected: selectedId == defaultCategory.id,
                    onTap: () => ref
                        .read(selectedCategoryIdProvider.notifier)
                        .state = defaultCategory.id,
                  ),
                ),
              ),

              // 其他分类（可拖拽排序）
              Expanded(
                child: Stack(
                  children: [
                    categoriesAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                      data: (categories) {
                        final sortableCategories =
                            categories.where((c) => c.name != '全部').toList();

                        if (sortableCategories.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.swipe,
                                  size: 24,
                                  color: AppTheme.textPrimary.withOpacity(0.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '左右滑动查看更多分类',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        AppTheme.textPrimary.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ReorderableListView(
                          scrollDirection: Axis.horizontal,
                          scrollController: _scrollController,
                          buildDefaultDragHandles: false,
                          onReorder: (oldIndex, newIndex) {
                            if (isEditMode) {
                              _updateCategoryOrder(context, ref,
                                  sortableCategories, oldIndex, newIndex);
                            }
                          },
                          proxyDecorator: (child, index, animation) => Material(
                            elevation: 8,
                            child: child,
                          ),
                          children: [
                            for (var i = 0; i < sortableCategories.length; i++)
                              Padding(
                                key: ValueKey(
                                    'category_${sortableCategories[i].id}'),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: ReorderableDragStartListener(
                                  index: i,
                                  enabled: isEditMode,
                                  child: CategoryCard(
                                    category: sortableCategories[i],
                                    isSelected:
                                        selectedId == sortableCategories[i].id,
                                    onTap: () => ref
                                        .read(
                                            selectedCategoryIdProvider.notifier)
                                        .state = sortableCategories[i].id,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    // 右侧渐变提示
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              AppTheme.background.withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: Center(
                          child: AnimatedRotation(
                            duration: const Duration(milliseconds: 300),
                            turns: _showEndArrow ? 0 : 0.5, // 旋转 180 度
                            child: Icon(
                              Icons.chevron_right,
                              color: AppTheme.textPrimary.withOpacity(0.3),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 右侧按钮区域
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: CategoryCard(
                  category: Category(
                    name: isEditMode ? '完成排序' : '管理分类',
                    icon: isEditMode
                        ? Icons.done.codePoint
                        : Icons.edit.codePoint,
                    sortOrder: -1,
                  ),
                  isSelected: isEditMode,
                  onTap: () {
                    if (isEditMode) {
                      // 完成排序
                      ref.read(categoryEditModeProvider.notifier).state = false;
                    } else {
                      // 显示管理菜单
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.add),
                              title: const Text('添加分类'),
                              onTap: () {
                                Navigator.pop(context);
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      const CategoryEditDialog(),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.sort),
                              title: const Text('调整顺序'),
                              onTap: () {
                                Navigator.pop(context);
                                ref
                                    .read(categoryEditModeProvider.notifier)
                                    .state = true;
                              },
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
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
      // 调整索引
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      // 重新排序分类列表
      final category = categories.removeAt(oldIndex);
      categories.insert(newIndex, category);

      // 保存新的排序
      final repository = ref.read(categoryRepositoryProvider);
      final success = await repository.updateCategoriesOrder(categories);

      if (success) {
        ref.invalidate(categoriesProvider);
      } else {
        throw '更新排序失败';
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.showError(context, '更新分类顺序失败: $e');
      }
    }
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
