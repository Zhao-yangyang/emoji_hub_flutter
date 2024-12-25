import 'package:flutter/material.dart';

class FloatingWindowView extends StatelessWidget {
  const FloatingWindowView({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Column(
        children: [
          // 顶部工具栏
          Container(
            height: 40,
            color: Colors.purple,
            child: Row(
              children: [
                const Text('EmojiHub', style: TextStyle(color: Colors.white)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    // 关闭悬浮窗
                  },
                ),
              ],
            ),
          ),

          // 表情内容区域
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                return Card(
                  child: Center(
                    child: Image.asset('assets/emojis/emoji_$index.png'),
                  ),
                );
              },
              itemCount: 12, // 显示12个表情
            ),
          ),
        ],
      ),
    );
  }
}
