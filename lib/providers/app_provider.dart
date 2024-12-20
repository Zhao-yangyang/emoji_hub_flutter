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

// 当前选中分类状态
final selectedCategoryIdProvider = StateProvider<int?>((ref) => null);

// 表情列表状态
final emojisProvider = FutureProvider<List<Emoji>>((ref) async {
  final repository = ref.read(emojiRepositoryProvider);
  final categoryId = ref.watch(selectedCategoryIdProvider);
  return repository.getEmojis(categoryId: categoryId);
});
