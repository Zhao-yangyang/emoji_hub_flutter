import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class IconPickerDialog extends StatelessWidget {
  static const _icons = [
    Icons.folder,
    Icons.emoji_emotions,
    Icons.favorite,
    Icons.star,
    Icons.pets,
    Icons.music_note,
    Icons.sports_esports,
    Icons.local_cafe,
    Icons.camera_alt,
    Icons.movie,
    Icons.book,
    Icons.palette,
  ];

  const IconPickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择图标'),
      content: SizedBox(
        width: 300,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: _icons.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () => Navigator.pop(context, _icons[index]),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.textSecondary),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _icons[index],
                  color: AppTheme.textPrimary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
