import 'dart:math' show max;
import 'package:flutter/material.dart' show IconData, Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/database_service.dart';

final categoryRepositoryProvider = Provider((ref) => CategoryRepository());

class CategoryRepository {
  final _db = DatabaseService();

  Future<List<Category>> getCategories() async {
    final categories = await _db.getCategories();
    categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return categories;
  }

  Future<Category> getOrCreateDefaultCategory() async {
    final categories = await getCategories();
    final defaultCategory = categories.firstWhere(
      (c) => c.name == '全部',
      orElse: () => Category(
        name: '全部',
        icon: Icons.grid_view.codePoint,
        sortOrder: 0,
      ),
    );

    if (defaultCategory.id == null) {
      final id = await _db.insertCategory(defaultCategory);
      return defaultCategory.copyWith(id: id);
    }

    return defaultCategory;
  }

  Future<Category?> addCategory(String name, IconData icon,
      {int? color}) async {
    try {
      final category = Category(
        name: name,
        icon: icon.codePoint,
        color: color ?? 0xFF00E5FF,
        sortOrder: await _getNextSortOrder(),
      );

      final id = await _db.insertCategory(category);
      return category.copyWith(id: id);
    } catch (e) {
      print('Error adding category: $e');
      return null;
    }
  }

  Future<bool> updateCategory(Category category) async {
    final result = await _db.updateCategory(category);
    return result != 0;
  }

  Future<bool> deleteCategory(int id) async {
    final result = await _db.deleteCategory(id);
    return result != 0;
  }

  Future<int> _getNextSortOrder() async {
    final categories = await getCategories();
    if (categories.isEmpty) return 0;
    return categories.map((c) => c.sortOrder).reduce(max) + 1;
  }

  Future<bool> updateCategoriesOrder(List<Category> categories) async {
    try {
      final batch = await _db.database.then((db) => db.batch());

      for (var i = 0; i < categories.length; i++) {
        final category = categories[i];
        final updatedCategory = category.copyWith(
          sortOrder: i,
          updateTime: DateTime.now(),
        );
        await _db.updateCategory(updatedCategory);
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error updating categories order: $e');
      return false;
    }
  }
}
