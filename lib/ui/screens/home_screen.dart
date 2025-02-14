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
import '../../core/utils/loading_manager.dart';
import '../../core/utils/sync_manager.dart';
import '../../ui/widgets/backup_history_dialog.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:io' show Platform;
import 'package:emoji_hub_flutter/core/services/floating_window_service.dart';
import 'package:emoji_hub_flutter/core/services/permission_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final emojisAsync = ref.watch(emojisProvider);
    final isSelectionMode = ref.watch(selectionModeProvider);

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

    // 获取悬浮窗服务
    final floatingWindowService = ref.watch(floatingWindowServiceProvider);
    final permissionService = ref.watch(permissionServiceProvider);

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
              actions: [
                IconButton(
                  icon: const Icon(Icons.save_alt),
                  tooltip: '导出备份',
                  onPressed: () async {
                    try {
                      ref
                          .read(loadingProvider.notifier)
                          .startLoading('正在导出数据...');
                      final file =
                          await ref.read(syncManagerProvider).exportData();
                      ref.read(loadingProvider.notifier).stopLoading();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('数据已导出到: ${file.path}')),
                        );
                      }
                    } catch (e) {
                      ref.read(loadingProvider.notifier).stopLoading();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.file_upload),
                  tooltip: '导入恢复',
                  onPressed: () async {
                    try {
                      final XFile? file = await openFile(
                        acceptedTypeGroups: [
                          XTypeGroup(
                            label: '备份文件',
                            extensions: ['json'],
                            uniformTypeIdentifiers: ['public.json'],
                          ),
                        ],
                      );

                      if (file != null) {
                        ref
                            .read(loadingProvider.notifier)
                            .startLoading('正在导入数据...');
                        final jsonString = await file.readAsString();
                        await ref
                            .read(syncManagerProvider)
                            .importData(jsonString);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('数据导入成功')),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ErrorHandler.showError(context, '导入失败: $e');
                      }
                    } finally {
                      ref.read(loadingProvider.notifier).stopLoading();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: '备份历史',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const BackupHistoryDialog(),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.dock),
                  tooltip: '系统悬浮工具条',
                  onPressed: Platform.isAndroid
                      ? () async {
                          try {
                            print("开始处理悬浮窗操作");
                            print("检查悬浮窗权限");
                            // 检查权限
                            final hasPermission = await permissionService
                                .checkOverlayPermission();
                            print("悬浮窗权限状态: $hasPermission");

                            if (!hasPermission) {
                              print("请求悬浮窗权限");
                              // 请求权限
                              await permissionService
                                  .requestOverlayPermission();
                              print("权限请求已发送");
                              return;
                            }

                            print("切换悬浮窗状态");
                            // 显示悬浮窗
                            await floatingWindowService.toggle();
                            print("悬浮窗切换命令已发送");

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('悬浮窗已切换')),
                              );
                            }
                          } catch (e, stack) {
                            print("操作悬浮窗失败");
                            print("错误信息: $e");
                            print("错误堆栈: $stack");
                            if (context.mounted) {
                              ErrorHandler.showError(context, '操作悬浮窗失败: $e');
                            }
                          }
                        }
                      : null,
                ),
              ],
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
