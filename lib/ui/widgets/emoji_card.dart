import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class EmojiCard extends StatelessWidget {
  final String name;
  final String imagePath;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const EmojiCard({
    super.key,
    required this.name,
    required this.imagePath,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<String>(
                future: getApplicationDocumentsDirectory().then((dir) {
                  if (imagePath.startsWith('/')) {
                    return imagePath;
                  }
                  return '${dir.path}/$imagePath';
                }),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Image.file(
                    File(snapshot.data!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('图片加载失败: $error\n路径: ${snapshot.data}');
                      return const Center(
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.red,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
