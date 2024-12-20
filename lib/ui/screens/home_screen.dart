import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../ui/widgets/category_list.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // 自定义 AppBar
          SliverAppBar(
            expandedHeight: 200,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.background,
                      AppTheme.surface,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 分类列表占位
          const SliverToBoxAdapter(
            child: CategoryList(),
          ),

          // 表情网格占位
          SliverPadding(
            padding: const EdgeInsets.all(AppConstants.spacing),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: AppConstants.spacing,
                crossAxisSpacing: AppConstants.spacing,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius:
                        BorderRadius.circular(AppConstants.cardBorderRadius),
                  ),
                ),
                childCount: 12, // 临时显示12个占位
              ),
            ),
          ),
        ],
      ),
    );
  }
}
