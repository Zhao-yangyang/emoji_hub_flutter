import 'dart:math' show max;
import 'package:flutter/material.dart' show IconData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/database_service.dart';

final categoryRepositoryProvider = Provider((ref) => CategoryRepository());

class CategoryRepository {
  final _db = DatabaseService();

  Future<List<Category>> getCategories({bool includeDeleted = false}) async {
    return _db.getCategories(includeDeleted: includeDeleted);
  }

  Future<Category?> addCategory(String name, IconData icon) async {
    final category = Category(
      name: name,
      icon: icon,
      sortOrder: await _getNextSortOrder(),
    );

    final id = await _db.insertCategory(category);
    if (id != 0) {
      return category.copyWith(id: id);
    }
    return null;
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
    return categories.map((e) => e.sortOrder).reduce(max) + 1;
  }
}
