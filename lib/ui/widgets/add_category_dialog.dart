import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({super.key});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  IconData _selectedIcon = Icons.folder_rounded;

  final _icons = [
    Icons.folder_rounded,
    Icons.emoji_emotions_rounded,
    Icons.favorite_rounded,
    Icons.star_rounded,
    Icons.gif_rounded,
    Icons.image_rounded,
    Icons.tag_faces_rounded,
    Icons.category_rounded,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacing),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '添加新分类',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.spacing),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: '分类名称',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        AppConstants.cardBorderRadius / 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        AppConstants.cardBorderRadius / 2),
                    borderSide: const BorderSide(color: AppTheme.textSecondary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        AppConstants.cardBorderRadius / 2),
                    borderSide: const BorderSide(color: AppTheme.accent),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入分类名称';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: AppConstants.spacing),
            Text(
              '选择图标',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppConstants.spacing / 2),
            Wrap(
              spacing: AppConstants.spacing / 2,
              runSpacing: AppConstants.spacing / 2,
              children: _icons.map((icon) {
                final isSelected = icon == _selectedIcon;
                return InkWell(
                  onTap: () => setState(() => _selectedIcon = icon),
                  borderRadius:
                      BorderRadius.circular(AppConstants.cardBorderRadius / 2),
                  child: Container(
                    padding: const EdgeInsets.all(AppConstants.spacing / 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.accent.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                          AppConstants.cardBorderRadius / 2),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.accent
                            : AppTheme.textSecondary,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color:
                          isSelected ? AppTheme.accent : AppTheme.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppConstants.spacing),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: AppConstants.spacing / 2),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context, {
                        'name': _nameController.text,
                        'icon': _selectedIcon,
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                  ),
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
