import 'package:flutter/material.dart';

class FloatingToolbar extends StatelessWidget {
  const FloatingToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        return Card(
          child: InkWell(
            onTap: () {
              // TODO: 处理表情点击
            },
            child: const Icon(Icons.emoji_emotions),
          ),
        );
      },
      itemCount: 9, // 临时显示9个表情
    );
  }
}
