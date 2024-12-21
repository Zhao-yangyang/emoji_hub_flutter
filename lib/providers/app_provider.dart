import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/category.dart';
import '../data/models/emoji.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/emoji_repository.dart';

// 分类列表状态
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.read(categoryRepositoryProvider);
  return repository.getCategories();
});

// 默认分类状态
final defaultCategoryProvider = FutureProvider<Category>((ref) async {
  final repository = ref.read(categoryRepositoryProvider);
  return repository.getOrCreateDefaultCategory();
});

// 当前选中分类状态
final selectedCategoryIdProvider = StateProvider<int?>((ref) {
  // 获取默认分类ID
  final defaultCategory = ref.watch(defaultCategoryProvider);
  return defaultCategory.value?.id;
});

// 表情列表状态
final emojisProvider = FutureProvider<List<Emoji>>((ref) async {
  final repository = ref.read(emojiRepositoryProvider);
  final categoryId = ref.watch(selectedCategoryIdProvider);

  // 如果是默认分类（全部），则不传categoryId
  if (categoryId == ref.watch(defaultCategoryProvider).value?.id) {
    return repository.getEmojis();
  }
  return repository.getEmojis(categoryId: categoryId);
});

final emojiRepositoryProvider = Provider((ref) => EmojiRepository());
