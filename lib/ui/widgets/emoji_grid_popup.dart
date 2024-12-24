import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../providers/floating_toolbar_provider.dart';
import '../../core/services/overlay_service.dart';
import '../../core/utils/emoji_operations.dart';
import '../widgets/emoji_preview_overlay.dart';
import '../../data/models/emoji.dart';

class EmojiGridPopup extends ConsumerWidget {
  const EmojiGridPopup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emojis = ref.watch(emojisProvider).value ?? [];

    return Container(
      width: 300,
      height: 400,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: emojis.length,
        itemBuilder: (context, index) {
          final emoji = emojis[index];
          return GestureDetector(
            onTap: () {
              ref.read(selectedEmojiProvider.notifier).state = emoji;
              ref.read(overlayServiceProvider).show(
                    context,
                    EmojiPreviewOverlay(
                      emoji: emoji,
                      onShare: () =>
                          EmojiOperations.shareEmojis(context, [emoji]),
                      onCopy: () => _copyToClipboard(context, emoji),
                    ),
                  );
            },
            child: Image.file(
              File(emoji.path),
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }

  Future<void> _copyToClipboard(BuildContext context, Emoji emoji) async {
    // 实现复制到剪贴板功能
  }
}
