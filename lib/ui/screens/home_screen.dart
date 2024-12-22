import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../ui/widgets/category_list.dart';
import '../../ui/widgets/emoji_grid.dart';
import '../../ui/widgets/import_emoji_dialog.dart';
import '../../ui/widgets/loading_overlay.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_provider.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/error_manager.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final emojisAsync = ref.watch(emojisProvider);
    final isSelectionMode = ref.watch(selectionModeProvider);
    final errorState = ref.watch(errorProvider);

    final isLoading = categoriesAsync.isLoading || emojisAsync.isLoading;

    // 监听错误状态
    ref.listen(errorProvider, (previous, next) {
      if (next.hasError) {
        ErrorHandler.showError(context, next.message!, next.stackTrace);
        ref.read(errorProvider.notifier).clearError();
      }
    });

    // 处理错误状态
    if (categoriesAsync.hasError || emojisAsync.hasError) {
      final error =
          categoriesAsync.hasError ? categoriesAsync.error : emojisAsync.error;
      ErrorHandler.showError(context, '加载失败: $error');
    }

    return LoadingOverlay(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        floatingActionButton: isSelectionMode
            ? null
            : FloatingActionButton(
                onPressed: () => _showImportDialog(context, ref),
                child: const Icon(Icons.add_photo_alternate_rounded),
              ),
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
              sliver: SliverFillRemaining(
                hasScrollBody: true,
                child: EmojiGrid(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const ImportEmojiDialog(),
    );

    if (result == true) {
      // 刷新表情列表
      if (context.mounted) {
        ref.invalidate(emojisProvider);
      }
    }
  }
}
