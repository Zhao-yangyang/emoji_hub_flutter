import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/emoji.dart';

class EmojiPreviewOverlay extends StatelessWidget {
  final Emoji emoji;
  final VoidCallback onShare;
  final VoidCallback onCopy;

  const EmojiPreviewOverlay({
    super.key,
    required this.emoji,
    required this.onShare,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.file(
            File(emoji.path),
            height: 100,
            width: 100,
            fit: BoxFit.contain,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: onCopy,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
