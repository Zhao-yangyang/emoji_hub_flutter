import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ColorPickerDialog extends StatelessWidget {
  static const _colors = [
    0xFF00E5FF, // 默认主题色
    0xFFFF4081, // 粉红
    0xFF7C4DFF, // 紫色
    0xFF00BFA5, // 青绿
    0xFFFF6E40, // 橙色
    0xFF64DD17, // 绿色
    0xFFFFAB00, // 琥珀
    0xFF448AFF, // 蓝色
    0xFF536DFE, // 靛蓝
    0xFFE91E63, // 玫瑰
    0xFF009688, // 蓝绿
    0xFF3F51B5, // 靛青
  ];

  const ColorPickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择颜色'),
      content: SizedBox(
        width: 300,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: _colors.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () => Navigator.pop(context, _colors[index]),
              child: Container(
                decoration: BoxDecoration(
                  color: Color(_colors[index]),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
