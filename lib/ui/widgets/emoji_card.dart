import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../ui/widgets/emoji_preview_dialog.dart';
import '../../data/models/emoji.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_provider.dart';
import '../../core/utils/image_cache_manager.dart';

class EmojiCard extends ConsumerWidget {
  final Emoji emoji;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;

  const EmojiCard({
    super.key,
    required this.emoji,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              if (isSelectionMode) {
                onSelected?.call(!isSelected);
              } else {
                showDialog(
                  context: context,
                  builder: (context) => EmojiPreviewDialog(emoji: emoji),
                );
              }
            },
            onLongPress: () {
              if (!isSelectionMode) {
                ref.read(selectionModeProvider.notifier).state = true;
                ref.read(selectedEmojisProvider.notifier).state = {emoji.id!};
              } else {
                onSelected?.call(!isSelected);
              }
            },
            child: Opacity(
              opacity: isSelectionMode && !isSelected ? 0.5 : 1.0,
              child: SizedBox.expand(
                child: FutureBuilder<File?>(
                  future: ImageCacheManager.getCachedImage(emoji.path),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Image.file(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        cacheWidth: 200,
                        errorBuilder: (context, error, stackTrace) {
                          print('图片加载失败: $error\n路径: ${emoji.path}');
                          return const Center(
                            child: Icon(Icons.error_outline, color: Colors.red),
                          );
                        },
                      );
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(4.0),
              child: Text(
                emoji.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (isSelectionMode)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey,
                          ),
                        ),
                        child: Icon(
                          Icons.check,
                          size: 20,
                          color: isSelected ? Colors.white : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
