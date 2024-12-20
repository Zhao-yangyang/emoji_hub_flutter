import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../core/constants/app_constants.dart';
import 'emoji_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_provider.dart';

class EmojiGrid extends ConsumerWidget {
  const EmojiGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emojisAsync = ref.watch(emojisProvider);

    print('Emojis state: $emojisAsync'); // 保留这个日志

    return emojisAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (emojis) => emojis.isEmpty
          ? const Center(child: Text('暂无表情，请先选择分类并导入表情'))
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              padding: const EdgeInsets.all(8),
              itemCount: emojis.length,
              itemBuilder: (context, index) {
                final emoji = emojis[index];
                print('构建表情卡片: ${emoji.name} - ${emoji.path}'); // 添加构建日志
                return EmojiCard(
                  name: emoji.name,
                  imagePath: emoji.path,
                  onTap: () {
                    // TODO: 实现表情预览
                  },
                  onLongPress: () {
                    // TODO: 实现表情编辑菜单
                  },
                );
              },
            ),
    );
  }
}
