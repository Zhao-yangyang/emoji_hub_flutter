import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import 'category_card.dart';

class CategoryList extends StatelessWidget {
  const CategoryList({super.key});

  @override
  Widget build(BuildContext context) {
    // 临时数据，后续会从数据库获取
    final categories = [
      {'name': '全部', 'icon': Icons.grid_view_rounded},
      {'name': '收藏', 'icon': Icons.favorite_rounded},
      {'name': '表情包', 'icon': Icons.emoji_emotions_rounded},
      {'name': '贴纸', 'icon': Icons.sticky_note_2_rounded},
      {'name': 'GIF', 'icon': Icons.gif_rounded},
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacing / 2,
        ),
        itemCount: categories.length + 1, // +1 用于添加新分类的按钮
        itemBuilder: (context, index) {
          if (index == categories.length) {
            // 添加新分类的按钮
            return CategoryCard(
              name: '添加分类',
              icon: Icons.add_rounded,
              onTap: () {
                // TODO: 实现添加分类功能
              },
            );
          }

          final category = categories[index];
          return CategoryCard(
            name: category['name'] as String,
            icon: category['icon'] as IconData,
            onTap: () {
              // TODO: 实现分类切换功能
            },
          );
        },
      ),
    );
  }
}
